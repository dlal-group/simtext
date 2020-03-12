# similarity_app

 $ cd Dropbox/LAL_PROJECTS/RESEARCH_PORTAL

#T1: For each ID term get 20 PMIDs.

 $ chmod -x T1_pubmedsearch_by_keyword.R
 
 $ RScript T1_pubmedsearch_by_keyword.R -i "gene_testdata.txt" -o "gene_testdata_T1_result" -n 20 -k "15f2fa5c9d427fd88d53b5041002aeabd309"


#T2: For each PMID get the according abstract text.

 $ chmod -x T2_pubmedsearch_by_pmid.R
 
 $ RScript T2_pubmedsearch_by_pmid.R -i "gene_testdata_T1_result" -o "gene_testdata_T2_result"


#T3: Pubtator search of PMIDs. Generation of wordcount matrix

 $
 $


 #T4: 
 
 $ chmod -x T4_text_to_wordcountmatrix.R
 
 $ RScript T4_text_to_wordcountmatrix.R -i "gene_testdata_T2_result" -o "gene_testdata_T4_result" -n 200 


 #T5: Dimensionality reduction of matrix into coordinates of subjects in 2D.
 
 $
 
 $
