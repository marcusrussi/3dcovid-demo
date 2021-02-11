# List of all the filenames of the ACS for each state - all of these are on
# the census.gov server
acs_gdbs := $(patsubst %,ACS_2018_5YR_BG_%.gdb,$(shell cut -d_ -f1 ACS_NAMES))

# These don't exist yet - but when made they're made they are of structure
# [GEOID,population], one line per CBG
acs_csvs := $(patsubst %,ACS_2018_5YR_BG_%.csv,$(shell cat ACS_NAMES))

# Directory where all the ACS files live
acs_url := https://www2.census.gov/geo/tiger/TIGER_DP/2018ACS/

# .shp with all the CBG boundaries
cb_url := https://www2.census.gov/geo/tiger/GENZ2019/shp/cb_2019_us_bg_500k.zip

points/%.json: points/%.csv
	csvjson < $< > $@

points/%.csv: infection-by-cbg/%.csv \
  cb_2019_us_bg_500k/cb_2019_us_bg_500k.shp
	@mkdir -p points
	r -e 'library(tidyverse)' \
	  -e 'library(sf)' \
	  -e 'd <- read_csv("$<")' \
	  -e 'df <- st_read("cb_2019_us_bg_500k/cb_2019_us_bg_500k.shp")' \
	  -e 'd <- mutate(d, GEOID = str_sub(GEOID, 8, 19))' \
	  -e 'joined <- st_as_sf(left_join(d, df))' \
	  -e 'joined <- filter(joined, !is.na(st_dimension(geometry)))' \
	  -e 'chopped <- mutate(joined, infections = floor(infections/2))'  \
	  -e 'chopped <- filter(chopped, infections > 0)' \
	  -e 'samples <- st_sample(chopped, pull(chopped, infections))' \
	  -e 'prepped <- st_set_geometry(cbind(st_as_sf(samples), st_coordinates(samples)), NULL)' \
	  -e 'prepped <- transmute(prepped, x = round(X, digits=3), y = round(Y, digits=3))' \
	  -e 'write_csv(prepped, "$@")'

# `bydate/` is a dir
infection-by-cbg/bydate: summary.csv population_by_cbg.csv sample-infections-by-cbg.R
	@mkdir -p $@
	./sample-infections-by-cbg.R \
	  -o $@ \
	  --split \
	  --summary summary.csv \
	  --pop population_by_cbg.csv

infection-by-cbg/latest.csv: summary.csv population_by_cbg.csv sample-infections-by-cbg.R
	@mkdir -p infection-by-cbg
	./sample-infections-by-cbg.R \
	  -o $@ \
	  --latest \
	  --summary summary.csv \
	  --pop population_by_cbg.csv

population_by_cbg.csv: all_acs_csvs
	r -e 'library(magrittr)' \
	  -e 'csvs <- Sys.glob("ACS/ACS_2018_5YR_BG_*.csv")' \
	  -e 'd <- purrr::map_dfr(csvs, readr::read_csv)' \
	  -e 'readr::write_csv(d, "'$@'")'

all_acs_csvs: $(patsubst %,ACS/%,$(acs_csvs))
	@touch all_acs_csvs

ACS/ACS_2018_5YR_BG_%.csv: ACS/ACS_2018_5YR_BG_%.gdb
	r -e 'd <- sf::st_read("'$<'", layer="X01_AGE_AND_SEX")' \
	  -e 'd <- dplyr::select(d, GEOID, population = B01001e1)' \
	  -e 'readr::write_csv(d, "'$@'")'

# Extract all the .zip files to get the ESRI .gdb files
ACS/ACS_2018_5YR_BG_%.gdb: ACS/ACS_2018_5YR_BG_%.gdb.zip
	tar -xzf $< -C ACS/

# Download all the zipped .gdb files
ACS/ACS_2018_5YR_BG_%.gdb.zip:
	@mkdir -p ACS
	curl $(acs_url)/$(notdir $@) > $@

cb_2019_us_bg_500k/cb_2019_us_bg_500k.shp:
	@mkdir -p $(@D)
	curl $(cb_url) | tar -C $(@D) -xz
