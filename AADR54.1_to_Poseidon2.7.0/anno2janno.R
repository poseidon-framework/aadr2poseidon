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

# translating the Data source column
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


