#Carregar os Pacotes
library(shiny)
library(ggplot2)
library(DT)
library(dplyr) 
library(scales)

# Carregar a base de dados
data <- readxl::read_excel("Base Dataset.xlsx", sheet = "Dados_-_Desafio_-_GAUDIUM")
data
data <- na.omit(data)  # Remove todas as linhas com pelo menos um valor nulo
data

# Corrigir a variável TIPO
data$Tipo <- sub("^Pó.*", "Pós-Pago", data$Tipo, ignore.case = TRUE)
data$Tipo <- sub("^Pr.*", "Pré-Pago", data$Tipo, ignore.case = TRUE)

# Verificar os resultados
table(data$Tipo)

# Corrigir a variável SEXO
data$Sexo <- sub("^M.*", "Masculino", data$Sexo, ignore.case = TRUE)
data$Sexo <- sub("^F.*", "Feminino", data$Sexo, ignore.case = TRUE)

# Verificar os resultados
table(data$Sexo)

# Corrigir a variável OPINIÃO
data$Opinião <- sub("^Con.*", "Confiável", data$Opinião, ignore.case = TRUE)
data$Opinião <- sub("^Exce.*", "Excelente", data$Opinião, ignore.case = TRUE)
data$Opinião <- sub("^Me.*", "Mediana", data$Opinião, ignore.case = TRUE)
data$Opinião <- sub("^So.*", "Sofrível", data$Opinião, ignore.case = TRUE)
data$Opinião <- sub("^Te.*", "Terrível", data$Opinião, ignore.case = TRUE)


# Verificar os resultados
table(data$Opinião)

# Corrigir a variável MODELO
data$Modelo <- sub("^Eri.*", "Ericsson", data$Modelo, ignore.case = TRUE)
data$Modelo <- sub("^Gr.*", "Gradiente", data$Modelo, ignore.case = TRUE)
data$Modelo <- sub("^Mo.*", "Motorola", data$Modelo, ignore.case = TRUE)
data$Modelo <- sub("^Sa.*", "Samsung", data$Modelo, ignore.case = TRUE)
data$Modelo <- sub("^Si.*", "Siemens", data$Modelo, ignore.case = TRUE)


# Verificar os resultados
table(data$Modelo)

# Corrigir a variável OUTRA
data$Outra <- sub("^Cu.*", "Cumbuca", data$Outra, ignore.case = TRUE)
data$Outra <- sub("^Es.*", "Escuridão", data$Outra, ignore.case = TRUE)
data$Outra <- sub("^Fe.*", "Ferrocom", data$Outra, ignore.case = TRUE)
data$Outra <- sub("^Mo.*", "Mortinho", data$Outra, ignore.case = TRUE)
data$Outra <- sub("^Ne.*", "Nenhuma", data$Outra, ignore.case = TRUE)


# Verificar os resultados
table(data$Outra)

# Corrigir a variável RAZÃO
data$Razão <- sub("^Ma.*", "Maior cobertura", data$Razão, ignore.case = TRUE)
data$Razão <- sub("^Qu.*", "Qualidade do sinal", data$Razão, ignore.case = TRUE)
data$Razão <- sub("^Ta.*", "Tarifa menor", data$Razão, ignore.case = TRUE)


# Verificar os resultados
table(data$Razão)

# Função para formatar valores para moeda 
format_real <- function(x) {
  scales::dollar(x, prefix = "R$ ", big.mark = ".", decimal.mark = ",")
}

