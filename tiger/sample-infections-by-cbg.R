#!/usr/bin/env Rscript

library(docopt)
library(glue)
library(cli)
suppressPackageStartupMessages( library(tidyverse) )

glue('Infections-per-CBG sampler

Usage:
  {name} -o <output_path> --summary <csv> --pop <csv> [--latest] [--split]
  {name} (-h | --help)
  {name} --version

Options:
  --latest               Only save the most recent day
  --split                Treat -o as a directory and split out by date
  -o <output_path>       Where to save the filtered input data .csv. 
  --summary <csv>        .csv from a county-level Covidestim run
  --pop <csv>            .csv w/ columns [GEOID, population]
  -h --help              Show this screen.
  --version              Show version.
', name = "sample-infections-by-cbg.R") -> doc

args <- docopt(doc, version = '0.1')

ps <- cli_process_start
pd <- cli_process_done

ps("Reading Covidestim summary file {.file {args$summary}}")
dSummary <- read_csv(
  args$summary,
  col_types = cols(.default = col_guess(), fips = col_character())
)
pd()

ps("Reading population file {.file {args$pop}}")
dPop <- read_csv(
  args$pop,
  col_types = cols(GEOID = col_character(), population = col_number())
)
pd()

# Get the FIPS code for each CBG
dPop <- mutate(dPop, fips = str_sub(GEOID, 8, 12))

if (args$latest) {
  dSummary <- group_by(dSummary, fips) %>%
    filter(date == max(date))
}

ps("Left-join between population and Covidestim summary")
joined <- left_join(
  dPop, 
  select(dSummary, fips, infections, date),
  by = 'fips'
)
pd()

ps("Calculating proportional infections")
proportional <- joined %>%
  group_by(fips, date) %>%
  mutate(infections = infections * population / sum(population)) %>%
  ungroup %>%
  select(-fips, population)
pd()

ps("Rounding `infections` to the nearest integer and typecasting")
proportional <- mutate(
  proportional,
  infections = as.integer(round(infections))
)

if (!args$split) {
  ps("Saving to file {.file {args$o}}")
  write_csv(proportional, args$o)
  pd()
} else {
  ps("Splitting by date")
  proportional_split <- group_by(proportional, date)
  pd()
  ps("Saving split files to {.file args$o}")
  group_walk(proportional_split, ~write_csv(.x, paste0(args$o, '/', .y$date, '.csv')))
  pd()
}
