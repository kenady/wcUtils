#' Parse a *-Histos.csv files into a proper data.frame
#'
#' @param histo_file file path or file connection to a *-Histos.csv file
#' @param to_lower whether to convert the column names to lower case
#'
#' @return a data frame
#' @export
read_histos <- function(histo_file,to_lower = TRUE) {
  histo_lines <- readr::read_lines(file = histo_file)
  
  blank_rows <- function(histo_list) {
    row_check <- lapply(histo_list,function(x)
      nchar(x) < 10)
    return(which(row_check == TRUE))
  }
  
  #find the row with colnames and populate histo_colnames vector
  colnames_row <- function(histo_list) {
    row_check <-
      lapply(histo_list[1:10],function(x)
        grepl("HistType",x))
    return(which(row_check == TRUE))
  }
  
  histo_colnames <-
    unlist(strsplit(histo_lines[[colnames_row(histo_lines)]],','))
  
  #find the rows with the histo limit values and populate the histo_limits vector
  limits_rows <- function(histo_list) {
    row_check <- lapply(histo_list,function(x)
      grepl("LIMITS",x))
    return(which(row_check == TRUE))
  }
  
  histo_limits <- histo_lines[limits_rows(histo_lines)]
  
  histo_lines <- histo_lines[-c(blank_rows(histo_lines),
                                colnames_row(histo_lines),
                                limits_rows(histo_lines))]
  
  histo_lines <- lapply(histo_lines,function(x)
    strsplit(x,','))
  
  histos <- do.call("rbind", lapply(histo_lines,
                                    function(x)
                                      t(
                                        data.frame(x,row.names = NULL,stringsAsFactors = FALSE)
                                      )))
  rownames(histos) <- NULL
  #check if histos_df and histo_colnames have same number of columns; fix if needed
  if (ncol(histos) != length(histo_colnames)) {
    #we will presume that histos_df is short columns
    col2add <- length(histo_colnames) - ncol(histos)
    m <- matrix(data = "",nrow = nrow(histos),ncol = col2add)
    histos <- cbind(histos,m)
  }
  histos_df <- data.frame(histos,stringsAsFactors = FALSE)
  colnames(histos_df) <- sub(" ", "_", histo_colnames)
  if (to_lower == TRUE) {
    colnames(histos_df) <- tolower(colnames(histos_df))
  }
  
  #create our list of desired data types
  
  coltypes_list <- list(
    deployid = col_character(),
    ptt = col_character(),
    depthsensor = col_numeric(),
    source = col_character(),
    instr = col_character(),
    histtype = col_character(),
    date = col_datetime(format = "%H:%M:%S %d-%b-%Y",tz = "UTC"),
    time_offset = col_numeric(),
    count = col_integer(),
    locationquality = col_character(),
    latitude = col_numeric(),
    longitude = col_numeric(),
    numbins = col_integer(),
    sum = col_numeric()
  )
  
  bintypes <-
    lapply(1:72,function(x)
      eval(parse(text = "col_numeric()")))
  names(bintypes) <- rep(paste0("bin",1:72))
  
  coltypes_list <- c(coltypes_list,bintypes)
  
  histos_df <- readr::type_convert(histos_df,col_types = coltypes_list)
  return(histos_df)
}