# [V66.0](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/FFIDCW): Data release: Apr 13 2026

Here are the steps we applied to transform the different datasets to a set of Poseidon packages:

1. Download the AADR datasets and convert the genotype data to a Poseidon-compatible format with `download_and_convert_genotypes.sh`.
2. Load and save the `.anno` files with Libre Office to fix the quoting. Delete the duplicate `.anno` column `Sum total of ROH segments >20cM` from each of them.
3. Transform the `.anno` files to `.janno` files with `anno2janno.hs`. This includes mapping and transforming some `.anno` columns to specific [`.janno` columns](https://poseidon-framework.github.io/#/janno_details) and renaming all `.anno` columns according to `aadr_columns_renamed.csv`.
4. Prepare a `.bib` file with all references for all publications contributing individuals to the AADR with `prepare_bib_file.R`.
5. Manually compile the generated information in dataset-wise packages and add `POSEIDON.yml` files.
