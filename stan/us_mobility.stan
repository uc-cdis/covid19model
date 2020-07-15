data {
  int <lower=1> M; // number of countries
  int <lower=1> N0; // number of days for which to impute infections
  int<lower=1> N[M]; // days of observed data for country m. each entry must be
  real<lower=0> x[N]; // index of days (starting at 1)
  int cases[N,M]; // reported cases
  int deaths[N, M]; // reported deaths -- the rows with i > N contain -1 and should be ignored
  matrix[N, M] f; // h * s
  int EpidemicStart[M];
  real SI[N]; // fixed pre-calculated SI using emprical data from Neil
  // new data for mobility //
  int <lower=1> P_partial_county; // number of covariates for partial pooling (state-level effects)
  matrix[N, P_partial_county] X_partial_county[M];
  int W; // number of weeks for weekly effects
  int week_index[M,N];
}

parameters {
  real<lower=0> mu[M]; // intercept for Rt
  vector[P_partial_county] alpha_county[M];
  real<lower=0> kappa;
  real<lower=0> y[M];
  real<lower=0> phi;
  real<lower=0> tau;
  // new parameters
  real<lower=0> gamma_county;
  matrix[W+1,M] weekly_effect;
  real<lower=0, upper=1> weekly_rho;
  real<lower=0, upper=1> weekly_rho1;
  real<lower=0> weekly_sd;

}

transformed parameters {
  real convolution;
  matrix[N, M] prediction = rep_matrix(0,N,M);
  matrix[N, M] E_deaths  = rep_matrix(0,N,M);
  matrix[N, M] Rt = rep_matrix(0,N,M);
  for (m in 1:M){
    prediction[1:N0,m] = rep_vector(y[m],N0); // learn the number of cases in the first N0 days
    Rt[,m] = mu[m] * 2 * inv_logit(-X_partial_county[m] * alpha_county[m] - weekly_effect[week_index[m],m]);    
    E_deaths[1, m]= 1e-9;
    for (i in 2:N){
      E_deaths[i,m]= 0;
      for(j in 1:(i-1)){
        E_deaths[i,m] += prediction[j,m]*f[i-j,m];
      }
    }
  }
}

model {
  tau ~ exponential(0.03);
  gamma_county ~ normal(0,.5);
  weekly_sd ~ normal(0,0.2);
  weekly_rho ~ normal(0.8, 0.05);
  weekly_rho1 ~ normal(0.1, 0.05);
  kappa ~ normal(0,0.5);
  mu ~ normal(3.28, kappa); // citation: https://academic.oup.com/jtm/article/27/2/taaa021/5735319
  phi ~ normal(0,5);
  for (m in 1:M) {
      alpha_county[m] ~ normal(0,gamma_county);
      y[m] ~ exponential(1/tau);
      weekly_effect[3:(W+1), m] ~ normal(weekly_effect[2:W,m]* weekly_rho + weekly_effect[1:(W-1),m]* weekly_rho1, 
                                            weekly_sd *sqrt(1-pow(weekly_rho,2)-pow(weekly_rho1,2) - 2 * pow(weekly_rho,2) * weekly_rho1/(1-weekly_rho1)));
      for(i in EpidemicStart[m]:N[m]){
        deaths[i,m] ~ neg_binomial_2(E_deaths[i,m],phi); 
      }
  }
  weekly_effect[2, ] ~ normal(0,weekly_sd *sqrt(1-pow(weekly_rho,2)-pow(weekly_rho1,2) - 2 * pow(weekly_rho,2) * weekly_rho1/(1-weekly_rho1)));
  weekly_effect[1, ] ~ normal(0, 0.01);
}

