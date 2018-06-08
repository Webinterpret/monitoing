#!/bin/bash

set -m

CONFIG_FILE="/etc/grafana/config.ini"

echo "=> Starting Grafana ..."
exec /usr/sbin/grafana-server --homepath /usr/share/grafana --config ${CONFIG_FILE}
