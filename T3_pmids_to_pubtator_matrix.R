#!/usr/bin/env Rscript
#TOOL3:pmids_to_pubtator_matrix
#
# The tool takes all PMIDs per ID and uses pubtator to extract all "Genes", "Diseases", "Mutations", "Chemicals", "Species" terms of the abstracts. 
# The user can choose if terms of all, some or one of the aforementioned categories should be used.
# All terms that occured for all IDs are used to generate a matrix with rows= IDs and columns= terms.
# The resulting matrix is binary with 0= did not occur and 1= did occur. 

# usage: T3_pmids_to_pubtator_matrix.R [-h] [-i INPUT] [-o OUTPUT]
# [-c {Genes,Diseases,Mutations,Chemicals,Species} [{Genes,Diseases,Mutations,Chemicals,Species} ...]]
# 
# optional arguments:
#   -h, --help                 show this help message and exit
#   -i INPUT, --input INPUT    input fie name. add path if file is not in workind directory
#   -o OUTPUT, --output OUTPUT output file name. [default "T3_result"]
#   -c {Genes,Diseases,Mutations,Chemicals,Species} [{Genes,Diseases,Mutations,Chemicals,Species} ...], --categories {Genes,Diseases,Mutations,Chemicals,Species} [{Genes,Diseases,Mutations,Chemicals,Species} ...]
#      Pubtator categories that should be considered.  [default "('Genes', 'Diseases', 'Mutations','Chemicals')"]

if (!require('argparse')) install.packages('argparse'); suppressPackageStartupMessages(library("argparse"))
if (!require('stringr')) install.packages('stringr'); library('stringr')
if (!require('pubmed.mineR')) install.packages('pubmed.mineR'); library('pubmed.mineR')

parser <- ArgumentParser()

parser$add_argument("-i", "--input", 
                    help = "input fie name. add path if file is not in workind directory")
parser$add_argument("-o", "--output", default="T3_result",
                    help = "output file name. [default \"%(default)s\"]")
parser$add_argument("-c", "--categories", choices=c("Genes", "Diseases", "Mutations", "Chemicals", "Species"), nargs="+", 
                    default= c("Genes", "Diseases", "Mutations", "Chemicals"),
                    help = "Pubtator categories that should be considered. [default \"%(default)s\"]")

args <- parser$parse_args()

data = read.delim(args$input, stringsAsFactors=FALSE, header = TRUE, sep='\t')
pmid_cols_index <- grep(c("PMID"), names(data))

word_matrix = data.frame()

get_pubtator_terms = function(pmids, categories){
  results= try(pubtator_function(as.character(pmids)))
  df_terms = as.data.frame(str_split_fixed(unlist(results[c(categories)]), ">", n=2))
  pubtator_terms = unique(as.character(df_terms$V1))
  pubtator_terms = pubtator_terms[!pubtator_terms==""]
  return(pubtator_terms)
}

for (i in 1:nrow(data)){

  terms= get_pubtator_terms(data[i,pmid_cols_index], args$categories)
  terms= terms[!terms == "No Data"]
  
  if (length(terms) == 0){
      terms= get_pubtator_terms(data[i,pmid_cols_index], args$categories)
      terms= terms[!terms == "No Data"]
      Sys.sleep(30)}
  
  if (length(terms) == 0){
        terms= get_pubtator_terms(data[i,pmid_cols_index], args$categories)
        terms= terms[!terms == "No Data"]
        Sys.sleep(45)
        } 
  if (length(terms) == 0){
          terms= get_pubtator_terms(data[i,pmid_cols_index], args$categories)
          terms= terms[!terms == "No Data"]
          Sys.sleep(60)
  }
  
  #add terms to word matrix (as new or already existing columns) 
  if (length(terms) >0 ){
          word_matrix[i,terms] <- 1
          Sys.sleep(1)}
  
  if(round(i/5) == i/5){
    Sys.sleep(5)}
  
  cat("Pubtator found", length(terms), "terms for", data[i,"ID"],'\n')
}

word_matrix <- as.matrix(word_matrix)
word_matrix[is.na(word_matrix)] <- 0

cat("A word matrix with ",nrow(word_matrix)," rows and ",ncol(word_matrix)," columns is generated.","\n")

write.table(word_matrix, args$output, sep = '\t')

