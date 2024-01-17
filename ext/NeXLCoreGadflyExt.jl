module NeXLCoreGadflyExt

using NeXLCore
using Gadfly
using Colors
using Pkg.Artifacts
using CSV
using Statistics
using CategoricalArrays

const NeXLPalette =
    convert.(
        RGB{Colors.N0f8},
        distinguishable_colors(
            66,
            [RGB(253 / 255, 253 / 255, 241 / 255), RGB(0, 0, 0), colorant"DodgerBlue4"],
            transform = deuteranopic,
        )[3:end],
    )

const NeXLColorblind = NeXLPalette

"""
    Gadfly.plot(transitions::AbstractVector{Transition}; mode=:Energy|:Weight, palette=NeXLPalette)

Plot either the `:Energy` or `:Weight` associated with the specified transitions over the range of supported elements.
"""
function Gadfly.plot(
    transitions::AbstractVector{Transition};
    mode = :Energy,
    palette = NeXLPalette,
)
    if mode == :Energy
        plotXrayEnergies(transitions, palette=palette)
    elseif mode == :Weight
        plotXrayWeights(transitions, palette=palette)
    end
end

function plotXrayEnergies(transitions::AbstractVector{Transition}; palette = NeXLPalette)
    layers, names, colors = [], String[], []
    for (tr, col) in zip(transitions, Iterators.cycle(palette))
        elems = filter(e->has(e, tr), eachelement())
        if !isempty(elems)
            push!(names, repr(tr))
            push!(colors, col)
            push!(layers, #
                Gadfly.layer(
                    x = [ z(e) for e in elems ],
                    y = [ energy(characteristic(e, tr)) for e in elems ],
                    Geom.point,
                    Gadfly.Theme(default_color = col),
                )
            )
        end
    end
    Gadfly.plot(
        layers...,
        Gadfly.Guide.title("Characteristic X-ray Energies"),
        Gadfly.Guide.manual_color_key("Type", names, color = colors),
        Gadfly.Guide.xlabel("Atomic Number"),
        Guide.ylabel("Energy (eV)"),
        Gadfly.Coord.cartesian(xmin = z(eachelement()[1]), xmax = z(eachelement()[end])),
    )
end

function plotXrayWeights(transitions::AbstractVector{Transition}; palette = NeXLPalette)
    layers, names, colors = [], String[], []
    for (tr, col) in zip(transitions, Iterators.cycle(palette))
        elems = filter(e->has(e,tr), eachelement())
        if !isempty(elems)
            push!(names, repr(tr))
            push!(colors, col)
            append!(
                layers,
                Gadfly.layer(
                    x = [ z(elm) for elm in elems ],
                    y = [weight(NormalizeByShell, characteristic(elm, tr)) for elm in elems ],
                    Geom.point,
                    Gadfly.Theme(default_color = col),
                )
            )
        end
    end
    Gadfly.plot(
        layers...,
        Gadfly.Guide.title("Characteristic X-ray Weights"),
        Gadfly.Guide.manual_color_key("Type", names, colors),
        Gadfly.Guide.xlabel("Atomic Number"),
        Guide.ylabel("Weight"),
        Gadfly.Scale.y_log10(),
        Gadfly.Coord.cartesian(xmin = z(eachelement()[1]), xmax = z(eachelement()[end])),
    )
end

"""
    Gadfly.plot(sss::AbstractVector{SubShell}, mode=:EdgeEnergy|:FluorescenceYield; palette=NeXLPalette)

Plot the edge energies/fluorescence yields associated with the specified vector of SubShell objects.
"""
function Gadfly.plot(sss::AbstractVector{SubShell}, mode = :EdgeEnergy)
    if mode == :FluorescenceYield
        plotFluorescenceYield(sss::AbstractVector{SubShell})
    else
        plotEdgeEnergies(sss)
    end
end

