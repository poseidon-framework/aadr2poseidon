library(magrittr)

#### prepare input data ####
# this assumes the .anno file was downloaded

anno_lines <- readLines("AADR54.1_to_Poseidon2.7.0/tmp/v54.1.p1_1240K_public.anno")

# remove malicious quotes in .anno file
anno_lines[3301] <- gsub("\"384-202 calBCE", "384-202 calBCE", anno_lines[3301])
anno_lines[3302] <- gsub("\"381-201 calBCE", "381-201 calBCE", anno_lines[3302])

# replace double quotes in general with single quotes
anno_lines <- purrr::map_chr(anno_lines, \(x) { gsub("\"", "'", x) })

anno <- readr::read_tsv(
  paste0(anno_lines, "\n"),
  col_names = T ,
  show_col_types = F ,
  skip_empty_rows = F ,
  na = c("..", "", "n/a", "na")
)

# make list of column names for columns_mapping.csv
# purrr::walk(colnames(anno), \(x) cat(x, "\n"))

# adopt simplified column names for convenience
mapping_reference <- readr::read_csv("AADR54.1_to_Poseidon2.7.0/column_mapping.csv")
colnames(anno) <- mapping_reference$`Simplified .anno column name`

# renaming duplicates

# anno %>%
#   dplyr::mutate(index = 1:nrow(.)) %>%
#   dplyr::group_by(Genetic_ID) %>%
#   dplyr::filter(dplyr::n() > 1) %>% View()

#### construct janno columns ####

Poseidon_ID <- anno$Genetic_ID %>%
  gsub("<", "LT", .) %>%
  gsub(">", "GT", .)
# tibble::tibble(a = Poseidon_ID, b = anno$Genetic_ID) %>% dplyr::filter(a != b) %>% View()

Alternative_IDs <- anno$Master_ID

Collection_ID <- anno$Skeletal_Code

Source_Tissue <- anno$Skeletal_Element

AADR_Year_First_Publication <- anno$Year_First_Publication

Publication_list <- anno$Publication %>%
  stringr::str_extract_all(pattern = "[a-zA-Z]{5,}[0-9]{4}|1KGPhase3") %>%
  purrr::map(function(x) {
    if (all(is.na(x))) { NULL } else { x }
  })
# cbind(Publication_list, anno$Publication) %>% unique %>% View()

# this is informed by the observations in prepare_bib_file.R!
key_replacement <- tibble::tribble(
  ~bad, ~good,
  "RaghavanNature2013", "RaghavanNature2014",
  "Olalde2014", "OlaldeNature2014",
  "Gamba2014",  "GambaNatureCommunications2014",
  "SiskaScienceAdvances2017", "SikoraScience2017"
)

# replace bad keys
Publication_cleaned <- Publication_list %>%
  purrr::map(\(pubs) {
    if (is.null(pubs)) { NULL } else {
      purrr::map_chr(pubs, \(pub) {
        if (pub %in% key_replacement$bad) {
          key_replacement$good[pub == key_replacement$bad]
        } else { pub }
      })
    }
  })
#tibble::tibble(a = Publication_cleaned, b = Publication_list) %>%
#  dplyr::filter(paste(a) != paste(b)) %>% View()
Publication <- Publication_cleaned %>%
  purrr::map_chr(\(x) paste0(x, collapse = ";"))

AADR_Publication <- anno$Publication

Date_Note <- anno$Date_Method
AADR_Date_Mean_BP <- anno$Date_Mean_BP
AADR_Date_SD <- anno$Date_SD

# fix obviously wrong entry
anno$Date_Full_Info[12786] <- "5350-5250 BCE"

source("AADR54.1_to_Poseidon2.7.0/age_string_parser.R")
date_string_parsing_result <- split_age_string(anno$Date_Full_Info)

AADR_Date_Full_Info <- anno$Date_Full_Info

AADR_Age_Death <- anno$Age_Death

# read .ind file for correct group and sex information
ind_file <- readLines("AADR54.1_to_Poseidon2.7.0/tmp/v54.1.p1_1240K_public.ind") %>%
  trimws() %>%
  paste0("\n") %>%
  gsub("\\s{2,}", " ", .) %>%
  readr::read_delim(" ", col_names = c("id", "sex", "group"))
# tibble::tibble(a = ind_file$group, b = anno$Group_ID) %>%
#   dplyr::filter(a != b)

Group_Name <- ind_file$group

anno$Locality[10823] <- anno$Locality[10824] <- "Valencian Community, Valencia/Valencia, Bocairent, La Coveta Empareta"

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
    x %equalToLower% "Reference.Genome" ~ "ReferenceGenome" ,
    TRUE ~ "OtherCapture"
  )
}

Capture_Type <- parse_capture_type(anno$Data_Source)

AADR_Data_Source <- anno$Data_Source

Nr_Libraries <- anno$No_Libraries

AADR_Coverage_1240K <- readr::parse_number(anno$Coverage_1240k)

AADR_SNPs_1240K <- anno$SNPs_Autosomal_Targets_1240k

AADR_SNPs_HO <- anno$SNPs_Autosomal_Targets_HO

#anno[sex_in_ind_file != anno$Molecular_Sex,] %>% View()
# There is just one case where "c" should be "M"
Genetic_Sex <- dplyr::case_when(ind_file$sex == "c" ~ "U", TRUE ~ ind_file$sex )
#Genetic_Sex %>% table()

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

# replace wrong delimiters
semicolon_delimited <- anno$Libraries[c(1764, 4372:4407, 4679, 9591, 9592, 10303)]
anno$Libraries[c(1764, 4372:4407, 4679, 9591, 9592, 10303)] <- semicolon_delimited %>%
  gsub(",", "", .) %>%
  gsub(";", ",", .)

Library_Names <- anno$Libraries %>%
  stringr::str_split(",") %>%
  purrr::map(function(x) {
    if (all(is.na(x))) { NULL } else { trimws(x) }
  })
# cbind(Library_Names, anno$Libraries) %>% unique() %>% View()

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
  I(Library_Names),
  AADR_Assessment,
  AADR_Assessment_Warnings
) %>% tibble::tibble()

res_janno <- janno::as.janno(res_janno_raw)

janno::write_janno(res_janno, path = "AADR54.1_to_Poseidon2.7.0/tmp/AADR_1240K.janno")


#### inspect result ####

issues <- janno::validate_janno("AADR54.1_to_Poseidon2.7.0/tmp/AADR_1240K.janno")

issues %>% View()
