# SimText

A text mining framework for interactive analysis and visualization of similarities among biomedical entities.

## Brief overview of tools:

 - pubmed_by_queries: 

 For each search query, PMIDs or abstracts from PubMed are saved.

 - abstracts_by_pmids: 

 For all PMIDs in each row of a table the according abstracts are saved in additional columns.

 - text_to_wordmatrix: 

 The most frequent words of text from each row are extracted and united in one large binary matrix. 
 
 - pmids_to_pubtator_matrix: 

 For PMIDs of each row, scientific words are extracted using PubTator annotations and subsequently united in one large binary matrix. 

 - simtext_app: 

 Shiny app with word clouds, dimension reduction plot, dendrogram of hierarchical clustering and table with words and their frequency among the search queries.

## Set up user credentials on Galaxy

To enable users to set their credentials (NCBI API Key) for this tool,
make sure the file `config/user_preferences_extra_conf.yml` has the following section:

```
preferences:
    ncbi_account:
        description: NCBI account information
        inputs:
            - name: apikey
              label: NCBI API Key (available from "API Key Management" at https://www.ncbi.nlm.nih.gov/account/settings/)
              type: text
              required: False

```