function plotFluorescenceYield(sss::AbstractVector{SubShell})
    layers, names = [], String[]
    colors = distinguishable_colors(
        length(sss) + 2,
        Color[RGB(253 / 255, 253 / 255, 241 / 255), RGB(0, 0, 0)],
    )
    for (i, sh) in enumerate(sss)
        elems = filter(e->has(e,sh), eachelement())
        if !isempty(elems)
            push!(names, repr(sh))
            append!(
                layers,
                Gadfly.layer(
                    x = [ z(elm) for elm in elems],
                    y = [ fluorescenceyield(atomicsubshell(elm, sh)) for elm in elems ],
                    Geom.point,
                    Gadfly.Theme(default_color = colors[i+2]),
                )
            )
        end
    end
    Gadfly.plot(
        layers...,
        Gadfly.Guide.title("Fluourescence Yield"),
        Gadfly.Guide.manual_color_key("Type", names, colors[3:end]),
        Gadfly.Guide.xlabel("Atomic Number"),
        Guide.ylabel("Yield (Fractional)"),
        Scale.y_log10(maxvalue = 1.0),
        Gadfly.Coord.cartesian(xmin = z(eachelement()[1]), xmax = z(eachelement()[end])),
    )
end


function plotEdgeEnergies(sss::AbstractVector{SubShell})
    layers, names = [], String[]
    colors = distinguishable_colors(
        length(sss) + 2,
        Color[RGB(253 / 255, 253 / 255, 241 / 255), RGB(0, 0, 0)],
    )
    for (i, sh) in enumerate(sss)
        elems = filter(e->has(e, sh), eachelement())
        if !isempty(elems)
            push!(names, repr(sh))
            append!(
                layers,
                Gadfly.layer(
                    x = [ z(elm) for elm in elems ],
                    y = [ energy(atomicsubshell(elm, sh)) for elm in elems ],
                    Geom.point,
                    Gadfly.Theme(default_color = colors[i+2]),
                )
            )
        end
    end
    Gadfly.plot(
        layers...,
        Gadfly.Guide.title("Atomic Sub-Shell Energies"),
        Gadfly.Guide.manual_color_key("Type", names, colors[3:end]),
        Gadfly.Guide.xlabel("Atomic Number"),
        Guide.ylabel("Edge Energy (eV)"),
        Gadfly.Coord.cartesian(xmin = z(eachelement()[1]), xmax = z(eachelement()[end])),
    )
end

"""
    compareMACs(elm::Element; palette=NeXLPalette)

Plot a comparison of the FFAST and Heinrich MAC tabulations for the specified Element.
"""
function compareMACs(elm::Element; palette = NeXLPalette)
    names = String[]
    layers = map( enumerate([DefaultAlgorithm, DTSA, ])) do (i, alg)
        push!(names, repr(alg))
        layer(
            ev -> log10(mac(elm, ev, alg)),
            100.0,
            20.0e3,
            Geom.line,
            Gadfly.Theme(default_color = palette[i]),
        )
    end
    Gadfly.plot(
        layers...,
        Gadfly.Guide.title("MAC - $elm"),
        Gadfly.Guide.manual_color_key("Type", ["Default/FFAST", "Heinrich"], palette[1:2]),
        Gadfly.Guide.xlabel("Energy (eV)"),
        Guide.ylabel("log₁₀(MAC (cm²/g))"),
        Gadfly.Coord.cartesian(xmin = 0.0, xmax = 20.0e3),
    )
end

"""
    plot(alg::Type{<:NeXLAlgorithm}, elm::Union{Element,Material}; palette = NeXLPalette, xmax=20.0e3)

Plot a MAC tabulations for the specified Element or Material.
"""
function Gadfly.plot(
    alg::Type{<:NeXLAlgorithm},
    elm::Union{Element,Material};
    palette = NeXLPalette,
    xmax = 20.0e3,
)
    l1 = layer(
        ev -> log10(mac(elm, ev, alg)),
        100.0,
        xmax,
        Geom.line,
        Gadfly.Theme(default_color = palette[1]),
    )
    Gadfly.plot(
        l1,
        Gadfly.Guide.title("MAC - $(name(elm))"),
        Gadfly.Guide.xlabel("Energy (eV)"),
        Guide.ylabel("log₁₀(MAC (cm²/g))"),
        Gadfly.Coord.cartesian(xmin = 0.0, xmax = xmax),
    )
end

