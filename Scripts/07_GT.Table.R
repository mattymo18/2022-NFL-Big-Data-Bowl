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
    Name == "Arik Armstead" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/2971275.png&w=350&h=254"
  )) %>% 
  mutate(Team = case_when(
    Name == "John Cominsky" ~ "https://logos-world.net/wp-content/uploads/2020/05/Atlanta-Falcons-logo.png",
    Name == "Collin Johnson" ~ "https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/New_York_Giants_logo.svg/1280px-New_York_Giants_logo.svg.png",
    Name == "Jordan Miller" ~ "https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/New_Orleans_Saints_logo.svg/630px-New_Orleans_Saints_logo.svg.png",
    Name == "Jason McCourty" ~ "https://sportslogohistory.com/wp-content/uploads/2018/04/miami_dolphins_2018-pres.png",
    Name == "Bruce Miller" ~ "https://logos-world.net/wp-content/uploads/2020/05/Jacksonville-Jaguars-logo.png",
    Name == "J.T. Hassell" ~ "https://upload.wikimedia.org/wikipedia/en/thumb/6/6b/New_York_Jets_logo.svg/640px-New_York_Jets_logo.svg.png",
    Name == "Paul Worrilow" ~ "https://upload.wikimedia.org/wikipedia/en/thumb/6/6b/New_York_Jets_logo.svg/640px-New_York_Jets_logo.svg.png",
    Name == "Darius Slay" ~ "https://logos-world.net/wp-content/uploads/2020/05/Philadelphia-Eagles-Logo.png",
    Name == "Ian Thomas" ~ "https://sportslogohistory.com/wp-content/uploads/2017/12/carolina_panthers_2012-pres.png",
    Name == "Peyton Barber" ~ "https://static.www.nfl.com/t_q-best/league/api/clubs/logos/LV",
    Name == "Wayne Gallman" ~ "https://images.thdstatic.com/productImages/43fcf2e8-c5e4-46ef-b122-259b33a18eb9/svn/purple-applied-icon-wall-decals-nfop1901-64_600.jpg",
    Name == "Chase Allen" ~ "https://sportslogohistory.com/wp-content/uploads/2018/04/miami_dolphins_2018-pres.png",
    Name == "Martrell Spaight" ~ "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Washington_Commanders_logo.svg/2560px-Washington_Commanders_logo.svg.png",
    Name == "Van Jefferson" ~ "https://logos-world.net/wp-content/uploads/2020/05/Los-Angeles-Rams-logo.png",
    Name == "Albert Wilson" ~ "https://sportslogohistory.com/wp-content/uploads/2018/04/miami_dolphins_2018-pres.png",
    Name == "Ryan Kerrigan" ~ "https://logos-world.net/wp-content/uploads/2020/05/Philadelphia-Eagles-Logo.png",
    Name == "Da'Ron Payne" ~ "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Washington_Commanders_logo.svg/2560px-Washington_Commanders_logo.svg.png",
    Name == "Tyron Johnson" ~ "https://justblogbaby.com/files/2013/07/Raider-logo-4.png",
    Name == "Kerry Hyder" ~ "https://sportslogohistory.com/wp-content/uploads/2017/12/seattle_seahawks_2002-2011.png",
    Name == "Arik Armstead" ~ "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/San_Francisco_49ers_logo.svg/2560px-San_Francisco_49ers_logo.svg.png"
  )) %>% 
  mutate(Contribution = round(Contribution, digits = 4)) %>% 
  mutate(Contribution2 = Contribution) %>% 
  mutate(Snaps2 = Snaps) %>% 
  select(Team, Name, headshot, Position, Snaps, Snaps2, Contribution, Contribution2)

top20_gt <- Top20 %>% 
  gt() %>% 
  gt_img_rows(headshot) %>% 
  gt_img_rows(Team) %>% 
  gt_plt_bar(column = Snaps2, scaled = TRUE, color = "darkgreen") %>%
  gt_plt_bar(column = Contribution2, scaled = TRUE, color = "darkblue") %>%
  gt_theme_538(table.width = px(650)) %>%
  cols_align(align = "center") %>%
  cols_label(Team = "", 
             Name = "",
             headshot = "",
             Position = "",
             Snaps = "",
             Snaps2 = "",
             Contribution = "", 
             Contribution2 = "") %>%
  tab_spanner(label ="Player", 
              columns = c(Team, Name, headshot, Position)) %>% 
  tab_spanner(label = "Snap Count", 
              columns = c(Snaps, Snaps2)) %>% 
  tab_spanner(label = "EPA Contribution", 
              columns = c(Contribution, Contribution2)) %>% 
  tab_style(
    cell_borders(sides = "right"), 
    locations = cells_body(
      columns = c(Position, Snaps2)
    )
  ) %>% 
  tab_header(
    title = md("**Top 10 & Bottom 10 Player EPA Contribution**"),
    subtitle = "2018-2020 | Minimum of 25 punt returns in that time")

gtsave(top20_gt, "Regression_Plots/top20_gt.png") 
