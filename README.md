# Archimedes_Optical_Data

This repository contains code developed for the SIMONS Foundation project 654879 "Processing and Distribution of Hyperspectral Radiometer Data from Ships of Opportunity for Monitoring Phytoplankton in the Ocean"

The code is designed to process data collected using Sea-Bird Scientific’s OCR digital optical sensors mounted on a Surface Acquisition System (SAS). The system is designed to obtain high-precision measurements of water-leaving spectral radiance, downwelling spectral irradiance and sea-surface temperature.

The code is designed to ingest SATCON output, including spectral downwelling irradiance (Es), sky radiance (Li), water-leaving radiance (Lt), GPS positioning data, SAS output, and pyrometer data (which provided sea-surface temperature).  

The code essentially processes the data as follows:

1. On each optical instrument, a shutter closes periodically to record dark values. The Es, Li and Lt data are first dark corrected, by interpolating the dark value data in time to match the light measurements for each sensor, then subtracting the dark values from the light measurements at each wavelength.

2. The Es, Li and Lt were then interpolated to the same set of wavelengths (every 2 nm from 350–800 nm).

3. As the three sensors have different integration times and thus collect data at slightly different time stamps, the Es and Li data are interpolated to the Lt time stamps, which was selected as it is the sensor with the slowest integration time. This resulted in Es, Li and Lt data at the same time and same sets of wavelengths.

3. All other data (GPS locations, sensor angle, ship speed, course, SST, heading, sun angles, etc.) are interpolated to the same time stamps at the optical data.

4. Remote-sensing reflectance (Rrs(λ)) was then computed according to Rrs(λ) = [Lt(λ) − ρLi(λ)]/Es(λ), where ρ was set of 0.028.

5. All data were median binned to 1-minute intervals and the median absolute deviation computed for each product for each bin. 

6. Rrs data were quality controlled by removing data where the angle between the sensors and the sun azimuth was less than 100 degrees and greater than 260 degrees, and where sun zenith angles were less than 60 degrees. An additional quality control step was added, removing data where the 1-minute median absolute deviation in Rrs(750) was greater than 0.002 (high variance at this wavelength indicative of sun glint) and for the remaining data, the median value of Rrs at 750-800nm for each spectrum was subtracted from each spectrum.
