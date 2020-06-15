# SimText

## Brief overview of tools:

 - T1_pubmed_by_queries: Pubmed searches by queries. For each query save PMIDs or abstracts in additional columns.

 - T2_abstracts_by_pmids: For all PMIDs in each row of a table save the according abstracts in additional columns.

 - T3_text_to_wordmatrix: Textmining of abstracts/text of each row. Extraction of most frequent words. Generation of binary matrix (rows= entities, columns= words).
 
 - T4_pmids_to_pubtator_matrix: PubTator search for specific scientific words from PMIDs. Generation of binary matrix (rows= entities, columns= words). 

 - T5_simtext_app: Shiny app with word clouds, dimensionality reduction plot, dendrogram of hierarchical clustering and table with words and their frequency among the entities.

## Requirements

 - R (version X.X)

## T1_pubmed_by_queries

This tool uses a set of entities as queries to download a defined number of abstracts or PMIDs from PubMed.

Input:

Tab-delimited table with entities in a column starting with "ID_", e.g. "ID_gene" if entities are genes. The entities are successively used as search query in PubMed.

Usage:
```
$ T1_pubmed_by_queries.R [-h] [-i INPUT] [-o OUTPUT] [-n NUMBER] [-a] [-k KEY]
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

This tool retrieves for all PMIDs in each row of a table the according abstracts and saves them in additional columns.

Input:

Tab-delimited table with columns containing PMIDs. The names of the PMID columns should start with “PMID”, e.g. “PMID_1”, “PMID_2” etc.

Usage:
```
$ T2_abstracts_by_pmid.R [-h] [-i INPUT] [-o OUTPUT]
```

Optional arguments: 
```
 -h, --help                    show help message
 -i INPUT, --input INPUT    input file name. add path if file is not in working directory
 -o OUTPUT, --output OUTPUT output file name [default "T2_output"]
```

Output: 

Input table with additional columns containing abstracts corresponding to the PMIDs from PubMed.

## T3_text_to_wordmatrix

The tool extracts the most frequent words per entity (per row). Text of columns starting with "ABSTRACT" or "TEXT" are considered. The most frequent words are used to generate a binary matrix with rows = entities and columns = extracted words, with 0= word not frequently occurring in abstracts/text of entity and 1= word frequently present in abstracts/text of entity.

Input: 

Output of T1_pubmed_by_queries or T2_abstracts_by_pmids, or tab-delimited table with text in columns starting with "ABSTRACT" or "TEXT".

Usage:
```
$ T3_text_to_wordmatrix.R [-h] [-i INPUT] [-o OUTPUT] [-n NUMBER] [-r] [-l] [-w] [-s] [-p]
```

Optional arguments: 
```
 -h, --help                    show help message
 -i INPUT, --input INPUT       input file name. add path if file is not in working directory
 -o OUTPUT, --output OUTPUT    output file name. [default "T3_output"]
 -n NUMBER, --number NUMBER    number of most frequent words that should be extracted [default "50"]
 -r, --remove_num              remove any numbers in text
 -l, --lower_case              by default all characters are translated to lower case. otherwise use -l
 -w, --remove_stopwords        by default a set of english stopwords (e.g., 'the' or 'not') are removed. otherwise use -w
 -s, --stemDoc                 apply Porter's stemming algorithm: collapsing words to a common root to aid comparison of vocabulary
 -p, --plurals                 by default words in plural and singular are merged to the singular form. otherwise use -p
```

Output: 

Binary matrix with rows = entities and columns = extracted words.

## T4_pmids_to_pubtator_matrix

The tool takes all PMIDs per entity (per row) and uses PubTator to extract all "Genes", "Diseases", "Mutations", "Chemicals" and "Species" terms of the corresponding abstracts. The user can choose if terms of all, some or one of the aforementioned categories should be extracted. All extracted terms are used to generate a matrix with rows = entities and columns = extracted words. The resulting matrix is binary with 0= word not present in abstracts of entity and 1= word present in abstracts of entity.

Input: 

Output of T2_abstracts_by_pmids or tab-delimited table with entities in column starting with "ID_" and columns containing PMIDs. The names of the PMID columns should start with "PMID", e.g. "PMID_1", "PMID_2" etc.

Usage:
```
$ T4_pmids_to_pubtator_matrix.R [-h] [-i INPUT] [-o OUTPUT] [-c {Genes,Diseases,Mutations,Chemicals,Species} [{Genes,Diseases,Mutations,Chemicals,Species} ...]]
```
 
Optional arguments:
```
 -h, --help                    show help message
 -i INPUT, --input INPUT       input file name. add path if file is not in workind directory
 -o OUTPUT, --output OUTPUT    output file name. [default "T4_output"]
 -c [...], --categories [...]  PubTator categories that should be considered [default "('Genes', 'Diseases', 'Mutations','Chemicals')"]
```

Output: 

Binary matrix with rows = entities and columns = extracted words.

## T5_simtext_app

Input:

- Input 1: Tab-delimited table with entities in column starting with "ID_", e.g. "ID_gene" if entities are genes and column(s) with grouping factor, e.g. column containing information with which disorders the genes are associated with. The names of grouping columns should start with "GROUPING_". If the column is called "GROUPING_disorder", the app will show "disorder" as a grouping variable.
- Input 2: Binary word matrix (or output of T3_text_to_wordmatrix or T4_pmids_to_pubtator_matrix).

Usage:
```
$ T5_simtext_app.R [-h] [-i INPUT] [-m MATRIX] [-p PORT] 
```

Optional arguments:
```
 -h,        --help             show help message
 -i INPUT,  --input INPUT      input file name. add path if file is not in working directory
 -m MATRIX, --matrix MATRIX    matrix file name. add path if file is not in working directory
 -p PORT,   --port PORT        specify port, otherwise randomly selected
```

Output: 

Shiny app with word clouds of entities, dimensionality reduction plot, dendrogram of hierarchical clustering and table with extracted words and their frequency among the entities.
