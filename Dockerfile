FROM ubuntu:focal

RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    DEBIAN_FRONTEND=noninteractive \
    apt update && apt install -y --no-install-recommends tzdata

RUN echo "postmaster: root" > /etc/aliases && \
    echo "localhost" > /etc/mailname && \
    echo postfix postfix/main_mailer_type string "No configuration" && \
    apt update && apt install -y postfix

RUN apt update && apt install -y --no-install-recommends \
    dovecot-core dovecot-imapd dovecot-lmtpd

RUN apt update && apt install -y --no-install-recommends \
    libsasl2-modules sasl2-bin rsyslog libpam-pwquality libpam-cracklib

RUN apt update && apt install -y curl telnet less nano

EXPOSE 25 587
ENV CONFIG_REPO /source
WORKDIR /app
COPY . .
VOLUME /source
VOLUME /home
RUN scripts/docker/init.sh
RUN scripts/docker/sasl.sh
RUN scripts/docker/dovecot.sh
CMD ["/bin/bash", "/app/scripts/docker/start.sh"]