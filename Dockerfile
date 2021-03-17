FROM quay.io/cdis/debian:bullseye

# install R dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	curl \
	build-essential \
	wget \
	libboost-all-dev \
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	fonts-open-sans \
	fonts-arkpandora \
	fonts-adf-verana \
	gnupg2 \
	r-base \
	r-cran-rstan \
	r-cran-tidyverse \
	r-cran-matrixstats \
	r-cran-scales \
	r-cran-gdata \
	r-cran-gridextra \
	r-cran-bayesplot \
	r-cran-svglite \
	r-cran-optparse \
	r-cran-nortest \
	r-cran-pbkrtest \
	r-cran-rcppeigen \
	r-cran-bh \
	r-cran-ggpubr \
	r-cran-cowplot \
	r-cran-isoband

RUN Rscript -e "install.packages('BH', dependencies=TRUE)"
RUN Rscript -e "install.packages('EnvStats', dependencies=TRUE)"
RUN Rscript -e "install.packages('inline', dependencies=TRUE)"
RUN Rscript -e "install.packages('loo', dependencies=TRUE)"
RUN Rscript -e "install.packages('mlr3verse', dependencies=TRUE)"
RUN Rscript -e "install.packages('ranger', dependencies=TRUE)"
RUN Rscript -e "install.packages('RcppParallel', dependencies=TRUE)"
RUN Rscript -e "install.packages('rstan', dependencies=TRUE)"
RUN Rscript -e "install.packages('StanHeaders', dependencies=TRUE)"
RUN Rscript -e "install.packages('visdat', dependencies=TRUE)"
RUN Rscript -e "install.packages('zoo', dependencies=TRUE)"
RUN Rscript -e "install.packages('http://cran.r-project.org/src/contrib/Archive/rstan/rstan_2.19.3.tar.gz', repos=NULL, type='source', dependencies=TRUE)"

# install Python dependencies
RUN apt-get update && apt-get install -y \
	python3 \
	python3-pip \
	python3-pandas
RUN pip3 install awscli==1.18.*

WORKDIR /
COPY ./covid19model /
COPY ./run-with-slack.sh ./docker-run.sh ./run.sh /

ENV MODEL_RUN_MODE stateList
ENV DEATHS_CUTOFF 10
ENV N_ITER 200
ENV STATE_LIST all
# or mode=batch, maxBatchSize=20 like in covid19model/cwl/request_body.json?

CMD [ "bash", "/run-with-slack.sh" ]
