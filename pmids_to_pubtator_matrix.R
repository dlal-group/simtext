#!/usr/bin/env Rscript
#tool: pmids_to_pubtator_matrix
#
# The tool uses all PMIDs per row and extracts "Gene", "Disease", "Mutation", "Chemical" and "Species" terms of the 
# corresponding abstracts, using PubTator annotations. The user can choose from which categories terms should be extracted. 
# The extracted terms are united in one large binary matrix, with 0= term not present in abstracts of 
# that row and 1= term present in abstracts of that row.
#
#Input: Output of abstracts_by_pmids or tab-delimited table with columns containing PMIDs. 
#The names of the PMID columns should start with "PMID", e.g. "PMID_1", "PMID_2" etc.
#
#Output: Binary matrix in that each column represents one of the extracted terms.
#
# r-stringr 1.4.0, r-argparse-2.0.1, r-rcurl 1.95_4.12
#
# usage: $ pmids_to_pubtator_matrix.R [-h] [-i INPUT] [-o OUTPUT]
# [-c {Genes,Diseases,Mutations,Chemicals,Species} [{Genes,Diseases,Mutations,Chemicals,Species} ...]]
# 
# optional arguments:
#   -h, --help                 show help message
#   -i INPUT, --input INPUT    input file name. add path if file is not in workind directory
#   -o OUTPUT, --output OUTPUT output file name. [default "pmids_to_pubtator_matrix_output"]
#   -c {Gene,Disease,Mutation,Chemical,Species} [{Genes,Diseases,Mutations,Chemicals,Species} ...], --categories {Gene,Disease,Mutation,Chemical,Species} [{Gene,Disease,Mutation,Chemical,Species} ...]
#      Pubtator categories that should be considered.  [default "('Gene', 'Disease', 'Mutation','Chemical')"]

if (!require('argparse')) install.packages('argparse'); suppressPackageStartupMessages(library("argparse"))
if (!require('stringr')) install.packages('stringr'); library('stringr')
if (!require('RCurl')) install.packages('RCurl'); library('RCurl')

parser <- ArgumentParser()

parser$add_argument("-i", "--input", 
                    help = "input fie name. add path if file is not in workind directory")
parser$add_argument("-o", "--output", default="pmids_to_pubtator_matrix_output",
                    help = "output file name. [default \"%(default)s\"]")
parser$add_argument("-c", "--categories", choices=c("Gene", "Disease", "Mutation", "Chemical", "Species"), nargs="+", 
                    default= c("Gene", "Disease", "Mutation", "Chemical"),
                    help = "Pubtator categories that should be considered. [default \"%(default)s\"]")

args <- parser$parse_args()

#args$input = "~/Dropbox/LAL_PROJECTS/RESEARCH_PORTAL/SimText/examples/data/1b/T1_output"
data = read.delim(args$input, stringsAsFactors=FALSE, header = TRUE, sep='\t')

pmid_cols_index <- grep(c("PMID"), names(data))
word_matrix = data.frame()
dict.table = data.frame()
pmids_count_total <- 0

get_pubtator_terms = function(pmids, categories){

  cat(1)
      out.data = NULL
      table = NULL
      try_num <- 1
      t_0 <- Sys.time()

      
      while(is.null(out.data)) {
        
        # Timing check: kill at 3 min
        if (try_num > 1){
          Sys.sleep(time = 2*try_num)
          cat("Connection problem. Please wait. Try number:",try_num,"\n") 
        }

        t_1 <- Sys.time()
        
        if(as.numeric(difftime(t_1, t_0, units = "mins")) > 3){
          message("Killing the request! Something is not working. Please, try again later","\n")
          return(table)
        }

      out.data <- tryCatch({    
          getURL(paste("https://www.ncbi.nlm.nih.gov/research/pubtator-api/publications/export/pubtator?pmids=", pmids, sep = ""))
        }, error = function(e) {
          NULL
        }, finally = {
            Sys.sleep(0)
        })
      
      if(!is.null(out.data)){
        out.data = unlist(strsplit(out.data, "\n", fixed = T))
        
        for (i in 3:length(out.data)) {
          temps = unlist(strsplit(out.data[i], "\t", fixed = T))
          if (length(temps) == 5) {
            temps = c(temps, NA)
          }
          table = rbind(table, temps)
        }
      }
      
      # Check if error
      if (!is.null(out.data) && ncol(table) != 6) {
        out.data <- NULL
      }
      
      try_num <- try_num + 1
      
    } #end while loop
    
    index.categories = c()
    categories = as.character(unlist(categories))
    
    if(ncol(table) == 6){
      
      for(i in categories){
        tmp.index = grep(TRUE, i == as.character(table[,5]))
        
        if(length(tmp.index) > 0){
          index.categories = c(index.categories,tmp.index)
        }

        table = as.data.frame(table, stringsAsFactors=FALSE)
        table = table[index.categories,c(4,6)]
        table = table[!is.na(table[,2]),]
        table = table[!duplicated(table[,2]),]
        
        return(table)
      }
    } else {
      return(NULL)
    }
}

#for all PMIDs of a row get PubTator terms and add them to the matrix
for (i in 1:nrow(data)){
  
  print(paste("Row", i))
  pmids = as.character(data[i,pmid_cols_index])
  pmids = pmids[!pmids == "NA"]
  pmids_count_total = pmids_count_total + length(pmids)
  
    if(pmids_count_total > 1000){
      cat("Break (60s) to avoid killing of requests. Please wait.",'\n')
      Sys.sleep(60)
      pmids_count_total = c()
    }
    
    #get_pubtator_terms function
    if (length(pmids) >0){
      table = get_pubtator_terms(pmids, args$categories)
      
      if(!is.null(table)){
        colnames(table) = c("term","mesh.id")
        mesh.ids = as.character(table[,2])
        
        # add data in binary matrix
        if (length(mesh.ids) > 0 ){
          word_matrix[i,mesh.ids] <- 1 
          cat(length(mesh.ids), "different terms for PMIDs of row", i," were found.",'\n')
        }
        
        # add data in dictionnary
        dict.table = rbind(dict.table, table)
        dict.table = dict.table[!duplicated(as.character(dict.table[,2])),]
      }
    } else {
      cat("No terms for PMIDs of row", i," were found.",'\n')
   }
  }

#change column names of matrix: exchange meshids/ids with term
index_names = match(names(word_matrix), as.character(dict.table[[2]]))
colnames(word_matrix) = dict.table[index_names,1]

#binary matrix
word_matrix <- as.matrix(word_matrix)
word_matrix[is.na(word_matrix)] <- 0

cat("Matrix with ",nrow(word_matrix)," rows and ",ncol(word_matrix)," columns generated.","\n")
write.table(word_matrix, args$output, row.names = FALSE, sep = '\t')

