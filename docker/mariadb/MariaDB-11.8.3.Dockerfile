#++++++++++++++++++++++++++++++++++++++
# MySQL Docker container
#++++++++++++++++++++++++++++++++++++++
#
# Official images:
#
#   mariadb - MariaDB (MySQL fork) from MariaDB Foundation
#             https://hub.docker.com/r/library/mariadb/
#
#++++++++++++++++++++++++++++++++++++++

FROM mariadb:11.8.3

ADD conf/mariadb-docker.cnf /etc/mysql/conf.d/z99-docker.cnf
RUN chown mysql:mysql /etc/mysql/conf.d/z99-docker.cnf \
    && chmod 0644 /etc/mysql/conf.d/z99-docker.cnf
