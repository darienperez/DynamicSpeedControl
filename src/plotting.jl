function generate_plots(initialized::NamedTuple)
    wps = initialized.wps
    pixels = initialized.pixels
    mapped = initialized.mapped

    # Define trace specifications: (plot function, parameters, x-axis ID, y-axis ID)
    trace_specs = [
        (PlotlyJS.surface, (; x=pixels.x, y=pixels.y, z=pixels.densities, colorscale="Viridis"), "x1", "y1"),
        (PlotlyJS.contour,  (; x=pixels.x, y=pixels.y, z=pixels.densities, colorscale="Viridis"), "x2", "y2"),
        (PlotlyJS.surface, (; x=pixels.x, y=pixels.y, z=mapped.speeds, colorscale="Turbo"), "x3", "y3"),
    ]

    # Generate traces in a Julian-comprehension style
    traces = [ make_trace(func, params, xa, ya) for (func, params, xa, ya) in trace_specs ]

    # Create a 1x3 subplot layout
    layout = Layout(title = "UAV Speed and Pixel Density",
                    xaxis = attr(domain = [0, 0.33]),
                    xaxis2 = attr(domain = [0.34, 0.66]),
                    xaxis3 = attr(domain = [0.67, 1]),
                    yaxis = attr(title = "Density"),
                    yaxis2 = attr(title = "Density"),
                    yaxis3 = attr(title = "Speed"))

    PlotlyJS.plot(traces, layout)
end

function plot_lawnmower_path(initialized)
    pixels = initialized.pixels
    x = pixels.x
    y = pixels.y
    z = pixels.densities

    # Extract x, y from waypoints
    wps = initialized.wps
    x_wp = wps[:x][wps[:keep]]
    y_wp = wps[:y][wps[:keep]]
    speeds = wps[:cspeeds][wps[:keep]]
    
    # Create the base contour plot
    contour_plot =  PlotlyJS.contour(
        x = wps[:x],
        y = wps[:y],
        z = wps[:cspeeds],
        zmin = minimum(wps[:cspeeds]),
        zmax = maximum(wps[:cspeeds]),
        colorscale = "Viridis",
        name = "Pixel speed Contour",
        xmin = minimum(wps[:x]),
        xmax = maximum(wps[:x])
    )

    # Overlay the lawnmower path
    path_trace =  PlotlyJS.scatter(
        x = x_wp,
        y = y_wp,
        mode = "markers",
        line = attr(color = "red"),
        marker = attr(size = 6),
        name = "Lawnmower Path"
    )

    # Combine plots
    layout = Layout(title = "Lawnmower Path over UAV Speeds")
     PlotlyJS.plot([contour_plot, path_trace], layout)
end

make_trace(plotfn, params::NamedTuple, xaxis::AbstractString, yaxis::AbstractString) = begin
    t = plotfn(; params...)
    t[:xaxis] = xaxis
    t[:yaxis] = yaxis
    return t
end

make_trace(cs::ClusteredState, k)  = begin
    transform(cs.pca, cls[k]) |> DataFrame |> 
    df ->  scatter3d(df, x=:x1, y=:x2, z=:x3, mode="markers", marker=attr(size=2, opacity=0.5))
end

