#!/bin/bash
#!/bin/bash

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <hadoop|hbase|spark|trendmap>"
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
        "trendmap")TARGET_HOSTS=$CF_HOSTS;;
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

function trendmap() {
	echo "unarchive api.tar.gz ..."
	cf_ssh $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "tar -xf $CF_TRENDMAP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/api.tar.gz -C $CF_TRENDMAP_INSTALL_DIR"
	echo "unarchive jdk ..."
	cf_ssh $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "rm -rf $CF_TRENDMAP_INSTALL_DIR/api/jdk"
	ssh $CF_TRENDMAP_USER@$x $CF_TRENDMAP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/script/util/unarchiver.sh jdk $CF_TRENDMAP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/$CF_JAVA_SRC $CF_TRENDMAP_INSTALL_DIR/api
	echo "add symbolic link hbase ..."
	cf_ssh $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "ln -s $CF_HBASE_HOME $CF_TRENDMAP_HOME/api/thrift/hbase"
	echo "chmod 777 hbase logs dir"
	cf_ssh $CF_TRENDMAP_API_HOSTS $CF_HBASE_USER "chmod 777 $CF_HBASE_HOME/logs"
        echo "make old KeyCat Dir.. (admin tool neeed old directory. hard cording path in c++ source code.)"
        cf_ssh $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "mkdir -p /home/trendmap/Trendmap2/KeyCat/engine/tm_kr/resource"
        echo "add symbolic link category"
        cf_ssh $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "ln -s $CF_TRENDMAP_INSTALL_DIR/api/keycat/resource/category /home/trendmap/Trendmap2/KeyCat/engine/tm_kr/resource/category"

	echo "unarchive management.tar.gz ..."
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "tar -xf $CF_TRENDMAP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/management.tar.gz -C $CF_TRENDMAP_INSTALL_DIR"
	echo "unarchive admintool.tar.gz ..."
	cf_ssh $CF_TRENDMAP_ADMINTOOL_HOSTS $CF_TRENDMAP_USER "tar -xf $CF_TRENDMAP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/admintool.tar.gz -C $CF_TRENDMAP_INSTALL_DIR"

	echo "unarchive analysis.tar.gz ..."
	cf_ssh $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "tar -xf $CF_TRENDMAP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME/analysis.tar.gz -C $CF_TRENDMAP_INSTALL_DIR"
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

