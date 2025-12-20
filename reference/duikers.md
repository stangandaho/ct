# Maxwell's duiker camera-trap distance & video-start data

The **`duikers`** dataset is a **named list** of three tibbles derived
from Maxwell's duiker (*Philantomba maxwellii*) camera trap and distance
sampling data collected in Taï National Park, Côte d'Ivoire (2014), and
archived as the Dryad dataset *Distance sampling with camera traps*
(Howe et al., 2018)

## Usage

``` r
duikers
```

## Format

A named list with these tibbles: **DaytimeDistances**: A tibble of all
Maxwell's duiker distance observations (including non peak periods)
recorded at camera stations during daytime deployments. It has the
following columns:

- `distance`: the midpoint (m) of the assigned distance interval between
  animal and camera.

- `Sample.Label`: camera station identifier.

- `Effort`: number of active 2 second time steps the camera operated
  (i.e. temporal effort).

- `Region.Label`: stratum name (only a single stratum in this dataset).

- `Area`: study area size (km^2; in this dataset, 40.4).

- `multiplier`: spatial effort: fraction of a full circle covered, based
  on the camera's 42 deg field of view (42/360).

- `utm.e`: UTM easting (metres) of the camera station.

- `utm.n`: UTM northing (metres) of the camera station.

- `object`: a unique identifier for each observation

**PeakDistances**: A tibble with the **same column structure** as
**DaytimeDistances**, but includes **only** observations during the
species' peak activity periods (no dawn or late day records).

**VideoStartTimesFullDays**: A tibble of camera‑trigger times for duiker
videos that were recorded on **full day deployments** (i.e. days without
researcher visits). Columns include:

- `order`: sequential order of video events at each station/day.

- `folder`: local folder (e.g. `"A1"`) for grouping videos by station or
  session.

- `vid.no`: unique video identifier number.

- `ek.no`: event key number (original trigger event id).

- `easting`: UTM easting (metres) for the video event.

- `northing`: UTM northing (metres) for the video event.

- `month`: calendar month (1-12) of the video event.

- `day`: day of the month (1-31).

- `hour`: hour (24h clock) when the video started.

- `minute`: minute of that hour when the video started.

- `date`: Date of the record

- `time`: Time of the record

- `datetime`: date pasted with time

## References

Howe, E. J., Buckland, S. T., Després-Einspenner, M. L., Kühl, H. S., &
Buckland, S. T. (2018). Data from: Distance sampling with camera traps.
[doi:10.5061/dryad.b4c70](https://doi.org/10.5061/dryad.b4c70)
