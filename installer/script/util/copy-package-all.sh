#!/bin/bash

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <hadoop|hbase|spark> <src|installer>"
        echo ""
        echo "src		: copy target system src file"
        echo "installer	: copy installer"
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
        "hadoop")TARGET_HOSTS=$CF_HOSTS;;
        "hbase")TARGET_HOSTS=$CF_HBASE_INSTALL_HOSTS;;
        "spark")TARGET_HOSTS=$CF_SPARK_INSTALL_HOSTS;;
        *) print_usage;exit;;
esac

######### MAIN FUNCTIONS #######
function copy_src() {
	COPY_TARGET=$1
	case $COPY_TARGET in
		"hadoop")
			cf_ssh_mkdir $TARGET_HOSTS $CF_HADOOP_USER $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER $CF_INSTALLER_SRCDIR/$CF_HADOOP_SRC $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER $CF_INSTALLER_SRCDIR/$CF_ZOOKEEPER_SRC $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER $CF_INSTALLER_SRCDIR/$CF_JAVA_SRC $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		;;
		"hbase")
			cf_ssh_mkdir $TARGET_HOSTS $CF_HBASE_USER $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
			cf_scp $TARGET_HOSTS $CF_HBASE_USER $CF_INSTALLER_SRCDIR/$CF_HBASE_SRC $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		;;
		"spark")
			cf_ssh_mkdir $TARGET_HOSTS $CF_SPARK_USER $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
			cf_scp $TARGET_HOSTS $CF_SPARK_USER $CF_INSTALLER_SRCDIR/$CF_SPARK_SRC $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		;;
	esac
}

function copy_installer() {
	COPY_TARGET=$1
        case $COPY_TARGET in
	"hadoop")
		cf_ssh_mkdir $TARGET_HOSTS $CF_HADOOP_USER $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		cf_scp $TARGET_HOSTS $CF_HADOOP_USER $CF_INSTALLER_HOME/script $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
                ;;
	"hbase")
		cf_ssh_mkdir $TARGET_HOSTS $CF_HBASE_USER $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		cf_scp $TARGET_HOSTS $CF_HBASE_USER $CF_INSTALLER_HOME/script $CF_HBASE_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME	
                ;;
	"spark")
		cf_ssh_mkdir $TARGET_HOSTS $CF_SPARK_USER $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		cf_scp $TARGET_HOSTS $CF_SPARK_USER $CF_INSTALLER_HOME/script $CF_SPARK_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
                ;;
        esac
}


function echo_start() {
	cf_echo_start $(basename "$0") $CF_HOSTS
}

function echo_end() {
	cf_echo_end ${0}
}

case $MODE in
	"src")echo_start;copy_src $TARGET;echo_end;;
	"installer")echo_start;copy_installer $TARGET;echo_end;;
esac
