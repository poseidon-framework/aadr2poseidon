#### prepare a list of all required papers ####

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
  "-o AADR54.1_to_Poseidon2.7.0/tmp/DOIs.txt"
  ))

# manual step: add missing DOIs to DOIs.txt
additional_dois <- c(
  "LazaridisNature2016" = "10.1038/nature19310",
  "LiScience2008" = "10.1126/science.1153717",
  "JakobssonNature2008" =  "10.1038/nature06742",
  "BraceDiekmannNatureEcologyEvolution2019" = "10.1038/s41559-019-0871-9",
  "HaakLazaridis2015" = "10.1038/nature14317",
  "Gamba2014" = "10.1038/ncomms6257",
  "UllingerNearEasternArchaeology2022" = "10.1086/720748",
  "AntonioGaoMootsScience2019" = "10.1126/science.aay6826",
  "KanzawaKiriyamaJHG2016" = "10.1038/jhg.2016.110",
  "JonesCurrentBiology2017" = "10.1016/j.cub.2016.12.060",
  "ColonMolecularBiologyandEvolution2020" = "10.1093/molbev/msz267",
  "RaghavanNature2013" = "10.1038/nature12736",
  "OrlandoScience2014" = "10.1126/science.aaa0114",
  "Olalde2014" = "10.1038/nature12960",
  "GreenScience2010" = "10.1126/science.1188021",
  "LindoFigueiroPNASNexus2022" = "10.1093/pnasnexus/pgac047"
)
write(additional_dois, file = "AADR54.1_to_Poseidon2.7.0/tmp/DOIs.txt", append = TRUE)
#check nr of lines in result file: system("wc -l AADR54.1_to_Poseidon2.7.0/tmp/DOIs.txt")

#### resolve DOIs to BibTeX entries ####

# using doi2bib: https://github.com/bibcure/doi2bib
system(paste(
  "doi2bib",
  "-i AADR54.1_to_Poseidon2.7.0/tmp/DOIs.txt",
  "-o AADR54.1_to_Poseidon2.7.0/tmp/References.bib"
))

#### adjust citation keys ####

references <- bibtex::read.bib("AADR54.1_to_Poseidon2.7.0/tmp/References.bib")


# manual step: clean .bib file with https://flamingtempura.github.io/bibtex-tidy/
