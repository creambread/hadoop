#!/bin/bash

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <hadoop|hbase|spark>"
}
function endScript() {
	echo "end script"
	exit;
}

if [ $# != 1 ]; then
	print_usage
	exit;
fi
TARGET=$1

######### HOST SELECTED ########
IFS_OLD="$IFS"
IFS=","
case $TARGET in
        "hadoop")TARGET_HOSTS=$CF_HOSTS;;
        "hbase")TARGET_HOSTS=$CF_HBASE_INSTALL_HOSTS;;
        "spark")TARGET_HOSTS=$CF_SPARK_INSTALL_HOSTS;;
        *) print_usage;exit;;
esac
HOSTS_ARRAY=($TARGET_HOSTS)
IFS=$IFS_OLD

######### MAIN FUNCTIONS #######
function hadoop() {
	for x in "${HOSTS_ARRAY[@]}"
	do
		echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
		ssh $CF_HADOOP_USER@$x $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/script/util/unarchiver.sh hadoop $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/$CF_HADOOP_SRC $CF_HADOOP_INSTALL_DIR
		ssh $CF_HADOOP_USER@$x $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/script/util/unarchiver.sh java $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/$CF_JAVA_SRC $CF_HADOOP_INSTALL_DIR
		ssh $CF_HADOOP_USER@$x $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/script/util/unarchiver.sh zookeeper $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/$CF_ZOOKEEPER_SRC $CF_HADOOP_INSTALL_DIR
	done
}
function hbase() {
        for x in "${HOSTS_ARRAY[@]}"
        do
                echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
                ssh $CF_HBASE_USER@$x $CF_HBASE_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/script/util/unarchiver.sh hbase $CF_HBASE_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/$CF_HBASE_SRC $CF_HBASE_INSTALL_DIR
        done

}
function spark() {
        for x in "${HOSTS_ARRAY[@]}"
        do
                echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
                ssh $CF_SPARK_USER@$x $CF_SPARK_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/script/util/unarchiver.sh spark $CF_SPARK_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/$CF_SPARK_SRC $CF_SPARK_INSTALL_DIR
        done
}

function echo_start() {
	cf_echo_start $(basename "$0") $TARGET_HOSTS
}
function echo_end() {
	cf_echo_end ${0}
}

case $TARGET in
	"hadoop") echo_start;hadoop;echo_end;;
	"hbase") echo_start;hbase;echo_end;;
	"spark") echo_start;spark;echo_end;;
        "trendmap") echo_start;trendmap;echo_end;;
        *) print_usage;;
esac

