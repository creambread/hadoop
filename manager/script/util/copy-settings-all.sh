#!/bin/bash

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <hadoop|hbase|spark> <runner|installer>"
	echo ""
	echo "installer	: $CF_INSTALLER_HOME/conf setted file copy to all target hosts"
	echo "runner		: running main server setting file copy to all target hosts"
	echo ""
}
function endScript() {
	echo "end script"
	exit;
}

if [ $# != 2 ]; then
	print_usage
	exit;
fi

TARGET=$1
MODE=$2

######### HOST SELECTED ########
case $TARGET in
        "hadoop") TARGET_HOSTS=$CF_HOSTS;;
        "hbase") TARGET_HOSTS=$CF_HBASE_INSTALL_HOSTS;;
        "spark") TARGET_HOSTS=$CF_SPARK_INSTALL_HOSTS;;
        *) print_usage;exit;;
esac

######### MAIN FUNCTIONS #######
function copy_runner() {
	COPY_TARGET=$1
	case $TARGET in
		"hadoop")
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_HADOOP_HOME/etc/hadoop/*" "$CF_HADOOP_HOME/etc/hadoop/"
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_ZOOKEEPER_HOME/conf/zoo.cfg" "$CF_ZOOKEEPER_HOME/conf/zoo.cfg"
                ;;
                "hbase")
			cf_scp $TARGET_HOSTS $CF_HBASE_USER "$CF_HBASE_HOME/conf/*" "$CF_HBASE_HOME/conf/"
			cf_scp $TARGET_HOSTS $CF_HBASE_USER "$CF_HBASE_HOME/lib/*" "$CF_HBASE_HOME/lib/"
                ;;
                "spark")
			cf_scp $TARGET_HOSTS $CF_SPARK_USER "$CF_SPARK_HOME/conf/*" "$CF_SPARK_HOME/conf/"
                ;;
	esac
}

function copy_installer() {
	COPY_TARGET=$1
	case $TARGET in
		"hadoop")
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_INSTALLER_HOME/conf/hadoop/*" "$CF_HADOOP_HOME/etc/hadoop/"
			#cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_INSTALLER_HOME/lib/hadoop/native/*" "$CF_HADOOP_HOME/lib/native/"
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_INSTALLER_HOME/conf/zookeeper/*" "$CF_ZOOKEEPER_HOME/conf/"
                ;;
                "hbase")
			cf_scp $TARGET_HOSTS $CF_HBASE_USER "$CF_INSTALLER_HOME/conf/hbase/*" "$CF_HBASE_HOME/conf/"
			cf_scp $TARGET_HOSTS $CF_HBASE_USER "$CF_INSTALLER_HOME/lib/hbase/*" "$CF_HBASE_HOME/lib/"
                ;;
                "spark")
			cf_scp $TARGET_HOSTS $CF_SPARK_USER "$CF_INSTALLER_HOME/conf/spark/*" "$CF_SPARK_HOME/conf/"
                ;;
	esac
}

function echo_start() {
	cf_echo_start $(basename "$0") $TARGET_HOSTS
}
function echo_end() {
	cf_echo_end ${0}
}

case $TARGET in
        "hadoop")
                case $MODE in
                        "runner")echo_start;copy_runner "hadoop";echo_end;;
                        "installer")echo_start;copy_installer "hadoop";echo_end;;
                esac
        ;;
        "hbase")
                case $MODE in
                        "runner")echo_start;copy_runner "hbase";echo_end;;
                        "installer")echo_start;copy_installer "hbase";echo_end;;
                esac
        ;;
        "spark")
                case $MODE in
                        "runner")echo_start;copy_runner "spark";echo_end;;
                        "installer")echo_start;copy_installer "spark";echo_end;;
                esac
        ;;
        *) print_usage;;
esac



