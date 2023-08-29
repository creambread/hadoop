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

######### HOST SELECTED ########
case $MODE in
	"start") TARGET_HOSTS=$CF_HBASE_REGION_HOSTS;;
	"stop") TARGET_HOSTS=$CF_HBASE_REGION_HOSTS;;
	"status") TARGET_HOSTS=$CF_HBASE_REGION_HOSTS;;
        *) print_usage;exit;;
esac

######### MAIN FUNCTIONS #######
function start_app() {
	cf_ssh_command $TARGET_HOSTS $CF_HBASE_USER "$CF_HBASE_HOME/bin/hbase-daemon.sh start regionserver"
}

function stop_app() {
	cf_ssh_command $TARGET_HOSTS $CF_HBASE_USER "$CF_HBASE_HOME/bin/hbase-daemon.sh stop regionserver"
} 

function status_app() {
	cf_ssh_status $TARGET_HOSTS $CF_HBASE_USER "HRegionServer" "HRegionServer"
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
