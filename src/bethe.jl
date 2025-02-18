using QuadGK

# Energy loss expressions
"""
An abstract type to describe kinetic energy loss by electrons. 
"""
abstract type BetheEnergyLoss end

"""
The Bethe algorithm of kinetic energy loss by electrons.
"""
struct Bethe <: BetheEnergyLoss end

"""
The Joy-Luo algorithm of Bethe kinetic energy loss by electrons.
SCANNING Vol. 11, 176-180 (1989) 
"""
struct JoyLuo <: BetheEnergyLoss end


"""
D. B. Brown's, Naval Research Lab, electron stopping power algorithm from
the Handbook of Spectroscopy Vol 1, 1974
"""
struct DBBrown <: BetheEnergyLoss end

"""
	dEds(::Type{<:BetheEnergyLoss}, e::Float64, elm::Element, ρ::Float64; mip::Type{<:NeXLMeanIonizationPotential}=Berger1982)
	dEds(::Type{<:BetheEnergyLoss}, e::Float64, mat::Material, inclDensity=true; mip::Type{<:NeXLMeanIonizationPotential}=Berger1982)

Calculate the loss per unit path length for an electron in the specified element and density.  The results in energy
loss in eV/cm.  Implemented by `Type{Bethe}` and `Type{JoyLuo}`.
"""
dEds(
	::Type{Bethe},
	e::Float64,
	elm::Element,
	ρ::Float64,
	mip::Type{<:NeXLMeanIonizationPotential} = Berger1982,
) = (-785.0e8 * ρ * z(elm)) / (a(elm) * e) * log(1.166e / J(mip, elm))


function dEds(
	::Type{JoyLuo},
	e::Float64,
	elm::Element,
	ρ::Float64,
	mip::Type{<:NeXLMeanIonizationPotential} = Berger1982,
)
	# Zero allocation
	k = 0.731 + 0.0688 * log(10.0, z(elm))
	j = J(mip, z(elm))
	jp = j / (1.0 + k * j / e)
	return ((-785.0e8 * ρ * z(elm)) / (a(elm) * e)) * log(1.166 * e / jp)
end

function dEds(
	ty::Type{<:BetheEnergyLoss},
	e::Float64,
	mat::Material,
	mip::Type{<:NeXLMeanIonizationPotential} = Berger1982,
)
	ρ = density(mat)
	return sum(keys(mat)) do el
		dEds(ty, e, el, ρ, mip) * mat[el]
	end
end


function dEds(
	::Type{DBBrown},
	e::Float64,
	mat::Material,
	mip::Type{<:NeXLMeanIonizationPotential} = Berger1982,
)
	v = 0.001 * e # To keV
	γ = v / 511.0 + 1.0
	β = sqrt(1.0 - 1.0 / γ)
	density(mat) * 3.076e5 / (β^2) * sum(keys(mat)) do el
		(mat[el] * z(el) / a(el, mat)) * (
			log(v * sqrt(γ + 1) / J(mip, el)) + 0.153 - 0.5 * β^2 + 0.0625 * ((γ - 1.0) / γ)^2 - 0.693 * ((2.0 * γ - 1.0) / (2.0 * γ^2))
		)
	end
end

"""
	range(::Type{BetheEnergyLoss}, mat::Material, e0::Float64, inclDensity = true)

Calculates the electron range using numeric quadrature of a BetheEnergyLoss algorithm (in cm).
"""
Base.range(
	ty::Type{<:BetheEnergyLoss},
	mat::Material,
	e0::Float64,
	inclDensity = true;
	emin = 50.0,
	mip::Type{<:NeXLMeanIonizationPotential} = Berger1982,
) =
	quadgk(e -> 1.0 / dEds(ty, e, mat, mip), e0, emin, rtol = 1.0e-6)[1] *
	(inclDensity ? 1.0 : density(mat))

struct Kanaya1972 end

"""
	range(::Type{Kanaya1972}, mat::Material, e0::Float64, inclDensity = true)

Calculates the Kanaya-Okayama electron range (in cm)
Kanaya K, Okayama S (1972) Penetration and energy-loss theory of electrons in solid targets. J Appl Phys 5:43
"""
function Base.range(::Type{Kanaya1972}, mat::Material, e0::Float64, inclDensity = true)
	ko(elm, e0) = 0.0276 * a(elm) * (0.001 * e0)^1.67 / z(elm)^0.89
	return (1.0e-4 / mapreduce(elm -> mat[elm] / ko(elm, e0), +, keys(mat))) /
		   (inclDensity ? density(mat) : 1.0)
end
