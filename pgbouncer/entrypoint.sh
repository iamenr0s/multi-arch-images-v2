#!/bin/sh
PG_LOG=/var/log/pgbouncer
PG_CONFIG_DIR=/etc/pgbouncer
PG_USER=postgres

if [ ! -f ${PG_CONFIG_DIR}/pgbouncer.ini ]; then
 echo "create pgbouncer config in ${PG_CONFIG_DIR}"
 mkdir -p ${PG_CONFIG_DIR}

 printf "\
#pgbouncer.ini
[databases]
* = host=${DB_HOST:?"Setup pgbouncer config error! You must set DB_HOST env"} \
port=${DB_PORT:-5432} ${DB_USER:+user=${DB_USER}} \
${DB_PASSWORD:+password=${DB_PASSWORD}}

[pgbouncer]
${LOGFILE:+logfile = ${LOGFILE}\n}\
${PIDFILE:+pidfile = ${PIDFILE}\n}\
listen_addr = ${LISTEN_ADDR:-0.0.0.0}
${LISTEN_PORT:+listen_port = ${LISTEN_PORT}\n}\
${UNIX_SOCKET_DIR:+unix_socket_dir = ${UNIX_SOCKET_DIR}\n}\
${USER:+user = ${USER}\n}\
${AUTH_FILE:+auth_file = ${AUTH_FILE}\n}\
auth_type = ${AUTH_TYPE:-any}
${POOL_MODE:+pool_mode = ${POOL_MODE}\n}\
${MAX_CLIENT_CONN:+max_client_conn = ${MAX_CLIENT_CONN}\n}\
${DEFAULT_POOL_SIZE:+default_pool_size = ${DEFAULT_POOL_SIZE}\n}\
${MIN_POOL_SIZE:+min_pool_size = ${MIN_POOL_SIZE}\n}\
${RESERVE_POOL_SIZE:+reserve_pool_size = ${RESERVE_POOL_SIZE}\n}\
${MAX_DB_CONNECTIONS:+max_db_connections = ${MAX_DB_CONNECTIONS}\n}\
ignore_startup_parameters = ${IGNORE_STARTUP_PARAMETERS:-extra_float_digits}
admin_users = ${ADMIN_USERS:-postgres}
${STATS_USERS:+stats_users = ${STATS_USERS}\n}\
${SERVER_RESET_QUERY:+server_reset_query = ${SERVER_RESET_QUERY}\n}\
${SERVER_LIFETIME:+server_lifetime = ${SERVER_LIFETIME}\n}\
${SERVER_IDLE_TIMEOUT:+server_idle_timeout = ${SERVER_IDLE_TIMEOUT}\n}\
${CLIENT_LOGIN_TIMEOUT:+client_login_timeout = ${CLIENT_LOGIN_TIMEOUT}\n}\
${CLIENT_TLS_SSLMODE:+client_tls_sslmode = ${CLIENT_TLS_SSLMODE}\n}\
${CLIENT_TLS_KEY_FILE:+client_tls_key_file = ${CLIENT_TLS_KEY_FILE}\n}\
${CLIENT_TLS_CERT_FILE:+client_tls_cert_file = ${CLIENT_TLS_CERT_FILE}\n}\
${CLIENT_TLS_CA_FILE:+client_tls_ca_file = ${CLIENT_TLS_CA_FILE}\n}\
${SERVER_TLS_SSLMODE:+server_tls_sslmode = ${SERVER_TLS_SSLMODE}\n}\
${SERVER_TLS_CA_FILE:+server_tls_ca_file = ${SERVER_TLS_CA_FILE}\n}\
${SERVER_TLS_KEY_FILE:+server_tls_key_file = ${SERVER_TLS_KEY_FILE}\n}\
${SERVER_TLS_CERT_FILE:+server_tls_cert_file = ${SERVER_TLS_CERT_FILE}\n}\
################## end file ##################
" > ${PG_CONFIG_DIR}/pgbouncer.ini
fi

adduser ${PG_USER}
mkdir -p ${PG_LOG}
chmod -R 755 ${PG_LOG}
chown -R ${PG_USER}:${PG_USER} ${PG_LOG}

if [ -z $QUIET ]; then
 cat ${PG_CONFIG_DIR}/pgbouncer.ini
fi
echo "Starting pgbouncer..."
exec /pgbouncer/bin/pgbouncer ${QUIET:+-q} -u ${PG_USER} ${PG_CONFIG_DIR}/pgbouncer.ini
