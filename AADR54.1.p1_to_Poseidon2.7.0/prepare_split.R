library(magrittr)

aadrJanno <- poseidonR::read_janno("AADR54.1.p1_to_Poseidon2.7.0/tmp/AADR_1240K.janno", validate = F)

# define subsets
modern <- aadrJanno %>% dplyr::filter(
  Date_Type == "modern"
)

europe_ancient <- aadrJanno %>%
  dplyr::anti_join(modern, by = "Poseidon_ID") %>%
  dplyr::filter(
    Longitude >= -12 & Longitude <= 35,
    Latitude >= 34 & Latitude <= 65,
  )

beyond_europe_ancient <- aadrJanno %>%
  dplyr::anti_join(modern, by = "Poseidon_ID") %>%
  dplyr::anti_join(europe_ancient, by = "Poseidon_ID")

# sanity checks
nrow(aadrJanno) == nrow(modern) + nrow(europe_ancient) + nrow(beyond_europe_ancient)
setequal(
  aadrJanno$Poseidon_ID,
  c(modern$Poseidon_ID, europe_ancient$Poseidon_ID, beyond_europe_ancient$Poseidon_ID)
)
nrow(modern)/nrow(aadrJanno)

# write files
writeLines(
  paste0("<", modern$Poseidon_ID, ">"),
  "AADR54.1.p1_to_Poseidon2.7.0/tmp/subsetModern.pfs"
)
writeLines(
  paste0("<", europe_ancient$Poseidon_ID, ">"),
  "AADR54.1.p1_to_Poseidon2.7.0/tmp/subsetEuropeAncient.pfs"
)
writeLines(
  paste0("<", beyond_europe_ancient$Poseidon_ID, ">"),
  "AADR54.1.p1_to_Poseidon2.7.0/tmp/subsetBeyondEuropeAncient.pfs"
)
