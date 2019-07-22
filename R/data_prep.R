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
  mutate(pop = parse_number(pop) * 1000) %>%
  select(iso3, year, pop)

saveRDS(population, "./data/un_population_country_year.rds")




# Penn World GDP data -----------------------------------------------------
## rgdpe: Expenditure-side real GDP at chained PPPs (in mil. 2011US$)
url1 <- "https://www.rug.nl/ggdc/docs/pwt91.xlsx"
GET(url1, write_disk(tf <- tempfile(fileext = ".xlsx")))

penn_gdp <- read_excel(tf, sheet = "Data") %>%
  mutate(gdp_exp = rgdpe * 1000000,
         gdp_out = rgdpo * 1000000) %>%
  select(iso3 = countrycode, year, gdp_exp, gdp_out)

saveRDS(penn_gdp, "./data/penn_gdp.rds")



# UCDP armed conflict data ------------------------------------------------
## Pettersson, Therese; Stina Högbladh & Magnus Öberg, 2019. Organized violence, 1989-2018 and peace agreements, Journal of Peace Research 56(4).
## Gleditsch, Nils Petter, Peter Wallensteen, Mikael Eriksson, Margareta Sollenberg, and Håvard Strand (2002) Armed Conflict 1946-2001: A New Dataset. Journal of Peace Research 39(5). 

acd <- read_csv("http://ucdp.uu.se/downloads/ucdpprio/ucdp-prio-acd-191.csv")
acd <- acd %>%
  filter(type_of_conflict %in% c("3", "4")) %>%
  select(year, gwno_loc, intensity_level) %>%
  mutate(iso3 = countrycode(gwno_loc, "cown", "iso3c", 
                            custom_match = c(`678` = "YEM", `751` = "IND", `817` = "VNM", `345` = "SRB"))) %>%
  group_by(iso3, year) %>%
  summarise(conflict = max(intensity_level)) %>%
  ungroup()

saveRDS(acd, "./data/ucdp_acd.rds")
