#!/usr/bin/env Rscript
#TOOL5:dimreduction_of_wordcountmatrix
#
#the tool performs a dimension reduction (T-SNE) of the wordcount matrix to infer similarity among the 
#ID subjects based on the top words in their text/abstracts.
#It saves the coordinates in a dataframe together with ID and GROUPING variables as well as a plot of the ID subjects in DIM1 and DIM2.
#
# packages: r-argparse-2.0.1, r-rtsne-0.15,  r-ggplot2-3.1.1, r-ggrepel-0.8.2
#
# -h, --help                    show this help message and exit
# -i INPUT, --input INPUT       input fie name of dataframe with ID column and GROUPING column(s) (if grouping of ID subjects is wished). add path if file is not in working directory
# -m MATRIX, --matrix MATRIX    input file name of wordcont matrix (rows= ID, columns=words). add path if file is not in working directory.
# -o OUTPUT, --output OUTPUT    output file name of dataframe with ID, GROUPING and DIM1, DIM2 column. [default "T5_result"]
# -p PLOT, --plot PLOT          output file name of plot [default "T5_result_plot"]
# -n {1:50}, --number {1:50}    Perplexity value for T-SNE [default "2"]

if (!require('argparse')) install.packages('argparse'); suppressPackageStartupMessages(library("argparse"))
if (!require('Rtsne')) install.packages('Rtsne'); library('Rtsne')
if (!require('ggplot2')) install.packages('ggplot2'); library('ggplot2')
if (!require('ggrepel')) install.packages('ggrepel'); library('ggrepel')


parser <- ArgumentParser()
parser$add_argument("-i", "--input", 
                    help = "input fie name of dataframe with ID (and GROUPING column(s)). add path if file is not in working directory")
parser$add_argument("-m", "--matrix", 
                    help = "input file name of wordcont matrix (rows= ID, columns=words). add path if file is not in working directory.")
parser$add_argument("-o", "--output", default="T5_result",
                    help = "output file name. [default \"%(default)s\"]")
parser$add_argument("-p", "--perplexity", type="integer", default=2, choices=seq(0, 50, 0.1), metavar="{0..50}",
                    help="Numeric perplexity value for T-SNE Perplexity parameter (should not be bigger than 3 * perplexity < nrow(X) - 1) [default \"%(default)s\"]")
parser$add_argument("-g", "--plot", default="T5_result_plot",
                    help= "output file name of plot [default \"%(default)s\"]")


args <- parser$parse_args()

data <- read.delim(args$input, stringsAsFactors=FALSE, header = TRUE, sep='\t')
wordcount_matrix <- read.delim(args$matrix, stringsAsFactors=FALSE, header = TRUE, sep='\t')

data= data[,-grep(c("ABSTRACT|TEXT|PMID"), names(data))] #only keep columns: ID,GROUPING

wordcount_matrix = as.matrix(wordcount_matrix)
wordcount_matrix = (wordcount_matrix>0) *1 #transform matrix to binary matrix
tsne_result <- Rtsne(wordcount_matrix, perplexity = args$perplexity, check_duplicates=F)

data["TSNE_X"] = tsne_result$Y[,1]
data["TSNE_Y"] = tsne_result$Y[,2]

  
tsne_plot = ggplot(data, aes(x=TSNE_X, y=TSNE_Y)) +
  geom_text_repel(aes(label=data$ID, colour = factor(data[,grep(c("GROUPING"), names(data))[1]])),
                  size=5,
                  box.padding = 0,
                  fontface = "bold") +
  theme_classic()+
  scale_colour_brewer(palette="Paired")+
  theme(legend.title = element_blank())

ggsave(paste0(args$output, ".pdf"),plot=tsne_plot, width = 9, height = 6)

write.table(data, args$output, sep = '\t')




