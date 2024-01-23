library(plotly)
library(sf)
library(terra)
library(htmltools)
library(viridis)
library(smoothr)
library(rmapshaper)
library(leaflet)
library(ratlas)
library(dplyr)

# ------------------------------------------------------ #
#### Simplification geopackage aires protegees union ####
# ---------------------------------------------------- #
# aires <- st_read("data_clean/aires_protegees_union.gpkg") # fichier original delete
# a <- ms_simplify(aires)
# st_write(a, "data_clean/aires_protegees_union_simplifiees.gpkg")


# ------------------------------------------------------------ #
#### Function for drawing a vertical line on a plotly graph ####
# ------------------------------------------------------------ #
# fonction for drawing a vertical line
vline <- function(x = 0, color = "#238A8DFF") {
    list(
        type = "line",
        y0 = 0,
        y1 = 1,
        yref = "paper",
        x0 = x,
        x1 = x,
        line = list(color = color, dash = "dot")
    )
}


# ------------------------------------------ #
#### figure 1 - carte des aires protégées ####
# ------------------------------------------ #
aires <- st_read("./data_clean/aires_protegees_simplifiees.gpkg")

# conversion en lat lon pour visualisation dans leaflet
aires_latlon <- st_transform(
    aires,
    crs = st_crs(4326)
)
# popup infos
aires_latlon$POPINFOS <- paste0(
    "<b>", aires_latlon$NOM,
    "</b><br> date de création: <b>", aires_latlon$DA_CREATIO,
    "</b><br> superficie: <b>", round(aires_latlon$HA_LEGAL, digit = 1), " ha </b>"
)

# ----------------------------------------------------------------------- #
#### figure 2A - courbes de tendance de SPI à partir aire distribution ####
# --------------------------------------------------------------------- #

# SPI <- read.csv("./results/RANGES/SPI.csv")
SPI <- read.csv("./results/SPI_ranges.csv")
# error in species names
SPI$SPECIES[SPI$SPECIES == "Lyn rufus"] <- "Lynx rufus"
species <- as.character(unique(SPI$SPECIES))
years <- as.numeric(unique(SPI$YEAR))

# retrieve informations about species from Atlas
# info_spe <- get_taxa(scientific_name = species)
# info_spe <- info_spe[, c(2, 3, 5, 6, 7, 8)] # need to treat the data !
# info_ls <- split(info_spe, info_spe$valid_scientific_name)
# infos <- lapply(info_ls, function(x) {
#     l <- x[1, ]
#     l
# })

# info_spe2 <- do.call("rbind", infos)
# write.csv(info_spe2, "data_clean/ATLAS_info_spe_distri.csv")
info_spe2 <- read.csv("./data_clean/ATLAS_info_spe_distri.csv")[, -1]
# adding species info from Atlas (et al) with a left_join
SPI <- left_join(SPI, info_spe2, by = join_by("SPECIES" == "observed_scientific_name"))

# smoothing the curves
spi_ls <- split(SPI, SPI$SPECIES)

spi_smoo <- lapply(spi_ls, function(x) {
    m <- cbind(x$YEAR, x$SPI)
    sm <- smooth_ksmooth(m, smoothness = 4)
    df <- as.data.frame(sm)
    names(df) <- c("YEAR", "SPI")
    df$SPECIES <- unique(x$SPECIES)
    df$vernacular_fr <- unique(x$vernacular_fr)
    df$POPINFOS <- paste0(
        "<b>", df$vernacular_fr,
        # "<b>", df$SPECIES,
        "</b><br>Année <b>", floor(df$YEAR),
        "</b><br>SPI = <b>", round(df$SPI, digits = 3), "</b>"
    )
    df
})

sspi_df <- do.call("rbind", spi_smoo)

# computation of mean SPI
year_mean <- c()
for (i in years) {
    sub_year <- SPI$SPI[SPI$YEAR == i]
    year_mean <- c(year_mean, mean(sub_year, na.rm = TRUE))
}
s_mean_spi <- smooth_ksmooth(as.matrix(cbind(years, year_mean)))
df <- as.data.frame(s_mean_spi)
names(df) <- c("YEAR", "SPI")
df$SPECIES <- "Valeur moyenne"
df$vernacular_fr <- "Valeur moyenne"
df$POPINFOS <- paste0(
    # "<b>", df$SPECIES,
    "<b>", df$vernacular_fr,
    "</b><br>Année <b>", floor(df$YEAR),
    "</b><br>SPI = <b>", round(df$SPI, digits = 3), "</b>"
)

sspi_df <- rbind(sspi_df, df)

# Association d'un groupe par catégories - max, min & mean
spi2023 <- SPI[SPI$YEAR == 2023, ]
range(spi2023$SPI)
max_spe <- spi2023$SPECIES[spi2023$SPI == max(spi2023$SPI)]
min_spe <- spi2023$SPECIES[spi2023$SPI == min(spi2023$SPI)]

sspi_df$GROUPE[sspi_df$SPECIES == "Valeur moyenne"] <- "mean"
sspi_df$GROUPE[sspi_df$SPECIES == max_spe] <- "max"
sspi_df$GROUPE[sspi_df$SPECIES == min_spe] <- "min"
sspi_df$GROUPE[is.na(sspi_df$GROUPE)] <- "other"

# --------------------------------------------------------------------- #
#### figure 2B - courbes de tendance de SPI à partir des occurrences ####
# -------------------------------------------------------------------- #

