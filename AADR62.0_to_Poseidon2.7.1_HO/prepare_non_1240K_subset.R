library(magrittr)

#### read fam files of the 1240k AADR dataset ####

inds1240KModern <- readr::read_delim(
  "../aadr-archive/AADR_v62_1240K_Modern/AADR_v62_1240K_Modern.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

inds1240KEuropeNorth <- readr::read_delim(
  "../aadr-archive/AADR_v62_1240K_EuropeAncientNorth/AADR_v62_1240K_EuropeAncientNorth.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

inds1240KEuropeSouth <- readr::read_delim(
  "../aadr-archive/AADR_v62_1240K_EuropeAncientSouth/AADR_v62_1240K_EuropeAncientSouth.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

inds1240KBeyond <- readr::read_delim(
  "../aadr-archive/AADR_v62_1240K_BeyondAncient/AADR_v62_1240K_BeyondAncient.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

inds1240K <- c(inds1240KModern, inds1240KEuropeNorth, inds1240KEuropeSouth, inds1240KBeyond)

#### read HO fam file ####

indsHO <- readr::read_table(
  "AADR62.0_to_Poseidon2.7.1_HO/tmp/AADR_HO.ind",
  col_names = c("sample", "pop", "sex")
) %$% sample

#### define subset ####

indsOnlyInHO <- indsHO[!indsHO %in% inds1240K]

#### compare to last AADR release ####

inds1240KBeyond <- readr::read_delim(
  "../aadr-archive/AADR_v54_1_p1_HO_Modern_not_in_1240K/AADR_v54_1_p1_HO_Modern_not_in_1240K.fam",
  delim = "\t",
  col_names = FALSE
) %$% X2

setdiff(indsOnlyInHO, inds1240KBeyond)
setdiff(inds1240KBeyond, indsOnlyInHO)

#### write forgeScript files ###

writeLines(
  paste0("<", indsOnlyInHO, ">"),
  "AADR62.0_to_Poseidon2.7.1_HO/tmp/subsetOnlyHO.pfs"
)