function plot_data(X;
    xlabel="x label",
    ylabel="y label",
    zlabel="z label",
    plot_title="Plot Title",
    ax_fs=24,
    tk_fs=14,
    ttl_fs=20,
    ms=2.0,
    mlw=1.5,
    mc= "blue",
    mlc="lightgray",
    opacity=0.2,
    kwargs...)

    layout = Layout(
        scene=attr(
            aspectmode="cube",
            # choose a “closer” eye for zoom-in, or set >1 for zoom-out
            camera = attr(
              eye    = attr(x=1.5, y=1.5, z=1.5),  # camera position
              center = attr(x=0,   y=0,   z=0),    # look-at point (data center)
              up     = attr(x=0,   y=0,   z=1)     # which direction is “up”
            ),
            xaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=xlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            yaxis=attr(
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=ylabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            zaxis=attr(
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=zlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            )
        ),
        annotations=[   # ← place text inside the plotting area
            attr(
                text=plot_title,
                x=0.5,       # 50% across the width of the figure
                y=0.95,       # 90% up from the bottom of the figure
                xref="paper",# coordinates relative to the whole figure
                yref="paper",
                showarrow=false,
                font=attr(size=ttl_fs)
            )
        ]     
    )

    trace = PlotlyJS.scatter3d(x=X[:,1], y=X[:,2], z=X[:,3],
        marker_size=ms,
        mode="markers",
        opacity=opacity,
        marker=attr(
            color=mc,
            line_width=mlw,
            line_color=mlc
        ),
        kwargs...
    )

    PlotlyJS.plot(trace, layout)

end

struct IsLAB end
function plot_data(clustered::Dict, ::IsLAB;
    xlabel="L",
    ylabel="A",
    zlabel="B",
    plot_title="LAB colorspace plot of input image",
    ax_fs=24,
    tk_fs=14,
    ttl_fs=20,
    ms=2.0,
    mlw=1.5,
    mc= "blue",
    mlc="lightgray",
    opacity=0.2,
    kwargs...)

    layout = Layout(
        scene=attr(
            aspectmode="cube",
            # choose a “closer” eye for zoom-in, or set >1 for zoom-out
            camera = attr(
              eye    = attr(x=1.5, y=1.5, z=1.5),  # camera position
              center = attr(x=0,   y=0,   z=0),    # look-at point (data center)
              up     = attr(x=0,   y=0,   z=1)     # which direction is “up”
            ),
            xaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=xlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            yaxis=attr(
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=ylabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            zaxis=attr(
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=zlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            )
        ),
        annotations=[   # ← place text inside the plotting area
            attr(
                text=plot_title,
                x=0.5,       # 50% across the width of the figure
                y=0.95,       # 90% up from the bottom of the figure
                xref="paper",# coordinates relative to the whole figure
                yref="paper",
                showarrow=false,
                font=attr(size=ttl_fs)
            )
        ]     
    )

    X = clustered[:sampled][:X]
    trace = PlotlyJS.scatter3d(x=X[:,1], y=X[:,2], z=X[:,3],
        marker_size=ms,
        mode="markers",
        opacity=opacity,
        marker=attr(
            color=mc,
            line_width=mlw,
            line_color=mlc
        ),
        kwargs...
    )

    PlotlyJS.plot(trace, layout)

end

struct IsRGB end
function plot_data(clustered::Dict, ::IsRGB;
    xlabel="R",
    ylabel="G",
    zlabel="B",
    plot_title="RBG colorspace plot of input image",
    ax_fs = 24,
    tk_fs = 14,
    ttl_fs = 20,
    ms = 2.0,
    mlw = 1.5,
    mc= "blue",
    mlc="lightgray",
    opacity=0.2,
    kwargs...)

    layout = Layout(
        scene=attr(
            aspectmode="cube",
            # choose a “closer” eye for zoom-in, or set >1 for zoom-out
            camera = attr(
              eye    = attr(x=-1.5, y=-1.5, z=1.5),  # camera position
              center = attr(x=0,   y=0,   z=0),    # look-at point (data center)
              up     = attr(x=0,   y=0,   z=1)     # which direction is “up”
            ),
            xaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=xlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            yaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=ylabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            zaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=zlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            )
        ),
        annotations=[   # ← place text inside the plotting area
            attr(
                text=plot_title,
                x=0.5,       # 50% across the width of the figure
                y=0.95,       # 90% up from the bottom of the figure
                xref="paper",# coordinates relative to the whole figure
                yref="paper",
                showarrow=false,
                font=attr(size=ttl_fs)
            )
        ]
    )

    X = clustered[:sampled][:Xrgb]
    trace = PlotlyJS.scatter3d(x=X[:,1], y=X[:,2], z=X[:,3],
        marker_size=ms,
        mode="markers",
        opacity=opacity,
        marker=attr(
            color=mc,
            line_width=mlw,
            line_color=mlc),
        kwargs...
    )

    PlotlyJS.plot(trace, layout)

end

struct IsPCA end
function plot_data(clustered::Dict, ::IsLAB, ::IsPCA)
    X = matrix(clustered[:machines][:pca][:transforms][:lab])
    plot_data(X;
        xlabel="PC1",
        ylabel="PC2",
        zlabel="PC3",
        plot_title="LAB Transformed into Principal Component Space",
        ax_fs=20,
        ttl_fs=16
    )
end

function plot_data(clustered::Dict, ::IsRGB, ::IsPCA)
    X = matrix(clustered[:machines][:pca][:transforms][:rgb])
    plot_data(X;
        xlabel="PC1",
        ylabel="PC2",
        zlabel="PC3",
        plot_title="RGB Transformed into Principal Component Space",
        ax_fs=20,
        ttl_fs=16
    )
end

struct Is2D end

function plot_data(clustered::Dict, ::Is2D;
    xlabel="L",
    ylabel="A",
    zlabel="B",
    plot_title="RBG colorspace plot of input image",
    ax_fs = 24,
    tk_fs = 14,
    ttl_fs = 20,
    ms = 2.0,
    mlw = 1.5,
    mc= "blue",
    mlc="lightgray",
    opacity=0.2,
    kwargs...
    )

    layout = Layout(
        scene=attr(
            aspectmode="cube",
            # choose a “closer” eye for zoom-in, or set >1 for zoom-out
            camera = attr(
              eye    = attr(x=1.5, y=1.5, z=1.5),  # camera position
              center = attr(x=0,   y=0,   z=0),    # look-at point (data center)
              up     = attr(x=0,   y=0,   z=1)     # which direction is “up”
            ),
            xaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=xlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            yaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=ylabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            ),
            zaxis=attr(
                showbackground=true,
                backgroundcolor="white",
                gridcolor="lightgray",
                title=attr(text=zlabel, font=attr(size=ax_fs)),
                tickfont=attr(size=tk_fs)
            )
        ),
        annotations=[   # ← place text inside the plotting area
            attr(
                text=plot_title,
                x=0.5,       # 50% across the width of the figure
                y=0.95,       # 90% up from the bottom of the figure
                xref="paper",# coordinates relative to the whole figure
                yref="paper",
                showarrow=false,
                font=attr(size=ttl_fs)
            )
        ]
    )

    X = MLJ.matrix(clustered[:machines][:pca][:transforms][:lab])
    proj(j, X) = begin
        M = copy(X)
        M[:, j] .= minimum(X[:, j])
        M
    end

    cols = size(X, 2)
    col_rng = range(1, cols)
    proj_mats = proj.(col_rng, Ref(X))

    traces = [
        PlotlyJS.scatter3d(x=M[:,1], y=M[:,2], z=M[:,3];
            marker_size=ms,
            mode="markers",
            opacity=opacity,
            marker=attr(
                line_width=mlw,
                line_color=mlc),
            kwargs...
        ) for (j, M) in zip(col_rng, proj_mats)
    ]

    PlotlyJS.plot(traces, layout)
