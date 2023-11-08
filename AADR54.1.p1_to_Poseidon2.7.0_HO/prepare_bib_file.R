library(magrittr)

# to start from scratch
# file.remove(
#   "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/DOIs.txt",
#   "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/citation_keys.txt",
#   "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/aadr2doi_result.txt",
#   "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/References_raw.bib"
# )

#### prepare a list of all required papers ####
# this assumes the .janno file was created with the anno2janno.R script

aadrJanno <- poseidonR::read_janno("AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/AADR_HO_without_1240K.janno", validate = F)
keys <- aadrJanno$Publication %>% unlist() %>% unique()
writeLines(keys, "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/citation_keys.txt")

#### compile list of DOIs ###

# using aadr2doi: https://github.com/nevrome/aadr2doi
system(paste(
  "aadr2doi",
  "--inFile AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/citation_keys.txt",
  "--aadrVersion 54.1.p1",
  "--doiShape Short",
  "--printKey",
  "-o AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/aadr2doi_result.txt"
  ))

aadr2doi_result <- readr::read_tsv(
  "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/aadr2doi_result.txt",
  col_names = c("key", "doi")
)

# manual step: add missing DOIs to DOIs.txt
additional_dois <- tibble::tribble(
  ~key, ~doi,
  "LazaridisNature2016", "10.1038/nature19310",
  "VyasAJPA2017", "10.1002/ajpa.23312",
  "VyasDryadDigitalRepository2017", "10.5061/dryad.1pm3r"
)

# combine automatically retrieved and manually added dois
combined_doi_table <- dplyr::bind_rows(aadr2doi_result, additional_dois)

# identify doi duplicates
doi_duplicates <- combined_doi_table %>%
  dplyr::group_by(doi) %>%
  dplyr::summarize(keys = list(key)) %>%
  dplyr::filter(purrr::map_lgl(keys, \(x) length(x) > 1))

final_doi_table <- combined_doi_table

# write dois to file
writeLines(final_doi_table$doi, "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/DOIs.txt")

#### resolve DOIs to BibTeX entries ####

# using doi2bib: https://github.com/bibcure/doi2bib
system(paste(
  "doi2bib",
  "-i AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/DOIs.txt",
  "-o AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/References_raw.bib"
))

#### clean resulting .bib file ####

# load result
references <- bibtex::read.bib("AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/References_raw.bib")

# check which doi's are actually there
dois_actually_in_bibtex <- references %>% purrr::map_chr(\(x) x$doi)
setdiff(final_doi_table$doi, dois_actually_in_bibtex)

# 2. manual step: add missing bibtex entries for some papers
# 10.5061/dryad.1pm3r -> VyasDryadDigitalRepository2017

# 3. manual step: clean incorrectly formatted values
# {PLoS ONE} {ONE} -> {PLoS ONE}
# {Nat Ecol Evol}amp$\mathsemicolon$ Evolution} -> {Nat Ecol Evol}
# {PLoS Genet} Genetics} -> {PLoS Genet}

#### adjust citation keys in bib file ####

in_references <- bibtex::read.bib("AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/References_raw.bib")

dois_in_bibtex <- in_references %>% purrr::map_chr(\(x) x$doi)
keys_in_bibtex <- in_references %>% purrr::map_chr(\(x) attr(x, "key"))
in_bibtex <- tibble::tibble(doi2bib_key = keys_in_bibtex, doi = dois_in_bibtex)
merged_key_table <- dplyr::left_join(
  in_bibtex %>% dplyr::mutate(doi = tolower(doi)),
  final_doi_table %>% dplyr::mutate(doi = tolower(doi)),
  by = "doi"
)

out_references <- purrr::map2(
  in_references, merged_key_table$key,
  \(x, y) {
    attr(x, "key") <- y
    return(x)
  }
)
class(out_references) <- "bibentry"

#### write final .bib file #### 

bibtex::write.bib(out_references, "AADR54.1.p1_to_Poseidon2.7.0_HO/tmp/References.bib")

