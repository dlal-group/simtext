#!/usr/bin/env Rscript
#TOOL1 pubmed_by_queries

#Input: Tab-delimited table with entities in column called “ID_<name>”, e.g. “ID_genes” if entities are are genes.
#The entities are successively used as search query in PubMed.
#
#Output: Input table with additional columns containing PMIDs or abstracts from Pubmed.
#
#packages: r-easypubmed-2.13, r-argparse-2.0.1
#
#Usage: T1_pubmed_by_queries.R [-h] [-i INPUT] [-o OUTPUT] [-n {1,20}] [-a] [-k KEY]
# 
# optional arguments:
# -h, --help                  show this help message and exit
# -i INPUT, --input INPUT     input fie name. add path if file is not in working directory
# -o OUTPUT, --output OUTPUT  output file name. [default "T1_output"]
# -n {1,20}, --number {1,20}  Number of PMIDs or abstracts to save per ID [default "5"]
# -a, --abstract              Instead of PMIDs, abstracts are saved.
# -k KEY, --key KEY           If API key is available, add it to speed up the fetching of pubmed data.

if (!require('argparse')) install.packages('argparse');
suppressPackageStartupMessages(library("argparse"))

if (!require('easyPubMed')) install.packages('easyPubMed');
suppressPackageStartupMessages(library("easyPubMed"))

parser <- ArgumentParser()
parser$add_argument("-i", "--input", 
                    help = "input fie name. add path if file is not in workind directory")
parser$add_argument("-o", "--output", default="T1_output",
                    help = "output file name. [default \"%(default)s\"]")
parser$add_argument("-n", "--number", type="integer", default=5, choices=seq(1, 20), metavar="{0..20}",
                    help="Number of PMIDs (or abstracts) to save per  ID. [default \"%(default)s\"]")
parser$add_argument("-a", "--abstract", action="store_true", default=FALSE,
                    help="Instead of PMIDs, abstracts are saved.")
parser$add_argument("-k", "--key", type="character", 
                    help="If ncbi API key is available, add it to speed up the download of pubmed data.")
args <- parser$parse_args()


data = read.delim(args$input, stringsAsFactors=FALSE)
id_col_index <- grep("ID_", names(data))

pubmedsearch_by_keyword <- function(data, row, query, number, key, abstract){
  
    pubmed_search <- get_pubmed_ids(query, api_key = key)
    
    if(as.numeric(pubmed_search$Count) == 0){
      cat("No pubmed result for the following query: ", query, "\n")
      return(data)
    } else {
        if(abstract == FALSE){
          PMIDs <- fetch_pubmed_data(pubmed_search, retmax= number, format = "uilist") 
          if(length(PMIDs)>0){
            data[row,sapply(1:length(PMIDs),function(i){paste0("PMID_",i)})] <- PMIDs
            cat(length(PMIDs)," PMID(s) for ",query, " added.",  "\n")
          }
            return(data)
        } else {
          abstracts_xml <- fetch_pubmed_data(pubmed_search, retmax= number, format = "xml") 
          abstracts <- custom_grep(xml_data = abstracts_xml, tag = "Abstract", format = "char")
          
          if(length(abstracts)>0){
            abstracts= sapply(1:length(abstracts), function(i){paste(custom_grep(abstracts[i], tag="AbstractText", format="char"),collapse="")})
            data[row,sapply(1:length(abstracts),function(i){paste0("ABSTRACT_",i)})] <- abstracts
            cat(length(abstracts)," abstracts for ",query, " added.",  "\n")
            
            }
            return(data)
          }
    }
    }




for(i in 1:nrow(data)){
  data= pubmedsearch_by_keyword(data= data,
                                row= i,
                                query= data[i,id_col_index],
                                number= args$number,
                                key= args$key,
                                abstract= args$abstract) 
  if(round(i/10) == i/10){
    Sys.sleep(5)
  }}

write.table(data, args$output, append = FALSE, sep = '\t', row.names = FALSE, col.names = TRUE)






