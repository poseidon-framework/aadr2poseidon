----------This this a walkthrough to convert AADR v50 to Poseidon v2.4.0----------------------
Steps and Descriptions ::
Clone the repository and open "data migration.R" script
It gets a copy of AADR50 1240K data into your local R working directory with the correct formattings. 
The it simplifies extra long column names which makes preview within R easy.
This script parses AADR v50 data into there respective poseidone columns.Please refer the column guide to check which AADR v50 columns relevent to Poseidon standards. 

---How this script works---
It makes a dummy dataframe called "test_pub" within your R working directoryaccording to Poseidon 2.40 standards.
line 159 # subseting necessary data from anno is used to subset the data of the publication that you want to convert into a poseidon package.
Then It uses built in functions to extract and parse data. 

---Function Descriptions---
* Basic column extraction function : This is the primary function that used to extract data from relevent AADR v50 columns directly without any parsings.

*Xcontam_parse : this function converts "Xcontam ANGSD MOM point estimate" into Poseidon "Xcontam" data. It replaces unncessary string values with NA values. As this measurement can only taken with male samples.

*Data_type_parse : this function converts AADR v50 "Data Source" column data into Poseidon 2.4 "Data type" data. 
Its nested with supportive %equalToLower% function to get data into common format nd minimalize complexities.

*parse_udg_treatment : clean up "library type" of AADR v50 and returns UGD value to Poseidon table. It converts "library type" of AADR into a proper list, then loop through the list and replace unnecesary strings.

*Lib_type_to_Lib_built : This function check the Library type values and decidethe Library built values as "ss" or "ds"
*Pub_clean : This function clear the AADR "Publication name" column and return corresponding Poseidon publication name.
*genotype : This function gets the AADR version ID and based on Its ".SG" or ".DG" part decides the genotype values of Poseidon "Genotype_Ploidy" 
*derive_standard_error : This function gets AADR "Xcontam ANGSD MOM point estimate (only if male and ≥200)" "Xcontam ANGSD MOM 95% CI truncated at 0 (only if male and ≥200)" as inputs. Then it clear those data columns by cuting of unnecessary string parts and obtains a numeric value. Afterwards formulates Poesidon "Xcontam_stderr" value and round it off upto 5 digits. 
*age_string_parser : Lines from #243 to #252 of this script are based on script "age_string_parser.R". Clone it and open in R. Function "split_age_string" takes in full date value of AADR and returns "Date_C14_Labnr,Date_C14_Uncal_BP,Date_C14_Uncal_BP_Err,Date_BC_AD_Start,Date_BC_AD_Stop,Date_Type" as a table which is assigned into the data object "Dates" .



----------------How to make new poseidon packags from the data extracted from AADR v50--------------------

1)Validate extracted data using PoseidonR
#in R : PoseidonR::Validate_janno
2)Create the forge file in R with all the individual names as a list with "<[individual name ]>" format
#Dummy syntax in R : writeLines(paste0("<",data.field,">"),con = "file_name.txt") 
3)Export seperated AADR data as a .janno file
#In R : PoseidonR::write_janno
4)Run Trident init
#trident init \
  --inFormat EIGENSTRAT \
  --genoFile aadr_eig.geno \
  --snpFile aadr_eig.snp \
  --indFile aadr_eig.ind \
  --snpSet 1240K \
  -o new_package \
  --minimal
  
5)Run Trident forge. "forge_list.txt" is the forge file created in step 2. -o is the desired location to make new package
# trident forge -d . \
  --forgeFile forge_list.txt \
  -o /home/user/Poseidon_data/New.janno_packages

Once the new packge is made ,
6) Replace the dummy.janno file with the file created in step 3
7)Make Bibiolethic data in ".bib" file.
8) Run trident validate to check wether everything is in correct format
9)Run Trident update
10) Commit nd Push your new changes


