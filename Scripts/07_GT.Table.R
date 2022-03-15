#load data and libs

library(tidyverse)
library(gt)
library(gtExtras)

DF <- read_csv("Derived_Data/Top.10.Players.csv")

#now we need to get everyones headshot url

Top20 <- DF %>% 
  mutate(headshot = case_when(
    Name == "John Cominsky" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/4411771.png&w=350&h=254",
    Name == "Collin Johnson" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/4039043.png&w=350&h=254",
    Name == "Jordan Miller" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3886824.png&w=350&h=254",
    Name == "Jason McCourty" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/12691.png&w=350&h=254",
    Name == "Bruce Miller" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/14083.png&w=350&h=254",
    Name == "J.T. Hassell" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/4264341.png&w=350&h=254",
    Name == "Paul Worrilow" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/16243.png&w=350&h=254",
    Name == "Darius Slay" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/15863.png&w=350&h=254",
    Name == "Ian Thomas" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/4045305.png&w=350&h=254",
    Name == "Peyton Barber" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3051902.png&w=350&h=254",
    Name == "Wayne Gallman" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3045127.png&w=350&h=254",
    Name == "Chase Allen" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/2975680.png&w=350&h=254",
    Name == "Martrell Spaight" ~ "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTXnX7KcxSTKVasl1dSbVuhgrgjtQ23MN8d5jeQdiX22o5QBH7QipBu67olNE3rp0_0fFE&usqp=CAU",
    Name == "Van Jefferson" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3930066.png&w=350&h=254",
    Name == "Albert Wilson" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/17051.png&w=350&h=254",
    Name == "Ryan Kerrigan" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/13973.png&w=350&h=254",
    Name == "Da'Ron Payne" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3925354.png&w=350&h=254",
    Name == "Tyron Johnson" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3894912.png",
    Name == "Kerry Hyder" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/17068.png&w=350&h=254",
    Name == "Arik Armstead" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/2971275.png&w=350&h=254",
  )) %>% 
  select(Name, headshot, Position, Snaps, Contribution) %>% 
  mutate(Contribution = round(Contribution, digits = 4))

top20_gt <- Top20 %>% 
  gt() %>% 
  gt_img_rows(headshot) %>% 
  gt_plt_bar(column = Snaps, scaled = TRUE, color = "darkgreen") %>%
  gt_plt_bar(column = Contribution, scaled = TRUE, color = "darkblue", keep_column = T) %>%
  gt_theme_538(table.width = px(650)) %>%
  cols_align(align = "center") %>%
  cols_label(Name = "Player",
             headshot = "",
             Snaps = "Snaps",
             Contribution = "EPA Contribution") %>%
  tab_header(
    title = md("**Top 10 & Bottom 10 Player EPA Contribution**"),
    subtitle = "2018-2020 | Minimum of 25 punt returns in that time"
  )

gtsave(top20_gt, "Regression_Plots/top20_gt.png") 
