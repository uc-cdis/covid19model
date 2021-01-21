# COVID-19 Model for USA By-County

This repo contains a variation of [this model](https://www.nature.com/articles/s41586-020-2405-7)
adapted to run on US counties.

You can use this model to generate daily estimates of true cases, true deaths and Rt for US counties
for the entirety of the COVID-19 pandemic.

The original model from the paper was built for and run on European countries.
Our adaptation is built for and runs on US counties.

Related Imperial College London reports on COVID-19:
- [Report 13](https://www.imperial.ac.uk/mrc-global-infectious-disease-analysis/covid-19/report-13-europe-npi-impact/): same material as the Nature publication; Rt is a step function; models early stages of the outbreak.
- [Report 23](https://www.imperial.ac.uk/mrc-global-infectious-disease-analysis/covid-19/report-23-united-states/): ICL's model applied to US by-state, including using mobility data to estimate Rt.

This statistical model is a hierarchical bayesian model implemented in [Stan](https://mc-stan.org/).

## How To Run The Model Locally

### Call Form

The `run.sh` script runs all the ETL and data fetching required to run the model.
The recommended way to run the model is through this bash script.
The ETL and setup however can take a few minutes,
and if you've already run it once all the way through
you can run the R script directly to run the model
so you don't keep fetching and ETL'ing the same data over and over again.

Here's how to run the model, complete with ETL and setup scripts:

```sh run.sh <stan_model> <minimumDeaths> <nIterations> -stateList <stateList>```

After you've run the ETL / setup once on a given day, you can bypass the ETL step if you'd like by
moving to the `/r` directory and running:

```Rscript base.r <stan_model> <minimumDeaths> <nIterations> -stateList <stateList>```

Notice all the params are the same and appear in the same order, 
you're just calling an R script instead of the bash.

#### Params

`<stan_model>` is the name of the `.stan` file to run, where the `.stan` file actually defines the bayesian model being run.
For example, `us_mobility` maps to the `stan/us_mobility.stan` file.

`<minimumDeaths>` is the cutoff for including counties in the simulation - 
only those counties with at least this many deaths get included in the simulation.

`<nIterations>` is the number of iterations to run the Stan model for. More iterations generally yields
more precise estimates with less variance, however there is a limit
as to how precise you can make your estimates.
To optimize for shortest runtime, you should run as few iterations as possible while still getting
acceptable variance and precision on your estimates.
For this model in particular, `200` seems to be the magic number beyond which 
precision doesn't increase any further.

`<stateList>` is a comma-separated list of states to include in the simulation.

### Examples

Run on all US counties which have reported at least 8000 deaths:

```sh run.sh us_mobility 8000 200 -stateList "all"```

Run on all IL and NY counties which have reported at least 150 deaths:

```sh run.sh us_mobility 150 200 -stateList "Illinois,NewYork"```

Run on all IL counties which have reported at least 15 deaths:

```sh run.sh us_mobility 15 200 -stateList "Illinois"```

### Runtime Expectations

The stan model takes a while to run.

For example, with this call: 

```sh run.sh us_mobility 8000 200 -stateList "all"```

That yielded a set of 3 counties to run on,
and that run took 83 minutes to complete.

## Inputs and Outputs

### Inputs

Data inputs to the model include:

- COVID-19 mortality data from the [jhu dataset](https://github.com/CSSEGISandData/COVID-19)
- Mobility data from [Google Mobility Reports](https://www.google.com/covid19/mobility/)

Precomputed inputs include:

- Serial interval (as described in the ICL papers)
- Fixed infection-fatality-ratio (IFR) taken from [this paper](https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(20)30243-7/fulltext), which is the same paper ICL consulted for their IFR estimates

### Outputs

Ultimately a model run results in a set of 3 visualizations per county, plus 1 visualization which includes Rt estimates from all counties.

Outputs get written to `modelOutput/figures/` like so:

```
Matts-MacBook-Pro:covid19model mattgarvin$ ls modelOutput/figures/
06037		17031		36047		Rt_All.png
Matts-MacBook-Pro:covid19model mattgarvin$ ls modelOutput/figures/17031/
Rt.png		cases.png	deaths.png
```

where the numbers in the `modelOutput/figures` directory are county IDs.

#### Example Output

Daily Cases:

![cases](exampleOutput/17031/cases.png?raw=true "Cases")

Daily Deaths:

![deaths](exampleOutput/17031/deaths.png?raw=true "Deaths")

Daily Rt:

![Rt](exampleOutput/17031/Rt.png?raw=true "Rt")

Average Rt over last 7 days for all counties included in the simulation:

![Rt_All](exampleOutput/Rt_All.png?raw=true "Rt All")

## Successes of the Model

The model appears to do a very good job of capturing trends in case and mortality for the entirety of the pandemic.

## Shortcomings and Limitations of the Model

One assumption of the model as it is currently defined is that there is no mixing between counties.
That is, the event of somebody from Cook County infecting somebody from DuPage County -
that event is not included in this model.
Since that kind of mixing is a very real and important aspect of the outbreak,
we consider it a limitation that the model has nothing to say about those mixing effects.

Another critical limitation of the model is that the IFR is fixed over time.
It's possible that the IFR has followed a downward trend since the beginning of the outbreak
as treatment options have improved, hospital capacity increased,
and maybe a larger proportion of those infected are young, healthy people
who experience severe cases much less frequently than older age groups.

It should also be noted that currently the same IFR is applied to all counties.
Although it's of course true that IFR in reality varies by location,
we don't consider this to be a signficant limitation of the model.
The reason it's not a big deal is that when testing out using county-specific IFRs,
the results were basically indistinguishable from the results achieved
by just applying the same IFR to all counties.

Finally it should be noted that there is not really a good way to validate this model.
This seems to be the case with many models of the COVID-19 outbreak.
You can't validate true case estimates, because there's no reliable number out there to validate against.
Rt, while useful and important, is an abstract concept and can't really be measured precisely or at all "in the real world".
You can compare your Rt estimates against other researchers' computed Rt estimates,
but you can't compare your Rt estimates against "observed Rt". 

With respect to deaths, it's true that this model estimates deaths very well.
However that seems to be an artifact primarily of the fact that this model is fitted to observed deaths data.
In various sensitivity analyses we tried to alter the value of Rt by a factor of 2 or 10 or 50,
expecting to see a corresponding increase in the deaths estimates.
However, we found that regardless of how we tried to affect the Rt values,
deaths estimates from the model remained basically spot-on.
The exact reason for this was never figured out completely,
but as it stands now, it appears that the model is 
very insensitive to the mobility data,
Rt always "fits" to about the same trends and values 
regardless of attempted manipulations, and the deaths estimates are always quite good.

## Misc. Comments

Be aware that [RStan](https://mc-stan.org/users/interfaces/rstan) can be tricky to install
with all its dependencies. When you run the stan model,
really all the computation actually happens through a series of C++ scripts
that get generated according to your `.stan` file.
So there are R dependencies, and then there are implicit C++ dependencies and configuration
that all need to be perfectly aligned in order for the Stan thing to happen.

Installing and running locally should not pose too great a problem,
but installing and running in a Docker container can be exceedingly tricky.
