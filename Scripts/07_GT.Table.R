#load data and libs

library(tidyverse)
library(gt)
library(gtExtras)

DF_EPA <- read_csv("Derived_Data/Top.10.Players.csv")

#now we need to get everyones headshot url

Top20_EPA <- DF_EPA %>% 
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

top20_EPA_gt <- Top20_EPA %>% 
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
  tab_spanner(label = "RAEPAC", 
              columns = c(Contribution, Contribution2)) %>% 
  tab_style(
    cell_borders(sides = "right"), 
    locations = cells_body(
      columns = c(Position, Snaps2)
    )
  ) %>% 
  tab_style(
    cell_borders(sides = "bottom"), 
    locations = cells_body(
      rows = 10
    )
  ) %>% 
  tab_header(
    title = md("**Top 10 & Bottom 10 Player EPA Contribution**"),
    subtitle = "2018-2020 | Minimum of 25 punt returns in that time")

gtsave(top20_EPA_gt, "Regression_Plots/top20_EPA_gt.png") 


#next we do the same table for penalties instead

DF_Penalty <- read_csv("Derived_Data/Top.20.Players.Penalty.csv")

#so we start by getting all their headshots and teams

DF_Penalty_20 <- DF_Penalty %>% 
  mutate(headshot = case_when(
    Name == "Brian Allen" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/2971632.png&w=350&h=254", 
    Name == "Dekoda Watson" ~ "https://www.playerprofiler.com/wp-content/uploads/2018/03/dekoda-watson-advanced-stats-metrics-analytics-profile.png", 
    Name == "Donnie Jones" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/5749.png&w=350&h=254", 
    Name == "Josh Hawkins" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/2575523.png", 
    Name == "Michael Davis" ~ "https://static.www.nfl.com/image/private/t_headshot_desktop/league/udhu04nmkn2rhujwpt2p", 
    Name == "K'Waun Williams" ~ "https://static.www.nfl.com/image/private/t_player_profile_landscape/f_auto/league/ewlh3um3bhdcj5jnao45", 
    Name == "James Proche" ~ "https://static.www.nfl.com/image/private/t_player_profile_landscape/f_auto/league/esjpio5c0exxgppw2i05", 
    Name == "Chapelle Russell" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3923413.png", 
    Name == "Trevor Daniel" ~ "https://static.www.nfl.com/image/private/t_player_profile_landscape/f_auto/league/ltzawsjjoug8mbqchxcb", 
    Name == "Isaiah Johnson" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/2570484.png&w=350&h=254", 
    Name == "Edmond Robinson" ~ "https://static.www.nfl.com/image/private/t_headshot_desktop/league/laxxbklw8na3w5v5uij0", 
    Name == "Brandon Graham" ~ "https://static.www.nfl.com/image/private/t_headshot_desktop/league/imeae5vrkbtc6u7vdttf", 
    Name == "Javelin Guidry" ~ "https://static.www.nfl.com/image/private/t_headshot_desktop/league/w2ol2sd7wjl8i7ruca8h", 
    Name == "D'Juan Hines" ~ "https://static.www.nfl.com/image/private/t_player_profile_landscape/f_auto/league/dhrmhpnpnvdj5aafminx", 
    Name == "DeShawn Shead" ~ "https://static.www.nfl.com/image/private/t_headshot_desktop/league/gj3liwtjkgotqaa5pav0", 
    Name == "Ray-Ray McCloud" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/3728262.png", 
    Name == "Coty Sensabaugh" ~ "https://static.www.nfl.com/image/private/t_player_profile_landscape/f_auto/league/jiuv92mavotqatsa9cq6", 
    Name == "Jack Cichy" ~ "https://static.www.nfl.com/image/private/t_headshot_desktop/league/nnna6bbld6f48exkyroq", 
    Name == "Patrick Chung" ~ "https://static.www.nfl.com/image/private/t_player_profile_landscape/f_auto/league/a47ekoy2j1fb1jd3qqo4", 
    Name == "Deon Bush" ~ "https://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/2969944.png&w=350&h=254"
  )
  ) %>% 
  mutate(Team = case_when(
    Name == "Brian Allen" ~ "https://logos-world.net/wp-content/uploads/2020/05/Los-Angeles-Rams-logo.png", 
    Name == "Dekoda Watson" ~ "https://images.thdstatic.com/productImages/57d2efec-e083-445c-a32a-7a8e7ed06c27/svn/blue-applied-icon-wall-decals-nfop2901-64_600.jpg", 
    Name == "Donnie Jones" ~ "https://logos-world.net/wp-content/uploads/2020/05/Los-Angeles-Rams-logo.png", 
    Name == "Josh Hawkins" ~ "https://logos-world.net/wp-content/uploads/2020/05/Philadelphia-Eagles-Logo.png", 
    Name == "Michael Davis" ~ "https://upload.wikimedia.org/wikipedia/en/thumb/a/a6/Los_Angeles_Chargers_logo.svg/1280px-Los_Angeles_Chargers_logo.svg.png", 
    Name == "K'Waun Williams" ~ "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/San_Francisco_49ers_logo.svg/2560px-San_Francisco_49ers_logo.svg.png", 
    Name == "James Proche" ~ "https://logos-world.net/wp-content/uploads/2020/05/Baltimore-Ravens-logo.png", 
    Name == "Chapelle Russell" ~ "https://logos-world.net/wp-content/uploads/2020/05/Jacksonville-Jaguars-logo.png", 
    Name == "Trevor Daniel" ~ "https://logos-world.net/wp-content/uploads/2020/05/Tennessee-Titans-Logo.png", 
    Name == "Isaiah Johnson" ~ "https://1000logos.net/wp-content/uploads/2016/10/Tampa-Bay-Buccaneers-logo.jpg", 
    Name == "Edmond Robinson" ~ "https://images.thdstatic.com/productImages/57d2efec-e083-445c-a32a-7a8e7ed06c27/svn/blue-applied-icon-wall-decals-nfop2901-64_600.jpg", 
    Name == "Brandon Graham" ~ "https://logos-world.net/wp-content/uploads/2020/05/Philadelphia-Eagles-Logo.png", 
    Name == "Javelin Guidry" ~ 'https://upload.wikimedia.org/wikipedia/en/thumb/6/6b/New_York_Jets_logo.svg/640px-New_York_Jets_logo.svg.png', 
    Name == "D'Juan Hines" ~ "https://wp.usatodaysports.com/wp-content/uploads/sites/90/2015/02/helmet_top_center1.png", 
    Name == "DeShawn Shead" ~ "https://cdn.freebiesupply.com/images/large/2x/detroit-lions-logo-transparent.png", 
    Name == "Ray-Ray McCloud" ~ "https://images.thdstatic.com/productImages/a1c4eb83-bc86-42f7-b13f-a70acea100c9/svn/white-applied-icon-wall-decals-nfop2603-64_600.jpg", 
    Name == "Coty Sensabaugh" ~ "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Washington_Commanders_logo.svg/2560px-Washington_Commanders_logo.svg.png", 
    Name == "Jack Cichy" ~ "https://1000logos.net/wp-content/uploads/2016/10/Tampa-Bay-Buccaneers-logo.jpg", 
    Name == "Patrick Chung" ~ "https://1000logos.net/wp-content/uploads/2017/05/New-England-Patriots-logo.jpg", 
    Name == "Deon Bush" ~ "https://loodibee.com/wp-content/uploads/nfl-chicago-bears-team-logo.png"
  )) %>% 
  mutate(Contribution = round(Contribution, digits = 4)) %>% 
  mutate(Contribution2 = Contribution) %>% 
  mutate(Snaps2 = Snaps) %>% 
  select(Team, Name, headshot, Position, Snaps, Snaps2, Contribution, Contribution2)

#and build the gt

top20_Penalty_gt <- DF_Penalty_20 %>% 
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
  tab_spanner(label = "RAPC", 
              columns = c(Contribution, Contribution2)) %>% 
  tab_style(
    cell_borders(sides = "right"), 
    locations = cells_body(
      columns = c(Position, Snaps2)
    )
  ) %>% 
  tab_header(
    title = md("**Top 20 Player Penalty Contribution**"),
    subtitle = "2018-2020 | Minimum of 25 punt returns in that time")

gtsave(top20_Penalty_gt, "Regression_Plots/top20_Penalty_gt.png") 