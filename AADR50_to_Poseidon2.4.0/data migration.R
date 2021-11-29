library(magrittr)

anno <- readr::read_tsv(
  "https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V50/V50.0/SHARE/public.dir/v50.0_1240K_public.anno",
  col_names = T ,
  show_col_types = F ,
  skip_empty_rows = F ,
  na = c("..", "", "n/a", "na")
)

names(anno)[38] <- "contamLD"
names(anno)[6] <- "Published Year"
names(anno)[8] <- "Method of determining date"
names(anno)[9] <- "Date mean"
names(anno)[10] <- "Date SD"
names(anno)[11] <- "Full date"
names(anno)[44] <- "Assesment reasoning"
names(anno)[41] <- "Library type"

# basic column extraction function
`%extract%` <- function(dfnew, varr) {
  if (varr %in% colnames(dfnew)) { dfnew[[varr]] } else { NA }
}

# replacing unnecessary strings with ""
`%xcontam_parse%` <- function(dfnew,varr) {
  if (varr %in% colnames(dfnew)) {
    as.numeric(gsub("n\\/a\\s\\(.*\\)",NA,dfnew[[varr]]))
  } else {
    NA 
  }
}

# helper function to compare to strings irrespective of case
`%equalToLower%` <- function(a,b) {
  tolower(a) == tolower(b)
}

# translating the Data source column
`%data_type_parse%` <- function(dfnew,varr) {
  if(varr %in% colnames(dfnew)) {
    dplyr::case_when( 
      dfnew[[varr]] %equalToLower% "1240K" ~ "1240K",
      dfnew[[varr]] %equalToLower% "Shotgun" ~ "Shotgun",
      dfnew[[varr]] %equalToLower% "Reference.Genome" ~ "Reference Genome" ,
      dfnew[[varr]] %equalToLower% "whole.genome.capture" ~ "Whole Genome Capture",
      TRUE ~ "OtherCapture"
    ) 
  } else {
    NA
  }
}

# clean up library type and returns UGD value
'%Library_type_clean%' <- function(dfnew,varr) {
  if (varr %in% colnames(dfnew)) {
    newlist <- lapply(dfnew[[varr]] %>% strsplit(","), function(x) {unique(x)})
    Cleaned_UDG <- dplyr::case_when(
      length(newlist) > 1 || (!is.na(newlist)) && newlist == "Mix"~ "Mixed" , (!is.na(newlist)) && newlist == ".." ~ "NA"  )
    return(Cleaned_UDG)
  }}

`%Lib_type_to_Lib_built%` <- function(dfnew, varr) {
  if (varr %in% colnames(dfnew)) { ifelse(grepl("^ss.", dfnew[[varr]]),"ss","ds") } else { NA } 
}

# clean up the publication. split the string and get the publication name 
'%Pub_clean%' <- function(dfnew, varr) {
  if (varr %in% colnames(dfnew)) {ifelse(grepl("^\\s*$", dfnew[[varr]]),strsplit(dfnew[[varr]]," ")[[1]][1], dfnew[[varr]]) } else { NA }
} 

'%genotype%' <- function(dfnew,varr) {
  if (varr %in% colnames(dfnew)) {ifelse(grepl("^.SG",dfnew[[varr]]),"Haploid",
                                         ifelse(grepl("^.DG",dfnew[[varr]]),"Diploid","Diploid"))}
  else {NA}
}
# subseting necessary data from anno
dfnew <- subset(anno,Publication=="PapacScienceAdvances2021")

#used theold table structure
test_pub <- tibble::tibble(
  source_file = NA,
  # IDs
  Individual_ID = rep(NA, nrow(dfnew)),
  Collection_ID = NA,
  # sample info
  Source_Tissue = NA,
  # spatial location
  Country = NA,
  Location = NA,
  Site = NA,
  Latitude = NA,
  Longitude = NA,
  # temporal location
  Date_C14_Labnr = NA,
  Date_C14_Uncal_BP = NA,
  Date_C14_Uncal_BP_Err = NA,
  Date_BC_AD_Median = NA,
  Date_BC_AD_Start = NA,
  Date_BC_AD_Stop = NA,
  Date_Type = NA,
  # aDNA info
  No_of_Libraries = NA,
  Data_Type = NA,
  Genotype_Ploidy = NA,
  Group_Name = NA,
  Genetic_Sex = NA,
  Nr_autosomal_SNPs = NA,
  Coverage_1240K = NA,
  MT_Haplogroup = NA,
  Y_Haplogroup = NA,
  Endogenous  = NA,
  UDG  = NA,
  Library_Built = NA,
  Damage = NA,
  Xcontam = NA, 
  Xcontam_stderr = NA,
  mtContam = NA,
  mtContam_stderr = NA,
  # meta info
  Primary_Contact = NA,
  Publication_Status = NA,
  Note = NA,
  Keywords= NA,
  Genetic_Source_Accession_IDs =NA,
  Data_Preparation_Pipeline_URL =NA
)

