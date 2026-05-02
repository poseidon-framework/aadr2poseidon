library(magrittr)

#### prepare DOI list ####

package <- "AADR_v66_1240K"

j <- janno::read_janno("tmp/output.janno", validate = F)

j_pub <- j %>%
  dplyr::transmute(
    pubkey = purrr::map_chr(Publication, \(x) { tail(x, n = 1) }),
    doi_url = AADR_Publication_DOI,
    doi = gsub("https://doi.org/", "", AADR_Publication_DOI)
  ) %>%
  dplyr::distinct()

j_pub_solvable <- j_pub %>% dplyr::filter(grepl("https", doi_url))

unique_dois <- j_pub_solvable$doi %>% unique()

writeLines(unique_dois, paste0("tmp/", package, "_DOIs.txt"))

#### resolve DOIs to BibTeX entries ####

# using doi2bib: https://github.com/bibcure/doi2bib
# runs for a couple of minutes
system(paste0(
  "doi2bib",
  " -i tmp/", package, "_DOIs.txt",
  " -o tmp/", package, "_bibtex_raw.bib"
))

#### clean resulting .bib file ####

# validate result
# system(paste0("biber --tool --validate-datamodel tmp/", package, "_bibtex_raw.bib"))

# load result
in_references <- bibtex::read.bib(paste0("tmp/", package, "_bibtex_raw.bib"))

# 1. manual step: add field "journal" to some entries
# (some "journal = {bioRxiv}")

in_references <- bibtex::read.bib(paste0("tmp/", package, "_bibtex_raw.bib"))

# check which doi's are actually there
dois_in_bibtex <- in_references %>% purrr::map_chr(\(x) {
  if (is.null(x$doi)) { NA_character_ } else {x$doi}
})
setdiff(tolower(unique_dois), tolower(dois_in_bibtex))

#### adjust citation keys in bib file ####

dois_in_bibtex <- in_references %>% purrr::map_chr(\(x) {
  if (is.null(x$doi)) { NA_character_ } else {x$doi}
})
keys_in_bibtex <- in_references %>% purrr::map_chr(\(x) attr(x, "key"))
in_bibtex <- tibble::tibble(
  bib_entry_index = 1:length(in_references),
  doi2bib_key = keys_in_bibtex,
  doi = tolower(dois_in_bibtex)
)

# note that this join potentially introduces doi duplicates!
# the AADR includes the same publication under different publication keys
merged_key_table <- dplyr::left_join(
  in_bibtex,
  j_pub_solvable,
  by = "doi"
)

out_references <- purrr::pmap(
  merged_key_table, function(bib_entry_index, pubkey, ...) {
    cur_reference <- in_references[[bib_entry_index]]
    # see here for an explanation of the weird syntax below:
    # https://stackoverflow.com/questions/9765493/how-do-i-reference-specific-tags-in-the-bibentry-class-using-the-or-conv
    cur_reference$key <- pubkey
    return(cur_reference)
  }
)

#### write final .bib file #### 

file.remove(paste0("tmp/", package, "_bibtex.bib"))
purrr::walk(
  out_references, function(bibentry) {
    text <- format(bibentry, style = "bibtex")
    write(
      text,
      file = paste0("tmp/", package, "_bibtex.bib"),
      append = TRUE
    )
  }
)

# manual step: add AADR references to References.bib
# AADRv660: https://doi.org/10.7910/DVN/FFIDCW
# AADR: http://dx.doi.org/10.1038/s41597-024-03031-7
