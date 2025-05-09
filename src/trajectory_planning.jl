
"""
Abstract type for waypoint extractors.
"""
abstract type AbstractWaypointGenerator end

"""
A LawnMowerGenerator specifies extraction of waypoints along a lawnmower path.
- interval: Determines the spacing between the rows used in the grid.
"""
struct LawnMowerGenerator <: AbstractWaypointGenerator
    interval::Int
    num_points::Int
end

"""
A ContourExtractor specifies extraction of waypoints along contour lines at specified density levels.
- levels: Array of density levels at which contours will be computed.
"""
struct ContourGenerator <: AbstractWaypointGenerator
    levels::Vector{Float64}
end

function waypoints(mapped::NamedTuple, extractor::LawnMowerGenerator)
    pixels = mapped.pixels
    x_centers = collect(pixels.x)
    #x_centers = reverse(x_centers)
    y_centers = mapped.pixels.y
    speeds = mapped.speeds
    
    # Create a 2D interpolation of the speeds (pixel density)
    itp = interpolate(speeds', BSpline(Linear()))
    itp = scale(itp, pixels.x, pixels.y)

    waypoints = Dict(:x => [], :y => [], :speeds => [])
    interval = extractor.interval
    n = extractor.num_points

    # Generate lawnmower path with fixed intervals in both x and y directions
    for (i, y) in enumerate(y_centers[1:interval:end])
        xs = isodd(i) ? x_centers[1:end] : reverse(x_centers[1:end])
        xs = range(xs[1], xs[end], n)
        for x in xs
            itpspeeds = itp(x, y)
            push!(waypoints[:x], x)
            push!(waypoints[:y], y)
            push!(waypoints[:speeds], itpspeeds)
        end
    end

    return waypoints
end

waypoints(waypoints::Dict, step::Number) = begin
    wps = waypoints
    wps[:cspeeds] = map_speeds(wps, step)
    speeds = wps[:cspeeds]
    change_idxs = findall(diff(speeds) .!== 0.0)
    wps[:starts] = [1; change_idxs .+ 1]
    wps[:ends] = [change_idxs; length(speeds)]
    wps[:keep] = sort(unique(vcat(wps[:starts], wps[:ends])))
    wps[:rspeeds] = wps[:cspeeds][wps[:keep]]
end

"""
    extract_waypoints(x_centers, y_centers, speeds, extractor::ContourExtractor)

Extracts waypoints based on the contours of the pixel density. Instead of sampling on a fixed grid,
this function computes contour lines at specified density levels and returns waypoints along these contours.

# Arguments
- x_centers: Array of x-coordinates.
- y_centers: Array of y-coordinates.
- speeds: 2D matrix of pixel densities.
- extractor: A ContourExtractor specifying the density levels for contour extraction.

# Returns
- waypoints: List of (x, y, level) tuples representing waypoints along each contour.
"""
function extract_waypoints(x_centers, y_centers, speeds, extractor::ContourGenerator)

end