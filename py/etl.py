### ETL script for generating input tables to model
### main point: ETL JHU covid-19 case and mortality data

# todo: refactor

## HERE! -> not handled here in python -> Serial Interval Table -> would be worthwhile to reproduce the R for that here
## "serial interval table" <--> that discretized gamma distribution
## so that this script does indeed produce all the required input tables for the model
## alternatively, could just generate that discretized gamma distribution in the R code itself, pre-simulation
## I don't like that idea -> will try to reproduce results in python - but not now -> other more pressing tasks now

import os
import numpy as np
import warnings

warnings.simplefilter(
    action="ignore", category=FutureWarning
)  # suppress pandas "future warning"
import pandas as pd


def makeCaseMortalityTable(dirPath):

    print("\n~ COVID-19 CASE-MORTALITY TABLE ~")

    # E
    print("--- extracting JHU covid-19 case and mortality data ---")

    # what's the issue here? sometimes stalls for some reason -> fetching data from git

    # fetch the JHU time-series data
    # see: https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/README.md
    jhu = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"
    cases_csv = "time_series_covid19_confirmed_US.csv"
    deaths_csv = "time_series_covid19_deaths_US.csv"
    casesOrig = pd.read_csv(jhu + cases_csv)
    deathsOrig = pd.read_csv(jhu + deaths_csv)

    # T
    print("--- transforming case and mortality data ---")

    # 1. process cases df to match form of EU table
    cases = casesOrig

    ## get daily counts -> make this a fn

    # take this out, put it back after compute
    dc = cases.copy().iloc[:, 11:].astype(np.int64)

    # fix monotone errors
    # rows
    for i in range(len(dc.iloc[:, 0])):
        # cols
        for j in range(len(dc.columns) - 1):
            # per row:
            # if the next value is bigger than current value -> set next val to current val
            # ensures monotonically increasing sequences
            # allows coherent compute of daily counts (increments -> prevents negative increments)
            if dc.iloc[i, j] > dc.iloc[i, j + 1]:
                dc.iloc[i, j + 1] = dc.iloc[i, j]

    # look, they're all monotone now!
    # print(dc.apply(lambda x: x.is_monotonic, axis=1).unique())

    dailyCounts = cases.copy()

    # replace cumulative counts with daily counts (i.e., increments)
    dailyCounts.iloc[:, 12:] = dc.diff(axis=1, periods=1).iloc[:, 1:]

    # treat the daily counts as our working table from here forward
    # note: need to do the same procedure for the death counts
    cases = dailyCounts

    # notice from data repo readme:
    # US counties: UID = 840 (country code3) + XXXXX (5-digit FIPS code)

    # drop redundant columns
    cases = cases.drop(cases.columns[[1, 2, 3, 4, 7, 10]], axis=1)

    # "melt" df into desired form
    # i.e., rows correspond to dates
    idVars = ["UID", "Admin2", "Province_State", "Lat", "Long_"]
    cases = cases.melt(id_vars=idVars, var_name="Date", value_name="Cases")

    # define mapping from our df to theirs
    # first just map the data
    # then can fix column names and python etl code accordingly

    # now, process deaths data, see if we can take the same path to the same outcome

    # 2. process deaths data
    deaths = deathsOrig

    # compute increments from cumulative counts - same steps as case table

    # take this out, put it back after compute
    # note: this table has "population" column - 1 additional column, so dates start at 12, not 11
    dc = deaths.copy().iloc[:, 12:].astype(np.int64)

    ## fix monotone errors -> make this a fn
    # rows
    for i in range(len(dc.iloc[:, 0])):
        # cols
        for j in range(len(dc.columns) - 1):
            if dc.iloc[i, j] > dc.iloc[i, j + 1]:
                dc.iloc[i, j + 1] = dc.iloc[i, j]

    # look, they're all monotone now!
    # print(dc.apply(lambda x: x.is_monotonic, axis=1).unique())

    dailyCounts = deaths.copy()
    # replace cumulative counts with daily counts (i.e., increments)
    dailyCounts.iloc[:, 13:] = dc.diff(axis=1, periods=1).iloc[:, 1:]

    # now working with daily deaths, not cumulative deaths
    deaths = dailyCounts

    # drop redundant columns -> keep population column
    deaths = deaths.drop(deaths.columns[[1, 2, 3, 4, 7, 10]], axis=1)

    # "melt" df into desired form
    # i.e., rows correspond to dates
    idVars = ["UID", "Admin2", "Province_State", "Lat", "Long_", "Population"]
    deaths = deaths.melt(id_vars=idVars, var_name="Date", value_name="Deaths")

    # note: processing of the two tables is exactly the same except
    # for the deaths table having the extra ID column "Population"
    # so can refactor/streamline code to make it concise and much prettier

    # next task: "merge" the deaths and cases tables

    # danke: https://stackoverflow.com/questions/19125091/pandas-merge-how-to-avoid-duplicating-columns
    # merge df's
    # i.e., inject population and deaths data from deaths df into cases df
    cols_to_use = deaths.columns.difference(cases.columns)
    caseAndMortality = pd.merge(
        cases, deaths[cols_to_use], left_index=True, right_index=True, how="outer"
    )

    # cut out rows where Admin2 is "Out of IL" or "Unassigned" (both have population 0)
    caseAndMortality = caseAndMortality.loc[caseAndMortality["Population"] > 0]

    # rename some columns; improve readability
    renameColsMap = {
        "UID": "CountyID",  # fairly certain this is appropriate, though will double check
        "Admin2": "Town",  # ? -> probably a better name for this
        "Province_State": "State",
        "Lat": "Latitude",
        "Long_": "Longitude",
    }
    caseAndMortality = caseAndMortality.rename(renameColsMap, axis=1)

    # now order the columns nicely
    columnOrder = [
        "Date",
        "Cases",
        "Deaths",
        "CountyID",
        "Town",
        "State",
        "Population",
        "Latitude",
        "Longitude",
    ]

    caseAndMortality = caseAndMortality[columnOrder]

    # looks good -> save it
    # suppressing this for now, so as not to create "unused" tables -> simplify output of this script
    # caseAndMortality.to_csv(dirPath + "/caseAndMortality.csv")

    # next:
    # 1. preserving this table; modify this table to exactly match the scheme of the Euro table
    # 2. save that as a separate file
    # 3. run the model with that table as input
    # 6. refactor all this; sketch plan for actual script(s) (!)

    df = caseAndMortality.copy()

    df["month"], df["day"], df["year"] = df["Date"].str.split("/").str

    # drop extra columns
    df = df.drop(["Latitude", "Longitude"], axis=1)

    # rename remaining columns to match Euro table
    ToEuroColumnsMap = {
        "Date": "dateRep",
        "Cases": "cases",
        "Deaths": "deaths",
        "State": "state",
        "CountyID": "countryterritoryCode",
        "Town": "countriesAndTerritories",
        "Population": "popData2018",
    }

    df = df.rename(ToEuroColumnsMap, axis=1)

    # populate geoID with Town also, just to populate it
    df["geoId"] = df["countriesAndTerritories"]

    # reorder the columns to match Euro table # probably don't hardcode this -> make proper config file (?)
    CaseMortalityColumnOrder = [
        "dateRep",
        "day",
        "month",
        "year",
        "cases",
        "deaths",
        "countriesAndTerritories",
        "geoId",
        "countryterritoryCode",
        "popData2018",
        "state",
    ]
    df = df[CaseMortalityColumnOrder]

    print("--- saving transformed case and mortality data  ---")

    # okay, done, now save it
    p = dirPath + "/CaseAndMortalityV2.csv"
    df.to_csv(p)

    countyIDList = caseAndMortality["CountyID"].unique()

    population_df = (
        caseAndMortality[["CountyID", "Population"]].copy().drop_duplicates()
    )

    return (p, countyIDList, population_df)