"""
    compareMACs(elm::Element; palette=NeXLPalette)

Plot a comparison of the FFAST and Heinrich MAC tabulations for the specified Element or Material.
"""
function Gadfly.plot(
    alg::Type{<:NeXLAlgorithm},
    elms::AbstractVector;
    palette = NeXLPalette,
    xmin = 100.0,
    xmax = 20.0e3,
)
    layers, colors, names = Layer[], Color[], String[]
    for (i, elm) in enumerate(elms)
        append!(
            layers,
            layer(
                ev -> log10(mac(elm, ev, alg)),
                xmin,
                xmax,
                Geom.line,
                Gadfly.Theme(default_color = palette[i]),
            ),
        )
        push!(colors, palette[i])
        push!(names, name(elm))
    end
    Gadfly.plot(
        layers...,
        Gadfly.Guide.xlabel("Energy (eV)"),
        Guide.ylabel("log₁₀(MAC (cm²/g))"),
        Gadfly.Guide.manual_color_key("Material", names, colors),
        Gadfly.Coord.cartesian(xmin = max(0.0, xmin - 100.0), xmax = xmax),
    )
end

function Gadfly.plot(
    mats::AbstractVector{<:Material};
    known::Union{Material,Missing} = missing,
    delta::Bool = false,
    label::AbstractString = "Material",
    palette = NeXLPalette,
)
    allelms = collect(union(map(keys, mats)...))
    xs = [name(mat) for mat in mats]
    layers, names, colors = Layer[], String[], RGB{Float64}[]
    if ismissing(known)
        known = material(
            "the Mean",
            Dict{Element,Float64}(
                elm => mean([value(mat[elm]) for mat in mats]) for elm in allelms
            ),
        )
    end
    for (i, elm) in enumerate(allelms)
        if delta
            append!(
                layers,
                layer(
                    x = xs,
                    y = [value(mat[elm]) - known[elm] for mat in mats],
                    ymin = [value(mat[elm]) - σ(mat[elm]) - known[elm] for mat in mats],
                    ymax = [value(mat[elm]) + σ(mat[elm]) - known[elm] for mat in mats],
                    Gadfly.Theme(default_color = palette[i]),
                    Geom.errorbar,
                    Geom.point,
                ),
            )
        else
            append!(
                layers,
                layer(
                    x = xs,
                    y = [value(mat[elm]) for mat in mats],
                    ymin = [value(mat[elm]) - σ(mat[elm]) for mat in mats],
                    ymax = [value(mat[elm]) + σ(mat[elm]) for mat in mats],
                    Gadfly.Theme(default_color = palette[i]),
                    Geom.errorbar,
                    Geom.point,
                ),
            )
        end
        push!(names, name(elm))
        push!(colors, palette[i])
    end
    lighten(col) = weighted_color_mean(0.2, RGB(col), colorant"white")
    if delta
        plot(
            layers...,
            Guide.ylabel("Δ(Mass Fraction)"),
            Guide.xlabel(label),
            Guide.manual_color_key("Element", names, Colorant[colors...]),
            Guide.title("Difference from $(known)"),
            Geom.hline(color = "black"),
            yintercept = [0.0],
        )
    else
        plot(
            layers...,
            Guide.ylabel("Mass Fraction"),
            Guide.xlabel(label), #
            Guide.manual_color_key("Element", names, Colorant[colors...]),
            yintercept = [known[elm] for elm in allelms],
            Geom.hline(color = [lighten(col) for col in colors], style = :dash),
        )
    end
end

function plot2(
    mats::AbstractVector{<:Material};
    label::AbstractString = "Material",
    palette = NeXLPalette,
)
    allelms = sort(convert(Vector{Element}, collect(union(map(keys, mats)...))))
    elmcol = Dict(elm => palette[i] for (i, elm) in enumerate(allelms))
    xs, ymin, ymax, ygroups, colors = String[], Float64[], Float64[], Element[], Color[]
    for mat in mats
        append!(xs, [name(mat) for elm in keys(mat)])
        append!(ymin, [value(mat[elm]) - σ(mat[elm]) for elm in keys(mat)])
        append!(ymax, [value(mat[elm]) + σ(mat[elm]) for elm in keys(mat)])
        append!(colors, [elmcol[elm] for elm in keys(mat)])
        append!(ygroups, collect(keys(mat)))
    end
    plot(
        x = xs,
        ymin = ymin,
        ymax = ymax,
        color = colors,
        ygroup = ygroups,
        Geom.subplot_grid(Geom.errorbar, free_y_axis = true),
        Scale.ygroup(labels = elm -> symbol(elm), levels = allelms),
        Guide.xlabel(label),
        Guide.ylabel("Mass Fraction by Element"),
    )
end

disp(p) = display(Gadfly.GadflyDisplay(), p)

end # module