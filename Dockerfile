FROM rocker/r-ver:latest

RUN R -e "install.packages(c('desc', 'remotes'))"

COPY tools/bumpercar.R /usr/local/bin/bumpercar.R
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