# SOCC <- read.csv("./results/RANGES/SPI_OCC.csv")
SOCC <- read.csv("./results/SPI_OCC.csv")
SOCC <- SOCC[!(SOCC$SPECIES == "Information masquée"), ]
species <- as.character(unique(SOCC$SPECIES))
years <- as.numeric(unique(SOCC$YEAR))

# smoothing the curves
spi_ls <- split(SOCC, SOCC$SPECIES)

spi_smoo <- lapply(spi_ls, function(x) {
    m <- cbind(x$YEAR, x$SPI)
    sm <- smooth_ksmooth(m, smoothness = 4)
    df <- as.data.frame(sm)
    names(df) <- c("YEAR", "SPI")
    df$SPECIES <- unique(x$SPECIES)
    df$POPINFOS <- paste0(
        "<b>", df$SPECIES,
        "</b><br>Année <b>", floor(df$YEAR),
        "</b><br>SPI = <b>", round(df$SPI, digits = 3), "</b>"
    )
    df
})

sspi_df_occ <- do.call("rbind", spi_smoo)

# computation of mean SPI
year_mean <- c()
for (i in years) {
    sub_year <- SOCC$SPI[SOCC$YEAR == i]
    year_mean <- c(year_mean, mean(sub_year, na.rm = TRUE))
}
s_mean_spi_occ <- smooth_ksmooth(as.matrix(cbind(years, year_mean)))
df <- as.data.frame(s_mean_spi_occ)
names(df) <- c("YEAR", "SPI")
df$SPECIES <- "Valeur moyenne"
df$POPINFOS <- paste0(
    "<b>", df$SPECIES,
    "</b><br>Année <b>", floor(df$YEAR),
    "</b><br>SPI = <b>", round(df$SPI, digits = 3), "</b>"
)

sspi_df_occ <- rbind(sspi_df_occ, df)

# Association d'un groupe par catégories - max, min & mean
spi2023 <- SOCC[SOCC$YEAR == 2023, ]
range(spi2023$SPI)
max_spe <- spi2023$SPECIES[spi2023$SPI > 0.999]
min_spe <- spi2023$SPECIES[spi2023$SPI == min(spi2023$SPI)]

sspi_df_occ$GROUPE[sspi_df_occ$SPECIES == "Valeur moyenne"] <- "mean"
sspi_df_occ$GROUPE[sspi_df_occ$SPECIES %in% max_spe] <- "max"
sspi_df_occ$GROUPE[sspi_df_occ$SPECIES %in% min_spe] <- "min"
sspi_df_occ$GROUPE[is.na(sspi_df_occ$GROUPE)] <- "other"

# ------------------------------------------------------------------------ #
#### figure 3A - barchat SPI 2023 par groupe Nord vs Sud - aire distri ####
# ------------------------------------------------------------------------ #
# last_spi_NS <- read.csv2("./data_clean/RANGE_SPI_north_south.csv")[, -1]
sspi_df_last <- SPI[SPI$YEAR == 2023, ]

last_spi_N <- SPI[SPI$YEAR == 2023 & SPI$SPI_NORTH != 0 & SPI$SPI_SOUTH == 0, ]
last_spi_S <- SPI[SPI$YEAR == 2023 & SPI$SPI_NORTH == 0 & SPI$SPI_SOUTH != 0, ]
# --- #
df <- SPI[SPI$YEAR == 2023 & SPI$SPI_NORTH != 0 & SPI$SPI_SOUTH != 0, ]
last_spi_NS <- data.frame(SPECIES = rep(df$SPECIES, 2),
                  vernacular_fr =  rep(df$vernacular_fr, 2),
                 SPI = c(df$SPI_NORTH, df$SPI_SOUTH),
                 LOC = c(rep("Nord", dim(df)[1]), rep("Sud", dim(df)[1])))

# last_spi_NS <- left_join(last_spi_NS, info_spe2, by = join_by("SPECIES" == "observed_scientific_name"))

# ------------------------------------------------------------------------ #
#### figure 3B - barchat SPI 2023 par groupe Nord vs Sud - occurrences ####
# ------------------------------------------------------------------------ #
head(SOCC)
socc2023 <- SOCC[SOCC$YEAR == 2023, ]

last_socc_N <- socc2023[socc2023$YEAR == 2023 & socc2023$SPI_NORTH != 0 & socc2023$SPI_SOUTH == 0, ]
last_socc_S <- socc2023[socc2023$YEAR == 2023 & socc2023$SPI_NORTH == 0 & socc2023$SPI_SOUTH != 0, ]
# --- #
df2 <- socc2023[socc2023$YEAR == 2023 & socc2023$SPI_NORTH != 0 & socc2023$SPI_SOUTH != 0, ]
last_socc_NS <- data.frame(SPECIES = rep(df2$SPECIES, 2),
                #   vernacular_fr =  rep(df2$vernacular_fr, 2),
                 SPI = c(df2$SPI_NORTH, df2$SPI_SOUTH),
                 LOC = c(rep("Nord", dim(df2)[1]), rep("Sud", dim(df2)[1])))

# WARNINGS !!!! SP manquantes ici ****
# ---------------------------------------------------------- #
#### figure 6 - barchat SPI 2023 par groupe taxonomique ####
# -------------------------------------------------------- #
# select data
last_spi <- SPI[SPI$YEAR == 2023, ]
# fill informations about species
# last_spi <- left_join(last_spi, info_spe2, by = join_by("SPECIES" == "observed_scientific_name"))
