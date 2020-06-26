#!/usr/bin/env Rscript
#tool: pubmed_by_queries
#
#
# This tool uses a set of search queries to download a defined number of abstracts or PMIDs for search query from PubMed. PubMed's search rules and syntax apply.
# 
# Input:
# 
# Tab-delimited table with search queries in a column starting with "ID_", e.g. "ID_gene" if search queries are genes. 
#
# Output: 
#
# Input table with additional columns with PMIDs or abstracts (--abstracts) from PubMed.
#
#packages: r-easypubmed-2.13, r-argparse-2.0.1
#
#Usage: $ pubmed_by_queries.R [-h] [-i INPUT] [-o OUTPUT] [-n NUMBER] [-a] [-k KEY]
# 
# optional arguments:
# -h, --help                  show this help message and exit
# -i INPUT, --input INPUT     input file name. add path if file is not in working directory
# -o OUTPUT, --output OUTPUT  output file name. [default "pubmed_by_queries_output"]
# -n NUMBER, --number NUMBER  number of PMIDs or abstracts to save per ID [default "5"]
# -a, --abstract              if abstracts instead of PMIDs should be retrieved use --abstracts 
# -k KEY, --key KEY           if NCBI API key is available, add it to speed up the fetching of pubmed data

if (!require('argparse')) install.packages('argparse');
suppressPackageStartupMessages(library("argparse"))

if (!require('easyPubMed')) install.packages('easyPubMed');
suppressPackageStartupMessages(library("easyPubMed"))

parser <- ArgumentParser()
parser$add_argument("-i", "--input", 
                    help = "input fie name. add path if file is not in working directory")
parser$add_argument("-o", "--output", default="pubmed_by_queries_output",
                    help = "output file name. [default \"%(default)s\"]")
parser$add_argument("-n", "--number", type="integer", default=5, 
                    help="Number of PMIDs (or abstracts) to save per  ID. [default \"%(default)s\"]")
parser$add_argument("-a", "--abstract", action="store_true", default=FALSE,
                    help="if abstracts instead of PMIDs should be retrieved use --abstracts ")
parser$add_argument("-k", "--key", type="character", 
                    help="if ncbi API key is available, add it to speed up the download of pubmed data")
args <- parser$parse_args()

MAX_WEB_TRIES = 100

data = read.delim(args$input, stringsAsFactors=FALSE)

id_col_index <- grep("ID_", names(data))

