FROM ubuntu:hirsute

RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && apt-get install -qy --no-install-recommends \
    curl rsyslog tzdata && \
    apt-get clean

# Postfix
RUN echo "postmaster: root" > /etc/aliases && \
    echo "localhost" > /etc/mailname && \
    echo postfix postfix/main_mailer_type string "No configuration" && \
    apt-get update -qq && apt-get install -qy --no-install-recommends \
    postfix postfix-pcre && \
    apt-get clean

# SASL Utilities
RUN apt-get update -qq && apt-get install -qy --no-install-recommends \
    libsasl2-modules libpam-pwquality libpam-cracklib pwgen && \
    apt-get clean

# Dovecot
RUN apt-get update -qq && apt-get install -qy --no-install-recommends \
    dovecot-core dovecot-imapd dovecot-lmtpd && \
    apt-get clean

# OpenDKIM, SPF, postsrsd
RUN apt-get update -qq && apt-get install -qy --no-install-recommends \
    opendkim opendkim-tools postfix-policyd-spf-python postsrsd && \
    apt-get clean

# postforward
RUN apt-get update -qq && apt-get install -qqy --no-install-recommends \
    make curl ca-certificates && \
    mkdir /tmp/pf && cd /tmp/pf && \
    curl -sL 'https://golang.org/dl/go1.17.1.linux-amd64.tar.gz' | tar xz && \
    curl -sL 'https://github.com/zoni/postforward/tarball/v1.1.1' | tar xz --strip-components=1 && \
    PATH="$PATH:/tmp/pf/go/bin" make && mv postforward /usr/sbin && \
    cd /tmp && rm -r /tmp/pf && apt-get purge -qy make && apt-get clean

# postwhite
RUN mkdir -p /usr/local/src/spf-tools && cd /usr/local/src/spf-tools && \
    curl -sL 'https://github.com/spf-tools/spf-tools/tarball/b0fd4a936' | tar xz --strip-components=1 && \
    mkdir -p /usr/local/src/postwhite && cd /usr/local/src/postwhite && \
    curl -sL 'https://github.com/owings1/postwhite/tarball/mod' | tar xz --strip-components=1

# General Utilities
RUN apt-get update -qq && apt-get install -qqy \
    psmisc curl telnet less nano ccze bash-completion busybox procmail && \
    apt-get clean

EXPOSE 25 143 587
ENV CONFIG_REPO /source
WORKDIR /source
COPY . /app
VOLUME /source
VOLUME /var/mail
VOLUME /etc/auth
RUN /app/docker/install.sh
CMD ["/bin/bash", "/app/docker/start.sh"]
