
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ヤフー・データソリューションの「東京23区滞在人口推計値の日別遷移（全体・来訪者・住人） 」をRでプロットしてみる

## Data

出典：ヤフー・データソリューション (<https://ds.yahoo.co.jp/report/>)

## Plot

``` r
library(readr)
library(ggplot2)
```

``` r
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
