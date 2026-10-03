suppressMessages(library(metacheck))
# A psychology-style stimulus image sitting in a folder that happens to
# contain the word "data" anywhere in its path
print(metacheck::data_classify_files("face_003.tif", "Experiment1/data/stimuli/face_003.tif"))
print(metacheck::data_classify_files("face_003.tif", "Experiment1/stimuli/face_003.tif"))
print(metacheck::data_classify_files("photo_specimen.tif", "raw_data_photos/photo_specimen.tif"))
