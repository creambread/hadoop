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

function start_app() {
	cf_ssh_command $CF_JHS_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/bin/mapred --daemon start historyserver"
}

function stop_app() {
	cf_ssh_command $CF_JHS_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/bin/mapred --daemon stop historyserver"

} 

function status_app() {
	cf_ssh_status $CF_JHS_HOSTS $CF_HADOOP_USER "JobHistoryServer" "JobHistoryServer"
}

function echo_start() {
	cf_echo_start $(basename "$0") $CF_JHS_HOSTS
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
