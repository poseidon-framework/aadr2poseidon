library(magrittr)

sub <- function(j) {
  j %>%
    dplyr::select(Poseidon_ID, Publication) %>%
    dplyr::mutate(
      first_pub = stringr::str_split(Publication, pattern = ";") %>%
        purrr::map_chr(\(x) x[[1]])
    )
}

j621240k <- readr::read_tsv("~/agora/aadr-archive/AADR_v62_1240K_Modern/AADR_v62_1240K_Modern.janno", guess_max = 10000)
j621240k %>% sub %$% first_pub %>% table()

j62HO <- readr::read_tsv("~/agora/aadr-archive/AADR_v62_HO_Modern_not_in_1240K/AADR_v62_HO_Modern_not_in_1240K.janno", guess_max = 10000)
j62HO %>% sub %$% first_pub %>% table()

j662M <- readr::read_tsv("~/agora/aadr-archive/AADR_v66_2M/AADR_v66_2M.janno", guess_max = 10000, na = c("", "NA", ".."))
j662MJacobs <- j662M %>% sub() %>% dplyr::filter(first_pub == "JacobsCoxCell2019")
nrow(j662MJacobs)

j66HO <- readr::read_tsv("~/agora/aadr-archive/AADR_v66_HO/AADR_v66_HO.janno", guess_max = 10000, na = c("", "NA", ".."))
j66HOJacobs <- j66HO %>% sub() %>% dplyr::filter(first_pub == "JacobsCoxCell2019")
nrow(j66HOJacobs)

all(j662MJacobs$Poseidon_ID == j66HOJacobs$Poseidon_ID)

j662MJacobs$Poseidon_ID %>%
  paste0("-<", ., ">") %>%
  cat(sep = "\n", file = "AADR66.p1_adjustments/remove_jacobs_forgefile.txt")
