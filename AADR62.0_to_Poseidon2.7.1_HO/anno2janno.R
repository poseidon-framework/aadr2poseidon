library(magrittr)

#### prepare input data ####

# relevant individuals for the HO dataset
indsOnlyInHO <- readLines("AADR62.0_to_Poseidon2.7.1_HO//tmp/subsetOnlyHO.pfs") %>%
  stringr::str_sub(start = 2, end = -2)

# anno dataset
anno_lines <- readLines("AADR62.0_to_Poseidon2.7.1_HO/tmp/v62.0_HO_public.anno")

# filter raw anno dataset to HO subset
anno_lines_filter <- anno_lines %>%
  strsplit(split = "\t") %>%
  purrr::map_lgl(
    function(x) {
      id <- x[1]
      id_modified <- gsub(",", "_", id)
      id_modified %in% indsOnlyInHO
    }
  )

anno_lines_filtered <- anno_lines[anno_lines_filter]

# sanity check
length(anno_lines_filtered) == length(indsOnlyInHO)

# add header line
anno_lines_HO <- c(anno_lines[1], anno_lines_filtered)

# replace double quotes in general with single quotes
anno_lines_HO <- purrr::map_chr(anno_lines_HO, \(x) { gsub("\"", "'", x) })

anno <- readr::read_tsv(
  paste0(anno_lines_HO, "\n"),
  col_names = T ,
  show_col_types = F ,
  skip_empty_rows = F ,
  na = c("..", "", "n/a", "na"),
  guess_max = length(anno_lines_HO)
)

# make list of column names for columns_mapping.csv
# purrr::walk(colnames(anno), \(x) cat(x, "\n"))

# adopt simplified column names for convenience
mapping_reference <- readr::read_csv("AADR62.0_to_Poseidon2.7.1_HO/column_mapping.csv")
colnames(anno) <- mapping_reference$`Simplified .anno column name`

#### construct janno columns ####

Poseidon_ID <- anno$Genetic_ID %>%
  gsub(",", "_", .)
# tibble::tibble(a = Poseidon_ID, b = anno$Genetic_ID) %>% dplyr::filter(a != b) %>% View()

Genotype_Ploidy <- anno %$%
  dplyr::case_when(
    grepl(".DG$", Genetic_ID) ~ "diploid",
    .default = "haploid"
  )
# tibble::tibble(anno$Genetic_ID, Genotype_Ploidy) %>% View()

Alternative_IDs <- anno$Master_ID
Collection_ID <- anno$Skeletal_Code
# Source_Tissue: table(anno$Skeletal_Element, useNA = "always")

## Publication related columns
AADR_Year_First_Publication <- anno$Year_First_Publication
AADR_Publication <- anno$Publication
AADR_Publication_DOI <- anno$Publication_DOI
AADR_Data_PID <- anno$Data_PID

publication_list <- anno$Publication %>%
  stringr::str_extract_all(pattern = "[a-zA-Z]{5,}[0-9]{4}|1KGPhase3") %>%
  purrr::map(function(x) {
    if (all(is.na(x))) { NULL } else { x }
  })
# cbind(publication_list, anno$Publication) %>% unique %>% View()

Publication <- publication_list %>%
  purrr::map(\(x) c(x, "AADRv620", "AADR"))

# preparation for bibtex entry compilation in prepare_bib_file.R
publications_and_dois_raw <- purrr::map2_dfr(
  publication_list,
  anno$Publication_DOI,
  function(pubkeys, potentialdoi) {
    pubkey <- if(!is.null(pubkeys)) { pubkeys[[1]] } else { NA_character_ }
    doi <- stringr::str_extract(potentialdoi, "(?i)10.\\d{4,9}[-._;()/:A-Z0-9]+")
    tibble::tibble(
      key = pubkey,
      doi = doi
    )
  }
) %>% unique()

key_and_dois <- publications_and_dois_raw %>%
  dplyr::group_by(key) %>%
  dplyr::slice_min(doi) %>%
  dplyr::ungroup() %>%
  dplyr::filter(!is.na(key))

