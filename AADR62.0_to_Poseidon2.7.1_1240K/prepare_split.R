library(magrittr)

#### read clean .janno file ####

aadr_janno <- janno::read_janno("AADR62.0_to_Poseidon2.7.1_1240K/tmp/AADR_1240K.janno", validate = F)

#### define subsets ####

modern <- aadr_janno %>% dplyr::filter(
  Date_Type == "modern"
)
europe_ancient_north <- aadr_janno %>%
  dplyr::anti_join(modern, by = "Poseidon_ID") %>%
  dplyr::filter(
    Longitude >= -12 & Longitude <= 35,
    Latitude >= 46 & Latitude <= 65,
  )
europe_ancient_south <- aadr_janno %>%
  dplyr::anti_join(modern, by = "Poseidon_ID") %>%
  dplyr::filter(
    Longitude >= -12 & Longitude <= 35,
    Latitude >= 34 & Latitude < 46,
  )
beyond_europe_ancient <- aadr_janno %>%
  dplyr::anti_join(modern, by = "Poseidon_ID") %>%
  dplyr::anti_join(europe_ancient_north, by = "Poseidon_ID") %>%
  dplyr::anti_join(europe_ancient_south, by = "Poseidon_ID")

#### sanity checks to make validate the subsets ####

nrow(aadr_janno) == nrow(modern) + nrow(europe_ancient_north) + nrow(europe_ancient_south) + nrow(beyond_europe_ancient)
setequal(
  aadr_janno$Poseidon_ID,
  c(
    modern$Poseidon_ID,
    europe_ancient_north$Poseidon_ID,
    europe_ancient_south$Poseidon_ID,
    beyond_europe_ancient$Poseidon_ID)
)
nrow(modern)/nrow(aadr_janno)

#### write forgeScript files ###

writeLines(
  paste0("<", modern$Poseidon_ID, ">"),
  "AADR62.0_to_Poseidon2.7.1_1240K/tmp/subsetModern.pfs"
)
writeLines(
  paste0("<", europe_ancient_north$Poseidon_ID, ">"),
  "AADR62.0_to_Poseidon2.7.1_1240K/tmp/subsetEuropeAncientNorth.pfs"
)
writeLines(
  paste0("<", europe_ancient_south$Poseidon_ID, ">"),
  "AADR62.0_to_Poseidon2.7.1_1240K/tmp/subsetEuropeAncientSouth.pfs"
)
writeLines(
  paste0("<", beyond_europe_ancient$Poseidon_ID, ">"),
  "AADR62.0_to_Poseidon2.7.1_1240K/tmp/subsetBeyondEuropeAncient.pfs"
)
