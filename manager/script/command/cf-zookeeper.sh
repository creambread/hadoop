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

IFS_OLD="$IFS"
IFS=","
HOST_ARRAY=($CF_ZOOKEEPER_HOSTS)
IFS=$IFS_OLD

function start_app() {
	cf_ssh_command $CF_ZOOKEEPER_HOSTS $CF_HADOOP_USER "$CF_ZOOKEEPER_HOME/bin/zkServer.sh start"
}

function stop_app() {
	cf_ssh_command $CF_ZOOKEEPER_HOSTS $CF_HADOOP_USER "$CF_ZOOKEEPER_HOME/bin/zkServer.sh stop"
} 

function status_app() {
	cf_ssh_status $CF_ZOOKEEPER_HOSTS $CF_HADOOP_USER "QuorumPeerMain" "zookeeper"
}

function echo_start() {
	cf_echo_start $(basename "$0") $CF_ZOOKEEPER_HOSTS
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
