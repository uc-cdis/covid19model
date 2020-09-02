FROM debian:bullseye

RUN apt-get update && \
	apt-get install -y build-essential \
# 	wget \
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
# 	fonts-open-sans \
# 	fonts-arkpandora \
# 	fonts-adf-verana \
	gnupg2 \
	python3 \
	python3-pip \
	r-base \
	libboost-all-dev

# install Python dependencies
RUN pip3 install --upgrade pip==20.1.*
RUN pip3 install -r requirements.txt

COPY . /

WORKDIR /batch/

CMD [ "bash", "/docker-run.sh" ]
