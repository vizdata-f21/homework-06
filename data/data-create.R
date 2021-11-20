# Load packages -----------------------------------------------------

library(shiny)
library(tidyverse)
library(colorblindr)
library(scales)
library(countrycode)

# Load data ---------------------------------------------------------
manager_survey <- read_csv("data/survey.csv",
                           show_col_types = FALSE)

manager_survey <- manager_survey %>%
  filter(
    !is.na(industry),
    !is.na(highest_level_of_education_completed),
    currency == "USD"
  ) %>%
  mutate(
    industry_other = fct_lump_min(industry, min = 100)
  )

industry_choices <- manager_survey %>%
  distinct(industry_other) %>%
  arrange(industry_other) %>%
  pull()

# Define UI ---------------------------------------------------------
ui <- fluidPage(
  titlePanel(title = "Ask a Manager"),
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput(
        inputId = "industry",
        label = "Select up to 8 industies:",
        choices = industry_choices,
        selected = industry_choices[1:3]
      )
    ),
    mainPanel(
      tabsetPanel(
        # tab 1: average salaries
        tabPanel(title = "Average salaries"),
        # tab 2: individual salaries
        tabPanel(
          title = "Individual salaries",
          plotOutput(outputId = "indiv_salary",
                     brush = "indiv_salary_brush"),
          tableOutput(outputId = "indiv_salary_table")
          ),
        # tab 3: data table
        tabPanel(
          title = "Data",
          DT::dataTableOutput(outputId = "data")
        )
      )
      )
  )
)

# Define server function --------------------------------------------
server <- function(input, output, session) {

  manager_survey_filtered <- reactive({
    manager_survey %>%
      filter(industry %in% input$industry)
  })

  output$data <- DT::renderDataTable({
    manager_survey_filtered()
  })

  output$indiv_salary <- renderPlot({

    validate(
      need(
        length(input$industry) <= 8,
        "Please select a maximum of 8 industries"
      )
    )

    ggplot(
      data = manager_survey_filtered(),
      aes(x = highest_level_of_education_completed,
          y = annual_salary,
          color = industry)
    ) +
      geom_jitter() +
      scale_color_OkabeIto()
  })

  ## build a table for brushed points
  output$indiv_salary_table <- renderTable({
    brushedPoints(
      manager_survey_filtered(),
      input$indiv_salary_brush
    )
  })

}

# Create the Shiny app object ---------------------------------------
shinyApp(ui = ui, server = server)
