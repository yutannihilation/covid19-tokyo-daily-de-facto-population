
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ヤフー・データソリューションの「東京23区滞在人口推計値の日別遷移（全体・来訪者・住人）」をRでプロットしてみる

## データの出典

  - 東京23区滞在人口推計値の日別遷移データ: ヤフー・データソリューション
    (<https://ds.yahoo.co.jp/report/>)
  - 行政区域データ: 国土数値情報
    (<http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N03-v2_3.html>)
  - 祝日データ: zipangu (<https://uribo.github.io/zipangu/>)

## Plot

``` r
library(readr)
library(ggplot2)
library(sf)
#> Linking to GEOS 3.8.0, GDAL 3.0.4, PROJ 6.3.1
library(dplyr, warn.conflicts = FALSE)
```

``` r
# 前処理の詳細は scripts/get_data.R
d <- readr::read_csv(here::here("data/data.csv"))
#> Parsed with column specification:
#> cols(
#>   エリア = col_character(),
#>   対象分類 = col_character(),
#>   date = col_date(format = ""),
#>   visitors = col_double()
#> )
```

``` r
ggplot(d, aes(date, visitors, colour = 対象分類, fill = 対象分類)) +
  geom_area() +
  facet_wrap(vars(エリア), ncol = 4) +
  scale_colour_viridis_d(alpha = 0.3, aesthetics = c("colour", "fill")) +
  scale_x_date(guide = guide_axis(n.dodge = 2), date_labels = "%m/%d") +
  theme_minimal() +
  theme(legend.position = "top")
```

![](README_files/figure-gfm/plot_simple-1.png)<!-- -->

``` r
# 前処理の詳細は scripts/get_tokyo_gpkg.R
tokyo <- read_sf(here::here("data/tokyo.gpkg"))

d2 <- d %>%
  mutate(
    is_holiday = zipangu::is_jholiday(date) | (lubridate::wday(date) %in% 6:7),
    week_begin = lubridate::floor_date(date, "weeks"),
    day = lubridate::wday(date, label = TRUE)
  ) %>% 
  inner_join(tokyo, ., by = c("市区町村名" = "エリア"))
```

``` r
d2 %>%
  filter(week_begin == as.Date("2020-02-02")) %>% 
  ggplot() +
  geom_sf(aes(fill = visitors), colour = NA) +
  facet_grid(rows = vars(対象分類), cols = vars(day)) +
  theme_minimal() +
  theme(legend.position = "top") +
  scale_fill_viridis_c(option = "B") +
  ggtitle("2020/2/2〜2/8")
```

![](README_files/figure-gfm/plot_first_week-1.png)<!-- -->

``` r
d_mean <- d2 %>%
  group_by(市区町村名, 対象分類, is_holiday = if_else(is_holiday, "holiday", "weekday"), week_begin) %>%
  summarise(visitors = mean(visitors)) %>%
  arrange(week_begin) %>%
  mutate(rel_visitors = visitors / first(visitors)) %>%
  ungroup()

ggplot(d_mean, aes(week_begin, rel_visitors, colour = 市区町村名)) +
  geom_line() +
  facet_grid(rows = vars(is_holiday, 対象分類))
```

![](README_files/figure-gfm/plot_changes-1.png)<!-- -->

住民は無視しても良さそうなので、来訪者のみの変化を見る

``` r
d_mean_de_facto <- d_mean %>% 
  filter(対象分類 == "来訪者") %>% 
  mutate(week_id = group_indices(., week_begin))

library(gganimate)

ggplot(d_mean_de_facto) +
  geom_sf(aes(fill = rel_visitors), colour = NA) +
  facet_grid(cols = vars(is_holiday)) +
  theme_minimal() +
  theme(legend.position = "top") +
  scale_fill_viridis_c(option = "B") +
  labs(title = "Week: {frame_time}") +
  transition_time(week_id) +
  ease_aes('linear')
```

![](README_files/figure-gfm/animate-1.gif)<!-- -->
