# [V54.1.p1](https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/index_v54.1.p1.html): Data release: Mar 6 2023 (minor patch on v54.1) - HO version

Here are the steps we applied to transform the AADR HO dataset to a set of Poseidon packages:

1. Download the AADR dataset and convert the genotype data to a Poseidon-compatible format with `download_and_convert_genotypes.sh`. Before the call to `trident genoconvert` some minor changes to the `.ind` file are required: The Genetic sex `c` for the sample `C3355` has to be changed to `U` and the `,` character in a number of sample names has to be replaced with `_`.
2. Extract samples not already in the 1240K dataset using the `prepare_non_1240K_subset.R` and the `remove_1240K_samples.sh` scripts.
3. Load .anno file, extract the same samples not already in the 1240K dataset and then transform the it to a .janno file with `anno2janno.R`. This includes renaming, manipulating and mapping the .anno columns to the specified [.janno columns](https://poseidon-framework.github.io/#/janno_details) according to the decisions documented in `column_mapping.csv`. Minor changes beyond that are listed below. The standardization of country names for `Country_ISO` relies on the `location_to_M49.tsv` lookup table originally provided by Hugo Zeberg.
4. Prepare a .bib file with all references for all publications contributing individuals to the AADR with `prepare_bib_file.R`. Cleaning the .bib file also involves some minor manual steps.
5. Compile a simple AADR Poseidon package from the data prepared in 1. to 4. by copying the relevant files to an output directory, running `trident init` and adjusting the POSEIDON.yml file.

## Notes on additional minor changes

`column_mapping.csv` only documents systematic changes. Here are some notes on minor, additional changes to the .anno file:

- The values `".."`, `""`, `"n/a"`, `"na"` were all treated as `NA`.
- The following paper keys are missing or not linked to entries with DOIs on the AADR website: `LazaridisNature2016`, `VyasDryadDigitalRepository2017`. We added the DOIs manually, as they are necessary for downloading the BibTeX entries automatically.
