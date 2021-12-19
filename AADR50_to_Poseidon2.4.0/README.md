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

The `--minimal` flag will keep the output package as simple as possible and only add a minimal `POSEIDON.yml file`.

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

This script translates .anno to .janno files in an opinionated way. Here we document the decisions we made for individual parameters. If you apply changes to this script, remember to validate output `.janno` file with trident or `poseidonR::validate_janno`.

* Basic column extraction function: This is the primary function that used to extract data from relevent AADR v50 columns directly without any parsings.

* Xcontam_parse: this function converts "Xcontam ANGSD MOM point estimate" into Poseidon "Xcontam" data. It replaces unncessary string values with NA values. As this measurement can only taken with male samples.

* Data_type_parse: this function converts AADR v50 "Data Source" column data into Poseidon 2.4 "Data type" data. 
Its nested with supportive %equalToLower% function to get data into common format nd minimalize complexities.

* parse_udg_treatment: clean up "library type" of AADR v50 and returns UGD value to Poseidon table. It converts "library type" of AADR into a proper list, then loop through the list and replace unnecesary strings.

* Lib_type_to_Lib_built: This function check the Library type values and decidethe Library built values as "ss" or "ds"

* Pub_clean: This function clear the AADR "Publication name" column and return corresponding Poseidon publication name.

* genotype: This function gets the AADR version ID and based on Its ".SG" or ".DG" part decides the genotype values of Poseidon "Genotype_Ploidy" 

* derive_standard_error: This function gets AADR "Xcontam ANGSD MOM point estimate (only if male and ≥200)" "Xcontam ANGSD MOM 95% CI truncated at 0 (only if male and ≥200)" as inputs. Then it clear those data columns by cuting of unnecessary string parts and obtains a numeric value. Afterwards formulates Poesidon "Xcontam_stderr" value and round it off upto 5 digits. 

* age_string_parser: Lines from #243 to #252 of this script are based on script "age_string_parser.R". Clone it and open in R. Function "split_age_string" takes in full date value of AADR and returns "Date_C14_Labnr,Date_C14_Uncal_BP,Date_C14_Uncal_BP_Err,Date_BC_AD_Start,Date_BC_AD_Stop,Date_Type" as a table which is assigned into the data object "Dates".


Relationships of Poseidon data fields to their corresponding AADR v50 data fields can be listed as below

*Individual_ID from Version ID : Extracted from AADR "Version ID" without any parsing

*Collection_ID from  Skeletal code : Extracted from AADR "Skeletal code" without any parsing

*Source_Tissue from Skeletal element : Extracted from AADR "Skeletal element" without any parsing

*Country from Country : Extracted from AADR "Country" without any parsing

*Location from	Locality : Extracted from AADR "Location" without any parsing

*Site	  -	                         Not Available in AADR. So Kept as NA

*Latitude from	Lat.	 :  Extracted from AADR "Lat." without any parsing

*Longitude from Long.	:   Extracted from AADR "Long." without any parsing

*Date_C14_Labnr from	Full date   :     radio carbon dated lab number 

*Date_C14_Uncal_BP from Full date : Uncalibrated carbon date.Extracted from AADR "Full Date" values. If the "Date_Type" is C14 	

*Date_C14_Uncal_BP_Err from Full date : Standard error of uncalibrated carbon date.Extracted from AADR "Full Date" values. If the "Date_Type" is C14 		

*Date_BC_AD_Median from Date mean in BP : Extracted from AADR "Date mean in BP " without any parsing	

*Date_BC_AD_Start from	Full date : Split the AADR "Full date" string and gets the earliest calibrated carbon date 	

*Date_BC_AD_Stop from	Full date : Split the AADR "Full date" string and gets the end value calibrated carbon date 		

*Date_Type from Full date : Based on the AADR "Full Date" values determines wether the information derived throgh radiocarbon dating (C14) or contextual information given by the experts or samples belong to modern era. 	

*No_of_Libraries from	No. Libraries : Extracted from AADR "No.Libraries" without any parsing

*Data_Type from Data source :	Determine the Data_Type depending on AADR “Data source” 

*Genotype_Ploidy from Version ID : Check if the AADR "Version ID" ends with ".SD". Genotype_Poloidy is considered as "haploid" if it is true. Otherwise it is considered as "diploid". 

*Group_Name from Group ID : Extracted from AADR "Group ID" without any parsing

*Genetic_Sex from Sex : Extracted from AADR "Sex" without any parsing

*Nr_autosomal_SNPs from SNPs hit on autosomal targets : Extracted from AADR "SNPs hit on autosomal targets" without any parsing

*Coverage_1240K from Coverage on autosomal targets : Extracted from AADR "Coverage on autosomal targets" without any parsing

*MT_Haplogroup from mtDNA haplogroup if â‰¥2 or published : Extracted from AADR "mtDNA haplogroup if â‰¥2 or published" without any parsing

*Y_Haplogroup from Y haplogroup in ISOGG v15.73 notation (automatically called) : Extracted from AADR "Y haplogroup in ISOGG v15.73 notation (automatically called)" without any parsing

*Endogenous	-	Not Available in AADR. So Kept as NA

*UDG from Library type : Split the “Library type” string and extract the first part of it which contain UDG value. Determine wether it is “minus” , “half” ,”plus” or a mixture of multiple values

*Library_Built from Library type : Get the later part of “Library_type” and decide its single stranded (ss) or double stranded (ds) or an other value

*Damage from Damage rate in first nucleotide on sequences overlapping 1240k targets (merged data) :	Extracted from AADR "Damage rate in first nucleotide on sequences overlapping 1240k targets (merged data)" without any parsing

*Xcontam from Xcontam ANGSD MOM point estimate (only if male and ≥200) : Clears AADR "Xcontam ANGSD MOM point estimate (only if male and ≥200)" by removing unnecessary string parts, Then gets the contamination of X chromasomes based on  ANGSD format. 

*Xcontam_stderr from	Xcontam ANGSD MOM 95% CI truncated at 0 (only if male and â‰¥200) :

*mtContam	-	Not Available in AADR. So Kept as NA

*mtContam_stderr	-	Not Available in AADR. So Kept as NA

*Primary_Contact	-	Not Available in AADR. So Kept as NA

*Publication_Status from Publication :

*Note from ASSESSMENT :  Extracted from AADR "ASSESMENT" without any parsing

*Keywords	-	Not Available in AADR. So Kept as NA

*Genetic_Source_Accession_IDs	-	Not Available in AADR. So Kept as NA

*Data_Preparation_Pipeline_URL	-	Not Available in AADR. So Kept as NA








