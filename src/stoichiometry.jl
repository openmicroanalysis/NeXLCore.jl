const valence = (  1, 0, 1, 2, 3, 4, 5, -2, 1, 0, 1, 2, 3, 4, 5, 6, 5, 0, 1, 2, 3, 4,
                   5, 2, 2, 2, 2, 2, 2, 2, 3, 4, 3, 6, 5, 0, 1, 2, 3, 4, 5, 6, 2, 4,
                   4, 2, 1, 2, 3, 2, 3, 4, 5, 0, 1, 2, 3, 4, 3, 3, 3, 3, 3, 3, 3, 3,
                   3, 3, 3, 3, 3, 4, 5, 6, 4, 4, 4, 4, 3, 2, 1, 2, 3, 4, 5, 0, 1, 2,
                   3, 4, 5, 4, 4, 4 )


"""
    asoxide(elm::Element, val = valence)

Compute the oxidized form of the specified element using the valences provided in `val`.  By default,
`val = NeXLCore.valences`, a typical set of valences.
"""
function asoxide(elm::Element; valence = valence, name=missing, atomicweights::Dict{Element,<:AbstractFloat}=Dict{Element,Float64}())
    function buildoxidefraction(elm, val)
        den = gcd(val[z(elm)], -val[z(n"O")])
        return ( n"O" => val[z(elm)] ÷ den,
                             elm => -val[z(n"O")] ÷ den)
    end
    function buildoxidename(elm, val)::String
        nn(n) = n>1 ? "$(n)" : ""
        den = gcd(val[z(elm)], -val[z(n"O")])
        ne, no = -val[z(n"O")] ÷ den, val[z(elm)] ÷ den
        return "$(symbol(elm))$(nn(ne))O$(nn(no))"
    end
    name = ismissing(name) ? buildoxidename(elm, valence) : name
    return atomicfraction(name, buildoxidefraction(elm, valence)..., atomicweights=atomicweights)
end

"""
    asoxide(elms::Pair{Element, <:AbstractFloat}...; valence = valence, name::Union{AbstractString,Nothing}=nothing)
    asoxide(elms::Dict{Element, <:AbstractFloat}...; valence = valence, name::Union{AbstractString,Nothing}=nothing)

Compute a mixture of the oxidized forms of the specified elements using the valences provided in `val`.
By default, `val = NeXLCore.valences`, a typical set of valences.
"""
function asoxide(elms::Dict{Element, <:AbstractFloat}; valence = valence, name::Union{AbstractString,Nothing}=nothing, atomicweights::Dict{Element,<:AbstractFloat}=Dict{Element,Float64}())
    bname = isnothing(name) ?
        join((repr(qty)*asoxide(elm,valence=valence).name for (elm, qty) in elms),"+") : name
    mats = ( massfraction(qty*asoxide(elm, valence=valence, atomicweights=atomicweights)) for (elm, qty) in elms )
    return material(bname, merge(+,mats...))
end
asoxide(elms::Pair{Element, <:AbstractFloat}...; valence = valence, name::Union{AbstractString,Nothing}=nothing, atomicweights::Dict{Element,<:AbstractFloat}=Dict{Element,Float64}()) =
    asoxide(Dict(elms), valence=valence, name=name, atomicweights=atomicweights)

"""
    obystoichiometry(elms::Pair{Element, <:AbstractFloat}, valence = valence)

Compute O-by-stoichiometry from the provided mass fractions of elements.
"""
obystoichiometry(elms::Pair{Element, <:AbstractFloat}...; valence = valence) =
    sum(f*(-valence[z(elm)]*a(n"O"))/(a(elm)*valence[z(n"O")]) for (elm,f) in elms)
