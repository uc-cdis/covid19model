FROM debian:bullseye

RUN apt-get update && \
	apt-get install -y build-essential \
	r-base \
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	gnupg2 \
    libboost-all-dev

WORKDIR /
COPY . /

WORKDIR /batch

CMD [ "bash", "/docker-run.sh" ]
