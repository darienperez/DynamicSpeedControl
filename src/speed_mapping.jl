# const DENSITY_BINS = [5000, 10000, 20000, 30000, 40000, Inf]
# const SPEED_VALUES = [10, 8, 6, 4, 2, 1]

# function map_speeds(densities)
#     map(density -> SPEED_VALUES[findfirst(density .< DENSITY_BINS)], densities)
# end

function map_speeds(pixels::NamedTuple, maxspeed)
    ϵ = 0.25 
    d = pixels.densities
    d_min, d_max = minimum(d), maximum(d)
    norm_d = @. (d - d_min) / (d_max - d_min)
    scaled_d = @. maxspeed * -norm_d + maxspeed
    #scaled_d = @. minimum([scaled_d, maxspeed])
    (speeds=scaled_d, norm_density=norm_d, pixels=pixels)
end

function map_speeds(waypoints::Dict, step::Number)
    speeds = waypoints[:speeds]
    waypoints[:cspeeds] = @. round(speeds / step) * step
end