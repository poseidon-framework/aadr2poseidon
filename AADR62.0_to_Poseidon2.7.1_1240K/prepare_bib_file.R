library(magrittr)

# write dois to file


#### resolve DOIs to BibTeX entries ####

# using doi2bib: https://github.com/bibcure/doi2bib
system(paste(
  "doi2bib",
  "-i AADR54.1.p1_to_Poseidon2.7.0_1240K/tmp/DOIs.txt",
  "-o AADR54.1.p1_to_Poseidon2.7.0_1240K/tmp/References_raw.bib"
))

#### clean resulting .bib file ####

# load result
references <- bibtex::read.bib("AADR54.1.p1_to_Poseidon2.7.0_1240K/tmp/References_raw.bib")

# 1. manual step: add field "journal" to entries 'Wang_2020', '_egarac_2020', 'Moots_2022', 'Antonio_2022'
# (all "journal = {bioRxiv}")

references <- bibtex::read.bib("AADR54.1.p1_to_Poseidon2.7.0_1240K/tmp/References_raw.bib")

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

in_references <- bibtex::read.bib("AADR54.1.p1_to_Poseidon2.7.0_1240K/tmp/References_raw.bib")

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

#### write final .bib file #### 

bibtex::write.bib(out_references, "AADR54.1.p1_to_Poseidon2.7.0_1240K/tmp/References.bib")

