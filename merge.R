library(stringr)
options(stringsAsFactors = FALSE)

# Load files and check
f = list.files("prov_files/")
f = paste0("prov_files/", f)
df_list = lapply(f, function(x) read.csv(x))
if( any(sapply(df_list, function(x) ncol(x)) != 23) ){warning("problem with ncol!")}

# Merge and select de jure population
census = as.data.frame(do.call("rbind", df_list))
census = subset(census, pop == "derecho")[, -which(names(census) == "pop")]

# Adapt INE codes ("01xxx" format)
census$muni_code = as.character(census$muni_code)
census$muni_code[census$prov_code %in% 1:9] = paste0("0",
  census$muni_code[census$prov_code %in% 1:9])

# Save
write.csv(census, "INE_census.csv", row.names = F)
