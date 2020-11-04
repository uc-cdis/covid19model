FROM debian:bullseye

# clear cache
RUN echo "clear cache"

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
	libboost-all-dev

WORKDIR /
COPY . /

# install Python dependencies
RUN pip3 install --upgrade pip==20.1.*
RUN pip3 install -r requirements.txt

WORKDIR /batch/

CMD [ "bash", "docker-run.sh" ]
