function PixelProcessor(img::T, gt::Vector{<:Real}) where {T}
    H, W = size(img)

    # Lab features
    cv_lab = channelview(Lab.(img))
    mat_lab = Float32.(reshape(cv_lab, 3, H*W)')

    # RGB features
    # cv_rgb = channelview(img)
    # mat_rgb = Float32.(reshape(cv_rgb, 3, H*W)')

    # Spatial Coordinates
    originX, pixelW, _, originY, _, pixelH = gt
    xs = originX .+ (0:W-1) .* pixelW
    ys = originY .+ (0:H-1) .* pixelH
    # make two 1×(H*W) vectors of coords
    Xs = repeat(xs, inner=H)     # length H*W
    Ys = repeat(ys, outer=W)     # length H*W
    coords = hcat(Xs, Ys)

    PixelProcessor(mat_lab, coords)
end

function load_raster_data(path::AbstractString)
    read(path) do ds
        # 1) Geo-metadata
        gt = getgeotransform(ds)
        dx, dy = gt[2], gt[6]

        # 2) Raw bands
        b1 = read(ds,1)
        b2 = read(ds,2)
        b3 = read(ds,3)

        # 3) Build an Images.jl RGB image
        r = N0f8.(b1 ./ 255)
        g = N0f8.(b2 ./ 255)
        bl= N0f8.(b3 ./ 255)
        img = colorview(RGB, r, g, bl)

        (img=img, geotransform=gt, dx=dx, dy=dy)
    end
end

function sample_pp(X::AbstractMatrix; N::Int = 10_000)
    rng = seed!(123)
    # 1) pick N random indices without replacement
    idx = randperm(rng, size(X, 1))[1:N]
    # 2) return the corresponding rows
    X[idx, :]
end

function extract(path::AbstractString)
    read(path) do ds
        imgbands = read(ds, (1,2,3))
        bands = reshape(imgbands, width(ds)*height(ds), 3)
        return (Float32.(bands), imgbands)
    end
end

function extract(path::AbstractString, ::Coords)
    read(path) do ds
        W, H = width(ds), height(ds)
        # Spatial Coordinates
        originX, pixelW, _, originY, _, pixelH = getgeotransform(ds)
        xs = originX .+ (0:W-1) .* pixelW
        ys = originY .+ (0:H-1) .* pixelH
        # make two 1×(H*W) vectors of coords
        Xs = repeat(xs, inner=H)     # length H*W
        Ys = repeat(ys, outer=W)     # length H*W

        imgbands = read(ds, (1,2,3))
        features = reshape(imgbands, W*H, 3) |> x -> hcat(x, Xs, Ys)
        (Float32.(features), imgbands)
    end
end

function extract(path::AbstractString, ::IsLAB)
    read(path) do ds
        println("ArchGDAL.IDataset assigned to ds")
        imgbands = read(ds, (1,2,3)) 
        img = toimg(imgbands) 
        bands = Lab.(img) |> channelview
        println("imgbands should now be in LAB space")
        W, H = width(ds), height(ds)
        println("width and height of ds assigned to W, H")
        bands = reshape(bands, 3, W*H)'
        println("bands shaped to size ($(W*H), 3)")
        return (Float32.(bands), imgbands)
    end
end

function extract(path::AbstractString, N::Int)
    read(path) do ds
        imgbands = read(ds, (1,2,3))
        W, H = width(ds), height(ds)
        bands = reshape(imgbands, W*H, 3)
        nowhiteblack(r) = (r != UInt8(0)) & (r != UInt8(255))
        idxs = reshape(all(row -> nowhiteblack(row), bands, dims=2), :)
        X = sample(
            bands[idxs, :],
            (N, 3),
            replace=false)
        return (Float32.(X), W, H)
    end
end

function extract(path::AbstractString, blocksize::Int, N::Int)
    # rng = MersenneTwister(1)
    read(path) do ds
        # gt = getgeotransform(ds)
        W, H = width(ds), height(ds)
        # generate a 3×N sample for each tile, then pack them all into one big matrix
        samples = (
            begin
                # compute zero-based window
                xoff = x0 - 1
                yoff = y0 - 1
                xlen = min(blocksize, W - xoff)
                ylen = min(blocksize, H - yoff)

                # read, permute and reshape
                tile = read(ds, (1,2,3), xoff, yoff, xlen, ylen)
                # tile = Base.PermutedDimsArray(tile, (3,1,2))
                tile = reshape(tile, xlen*ylen, 3)
                
                # draw N random pixels
                sample(Float32.(tile), (N, 3), replace=false)
            end
            for y0 in 1:blocksize:H, x0 in 1:blocksize:W
        )

        # one single allocation of the final 3×(num_tiles*N) matrix
        S = collect(samples)
        vcat(S...)
    end # do block
end

function extract(path::AbstractString, N::Int, ::Coords)
    read(path) do ds
        W, H = width(ds), height(ds)
        # Spatial Coordinates
        originX, pixelW, _, originY, _, pixelH = getgeotransform(ds)
        xs = originX .+ (0:W-1) .* pixelW
        ys = originY .+ (0:H-1) .* pixelH
        # make two 1×(H*W) vectors of coords
        Xs = repeat(xs, inner=H)     # length H*W
        Ys = repeat(ys, outer=W)     # length H*W

        imgbands = read(ds, (1,2,3))
        bands = reshape(imgbands, W*H, 3)

        nowhiteblack(r) = (r != UInt8(0)) & (r != UInt8(255))
        mask = reshape(all(row -> nowhiteblack(row), bands, dims=2), :)
        features = hcat(bands, Xs, Ys)
        idxs = sample(findall(mask), N)
        
        return Float32.(features[idxs, :])
    end
end

function extract(path::AbstractString, N::Int, ::IsLAB)
    println("sampling in LAB space $N times...")
    read(path) do ds
        println("ArchGDAL.IDataset assigned to ds")
        imgbands = read(ds, (1,2,3)) |> toimg |> x -> Lab.(x) |> channelview
        println("imgbands should now be in LAB space")
        W, H = width(ds), height(ds)
        println("width and height of ds assigned to W, H")
        bands = reshape(imgbands, 3, W*H)'
        println("bands shaped to size ($(W*H), 3)")
        d = size(bands)[2]
        println("feature depth is $d")

        println("sampling bands $N times after filtering black background")
        nowhiteblack(r) = (r != UInt8(0)) & (r != UInt8(255))
        mask = reshape(all(row -> nowhiteblack(row), bands, dims=2), :)
        idxs = sample(findall(mask), N)
       
        return Float32.(bands[idxs, :])
    end
end

function extract(img::Matrix{RGB{N0f8}})
    imgbands = channelview(img) |> x -> PermutedDimsArray(x, (2,3,1))
    W, H = size(imgbands)[1:2]
    bands = reshape(imgbands, W*H, 3)
    return Float32.(bands)
end

function extract(img::Matrix{RGB{N0f8}}, ::IsLAB)
    img = Lab.(img)
    imgbands = channelview(img) |> x -> PermutedDimsArray(x, (2,3,1))
    W, H = size(imgbands)[1:2]
    bands = reshape(imgbands, W*H, 3)
    return Float32.(bands)
end

function extract(img::Matrix{RGB{N0f8}}, N::Int)
    imgbands = channelview(img) |> x -> PermutedDimsArray(x, (2,3,1))
    W, H = size(imgbands)[1:2]
    bands = reshape(imgbands, W*H, 3)
    nowhiteblack(r) = (r !== UInt8(0)/UInt8(255)) & (r !== UInt8(255)/UInt8(255))
        idxs = reshape(all(row -> nowhiteblack(row), bands, dims=2), :)
        X = sample(
            bands[idxs, :],
            (N, 3),
            replace=false)
        return Float32.(X)
end

function toimg(imgbands::Array{UInt8, 3})
    # Convert to Matrix{RGB{N0f8}} and swap view of img dimensions for colorview()
    img = N0f8.(imgbands./255) |> x -> PermutedDimsArray(x, (3,1,2))
    GC.gc()
    colorview(RGB, img) 
end

function toimg(path::AbstractString)
    read(path) do ds
        imgbands = read(ds, (1,2,3))
        img = toimg(imgbands)
        return img
    end 
end

# extract(clustered::Dict) = begin
#     img = clustered[:raster_data].img
#     M = [clustered[:segs][c].labels_mat for c in keys(clustered[:segs])]
#     pixels = [
#         # for each matrix and each label…
#         ifelse.(mat .== label,           # mask: H×W of Bool
#                 img,                     # keep original pixel where mask==true
#                 zero(eltype(img)))      # else fill with “black” (zero of same type)
#         for mat   in M
#         for label in unique(mat)         # or minimum(mat):maximum(mat)
#     ]
#     pixels
# end

function segment(clustered::Dict; colorspace=:lab, kmed = :kmedoids2)
    img = clustered[:raster_data].img
    h, w = size(img)
    pca_mach = clustered[:machines][:pca][colorspace]
    if colorspace == :lab
        Xtrans = MLJ.transform(pca_mach, clustered[:standardized][:X])
    else
        Xtrans = MLJ.transform(pca_mach, clustered[:standardized][:Xrgb])
    end
    labels = MLJ.predict(clustered[:machines][kmed], Xtrans)
    labels_mat = reshape(Int.(labels.refs), h, w)
    segs = Dict{Symbol, Any}()
    segs[colorspace] = (Xtrans=Xtrans, labels_mat=labels_mat)
    clustered[:segs] = segs
end

function segment(
    cs::ClusteredState,
    cs_target::ClusteredState,
    k::Int;)
    # 1) pull out your original image and dims
    img = cs_target.init.raster_data.img
    H, W = size(img)

    # 2) build the full feature matrix exactly as in _cluster
    X = cs_target.features

    # 3) wrap as a table, then project with the exact PCA machine
    Xtbl = table(X)
    Xp   = matrix(transform(cs.pca, Xtbl))

    # 4) predict with the k‑medoids machine for this k
    mach = cs.kmeds[k]
    labs = Int.(predict(mach, Xp).refs)   # vector of length H*W

    # 5) reshape into H×W
    labels_mat = reshape(labs, H, W)

    return labels_mat
end

function densities(clustered::Dict)
    geotransform = clustered[:raster_data].geotransform
    dx, dy = clustered[:raster_data].dx, clustered[:raster_data].dy
    trees = extract(clustered)[2] |> (p -> findall(!=(zero(eltype(p))), p))
    x_coords = geotransform[1] .+ dx .* getindex.(trees, 2)
    y_coords = geotransform[4] .+ dy .* getindex.(trees, 1)

    x_edges = range(extrema(x_coords)..., length=50)
    y_edges = range(extrema(y_coords)..., length=50)
    hist = fit(Histogram, (x_coords, y_coords), (x_edges, y_edges))

    x_centers = midpoints(hist.edges[1])
    y_centers = midpoints(hist.edges[2])
    densities = reshape(hist.weights, length(x_centers), length(y_centers))

    clustered[:pixels] = (x=x_centers, y=y_centers, densities=densities, hist=hist)
end

function saveGTiff(orthopath::String, inraspath::String, outraspath::String)
    readraster(orthopath) do ds
        gt = getgeotransform(ds)
        proj_WGS84 = getproj(ds)
        drv = getdriver("GTiff")
        readraster(inraspath) do src_ds
            create(outraspath, driver=drv, width=width(ds), height=height(ds), nbands=3, dtype=UInt8) do out_ds
                for i in 1:3
                    src_band = getband(src_ds, i)
                    arr = read(src_band)
                    dst_band = getband(out_ds, i)
                    write!(dst_band, arr)
                    end
                setgeotransform!(out_ds, gt)
                setproj!(out_ds, proj_WGS84)
            end
        end
    end
end

function lengths(results::NamedTuple, cluster::NamedTuple)
    ls = 1:length(cluster.kmedmachs)
    [length(results.img[results.labels .== l]) for l in ls]
end