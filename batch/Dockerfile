FROM debian:bullseye

# FROM r-base:4.0.3

# clear cache
# RUN echo "clear cache"

RUN apt-get update && \
	apt-get install -y build-essential \
 	wget \
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	gnupg2 \
	python3 \
	python3-pip \
 	r-base \
	libboost-all-dev \
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

RUN Rscript -e "install.packages('EnvStats', dependencies=TRUE)"
RUN Rscript -e "install.packages('BH', dependencies=TRUE)"
RUN Rscript -e "install.packages('visdat', dependencies=TRUE)"
RUN Rscript -e "install.packages('mlr3verse', dependencies=TRUE)"
RUN Rscript -e "install.packages('ranger', dependencies=TRUE)"
RUN Rscript -e "install.packages('zoo', dependencies=TRUE)"

WORKDIR /
COPY . /

# install Python dependencies
RUN pip3 install --upgrade pip==20.1.*
RUN pip3 install -r requirements.txt
RUN pip3 install awscli==1.18.*

WORKDIR /batch/

CMD [ "bash", "docker-run.sh" ]
