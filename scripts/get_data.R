library(readxl)
library(purrr)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(lubridate)

xlsx_file <- here::here("data/raw_data0408.xlsx")
xlsx_url <- "https://dfi-place.west.edge.storage-yahoo.jp/web/report/%E6%9D%B1%E4%BA%AC23%E5%8C%BA%E6%8E%A8%E7%A7%BB0408.xlsx"
csv_file <- here::here("data/data.csv")

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