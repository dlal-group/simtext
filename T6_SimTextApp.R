#!/usr/bin/env Rscript
### SimText App ###

#Input: 
#1) A tab delimited table (--input) with at least two columns: one column named "ID" containing all objects and one or 
#   more columns starting with "GROUPING_" e.g."GROUPING_Disease". In this case the app will show Disease as a grouping variable.
#2) A matrix with rows = IDs (--matrix) and columns = words/terms. When a word/term is associated with an ID, the value is >0 
#   (if binary=1 or absolute count) and otherwise the value in the matrix is 0. The matrix is transformed into a binary matrix 
#   (based on >0) before analysis in the app.

#Packages
if (!require('shiny')) install.packages('shiny'); suppressPackageStartupMessages(library("shiny"))
if (!require('plotly')) install.packages('plotly'); suppressPackageStartupMessages(library("plotly"))
if (!require('DT')) install.packages('DT'); suppressPackageStartupMessages(library("DT"))
if (!require('shinycssloaders')) install.packages('shinycssloaders'); suppressPackageStartupMessages(library("shinycssloaders"))
if (!require('shinythemes')) install.packages('shinythemes'); suppressPackageStartupMessages(library("shinythemes"))
if (!require('tableHTML')) install.packages('tableHTML'); suppressPackageStartupMessages(library("tableHTML"))
if (!require('argparse')) install.packages('argparse');suppressPackageStartupMessages(library("argparse"))
if (!require('PubMedWordcloud')) install.packages('PubMedWordcloud'); suppressPackageStartupMessages(library("PubMedWordcloud"))
if (!require('ggplot2')) install.packages('ggplot2'); suppressPackageStartupMessages(library("ggplot2"))
if (!require('stringr')) install.packages('stringr'); suppressPackageStartupMessages(library("stringr"))
if (!require('tidyr')) install.packages('tidyr'); suppressPackageStartupMessages(library("tidyr"))
if (!require('magrittr')) install.packages('magrittr'); suppressPackageStartupMessages(library("magrittr"))
if (!require('plyr')) install.packages('plyr'); suppressPackageStartupMessages(library("plyr"))
if (!require('ggpubr')) install.packages('ggpubr'); suppressPackageStartupMessages(library("ggpubr")) 
if (!require('rafalib')) install.packages('rafalib'); suppressPackageStartupMessages(library("rafalib")) 
if (!require('RColorBrewer')) install.packages('RColorBrewer'); suppressPackageStartupMessages(library("RColorBrewer")) 
if (!require('dendextend')) install.packages('dendextend'); suppressPackageStartupMessages(library("dendextend")) 
if (!require('Rtsne')) install.packages('Rtsne'); suppressPackageStartupMessages(library("Rtsne")) 
if (!require('umap')) install.packages('umap'); suppressPackageStartupMessages(library("umap")) 

#command arguments
parser <- ArgumentParser()
parser$add_argument("-i", "--input", 
                    help = "input file name. add path if file is not in working directory")
parser$add_argument("-m", "--matrix", default= NULL,
                    help = "matrix file name. add path if file is not in working directory")
parser$add_argument("-p", "--port", type="integer", default=NULL,
                    help="Specify port, otherwise randomly select")
args <- parser$parse_args()

# Set port
if(!is.null(args$port)){
  options(shiny.port = args$port)
}

#load data
data = read.delim(args$input, stringsAsFactors=FALSE)
index_grouping = grep("GROUPING_", names(data))
names(data)[index_grouping] = sub(".*_", "",names(data)[index_grouping])

matrix = read.delim(args$matrix, stringsAsFactors=FALSE)
matrix.binary =  (as.matrix(matrix)>0) *1 #transform matrix to binary matrix
  
 ##### UI ######
