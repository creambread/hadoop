#!/bin/bash

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <hadoop|hbase|spark|trendmap> <runner|installer>"
	echo ""
	echo "installer	: $CF_INSTALLER_HOME/conf setted file copy to all target hosts"
	echo "runner		: running 1 server setted file copy to all target hosts"
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
        "trendmap") TARGET_HOSTS=$CF_HOSTS;;
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
                "trendmap")
			echo $0 trendmap runner mode not supported.
                ;;
	esac
}

function copy_installer() {
	COPY_TARGET=$1
	case $TARGET in
		"hadoop")
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_INSTALLER_HOME/conf/hadoop/*" "$CF_HADOOP_HOME/etc/hadoop/"
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_INSTALLER_HOME/lib/hadoop/native/*" "$CF_HADOOP_HOME/lib/native/"
			cf_scp $TARGET_HOSTS $CF_HADOOP_USER "$CF_INSTALLER_HOME/conf/zookeeper/*" "$CF_ZOOKEEPER_HOME/conf/"
                ;;
                "hbase")
			cf_scp $TARGET_HOSTS $CF_HBASE_USER "$CF_INSTALLER_HOME/conf/hbase/*" "$CF_HBASE_HOME/conf/"
			cf_scp $TARGET_HOSTS $CF_HBASE_USER "$CF_INSTALLER_HOME/lib/hbase/*" "$CF_HBASE_HOME/lib/"
                ;;
                "spark")
			cf_scp $TARGET_HOSTS $CF_SPARK_USER "$CF_INSTALLER_HOME/conf/spark/*" "$CF_SPARK_HOME/conf/"
                ;;
                "trendmap")
			cf_scp $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/hbase/hbase-site.xml" "$CF_TRENDMAP_HOME/conf/"
			cf_scp $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/management/servers.conf" "$CF_TRENDMAP_HOME/conf/"
			cf_scp $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/management/servers.conf" "$CF_TRENDMAP_HOME/conf/hdfs/global_conf/"
			cf_scp $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/management/trendmap-default.xml" "$CF_TRENDMAP_HOME/conf/"
			cf_scp $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/management/trendmap_env.sh" "$CF_TRENDMAP_HOME/bin/"

			cf_scp $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/analysis/build_asso.sh" "$CF_TRENDMAP_HOME/association/script/"
			cf_scp $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/analysis/ma.cfg.trendmap2" "$CF_TRENDMAP_HOME/Trendmap2/TextMiningServer/conf/"
			cf_scp $CF_TRENDMAP_ANALYSIS_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/analysis/tmtm.cfg.trendmap2" "$CF_TRENDMAP_HOME/Trendmap2/TextMiningServer/conf/"

			cf_scp $CF_TRENDMAP_ADMINTOOL_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/admintool/_admintool_env.sh" "$CF_TRENDMAP_HOME/admintool/"
			cf_scp $CF_TRENDMAP_ADMINTOOL_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/admintool/application.properties" "$CF_TRENDMAP_HOME/admintool/conf/"

			cf_scp $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/hbase/hbase-site.xml" "$CF_TRENDMAP_HOME/api/tomcat/webapps/ROOT/WEB-INF/classes"
			cf_scp $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/api/trendmap.properties" "$CF_TRENDMAP_HOME/api/tomcat/webapps/ROOT/WEB-INF/classes"
			cf_scp $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/api/mysql_conf.sh" "$CF_TRENDMAP_HOME/api/keycat/resource/category/script/"
			cf_scp $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/conf/trendmap/api/KeyCat.cfg" "$CF_TRENDMAP_HOME/api/keycat/bin/KeyCat.cfg"

			cf_scp $CF_TRENDMAP_API_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/lib/trendmap/*" "$CF_TRENDMAP_HOME/api/tomcat/webapps/ROOT/WEB-INF/lib"
			cf_scp $CF_TRENDMAP_MANAGEMENT_HOSTS $CF_TRENDMAP_USER "$CF_INSTALLER_HOME/lib/trendmap/*" "$CF_TRENDMAP_HOME/lib"
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
        "trendmap")
                case $MODE in
                        "runner")echo_start;copy_runner "trendmap";echo_end;;
                        "installer")echo_start;copy_installer "trendmap";echo_end;;
                esac
        ;;
        *) print_usage;;
esac



