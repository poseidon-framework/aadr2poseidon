library(magrittr)

split_age_string <- function(x) {
  
  #### modify input (fixing small details) ####
  x <- gsub("\\+", "\u00B1", x) # replace + with \u00B1
  #x <- gsub("(.*)(?=\\()", "\\1 ", x, perl = T) # missing space before parentheses
  x <- gsub("AA-R-", "AAR- ", x) # fix wrong lab code (http://www.radiocarbon.org/Info/labcodes.html)
  x <- gsub("Wk - ", "Wk-", x) # fix wrong lab code
  x <- gsub("\u{00a0}", " ", x) # replace wrong space characters
  x <- gsub("¬†", " ", x)
  
  #### construct result table ####
  res <- tibble::tibble(
    Date_C14_Labnr = rep(NA, length(x)),
    Date_C14_Uncal_BP = NA,
    Date_C14_Uncal_BP_Err = NA,
    Date_BC_AD_Start = NA,
    Date_BC_AD_Stop = NA,
    Date_Type = NA
  )
  
  #### first rough determination of dating type info ####
  none_ids <- which(is.na(x))
  res$Date_Type[none_ids] <- "none"
  present_ids <- grep("present", x)
  res$Date_Type[present_ids] <- "modern"
  c14_age_ids <- grep("±", x) # indizes of suspected radiocarbon dates
  
  #### parse nice, full uncalibrated c14 dates ####
  # extract real, nice radiocarbon dates
  full_radiocarbon_dates <- stringr::str_extract_all(
    x[c14_age_ids], 
    paste0(
      "[0-9]{1,5}(\\s+)*\u00B1(\\s+)*[0-9]{1,4}( BP){0,1},{0,1}\\s{0,1}(", # pattern for age +/- std
      paste(
        c( # patterns for labnrs
          "CNA4579.1.1",
          "Beta [0-9]+",
          "COL3897.1.1",
          "A-",
          "D-AMS-[0-9]*",
          "AA84155",
          "KIA44691",
          "MAMS 21972",
          "R-EVA1606/MAMS-[0-9]*",
          "TÜBİTAK-[0-9]*",
          "AAR-\\s[0-9]*",
          "OxA-X-[0-9]*-[0-9]*",
          "CIRCE-DSH-[0-9]*",
          "ISGS-A[0-9]*",
          "CEDAD-LTL[0-9]*A",
          "[A-Za-z]{2,7}(\\s|-)[0-9]*" # that's the normal pattern, the others are deviating from that
        ),
        collapse = "|"
      ),
      ")"
    )
  )
  
  # if there is no real, nice date, then it can't be a proper C14 date at all
  full_radiocarbon_date_consumed <- purrr::map_lgl(full_radiocarbon_dates, function(x) {length(x) > 0})
  c14_age_ids_true <- c14_age_ids[full_radiocarbon_date_consumed]
  
  # split date and labnr
  full_radiocarbon_split <- purrr::map(full_radiocarbon_dates[full_radiocarbon_date_consumed], function(y) {
    #if (length(stringr::str_split(y, c("\u00B1|( BP){0,1}, "))[[1]])<3) {print(y)}
    stringr::str_split(y, c("\u00B1|( BP )|( BP){0,1},(\\s){0,1}")) %>% 
      purrr::transpose(c("uncal_age", "uncal_std", "labnr")) %>%
      purrr::map(unlist)
  }) %>% purrr::transpose()
  
  # write uncalibrated dates into the result table
  res$Date_C14_Uncal_BP[c14_age_ids_true] <- full_radiocarbon_split$uncal_age
  res$Date_C14_Uncal_BP_Err[c14_age_ids_true] <- full_radiocarbon_split$uncal_std
  res$Date_C14_Labnr[c14_age_ids_true] <- full_radiocarbon_split$labnr
  
  #### parse unnamed radiocarbon dates ####
  c14_age_ids_false <- c14_age_ids[!full_radiocarbon_date_consumed]
  unnamed_radiocarbon_dates <- stringr::str_extract_all(
    x[c14_age_ids_false], 
    "[0-9]{1,5}(\\s+)*\u00B1(\\s+)*[0-9]{1,4}"
  ) %>%
    # if more than 2 dates are listed, then the first value is (usually?) not a real date
    purrr::map(function(x) { if (length(x)>2) {x[-1]} else x })
  
  unnamed_radiocarbon_split <- purrr::map(unnamed_radiocarbon_dates, function(y) {
    stringr::str_split(y, c("\\s*\u00B1")) %>% 
      purrr::transpose(c("uncal_age", "uncal_std")) %>%
      purrr::map(unlist)
  }) %>% purrr::transpose()
  
  # write uncalibrated dates into the result table
  res$Date_C14_Uncal_BP[c14_age_ids_false] <- unnamed_radiocarbon_split$uncal_age
  res$Date_C14_Uncal_BP_Err[c14_age_ids_false] <- unnamed_radiocarbon_split$uncal_std
  
  #### finally fill Date_Type column ####
  res$Date_Type[!is.na(res$Date_C14_Uncal_BP)] <- "C14"
  res$Date_Type[is.na(res$Date_Type)] <- "contextual"
  
  #### parse contextual (and simplified) ages ####
  
  # remove parenthesis and split at space and minus
  simple_age_split <- x %>%
    stringr::str_replace_all("\\(", "") %>%
    stringr::str_replace_all("\\)", "") %>%
    stringr::str_split("\\s*-\\s*|-|\\s+")
  
  # translate first elements of the vector to meaningful start and stop ages
  stop <- start <- rep(NA, length(simple_age_split))
  for (i in 1:length(simple_age_split)) {
    # no age info
    if (is.na(simple_age_split[[i]][1])) {
      start[i] <- NA
      stop[i] <- NA
      next
    }
    # age below calibration range, e.g. >45000
    if (grepl("^>", simple_age_split[[i]][1])) {
      start[i] <- -Inf
      stop[i] <- -as.numeric(gsub(">", "", simple_age_split[[i]][1]))
      next
    }
    # no range: only one value e.g. 5000 BCE
    if (length(simple_age_split[[i]]) == 2) {
      if (simple_age_split[[i]][2] == "BCE") {
        start[i] <- -as.numeric(simple_age_split[[i]][1])
        stop[i] <- -as.numeric(simple_age_split[[i]][1])
        next
      }
      if (simple_age_split[[i]][2] == "CE") {
        start[i] <- as.numeric(simple_age_split[[i]][1])
        stop[i] <- as.numeric(simple_age_split[[i]][1])
        next
      } 
      if (all(grepl("^[0-9]+$", simple_age_split[[i]]))) {
        start[i] <- -as.numeric(simple_age_split[[i]][1])
        stop[i] <- -as.numeric(simple_age_split[[i]][2])
        next
      }
    }
    # normal range 5000-4700 BCE
    if (simple_age_split[[i]][3] %in% c("BCE", "calBCE")) {
      start[i] <- -as.numeric(simple_age_split[[i]][1])
      stop[i] <- -as.numeric(simple_age_split[[i]][2])
      next
    }
    if (simple_age_split[[i]][3] %in% c("CE", "calCE")) {
      start[i] <- as.numeric(simple_age_split[[i]][1])
      stop[i] <- as.numeric(simple_age_split[[i]][2])
      next
    }
    if (simple_age_split[[i]][2] %in% c("BCE", "calBCE") & simple_age_split[[i]][4] %in% c("CE", "calCE")) {
      start[i] <- -as.numeric(simple_age_split[[i]][1])
      stop[i] <- as.numeric(simple_age_split[[i]][3])
      next
    }
  }
  
  # write start and to the columns
  res$Date_BC_AD_Start <- start
  res$Date_BC_AD_Stop <- stop
  
  return(res)
}