# UI do Shiny
ui <- fluidPage(
  titlePanel("Análise de Dados - Desafio GAUDIUM"),
  sidebarLayout(
    sidebarPanel(
      selectInput("x_var", "Escolha a variável do eixo X:", 
                  choices = names(data), 
                  selected = "Renda"),
      selectInput("y_var", "Escolha a variável do eixo Y:", 
                  choices = names(data), 
                  selected = "Gasto"),
      selectInput("color_var", "Escolha a variável de cor (opcional):", 
                  choices = c("Nenhuma", names(data)), 
                  selected = "Nenhuma"),
      sliderInput("gasto_range", "Filtrar por gasto mensal:", 
                  min = min(data$Gasto, na.rm = TRUE), 
                  max = max(data$Gasto, na.rm = TRUE), 
                  value = c(min(data$Gasto, na.rm = TRUE), max(data$Gasto, na.rm = TRUE)),
                  step = 1,
                  pre = "R$ ",
                  animate = FALSE),
      tags$script(HTML("
                $(document).ready(function() {
                    let slider = document.querySelector('.irs-grid');
                    if (slider) {
                        let min = $('.irs-grid-text').first();
                        let max = $('.irs-grid-text').last();
                        let mid = $('.irs-grid-text').eq(Math.floor($('.irs-grid-text').length / 2));
                        $('.irs-grid-text').not(min).not(mid).not(max).hide();
                    }
                });
            "))
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Gráficos", plotOutput("scatterPlot")),
        tabPanel("Resumo Estatístico", DTOutput("summaryTable")),
        tabPanel("Distribuição", plotOutput("distPlot"))
      )
    )
  )
)

# Server do Shiny
server <- function(input, output) {
  # Filtrar dados com base no intervalo selecionado
  filtered_data <- reactive({
    data[data$Gasto >= input$gasto_range[1] & data$Gasto <= input$gasto_range[2], ]
  })
  
  # Gráfico de dispersão
  output$scatterPlot <- renderPlot({
    ggplot(filtered_data(), aes_string(
      x = input$x_var, 
      y = input$y_var, 
      color = if (input$color_var == "Nenhuma") NULL else input$color_var
    )) +
      geom_point(size = 3, alpha = 0.7) +
      theme_minimal() +
      labs(title = "Gráfico de Dispersão", x = input$x_var, y = input$y_var)
  })
  
  # Tabela resumida com a nova estrutura
  output$summaryTable <- renderDT({
    # Resumo estatístico com 5 métricas para Gasto e Renda
    summary <- data.frame(
      Métrica = c("Gasto", "Renda"),
      Mín = c(min(filtered_data()$Gasto, na.rm = TRUE),
              min(filtered_data()$Renda, na.rm = TRUE)),
      Máx = c(max(filtered_data()$Gasto, na.rm = TRUE),
              max(filtered_data()$Renda, na.rm = TRUE)),
      Média = c(mean(filtered_data()$Gasto, na.rm = TRUE),
                mean(filtered_data()$Renda, na.rm = TRUE)),
      Soma = c(sum(filtered_data()$Gasto, na.rm = TRUE),
               sum(filtered_data()$Renda, na.rm = TRUE)),
      Variância = c(var(filtered_data()$Gasto, na.rm = TRUE),
                    var(filtered_data()$Renda, na.rm = TRUE))
    )
    
    # Formatar as colunas de moeda (apenas para Gasto e Renda)
    summary <- summary %>%
      mutate(
        Mín = ifelse(Métrica %in% c("Gasto", "Renda"), format_real(Mín), Mín),
        Máx = ifelse(Métrica %in% c("Gasto", "Renda"), format_real(Máx), Máx),
        Média = ifelse(Métrica %in% c("Gasto", "Renda"), format_real(Média), Média),
        Soma = ifelse(Métrica %in% c("Gasto", "Renda"), format_real(Soma), Soma),
        Variância = ifelse(Métrica %in% c("Gasto", "Renda"), format_real(Variância), Variância)
      )
    
    # Renderizar a tabela formatada
    datatable(summary, options = list(dom = 't', scrollX = TRUE))
  })
  
  # Gráfico de distribuição de gastos
  output$distPlot <- renderPlot({
    ggplot(filtered_data(), aes(x = Gasto)) +
      geom_histogram(binwidth = 10, fill = "blue", color = "white", alpha = 0.7) +
      theme_minimal() +
      labs(title = "Distribuição de Gastos", x = "Gasto Mensal", y = "Frequência") +
      scale_x_continuous(labels = scales::label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ","))
  })
}

# Rodar o aplicativo Shiny
shinyApp(ui = ui, server = server)