test_pub$Individual_ID <- dfnew %extract% "Version ID"
test_pub$Collection_ID <- dfnew %extract% "Skeletal code"
test_pub$Country <- dfnew %extract% "Country"
test_pub$Location <- dfnew %extract% "Locality"
test_pub$Latitude <- dfnew %extract% "Lat."
test_pub$Longitude <- dfnew %extract% "Long."
test_pub$No_of_Libraries <- dfnew %extract% "No.Libraries"
test_pub$Source_Tissue <- dfnew %extract% "Skeletal element"
test_pub$No_of_Libraries <- dfnew %extract% "No. Libraries"
test_pub$Data_Type <- dfnew %data_type_parse% "Data source"
test_pub$Group_Name <- dfnew %extract% "Group ID"
test_pub$Genetic_Sex <- dfnew %extract% "Sex"
test_pub$Nr_autosomal_SNPs <- dfnew %extract% "SNPs hit on autosomal targets"
test_pub$Coverage_1240K <- dfnew %extract% "Coverage on autosomal targets"
test_pub$MT_Haplogroup <- dfnew %extract% "mtDNA haplogroup if ≥2 or published"
test_pub$Y_Haplogroup<- dfnew %extract% "Y haplogroup in ISOGG v15.73 notation (automatically called)"
test_pub$UDG <- dfnew %Library_type_clean% "Library type"
test_pub$Library_Built <- dfnew %Lib_type_to_Lib_built% "Library type"
test_pub$Damage <- dfnew %extract% "Damage rate in first nucleotide on sequences overlapping 1240k targets (merged data)"
test_pub$Endogenous <- NA
test_pub$Site <- NA
test_pub$mtContam <- NA
test_pub$mtContam_stderr <- NA
test_pub$Primary_Contact <- NA
test_pub$Keywords <- NA
test_pub$Genetic_Source_Accession_IDs <- NA
test_pub$Data_Preparation_Pipeline_URL <- NA
test_pub$Xcontam <- dfnew %xcontam_parse% "Xcontam ANGSD MOM point estimate (only if male and ≥200)"
test_pub$Publication_Status <- dfnew %Pub_clean% "Publication"
test_pub$Genotype_Ploidy <- dfnew %genotype% "Version ID"
# Clemens full date parsing function gose below
dates <- split_age_string(dfnew$`Full date`)
test_pub$Date_C14_Labnr <- dates$Date_C14_Labnr
test_pub$Date_C14_Uncal_BP <- dates$Date_C14_Uncal_BP
test_pub$Date_C14_Uncal_BP_Err <- dates$Date_C14_Uncal_BP_Err
test_pub$Date_BC_AD_Start <- dates$Date_BC_AD_Start
test_pub$Date_BC_AD_Stop <- dates$Date_BC_AD_Stop
test_pub$Date_Type <- dates$Date_Type
# (Kept as NA for the moment) test_pub$Date_BC_AD_Median <- rowMeans(x <-tibble(dates$Date_BC_AD_Start,dates$Date_BC_AD_Stop))
test_pub$Date_BC_AD_Median <- NA

# Used Clemens old function
derive_standard_error <- function(anno, mean_var, err_var) {
  mean_val <- anno[[mean_var]]
  mean_val[mean_val == "n/a (<200 SNPs)"] <- NA
  mean_val <- as.numeric(mean_val)
  err_val <- anno[[err_var]]
  err_val[err_val == "n/a (<200 SNPs)"] <- NA
  range_list <- strsplit(gsub("\\[|\\]", "", err_val), ",")
  unlist(Map(
    function(mean_one, range_list_one) {
      lower_range <- as.numeric(range_list_one[1])
      upper_range <- as.numeric(range_list_one[2])
      if (is.na(mean_one) || is.na(lower_range) || is.na(upper_range)) {
        NA
      } else if ( upper_range < 1 ) {
        abs(upper_range - mean_one) / 1.65
      } else if ( upper_range >= 1 & lower_range > 0 ) {
        abs(mean_one - lower_range) / 1.65
      } else {
        NA
      }
    }, 
    mean_val, range_list
  ))
}
test_pub$Xcontam_stderr <- derive_standard_error(dfnew,"Xcontam ANGSD MOM point estimate (only if male and ≥200)","Xcontam ANGSD MOM 95% CI truncated at 0 (only if male and ≥200)")
