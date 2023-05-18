#!/bin/bash

ENV_DIR=$(cd "${EXEC_FILE%${EXEC_FILE##*/}}../"; echo "$PWD")
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <run>"
	echo ""
	echo "work list ..."
	echo "1. create default trendmap directory"
        echo "2. copy global_conf to hdfs"
	echo "3. init hbase common table"
	echo -e "${CF_COL_BRED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${CF_COL_END}"
        echo -e "${CF_COL_BRED}!!!!!!!!!!     WARNNING     !!!!!!!!!!!!!!${CF_COL_END}"
	echo -e "${CF_COL_BRED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${CF_COL_END}"
	echo -e "${CF_COL_BRED}please do run only first installed trendmap ${CF_COL_END}"
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

######### MAIN FUNCTIONS #######
function run_app() {
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_HADOOP_USER "$HADOOP_HOME/bin/hadoop fs -rm -r -skipTrash /user/trendmap"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_HADOOP_USER "$HADOOP_HOME/bin/hadoop fs -mkdir -p /user/trendmap"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_HADOOP_USER "$HADOOP_HOME/bin/hadoop fs -chown -R hadoop:hadoop /user"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_HADOOP_USER "$HADOOP_HOME/bin/hadoop fs -chown -R hadoop:hadoop /tmp"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_HADOOP_USER "$HADOOP_HOME/bin/hadoop fs -chown -R hadoop:hadoop /hbase"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_HADOOP_USER "$HADOOP_HOME/bin/hadoop fs -chown -R trendmap:trendmap /user/trendmap"

	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$HADOOP_HOME/bin/hadoop fs -mkdir -p conf"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$HADOOP_HOME/bin/hadoop fs -mkdir -p data/gw"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$HADOOP_HOME/bin/hadoop fs -mkdir -p projects"
	cf_ssh $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$HADOOP_HOME/bin/hadoop fs -copyFromLocal $CF_TRENDMAP_HOME/conf/hdfs/global_conf/* conf/"
	cf_ssh_command $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$CF_TRENDMAP_HOME/bin/project/create_hbase_table.sh -common"
}

case $TARGET in
	"run") run_app;;
        *) print_usage;;
esac

echo -e "${CF_COL_YELLO}end ${0}${CF_COL_END}"
