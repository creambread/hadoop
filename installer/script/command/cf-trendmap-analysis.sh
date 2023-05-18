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
	cf_ssh_command $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "$CF_TRENDMAP_HOME/Trendmap2/tm2analysis.sh start all"
}

function stop_app() {
	cf_ssh_command $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "$CF_TRENDMAP_HOME/Trendmap2/tm2analysis.sh stop all"
} 

function status_app() {
	cf_ssh_status_ps $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "ma_daemon_zmq" "ma"
	cf_ssh_status_ps $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "TrM_server_daemon_zmq" "tm"
}

function echo_start() {
	cf_echo_start $(basename "$0") $CF_TRENDMAP_ANALYSIS_HOSTS
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

exit;
