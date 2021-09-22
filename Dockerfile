FROM ubuntu:focal

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
COPY scripts /app/scripts
VOLUME /source
VOLUME /var/mail
VOLUME /etc/auth
RUN /app/scripts/docker/install.sh
CMD ["/bin/bash", "/app/scripts/docker/start.sh"]

# https://www.linuxfromscratch.org/blfs/view/svn/server/postfix.html

#src/util/sys_defs.h:
# define NO_CLOSEFROM

# # build-essential libdb-dev libssl-dev \
#      libevent-dev \
#      autoconf automake autopoint autotools-dev bsdextrautils debhelper debugedit default-libmysqlclient-dev dh-autoreconf dh-strip-nondeterminism distro-info-data dwz gettext gettext-base
#   groff-base html2text icu-devtools intltool-debian libarchive-zip-perl libcdb-dev libcdb1 libdebhelper-perl libdw1 libelf1 libfile-stripnondeterminism-perl libglib2.0-0 libicu-dev libldap2-dev
#   liblmdb-dev liblmdb0 libmysqlclient-dev libmysqlclient21 libpcre16-3 libpcre3-dev libpcre32-3 libpcrecpp0v5 libpipeline1 libpq-dev libpq5 libsasl2-dev libsigsegv2 libsqlite3-dev
#   libsub-override-perl libtool libuchardet0 libxml2 libzstd-dev lsb-release m4 man-db mysql-common pkg-config po-debconf zlib1g-dev

# # https://archive.mgm51.com/mirrors/postfix-source/official/postfix-3.6.2.tar.gz
# 
# make CCARGS="-DUSE_TLS -I/usr/include/openssl/                     \
#              -DUSE_SASL_AUTH" \
#      AUXLIBS="-lssl -lcrypto"                              \
#      makefiles &&
# make

# cyrus
#RUN apt-get update && apt-get install -y --no-install-recommends libsasl2-modules sasl2-bin 