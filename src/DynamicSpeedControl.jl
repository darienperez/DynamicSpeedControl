module DynamicSpeedControl
# Dynamically load all modules from `src`
# push!(LOAD_PATH, joinpath(pwd(), "src"))
using Revise
using ArchGDAL: read, height, width, getgeotransform
using Clustering: SqEuclidean, clustering_quality
#using ColorTypes 
using Colors: RGB, N0f8
using DataFrames: DataFrame
#using GLMakie
#using GaussianMixtures
using Images: colorview, Lab
#using Interpolations
#using LinearAlgebra
import MLJ: predict, Machine, machine, fit!, transform, matrix, table, fitted_params, @load
KMedoids = @load KMedoids pkg=Clustering verbosity=0
PCA = @load PCA pkg=MultivariateStats verbosity=0
#using Plots
#using PlotlyJS
#using PlutoPlotly
using StatsBase: mean, std, Random.seed!
#using Statistics
#using FileIO

export 

# Workflow
initialize,
visuals,
classify,
InitState,
UseDict,

# RasterProcessing
PixelProcessor,
sample_pp,
load_raster_data,
sample_lab_pixels,
segment,
extract,
toimg,
densities,

# Clustering
ClusteredState,
ClusterQualities,
cluster,
clusters,
standardize!,
cluster_gmm,
evaluate_quality,

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

# src files
include(joinpath(@__DIR__, "main.jl"))
include(joinpath(@__DIR__, "clusters.jl"))
include(joinpath(@__DIR__, "raster_processing.jl"))
include(joinpath(@__DIR__, "speed_mapping.jl"))
include(joinpath(@__DIR__, "trajectory_planning.jl"))
include(joinpath(@__DIR__, "plotting.jl"))

end