pubmed_data_in_table <- function(data, row, query, number, key, abstract){
if (is.null(query)){print(data)}
    pubmed_search <- get_pubmed_ids(query, api_key = key)

    if(as.numeric(pubmed_search$Count) == 0){
      cat("No PubMed result for the following query: ", query, "\n")
      return(data)
      
    } else if (abstract == FALSE) { # fetch PMIDs
          
            myPubmedURL <- paste("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?", 
                                 "db=pubmed&retmax=", number, "&term=", pubmed_search$OriginalQuery, "&usehistory=n", sep = "")
            # get ids
            idXML <- c()
            for (i in 1:MAX_WEB_TRIES){
              tryCatch({
                IDconnect <- suppressWarnings(url(myPubmedURL, open = "rb", encoding = "UTF8"))
                idXML <- suppressWarnings(readLines(IDconnect, warn = FALSE, encoding = "UTF8"))
                suppressWarnings(close(IDconnect))
                break
              }, error = function(e) {
                print(paste('Error getting URL, sleeping',2*i,'seconds.'))
                print(e)
                Sys.sleep(time = 2*i)
              })
          }

            PMIDs = c()
            
            for (i in 1:length(idXML)) {
              if (grepl("^<Id>", idXML[i])) {
                pmid <- custom_grep(idXML[i], tag = "Id", format = "char")
                PMIDs <- c(PMIDs, as.character(pmid[1]))
              }
            }
          

            if(length(PMIDs)>0){
              data[row,sapply(1:length(PMIDs),function(i){paste0("PMID_",i)})] <- PMIDs
              cat(length(PMIDs)," PMIDs for ",query, " are added in the table.",  "\n")
             }

            return(data) 
      
    } else if (abstract == TRUE) { # fetch abstracts and title text
          
          efetch_url = paste("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?", 
                             "db=pubmed&WebEnv=", pubmed_search$WebEnv, "&query_key=", pubmed_search$QueryKey, 
                             "&retstart=", 0, "&retmax=", number, 
                             "&rettype=", "null","&retmode=", "xml", sep = "")

          api_key <- pubmed_search$APIkey
          if (!is.null(api_key)) {
            efetch_url <- paste(efetch_url, "&api_key=", api_key, sep = "")
          }

          # initialize
          out.data <- NULL
          try_num <- 1
          t_0 <- Sys.time()
          
          # Try to fetch results
          while(is.null(out.data)) {
            
              # Timing check: kill at 3 min
              if (try_num > 1){
                Sys.sleep(time = 2*try_num)
                cat("Problem to receive PubMed data or error is received. Please wait. Try number:",try_num,"\n") 
                }

              t_1 <- Sys.time()
              
              if(as.numeric(difftime(t_1, t_0, units = "mins")) > 3){
                message("Killing the request! Something is not working. Please, try again later","\n")
                return(data)
              }
              
              # ENTREZ server connect
              out.data <- tryCatch({    
                tmpConnect <- suppressWarnings(url(efetch_url, open = "rb", encoding = "UTF8"))
                suppressWarnings(readLines(tmpConnect, warn = FALSE, encoding = "UTF8"))
              }, error = function(e) {
                print(e)
              }, finally = {
                try(suppressWarnings(close(tmpConnect)), silent = TRUE)
              })  
              
              # Check if error
              if (!is.null(out.data) && 
                  class(out.data) == "character" &&
                  grepl("<ERROR>", substr(paste(utils::head(out.data, n = 100), collapse = ""), 1, 250))) {
                  out.data <- NULL
              }
              try_num <- try_num + 1
          }
          
          if (is.null(out.data)) {
            message("Killing the request! Something is not working. Please, try again later","\n")
            return(data)
          } else {
            cat("Data retrieved from PubMed.", "\n")
          }
      
          # process xml data
          xml_data <- paste(out.data, collapse = "")
          
          # articles to list
          xml_data <- strsplit(xml_data, "<PubmedArticle(>|[[:space:]]+?.*>)")[[1]][-1]
          xml_data <- sapply(xml_data, function(x) {
                #trim extra stuff at the end of the record
                if (!grepl("</PubmedArticle>$", x))
                  x <- sub("(^.*</PubmedArticle>).*$", "\\1", x) 
                # Rebuid XML structure and proceed
                x <- paste("<PubmedArticle>", x)
                gsub("[[:space:]]{2,}", " ", x)}, 
                USE.NAMES = FALSE, simplify = TRUE)
          
          #titles
          titles = sapply(xml_data, function(x){
              x = custom_grep(x, tag="ArticleTitle", format="char")
              x <- gsub("</{0,1}i>", "", x, ignore.case = T)
              x <- gsub("</{0,1}b>", "", x, ignore.case = T)
              x <- gsub("</{0,1}sub>", "", x, ignore.case = T)
              x <- gsub("</{0,1}exp>", "", x, ignore.case = T)
              if (length(x) > 1){
                x <- paste(x, collapse = " ", sep = " ")
              } else if (length(x) < 1) {
                x <- NA
              }
              x
            }, 
            USE.NAMES = FALSE, simplify = TRUE)

          # abstracts
          abstract.text = sapply(xml_data, function(x){
            custom_grep(x, tag="AbstractText", format="char")}, 
            USE.NAMES = FALSE, simplify = TRUE)
          
          abstracts <- sapply(abstract.text, function(x){
                  if (length(x) > 1){
                    x <- paste(x, collapse = " ", sep = " ")
                    x <- gsub("</{0,1}i>", "", x, ignore.case = T)
                    x <- gsub("</{0,1}b>", "", x, ignore.case = T)
                    x <- gsub("</{0,1}sub>", "", x, ignore.case = T)
                    x <- gsub("</{0,1}exp>", "", x, ignore.case = T)
                  } else if (length(x) < 1) {
                    x <- NA
                  } else {
                    x <- gsub("</{0,1}i>", "", x, ignore.case = T)
                    x <- gsub("</{0,1}b>", "", x, ignore.case = T)
                    x <- gsub("</{0,1}sub>", "", x, ignore.case = T)
                    x <- gsub("</{0,1}exp>", "", x, ignore.case = T)
                  }
              x
          }, 
          USE.NAMES = FALSE, simplify = TRUE)
          
          #add title to abstracts
          if (length(titles) == length(abstracts)){
            abstracts = paste(titles,  abstracts)
          }

          if(length(abstracts)>0){
            data[row,sapply(1:length(abstracts),function(i){paste0("ABSTRACT_",i)})] <- abstracts
            cat(length(abstracts)," abstracts for ",query, " are added in the table.",  "\n")
          }
          
          return(data)
        }
    }

for(i in 1:nrow(data)){
    print(paste("Fetching PubMed data for",data[i,id_col_index]))
    data = tryCatch(pubmed_data_in_table(data= data, 
                           row= i,
                           query= data[i,id_col_index],
                           number= args$number,
                           key= args$key,
                           abstract= args$abstract), error=function(e){
                             print('main error')
                             print(e)
                             Sys.sleep(5)
                             })
    }


write.table(data, args$output, append = FALSE, sep = '\t', row.names = FALSE, col.names = TRUE)


