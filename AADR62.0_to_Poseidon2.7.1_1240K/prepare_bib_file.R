library(magrittr)

#### prepare DOI list ####

complete_keys_and_dois <- readRDS("AADR62.0_to_Poseidon2.7.1_1240K/tmp/complete_keys_and_dois.rds")

unqiue_dois <- complete_keys_and_dois$doi %>% unique()

writeLines(unqiue_dois, "AADR62.0_to_Poseidon2.7.1_1240K/tmp/DOIs.txt")

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
# system("biber --tool --validate-datamodel AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib")

# load result
references <- bibtex::read.bib("AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib")

# 1. manual step: add field "journal" to some entries
# (some "journal = {bioRxiv}")

references <- bibtex::read.bib("AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib")

# check which doi's are actually there
dois_actually_in_bibtex <- references %>% purrr::map_chr(\(x) x$doi)
requested_dois <- readLines("AADR62.0_to_Poseidon2.7.1_1240K/tmp/DOIs.txt")

setdiff(tolower(requested_dois), tolower(dois_actually_in_bibtex))

# 2. manual step: add missing bibtex entries for one paper
# https://reich.hms.harvard.edu/sites/reich.hms.harvard.edu/files/inline-files/10_24_2016_Screening_report_for_St_Marys_City_burials_FINAL_IL.pdf

#### adjust citation keys in bib file ####

in_references <- bibtex::read.bib("AADR62.0_to_Poseidon2.7.1_1240K/tmp/References_raw.bib")

dois_in_bibtex <- in_references %>% purrr::map_chr(\(x) {
  if (is.null(x$doi)) { NA_character_ } else {x$doi}
})
keys_in_bibtex <- in_references %>% purrr::map_chr(\(x) attr(x, "key"))
in_bibtex <- tibble::tibble(
  bib_entry_index = 1:length(in_references),
  doi2bib_key = keys_in_bibtex,
  doi = dois_in_bibtex
)
in_bibtex$doi <- tolower(in_bibtex$doi)
complete_keys_and_dois$doi <- tolower(complete_keys_and_dois$doi)

# note that this join introduces a number of doi duplicates!
# the AADR includes the same publication under different publication keys
merged_key_table <- dplyr::left_join(
  in_bibtex,
  complete_keys_and_dois,
  by = "doi"
)

out_references <- purrr::pmap(
  merged_key_table, function(bib_entry_index, doi2bib_key, doi, key) {
    cur_reference <- in_references[[bib_entry_index]]
    # see here for an explanation of the weird syntax below:
    # https://stackoverflow.com/questions/9765493/how-do-i-reference-specific-tags-in-the-bibentry-class-using-the-or-conv
    cur_reference$key <- key
    return(cur_reference)
  }
)

#### write final .bib file #### 

file.remove("AADR62.0_to_Poseidon2.7.1_1240K/tmp/References.bib")
purrr::walk(
  out_references, function(bibentry) {
    text <- format(bibentry, style = "bibtex")
    write(
      text,
      file = "AADR62.0_to_Poseidon2.7.1_1240K/tmp/References.bib",
      append = TRUE
    )
  }
)

