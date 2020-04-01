# Similarity app

- working directory should contain scripts and input data table 
- input data requires columns: "ID", "GROUPING"
- input data can have additional columns: 

    a) additional text columns, column names should contain "TEXT". eg."TEXT_1", "TEXT_2"
    
    b) manually curated PMID columns, column names should contain "PMID. eg."PMID_1", "PMID_2" 

# See Tutorial_usecases.doc for more details.
# Quick overview of tools:
 T1: Pubmed search by keyword. Save PMIDs or abstracts.

 T2: For each PMID get the according abstract text.

 T3: Pubtator search for specific scientific words in abstracts. Generation of matrix with IDs/scientific terms. As input PMIDs are used.

 T4: Textmining of abstracts/text. Generation of word co-occurence matrix based on top words. 

 T5: Dimensionality reduction (t-SNE) of word matrix into co-ordinates of subjects (column "ID") in 2D.

 Still coming: shiny app that visualizes results of tools
