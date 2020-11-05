FROM debian:bullseye

# clear cache
RUN echo "clear the cache"

# install R dependencies
RUN apt-get update && \
	apt-get install -y build-essential \
	wget \
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	fonts-open-sans \
	fonts-arkpandora \
	fonts-adf-verana \
	gnupg2 \
	python3 \
	python3-pip \
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

RUN apt-get update && \
	apt-get install -y libboost-all-dev

RUN Rscript -e "install.packages('EnvStats', dependencies=TRUE)"
RUN Rscript -e "install.packages('BH', dependencies=TRUE)"
RUN Rscript -e "install.packages('visdat', dependencies=TRUE)"
RUN Rscript -e "install.packages('mlr3verse', dependencies=TRUE)"
RUN Rscript -e "install.packages('ranger', dependencies=TRUE)"
RUN Rscript -e "install.packages('zoo', dependencies=TRUE)"
RUN Rscript -e "install.packages('rstan', dependencies=TRUE)"

# install Python dependencies
RUN pip3 install --upgrade pip==20.1.*
RUN pip3 install awscli==1.18.*

WORKDIR /
COPY . /

RUN pip3 install -r requirements.txt

CMD [ "bash", "/docker-run.sh" ]
