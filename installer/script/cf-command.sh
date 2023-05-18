#!/bin/bash
set -m

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
#ENV_DIR=${CURR_DIR%/*}
ENV_DIR=${CURR_DIR}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <start|stop|status> <all|hadoop|hbase|spark|trendmap>"
        echo " "
        echo "all	: <mode> all system"
        echo "hadoop	: <mode> hadoop & zookeeper system"
        echo "hbase	: <mode> hbase system"
        echo "spark	: <mode> spark system"
        echo "hadoop	: <mode> trendmap system"
	echo " "

}
function endScript() {
	echo "end script"
	exit;
}

if [ $# != 2 ]; then
	print_usage
	exit;
fi

MODE=$1
TARGET=$2

function start_app() {
	case $TARGET in
		"all")
                $CURR_DIR/command/cf-zookeeper.sh start
                $CURR_DIR/command/cf-journalnode.sh start
                $CURR_DIR/command/cf-namenode.sh start_active
                $CURR_DIR/command/cf-namenode.sh start_standby
                $CURR_DIR/command/cf-zkfc.sh start_active
                $CURR_DIR/command/cf-zkfc.sh start_standby
                $CURR_DIR/command/cf-historyserver.sh start
                $CURR_DIR/command/cf-resourcemanager.sh start
                $CURR_DIR/command/cf-nodemanager.sh start
                $CURR_DIR/command/cf-datanode.sh start

		if [ "${CF_HBASE_USE}" == "TRUE" ]; then
                	$CURR_DIR/command/cf-hmaster.sh start_active
        	        $CURR_DIR/command/cf-hmaster.sh start_standby
	                $CURR_DIR/command/cf-regionserver.sh start
		fi

		if [ "${CF_SPARK_USE}" == "TRUE" ]; then
	                $CURR_DIR/command/cf-spark.sh start
		fi
                $CURR_DIR/command/cf-trendmap-api.sh start
                $CURR_DIR/command/cf-trendmap-analysis.sh start		
		;;
		"hadoop")
                $CURR_DIR/command/cf-zookeeper.sh start		
                $CURR_DIR/command/cf-journalnode.sh start
                $CURR_DIR/command/cf-namenode.sh start_active
                $CURR_DIR/command/cf-namenode.sh start_standby
                $CURR_DIR/command/cf-zkfc.sh start_active
                $CURR_DIR/command/cf-zkfc.sh start_standby
                $CURR_DIR/command/cf-historyserver.sh start
                $CURR_DIR/command/cf-resourcemanager.sh start
                $CURR_DIR/command/cf-nodemanager.sh start
                $CURR_DIR/command/cf-datanode.sh start
		;;
		"hbase")
		$CURR_DIR/command/cf-hmaster.sh start_active
		$CURR_DIR/command/cf-hmaster.sh start_standby
		$CURR_DIR/command/cf-regionserver.sh start
		;;
		"spark")
		$CURR_DIR/command/cf-spark.sh start
		;;
		"trendmap")
		$CURR_DIR/command/cf-trendmap-api.sh start
		$CURR_DIR/command/cf-trendmap-analysis.sh start
		$CURR_DIR/command/cf-trendmap-admintool.sh start
		;;
	esac
}

