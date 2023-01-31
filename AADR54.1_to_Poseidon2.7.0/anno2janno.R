library(magrittr)

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

# construct janno columns

Poseidon_ID <- anno$Genetic_ID %>%
  gsub("<", "LT", .) %>%
  gsub(">", "GT", .)

Alternative_IDs <- anno$Master_ID

Collection_ID <- anno$Skeletal_Code

Source_Tissue <- anno$Skeletal_Element

AADR_Year_First_Publication <- anno$Year_First_Publication

Publication <- stringr::str_extract_all(anno$Publication, pattern = "[a-zA-Z]*[0-9]{4}|1KGPhase3")
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

Country <- anno$Political_Entity

Latitude <- round(anno$Lat, digits = 5)

Logitude <- round(anno$Lat, digits = 5)

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

AADR_Coverage_1240K <- anno$Coverage_1240k

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
