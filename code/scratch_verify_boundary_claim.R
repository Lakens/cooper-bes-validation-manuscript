suppressMessages(library(metacheck))
# Confirm the boundary-regex explanation for "ShapefilesAndData" directly
print(metacheck::data_classify_files("WoodPastures.shp", "RCode.zip/RCode/ShapefilesAndData/WoodPastures.shp"))
print(metacheck::data_classify_files("WoodPastures.shp", "RCode.zip/RCode/Shapefiles_And_Data/WoodPastures.shp"))
print(metacheck::data_classify_files("photo_specimen.tif", "raw_data_photos/photo_specimen.tif"))
print(metacheck::data_classify_files("photo_specimen.tif", "raw-data-photos/photo_specimen.tif"))
