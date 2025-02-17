library(magrittr)

#### prepare input data ####
# this assumes the .anno file was already downloaded

anno_lines <- readLines("AADR62.0_to_Poseidon2.7.1_1240K/tmp/v62.0_1240k_public.anno")

# replace double quotes in general with single quotes
anno_lines <- purrr::map_chr(anno_lines, \(x) { gsub("\"", "'", x) })

anno <- readr::read_tsv(
  paste0(anno_lines, "\n"),
  col_names = T,
  show_col_types = F,
  skip_empty_rows = F,
  na = c("..", "", "n/a", "na")
)

# adopt simplified column names for convenience
mapping_reference <- readr::read_csv("AADR62.0_to_Poseidon2.7.1_1240K/column_mapping.csv")
colnames(anno) <- mapping_reference$`Simplified .anno column name` ## WARNING!!! This works simply on the order base (not recognizing the actual column names so column_mapping.csv needs to be adjusted for each version of AADR release)


#### construct janno columns ####

Poseidon_ID <- anno$Genetic_ID %>%
  gsub("<", "LT", .) %>%
  gsub(">", "GT", .)
# tibble::tibble(a = Poseidon_ID, b = anno$Genetic_ID) %>% dplyr::filter(a != b) %>% View()

Genotype_Ploidy <- anno %$%
  dplyr::case_when(
    grepl(".DG$", Genetic_ID) ~ "diploid",
    .default = "haploid"
  )
# tibble::tibble(anno$Genetic_ID, Genotype_Ploidy) %>% View()

Alternative_IDs <- anno$Master_ID
Collection_ID <- anno$Skeletal_Code
Source_Tissue <- anno$Skeletal_Element

## Publication related columns
AADR_Year_First_Publication <- anno$Year_First_Publication
AADR_Publication <- anno$Publication
AADR_Publication_DOI <- anno$Publication_DOI

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
  "ChangmaiScientificReports2022", "10.1038/s41598-022-26799-3",
  "GerberbioRxiv2024", "10.1101/2024.05.29.596386",
  "NikitinPLoSOne2023", "10.1371/journal.pone.0285449",
  "Pruefer2017", "10.1126/science.aao1887",
  "ReichWorkingPaper2016", NA_character_, # this is a tricky one - it doesn't have a DOI
  "SiskaScienceAdvances2017", "10.1126/science.aao1807",
  "SjogrenPLoSOne2020", "10.1371/journal.pone.0241278",
  "HaakLazaridis2015", "10.1038/nature14317",
  "HarneyScience2023", "10.1126/science.ade4995",
  "LiScience2008", "10.1126/science.1153717",
  "JakobssonNature2008", "10.1038/nature06742",
  "GreenScience2010", "10.1126/science.1188021",
  "KellerNatureCommunications2012", "10.1038/ncomms1701",
  "NarasimahPattersonScience2019", "10.1126/science.aat7487",
  "FuNature2015", "10.1038/nature14558"
)

complete_keys_and_dois <- dplyr::rows_patch(all_keys_with_dois, manually_recovered_dois, by = "key")

# fixing wrong dois
complete_keys_and_dois$doi[complete_keys_and_dois$key == "FeldmanNatureCommunications2019"] <-
  "10.1038/s41467-019-09209-7"
complete_keys_and_dois$doi[complete_keys_and_dois$key == "StolarekGenomeBio2023"] <-
  "10.1186/s13059-023-03013-9"

# this is to be used in prepare_bib_file.R
saveRDS(
  complete_keys_and_dois,
  file = "AADR62.0_to_Poseidon2.7.1_1240K/tmp/complete_keys_and_dois.rds"
)

## Dating related columns
Date_Note <- anno$Date_Method

source("AADR62.0_to_Poseidon2.7.1_1240K/age_string_parser.R")
date_string_parsing_result <- split_age_string(anno$Date_Full_Info)

AADR_Date_Full_Info <- anno$Date_Full_Info

