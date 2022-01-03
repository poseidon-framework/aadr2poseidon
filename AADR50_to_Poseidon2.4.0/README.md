## AADR v50 to Poseidon v2.4.0

Here we collect code to translate the AADR (specifically the 1240k dataset) to Poseidon format. The general workflow (on a Unix system) to run this is as follows:

1. Download and untar the archive from the AADR website [here](https://reich.hms.harvard.edu/allen-ancient-dna-resource-aadr-downloadable-genotypes-present-day-and-ancient-dna-data).

```bash
wget https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V50/V50.0/SHARE/public.dir/v50.0_1240K_public.tar -O data/poseidon_data/aadrv50/tar_archive.tar
tar -xvf data/poseidon_data/aadrv50/tar_archive.tar -C data/poseidon_data/aadrv50
```

2. Convert the genotype data to a format that is supported by Poseidon. This can be achieved with e.g. with [convertf](https://github.com/DReichLab/EIG/tree/master/CONVERTF) and a config file like this (where you have to replace `path/to/` with the paths relevant for you):

```
genotypename: path/to/v50.0_1240k_public.geno
snpname: path/to/v50.0_1240k_public.snp
indivname: path/to/v50.0_1240k_public.ind
outputformat: EIGENSTRAT
genotypeoutname: path/to/aadr_eig.geno
snpoutname: path/to/aadr_eig.snp
indivoutname: path/to/aadr_eig.ind
```

```bash
convertf -p data/poseidon_data/aadrv50/convertf_parfile
```
3. Use [trident](https://poseidon-framework.github.io/#/trident) to embed the genotype data in the scaffold of a [Poseidon package](https://poseidon-framework.github.io/#/standard).

```bash
trident init \
  --inFormat EIGENSTRAT \
  --genoFile aadr_eig.geno \
  --snpFile aadr_eig.snp \
  --indFile aadr_eig.ind \
  --snpSet 1240K \
  -o new_package \
  --minimal
```

The `--minimal` flag will keep the output package as simple as possible and only add a minimal `POSEIDON.yml` file.

4. Run the script `data migration.R` to obtain a `.janno` file from the `.anno` file (more about this process below in **How does `data migration.R` work**) and add it to the package by adding the following line to the `POSEIDON.yml` file.

```
jannoFile: relative/path/to/yournewfile.janno
```

You can validate this addition to the minimal package with `trident validate`.

If you want to extract a certain subset of individuals from this package, you can follow these steps (this works already without step 4., if you for example want to create the `.janno` file only for one publication):

A. Create a [forge file](https://poseidon-framework.github.io/#/trident?id=forge-command) with all the individuals you want to extract

```
<individual1>
<individual2>
<individual3>
...
```

You can do that for example in R with:

```r
writeLines(paste0("<",individuals_vector,">"), con = "forge_list.txt") 
```

B. Run `trident forge` with this forge file. `-o` is the desired output directory where the new package should be created.

```bash
trident forge -d . \
  --forgeFile forge_list.txt \
  -o path/to/yournewpackage
```

The result will be a Poseidon package with only the individuals in the forge file. If you want the resulting package to be sufficiently complete to be considered for submission in the [public Poseidon repo](https://github.com/poseidon-framework/published_data) you should also do the following things:

- Add bibliographic information in a `.bib` file (which also has to be referenced in the `POSEIDON.yml` file)
- Run `trident update` to add checksums to the `POSEIDON.yml` file
- Run `trident validate` to check wether everything is in the correct format

### How does `data migration.R` work

This script translates .anno to .janno files in an opinionated way. Here we document the decisions we made for individual parameters. If you apply changes to this script, remember to validat the output `.janno` file with trident or `poseidonR::validate_janno`.

* Basic column extraction function: This is the primary function that is used to extract data from relavent AADR v50 columns directly -- without any parsing.

* Xcontam_parse: This function converts the AADR column "Xcontam ANGSD MOM point estimate" to the Poseidon column "Xcontam". It replaces unncessary string values with `NA` (this measurement can only be determined for male samples).

* Data_type_parse: This function converts AADR "Data Source" to Poseidon "Data type". It requires the helper function %equalToLower%, to get data into a common format and reduce complexity.

* parse_udg_treatment: Cleans up "library type" and returns "UGD" for the `.janno` table. It converts "library type" of AADR into a proper list, then loops through the list and replaces unnecessary strings.

* Lib_type_to_Lib_built: This function checks the "Library type" values and derives Poseidon's "Library built" values ("ss" or "ds").

* Pub_clean: This function simplifies the AADR "Publication name" column and returns the corresponding Poseidon "Publication name".

* genotype: This function takes the AADR "Version ID" and -- based on its ".SG" or ".DG" suffix -- decides which genotype values to set in Poseidon's "Genotype_Ploidy".

* derive_standard_error: This function takes the AADR columns "Xcontam ANGSD MOM point estimate (only if male and ≥200)" and "Xcontam ANGSD MOM 95% CI truncated at 0 (only if male and ≥200)" as inputs. It cleans these data columns by cutting off unnecessary strings and only keeps a numeric value. The output is written to Poseidon's "Xcontam_stderr" and and rounded to 5 decimal places.

* age_string_parser: The lines 243 to 252 of `data migration.R` employ the function `split_age_string` in `age_string_parser.R`. This function takes the "Full date ..." column in the AADR dataset and returns a data frame with the Poseidon columns "Date_C14_Labnr,Date_C14_Uncal_BP,Date_C14_Uncal_BP_Err,Date_BC_AD_Start,Date_BC_AD_Stop,Date_Type".
