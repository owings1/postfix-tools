#!/bin/bash

shopt -s expand_aliases

if [[ -e /etc/postfix/environment ]]; then
    . /etc/postfix/environment
fi

[[ -n "$CONFIG_REPO" ]] || CONFIG_REPO=/opt/config
[[ -n "$DKIM_KEYS_DIR" ]] || DKIM_KEYS_DIR=/opt/dkim
[[ -n "$AUTH_DIR" ]] || AUTH_DIR=/opt/auth
[[ -n "$AUTH_ALG" ]] || AUTH_ALG=SHA512-CRYPT
[[ -n "$AUTH_UID" ]] || AUTH_UID=600
[[ -n "$AUTH_GID" ]] || AUTH_GID=515
[[ -n "$AUTH_EMAILDIR" ]] || AUTH_EMAILDIR=/var/mail

alias doveadm=/usr/bin/doveadm
alias doveconf=/usr/bin/doveconf
alias dovecot=/usr/sbin/dovecot
alias postfix=/usr/sbin/postfix
alias postmap=/usr/sbin/postmap
alias postconf=/usr/sbin/postconf
alias service=/usr/sbin/service

is_term() {
    [[ -t 1 ]]
}

is_color() {
    [[ "$FORCE_COLOR" -gt 1 ]] || is_term
}

debug() {
    if [[ ! -z "$DEBUG" ]]; then
        echo "${cBlueLight}Debug${cReset} $@" >&2
    fi
}

abs() {
    echo `cd "$1" && pwd`
}

date_path() {
    date +"%Y-%m-%d-%H-%M-%s"
}

is_dovecot() {
    command -v /usr/sbin/dovecot > /dev/null
}

is_spf() {
    command -v /usr/bin/policyd-spf > /dev/null
}

is_srsd() {
    command -v /usr/sbin/postsrsd > /dev/null
}

is_dkim() {
    command -v /usr/sbin/opendkim > /dev/null
}

is_dkim_enabled() {
    [[ ! -z "$DKIM_ENABLED" ]] && is_dkim
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
        systemctl is-active -q "$1"
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
    elif is_docker && [[ "$1" = rsyslog ]]; then
        killall rsyslogd
    else
        service "$1" stop
    fi
}

service_restart() {
    if is_systemd ; then
        systemctl restart "$1"
    else
        service "$1" restart
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
        echo "Bad password: $rxdesc" >&2
        return 1
    fi
}

passwd_vmbx() {
    local pwdfile="$1"
    local vmbxfile="$(abs "$(dirname "$pwdfile")")/users.vmbx"
    grep -vE '^\s*#' "$pwdfile" \
        | awk -F: '{print $1" "$6}' \
        | { grep -vE '\s.{0,1}$' || true ; } \
        > "$vmbxfile" &&
    postmap "$vmbxfile" &&
    echo "Updated $(basename "$vmbxfile")"
}

passwd_tlsdb() {
    local pwdfile="$1"
    local tlsfile="$(abs "$(dirname "$pwdfile")")/users.tls"
    grep -vE '^\s*#' "$pwdfile" \
        | sed 's#:.*#/valid::::::#' \
        > "$tlsfile" &&
    echo "Updated $(basename "$tlsfile")"
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
        getent services "$name" | awk '{print $2}' | sed 's-/.*--'
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
    tee "$@" > /dev/null
}

if is_color; then
    cBlue="$(printf '\x1b[0;34m')"
    cBlueLight="$(printf '\x1b[1;34m')"
    cCyan="$(printf '\x1b[0;36m')"
    cCyanLight="$(printf '\x1b[1;36m')"
    cGreen="$(printf '\x1b[0;32m')"
    cGreenLight="$(printf '\x1b[1;32m')"
    cGrey="$(printf '\x1b[1;30m')"
    cGreyLight="$(printf '\x1b[0;37m')"
    cMagenta="$(printf '\x1b[0;35m')"
    cMagentaLight="$(printf '\x1b[1;35m')"
    cOrange="$(printf '\x1B[38;2;255;165;0m')"
    cOrangeLight="$(printf '\x1B[38;2;255;165;0m\x1B[1m')"
    cRed="$(printf '\x1b[0;31m')"
    cRedLight="$(printf '\x1b[1;31m')"
    cYellow="$(printf '\x1b[0;33m')"
    cYellowLight="$(printf '\x1b[1;33m')"
    cWhite="$(printf '\x1b[1;37m')"
    cWhiteLight="$(printf '\x1b[37;1m')"
    cReset="$(printf '\x1b[0m')"
    cDim="$(printf '\x1b[2m')"
    cUndim="$(printf '\x1b[22m')"
fi
uCheck="√" # \xe2\x88\x9a
uCaret="❯"
uCaretr="❮"

color_curl_smtp() {
    local line scope lcolor
    local cmds='STARTTLS|EHLO|AUTH DIGEST-MD5|AUTH PLAIN|AUTH LOGIN|MAIL FROM|RCPT TO|DATA|\*|QUIT'
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
    return "$status"
}

declare -a APP_LOGS
if is_docker ; then
    APP_LOGS+=(coordinator.log syslog)
fi
APP_LOGS+=(auth.log reconfigure.log)
if is_dovecot; then
    APP_LOGS+=(
        dovecot.dbg
        dovecot.err
        dovecot.log
    )
fi
if is_spf ; then
    APP_LOGS+=(
        policy.dbg
        policy.err
        policy.log
    )
fi
if is_dkim_enabled ; then
    APP_LOGS+=(
        dkim.dbg
        dkim.err
        dkim.log
    )
fi
APP_LOGS+=(
    postfix.dbg
    postfix.err
    postfix.log
)

if [[ ! -e "$CONFIG_REPO" ]]; then
    echo "${cYellowLight}WARNING${cReset} $CONFIG_REPO does not exist" >&2
fi
