# [V62.0](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/FFIDCW): Data release: Sep 16 2024 - 1240K version

Here are the steps we applied to transform the AADR 1240K dataset to a set of Poseidon packages:

1. Download the AADR dataset and convert the genotype data to a Poseidon-compatible format with `download_and_convert_genotypes.sh`.
2. Transform the .anno file to a .janno file with `anno2janno.R`. This includes renaming, manipulating and mapping the .anno columns to the specified [.janno columns](https://poseidon-framework.github.io/#/janno_details) according to the decisions documented in `column_mapping.csv`. Minor changes beyond that are listed below. The parsing of the `Full Date...` column requires more code outsourced to `age_string_parser.R`. The standardization of country names for `Country_ISO` relies on the `location_to_M49.tsv` lookup table provided by Hugo Zeberg.
3. Prepare a .bib file with all references for all publications contributing individuals to the AADR with `prepare_bib_file.R`. Cleaning the .bib file also involves some small manual steps not worth automating, including adding the relevant AADR references to each sample.
4. Define meaningful subsets of the AADR dataset with `prepare_split.R` and write forgeScript files. Splitting is necessary, because GitHub LFS only support single files up to a size of 2GB.
5. Compile a simple AADR Poseidon package from the data prepared in 1. to 3. and split it according to the specified subsets (4.) in `prepare_dummy_packages.sh`.
6. Manually curate these resulting packages by adding the relevant meta information in the POSEIDON.yml files.

## Notes on additional minor changes

`column_mapping.csv` only documents systematic changes. Here are some notes on minor, additional changes to the .anno file. Some of these where proposed by Martyna Molak. We enacted the changes before or during reading.

- Line 15317: Three entries for `Damage rate in first nucleotide on sequences overlapping 1240k targets (merged data)`, where only a single numbers is expected: `0.0157, 0.0173, 0.0162`. We selected the middle value `0.0162` and deleted the others.
- Lines 15365, 15366, and 15366: Have the `mtDNA haplogroup if >2x or published` entries wrongly in the column `mtDNA coverage (merged data)`. We moved the three values to the correct column.
- Line 15615: Impossible entry in `Full Date...`: `76-2332 calCE`. We assume that there was a typo in the Stolarek et al. supplementary information file. The samples were radiocarbon dated, but the publication does not report dating lab numbers nor uncalibrated C14 dates. We then set the mean date and the standard deviation to `..`.
- Line 7264: Impossible entry in `Full Date...`: `2550-565 calCE (1646±68 BP)`. We assume there was a typo in AADR field `2550-565 calCE (1646±68 BP)` for this sample; the original publication "WangYuCurrentBiology2023" refrains from providing calibrated dates at all due to indication of a strong reservoir effect and "lack of estimates for the local reservoir effect in the region"; not sure how AADR came up with these estimates for this sample as well as for two other samples from the site (also dated): KMT001.SG, KMT002.SG, KMT003.SG.
- Lines 15416 and 15429: Incorrectly formatted `Full Date...` entries. We changed them to:
  - `4311-4052 calBCE (5329±23 BP) [R_combine: (5220±90 BP, Gd-2729), (5366±32 BP, OxA-30501), (5300±35 BP, Poz-76057)]`
  - `5623-5487 calBCE (6635±18 BP) [R_combine: (6610±30 BP, Beta-386397), (6670±30 BP, Beta-386398), (6630±30 BP, Beta-458001), (6630±30 BP, Beta-458002)]`
- We renamed the radiocarbon lab `T±B_TAK` to `TUBITAK` in the radiocarbon date lab identifiers.


- The line 7098 has wrong separators between individual values in the list column `Libraries`. We replaced the entry with `MLZ003.A0201.TF1.1,MLZ003.A0202.TF2.1,MLZ003.A0203.TF2.1,MLZ005.A0101.TF1.1,MLZ005.A0102.TF2.1,MLZ005.A0103.TF2.1,MLZ005.A0201.TF1.1,MLZ005.A0202.TF2.1,MLZ005.A0203.TF2.1`.


- #anno$Locality[c(2055, 2058, 2059, 2060, 8127, 8128, 8129, 8130, 8132, 8135, 8137, 9621, 10239, 10240, 10241, 10242)] <- "El Soco (southeast coast DR, San Pedro de Macorís, Ramón Santana, Playa Nueva Romana)"



- We preemptively replaced all double quotes (if there are any) with single quotes to avoid reading issues.
- The values `".."`, `""`, `"n/a"`, `"na"` were all treated as `NA`.


- The publication keys `RaghavanNature2013`, `Olalde2014`, `Gamba2014` and `SiskaScienceAdvances2017` are DOI duplicates of `RaghavanNature2014`, `OlaldeNature2014`, `GambaNatureCommunications2014` and `SikoraScience2017` and were replaced by these.
- The country name `Gernamy` was treated as `Germany`.
- The entry `"Valencian Community, València/Valencia, Bocairent, La Coveta Emparetà"` of the `Locality` column in the rows 10824 and 10825 seems to include invalid unicode characters. We changed it to `"Valencian Community, Valencia/Valencia, Bocairent, La Coveta Empareta"`.
- The Genetic sex `c` was treated as `U`.
- Some entries to the `Libraries` column (rows: 1765, 4373, 4374, 4375, 4376, 4377, 4378, 4379, 4380, 4381, 4382, 4383, 4384, 4385, 4386, 4387, 4388, 4389, 4390, 4391, 4392, 4393, 4394, 4395, 4396, 4397, 4398, 4399, 4400, 4401, 4402, 4403, 4404, 4405, 4406, 4407, 4408, 4680, 9592, 9593, 10304) are not delimited by `,`, but by `;`. We changed the entries before parsing.
- The following paper keys are missing or not linked to entries with DOIs on the AADR website: `LazaridisNature2016`, `LiScience2008`, `JakobssonNature2008`, `BraceDiekmannNatureEcologyEvolution2019`, `HaakLazaridis2015`, `UllingerNearEasternArchaeology2022`, `AntonioGaoMootsScience2019`, `KanzawaKiriyamaJHG2016`, `JonesCurrentBiology2017`, `ColonMolecularBiologyandEvolution2020`, `OrlandoScience2014`, `GreenScience2010`, `LindoFigueiroPNASNexus2022`. We added the DOIs manually, as they are necessary for downloading the BibTeX entries automatically.

