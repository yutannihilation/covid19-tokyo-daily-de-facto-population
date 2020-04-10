library(readxl)
library(purrr)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(lubridate)

date <- "0409"

xlsx_file <- here::here(glue::glue("data/raw_data{date}.xlsx"))
xlsx_url <- glue::glue("https://dfi-place.west.edge.storage-yahoo.jp/web/report/%E6%9D%B1%E4%BA%AC23%E5%8C%BA%E6%8E%A8%E7%A7%BB{date}.xlsx")
csv_file <- here::here(glue::glue("data/data{date}.csv"))

if (!file.exists(xlsx_file)) {
  download.file(xlsx_url, xlsx_file)
}

sheets <- excel_sheets(xlsx_file)

d_raw <- map_dfr(sheets, function(sheet) {
  read_xlsx(xlsx_file, sheet = sheet) %>%
    fill(エリア) %>% 
    pivot_longer(
      -c(エリア, 対象分類),
      names_to = "date",
      values_to = "visitors"
    )
})

d <- d_raw %>% 
  mutate(
    date = as_date(as.integer(date), origin = "1899-12-30")
  )

# validation ----------------------------------------------------------

# 来訪者+住人=全体 のはず
d %>% 
  group_split(エリア) %>% 
  walk(function(x) {
    x <- pivot_wider(x, names_from = 対象分類, values_from = visitors)
    invalid <- filter(x, 来訪者 + 住人 != 全体)
    if (nrow(invalid) > 0) {
      rlang::abort(glue::glue("something is wrong with {x$エリア[1]}"))
    }
  })

# write data ---------------------------------------------------------

d_filtered <- d %>% 
  filter(
    エリア != "東京23区全体",
    対象分類 != "全体"
  )

readr::write_csv(d_filtered, csv_file)

# Workaround ---------------------------------------------------------------------

# 4/9のデータに過去分が含まれてなかったので workaroundとして前日分とjoinしてdistinctを取る

d_old <- readr::read_csv(here::here("data/data0408.csv"))
d_joined <- bind_rows(d_filtered, d_old) %>% 
  distinct() %>% 
  arrange(エリア, 対象分類, date)

# 重複している行があればおかしい
invalid <- d_joined %>% 
  group_by(エリア, 対象分類, date) %>% 
  filter(n() > 1)

if (nrow(invalid)) {
  rlang::abort("some rows are duplicated!!!")
}

readr::write_csv(d_joined, here::here("data/data.csv"))
