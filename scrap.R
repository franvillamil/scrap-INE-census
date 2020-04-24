# Code to scrap INE census, valid as of 2011 census
# NOTE: Needs to be updated after 2021 census is released

setwd("~/Documents/Academic/DATA/Spain")
library(rvest)
library(stringr)
options(stringsAsFactors = FALSE)
library(muniSpain)

dir.create("census/prov_files")
dir.create("census/prov_files_cambios")

codelist = read.csv("census/codelist.csv")

provs = c("alava", "albacete", "alicante", "almeria", "avila",
  "badajoz", "baleares", "barcelona", "burgos", "caceres",
  "cadiz", "castellon", "ciudad real", "cordoba", "a coruna",
  "cuenca", "girona", "granada", "guadalajara", "gipuzkoa",
  "huelva", "huesca", "jaen", "leon", "lleida",
  "la rioja", "lugo", "madrid", "malaga", "murcia",
  "navarra", "ourense", "asturias", "palencia", "las palmas",
  "pontevedra", "salamanca", "santa cruz de tenerife",
  "cantabria", "segovia", "sevilla", "soria", "tarragona",
  "teruel", "toledo", "valencia", "valladolid", "bizkaia",
  "zamora", "zaragoza", "ceuta", "melilla")

############################################################
### PART I: SCRAP DATA FROM INE WEBSITE

url = "https://www.ine.es/intercensal/"

for (j in provs){

  census_data = data.frame()
  cambios = data.frame()

  prov_code = prov_to_code(j)

  for (i in codelist$muni[codelist$prov == prov_code]){
  # for (i in c(1:999, 5001:5999)){

    muni_code = i
    print(i)

    pgsession = html_session(url)
    pgform = html_form(pgsession)[[3]]
    pgform = set_values(pgform, 'codigoProvincia' = prov_code, 'codigoMunicipio' = muni_code)
    resp = submit_form(pgsession, pgform)
    resp2 = httr::content(resp$response)

    title = resp2 %>%
      html_nodes(".TITULOH3") %>%
      html_text()

    if(length(title) != 0){

      muni_code = sprintf("%05.0f",
        as.integer(paste0(prov_code, sprintf("%03.0f", muni_code))) )
      muni_name = gsub("\r|\n|(\u00a0)|", "", title)
      muni_name = gsub("\\s+", " ", muni_name) # more than 1 space
      muni_name = gsub(" $", "", muni_name) # final space
      muni_name = str_sub(muni_name,
        str_locate(muni_name, muni_code)[,2] + 1, -1L)
      muni_name = adapt(muni_name)
      prov_name = code_to_prov(prov_code)

      muni_data_raw = resp2 %>%
        html_nodes("table") %>%
        html_table(fill = TRUE)
      muni_data = muni_data_raw[[2]]
      muni_cambios = muni_data_raw[[3]]
      census_times_raw = gsub("\r\n|\\s\\s+", "", muni_data[1,])

      # Transform population data
      for (i in 1:ncol(muni_data)){
        muni_data[,i] = gsub("\r|\n|(\u00a0)| ", "", muni_data[,i])
      }

      pop_data = as.numeric(muni_data[3, 2:ncol(muni_data)])# (Poblacion de DERECHO)
      pop_data_hecho = as.numeric(muni_data[2, 2:ncol(muni_data)])# (Poblacion de HECHO)
      year_data = as.character(muni_data[1, 2:ncol(muni_data)])
      year_data = gsub("\\[.\\]|\\(.\\)", "", year_data)

      if (length(year_data) != 18){
        print(paste0("Warning: ", length(year_data), " columns"))
        print(paste0("Removing duplicated ", year_data[duplicated(year_data)]))
        pop_data = pop_data[!duplicated(year_data)]
        pop_data_hecho = pop_data_hecho[!duplicated(year_data)]
        year_data = year_data[!duplicated(year_data)]
      }

      output = as.data.frame(rbind(pop_data, pop_data_hecho))
      names(output) = paste0("c", year_data)
      # rownames(output) = rep(muni_code, nrow(output))
      output = cbind(prov_code, prov_name, muni_code, muni_name, output)
      output$pop = c("derecho", "hecho")

      # Put cambios together if the exist
      if(!all(dim(muni_cambios) == 1)){warning("Cambios, dimensions != 1x1?")
      } else {muni_cambios = muni_cambios[1,1]}
      output_cambios = data.frame(muni_code = muni_code,
        cambios = muni_cambios, census_head = paste(census_times_raw, collapse = ";"))


    census_data = rbind(census_data, output)
    cambios = rbind(cambios, subset(output_cambios, !is.na(cambios)))

    }

  }

  # Saving census data
  file = paste0("census/prov_files/", code_to_prov(prov_code), ".csv")
  write.csv(census_data, file, row.names = FALSE)
  # Saving cambios to municipios
  file_cambios = paste0("census/prov_files_cambios/", code_to_prov(prov_code), ".csv")
  write.csv(cambios, file_cambios, row.names = FALSE)

}
