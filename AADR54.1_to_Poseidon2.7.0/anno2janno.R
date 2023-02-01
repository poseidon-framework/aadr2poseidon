library(magrittr)

#### prepare input data ####

anno <- readr::read_tsv(
  "https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1/SHARE/public.dir/v54.1_1240K_public.anno",
  col_names = T ,
  show_col_types = F ,
  skip_empty_rows = F ,
  na = c("..", "", "n/a", "na")
) %>%
  # remove empty last column
  dplyr::select(-"...36")

# make list of column names for columns_mapping.csv
# purrr::walk(colnames(anno), \(x) cat(x, "\n"))

# adopt simplified column names for convenience
mapping_reference <- readr::read_csv("AADR54.1_to_Poseidon2.7.0/column_mapping.csv")
colnames(anno) <- mapping_reference$`Simplified .anno column name`

#### construct janno columns ####

Poseidon_ID <- anno$Genetic_ID %>%
  gsub("<", "LT", .) %>%
  gsub(">", "GT", .)

Alternative_IDs <- anno$Master_ID

Collection_ID <- anno$Skeletal_Code

Source_Tissue <- anno$Skeletal_Element

AADR_Year_First_Publication <- anno$Year_First_Publication

Publication <- anno$Publication %>%
  stringr::str_extract_all(pattern = "[a-zA-Z]*[0-9]{4}|1KGPhase3") %>%
  purrr::map_chr(function(x) paste(x, collapse = ";"))


AADR_Publication <- anno$Publication

Date_Note <- anno$Date_Method
AADR_Date_Mean_BP <- anno$Date_Mean_BP
AADR_Date_SD <- anno$Date_SD

source("AADR54.1_to_Poseidon2.7.0/age_string_parser.R")
date_string_parsing_result <- split_age_string(anno$Date_Full_Info)

AADR_Date_Full_Info <- anno$Date_Full_Info

AADR_Age_Death <- anno$Age_Death

Group_Name <- anno$Group_ID

Location <- anno$Locality

country_lookup_table <- readLines("AADR54.1_to_Poseidon2.7.0/location_to_M49.tsv") %>%
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
# cbind(Country_ISO, anno$Political_Entity) %>% as.data.frame() %>% dplyr::filter(is.na(Country_ISO))

Country <- anno$Political_Entity

Latitude <- round(anno$Lat, digits = 5)

Longitude <- round(anno$Long, digits = 5)

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
    x %equalToLower% "Reference.Genome" ~ "Reference Genome" ,
    TRUE ~ "OtherCapture"
  )
}

Capture_Type <- parse_capture_type(anno$Data_Source)

AADR_Data_Source <- anno$Data_Source

Nr_Libraries <- anno$No_Libraries

AADR_Coverage_1240K <- readr::parse_number(anno$Coverage_1240k)

AADR_SNPs_1240K <- anno$SNPs_Autosomal_Targets_1240k

AADR_SNPs_HO <- anno$SNPs_Autosomal_Targets_HO

Genetic_Sex <- dplyr::case_when(anno$Molecular_Sex == "c" ~ "U", TRUE ~ anno$Molecular_Sex)

AADR_Kinship <- anno$Family_ID

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
    # make ".." to proper NA
    ifelse(x == "..", NA_character_, x) %>%
    # remove irrelevant parts of the string (before and after .)
    gsub("^[a-z]*\\.", "", .) %>%
    gsub("\\.[a-z]*$", "", .) %>%
    trimws() %>%
    unique
  }) %>%
  # make translation decision
  purrr::map_chr(function(x) {
    ifelse(length(x) > 1, "mixed", x) %>%
    ifelse(. == "Mix", "mixed", .)
  })
}

UDG <- parse_udg_treatment(anno$Library_Type)

parse_library_built <- function(x) {
  # split string list column into a proper list column
  x %>% strsplit(",") %>%
  # loop through list entries (one vector per entry)
  purrr::map(function(x) { 
    # make ".." to proper NA
    ifelse(x == "..", NA_character_, x) %>%
    # remove irrelevant parts of the string (after .)
    gsub("\\.[a-z\\.]*$", "", .) %>%
    trimws() %>%
    unique
  }) %>%
  # make translation decision
  purrr::map_chr(function(x) {
    ifelse(length(x) > 1, "mixed", x)
  })
}

Library_Built <- parse_library_built(anno$Library_Type)

AADR_Library_Type <- anno$Library_Type

AADR_Libraries <- anno$Libraries

AADR_Assessment <- anno$Assessment

AADR_Assessment_Warnings <- anno$Assessment_Warnings

#### combine results ####

res_janno_raw <- cbind(
  Poseidon_ID,
  Alternative_IDs,
  Collection_ID,
  Source_Tissue,
  AADR_Year_First_Publication,
  Publication,
  AADR_Publication,
  Date_Note,
  AADR_Date_Mean_BP,
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
  Capture_Type,
  AADR_Data_Source,
  Nr_Libraries,
  AADR_Coverage_1240K,
  AADR_SNPs_1240K,
  AADR_SNPs_HO,
  Genetic_Sex,
  AADR_Kinship,
  Y_Haplogroup,
  AADR_Y_Haplogroup_ISOGG,
  AADR_Coverage_mtDNA,
  MT_Haplogroup,
  AADR_MT_Match_Consensus,
  Damage,
  AADR_Sex_Ratio,
  UDG,
  Library_Built,
  AADR_Library_Type,
  AADR_Libraries,
  AADR_Assessment,
  AADR_Assessment_Warnings
) %>% tibble::tibble()

res_janno <- poseidonR::as.janno(res_janno_raw)

poseidonR::write_janno(res_janno, path = "AADR54.1_to_Poseidon2.7.0/tmp/AADR_1240K.janno")
