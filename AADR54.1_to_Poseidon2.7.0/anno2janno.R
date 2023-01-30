library(magrittr)

anno <- readr::read_tsv(
  "https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1/SHARE/public.dir/v54.1_1240K_public.anno",
  col_names = T ,
  show_col_types = F ,
  skip_empty_rows = F ,
  na = c("..", "", "n/a", "na")
) %>%
  # remove empty last column
  dplyr::select(-"...36")

# make list of column names for columns_mapping.csv
# purrr::walk(colnames(anno), \(x) cat(x, "\n"))

# adopt simplified column names for convenience
mapping_reference <- readr::read_csv("AADR54.1_to_Poseidon2.7.0/column_mapping.csv")
colnames(anno) <- mapping_reference$`Simplified .anno column name`

# construct janno columns

Poseidon_ID <- anno$Genetic_ID %>%
  gsub("<", "LT", .) %>%
  gsub(">", "GT", .)

Alternative_IDs <- anno$Master_ID

Collection_ID <- anno$Skeletal_Code

Source_Tissue <- anno$Skeletal_Element

AADR_Year_First_Publication <- anno$Year_First_Publication

Publication <- stringr::str_extract_all(anno$Publication, pattern = "[a-zA-Z]*[0-9]{4}|1KGPhase3")
AADR_Publication <- anno$Publication



