## Code to prepare `EcoregionResults_PostProcessed` dataset goes here

# This script generates report-worthy results for ecoregion-level biomass and age relationships.
# It post-processes a .csv from Google Colab, that aggregated point-level biomass/age measurements exported from Google Earth Engine.

# The result displays estimated biomass in primary forests,
# biomass growth rates in forests regrowing from disturbance (via the Tropical Moist Forests (TMF) dataset),
# and several additional fields about the timeline and progress of biomass recovery.

# -----------------------------------------------------------------------------
# Setup & data access

## Load packages/library setup
install.packages("here")
library(here)

## Set file path
filepath <- here("data-raw", "EcoregionExports.csv")

## Read CSV file
df_ecoregions_original <- read.csv(filepath) # Storing this as its own object in Environment for reference

# -----------------------------------------------------------------------------
# Filtering data

## Remove columns with Global Forest Change (GFC) data, which I’m no longer using.
df_ecoregions <- subset(df_ecoregions_original,
                        select = -c(gfc_n, gfc_slope, gfc_int, gfc_r2))

## Filter errant/low-quality data records
### Remove records where ecoregions had no viable data points within Primary Forests or TMF Regrowing Forests
df_ecoregions <- df_ecoregions[df_ecoregions$pri_n != -1 & # -1: nodata flag
                                 df_ecoregions$tmf_n != -1,]
### Ensure that only records with positive, nonzero slopes are kept
df_ecoregions <- df_ecoregions[df_ecoregions$tmf_slope > 0,]
### Remove ecoregions where R^2 was particularly low, less than 0.3
df_ecoregions <- df_ecoregions[df_ecoregions$tmf_r2 >= 0.3,]

# -----------------------------------------------------------------------------
# Calculate new fields for reporting

## Calculate the predicted biomass after 20 years of regrowth (via linear regression)
df_ecoregions$tmf_agbd20 <- df_ecoregions$tmf_slope * 20 + df_ecoregions$tmf_int

## Calculate the percent of Primary Forest biomass that the 20-year prediction reaches
df_ecoregions$tmf_pct20 <- (df_ecoregions$tmf_agbd20 / df_ecoregions$pri_median) * 100

## Calculate the estimated time it would take to reach Primary Forest biomass, assuming continual linear regrowth
df_ecoregions$tmf_timetopri <- (df_ecoregions$pri_median - df_ecoregions$tmf_int) / df_ecoregions$tmf_slope

# -----------------------------------------------------------------------------
# Sort data

## Order the data so that ecoregions with the quickest time-to-primary are at the top
df_ecoregions <- df_ecoregions[order(df_ecoregions$tmf_timetopri),]

# -----------------------------------------------------------------------------
# Save the results to data folder

EcoregionReports <- df_ecoregions
usethis::use_data(EcoregionReports, overwrite = TRUE)
