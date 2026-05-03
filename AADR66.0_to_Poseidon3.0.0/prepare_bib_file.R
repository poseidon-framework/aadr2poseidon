library(magrittr)

#### prepare DOI list ####

janno_1240K <- janno::read_janno("tmp/AADR_v66_1240K/AADR_v66_1240K.janno", validate = F)
janno_2M <- janno::read_janno("tmp/AADR_v66_2M/AADR_v66_2M.janno", validate = F)
janno_2M_compatibility <- janno::read_janno("tmp/AADR_v66_2M_compatibility/AADR_v66_2M_compatibility.janno", validate = F)
janno_HO <- janno::read_janno("tmp/AADR_v66_HO/AADR_v66_HO.janno", validate = F)
janno_HO_compatibility <- janno::read_janno("tmp/AADR_v66_HO_compatibility/AADR_v66_HO_compatibility.janno", validate = F)

j <- dplyr::bind_rows(
  janno_1240K, janno_2M, janno_2M_compatibility, janno_HO, janno_HO_compatibility
)

j_pub <- j %>%
  dplyr::transmute(
    pubkey = purrr::map_chr(Publication, \(x) { head(x, n = 1) }),
    doi_url = AADR_Publication_DOI,
    doi = gsub("https://doi.org/", "", AADR_Publication_DOI)
  ) %>%
  dplyr::distinct() %>%
  # when there is no key in the AADR (e.g. "unpublished"),
  # then only the AADR entries are here
  dplyr::filter(!stringr::str_starts(pubkey, "AADR"))

j_pub_solvable <- j_pub %>% dplyr::filter(grepl("https", doi_url))

unique_dois <- j_pub_solvable$doi %>% unique()

writeLines(unique_dois, "tmp/bibtex_DOIs.txt")

#### resolve DOIs to BibTeX entries ####

# using doi2bib: https://github.com/bibcure/doi2bib
# runs for a couple of minutes
system(paste0(
  "doi2bib",
  " -i tmp/bibtex_DOIs.txt",
  " -o tmp/bibtex_raw_entries.bib"
))

#### clean resulting .bib file ####

# validate result
# system(paste0("biber --tool --validate-datamodel tmp/", package, "_bibtex_raw.bib"))

# load result
in_references <- bibtex::read.bib(paste0("tmp/bibtex_raw_entries.bib"))

# manual step: add field "journal" to some entries in "mod" version
file.copy("tmp/bibtex_raw_entries.bib", "tmp/bibtex_mod_entries.bib")
# most common issue: missing "journal = {bioRxiv}"

in_references <- bibtex::read.bib(paste0("tmp/bibtex_mod_entries.bib"))

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

file.remove(paste0("tmp/bibtex.bib"))
purrr::walk(
  out_references, function(bibentry) {
    text <- format(bibentry, style = "bibtex")
    write(
      text,
      file = paste0("tmp/bibtex.bib"),
      append = TRUE
    )
  }
)

# manual step: add missing references to "mod" version
# can be checked with trident validate in the result packages
file.copy("tmp/bibtex.bib", "tmp/bibtex_mod.bib")
# AADRv660: https://doi.org/10.7910/DVN/FFIDCW
# AADR: http://dx.doi.org/10.1038/s41597-024-03031-7
# AkbariReichNature2026: https://doi.org/10.1038/s41586-026-10358-1
# FernandesMegalithicUnpublished: ?
# AntonioPritchardeLife2024: https://doi.org/10.7554/eLife.79714
# Unpublished: ?
# AgelarakisAgelarakisJournalModernHellenism2026: https://reich.hms.harvard.edu/sites/reich.hms.harvard.edu/files/inline-files/014_%2BSt%2BIsidore%2BArticle%2B-Agelarakis_2026_0.pdf
# MaierReicheLife2023: https://doi.org/10.7554/eLife.85492