all_keys_as_used <- tibble::tibble(
  key = publication_list %>% unlist() %>% unique()
)

all_keys_with_dois <- dplyr::full_join(key_and_dois, all_keys_as_used, by = "key")
# this shows the entries without DOI -> must be added manually
all_keys_with_dois %>%
  dplyr::filter(is.na(doi))

manually_recovered_dois <- tibble::tribble(
  ~key, ~doi,
  "VyasDryadDigitalRepository2017", "10.5061/dryad.1pm3r",
)

complete_keys_and_dois <- dplyr::rows_patch(all_keys_with_dois, manually_recovered_dois, by = "key")

# this is to be used in prepare_bib_file.R
saveRDS(
  complete_keys_and_dois,
  file = "AADR62.0_to_Poseidon2.7.1_HO/tmp/complete_keys_and_dois.rds"
)

## Dating related columns
Date_Note <- anno$Date_Method
Date_Type <- "modern"
Date_BC_AD_Median <- 2000
AADR_Date_Mean_BP <- anno$Date_Mean_BP
AADR_Date_SD <- anno$Date_SD
AADR_Date_Full_Info <- anno$Date_Full_Info

# AADR_Age_Death: table(anno$Age_Death, useNA = "always")

## Columns overlapping with the .ind file
# read .fam file for correct group and sex information
ind_file <- readr::read_tsv(
  "AADR62.0_to_Poseidon2.7.1_HO/tmp/AADR_HO_without_1240K.fam",
  col_names = c("group", "id", NA, NA, "sex", NA)
  ) %>%
  dplyr::mutate(
    sex = dplyr::case_match(
      sex,
      0 ~ "U",
      1 ~ "M",
      2 ~ "F"
    )
  )

tibble::tibble(.ind = ind_file$id, .anno = anno$Genetic_ID) %>%
  dplyr::filter(.ind != .anno)
tibble::tibble(.ind = ind_file$id, .anno = Poseidon_ID) %>%
  dplyr::filter(.ind != .anno)
tibble::tibble(.ind = ind_file$group, .anno = anno$Group_ID) %>%
  dplyr::filter(.ind != .anno)
tibble::tibble(.ind = ind_file$sex, .anno = anno$Molecular_Sex) %>%
  dplyr::filter(.ind != .anno)

# check for non-ASCII characters in the group names
ind_file$group[grepl("[^ -~]", ind_file$group)]

Genetic_Sex <- anno$Molecular_Sex
Group_Name <- anno$Group_ID

## Spatial columns
Location <- anno$Locality

country_lookup_table <- readLines("AADR62.0_to_Poseidon2.7.1_HO/location_to_M49.tsv") %>%
  magrittr::extract(-2) %>%
  gsub(";", "\t", .) %>%
  paste0(collapse = "\n") %>%
  readr::read_tsv(na = c(".." ,"")) %>%
  dplyr::select(
    aadr_pol_entity = `Political Entity`,
    alpha2 = `ISO-alpha2 Code`
  )
lookup_alpha2 <- function(x) {
  if (is.na(x)) { return(NA_character_) }
  position <- country_lookup_table$aadr_pol_entity == x
  if (any(position)) {
    country_lookup_table$alpha2[country_lookup_table$aadr_pol_entity == x]
  } else {
    NA_character_
  }
}

Country_ISO <- purrr::map_chr(anno$Political_Entity, lookup_alpha2)
# table(Country_ISO, useNA = "always")
# dplyr::bind_cols(iso = Country_ISO, pe = anno$Political_Entity) %>%
# dplyr::filter(is.na(Country_ISO))

Country <- anno$Political_Entity
Latitude <- round(anno$Lat %>% as.numeric(), digits = 5)
Longitude <- round(anno$Long %>% as.numeric(), digits = 5)

## Columns related to genetic data preparation
AADR_Pulldown_Strategy <- anno$Pulldown_Strategy

