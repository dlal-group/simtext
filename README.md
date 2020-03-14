# similarity_app

# working directory should contain scripts, Input data table (with columns: "ID", "GROUPING")
 $ cd "path_working_directory"

# T1: Pubmed search by keyword. Save PMIDs. Here: for each ID term save 20 PMIDs.

 $ chmod -x T1_pubmedsearch_by_keyword.R
 
 $ RScript T1_pubmedsearch_by_keyword.R -i "INPUT.txt" -n 20 -k "15f2fa5c9d427fd88d53b5041002aeabd309"


# T2: For each PMID get the according abstract text.

 $ chmod -x T2_pubmedsearch_by_pmid.R
 
 $ RScript T2_pubmedsearch_by_pmid.R -i "T1_result"


# T3: Pubtator search of PMIDs. Generation of IDs/MESH terms matrix.

 $ chmod -x T3_pmids_to_pubtator_matrix.R
 
 $ RScript T3_pmids_to_pubtator_matrix.R -i "T2_result" -c Genes Diseases


# T4: Textmining of abstracts/text. Generation of wordcount matrix based on top words. Here: Top 200 words
 
 $ chmod -x T4_text_to_wordcountmatrix.R
 
 $ RScript T4_text_to_wordcountmatrix.R -i "T2_result" -n 200 


# T5: Dimensionality reduction of matrix (here of matrix of T3) into coordinates of subjects in 2D. Here: TSNE of matrix with perplexity value =1
 
 $ chmod -x T5_dimreduction_of_wordcountmatrix.R
 
 $ RScript T5_dimreduction_of_wordcountmatrix.R -i "T2_result" -m "T3_result" -p 1
