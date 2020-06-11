#!/usr/bin/env Rscript
# TOOL3 text_to_wordmatrix
#
#The tool extracts the most frequent words per entity (per row). Text of columns starting with "ABSTRACT" or "TEXT" are considered. 
#All extracted terms are used to generate a word matrix with rows = entities and columns = extracted words. 
#The resulting matrix is binary with 0= word not present in abstracts of entity and 1= word present in abstracts of entity.
#
#Input: Output of tool 1 or 2, or tab-delimited table with entities in column called “ID_<name>”, 
#e.g. “ID_genes” and text in columns starting with "ABSTRACT" or "TEXT".
#
#Output: Binary matrix with rows = entities and columns = extracted words.
#
#packages: r-argparse-2.0.1, r-textclean-0.9.3, r-snowballc-0.6.0,  r-pubmedwordcloud-0.3.3, ("SemNetCleaner" not found in anaconda cloud)
#
#usage: T3_text_to_wordmatrix.R [-h] [-i INPUT] [-o OUTPUT] [-n NUMBER] [-r] [-l] [-w] [-s] [-p]
# 
# optional arguments:
# -h, --help                    show help message
# -i INPUT, --input INPUT       input file name. add path if file is not in working directory
# -o OUTPUT, --output OUTPUT    output file name. [default "T3_output"]
# -n NUMBER, --number NUMBER    number of most frequent words that should be extracted [default "50"]
# -r, --remove_num              remove any numbers in text
# -l, --lower_case              by default all characters are translated to lower case. otherwise use -l
# -w, --remove_stopwords        by default a set of english stopwords (e.g., 'the' or 'not') are removed. otherwise use -w
# -s, --stemDoc                 apply Porter's stemming algorithm: collapsing words to a common root to aid comparison of vocabulary
# -p, --plurals                 by default words in plural and singular are merged to the singular form. otherwise use -p

if (!require('argparse')) install.packages('argparse'); suppressPackageStartupMessages(library("argparse"))
if (!require("PubMedWordcloud")) install.packages("PubMedWordcloud"); library("PubMedWordcloud") 
if (!require('SnowballC')) install.packages('SnowballC'); suppressPackageStartupMessages(library("SnowballC"))
if (!require('textclean')) install.packages('textclean'); suppressPackageStartupMessages(library("textclean"))
if (!require('SemNetCleaner')) install.packages('SemNetCleaner'); suppressPackageStartupMessages(library("SemNetCleaner"))

parser <- ArgumentParser()
parser$add_argument("-i", "--input", 
                    help = "input fie name. add path if file is not in workind directory")
parser$add_argument("-o", "--output", default="T3_output",
                    help = "output file name. [default \"%(default)s\"]")
parser$add_argument("-n", "--number", type="integer", default=50, choices=seq(1, 500), metavar="{0..500}",
                    help="Number of most frequent words used per ID in word matrix [default \"%(default)s\"]")
parser$add_argument("-r", "--remove_num", action="store_true", default=FALSE,
                    help= "Remove any numbers in text.")
parser$add_argument("-l", "--lower_case", action="store_false", default=TRUE,
                    help="By default all characters are translated to lower case. Use -l if unwanted.")
parser$add_argument("-w", "--remove_stopwords", action="store_false", default=TRUE,
                    help="By default a set of English stopwords (e.g., 'the' or 'not') are removed. Use -s if unwanted.")
parser$add_argument("-s", "--stemDoc", action="store_true", default=FALSE,
                    help="Apply Porter's stemming algorithm: collapsing words to a common root to aid comparison of vocabulary")
parser$add_argument("-p", "--plurals", action="store_false", default=TRUE,
                    help="By default words in plural and singular are merged to the singular form. Use -p if unwanted")


args <- parser$parse_args()


data = read.delim(args$input, stringsAsFactors=FALSE, header = TRUE, sep='\t')
word_matrix = data.frame()

text_cols_index <- grep(c("ABSTRACT|TEXT"), names(data))
id_col_index <- grep("ID_", names(data))

for(row in 1:nrow(data)){
    top_words = cleanAbstracts(abstracts= data[row,text_cols_index], 
                               rmNum = args$remove_num, 
                               tolw= args$lower_case,
                               rmWords= args$remove_stopwords,
                               stemDoc= args$stemDoc)
    
    top_words$word <- as.character(top_words$word)
    
    #cat("Top words for ", data[row,id_col_index], " are extracted.", "\n")
    
      if(args$plurals == TRUE){
        top_words$word <- sapply(top_words$word, function(x){singularize(x)})
        top_words = aggregate(freq~word,top_words,sum)
      }
    
    top_words = top_words[order(top_words$freq, decreasing = TRUE), ]
    top_words$word = as.character(top_words$word)
    
    word_matrix[row,sapply(1:args$number, function(x){paste0(top_words$word[x])})] <- top_words$freq[1:args$number]
  }

  word_matrix <- as.matrix(word_matrix)
  word_matrix[is.na(word_matrix)] <- 0
  word_matrix <- word_matrix>0 *1  #transform matrix to binary matrix

cat("A word matrix with ", nrow(word_matrix), " rows and ", ncol(word_matrix), "columns is generated.", "\n")
  
write.table(word_matrix, args$output, sep = '\t')
