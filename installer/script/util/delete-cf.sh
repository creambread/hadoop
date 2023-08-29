#!/bin/bash

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
ENV_DIR=$(cd "${EXEC_FILE%${EXEC_FILE##*/}}../"; echo "$PWD")
. ${ENV_DIR}/cf-env.sh


######### HOST SELECTED ########

IFS_OLD="$IFS"
IFS=","
case $TARGET in
        "hadoop") HOSTS_ARRAY=($CF_HOSTS);TARGET_HOSTS=$CF_HOSTS;;
        "hbase") HOSTS_ARRAY=($CF_HBASE_INSTALL_HOSTS);TARGET_HOSTS=$CF_HBASE_INSTALL_HOSTS;;
        "spark") HOSTS_ARRAY=($CF_SPARK_INSTALL_HOSTS);TARGET_HOSTS=$CF_SPARK_INSTALL_HOSTS;;
        *) print_usage;exit;;
esac
IFS=$IFS_OLD
echo -e "${CF_COL_BYELLO}${0} target hosts ... $TARGET_HOSTS${CF_COL_END}"

######### MAIN FUNCTIONS #######
function init_datadir() {
	
	TARGET=$1
	USER=$2
	HOSTS=$3	
	
	case $TARGET in
        	"namenode") DEL_DIR=$CF_HDFS_NN_DIR;;
        	"datanode") DEL_DIR=$CF_HDFS_DN_DIR;;
	esac

        IFS_OLD="$IFS"
        IFS=","
        HOSTS_ARRAY=($HOSTS);
        IFS=$IFS_OLD

        IFS_OLD="$IFS"
        IFS=","
        DEL_ARRAY=($DEL_DIR);
        IFS=$IFS_OLD

        for x in "${HOSTS_ARRAY[@]}"
        do
                (
	        for y in "${DEL_ARRAY[@]}"
        	do      
	                (
                	echo delete $TARGET every things...
        	        echo "ssh $USER@$x rm -rf $y/*"     
	                ssh $USER@$x rm -rf $y/*
                	) &
        	done
	        wait

                ) &
        done
        wait

}

function hadoop() {
	for x in "${HOSTS_ARRAY[@]}"
	do
		(
		echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
		echo delete $TARGET every things...
		echo "ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME"	
		ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		echo "ssh $CF_HADOOP_USER@$x rm $CF_HADOOP_INSTALL_DIR/hadoop"
		ssh $CF_HADOOP_USER@$x rm $CF_HADOOP_INSTALL_DIR/hadoop
		echo "ssh $CF_HADOOP_USER@$x rm $CF_HADOOP_INSTALL_DIR/zookeeper"
		ssh $CF_HADOOP_USER@$x rm $CF_HADOOP_INSTALL_DIR/zookeeper
		echo "ssh $CF_HADOOP_USER@$x rm $CF_HADOOP_INSTALL_DIR/java"
		ssh $CF_HADOOP_USER@$x rm $CF_HADOOP_INSTALL_DIR/java
		echo "ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/hadoop*"
		ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/hadoop*
		echo "ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/jdk*"
		ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/jdk*
		echo "ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/*zookeeper*"
		ssh $CF_HADOOP_USER@$x rm -rf $CF_HADOOP_INSTALL_DIR/*zookeeper*
		) &
	done
	wait

	#NameNodes
	init_datadir "namenode" $CF_HADOOP_USER $CF_NAMENODE_HOSTS

	#DataNodes
	init_datadir "namenode" $CF_HADOOP_USER $CF_DATANODE_HOSTS
	init_datadir "datanode" $CF_HADOOP_USER $CF_DATANODE_HOSTS
}

function hbase() {
        for x in "${HOSTS_ARRAY[@]}"
        do	
		(
                echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
                echo delete $TARGET every things...
		echo "ssh $CF_HBASE_USER@$x rm -rf $CF_HBASE_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME"
		ssh $CF_HBASE_USER@$x rm -rf $CF_HBASE_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		echo "ssh $CF_HBASE_USER@$x rm $CF_HBASE_INSTALL_DIR/hbase"
                ssh $CF_HBASE_USER@$x rm $CF_HBASE_INSTALL_DIR/hbase
		echo "ssh $CF_HBASE_USER@$x rm -rf $CF_HBASE_INSTALL_DIR/hbase*"
                ssh $CF_HBASE_USER@$x rm -rf $CF_HBASE_INSTALL_DIR/hbase*
		) &
        done
	wait

}

function spark() {
        for x in "${HOSTS_ARRAY[@]}"
        do
		(
                echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
                echo delete $TARGET every things...
		echo "ssh $CF_SPARK_USER@$x rm -rf $CF_SPARK_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME"
		ssh $CF_SPARK_USER@$x rm -rf $CF_SPARK_INSTALL_DIR/$CF_INSTALLER_DOWNLOAD_DIR_NAME
		echo "ssh $CF_SPARK_USER@$x rm $CF_SPARK_INSTALL_DIR/spark"
                ssh $CF_SPARK_USER@$x rm $CF_SPARK_INSTALL_DIR/spark
		echo "ssh $CF_SPARK_USER@$x rm -rf $CF_SPARK_INSTALL_DIR/spark*"
                ssh $CF_SPARK_USER@$x rm -rf $CF_SPARK_INSTALL_DIR/spark*
		) &
        done
	wait
}


function init() {
	case $TARGET in
		"hadoop") hadoop;;
	        "hbase") hbase;;
	        "spark") spark;;
	        *) print_usage;;
	esac
}

while true; do
    echo -e "${CF_COL_BRED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${CF_COL_END}"
    echo -e "${CF_COL_BRED}!!!!!!!!!!     WARNNING     !!!!!!!!!!!!!!${CF_COL_END}"
    echo -e "${CF_COL_BRED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${CF_COL_END}"
    read -p "Do you wish to delete all $TARGET program? (y/n)" yn
    case $yn in
        [Yy]* ) init; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y or n.";;
    esac
done

echo -e "${CF_COL_YELLO}end ${0}${CF_COL_END}"
