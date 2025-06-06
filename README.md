# DynamicSpeedControl
My first package! Goal is to identify terrain and use that information to control UAV velocities

Use local raster_path and pass to initialize to get started!

In my case it's

raster_path = "/Users/darien/Desktop/Academia/Research/UAV Applications/Dr. Jacob's Research/Code/Julia/DynamicSpeedControl/data/rasters/processed/ortho_2_20_2021_uncorrected_6348_NAD83_19N.tif"

kf1_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_01_18.tif"

kf2_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_01_23.tif"

kf3_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_01_27.tif"

kf4_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_02_06.tif"

kf5_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_02_08.tif"

kf6_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_02_12.tif"

kf7_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_02_26.tif"

kf8_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_04_05.tif"

kf9_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_04_08.tif"

kf10_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_05_13.tif"

kf11_path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/KF_ortho_P4_2024_05_27.tif"

outpath = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/kmedoids/outputs/rasters/"

outpathgmm = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/P4/gaussianMMs/outputs/"