# helper function to compare to strings irrespective of case
`%equalToLower%` <- function(a, b) {
  tolower(a) == tolower(b)
}

parse_capture_type <- function(x) {
  dplyr::case_when( 
    x %equalToLower% "1240K" ~ "1240K",
    x %equalToLower% "Twist1.4M" ~ "TwistAncientDNA",
    x %equalToLower% "Shotgun" ~ "Shotgun",
    x %equalToLower% "Shotgun.diploid" ~ "Shotgun",
    x %equalToLower% "Reference.Genome" ~ "ReferenceGenome" ,
    TRUE ~ "OtherCapture"
  )
}

# many of these columns are empty for the modern HO data
AADR_Suffices <- anno$Call_Suffix
Capture_Type <- parse_capture_type(anno$Data_Source)
AADR_Data_Source <- anno$Data_Source
# Nr_Libraries: table(anno$No_Libraries, useNA = "always")
# AADR_SNPs_1240K: table(anno$SNPs_Autosomal_Targets_1240k, useNA = "always")
AADR_SNPs_HO <- anno$SNPs_Autosomal_Targets_HO
# AADR_ROHmin4cM: table(anno$ROH_min4cM, useNA = "always")
# AADR_ROHmin20cM: table(anno$ROH_min20cM, useNA = "always")
# AADR_Y_Haplogroup_Terminal_Mutation: table(anno$Y_Haplogroup_Terminal_Mutation, useNA = "always")
# AADR_Y_Haplogroup_ISOGG: table(anno$Y_Haplogroup_ISOGG, useNA = "always")
AADR_Y_Haplogroup_Manual <- anno$Y_Haplogroup_Manual
# AADR_Coverage_mtDNA: table(anno$Coverage_mtDNA, useNA = "always")
# MT_Haplogroup: table(anno$mtDNA_Haplogroup, useNA = "always")
# AADR_MT_Match_Consensus: table(anno$mtDNA_Match_Consensus, useNA = "always")
# Damage: table(anno$Damage, useNA = "always")
# AADR_Sex_Ratio: table(anno$Sex_Ratio, useNA = "always")
# AADR_ANGSD_MoM95: table(anno$ANGSD_MoM95CI, useNA = "always")
# AADR_hapConX_95: table(anno$hapCon_95CI, useNA = "always")
# AADR_Library_Type: table(anno$Library_Type, useNA = "always")
# Library_Names: table(anno$Libraries, useNA = "always")
# AADR_Endogenous: table(anno$Endogenous, useNA = "always")

## Assessment columns
AADR_Assessment <- anno$Assessment
AADR_Assessment_Warnings <- anno$Assessment_Warnings

#### combine results ####

res_janno_raw <- tibble::tibble(
  Poseidon_ID,
  Genotype_Ploidy,
  Alternative_IDs,
  Collection_ID,
  AADR_Year_First_Publication,
  Publication = I(Publication),
  AADR_Publication,
  AADR_Publication_DOI,
  AADR_Data_PID,
  Date_Type,
  Date_BC_AD_Median,
  AADR_Date_Mean_BP,
  AADR_Date_SD,
  AADR_Date_Full_Info,
  Group_Name,
  Location,
  Country_ISO,
  Country,
  Latitude,
  Longitude,
  AADR_Pulldown_Strategy,
  AADR_Suffices,
  Capture_Type,
  AADR_Data_Source,
  AADR_SNPs_HO,
  Genetic_Sex,
  AADR_Y_Haplogroup_Manual,
  AADR_Assessment,
  AADR_Assessment_Warnings
)

res_janno <- janno::as.janno(res_janno_raw)

#### write .janno file ####

janno::write_janno(
  res_janno,
  path = "AADR62.0_to_Poseidon2.7.1_HO/tmp/AADR_HO_without_1240K_Publications_Incomplete.janno"
)

#### inspect result ####

issues <- janno::validate_janno("AADR62.0_to_Poseidon2.7.1_HO/tmp/AADR_HO_without_1240K_Publications_Incomplete.janno")
issues %>% View()
