FROM	ubuntu:18.04

ENV GRAFANA_VERSION 5.1.3
ENV INFLUXDB_VERSION 1.5.3
ENV CHRONOGRAF_VERSION 1.5.0.1

# Prevent some error messages
ENV DEBIAN_FRONTEND noninteractive

# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
RUN		apt-get -y update && apt-get -y upgrade && \
			apt-get -y install wget nginx-light supervisor curl adduser libfontconfig

# Install Grafana
RUN		wget -nv https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_${GRAFANA_VERSION}_amd64.deb && \
			dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb && rm grafana_${GRAFANA_VERSION}_amd64.deb

# Install InfluxDB
RUN		wget -nv https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
			dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# Install Chronograf
RUN		wget -nv https://dl.influxdata.com/chronograf/releases/chronograf_${CHRONOGRAF_VERSION}_amd64.deb && \
			dpkg -i chronograf_${CHRONOGRAF_VERSION}_amd64.deb && rm chronograf_${CHRONOGRAF_VERSION}_amd64.deb

# ----------------- #
#   Configuration   #
# ----------------- #

# Configure InfluxDB
ADD		influxdb/config.toml /etc/influxdb/config.toml
ADD		influxdb/run.sh /usr/local/bin/run_influxdb
# These two databases have to be created. These variables are used by set_influxdb.sh and set_grafana.sh
ENV		PRE_CREATE_DB data grafana
ENV		INFLUXDB_HOST localhost:8086
ENV   INFLUXDB_DATA_USER data
ENV   INFLUXDB_DATA_PW data
ENV		INFLUXDB_GRAFANA_USER grafana
ENV		INFLUXDB_GRAFANA_PW grafana
ENV		ROOT_PW root

# Configure Grafana
ADD   ./grafana/config.ini /etc/grafana/config.ini
ADD		grafana/run.sh /usr/local/bin/run_grafana
ADD		./configure.sh /configure.sh
ADD		./set_grafana.sh /set_grafana.sh
ADD		./set_influxdb.sh /set_influxdb.sh
RUN 	/configure.sh

# Configure Chronograf
ENV		INFLUXDB_URL http://${INFLUXDB_HOST}
ENV		INFLUXDB_USERNAME ${INFLUXDB_DATA_USER}
ENV		INFLUXDB_PASSWORD ${INFLUXDB_DATA_PW}
ENV		PUBLIC_URL http://localhost:8888

# Configure nginx and supervisord
ADD		./nginx/nginx.conf /etc/nginx/nginx.conf
ADD		./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ----------- #
#   Cleanup   #
# ----------- #

RUN		apt-get autoremove -y wget curl && \
			apt-get -y clean && \
			rm -rf /var/lib/apt/lists/* && rm /*.sh

# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE	3000

# Chronograf
EXPOSE	8888

# InfluxDB HTTP API
EXPOSE	8086

# InfluxDB HTTPS API
EXPOSE	8084

# -------- #
#   Run!   #
# -------- #

CMD		["/usr/bin/supervisord"]
