#!/bin/bash

shopt -s expand_aliases

alias doveadm=/usr/bin/doveadm
alias doveconf=/usr/bin/doveconf
alias dovecot=/usr/sbin/dovecot
alias postfix=/usr/sbin/postfix
alias postmap=/usr/sbin/postmap
alias postconf=/usr/sbin/postconf
alias service=/usr/sbin/service
if [[ -t 0 ]]; then
    alias is_term=true
else
    alias is_term=false
fi

if [[ "$FORCE_COLOR" < 1 ]]; then
    alias is_color=is_term
else
    alias is_color=true
fi

abs() {
    echo `cd "$1" && pwd`
}

date_path() {
    date +"%Y-%m-%d-%H-%M-%s"
}

is_dovecot() {
    command -v /usr/sbin/dovecot > /dev/null
}

is_saslauthd() {
    command -v /usr/sbin/saslauthd > /dev/null
}

is_firstrun() {
    [[ ! -e /etc/first-run ]]
}

is_docker() {
    grep -sq 'docker\|lxc' /proc/1/cgroup
}

is_systemd() {
    pidof systemd > /dev/null
}

service_up() {
    if is_systemd; then
        systemctl is-active "$1" > /dev/null
    else
        service "$1" status
    fi
}

service_reload() {
    if is_systemd ; then
        systemctl reload "$1"
    else
        service "$1" reload
    fi
}

service_start() {
    if is_systemd ; then
        systemctl start "$1"
    else
        service "$1" start
    fi
}

service_stop() {
    if is_systemd ; then
        systemctl stop "$1"
    elif is_docker && [[ "$1" == rsyslog ]]; then
        killall rsyslogd
    else
        service "$1" stop
    fi
}

dovecot_reload() {
    if is_dovecot; then
        echo "Checking if dovecot is up"
        if service_up dovecot; then
            echo "Reloading dovecot config"
            service_reload dovecot
            echo "Reloaded dovecot config"
        else
            echo "Dovecot is not running"
        fi
    fi
}

postfix_reload() {
    echo "Checking if postfix is up"
    if service_up postfix; then
        echo "Reloading postfix config"
        service_reload postfix
        echo "Reloaded postfix config"
    else
        echo "Postfix is not running"
    fi
}

