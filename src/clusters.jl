# import MLJ: predict

function standardize!(X::AbstractMatrix)
    for j in 1:(size(X,2))
        col = X[:,j]
        μ, σ = mean(col), std(col)
        X[:,j] = (col .- μ) ./ σ
    end
    return X
end

function _features(pp::PixelProcessor, space::Symbol;
    include_coords::Bool=true)
    M = space == :lab ? pp.mat_lab : pp.mat_rgb
    include_coords ? standardize!(hcat(M, pp.coords)) : standardize!(M)
end

function _cluster(init::InitState, space::Symbol;
    krange::UnitRange=2:2,
    pca_dim::Int=3,
    sample_N::Int=10_000,
    include_coords::Bool=true
    )

    #-1. Select the feature matrix
    X = _features(init.processor, space; include_coords=include_coords)

    # 0. Sample at most sample_N rows
    rng = seed!(123)
    span = range(1, size(X,1))
    idxs = sample(rng, span, sample_N, replace=false)
    Xs = X[idxs, :]
    
    # 1. Fit PCA, transform
    Xst = table(Xs)
    pca_mach = machine(PCA(maxoutdim = pca_dim), Xst) |> fit!
    Xp = transform(pca_mach, Xs)

    # 3. For each k in the range, fit the K-Medoids and collect labels
    kmeds = Dict{Int, Machine}()
    labels = Dict{Int, Vector{Int}}()
    for k in krange
        mach = machine(KMedoids(k = k), Xp) |> fit!
        kmeds[k] = mach
        labels[k] = Int.(predict(mach, Xp).refs) 
    end

    (pca = pca_mach, kmeds = kmeds, labels = labels, Xs=Xs, X=X)
end

cluster(init::InitState, space::Symbol;
    krange=2:2,
    pca_dim::Int=3,
    sample_N=10_000,
    include_coords=true) = begin
        res = _cluster(
            init, space;
            krange=krange,
            pca_dim=pca_dim,
            sample_N=sample_N,
            include_coords=include_coords
    )
    ClusteredState(init, space, res.X, res.Xs, res.pca, res.kmeds, res.labels)

end

# cluster(init::InitState, space::Symbol; krange::UnitRange=2:2, pca_dim::Int=3) = begin
#             _cluster(init, space; krange=krange, pca_dim=pca_dim)
# end

# Default cluster() using LAB space
cluster(init::InitState; krange=2:2, pca_dim=3, sample_N=10_000, include_coords=true) = begin
    cluster(init, :lab;
            krange=krange, 
            pca_dim=pca_dim,
            sample_N=sample_N,
            include_coords=include_coords
    )
end

