library(magrittr)

#### prepare input data ####

# relevant individuals for the HO dataset
indsOnlyInHO <- readLines("AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/subsetOnlyHO.pfs") %>%
  stringr::str_sub(start = 2, end = -2)

# anno dataset
anno_lines <- readLines("AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/v54.1.p1_HO_public.anno")

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
# anno_lines_HO <- c(anno_lines[1], anno_lines_filtered)

# replace double quotes in general with single quotes
#anno_lines <- purrr::map_chr(anno_lines, \(x) { gsub("\"", "'", x) })

anno <- readr::read_tsv(
  paste0(anno_lines_HO, "\n"),
  col_names = T ,
  show_col_types = F ,
  skip_empty_rows = F ,
  na = c("..", "", "n/a", "na")
)

# make list of column names for columns_mapping.csv
# purrr::walk(colnames(anno), \(x) cat(x, "\n"))

# adopt simplified column names for convenience
mapping_reference <- readr::read_csv("AADR54.1.p1_to_Poseidon2.7.0_HO/column_mapping.csv")
colnames(anno) <- mapping_reference$`Simplified .anno column name`

#### construct janno columns ####
# for future versions note that some columns were entirely removed here, because they were empty

Poseidon_ID <- anno$Genetic_ID %>%
  gsub(",", "_", .)
# tibble::tibble(a = Poseidon_ID, b = anno$Genetic_ID) %>% dplyr::filter(a != b) %>% View()

Alternative_IDs <- anno$Master_ID

# anno$Skeletal_Code %>% is.na() %>% all()
# Collection_ID <- anno$Skeletal_Code

# anno$Skeletal_Element %>% is.na() %>% all()
# Source_Tissue <- anno$Skeletal_Element

AADR_Year_First_Publication <- anno$Year_First_Publication

Publication_list <- anno$Publication %>%
  stringr::str_extract_all(pattern = "[a-zA-Z]{5,}[0-9]{4}|1KGPhase3") %>%
  purrr::map(function(x) {
    if (all(is.na(x))) { NULL } else { x }
  })
# cbind(Publication_list, anno$Publication) %>% unique %>% View()

# this is informed by the observations in prepare_bib_file.R!
# skip in first run: Publication_list -> Publication_cleaned
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

Date_Type <- "modern"

AADR_Date_Mean_BP <- anno$Date_Mean_BP

AADR_Date_SD <- anno$Date_SD

AADR_Date_Full_Info <- anno$Date_Full_Info

Group_Name <- anno$Group_ID

Location <- anno$Locality

country_lookup_table <- readLines("AADR54.1.p1_to_Poseidon2.7.0_HO/location_to_M49.tsv") %>%
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
# cbind(Country_ISO, anno$Political_Entity) %>% as.data.frame() %>% dplyr::filter(is.na(Country_ISO))

Country <- anno$Political_Entity

Latitude <- round(anno$Lat %>% as.numeric(), digits = 5)

Longitude <- round(anno$Long %>% as.numeric(), digits = 5)

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

AADR_SNPs_HO <- anno$SNPs_Autosomal_Targets_HO

Genetic_Sex <- anno$Molecular_Sex

AADR_Assessment <- anno$Assessment

#### combine results ####

res_janno_raw <- tibble::tibble(
  Poseidon_ID,
  Alternative_IDs,
  AADR_Year_First_Publication,
  Publication,
  AADR_Publication,
  Date_Type,
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
  Capture_Type,
  AADR_Data_Source,
  AADR_SNPs_HO,
  Genetic_Sex,
  AADR_Assessment
)

res_janno <- janno::as.janno(res_janno_raw)

#### write .janno file ####

janno::write_janno(
  res_janno,
  path = "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/AADR_HO_without_1240K.janno"
)

#### inspect result ####

issues <- janno::validate_janno("AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/AADR_HO_without_1240K.janno")
issues %>% View()
