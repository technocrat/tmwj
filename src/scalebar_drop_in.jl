using Accessors:  @modify, @set # ↪ gives you @modify (and @optic, @set, …)
using Unitful: unit                  # for u"km" etc. must be before MakieExtra
using CairoMakie, GeoMakie     # for Figure, GeoAxis, lines!, etc
import IntervalArithmetic: sup, inf
using GeometryBasics
import Makie: @lift            # ↪ brings @lift into Main so your reactiv`e code will compile
import RecipesBase: @recipe    # ↪ if you happen not to already have @recipe
import MakieExtra: scalebar     # ↪ pull in the original recipe so you can override it
import DataPipes: @p




# Define both methods
sup(x::IntervalSets.ClosedInterval{T}) where T = x.right
inf(x::IntervalSets.ClosedInterval{T}) where T = x.left

# Local function for interval width to avoid ambiguity
_intervalwidth(iv) = sup(iv) - inf(iv)


"""    geoscalebar(scale; kwargs...)

Add a scalebar to a GeoAxis plot.

Supports all `lines()` and `text()` attributes, forwarding them to the respective plot calls.
The `position` attribute defines the position of the scalebar in relative `Axis` coordinates.
The `target_ax_frac` attribute defines the fraction of the axis width the scalebar should span.
The multiple of `scale` will be chosen automatically (from `muls`) so that the scalebar length is closest to `target_ax_frac`.

Typically, `scale` is a `Unitful` quantity that defines the size of one plot unit.
For example, `geoscalebar!(1u"mm")` means that the plot units are millimeters.
Alternatively, `scale` can be a tuple `(number, function)` where `function` is called for the string representation.
"""
@recipe GeoScalebar (scale,) begin
    # Set default attributes directly
    color = :black
    cycle = nothing
    position = Vec2(0.85f0, 0.08f0)
    target_ax_frac = 0.2f0
    muls = [p isa Int ? x*p : round(x*p, sigdigits=4)
        for p in Real[[10.0^p for p in -50:-1]; [1, 10, 100, 1000, 10000]; [10.0^p for p in 5:50]]
        for x in [1, 2, 5]]
end

Makie.data_limits(::GeoScalebar) = Rect3f(Point3f(NaN), Vec3f(NaN))
Makie.boundingbox(::GeoScalebar, space::Symbol=:data) = Rect3f(Point3f(NaN), Vec3f(NaN))

function Makie.plot!(p::GeoScalebar)
    scene = Makie.parent_scene(p)

    # ─── 1) Unwrap all of the Observables immediately ────────────────────────────
    # p.scale, p.muls, p.target_ax_frac, etc. are all Observables{…}, so we do:
    scale          = p.scale[]             # Quantity{…} 
    muls           = p.muls[]              # Vector{<:Real}
    target_ax_frac = p.target_ax_frac[]    # Real
    color          = p.color[]             # Color or Symbol
    cycle          = p.cycle[]             # maybe nothing or a cycle
    position       = p.position[]          # Vec2 or Point2

    # ─── 2) Get the projected x‐limits in 2D ─────────────────────────────────────
    # projview_to_2d_limits still returns an Observable, so unwrap that too:
    rect   = Makie.projview_to_2d_limits(p)[]  
    origin = rect.origin     # 2‐vector of minima
    widths = rect.widths     # 2‐vector of spans
    xlims  = Interval(origin[1], origin[1] + widths[1])

    # ─── 3) Choose the “best” multiple so that the bar spans ~target_ax_frac of axis ──
    units_in_data = ustrip(scale)  # strip the units
    diffs = abs.(1/units_in_data .* muls .- target_ax_frac * _intervalwidth(xlims))
    best = argmin(diffs)
    mul  = muls[best]

    # ─── 4) Compute the two end‐points & the label ────────────────────────────────
    length_data = mul / units_in_data
    length_ax   = length_data / _intervalwidth(xlims)
    p₁ = position .- Vec2(length_ax/2, 0)
    p₂ = position .+ Vec2(length_ax/2, 0)
    label = _scalebar_str(scale, mul)

    # ─── 5) Draw once ──────────────────────────────────────────────────────────────
    lines!(
      scene, Point2[p₁, p₂];
      color=color, cycle=cycle, space=:relative,
      xautolimits=false, yautolimits=false,
    )
    text!(
      scene, label;
      position=position,
      color=color,
      align=(:center, :top),
      space=:relative,
      xautolimits=false,
      yautolimits=false,
    )

    return p
end


units_in_dataunit(x::Number) = ustrip(x)
units_in_dataunit(x::Tuple) = units_in_dataunit(x[1])

_scalebar_str(scale::Quantity, mul) = "$mul $(unit(scale))"
_scalebar_str(scale::Tuple{<:Number,<:Function}, mul) = scale[2](mul) 