ui <- shinyUI(fluidPage(
  navbarPage(theme = shinytheme("flatly"), id = "inTabset",selected = "panel1",
             title = "SimText",
             tabPanel("Home", value = "panel1",
             tabPanel("Results", value = "panel1",
      fluidRow(width=12, offset=0,
           column(width = 4,  style = "padding-right: 0px",
                  wellPanel(h5(strong("ID of interest")),
                            style = "background-color:white;
                            border-bottom: 2px solid #EEEEEE;
                            border-top-color: white;
                            border-right-color: white;
                            border-left-color: white;
                            box-shadow: 0px 0px 0px white;
                            padding:3px;
                            width: 100%"),
                  selectInput('ID', 'Select ID:', paste0(data$ID," (",seq(1,length(data$ID)),")"))),
           column(width = 3,  style = "padding-right: 0px",
                  wellPanel(h5(strong("Color settings")),
                            style = "background-color:white;
                            border-bottom: 2px solid #EEEEEE;
                            border-top-color: white;
                            border-right-color: white;
                            border-left-color: white;
                            box-shadow: 0px 0px 0px white;
                            padding:3px;
                            width: 100%"),
                  radioButtons('colour', 'Color by:', c("Grouping variable", "Individual word")), 
                  #conditionalPanel(condition = "input.colour == 'Individual word'",
                  selectInput("colour_select", "Select:",  choices=c(names(data)[index_grouping])))
           ),
    fluidRow(width = 12, offset = 0,
           column(width = 4, #style = "height:650px;",
                  wellPanel(textOutput("ID"),
                            style = "background-color: #333333;
                            color: white;
                            border-top-color: #333333;
                            border-left-color: #333333;
                            border-right-color: #333333;
                            box-shadow: 3px 3px 3px #d8d8d8;
                            margin-bottom: 0px;
                            padding:5px"), 
                  wellPanel(withSpinner(plotOutput("WordcloudPlot",height= "350px")),
                            downloadLink("downloadWordcloud", "Download"),
                            style = "background-color: #ffffff;
                            border-bottom-color: #333333;
                            border-left-color: #333333;
                            height: 400px;
                            border-right-color: #333333;
                            box-shadow: 3px 3px 3px #d8d8d8;
                            margin-top: 0px"),
                  wellPanel(textOutput("Table"),
                            style = "background-color: #333333;
                            color: white;
                            border-top-color: #333333;
                            border-left-color: #333333;
                            border-right-color: #333333;
                            box-shadow: 3px 3px 3px #d8d8d8;
                            margin-bottom: 0px;
                            padding:5px"),
                  wellPanel(withSpinner(DT::dataTableOutput("datatable", height= "210px")),
                            style = "background-color: #ffffff;
                            border-bottom-color: #333333;
                            border-left-color: #333333;
                            border-right-color: #333333;
                            height: 245px;
                            box-shadow: 3px 3px 3px #d8d8d8;
                            margin-top: 0px")
                  ), 
           column(width = 8, #style='padding:0px;',
                  wellPanel("T-SNE plot of wordmatrix",
                            style = "background-color: #333333;
                            color: white;
                            border-top-color: #333333;
                            border-left-color: #333333;
                            border-right-color: #333333;
                            box-shadow: 3px 3px 3px #d8d8d8;
                            margin-bottom: 0px;
                            padding:5px"), 
                  wellPanel( 
                     fluidRow(
                           column(width = 2,
                                  radioButtons('method', 'Method:',choices=c("t-SNE","UMAP"))),
                           column(width = 2,
                                  numericInput('perplexity', 'Perplexity:',value = 2, min=1, max=nrow(data)-1)),
                           column(width = 2,
                                  radioButtons('label', 'Labels:',choices=c("Index","IDs"))),
                           column(width = 2,
                                  numericInput('labelsize', 'Labelsize:',value = 12, min=1, max=30)),
                           column(width = 8, style='padding:0px;',
                                  withSpinner(plotlyOutput("TsnePlot",height=550))),
                           column(width = 4, style='padding:0px;',
                                  withSpinner(plotOutput("TsnePlot_legend",height=550))),
                           column(width=2, 
                                  downloadLink("downloadPlotdata",label = "Download data"))),
                            style = "background-color: white;
                            border-bottom-color: #333333;
                            border-left-color:  #333333;
                            border-right-color: #333333;
                            box-shadow: 3px 3px 3px #d8d8d8;
                            margin-top: 0px"
                            #height=575px
                       ))),
    fluidRow(column(width = 12,
                  wellPanel("Hierarchical clustering of wordmatrix",
                            style = "background-color: #333333;
                            color: white;
                            border-top-color: #333333;
                            border-left-color: #333333;
                            border-right-color: #333333;
                            box-shadow: 3px 3px 3px #d8d8d8;
                            margin-bottom: 0px;
                            padding:5px")
                  ,
                  wellPanel(
                    fluidRow(
                          column(width = 2,
                                 radioButtons('hcmethod', 'Method:',choices=c("ward.D2","average","complete","single"))),
                          column(width = 2,
                                 numericInput('labelsize_hc', 'Labelsize:', value = 8, min=1, max=30))
                          ),
                      fluidRow(
                          column(width = 9,
                                withSpinner(plotOutput("hclust"))),
                          column(width = 3, 
                                 withSpinner(plotOutput("hclust_legend")))
                          ),
                                style = "background-color: #ffffff;
                                border-bottom-color: #333333;
                                border-left-color: #333333;
                                border-right-color: #333333;
                                box-shadow: 3px 3px 3px #d8d8d8;
                                margin-top: 0px")
                  ,
                  verbatimTextOutput("test")
                ))
    )),
      
  tabPanel("About", value = "panel2", h3("work in progress"))
  
  )))
           
         
         

###### SERVER ###### 
server <- function(input, output, session) {

  ##### Global ##### 
  IDs = reactive(paste0(data$ID," (",seq(1,length(data$ID)),")"))
  index_ID = reactive({which(IDs() == input$ID)})

  ##### Wordcloud plot and download  ######
  
  output$ID <- renderText({
    paste("Wordcloud of",data$ID[index_ID()])
  })
  
  output$WordcloudPlot <- renderPlot({
    ID_matrix = matrix[index_ID(),]
    ID_matrix = data.frame(word= names(ID_matrix), freq= t(ID_matrix))
    colnames(ID_matrix) = c("word", "freq")
    ID_matrix = ID_matrix[ID_matrix$freq > 0,]
    ID_matrix <- ID_matrix[order(ID_matrix$freq,decreasing=F),]
    plotWordCloud(ID_matrix, max.words = 100, colors= brewer.pal(8,"Greys")[5:8])
  })
  
  output$downloadWordcloud <- downloadHandler(
    filename = function() {
      paste0(paste0("Wordcloudof",data$ID[index_ID()]),".pdf", sep="")
    },
    content = function(file) {
      ID_matrix = matrix[index_ID(),]
      ID_matrix = data.frame(word= names(ID_matrix), freq= t(ID_matrix))
      colnames(ID_matrix) = c("word", "freq")
      ID_matrix = ID_matrix[ID_matrix$freq > 0,]
      ID_matrix <- ID_matrix[order(ID_matrix$freq, decreasing=F),]
      pdf(file)
      plotWordCloud(ID_matrix, max.words = 100, colors= brewer.pal(8,"Greys")[5:8])
      dev.off()
    }
  )
  
  ##### Table #####
  output$Table  <-  renderText({
    paste("Most occuring words among IDs")
  })
  
  output$datatable <- DT::renderDataTable({
    
    colsum_data= data.frame(word=colnames(matrix.binary), freq=colSums(matrix.binary))
    colsum_data = colsum_data[order(colsum_data$freq, decreasing = T),]
    colnames(colsum_data) = c("Word", paste0("IDs (total n=", nrow(matrix),")"))

    DT::datatable(colsum_data,
                  extensions = c("Buttons"),
                  rownames = F,
                  fillContainer = T,
                  escape=FALSE,
                  options = list(dom = "t",
                                 scrollY = min(nrow(colsum_data),500),
                                 scrollX= TRUE,
                                 scroller = TRUE,
                                 pageLength = nrow(colsum_data),
                                 columnDefs = list(list(className = 'dt-center', targets = "_all"))))
  })
  
  #DT::formatStyle(columns=c(1), backgroundColor = "#F7080880")
  #DT::datatable(colsum_data) %>% 
  #                           formatStyle(columns=c(1), backgroundColor = "#F7080880")
  
  
  ##### Colour/Grouping #####
  
  outVar <- reactive({
    if(input$colour == "Grouping variable"){
      return(names(data)[index_grouping])
    } else {
      return(colnames(matrix))
    }
  })

  observe({ 
    updateSelectInput(session, "colour_select", choices = outVar())})
  
  colour_choice =  reactive({
    if(input$colour == "Grouping variable"){
      return(as.factor(data[,input$colour_select]))
  } else {
      colour_byword = matrix[[input$colour_select]]
      colour_byword = ifelse(colour_byword > 0,"Selected word associated with ID","Selected word not associated with ID")
      return(as.factor(colour_byword))
  }
    })

  color_palette = reactive({palette=c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", 
                                      "#E31A1C", "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A",
                                      "#00AFBB", "#E7B800", "#FC4E07", "#999999", "#E69F00", 
                                      "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00")
                            return( palette[1:length(levels(colour_choice()))] ) 
  })
  
  ##### Dimension reduction plot and download #####
 
   data.dimred = reactive({
    if (input$method == "t-SNE"){
      tsne_result <- Rtsne(matrix, perplexity = input$perplexity, check_duplicates=F)
      data["X_Coord"] = tsne_result$Y[,1]
      data["Y_Coord"] = tsne_result$Y[,2]
      return(data)
    } else if (input$method == "UMAP"){
      umap_result = umap(matrix)
      data["X_Coord"] = umap_result$layout[,1]
      data["Y_Coord"] = umap_result$layout[,2]
      return(data)
    }  
  })
  
  output$TsnePlot <- renderPlotly({
    
    if (input$label == "Index") {
        labeling = as.character(seq(1,nrow(data)))
    } else if (input$label == "IDs") {
        labeling= as.character(data$ID)
    }
    
    p = plot_ly(colors = color_palette()) %>%
      add_trace(type="scatter",
                mode = 'markers',
                x = data.dimred()$X_Coord[index_ID()],
                y = data.dimred()$Y_Coord[index_ID()],
                opacity=0.15,
                marker = list(
                  color = "grey",
                  size = 80)) %>%
      add_trace(x=data.dimred()$X_Coord, 
                y=data.dimred()$Y_Coord, 
                type="scatter", 
                mode="text",
                text= labeling,
                textfont = list(size= input$labelsize),
                color = factor(colour_choice())) %>%
      add_trace(x=data.dimred()$X_Coord, 
                y=data.dimred()$Y_Coord, 
                type="scatter", 
                mode="markers",
                opacity=0,
                text= paste0( "ID: ",data$ID, "\n",
                              "Index: ",seq(1,nrow(data)), "\n",
                              "Grouping: ", paste(data[,index_grouping])),
                hoverinfo = "text",
                color = factor(colour_choice())) %>% 
      layout(showlegend = FALSE,
             yaxis= list(title = "",
                         zeroline = FALSE,
                         linecolor = toRGB("black"),
                         linewidth = 1,
                         showticklabels = FALSE,
                         showgrid = FALSE),
             xaxis = list(title = "",
                          zeroline = FALSE,
                          linecolor = toRGB("black"),
                          linewidth = 1,
                          showticklabels = FALSE,
                          showgrid = FALSE),
             autosize = T) %>% 
      config(modeBarButtonsToRemove = c("zoomIn2d", "zoomOut2d", "hoverClosestGeo", "hoverClosestGl2d", "toImage",
                                        "hoverClosestCartesian", "lasso2d", "select2d", "resetScale2d",
                                        "hoverCompareCartesian", "hoverClosestPie", "toggleSpikelines"), displaylogo = FALSE) %>% 
      style(hoverinfo = "none", traces = c(1,2))
    
    p
  })
  
  #legend of plotly plot by ggplot
  
  output$TsnePlot_legend <- renderPlot({
    p = ggplot(data, aes(x=1, y=1)) +
        geom_text(aes(label=seq(1,nrow(data)), colour=factor(colour_choice())), 
                size=3.5, fontface = "bold") +
        theme_classic()+
        scale_color_manual(values = color_palette())+
        theme(legend.title = element_blank())+
        theme(legend.position = "right")+
        theme(legend.text=element_text(size=9))
    leg <- get_legend(p)
    as_ggplot(leg)
  })
  
  output$downloadPlotdata <- downloadHandler(
    filename = function() {
      paste0(input$method,"_coordinates.csv")
    },
    content = function(file) {
      write.csv(data.dimred(), file, row.names = F)
    }
  )

  ##### Hierarchical clustering #######  
  
  output$hclust <- renderPlot({
    set.seed(42)
    clustering=hclust(dist(matrix.binary), method=input$hcmethod)
    par(oma=c(3,3,3,3))
    palette(color_palette())
    par(mar = rep(0, 4))
    myplclust(clustering, 
              labels=paste(data$ID), 
              lab.col=as.fumeric(as.character(colour_choice()), levels = sort(unique(as.character(colour_choice())))), 
              cex=as.numeric(input$labelsize_hc/10),
              main="",
              yaxt="n",
              ylab= "")
    })
  
    #legend
    output$hclust_legend <- renderPlot({
      p = ggplot(data, aes(x=1, y=1)) +
        geom_text(aes(label=seq(1,nrow(data)), colour=factor(colour_choice())), fontface = "bold") +
        theme_classic()+
        scale_color_manual(values = color_palette())+
        theme(legend.title = element_blank())+
        theme(legend.position = "right")+
        theme(legend.text=element_text(size=9))
      leg <- get_legend(p)
      as_ggplot(leg)
    })
    
    
  ##### Test field for development ######
  #output$test <- renderPrint({
  #print(input$plot1_brush)
    #print(colour_choice())
    #print(class(colour_choice()))
    #print(color_palette())
   # print(session)
  #})
  
    }

###### APP ######
shinyApp(ui, server)
