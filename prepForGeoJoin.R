#!/usr/bin/env Rscript

library(docopt)
library(glue)
library(cli)
library(jsonlite)
suppressPackageStartupMessages( library(tidyverse) )


glue('covidestim summary-to-geojson joiner

Usage:
  {name} -o <output_path> --summary <summary> [-1] [--pop]
  {name} (-h | --help)
  {name} --version

Options:
  -o <output_path>       Where to save the joined GeoJSON file
  --summary <summary>    A .csv summary from a covidestim run
  --pop                  Include population estimate for each county
  -h --help              Show this screen.
  --version              Show version.
', name = "geojson-join.R") -> doc

args <- docopt(doc, version = '0.1')

ps <- cli_process_start
pd <- cli_process_done

ps("Reading summary file {.file {args$summary}}")
d <- read_csv(
  args$summary,
  col_types = cols(
    fips = col_character(),
    .default = col_guess()
  )
)
pd()

if (args$`1`) {
  cli_alert_info('Selecting last day of data')

  d <- group_by(d, fips) %>% filter(date == max(date)) %>%
    ungroup %>%
    left_join(select(usmap::countypop, fips, pop=pop_2015), by = 'fips')

  if (args$pop)
    d <- select(d, id=fips, infections, pop)
  else
    d <- select(d, id=fips, infections)

  ps("Writing JSON to {.file {args$o}}")
  write_json(d, args$o)
  pd()
}
