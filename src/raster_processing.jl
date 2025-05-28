PixelProcessor(img, gt) = begin
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

function sample_pp(X::AbstractMatrix; N::Int = 10_000)
    rng = seed!(123)
    # 1) pick N random indices without replacement
    idx = randperm(rng, size(X, 1))[1:N]
    # 2) return the corresponding rows
    X[idx, :]
end


function load_raster_data(path::AbstractString)
    ArchGDAL.read(path) do ds
        # 1) Geo-metadata
        gt = ArchGDAL.getgeotransform(ds)
        dx, dy = gt[2], gt[6]

        # 2) Raw bands
        b1 = ArchGDAL.read(ArchGDAL.getband(ds,1))
        b2 = ArchGDAL.read(ArchGDAL.getband(ds,2))
        b3 = ArchGDAL.read(ArchGDAL.getband(ds,3))

        # 3) Build an Images.jl RGB image
        r = N0f8.(b1 ./ 255)
        g = N0f8.(b2 ./ 255)
        bl= N0f8.(b3 ./ 255)
        img = colorview(RGB, r, g, bl)

        (img=img, geotransform=gt, dx=dx, dy=dy)
    end
end

function pixel_data(img, gt)
    H, W = size(img)
    # 1) color‐convert to Lab and get a 3×H×W array
    cv = channelview(Lab.(img))     # dims = (3, H, W)
    lab = reshape(cv, 3, H*W)
    cvrgb = channelview(img)
    rgb = reshape(cvrgb, 3, H*W)

    # 2) compute real‐world X,Y for each column
    #    GT tuple is (originX, pixelW, rotX, originY, rotY, pixelH)
    originX, pixelW, _, originY, _, pixelH = gt
    xs = originX .+ (0:W-1) .* pixelW
    ys = originY .+ (0:H-1) .* pixelH
    # make two 1×(H*W) vectors of coords
    Xs = repeat(xs, inner=H)     # length H*W
    Ys = repeat(ys, outer=W)     # length H*W

    # 4) pull out the features and coords
    feat = Float32.(lab')   # N×3
    coords = hcat(Xs, Ys)         # N×2
    X = hcat(feat, coords)
    featrgb = Float32.(rgb')
    Xrgb = hcat(featrgb, coords)
    return (X=X, Xrgb=Xrgb)
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

extract(clustered::Dict) = begin
    img = clustered[:raster_data].img
    M = [clustered[:segs][c].labels_mat for c in keys(clustered[:segs])]
    pixels = [
        # for each matrix and each label…
        ifelse.(mat .== label,           # mask: H×W of Bool
                img,                     # keep original pixel where mask==true
                zero(eltype(img)))      # else fill with “black” (zero of same type)
        for mat   in M
        for label in unique(mat)         # or minimum(mat):maximum(mat)
    ]
    pixels
end

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
    k::Int;
)
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