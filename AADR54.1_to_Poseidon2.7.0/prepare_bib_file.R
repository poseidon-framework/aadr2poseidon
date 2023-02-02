library(magrittr)

# to start from scratch
# file.remove(
#   "AADR54.1_to_Poseidon2.7.0/tmp/DOIs.txt",
#   "AADR54.1_to_Poseidon2.7.0/tmp/citation_keys.txt",
#   "AADR54.1_to_Poseidon2.7.0/tmp/aadr2doi_result.txt",
#   "ADR54.1_to_Poseidon2.7.0/tmp/References_raw.bib"
# )

#### prepare a list of all required papers ####
# this assumes the .janno file was created with the anno2janno.R script

aadrJanno <- poseidonR::read_janno("AADR54.1_to_Poseidon2.7.0/tmp/AADR_1240K.janno", validate = F)
keys <- aadrJanno$Publication %>% unlist() %>% unique()
writeLines(keys, "AADR54.1_to_Poseidon2.7.0/tmp/citation_keys.txt")

#### compile list of DOIs ###

# using aadr2doi: https://github.com/nevrome/aadr2doi
system(paste(
  "aadr2doi",
  "--inFile AADR54.1_to_Poseidon2.7.0/tmp/citation_keys.txt",
  "--aadrVersion 54.1",
  "--doiShape Short",
  "--printKey",
  "-o AADR54.1_to_Poseidon2.7.0/tmp/aadr2doi_result.txt"
  ))

aadr2doi_result <- readr::read_tsv(
  "AADR54.1_to_Poseidon2.7.0/tmp/aadr2doi_result.txt",
  col_names = c("key", "doi")
)

# manual step: add missing DOIs to DOIs.txt
additional_dois <- tibble::tribble(
  ~key, ~doi,
  "LazaridisNature2016", "10.1038/nature19310",
  "LiScience2008", "10.1126/science.1153717",
  "JakobssonNature2008",  "10.1038/nature06742",
  "BraceDiekmannNatureEcologyEvolution2019", "10.1038/s41559-019-0871-9",
  "HaakLazaridis2015", "10.1038/nature14317",
  "Gamba2014", "10.1038/ncomms6257",
  "UllingerNearEasternArchaeology2022", "10.1086/720748",
  "AntonioGaoMootsScience2019", "10.1126/science.aay6826",
  "KanzawaKiriyamaJHG2016", "10.1038/jhg.2016.110",
  "JonesCurrentBiology2017", "10.1016/j.cub.2016.12.060",
  "ColonMolecularBiologyandEvolution2020", "10.1093/molbev/msz267",
  "RaghavanNature2013", "10.1038/nature12736",
  "OrlandoScience2014", "10.1126/science.aaa0114",
  "Olalde2014", "10.1038/nature12960",
  "GreenScience2010", "10.1126/science.1188021",
  "LindoFigueiroPNASNexus2022", "10.1093/pnasnexus/pgac047"
)

# combine automatically retrieved and manually added dois
combined_doi_table <- dplyr::bind_rows(aadr2doi_result, additional_dois)

# clean out .Paperpile suffix in dois
combined_doi_table$doi <- combined_doi_table$doi %>% gsub(".Paperpile", "", .)

# identify doi duplicates
doi_duplicates <- combined_doi_table %>%
  dplyr::group_by(doi) %>%
  dplyr::summarize(keys = list(key)) %>%
  dplyr::filter(purrr::map_lgl(keys, \(x) length(x) > 1))

# decide which ones to keep
#doi_duplicates$keys
# set this also in key_replacement in anno2janno.R!

key_replacement <- tibble::tribble(
  ~bad, ~good,
  "RaghavanNature2013", "RaghavanNature2014",
  "Olalde2014", "OlaldeNature2014",
  "Gamba2014",  "GambaNatureCommunications2014",
  "SiskaScienceAdvances2017", "SikoraScience2017"
)

# remove keys from doi list
final_doi_table <- combined_doi_table %>%
  dplyr::filter(!(key %in% key_replacement$bad))

# write dois to file
writeLines(final_doi_table$doi, "AADR54.1_to_Poseidon2.7.0/tmp/DOIs.txt")

#### resolve DOIs to BibTeX entries ####

# using doi2bib: https://github.com/bibcure/doi2bib
system(paste(
  "doi2bib",
  "-i AADR54.1_to_Poseidon2.7.0/tmp/DOIs.txt",
  "-o AADR54.1_to_Poseidon2.7.0/tmp/References_raw.bib"
))

#### clean resulting .bib file ####

# load result
references <- bibtex::read.bib("AADR54.1_to_Poseidon2.7.0/tmp/References_raw.bib")

# 1. manual step: add field "journal" to entries 'Wang_2020', '_egarac_2020', 'Moots_2022', 'Antonio_2022'
# (all "journal = {bioRxiv}")

references <- bibtex::read.bib("AADR54.1_to_Poseidon2.7.0/tmp/References_raw.bib")

# check which doi's are actually there
dois_actually_in_bibtex <- references %>% purrr::map_chr(\(x) x$doi)
setdiff(final_doi_table$doi, dois_actually_in_bibtex)

# 2. manual step: add missing bibtex entries for some papers
# 10.1126/science.abm4247 -> The genetic history of the Southern Arc...

# 3. manual step: clean incorrectly formatted values
# {PLoS ONE} {ONE} -> {PLoS ONE}
# {Nat Ecol Evol}amp$\mathsemicolon$ Evolution} -> {Nat Ecol Evol}
# {PLoS Biol} Biology} -> {PLoS Biol}
# {PLoS Genet} Genetics} -> {PLoS Genet}

#### adjust citation keys in bib file ####

in_references <- bibtex::read.bib("AADR54.1_to_Poseidon2.7.0/tmp/References_raw.bib")

dois_in_bibtex <- in_references %>% purrr::map_chr(\(x) x$doi)
keys_in_bibtex <- in_references %>% purrr::map_chr(\(x) attr(x, "key"))
in_bibtex <- tibble::tibble(doi2bib_key = keys_in_bibtex, doi = dois_in_bibtex)
merged_key_table <- dplyr::left_join(in_bibtex, final_doi_table, by = "doi")

out_references <- purrr::map2(
  in_references, merged_key_table$key,
  \(x, y) {
    attr(x, "key") <- y
    return(x)
  }
)
class(out_references) <- "bibentry"

bibtex::write.bib(out_references, "AADR54.1_to_Poseidon2.7.0/tmp/References.bib")

