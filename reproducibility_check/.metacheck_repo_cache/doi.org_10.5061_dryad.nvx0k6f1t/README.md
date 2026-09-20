# Data from: Automating field based floral surveys with machine learning

[https://doi.org/10.5061/dryad.nvx0k6f1t](https://doi.org/10.5061/dryad.nvx0k6f1t)

This repo contains **(1)** orthorectified drone images of the ten study sites located in Rouge National Urban Park, Ontario, Canada. The imagery was collected at low altitude (7m, 15m, or 30m) in September 2024 with the DJI Phantom 4 Pro V2. **(2)** Floral classification maps predicted by the trained convolutional neural network (CNN) that is described in the paper. The CNN was trained to perform multi-classification of the three flower taxa that dominate the Fall flowering landscape in the region. **(3)** The trained CNN model that performs the multi-classification on input drone imagery. **(4)** Tabulation of plot-level floral surveys that were used to ground the truth of the CNN model.

The code is provided as supporting data for

Sookhan N, Sookhan S, Grewal D, MacIvor JS. 2024. Automating field-based floral surveys with machine learning. Ecological Solutions and Evidence.

## Description of the data and file structure

### Files and variables

#### File: image.7z

**Description:** Drone orthomosaic rasters of each study site in GeoTIFF format. Compressed folder contains 13 files.

* **20210907_siteCF_h15m.7z**: Compressed drone orthomosaic of site CF collected at 15 m altitude above ground level.  
* **20210907_siteCF_h30m.7z:** Compressed drone orthomosaic of site CF collected at 30 m altitude above ground level.

- **20210913_siteA_h7m.7z:** Compressed drone orthomosaic of site A collected at 7 m altitude above ground level. 
- **20210913_siteA_h15m.7z**: Compressed drone orthomosaic of site A collected at 15 m altitude above ground level.
- **20210913_siteA_h30m.7z**: Compressed drone orthomosaic of site A, 1 and 2 collected at 30 m altitude above ground level.
- **20210913_site2_h15m.7z**: Compressed drone orthomosaic of site 2 collected at 15 m altitude above ground level.
- **20210906_site5_h7m.7z**: Compressed drone orthomosaic of site 5 collected at 7 m altitude above ground level.
- **20210907_site6_h15m.7z**: Compressed drone orthomosaic of site 6 collected at 15 m altitude above ground level.
- **20210907_site6_h30m.7z**: Compressed drone orthomosaic of site 6 collected at 30 m altitude above ground level.
- **20210905_site8_h7m.7z**: Compressed drone orthomosaic of site 8 collected at 7 m altitude above ground level.
- **20210905_site9_h7m.7z**: Compressed drone orthomosaic of site 9 collected at 7 m altitude above ground level.
- **20210905_site10_h7m.7z**: Compressed drone orthomosaic of site 10 collected at 7 m altitude above ground level.
- **20210907_site15_h15m.7z**: Compressed drone orthomosaic of site 15 collected at 15 m altitude above ground level.

#### File: predict.7z

**Description:** Floral classification maps predicted by the trained convolutional neural network for each study site in 8-bit GeoTIFF format. Compressed folder contains 13 files.

* **20210907_siteCF_h15m.7z**: Compressed floral classification map of site CF collected at 15 m altitude above ground level.  
* **20210907_siteCF_h30m.7z**: Compressed floral classification map of site CF collected at 30 m altitude above ground level.
* **20210913_siteA_h7m.7z**: Compressed floral classification map of site A collected at 7 m altitude above ground level. 
* **20210913_siteA_h15m.7z**: Compressed floral classification map of site A collected at 15 m altitude above ground level.
* **20210913_siteA_h30m.7z**: Compressed floral classification map of site A, 1 and 2 collected at 30 m altitude above ground level.
* **20210913_site2_h15m.7z**: Compressed floral classification map of site 2 collected at 15 m altitude above ground level.
* **20210906_site5_h7m.7z**: Compressed floral classification map of site 5 collected at 7 m altitude above ground level.
* **20210907_site6_h15m.7z**: Compressed floral classification map of site 6 collected at 15 m altitude above ground level.
* **20210907_site6_h30m.7z**: Compressed floral classification map of site 6 collected at 30 m altitude above ground level.
* **20210905_site8_h7m.7z**: Compressed floral classification map of site 8 collected at 7 m altitude above ground level.
* **20210905_site9_h7m.7z**: Compressed floral classification map of site 9 collected at 7 m altitude above ground level.
* **20210905_site10_h7m.7z**: Compressed floral classification map of site 10 collected at 7 m altitude above ground level.
* **20210907_site15_h15m.7z**: Compressed floral classification map of site 15 collected at 15 m altitude above ground level.

#### File: model.7z

**Description:** The trained TensorFlow model in HDF5 format.

#### **File: external\_val.7z**

**Description:** Floral counts completed at the plot level that were used to externally validate the automated drone-derived floral abundance predicted by the trained convolutional model. In CSV format.

* **date:** Date (YYYY-MM-DD) that plot was surveyed. 
* **time_start**: Time (HH:MM) survey commenced.
* **time_end**: Time (HH:MM) survey was completed.
* **site_id:** Site ID of plot. 
* **plot_id:** Plot ID of plot. 
* **total.area:** Drone-derived floral abundance measure. CNN predicted floral cover.
* **prop.area:**	Drone-derived floral abundance measure. CNN predicted relative floral cover (relative to plot area)
* **fu:** Field-derived floral abundance measure. Field count of floral units.  
* **shoot:** Field-derived floral abundance measure. Field count of  number of flowering shoots.

  For each of the drone and field-derived floral abundance measures, a separate column is provided for each of the species detected in the study. The species are *Solidago* spp (SOSP), *Achillea millefolium* (ACME), *Symphyotrichum ericoides* (SYER), *Symphyotrichum novae-angliae* (SYNO), *Symphyotrichum lanceolatum* (SYLA), *Lotus corniculatus* (LOCO), *Trifolium repens* (TRRE), *Medicago lupulina* (MELU).

