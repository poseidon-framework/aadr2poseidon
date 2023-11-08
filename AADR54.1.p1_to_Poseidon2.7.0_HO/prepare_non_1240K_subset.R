library(magrittr)

#### read fam files of the 1240k AADR dataset ####

inds1240KModern <- readr::read_delim(
  "../aadr-archive/AADR_v54_1_p1_1240K_Modern/AADR_v54_1_p1_1240K_Modern.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

inds1240KEurope <- readr::read_delim(
  "../aadr-archive/AADR_v54_1_p1_1240K_EuropeAncient/AADR_v54_1_p1_1240K_EuropeAncient.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

inds1240KBeyond <- readr::read_delim(
  "../aadr-archive/AADR_v54_1_p1_1240K_BeyondAncient/AADR_v54_1_p1_1240K_BeyondAncient.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

inds1240K <- c(inds1240KModern, inds1240KEurope, inds1240KBeyond)

#### read HO fam file ####

indsHO <- readr::read_delim(
  "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/AADR_HO.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

#### define subset ####

indsOnlyInHO <- indsHO[!indsHO %in% inds1240K]

#### write forgeScript files ###

writeLines(
  paste0("<", indsOnlyInHO, ">"),
  "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/subsetOnlyHO.pfs"
)
