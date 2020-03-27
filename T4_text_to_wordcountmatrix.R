#!/usr/bin/env Rscript
#TOOL4:text_to_wordcountmatrix
#
#the tool performs textmining of all text per ID and generates a word matrix with the top used words per ID.
#all columns starting with "ABSTRACT" or "TEXT" are used for textmining.
#
#packages: r-argparse-2.0.1, r-textclean-0.9.3, r-snowballc-0.6.0,  r-pubmedwordcloud-0.3.3, ("SemNetCleaner" not found in anaconda cloud)
#
# usage: T4_text_to_wordcountmatrix.R [-h] [-i INPUT] [-o OUTPUT]
# 
# optional arguments:
# -h, --help                    show this help message and exit
# -i INPUT, --input INPUT       input fie name. add path if file is not in working directory
# -o OUTPUT, --output OUTPUT    output file name. [default "T4_result"]
# -n {1:500}, --number {1:500}  Number of mostfrequent words used per ID in wordcount matrix. [default "50"]
# -r, --remove_num              Remove any numbers in text.
# -l, --lower_case              By default all characters are translated to lower case. Use -l if this should not be done.
# -w, --remove_stopwords        By default a set of English stopwords (e.g., 'the' or 'not') are removed. Use -s if unwanted.
# -s, --stemDoc                 Apply Porter's stemming algorithm: collapsing words to a common root to aid comparison of vocabulary
# -p, --plurals                 By default words in plural and singular are merged to the singular form. Use -p if unwanted


if (!require('argparse')) install.packages('argparse'); suppressPackageStartupMessages(library("argparse"))
if (!require("PubMedWordcloud")) install.packages("PubMedWordcloud"); library("PubMedWordcloud") 
if (!require('SnowballC')) install.packages('SnowballC'); suppressPackageStartupMessages(library("SnowballC"))
if (!require('textclean')) install.packages('textclean'); suppressPackageStartupMessages(library("textclean"))
if (!require('SemNetCleaner')) install.packages('SemNetCleaner'); suppressPackageStartupMessages(library("SemNetCleaner"))


parser <- ArgumentParser()
parser$add_argument("-i", "--input", 
                    help = "input fie name. add path if file is not in workind directory")
parser$add_argument("-o", "--output", default="T4_result",
                    help = "output file name. [default \"%(default)s\"]")
parser$add_argument("-n", "--number", type="integer", default=50, choices=seq(1, 500), metavar="{0..500}",
                    help="Number of mostfrequent words used per ID in wordcount matrix [default \"%(default)s\"]")
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
  
text_cols_index <- grep(c("ABSTRACT|TEXT"), names(data))
                          
wordcount_matrix = data.frame()

for(row in 1:nrow(data)){
    top_words = cleanAbstracts(abstracts= data[row,text_cols_index], 
                               rmNum = args$remove_num, 
                               tolw= args$lower_case,
                               rmWords= args$remove_stopwords,
                               #yrWords= remove_words, 
                               stemDoc= args$stemDoc)
    
    top_words$word <- as.character(top_words$word)
    
    cat("Top words for ", data$ID[row], " are extracted.", "\n")
    
      if(args$plurals == TRUE){
        top_words$word <- sapply(top_words$word, function(x){singularize(x)})
        top_words = aggregate(freq~word,top_words,sum)
      }
    
    top_words = top_words[order(top_words$freq, decreasing = TRUE), ]
    top_words$word = as.character(top_words$word)
    
    wordcount_matrix[row,sapply(1:args$number, function(x){paste0(top_words$word[x])})] <- top_words$freq[1:args$number]
  }

  wordcount_matrix <- as.matrix(wordcount_matrix)
  wordcount_matrix[is.na(wordcount_matrix)] <- 0
  

cat("A wordcount matrix with ", nrow(wordcount_matrix), " rows and ", ncol(wordcount_matrix), "columns is generated.", "\n")
  
write.table(wordcount_matrix, args$output, sep = '\t')
