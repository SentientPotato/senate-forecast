## Load required packages
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(usmap)
## Override verbosity defaults and default ggplot theme
options(readr.show_col_types = FALSE)
options(dplyr.summarise.inform = FALSE)
theme_set(theme_bw())
## Read in historical Senate polls from FiveThirtyEight
## (projects.fivethirtyeight.com/polls-page/data/senate_polls_historical.csv)
historical_polls = read_csv("senate_polls_historical.csv")
## Read in historical Senate results from MIT's Election Data Lab
## (doi.org/10.7910/DVN/PEJ5QU)
historical_results = read_csv("1976-2020-senate.csv")
## Eliminate problematic cases
historical_polls = historical_polls %>%
    filter(!(state %in% c("California", "Louisiana"))) %>%
    filter(!(race_id %in% c(7780, 7781))) %>% ## Warnock
    filter(!(race_id %in% c(6271, 130))) ## pre-runoff Ossoff & Espy
idx_to_fix = which(with(historical_results,
                        year == 2020 & state == "WYOMING" & candidate == "CYNTHIA M. LUMMIS"
))
historical_results$party_simplified[idx_to_fix] = "REPUBLICAN"
idx_to_fix = which(with(historical_results,
                        year == 2020 & state == "WYOMING" & candidate == "MERAV BEN DAVID"
))
historical_results$party_simplified[idx_to_fix] = "DEMOCRAT"
historical_results = historical_results %>%
    filter(!writein) %>%
    filter(candidate != "ERNEST J. PAGELS, JR.") %>%
    select(year, state, stage, special, candidatevotes, party_simplified) %>%
    filter(year >= 2010) %>%
    filter(party_simplified %in% c("DEMOCRAT", "REPUBLICAN")) %>%
    filter(!(state %in% c("CALIFORNIA", "LOUISIANA"))) %>%
    filter(!(special & year == 2020 & state == "GEORGIA"))
## Calculate Democratic two party voteshare for each race
historical_results = historical_results %>%
    pivot_wider(names_from = party_simplified, values_from = candidatevotes) %>%
    mutate(twoparty = DEMOCRAT / (DEMOCRAT + REPUBLICAN))
## Read in current Senate polls from FiveThirtyEight
## (projects.fivethirtyeight.com/polls-page/data/senate_polls.csv)
current_polls = read_csv("senate_polls.csv")
## Eliminate problematic cases
current_polls = current_polls %>%
    filter(!(state %in% c("California", "Louisiana"))) %>%
    filter(cycle == 2022)
## Calculate Democratic and Republican "votes" from each poll
aggpolls = function(x) round(mean(x, na.rm = TRUE))
current_polls = current_polls %>%
    filter(stage != "jungle primary") %>%
    filter(party %in% c("DEM", "REP")) %>%
    filter(!is.na(sample_size)) %>%
    mutate(special = race_id %in% c(9480, 9482)) %>%
    group_by(poll_id, party) %>%
    summarise(
        year = first(as.numeric(paste0("20", gsub(".*/", "", election_date)))),
        state = first(state),
        special = first(special),
        votes = (pct / 100) * sample_size
    ) %>%
    pivot_wider(names_from = party, values_from = votes, values_fn = aggpolls)
dat = current_polls %>%
    na.omit() %>%
    group_by(year, state, special) %>%
    summarise(DEMOCRAT = sum(DEM), REPUBLICAN = sum(REP)) %>%
    mutate(state = toupper(state))
dat$a = 0; dat$b = 0
for ( i in 1:nrow(dat) ) {
    s = dat$state[i]
    y = dat$year[i]
    p = historical_results %>% filter(state == s & year < y) %>% pull(twoparty)
    mu = mean(p, na.rm = TRUE)
    s2 = var(p, na.rm = TRUE)
    dat$a[i] = ( ((1 - mu) / s2) - (1 / mu) ) * mu^2
    dat$b[i] = dat$a[i] * ( (1 / mu) - 1 )
}
dat = dat %>%
    mutate(estimate = (a + DEMOCRAT) / (a + b + DEMOCRAT + REPUBLICAN))
safe_d = 36 + 2 ## seats not up + CA + HI
safe_r = 29 + 3 ## seats not up + LA + ND + ID

## Compare to results
results = data.frame(
    state = dat$state,
    special = dat$special,
    twoway = c(
        435428  / ( 435428 +  940048), ##ALABAMA
        117299  / ( 135972 +  117299), ##ALASKA
        1322026 / (1322026 + 1196308), ##ARIZONA
        279277  / ( 279277 +  591045), ##ARKANSAS
        1397170 / (1397170 + 1031693), ##COLORADO
        724785  / ( 724785 +  536020), ##CONNECTICUT
        3200581 / (3200581 + 4474402), ##FLORIDA
        1946117 / (1946117 + 1908442), ##GEORGIA
        2272228 / (2272228 + 1689326), ##ILLINOIS
        702873  / ( 702873 + 1088428), ##INDIANA
        533318  / ( 533318 +  681487), ##IOWA
        365819  / ( 365819 +  595362), ##KANSAS
        564297  / ( 564297 +  913276), ##KENTUCKY
        1316929 / (1316929 +  682301), ##MARYLAND
        868875  / ( 868875 + 1143636), ##MISSOURI
        493443  / ( 493443 +  484436), ##NEVADA
        331987  / ( 331987 +  275307), ##NEW HAMPSHIRE
        3199839 / (3199839 + 2448323), ##NEW YORK
        1784049 / (1784049 + 1905786), ##NORTH CAROLINA
        1883223 / (1883223 + 2147898), ##OHIO
        368979  / ( 368979 +  739298), ##OKLAHOMA
        404951  / ( 404951 +  710004), ##OKLAHOMA
        1075894 / (1075894 +  788696), ##OREGON
        2747601 / (2747601 + 2484096), ##PENNSYLVANIA
        627616  / ( 627616 + 1066274), ##SOUTH CAROLINA
        90996   / (  90996 +  242282), ##SOUTH DAKOTA
        459958  / ( 459958 +  571974), ##UTAH
        195421  / ( 195421 +   80237), ##VERMONT
        1741738 / (1741738 + 1299039), ##WASHINGTON
        1310673 / (1310673 + 1336928)  ##WISCONSIN
    )
)

dat = dat %>% left_join(results)
table(prediction = ifelse(dat$estimate > 0.5, 1, 0), actual = ifelse(dat$twoway > 0.5, 1, 0))
# dat = dat %>%
#     select(state, special, estimate, twoway) %>%
#     pivot_longer(estimate:twoway, names_to = "G")
plt = ggplot(data = dat, mapping = aes(x = estimate, y = twoway)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "#80808080") +
    geom_point(size = 2) +
    xlab("Estimated Dem Two-way Voteshare") +
    ylab("Actual Result")
ggsave(
    plot = plt, filename = "accuracy.png", device = "png",
    width = 1200 / 300, height = 675 / 300
)