end

struct IsQuality end

function plot_data(clustered::Dict, ::IsQuality;
    plot_title="LAB-space Clustering Quality Index Scores",
    xlabel="k",
    kwargs...
    )
    # Extract quality scores and k-range
    cqs    = clustered[:cluster_qualities]
    krange = clustered[:krange]
    qidxs  = clustered[:qidxs]

    # Create a 5×1 subplot figure with shared x-axis
    fig = PlotlyJS.make_subplots(
        rows=length(qidxs), cols=1,
        shared_xaxes=true,
        # subplot_titles = string.(qidxs)
    )

    # Add one scatter trace per subplot
    for (i, q) in enumerate(qidxs)
        trace = PlotlyJS.scatter(
            x=krange,
            y=cqs[q],
            mode="lines+markers",
            name=string(q),
            xaxis=attr(text="k")
        )
        add_trace!(fig, trace, row=i, col=1)
        # Label each y-axis
        # fig.layout["yaxis$i"] = attr(title=string(q))
    end

    relayout!(fig, title_text=plot_title)
    # Label the bottom x-axis and set the overall title
    # fig.layout["xaxis1"] = attr(title=xlabel)
    # fig.layout["title"]  = plot_title

    display(fig)
    fig
end

function plot_data(cs::ClusteredState, ::IsQuality)
    
end