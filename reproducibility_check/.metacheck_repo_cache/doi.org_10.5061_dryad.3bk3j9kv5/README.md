# Data from: Individual responses of GPS-tagged geese scared off crops by drones or walking humans

[https://doi.org/10.5061/dryad.3bk3j9kv5](https://doi.org/10.5061/dryad.3bk3j9kv5)

## Description of the data and file structure

In June 2018 and June 2019 breeding and moulting (flightless) greylag geese (N=32) were caught.  In addition to classic tarsal metal rings, geese were provided with neck collars fitted with a solar powered GPS tracking device: Ornitela (OT-N35 or OT-N44). Geese were aged (juvenile or adult ≥2nd calendar year) based on plumage and sexed by cloacal inspection. Out of the 32 individuals, four were juveniles and 28 adults; 13 were females and 19 males. For the present study we used GPS positions from 48 hours before to 48 hours after each scaring event of an individual. The default positioning rate was set to every 30 minutes (i.e., in total 192 positions per scaring event). In addition, we tracked the geese more intensively (one position every 5 minutes) from 4 hours before to 4 hours after each scaring event (96 additional positions per scaring event). This intensive and real-time positioning allowed us to find a certain individual targeted for a trial and to follow its movements before and after scaring. Inaccurate positions, measured with dilution of precision (DOP) >7, were excluded (n=534 out of 228 906 obtained positions, ~ 0.2%). The total number of positions obtained between 24 and 48 hours before scaring was 12614, and 12836 for the same duration (period) after scaring. We used the DJI Phantom 4 drone, flown in a straight line towards the flock containing the target goose at a speed of 50 km/h at an altitude of 10 m. Scaring by walking was performed by approaching the goose flock in a straight line using a normal walking pace. 

### Files and variables

#### File: Geese\_scaring\_data.csv

**Description:** 

##### Variables

* row_number – row number of in data set
* before_after – factor indicting before and after scaring (includes the scaring point “scaring”)
* trial_id – factor indicting trial
* device_id – factor indicting collar id
* UTC_datetime – date and time (UTC) for the GPS location
* time – only time (UTC)
* time_num – time numerical
* time_scaring – time in relation to scaring time (negative time before scaring, positive time after scaring)
* time_period – time period in relation to scaring time divided into twelve time intervals: A (48 – 24 hours before), B (24 – 4 hours before), C (4 – 3 hours before), D (3 – 2 hours before), E (2 – 1 hours before), F (1 – 0 hours before), G (0 – 1 hours after), H (1 – 2 hours after), I (2 – 3 hours after), J (3 – 4 hours after), K (4 – 24 hours after), and L (24 – 48 hours after)
* time_of_day – factor for time of the day when scared; morning (before 11 AM) or afternoon (after 12 AM)
* scaring_method – factor for scaring method; drone versus walking
* season – factor for season when scared; spring (March – April), summer (July – August), and fall (September
* distance – distance (m) to the scaring point
* buffer – factor if the goose was ≤300 m from the scaring point (coded as 1) or >300 m from the scaring point (coded as 0)
* habitat – habitat characteristics for the goose positions; agricultural field and wetland

## Code/software

R (version 4.2.2, R core team 2022) and Open office
