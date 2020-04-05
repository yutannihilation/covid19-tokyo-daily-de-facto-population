library(dplyr, warn.conflicts = FALSE)
library(kokudosuuchi)
library(sf)

d <- getKSJURL("N03", prefCode = "13")

url <- d %>%
  arrange(desc(year)) %>%
  slice(1) %>%
  pull(zipFileUrl)

# workaround for a bug in kokudosuuchi...
zip_file <- here::here("cache/N03-190101_13_GML.zip")
if (!file.exists(zip_file)) {
  download.file(url, destfile = zip_file)
}

d <- getKSJData(url, cache_dir = here::here("cache"))
d <- translateKSJData(d)
d <- d[[1]]

# 市区町村ごとに1つのポリゴンにまとめる
d_summarised <- d %>%
  group_by(市区町村名) %>%
  summarise()

write_sf(d_summarised, here::here("data/tokyo.gpkg"))
