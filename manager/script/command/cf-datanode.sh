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
	cf_ssh_command $CF_DATANODE_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/bin/hdfs --daemon start datanode"
}

function stop_app() {
	cf_ssh_command $CF_DATANODE_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/bin/hdfs --daemon stop datanode"
} 

function status_app() {
	cf_ssh_status $CF_DATANODE_HOSTS $CF_HADOOP_USER "DataNode" "DataNode"
}

function echo_start() {
	cf_echo_start $(basename "$0") $CF_DATANODE_HOSTS
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