function cluster(init::Dict, krange; colorspace=:lab)
    KMedoids = @load KMedoids pkg=Clustering verbosity=0
    PCA = @load PCA pkg=MultivariateStats verbosity=0

    pca = PCA(;maxoutdim=3)
    
    machines = Dict{Symbol, Any}()
    machines[:pca] = Dict{Symbol, Any}(
            :lab => machine(pca, init[:tables][:X]) |> fit!,
            :rgb => machine(pca, init[:tables][:Xrgb]) |> fit!,
    )

    transforms = (
        lab=transform(machines[:pca][:lab], init[:tables][:X]),
        rgb=transform(machines[:pca][:rgb], init[:tables][:Xrgb])
    )
    machines[:pca][:transforms] = transforms
    
    cluster_qualities = Dict(
        :dunn => Float64[],
        :silhouettes => Float64[],
        :calinski_harabasz => Float64[],
        :xie_beni => Float64[],
        :davies_bouldin => Float64[]
    )

    labmat = matrix(transforms.lab)
    qidxs = [:dunn, :silhouettes, :calinski_harabasz, :xie_beni, :davies_bouldin ]


    evaluator!(cluster_qualities::Dict, data::AbstractMatrix, qidxs, labels, centers) = begin
        require_centers = Set([:calinski_harabasz, :xie_beni, :davies_bouldin])
        for qidx in qidxs
            if qidx in require_centers
                quality = clustering_quality(data', centers, labels; quality_index=qidx, metric=SqEuclidean())
            else
                quality = clustering_quality(data', labels; quality_index=qidx, metric=SqEuclidean())
            end
            push!(cluster_qualities[qidx], quality)
        end
    end
    for k in krange
        model = KMedoids(k=k)
        mach = machine(model, machines[:pca][:transforms][colorspace]) |> fit!
        labels = predict(mach, machines[:pca][:transforms][colorspace])
        labels = Int.(labels.refs)
        centers = fitted_params(mach).medoids
        
        evaluator!(cluster_qualities, labmat, qidxs, labels, centers)
        
        key = Symbol("kmedoids", k)
        machines[key] = mach
    end
    clustered = copy(init)
    clustered[:machines] = machines
    clustered[:cluster_qualities] = cluster_qualities
    clustered[:qidxs] = qidxs
    clustered[:krange] = krange
    clustered
end

clusters(cs::ClusteredState, k) = begin
       ls = cs.labels
       Xs = cs.sampled_features
       [Xs[ls[k] .== l, :] for l in unique(ls[k])]
end


# Function to cluster using a Gaussian Mixture Model (GMM)
function cluster_gmm(init::Dict, krange)
    # Prepare quality metrics storage
    cluster_qualities = Dict(
        :dunn => Float64[],
        :silhouettes => Float64[],
        :calinski_harabasz => Float64[],
        :xie_beni => Float64[],
        :davies_bouldin => Float64[]
    )
    labmat = MLJ.matrix(init[:machines][:pca][:transforms][:lab])
    qidxs = [:dunn, :silhouettes, :calinski_harabasz, :xie_beni, :davies_bouldin]

    # Evaluator helper
    evaluator!(cluster_qualities::Dict, data::AbstractMatrix, qidxs, labels, centers) = begin
        require_centers = Set([:calinski_harabasz, :xie_beni, :davies_bouldin])
        for qidx in qidxs
            if qidx in require_centers
                quality = clustering_quality(data', centers, labels; quality_index=qidx, metric=SqEuclidean())
            else
                quality = clustering_quality(data', labels; quality_index=qidx, metric=SqEuclidean())
            end
            push!(cluster_qualities[qidx], quality)
        end
    end

    for k in krange
        # Fit GMM directly using GaussianMixtures.jl (components, data)
        gmm_model = GMM(k, Matrix(labmat'))       # fit GMM with k components on data (samples×features)
        labels = GaussianMixtures.assign_clusters(gmm_model, labmat')  # get hard assignments
        centers = gmm_model.μ                      # component means
        
        # Compute quality metrics
        evaluator!(cluster_qualities, labmat, qidxs, labels, centers)
        
        # Store the fitted GMM model
        init[Symbol("gmm", k)] = gmm_model
    end

    # Save results back into init
    
    init[:gmmcluster_qualities] = cluster_qualities
    return init
end

function evaluate_quality(
    cs::ClusteredState;
    qualityIdx::Symbol=:dunn,
    metric = SqEuclidean()
    )   
    
    Xp = transform(cs.pca, cs.sampled_features) |> matrix
    indices = Dict{Int, Float64}()
    for (k, labels) in cs.labels
        if qualityIdx in (:calinski_harabasz, :xie_beni, :davies_bouldin)
            centers = fitted_params(cs.kmeds[k]).medoids
            indices[k] = clustering_quality(
                Xp', centers, labels; quality_index=qualityIdx, metric=metric
            )
        else
            indices[k] = clustering_quality(
                Xp', labels; quality_index=qualityIdx, metric=metric
            )
        end
    end
    vals = collect(values(sort(indices)))
    vals
end

function ClusterQualities(cs::ClusteredState)
    qs = []
    cqs = fieldnames(ClusterQualities)
    for qualityIdx in cqs
        eqs = evaluate_quality(cs, qualityIdx=qualityIdx)
        push!(qs, eqs)
    end
    ClusterQualities(qs[1], qs[2], qs[3], qs[4], qs[5])
end