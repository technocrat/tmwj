using CairoMakie, GeoMakie
using Unitful                   # for u"km"
using GeometryBasics
import GeometryBasics: Vec2, Vec3f, Point3f


function geoscalebar!(
    ax::GeoAxis,
    scale::Quantity;                   # e.g. 1u"km"
    muls        = [1,2,5,10,20,50,100,200,500,1000],
    target_frac = 0.2,                # fraction of axis width
    position    = Vec2(0.85, 0.08),   # rel coords in axis
    color       = :black,
    linewidth   = 2,
)
    # 1) extract the two “x” clip‐space points and get min/max
    pv   = ax.scene.camera.projectionview[]       # 4×4 matrix
    xs   = (((-1, 1) .- pv[1,4]) ./ pv[1,1])      # two Float32 values
    min_x, max_x = minimum(xs), maximum(xs)
    Δ      = max_x - min_x

    # 2) pick the best‐fit multiple so that (m/units) ≈ target_frac*Δ
    units_in_data = ustrip(scale)
    diffs         = abs.((muls ./ units_in_data) .- (target_frac * Δ))
    mul           = muls[argmin(diffs)]

    # 3) compute relative half‐length, then lift to 3D
    half_ax = ( (mul/units_in_data) / Δ ) / 2
    c       = position
    p1 = GeometryBasics.Point3f(c[1] - half_ax, c[2], 0f0)
    p2 = GeometryBasics.Point3f(c[1] + half_ax, c[2], 0f0)

    # 4) draw once in 3D, disable all auto‐limits
    lines!(
      ax, [p1, p2];
      color       = color,
      linewidth   = linewidth,
      space       = :relative,
      xautolimits = false,
      yautolimits = false,
      zautolimits = false,
    )
    text!(
      ax,
      "$(mul) $(unit(scale))";      # inline label function
      position   = GeometryBasics.Point3f(c[1], c[2], 0f0),
      color      = color,
      align      = (:center, :top),
      space      = :relative,
      xautolimits= false,
      yautolimits= false,
      zautolimits= false,
    )

    return nothing
end
