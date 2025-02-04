library(magrittr)

#### resolve DOIs to BibTeX entries ####

# using doi2bib: https://github.com/bibcure/doi2bib
# runs for a couple of minutes
system(paste(
  "doi2bib",
  "-i AADR62.0_to_Poseidon2.7.1_1240K/tmp/DOIs.txt",
  "-o AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib"
))

#### clean resulting .bib file ####

# validate result

system("biber --tool --validate-datamodel AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib")

# load result
references <- bibtex::read.bib("AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib")

# 1. manual step: add field "journal" to some entries
# (some "journal = {bioRxiv}")

references <- bibtex::read.bib("AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib")

# check which doi's are actually there
dois_actually_in_bibtex <- references %>% purrr::map_chr(\(x) x$doi)
requested_dois <- readLines("AADR62.0_to_Poseidon2.7.1_1240K/tmp/DOIs.txt")

setdiff(requested_dois, dois_actually_in_bibtex)

# 2. manual step: add missing bibtex entries for some papers
# 10.7554/eLife.79714 -> 
# 10.1038/s41467-019-09209- -> 
# 10.7554/eLife.85492 -> 
# 10.1186/s13059-023-03013-103 -> 

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

