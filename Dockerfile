FROM ubuntu:focal

RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get install -y --no-install-recommends tzdata

RUN echo "postmaster: root" > /etc/aliases && \
    echo "localhost" > /etc/mailname && \
    echo postfix postfix/main_mailer_type string "No configuration" && \
    apt-get update && apt-get install -y \
    postfix postfix-pcre rsyslog

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpam-pwquality libpam-cracklib pwgen

RUN apt-get update && apt-get install -y --no-install-recommends \
    dovecot-core dovecot-imapd dovecot-lmtpd

RUN apt-get update && apt-get install -y psmisc curl telnet less nano ccze

EXPOSE 25 143 587
ENV CONFIG_REPO /source
WORKDIR /source
COPY scripts /app/scripts
VOLUME /source
VOLUME /home/email
VOLUME /etc/auth
RUN /app/scripts/docker/install.sh
CMD ["/bin/bash", "/app/scripts/docker/start.sh"]

#RUN apt-get update && apt-get install -y --no-install-recommends \
#    libsasl2-modules sasl2-bin 