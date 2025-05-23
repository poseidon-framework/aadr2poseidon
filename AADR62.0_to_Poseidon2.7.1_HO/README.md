# [V62.0](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/FFIDCW): Data release: Sep 16 2024 - HO version

Here are the steps we applied to transform the AADR HO dataset to a set of Poseidon packages:

1. Download the AADR dataset and convert the genotype data to a Poseidon-compatible format with `download_and_convert_genotypes.sh`. Some minor manual changes to the `.ind` file are required: The `,` character multiple sample names has to be replaced with `_`.
2. Extract samples not already in the 1240K dataset using the `prepare_non_1240K_subset.R` and the `remove_1240K_samples.sh` scripts.
3. Load .anno file, extract the same samples not already in the 1240K dataset and then transform the it to a .janno file with `anno2janno.R`. This includes renaming, manipulating and mapping the .anno columns to the specified [.janno columns](https://poseidon-framework.github.io/#/janno_details) according to the decisions documented in `column_mapping.csv`. Minor changes beyond that are listed below. The standardization of country names for `Country_ISO` relies on the `location_to_M49.tsv` lookup table originally provided by Hugo Zeberg. Note that for the modern data in the HO dataset many columns are completely empty and were omitted here.
4. Prepare a .bib file with all references for all publications contributing individuals to the AADR with `prepare_bib_file.R`. Cleaning the .bib file also involves some minor manual steps.
5. Compile a simple AADR Poseidon package from the data prepared in 1. to 4. by copying the relevant files to an output directory, starting with `trident init -p tmp/AADR_HO_without_1240K.bed -o tmp/AADR_v62_HO_Modern_not_in_1240K`.
