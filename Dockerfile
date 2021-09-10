FROM ubuntu:focal

RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qy --no-install-recommends tzdata && \
    apt-get clean

RUN echo "postmaster: root" > /etc/aliases && \
    echo "localhost" > /etc/mailname && \
    echo postfix postfix/main_mailer_type string "No configuration" && \
    apt-get update -qq && apt-get install -qy --no-install-recommends \
    postfix postfix-pcre rsyslog && \
    apt-get clean

RUN apt-get update -qq && apt-get install -qy --no-install-recommends \
    libpam-pwquality libpam-cracklib pwgen && \
    apt-get clean

RUN apt-get update -qq && apt-get install -qy --no-install-recommends \
    dovecot-core dovecot-imapd dovecot-lmtpd && \
    apt-get clean

RUN apt-get update -qq && apt-get install -qy --no-install-recommends \
    opendkim opendkim-tools postfix-policyd-spf-python postsrsd && \
    apt-get clean

RUN apt-get update -qq && apt-get install -qqy --no-install-recommends make curl ca-certificates && \
    mkdir /tmp/pf && cd /tmp/pf && \
    curl -sL 'https://golang.org/dl/go1.17.1.linux-amd64.tar.gz' | tar xz && \
    curl -sL 'https://github.com/zoni/postforward/tarball/v1.1.1' | tar xz --strip-components=1 && \
    PATH="$PATH:/tmp/pf/go/bin" make && mv postforward /usr/sbin && \
    cd /tmp && rm -r /tmp/pf && apt-get purge -qy make && apt-get clean

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

#RUN apt-get update && apt-get install -y --no-install-recommends libsasl2-modules sasl2-bin 