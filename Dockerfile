FROM ubuntu:focal

RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    DEBIAN_FRONTEND=noninteractive \
    apt update && apt install -y --no-install-recommends tzdata

RUN echo "postmaster: root" > /etc/aliases && \
    echo "localhost" > /etc/mailname && \
    echo postfix postfix/main_mailer_type string "No configuration" && \
    apt update && apt install -y postfix

RUN apt update && apt install -y --no-install-recommends \
    libsasl2-modules sasl2-bin rsyslog libpam-pwquality libpam-cracklib

RUN apt update && apt install -y curl telnet less nano

EXPOSE 25 587
ENV USER_SOURCE /source
WORKDIR /app
COPY . .
RUN scripts/docker/init.sh
RUN scripts/docker/sasl.sh
CMD ["/bin/bash", "/app/scripts/docker/start.sh"]