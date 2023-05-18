#!/bin/bash
set -m

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <start_active|start_standby|stop_active|stop_standby|format_active|format_standby|status>"
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
        "start_active") TARGET_HOSTS=$CF_HA_ACTIVE_HOSTS;;
        "start_standby") TARGET_HOSTS=$CF_HA_STANDBY_HOSTS;;
        "stop_active") TARGET_HOSTS=$CF_HA_ACTIVE_HOSTS;;
        "stop_standby") TARGET_HOSTS=$CF_HA_STANDBY_HOSTS;;
        "format_active") TARGET_HOSTS=$CF_HA_ACTIVE_HOSTS;;
        "format_standby") TARGET_HOSTS=$CF_HA_STANDBY_HOSTS;;
        "status") TARGET_HOSTS=$CF_HA_ZKFC_HOSTS;;
        *) TARGET_HOSTS=$CF_HA_ZKFC_HOSTS;;
esac

function start_app() {
	cf_ssh_command $TARGET_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/bin/hdfs --daemon start zkfc"
}

function stop_app() {
	cf_ssh_command $TARGET_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/bin/hdfs --daemon stop zkfc"
}

function format_app() {
	cf_ssh_command $TARGET_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/bin/hdfs zkfc -formatZK"
}

function status_app() {
	cf_ssh_status $CF_HA_ZKFC_HOSTS $CF_HADOOP_USER "DFSZKFailoverController" "DFSZKFailoverController"
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
        "format_active") echo_start;format_app;echo_end;;
        "format_standby") echo_start;format_app;echo_end;;
        "status") echo_start;status_app;echo_end;;
        *) print_usage;;
esac
