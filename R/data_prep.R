library(tidyverse)
library(readxl)
library(countrycode)
library(httr)


# UN population data ------------------------------------------------------
url1 <- "https://population.un.org/wpp/Download/Files/1_Indicators%20(Standard)/EXCEL_FILES/1_Population/WPP2019_POP_F01_1_TOTAL_POPULATION_BOTH_SEXES.xlsx"
GET(url1, write_disk(tf <- tempfile(fileext = ".xlsx")))
population <- read_excel(tf,
                         sheet = "ESTIMATES", skip = 16) %>%
  filter(Type == "Country") %>%
  rename(country = `Region, subregion, country or area *`) %>%
  select(-c(Index, Variant, Notes, Type, `Parent code`)) %>%
  gather(year, pop, -c(country, `Country code`)) %>%
  mutate(iso3 = countrycode(country, "country.name", "iso3c", custom_match = c(`Eswatini` = "SWZ"))) %>%
  filter(!is.na(iso3)) %>%
  mutate(pop = parse_number(pop) * 1000,
         year = parse_number(year)) %>%
  select(iso3, year, pop)

saveRDS(population, "./data/un_population_country_year.rds")


# Penn World data ---------------------------------------------------------
## rgdpe: Expenditure-side real GDP at chained PPPs (in mil. 2005US$)
## pop:	Population (in millions)
url1 <- "https://www.rug.nl/ggdc/docs/pwt80.xlsx"
GET(url1, write_disk(tf <- tempfile(fileext = ".xlsx")))

penn_world <- read_excel(tf, sheet = "Data") %>%
  mutate(gdp_exp = rgdpe * 1e6,
         pop = pop * 1e6) %>%
  select(iso3 = countrycode, year, gdp_exp, pop)

saveRDS(penn_world, "./data/penn_world.rds")
