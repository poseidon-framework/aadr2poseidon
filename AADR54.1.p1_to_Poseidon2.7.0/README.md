# [V54.1.p1](https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/index_v54.1.p1.html): Data release: Mar 6 2023 (minor patch on v54.1)

Here are the steps we applied to transform the AADR dataset to a Poseidon package:

1. Download the AADR dataset and convert the genotype data to a Poseidon-compatible format with `download_and_convert_genotypes.sh`.
2. Transform the .anno file to a .janno file with `anno2janno.R`. This includes renaming, manipulating and mapping the .anno columns to the specified [.janno columns](https://poseidon-framework.github.io/#/janno_details) according to the table in `column_mapping.csv`. Look here to understand how the .anno file translates to the .janno file. The parsing of the `Full Date...` column requires more code outsourced to `age_string_parser.R`.
3. Prepare a .bib file with all references for all publications with `prepare_bib_file.R`.
4. Define meaningful subsets of the AADR dataset with `prepare_split.R` and write forgeScript files. This is necessary, because GitHub LFS only support single files up to a size of 2GB.
5. Compile a simple AADR Poseidon package and split it according to the specified subsets in `prepare_dummy_packages.sh`.
6. Manually curate these packages by adding the relevant meta information in the POSEIDON.yml files.

