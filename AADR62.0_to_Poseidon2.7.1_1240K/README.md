# [V62.0](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/FFIDCW): Data release: Sep 16 2024 - 1240K version

Here are the steps we applied to transform the AADR 1240K dataset to a set of Poseidon packages:

1. Download the AADR dataset and convert the genotype data to a Poseidon-compatible format with `download_and_convert_genotypes.sh`.
2. Transform the .anno file to a .janno file with `anno2janno.R`. This includes renaming, manipulating and mapping the .anno columns to the specified [.janno columns](https://poseidon-framework.github.io/#/janno_details) according to the decisions documented in `column_mapping.csv`. Minor changes beyond that are listed below. The parsing of the `Full Date...` column requires more code outsourced to `age_string_parser.R`. The standardization of country names for `Country_ISO` relies on the `location_to_M49.tsv` lookup table provided by Hugo Zeberg.
3. Prepare a .bib file with all references for all publications contributing individuals to the AADR with `prepare_bib_file.R`.
4. Define meaningful subsets of the AADR dataset with `prepare_split.R` and write forgeScript files. Splitting is necessary, because GitHub LFS only support single files up to a size of 2GB.
5. Compile a simple AADR Poseidon package from the data prepared in 1. to 3. and split it according to the specified subsets (4.) in `prepare_dummy_packages.sh`.
6. Manually curate these resulting packages by adding the relevant meta information in the POSEIDON.yml files.

## Notes on additional minor changes

`column_mapping.csv` only documents systematic changes. Here are some notes on minor, additional changes from the original .anno to the resulting .janno file -- in no particular order. Some of these where kindly proposed by Martyna Molak.

- Line 15317: Three entries for `Damage rate in first nucleotide on sequences overlapping 1240k targets (merged data)`, where only a single numbers is expected: `0.0157, 0.0173, 0.0162`. We selected the middle value `0.0162` and deleted the others.
- Lines 15365, 15366, and 15366: Have the `mtDNA haplogroup if >2x or published` entries wrongly in the column `mtDNA coverage (merged data)`. We moved the three values to the correct column.
- Line 15615: Impossible entry in `Full Date...`: `76-2332 calCE`. We assume that there was a typo in the Stolarek et al. supplementary information file. The samples were radiocarbon dated, but the publication does not report dating lab numbers nor uncalibrated C14 dates. We decided to set the mean date and the standard deviation to `..`.
- Line 7264: Impossible entry in `Full Date...`: `2550-565 calCE (1646±68 BP)`. We assume there was a typo in AADR field `2550-565 calCE (1646±68 BP)` for this sample; the original publication "WangYuCurrentBiology2023" refrains from providing calibrated dates at all due to indication of a strong reservoir effect and "lack of estimates for the local reservoir effect in the region"; not sure how the AADR-Team came up with the estimates for this sample as well as for two other samples from the site (also dated): KMT001.SG, KMT002.SG, KMT003.SG.
- Lines 15416 and 15429: Incorrectly formatted `Full Date...` entries. We changed them to:
  - `4311-4052 calBCE (5329±23 BP) [R_combine: (5220±90 BP, Gd-2729), (5366±32 BP, OxA-30501), (5300±35 BP, Poz-76057)]`
  - `5623-5487 calBCE (6635±18 BP) [R_combine: (6610±30 BP, Beta-386397), (6670±30 BP, Beta-386398), (6630±30 BP, Beta-458001), (6630±30 BP, Beta-458002)]`
- Line 7778: The information for the uncalibrated radiocarbon date in the `Full Date...` column is incomplete: `988-1163 calCE (1065±, EZV-00225)`. We adjusted the entry to the shape of a contextual, non-C14 date: `988-1163 CE`.
- Lines 6881 and 6882: The `Full Date...` column used `cal BP` instead of the usual `BP`. We changed it.
- Line 4069: The lab identifier in the `Full Date...` entry included a misplaced character: `±ETH` -> `ETH`.
- Line 7098: Wrong separators between individual values in the list column `Libraries`. We replaced the entry with `MLZ003.A0201.TF1.1,MLZ003.A0202.TF2.1,MLZ003.A0203.TF2.1,MLZ005.A0101.TF1.1,MLZ005.A0102.TF2.1,MLZ005.A0103.TF2.1,MLZ005.A0201.TF1.1,MLZ005.A0202.TF2.1,MLZ005.A0203.TF2.1`.
- We renamed the radiocarbon lab `T±B_TAK` (encoding issue?) to `TUBITAK` in the radiocarbon date lab identifiers.

`anno2janno.R` and `age_string_parser.R` includes code with more minor changes, that we did not apply to the source data, but only in memory for subsequent parsing and creation of the desired Poseidon fields. Especially the `Full Date...` column includes many formatting inconsistencies.

- `Group_Names` and `Genetic_Sex` were taken from the .ind-file, not the .anno file. Like this we avoid the many mismatches.
- Future versions of Poseidon will not support non-ASCII characters in group/population names, so we replaced every instance of `ø` (in `Ertebølle`) with `o` in this field.
