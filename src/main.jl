
struct PixelProcessor
    mat_lab::Matrix{Float32}
    # mat_rgb::Matrix{Float32}
    coords::Matrix{Float64}
end

struct InitState
    raster_data::NamedTuple
    processor::PixelProcessor
end

struct ClusteredState
    init::InitState
    space::Symbol
    features::AbstractMatrix
    sampled_features::AbstractMatrix
    pca::Machine
    kmeds::Dict{Int,Machine}
    labels::Dict{Int,Vector{Int}}
end

struct ClusterQualities
    dunn::Vector{}
    silhouettes::Vector{}
    calinski_harabasz::Vector{}
    xie_beni::Vector{}
    davies_bouldin::Vector{}
end

function initialize(;path::Union{AbstractString, Nothing}=nothing)
    if isnothing(path)
        path = "/Users/darien/Desktop/Academia/Research/UAV Applications/Dr. Jacob's Research/Code/Julia/DynamicSpeedControl/data/rasters/processed/ortho_2_20_2021_uncorrected_6348_NAD83_19N.tif"
    end
    rd = load_raster_data(path)
    pp = PixelProcessor(rd.img, rd.geotransform)
    InitState(rd, pp)
end

struct UseDict end

function initialize(::UseDict;
    raster_path = "data/rasters/processed/ortho_2_20_2021_uncorrected_6348_NAD83_19N.tif",
    num_samples = 10_000
    )

    init = Dict()
    
    raster_data = load_raster_data(raster_path)
    init[:raster_data] = raster_data
    img, gt = raster_data.img, raster_data.geotransform
    init[:px_data] = pixel_data(img, gt)
    X_standard = copy(init[:px_data].X)
    Xrgb_standard = copy(init[:px_data].Xrgb)
    init[:standardized] = 
        Dict(
            :X => standardize!(X_standard),
            :Xrgb => standardize!(Xrgb_standard)
        )

    rng = seed!(123)
    data_range = range(1, size(init[:standardized][:X], 1))
    idx = sample(rng, data_range, num_samples, replace=false)
    init[:sampled] = 
        Dict(
            :X => init[:standardized][:X][idx, :],
            :Xrgb => init[:standardized][:Xrgb][idx, :]
        )

    init[:tables] = 
        Dict(
            :X => table(init[:sampled][:X]),
            :Xrgb => table(init[:sampled][:Xrgb])
        )
    
    init
end


function visuals(initialized::NamedTuple)
    generate_plots(initialized)
    #plot_lawnmower_path(initialized)
end

function visuals(clustered::Dict, flags)
    plots = []
    for flag in flags
        if flag isa Tuple
            plot = plot_data(clustered, flag...)
            push!(plots, plot)
        else
            plot = plot_data(clustered, flag)
            push!(plots, plot)
        end
    end
    plots
end

function classify(path::AbstractString; k::Int=2, N::Int=10_000)
    kf_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_01_23.tif"
    kf2_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_02_06.tif"

    println("Sampling image and generating feature matrix and bands...")
    X, bands = sample_p(path, N=N)
    println("Done!")

    # Standardize
    println("Standardizing feature matrix and bands...")
    standardize!(X)
    standardize!(bands)
    println("Done!")

    # Do PCA and train kmed model
    println("Performing PCA...")
    pca = PCA(maxoutdim=3)
    pcamach = machine(pca, DataFrame(X, [:R, :G, :B])) |> fit!
    println("Done!")

    println("Training K-Medoids model with k=$k ...")
    kmed = KMedoids(k=k)
    kmedmach = machine(kmed, DataFrame(X, [:R, :G, :B])) |> fit!

    # Apply PCA to bands and predict labels
    println("Appling PCA to bands of full image...")
    pcabands = transform(pcamach, DataFrame(bands, :auto))
    println("predicting labels for full image")
    labels = transform(kmedmach, pcabands)
    println("Done!")

    Int.(labels.refs)
end