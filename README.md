# SimText

## Brief overview of tools:

 - T1_pubmed_by_queries: Pubmed searches by queries. For each query save PMIDs or abstracts in additional columns.

 - T2_abstracts_by_pmids: For all PMIDs in each row of a table save the according abstracts in additional columns.

 - T3_text_to_wordmatrix: Textmining of abstracts/text of each row. Extraction of most frequent words. Generation of binary matrix (rows= entities, columns= words).
 
 - T4_pmids_to_pubtator_matrix: PubTator search for specific scientific words from PMIDs. Generation of binary matrix (rows= entities, columns= words). 

 - T5_simtext_app: Shiny app with word clouds, dimensionality reduction plot, dendrogram of hierarchical clustering and table words and their frequency among the entities.

## T1_pubmed_by_queries

Input:
Tab-delimited table with entities in a column called “ID_<name>”, e.g. “ID_genes” if entities are genes. The entities are successively used as search query in PubMed.
Settings:
-	Save abstracts or PMIDs
-	Number of abstracts or PMIDs that should be retrieved per entity
-	NCBI API key if applicable
-	Name of the output file
Output: 
Input table with additional columns containing PMIDs or abstracts from PubMed.

## T2_abstracts_by_pmids

Input:
Tab-delimited table with entities in a column called “ID_<name>” and columns containing PMIDs. The names of the PMID columns should start with “PMID”, e.g. “PMID_1”, “PMID_2” etc.
Settings:
-	Name of the output file
Output: 
Input table with additional columns containing abstracts corresponding to the PMIDs from PubMed.

## T3_text_to_wordmatrix

The tool extracts the most frequent words per entity (per row). Text of columns starting with "ABSTRACT" or "TEXT" are considered. The most frequent words are used to generate a word matrix with rows = entities and columns = extracted words. The resulting matrix is binary with 0= word not frequently occurring in abstracts/text of entity and 1= word frequently present in abstracts/text of entity.

Input: Output of tool 1 or tool 2, or tab-delimited table with entities in column called “ID_<name>”, e.g. “ID_genes” and text in columns starting with "ABSTRACT" or "TEXT".
Settings:
-	Number most frequent words that should be extracted (default: top 50 words)
-	All characters translated to lower case (default)
-	A set of English stop words (e.g., 'the' or 'not') are removed (default)
-	Remove any numbers in text 
-	Apply Porter's stemming algorithm: collapsing words to a common root to aid comparison of vocabulary
-	Transform words in plural to their singular form (default)
-	Name of the output file
Output: 
Binary matrix with rows = entities and columns = extracted words.

## T4_pmids_to_pubtator_matrix

This tool takes all PMIDs per entity (per row) and uses PubTator to extract all "Genes", "Diseases", "Mutations", "Chemicals" and "Species" terms of the corresponding abstracts. The user can choose if terms of all, some or one of the aforementioned categories should be extracted. All extracted terms are used to generate a matrix with rows = entities and columns = extracted words. The resulting matrix is binary with 0= word not present in abstracts of entity and 1= word present in abstracts of entity.

Input: 
Output of tool 2 or tab-delimited table with entities in column called “ID_<name>” and columns containing PMIDs. The names of the PMID columns should start with “PMID”, e.g. “PMID_1”, “PMID_2” etc.
Settings:
-	Name of the output file
-	PubTator categories that should be considered (options: Genes, Diseases, Mutations, Chemicals, Species)
Output: 
Binary matrix with rows = entities and columns = extracted words

## T5_simtext_app

Input:
Input 1: Tab-delimited table with entities in column called “ID_<name>”, e.g. “ID_gene” if entities are genes and column(s) with grouping factor, e.g. column containing information to which diseases the genes are associated with. The names of grouping columns should start with “GROUPING_”. If the column is called “GROUPING_disease”, the app will show “disease” as a grouping variable.
Input 2: Binary word matrix (or output of tool 3 or tool 4).
Settings: 
The user can choose different settings interactively within the app.
Output: 
Shiny app with word clouds, dimensionality reduction plot, dendrogram of hierarchical clustering and table with extracted words and their frequency among the entities.
