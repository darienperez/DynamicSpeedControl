module DynamicSpeedControl
# Dynamically load all modules from `src`
# push!(LOAD_PATH, joinpath(pwd(), "src"))
using Revise
using AppleAccelerate
using ArchGDAL: read, readraster,height, width, getdriver, getgeotransform, setgeotransform!,
getproj, setproj!, create, getband, write!, nraster, IDataset
using Clustering: SqEuclidean, clustering_quality
#using ColorTypes
using DataFrames: DataFrame, transform!, nrow, ncol, select!, Not, unique!, ByRow
#using GLMakie
#using GaussianMixtures: GMM, em!, llpg, loglikelihood, n_components, kind
using Images: colorview, channelview, Lab, RGB, RGBA, N0f8
cyan = RGB(0,1,1); yellow = RGB(1,1,0); magenta = RGB(1,0,1);
red = RGB(1,0,0); blue = RGB(0,0,1); green = RGB(0,1,0); white = RGB(1,1,1);
black = RGB(0,0,0)
#using Interpolations
using LazIO
#using LinearAlgebra
import MLJ: Standardizer, predict, Machine, machine, fit!, transform, matrix, table, fitted_params, @load
KMedoids = @load KMedoids pkg=Clustering verbosity=0
PCA = @load PCA pkg=MultivariateStats verbosity=0
#using Plots
#using PlotlyJS
#using PlutoPlotly
using StatsBase: sample, mean, std, Random.seed!
#using Statistics
using FileIO

# src files
include(joinpath(@__DIR__, "main.jl"))
include(joinpath(@__DIR__, "las.jl"))
include(joinpath(@__DIR__, "clusters.jl"))
include(joinpath(@__DIR__, "raster_processing.jl"))
include(joinpath(@__DIR__, "speed_mapping.jl"))
include(joinpath(@__DIR__, "trajectory_planning.jl"))
include(joinpath(@__DIR__, "plotting.jl"))

export 

# Workflow
initialize,
visuals,
classify,
InitState,
UseDict,
Coords,
UseGMM,

# RasterProcessing
cyan, yellow, magenta, red, blue, green, white, black,
PixelProcessor,
sample_pp,
load_raster_data,
load_data,
apply_filter!,
segment,
extract,
filter_bg,
toimg,
densities,
saveGTiff,
NoWhites,
lengths,
repair!,
getdoids,

# Clustering
ClusteredState,
ClusterQualities,
cluster,
# clusters,
standardize!,
# bic,
evaluate_quality,
qualities,
ksfromquals,

# Working with LiDAR data
laspath,
trainKmed,
trainPCA,
write_las,
# make_Points3!,
make_df,
transform_df!,
sample_df,
classify_las,
change_labels!,

# SpeedMapping
map_speeds,

# Plotting
generate_plots, 
plot_lawnmower_path,
plot_data,
IsLAB,
IsRGB,
IsPCA,
IsQuality,
Is2D,

# Trajectory Planning
waypoints, 
LawnMowerGenerator, 
ContourGenerator
end