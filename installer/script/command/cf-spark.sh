#!/bin/bash
set -m

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <start|stop|status>"
}
function endScript() {
	echo "end script"
	exit;
}

if [ $# != 1 ]; then
	print_usage
	exit;
fi
MODE=$1

case $MODE in
        "start") TARGET_HOSTS=$CF_SPARK_MASTER_HOSTS;;
        "stop") TARGET_HOSTS=$CF_SPARK_MASTER_HOSTS;;
        "status") TARGET_HOSTS=$CF_SPARK_INSTALL_HOSTS;;
        *) TARGET_HOSTS=$CF_SPARK_INSTALL_HOSTS;;
esac


IFS_OLD="$IFS"
IFS=","
HOST_ARRAY=($CF_SPARK_MASTER_HOSTS)
IFS=$IFS_OLD

function start_app() {
	cf_ssh_command $CF_SPARK_MASTER_HOSTS $CF_SPARK_USER "$CF_SPARK_HOME/sbin/start-all.sh"
}

function stop_app() {
	cf_ssh_command $CF_SPARK_MASTER_HOSTS $CF_SPARK_USER "$CF_SPARK_HOME/sbin/stop-all.sh"
} 

function status_app() {
	cf_ssh_status $CF_SPARK_MASTER_HOSTS $CF_SPARK_USER "Master" "Master"
	cf_ssh_status $CF_SPARK_SLAVE_HOSTS $CF_SPARK_USER "Worker" "Worker"
}

function echo_start() {
	cf_echo_start $(basename "$0") $TARGET_HOSTS
}
function echo_end() {
	cf_echo_end ${0}
}

case $MODE in
        "start") echo_start;start_app;echo_end;;
        "stop") echo_start;stop_app;echo_end;;
        "status") echo_start;status_app;echo_end;;
        *) print_usage;;
esac
