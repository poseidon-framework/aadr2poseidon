# [V54.1.p1](https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/index_v54.1.p1.html): Data release: Mar 6 2023 (minor patch on v54.1)

Here are the steps we applied to transform the AADR dataset to a set of Poseidon packages:

1. Download the AADR dataset and convert the genotype data to a Poseidon-compatible format with `download_and_convert_genotypes.sh`.
2. Transform the .anno file to a .janno file with `anno2janno.R`. This includes renaming, manipulating and mapping the .anno columns to the specified [.janno columns](https://poseidon-framework.github.io/#/janno_details) according to the decisions documented in `column_mapping.csv`. Minor changes beyond that are listed below. The parsing of the `Full Date...` column requires more code outsourced to `age_string_parser.R`. The standardization of country names for `Country_ISO` relies on the `location_to_M49.tsv` lookup table provided by Hugo Zeberg.
3. Prepare a .bib file with all references for all publications contributing individuals to the AADR with `prepare_bib_file.R`. Cleaning the .bib file also involves some small manual steps not worth automating.
4. Define meaningful subsets of the AADR dataset with `prepare_split.R` and write forgeScript files. Splitting is necessary, because GitHub LFS only support single files up to a size of 2GB.
5. Compile a simple AADR Poseidon package from the data prepared in 1. to 3. and split it according to the specified subsets (4.) in `prepare_dummy_packages.sh`.
6. Manually curate these resulting packages by adding the relevant meta information in the POSEIDON.yml files.

## Notes on additional minor changes

`column_mapping.csv` only documents systematic changes. Here are some notes on minor, additional changes to the .anno file:

- The lines 3301 and 3302 of the .anno file feature malicious quotes in the `Full Date...` column. They had to be removed to read it correctly. To make sure this doesn't also happen in other columns unnoticed we replaced all double quotes with single quotes.
- The values `".."`, `""`, `"n/a"`, `"na"` were all treated as `NA`.
- The publication keys `RaghavanNature2013`, `Olalde2014`, `Gamba2014` and `SiskaScienceAdvances2017` are DOI duplicates of `RaghavanNature2014`, `OlaldeNature2014`, `GambaNatureCommunications2014` and `SikoraScience2017` and were replaced by these.
- The entry `"5350-5250 CE"` in the `Full Date...` column in row 12787 is impossible. We changed it to `"5350-5250 BCE"`.
- The country name `Gernamy` was treated as `Germany`.
- The entry `"Valencian Community, València/Valencia, Bocairent, La Coveta Emparetà"` of the `Locality` column in the rows 10824 and 10825 seems to include invalid unicode characters. We changed it to `"Valencian Community, Valencia/Valencia, Bocairent, La Coveta Empareta"`.
- The Genetic sex `c` was treated as `U`.
- Some entries to the `Libraries` column (rows: 1765, 4373, 4374, 4375, 4376, 4377, 4378, 4379, 4380, 4381, 4382, 4383, 4384, 4385, 4386, 4387, 4388, 4389, 4390, 4391, 4392, 4393, 4394, 4395, 4396, 4397, 4398, 4399, 4400, 4401, 4402, 4403, 4404, 4405, 4406, 4407, 4408, 4680, 9592, 9593, 10304) are not delimited by `,`, but by `;`. We changed the entries before parsing.
- The following paper keys are missing or not linked to entries with DOIs on the AADR website: `LazaridisNature2016`, `LiScience2008`, `JakobssonNature2008`, `BraceDiekmannNatureEcologyEvolution2019`, `HaakLazaridis2015`, `UllingerNearEasternArchaeology2022`, `AntonioGaoMootsScience2019`, `KanzawaKiriyamaJHG2016`, `JonesCurrentBiology2017`, `ColonMolecularBiologyandEvolution2020`, `OrlandoScience2014`, `GreenScience2010`, `LindoFigueiroPNASNexus2022`. We added the DOIs manually, as they are necessary for downloading the BibTeX entries automatically.

