# SimText

## Brief overview of tools:

 - T1_pubmed_by_queries: For each search query, PMIDs or abstracts from PubMed are saved.

 - T2_abstracts_by_pmids: For all PMIDs in each row of a table the according abstracts are saved in additional columns.

 - T3_text_to_wordmatrix: The most frequent words of text from each row are extracted and united in one large binary matrix. 
 
 - T4_pmids_to_pubtator_matrix: For PMIDs of each row, scientific words are extracted using PubTator annotations and subsequently united in one large binary matrix. 

 - T5_simtext_app: Shiny app with word clouds, dimensionality reduction plot, dendrogram of hierarchical clustering and table with words and their frequency among the search queries.

## Requirements

 - R (version X.X)

## T1_pubmed_by_queries

This tool uses a set of search queries to download a defined number of abstracts or PMIDs for search query from PubMed. PubMed's search rules and syntax apply.

Input:

Tab-delimited table with search queries in a column starting with "ID_", e.g. "ID_gene" if search queries are genes. 

Usage:
```
$ RScript T1_pubmed_by_queries.R [-h] [-i INPUT] [-o OUTPUT] [-n NUMBER] [-a] [-k KEY]
```

Optional arguments: 
```
 -h, --help                  show help message
 -i INPUT, --input INPUT     input file name. add path if file is not in working directory
 -o OUTPUT, --output OUTPUT  output file name [default "T1_output"]
 -n NUMBER, --number NUMBER  number of PMIDs or abstracts to save per ID [default "5"]
 -a, --abstract              if abstracts instead of PMIDs should be retrieved use --abstracts 
 -k KEY, --key KEY           if NCBI API key is available, add it to speed up the download of PubMed data
```

Output: 

Input table with additional columns with PMIDs or abstracts (--abstracts) from PubMed.

## T2_abstracts_by_pmids

For PMIDs of each row, this tool retrieves the according abstracts and saves them in additional columns.

Input:

Tab-delimited table with columns containing PMIDs. The names of the PMID columns should start with “PMID”, e.g. “PMID_1”, “PMID_2” etc.

Usage:
```
$ RScript T2_abstracts_by_pmid.R [-h] [-i INPUT] [-o OUTPUT]
```

Optional arguments: 
```
 -h, --help                    show help message
 -i INPUT, --input INPUT    input file name. add path if file is not in working directory
 -o OUTPUT, --output OUTPUT output file name [default "T2_output"]
```

Output: 

Input table with additional columns containing abstracts. 

## T3_text_to_wordmatrix

Per row, the tool extracts the most frequent words from text in columns starting with "ABSTRACT" or "TEXT. The extracted words of each row are united in one large binary matrix, with 0= word not frequently occurring in text of that row and 1= word frequently present in text of that row.

Input: 

Output of T1_pubmed_by_queries or T2_abstracts_by_pmids, or tab-delimited table with text in columns starting with "ABSTRACT" or "TEXT".

Usage:
```
$ RScript T3_text_to_wordmatrix.R [-h] [-i INPUT] [-o OUTPUT] [-n NUMBER] [-r] [-l] [-w] [-s] [-p]
```

Optional arguments: 
```
 -h, --help                    show help message
 -i INPUT, --input INPUT       input file name. add path if file is not in working directory
 -o OUTPUT, --output OUTPUT    output file name. [default "T3_output"]
 -n NUMBER, --number NUMBER    number of most frequent words that should be extracted per row [default "50"]
 -r, --remove_num              remove any numbers in text
 -l, --lower_case              by default all characters are translated to lower case. otherwise use -l
 -w, --remove_stopwords        by default a set of english stopwords (e.g., 'the' or 'not') are removed. otherwise use -w
 -s, --stemDoc                 apply Porter's stemming algorithm: collapsing words to a common root to aid comparison of vocabulary
 -p, --plurals                 by default words in plural and singular are merged to the singular form. otherwise use -p
```

Output: 

Binary matrix in that each column represents one of the extracted words.

## T4_pmids_to_pubtator_matrix

The tool uses all PMIDs per row and extracts "Gene", "Disease", "Mutation", "Chemical" and "Species" terms of the corresponding abstracts, using PubTator annotations. The user can choose from which categories terms should be extracted. The extracted terms are united in one large binary matrix, with 0= term not present in abstracts of that row and 1= term present in abstracts of that row.

Input: 

Output of T2_abstracts_by_pmids or tab-delimited table with columns containing PMIDs. The names of the PMID columns should start with "PMID", e.g. "PMID_1", "PMID_2" etc.

Usage:
```
$ RScript T4_pmids_to_pubtator_matrix.R [-h] [-i INPUT] [-o OUTPUT] [-c {Gene,Disease,Mutation,Chemical,Species} [{Gene,Disease,Mutation,Chemical,Species} ...]]
```
 
Optional arguments:
```
 -h, --help                    show help message
 -i INPUT, --input INPUT       input file name. add path if file is not in workind directory
 -o OUTPUT, --output OUTPUT    output file name. [default "T4_output"]
 -c [...], --categories [...]  PubTator categories that should be considered [default "('Gene', 'Disease', 'Mutation','Chemical')"]
```

Output: 

Binary matrix in that each column represents one of the extracted terms.

## T5_simtext_app

The tool enables the exploration of data generated by text_to_wordmatrix or pmids_to_pubtator_matrix in a locally run ShinyApp. Features are word clouds for each initial search query, dimension reduction and hierarchical clustering of the binary matrix, and a table with words and their frequency among the search queries. 

Input:

1)	Input 1: 
Tab-delimited table with 
- column with search queries starting with "ID_", e.g. "ID_gene" if initial search queries were genes 
- column(s) with grouping factor(s) to compare pre-existing categories of the initial search queries with the grouping based on text. The column names should start with "GROUPING_". If the column name is "GROUPING_disorder", "disorder" will be shown as a grouping variable in the app.
2)	Input 2: 
Output of text_to_wordmatrix or pmids_to_pubtator_matrix, or binary matrix.

Usage:
```
$ RScript T5_simtext_app.R [-h] [-i INPUT] [-m MATRIX] [-p PORT] 
```

Optional arguments:
```
 -h,        --help             show help message
 -i INPUT,  --input INPUT      input file name. add path if file is not in working directory
 -m MATRIX, --matrix MATRIX    matrix file name. add path if file is not in working directory
 -p PORT,   --port PORT        specify port, otherwise randomly selected
```

Output: 

SimText app