function stop_app() {
        case $TARGET in
                "all")
                if [ "${CF_HBASE_USE}" == "TRUE" ]; then
                        $CURR_DIR/command/cf-regionserver.sh stop
                        $CURR_DIR/command/cf-hmaster.sh stop_standby
                        $CURR_DIR/command/cf-hmaster.sh stop_active
                fi

                if [ "${CF_SPARK_USE}" == "TRUE" ]; then
                        $CURR_DIR/command/cf-spark.sh stop
                fi
                $CURR_DIR/command/cf-datanode.sh stop
                $CURR_DIR/command/cf-nodemanager.sh stop
                $CURR_DIR/command/cf-resourcemanager.sh stop
                $CURR_DIR/command/cf-historyserver.sh stop
                $CURR_DIR/command/cf-zkfc.sh stop_standby
                $CURR_DIR/command/cf-zkfc.sh stop_active
                $CURR_DIR/command/cf-namenode.sh stop_standby
                $CURR_DIR/command/cf-namenode.sh stop_active
                $CURR_DIR/command/cf-journalnode.sh stop
                $CURR_DIR/command/cf-zookeeper.sh stop

                $CURR_DIR/command/cf-trendmap-api.sh stop
                $CURR_DIR/command/cf-trendmap-analysis.sh stop		
		;;
                "hadoop")
		$CURR_DIR/command/cf-datanode.sh stop
		$CURR_DIR/command/cf-nodemanager.sh stop
		$CURR_DIR/command/cf-resourcemanager.sh stop
		$CURR_DIR/command/cf-historyserver.sh stop
		$CURR_DIR/command/cf-zkfc.sh stop_standby
		$CURR_DIR/command/cf-zkfc.sh stop_active
		$CURR_DIR/command/cf-namenode.sh stop_standby
		$CURR_DIR/command/cf-namenode.sh stop_active
		$CURR_DIR/command/cf-journalnode.sh stop
		$CURR_DIR/command/cf-zookeeper.sh stop
		;;
                "hbase")
                $CURR_DIR/command/cf-regionserver.sh stop
                $CURR_DIR/command/cf-hmaster.sh stop_standby
                $CURR_DIR/command/cf-hmaster.sh stop_active
		;;
                "spark")
		$CURR_DIR/command/cf-spark.sh stop
		;;
                "trendmap")
		$CURR_DIR/command/cf-trendmap-api.sh stop
		$CURR_DIR/command/cf-trendmap-analysis.sh stop
		$CURR_DIR/command/cf-trendmap-admintool.sh stop
		;;
        esac
} 


function status_app() {
        case $TARGET in
                "all")
                if [ "${CF_HBASE_USE}" == "TRUE" ]; then
                        $CURR_DIR/command/cf-regionserver.sh status
                        $CURR_DIR/command/cf-hmaster.sh status
                fi

                if [ "${CF_SPARK_USE}" == "TRUE" ]; then
                        $CURR_DIR/command/cf-spark.sh status
                fi
                $CURR_DIR/command/cf-datanode.sh status
                $CURR_DIR/command/cf-nodemanager.sh status
                $CURR_DIR/command/cf-resourcemanager.sh status
                $CURR_DIR/command/cf-historyserver.sh status
                $CURR_DIR/command/cf-zkfc.sh status
                $CURR_DIR/command/cf-namenode.sh status
                $CURR_DIR/command/cf-journalnode.sh status
                $CURR_DIR/command/cf-zookeeper.sh status

                $CURR_DIR/command/cf-trendmap-api.sh status
                $CURR_DIR/command/cf-trendmap-analysis.sh status		
                ;;
                "hadoop")
                $CURR_DIR/command/cf-datanode.sh status
                $CURR_DIR/command/cf-nodemanager.sh status
                $CURR_DIR/command/cf-resourcemanager.sh status
                $CURR_DIR/command/cf-historyserver.sh status
                $CURR_DIR/command/cf-zkfc.sh status
                $CURR_DIR/command/cf-namenode.sh status
                $CURR_DIR/command/cf-journalnode.sh status
                $CURR_DIR/command/cf-zookeeper.sh status
                ;;
                "hbase")
                $CURR_DIR/command/cf-regionserver.sh status
                $CURR_DIR/command/cf-hmaster.sh status
                ;;
                "spark")
                $CURR_DIR/command/cf-spark.sh status
                ;;
                "trendmap")
		$CURR_DIR/command/cf-trendmap-api.sh status
		$CURR_DIR/command/cf-trendmap-analysis.sh status
		$CURR_DIR/command/cf-trendmap-admintool.sh status
		;;
        esac
}

function echo_start() {
	cf_echo_start $(basename "$0") "all hosts"
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
