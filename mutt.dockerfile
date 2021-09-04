FROM ubuntu:focal

ENV TERM=xterm-color
ENV FORCE_COLOR=2

RUN apt update && apt install -y curl telnet less nano mutt wget