check_okpassword() {
    local pwd="$1"
    local raw="$(cracklib-check <<< "$pwd")"
    if [[ "$(awk '{print $NF}' <<< "$raw")" != 'OK' ]]; then
        local idx="$(expr "${#pwd}" + 3)"
        echo "Bad password: $(cut "-c$idx-" <<< "$raw")" >&2
        return 1
    fi
    local regex='^(?=.*[A-Z].*[A-Z])(?=.*[!@#$&*)(}{])(?=.*[0-9].*[0-9])(?=.*[a-z].*[a-z].*[a-z]).{8,}$'
    local rxdesc='Password must be at least 12 chars, two uppercase, three lower, two digits, one special'
    if ! grep -qP "$regex" <<< "$pwd" ; then
        echo "Bad password: " >&2
        return 1
    fi
}

passwd_map() {
    local pwdfile="$1"
    local mapfile="$pwdfile.map"
    sed 's/:.*/ ./' "$pwdfile" > "$mapfile" &&
    postmap "$mapfile" &&
    echo "Updated passwd map"
}

md5cmp() {
    [[ -e "$1" ]] &&
    [[ -e "$2" ]] &&
    [[ "$(md5sum < "$1")" = "$(md5sum < "$2")" ]]
}

port_number() {
    local name="$1"
    if [[ "$name" =~ ^[0-9]+$ ]]; then
        echo "$name"
    else
        getent services "$name" | awk '{print $2}' | sed s-/.*--
    fi
}

postfix_smtp_ports() {
    postconf -F '*/inet/command' | grep -P ' = smtpd($|\s)' | sed 's-/.*--' |
    while read port; do port_number "$port"; done
}

pushdq() {
    pushd "$1" > /dev/null
}

popdq() {
    popd > /dev/null
}

teeq() {
    tee $@ > /dev/null
}

if is_color; then
    cReset="$(printf '\x1b[0m')"
    cRed="$(printf '\x1b[0;31m')"
    cGreen="$(printf '\x1b[0;32m')"
    cBlue="$(printf '\x1b[0;34m')"
    cMagenta="$(printf '\x1b[0;35m')"
    cCyan="$(printf '\x1b[0;36m')"
    cCyanLight="$(printf '\x1b[1;36m')"
    cGreyLight="$(printf '\x1b[0;37m')"
    cGrey="$(printf '\x1b[1;30m')"
    cRedLight="$(printf '\x1b[1;31m')"
    cGreenLight="$(printf '\x1b[1;32m')"
    cYellow="$(printf '\x1b[0;33m')"
    cYellowLight="$(printf '\x1b[1;33m')"
    cBlueLight="$(printf '\x1b[1;34m')"
    cMagentaLight="$(printf '\x1b[1;35m')"
    cWhite="$(printf '\x1b[1;37m')"
    cWhiteLight="$(printf '\x1b[37;1m')"
    cDim="$(printf '\x1b[2m')"
    cUndim="$(printf '\x1b[22m')"
fi
uCheck="√" # \xe2\x88\x9a
uCaret="❯"
uCaretr="❮"

color_curl_smtp() {
    local line scope lcolor
    local cmds='STARTTLS|EHLO|AUTH DIGEST-MD5|AUTH LOGIN|MAIL FROM|RCPT TO|DATA|\*|QUIT'
    while read line; do
        case "${line:0:1}" in
            '<') scope=recv ; lcolor="$cCyan" ;;
            '>') scope=send ; lcolor="$cMagenta" ;;
            '{' | '}') scope=bytes ; lcolor="$cDim" ;;
            '*') scope=info ; lcolor="$cYellowLight$cDim" ;;
            *) scope= ; lcolor="$cReset" ;;
        esac
        if [[ "$scope" = send ]]; then
            line="$uCaret $(sed -E \
                -e "s/($cmds)/${cMagentaLight}\1${lcolor}/g" \
                <<< "${line:2}")"
        elif [[ "$scope" = recv ]]; then
            # https://www.iana.org/assignments/smtp-enhanced-status-codes/smtp-enhanced-status-codes.xhtml#smtp-enhanced-status-codes-3
            # https://en.wikipedia.org/wiki/List_of_SMTP_server_return_codes
            line="$uCaretr $(sed -E \
                -e "s/(2[0-9]{2} [0-9.]+)/${cGreenLight}\1${lcolor}/" \
                -e "s/(4[0-9]{2} [0-9.]+)/${cYellowLight}\1${lcolor}/" \
                -e "s/(5[0-9]{2} [0-9.]+)/${cRedLight}\1${lcolor}/" \
                -e "s/Ok: (queued) as/Ok: ${cGreen}\1${lcolor} as/" \
                -e "s/(Ok|3[0-9]{2} )/${cCyanLight}\1${lcolor}/" \
                <<< "${line:2}")"
        elif [[ "$scope" = info ]]; then
            line="  $(sed -E \
                -e "s/(SSL certificate verify ok)/${cGreen}\1${lcolor}/" \
                    <<< "${line:2}")"
        elif [[ "$scope" = bytes ]]; then
            line="  ${line:0}"
        fi
        line="$lcolor$line$cReset"
        echo "$line"
    done
}

color_curl_smtp_status() {
    local status="$1"
    if [[ "$status" = 0 ]]; then
        echo "${cGreenLight}${uCheck} ${cWhiteLight}Email sent${cReset}"
    else
        echo "${cRedLight}FAIL${cReset} curl exited with status ${cRedLight}${status}${cReset}"
    fi
}

if is_saslauthd; then
    SASL_SPOOL="/var/spool/postfix/var/run/saslauthd"
fi

declare -a APP_LOGS
if is_docker ; then
    APP_LOGS+=(coordinator.log syslog)
fi
APP_LOGS+=(auth.log)
if is_dovecot; then
    APP_LOGS+=(
        dovecot.debug
        dovecot.log
        dovecot.err
    )
fi
APP_LOGS+=(
    postfix.debug
    postfix.log
    postfix.err
    reconfigure.log
)
if [[ -z "$CONFIG_REPO" ]]; then
    CONFIG_REPO="/etc/postfix/repo"
fi

if [[ ! -e "$CONFIG_REPO" ]]; then
    echo "${cYellowLight}WARNING${cReset} $CONFIG_REPO does not exist" >&2
    return 1
fi