Date_BC_AD_Median <- ifelse(
  date_string_parsing_result$Date_Type == "modern",
  2000,
  -anno$Date_Mean_BP + 1950 # turn to BC/AD age
)
AADR_Date_SD <- anno$Date_SD

# inspect the parsing results
# dplyr::bind_cols(
#   full = AADR_Date_Full_Info,
#   date_string_parsing_result,
#   median = Date_BC_AD_Median
# ) %>% View()

AADR_Age_Death <- anno$Age_Death


## Columns overlapping with the .ind file
# read .ind file for correct group and sex information
ind_file <- readLines("AADR62.0_to_Poseidon2.7.1_1240K/tmp/v62.0_1240k_public.ind") %>%
  trimws() %>%
  paste0("\n") %>%
  gsub("\\s{2,}", " ", .) %>%
  readr::read_delim(" ", col_names = c("id", "sex", "group"))

# tibble::tibble(.ind = ind_file$id, .anno = anno$Genetic_ID) %>%
#   dplyr::filter(.ind != .anno)
# tibble::tibble(.ind = ind_file$group, .anno = anno$Group_ID) %>%
#   dplyr::filter(.ind != .anno)
# tibble::tibble(.ind = ind_file$sex, .anno = anno$Molecular_Sex) %>%
#   dplyr::filter(.ind != .anno)

# find non-ASCII characters in the group names
ind_file$group[grepl("[^ -~]", ind_file$group)]

# replace ø by o here and in AADR_1240K.ind
ind_file$group <- gsub("ø", "o", ind_file$group)
system("sed -i -e 's/ø/o/g' AADR62.0_to_Poseidon2.7.1_1240K/tmp/AADR_1240K.ind")

Group_Name <- ind_file$group

#ind_file$sex %>% table()
Genetic_Sex <- ind_file$sex

## Spatial columns
Location <- anno$Locality

country_lookup_table <- readLines("AADR62.0_to_Poseidon2.7.1_1240K/location_to_M49.tsv") %>%
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
  if (x == "Gernamy") { return("DE") } # special case
  position <- country_lookup_table$aadr_pol_entity == x
  if (any(position)) {
    country_lookup_table$alpha2[country_lookup_table$aadr_pol_entity == x]
  } else {
    NA_character_
  }
}

Country_ISO <- purrr::map_chr(anno$Political_Entity, lookup_alpha2)
# which(is.na(Country_ISO))
# cbind(Country_ISO, anno$Political_Entity) %>% as.data.frame() %>% dplyr::filter(is.na(Country_ISO))

Country <- anno$Political_Entity
Latitude <- round(anno$Lat, digits = 5)
Longitude <- round(anno$Long, digits = 5)

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

Capture_Type <- parse_capture_type(anno$Data_Source)
AADR_Data_Source <- anno$Data_Source
Nr_Libraries <- anno$No_Libraries
AADR_SNPs_1240K <- anno$SNPs_Autosomal_Targets_1240k
AADR_SNPs_HO <- anno$SNPs_Autosomal_Targets_HO
Y_Haplogroup <- anno$Y_Haplogroup_Terminal_Mutation
AADR_Y_Haplogroup_ISOGG <- anno$Y_Haplogroup_ISOGG
AADR_Coverage_mtDNA <- anno$Coverage_mtDNA
MT_Haplogroup <- anno$mtDNA_Haplogroup
AADR_MT_Match_Consensus <- anno$mtDNA_Match_Consensus
Damage <- anno$Damage
AADR_Sex_Ratio <- anno$Sex_Ratio

parse_udg_treatment <- function(x) {
  # split string list column into a proper list column
  x %>% strsplit(",") %>%
  # loop through list entries (one vector per entry)
  purrr::map(function(x) {
    stringr::str_extract_all(x, "((half)|(minus)|(plus)|(mixed)|(Mix))") %>%
      purrr::compact() %>%
      unlist() %>%
      unique
  }) %>%
  # make translation decision
  purrr::map_chr(function(x) {
    if (is.null(x)) {
      NA_character_
    } else if (all(is.na(x))) {
      NA_character_
    } else if (length(x) > 1) {
      "mixed"
    } else if (x == "Mix") {
      "mixed"
    } else {
      x
    }
  })
}

