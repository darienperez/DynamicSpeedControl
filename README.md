# DynamicSpeedControl
My first package! Goal is to identify terrain and use that information to control UAV velocities

Use local rasterpath and pass to initialize to get started!

In my case it's

rasterpath = "/Users/darien/Desktop/Academia/Research/UAV Applications/Dr. Jacob's Research/Code/Julia/DynamicSpeedControl/data/rasters/processed/ortho_2_20_2021_uncorrected_6348_NAD83_19N.tif"

kf1path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_01_21.tif"

kf2path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_02_25.tif"

kf3path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_03_04.tif"

kf4path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_03_09.tif"

kf5path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_03_10.tif"

kf6path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_AE_2025_03_12.tif"

kf7path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_03_26.tif"

kf8path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_P4_2024_04_05.tif"

kf9path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_P4_2024_04_08.tif"

kf10path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_P4_2024_05_13.tif"

kf11path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_P4_2024_05_27.tif"

kf12path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_02_03.tif"

kf13path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/KF/KF_ortho_MR_2025_02_19.tif"

tf1path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/TF/TF_ortho_P4_2021_02_24_HS.tif"

tf2path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/TF/TF_ortho_GV_2021_12_21.tif"

tf3path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/TF/TF_ortho_P4_2022_01_26_HS.tif"

tf4path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - Orthos/TF/TF_ortho_GV_2023_03_01.tif"

hb1path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_01_03.tif"

hb2path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_01_30.tif"

hb3path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_02_05.tif"

hb4path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_03_03.tif"

hb5path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_03_11.tif"

hb6path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_03_14.tif"

hb7path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_03_27.tif"

hb8path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_04_01.tif"

hb9path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_04_10.tif"

hb10path = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/Orthos/HB/HB_ortho_MR_2025_04_25.tif"

outpath = "/Users/darien/Library/CloudStorage/OneDrive-USNH/UNH BAA Cold Regions - UAV_SCA_FOREST/kmedoids/outputs/"