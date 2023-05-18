#!/bin/bash
set -m

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <start_active|start_standby|stop_active|stop_standby|status>"
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
	"start_active") TARGET_HOSTS=$CF_HA_HBASE_ACTIVE_HOSTS;;
	"start_standby") TARGET_HOSTS=$CF_HA_HBASE_STANDBY_HOSTS;;
	"stop_active") TARGET_HOSTS=$CF_HA_HBASE_ACTIVE_HOSTS;;
	"stop_standby") TARGET_HOSTS=$CF_HA_HBASE_STANDBY_HOSTS;;
	"status") TARGET_HOSTS=$CF_HBASE_MASTER_HOSTS;;
        *) print_usage;exit;;
esac

######### MAIN FUNCTIONS #######
function start_app() {
	cf_ssh_command $TARGET_HOSTS $CF_HBASE_USER "$CF_HBASE_HOME/bin/hbase-daemon.sh start master"
}

function stop_app() {
	cf_ssh_command $TARGET_HOSTS $CF_HBASE_USER "$CF_HBASE_HOME/bin/hbase-daemon.sh stop master"
} 

function status_app() {
	cf_ssh_status $TARGET_HOSTS $CF_HBASE_USER "HMaster" "HMaster"
}

function echo_start() {
	cf_echo_start $(basename "$0") $TARGET_HOSTS
}
function echo_end() {
	cf_echo_end ${0}
}

case $MODE in
        "start_active") echo_start;start_app;echo_end;;
        "start_standby") echo_start;start_app;echo_end;;
        "stop_active") echo_start;stop_app;echo_end;;
        "stop_standby") echo_start;stop_app;echo_end;;
        "status") echo_start;status_app;echo_end;;
        *) print_usage;;
esac