# feat/usa - fixme - lockdown happened at different times for different states
# can't use the IL lockdown dates for other states, of course
# for now, can suppress displaying lockdown anyway
# it doesn't get used for anything except to display that dashed line on the visualizations
# so - low priority for now
def makeInterventionsTable(dirPath, countyIDList):
    print("\n~ INTERVENTIONS TABLE ~")

    # task: make a table for IL by county that looks like their covariates table
    # only column is lockdown
    # dates for all counties the same
    # admittedly a dumb table for now, but will get extended later

    print("--- constructing interventions table ---")

    # counties correspond to countries
    ourCovariates = pd.DataFrame(countyIDList, columns=["Country"])

    print("--- loading intervention: lockdown ---")

    # date of IL lockdown: Saturday, March 21st, 2020
    # source: https://www.chicagotribune.com/coronavirus/ct-coronavirus-illinois-shelter-in-place-lockdown-order-20200320-teedakbfw5gvdgmnaxlel54hau-story.html
    ourCovariates["lockdown"] = "2020-03-21"

    print("--- saving covariates table ---")

    # save this new table
    p = dirPath + "/ILInterventionsV1.csv"
    ourCovariates.to_csv(p)

    return p


# paper: https://arxiv.org/abs/2004.00756
# data: https://github.com/JieYingWu/COVID-19_US_County-level_Summaries
def fetchSocEc(dirPath):
    print("\n~ SOC-EC TABLE ~")

    print("--- fetching soc-ec table ---")
    path = "https://raw.githubusercontent.com/JieYingWu/COVID-19_US_County-level_Summaries/master/data/counties.csv"
    df = pd.read_csv(path)

    print("--- saving soc-ec table ---")
    p = dirPath + "/SocEc.csv"
    df.to_csv(p)

    return p


# wow I want to really, thoroughly refactor all this so bad
# make a class - the whole thing -> not the most time pressing task though

if __name__ == "__main__":

    # put tables here
    dirPath = "/modelInput"
    os.makedirs(dirPath, exist_ok=True)

    p1, countyIDList, population_df = makeCaseMortalityTable(dirPath)

    # see note at this fn definition
    # p2 = makeInterventionsTable(dirPath, countyIDList)

    p4 = fetchSocEc(dirPath)

    print("\n")
    print("tables successfully written to these paths:")
    print("\t", p1)
    # print("\t", p2)
    print("\t", p4)
    print("\n")
