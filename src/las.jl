const laspath = "/Users/darien/Desktop/Academia/Research/UAV Applications/Dr. Jacob's Research/Code/LiDAR/"

function trainKmed(Xtrain::DataFrame; ks=2:2)
    kmedmachs = Dict{Int8, Machine}()
    for k in ks
        kmedmach = machine(KMedoids(k=k), Xtrain) |> fit!
        kmedmachs[k] = kmedmach
        end
    return kmedmachs
end

function trainPCA(df::DataFrame; N = 20_000, trials=1)
    pcamachs = []
    println("Fitting Standardizer...")
    std_mach = machine(Standardizer(), df[!, [:x,:y,:z]]) |> fit!
    println("Done!")
    println("Standardizing features..")
    X = transform(std_mach, df[:, [:x,:y,:z]])
    idxs = sample_df(X, N, trials)
    println("Done!")
    for idxs in eachcol(idxs)
        pcamach = machine(PCA(), X[idxs, :]) |> fit!
        push!(pcamachs, pcamach)
    end
    return pcamachs, X, idxs
end

function write_las(laspath, pts::Vector{LazIO.Point3}, ds::LazIO.Dataset{0x03}) 
    LazIO.write(
       (writer::Ptr{Cvoid}) -> begin
       for p in pts
       LazIO.writepoint(writer, p, ds.header)
       end
       end,
       laspath,
       ds.header)
end

function make_RawPoints!(df::DataFrame)
    LazIO.Point3.(
           df.geometry,
           df.intensity,           df.return_number, df.number_of_returns,
           df.scan_direction,      df.edge_of_flight_line,
           df.classification,      df.synthetic,
           df.key_point,           df.withheld,
           df.scan_angle_rank,     df.user_data,
           df.point_source_id,     df.gps_time,
           df.r,                   df.g,            df.b,
       )
end

function make_df(ds::LazIO.Dataset{UInt8(3)}) 
    df = DataFrame(ds)
    unique!(df, 1) # use unique df.geometry = [x,y,z] to filter full df
    transform_df!(df)
end

function transform_df!(df::DataFrame)
    transform!(df,
    :geometry => ByRow(p -> p[1]) => :x,
    :geometry => ByRow(p -> p[2]) => :y,
    :geometry => ByRow(p -> p[3]) => :z
    )
    select!(df,[:x,:y,:z], Not([:x,:y,:z]))
end

function sample_df(df::DataFrame, N, trials)
    sample(1:nrow(df), (N, trials), replace=false)
end


function classify_las(X::DataFrame, kmedmach, pcamach)
    dists = transform(kmedmach, X)
    labels = Int8.(argmin.(eachrow(matrix(dists))))
    dists = nothing; GC.gc()
    labels
end

function change_labels!(df::DataFrame, labels)
    df.classification = labels
end

