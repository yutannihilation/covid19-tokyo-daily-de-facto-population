library(readxl)
library(purrr)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(lubridate)

xlsx_urls <- c(
  "https://dfi-place.west.edge.storage-yahoo.jp/web/report/come_in_index_japan.xlsx",
  "https://dfi-place.west.edge.storage-yahoo.jp/web/report/go_out_index_japan.xlsx"
)

xlsx_files <- here::here("data", basename(xlsx_urls))

walk2(
  xlsx_urls,
  xlsx_files,
  ~ download.file(.x, .y)
)


process_one_xlsx <- function(xlsx_file) {
  sheets <- excel_sheets(xlsx_file)
  sheets_data <- sheets[-length(sheets)]
  sheets_metadata_wday <- sheets[length(sheets)]
  
  d_metadata_wday <- read_xlsx(
    xlsx_file,
    sheet = sheets_metadata_wday
  )
  colnames(d_metadata_wday) <- c("date_last_year", "wday_last_year", "date", "wday")
  
  d_metadata_wday <- d_metadata_wday %>% 
    transmute(
      date = date(date),
      # その日が土日または祝日か
      is_holiday  = wday(date) %in% c(1, 7) | stringr::str_detect(wday, "祝日"),
      # 比較対象の日（2019年）が土日または祝日か
      was_holiday = wday(date_last_year) %in% c(1, 7) | stringr::str_detect(wday_last_year, "祝日")
    )
  
  d_raw <- map_dfr(set_names(sheets_data), function(sheet) {
    read_xlsx(xlsx_file, sheet = sheet) %>%
      rename(date = any_of(c("【来訪】日付", "【往訪】日付"))) %>% 
      mutate(date = date(date)) %>% 
      pivot_longer(-date,
        names_to = "area",
        values_to = "visitors_relative"
      )
  }, .id = "prefecture") %>% 
    relocate(date)
  
  d <- d_raw %>% 
    left_join(d_metadata_wday, by = "date")
  
  csv_file <- paste0(tools::file_path_sans_ext(xlsx_file), ".csv")
  readr::write_csv(d, csv_file)
}

walk(xlsx_files, process_one_xlsx)
