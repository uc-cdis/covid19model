FROM debian:bullseye

# basics and python stuff
RUN apt-get update && \
	apt-get install -y build-essential \
 	wget \
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	gnupg2 \
	python3 \
	python3-pip \
	python3-pandas

# install Python dependencies
RUN pip3 install --upgrade pip==20.1.*
RUN pip3 install awscli==1.18.*

# RUN pip3 install -r requirements.txt

# R things.
RUN apt-get update && \
	apt-get install -y \
	fonts-open-sans \
	fonts-arkpandora \
	fonts-adf-verana \
	r-base \
	libboost-all-dev \
# 	r-cran-rstan \
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

RUN Rscript -e "install.packages('EnvStats', dependencies=TRUE)"
RUN Rscript -e "install.packages('BH', dependencies=TRUE)"
RUN Rscript -e "install.packages('visdat', dependencies=TRUE)"
RUN Rscript -e "install.packages('mlr3verse', dependencies=TRUE)"
RUN Rscript -e "install.packages('ranger', dependencies=TRUE)"
RUN Rscript -e "install.packages('zoo', dependencies=TRUE)"

RUN Rscript -e "install.packages('StanHeaders', dependencies=TRUE)"
RUN Rscript -e "install.packages('inline', dependencies=TRUE)"
RUN Rscript -e "install.packages('loo', dependencies=TRUE)"
RUN Rscript -e "install.packages('http://cran.r-project.org/src/contrib/Archive/rstan/rstan_2.19.3.tar.gz', repos=NULL, type='source', dependencies=TRUE)"

WORKDIR /
COPY . /

CMD [ "bash", "/docker-run.sh" ]