UDG <- parse_udg_treatment(anno$Library_Type)
# cbind(UDG, anno$Library_Type) %>% unique() %>% View()

parse_library_built <- function(x) {
  # split string list column into a proper list column
  x %>% strsplit(",") %>%
  # loop through list entries (one vector per entry)
  purrr::map(function(x) {
    stringr::str_extract_all(x, "((ds)|(ss))") %>%
      purrr::compact() %>%
      unlist() %>%
      unique
  }) %>%
  # make translation decision
  purrr::map_chr(function(x) {
    if (is.null(x)) {
      NA_character_
    } else if (all(is.na(x))) {
      NA_character_
    } else if (length(x) > 1) {
      "mixed"
    } else {
      x
    }
  })
}

Library_Built <- parse_library_built(anno$Library_Type)
# cbind(Library_Built, anno$Library_Type) %>% unique() %>% View()

AADR_Library_Type <- anno$Library_Type

Library_Names <- anno$Libraries %>%
  stringr::str_split(",") %>%
  purrr::map(function(x) {
    if (all(is.na(x))) { NULL } else { trimws(x) }
  })
# cbind(Library_Names, anno$Libraries) %>% unique() %>% View()

AADR_Data_PID <- anno$Data_PID
AADR_ROHmin4cM <- anno$ROH_min4cM
AADR_ROHmin20cM <- anno$ROH_min20cM
AADR_Suffices <- anno$Call_Suffix
AADR_Y_Haplogroup_Manual <- anno$Y_Haplogroup_Manual
AADR_ANGSD_MoM95 <- anno$ANGSD_MoM95CI
AADR_hapConX_95 <- anno$hapCon_95CI
AADR_Endogenous <- anno$Endogenous

## Assessment columns
AADR_Assessment <- anno$Assessment
AADR_Assessment_Warnings <- anno$Assessment_Warnings

#### combine results ####

res_janno_raw <- cbind(
  Poseidon_ID,
  Genotype_Ploidy,
  Alternative_IDs,
  Collection_ID,
  Source_Tissue,
  AADR_Year_First_Publication,
  I(Publication),
  AADR_Publication,
  AADR_Publication_DOI,
  AADR_Data_PID,
  Date_Note,
  Date_BC_AD_Median,
  AADR_Date_SD,
  date_string_parsing_result,
  AADR_Date_Full_Info,
  AADR_Age_Death,
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
  Nr_Libraries,
  AADR_SNPs_1240K,
  AADR_SNPs_HO,
  Genetic_Sex,
  AADR_ROHmin4cM,
  AADR_ROHmin20cM,
  Y_Haplogroup,
  AADR_Y_Haplogroup_ISOGG,
  AADR_Y_Haplogroup_Manual,
  AADR_Coverage_mtDNA,
  MT_Haplogroup,
  AADR_MT_Match_Consensus,
  Damage,
  AADR_Sex_Ratio,
  AADR_ANGSD_MoM95,
  AADR_hapConX_95,
  UDG,
  Library_Built,
  AADR_Library_Type,
  I(Library_Names),
  AADR_Endogenous,
  AADR_Assessment,
  AADR_Assessment_Warnings
) %>% tibble::tibble()


res_janno <- janno::as.janno(res_janno_raw)

#### write .janno file ####

janno::write_janno(
  res_janno,
  path = "AADR62.0_to_Poseidon2.7.1_1240K/tmp/AADR_1240K.janno"
)

#### inspect result ####

#issues <- janno::validate_janno("AADR62.0_to_Poseidon2.7.1_1240K/tmp/AADR_1240K.janno")
#issues %>% View()

#write.table(issues, file = "AADR62.0_to_Poseidon2.7.1_1240K/tmp/issues.tsv", sep = "\t")
