#!/bin/bash
set -m

CURR_DIR="$( cd "$( dirname "$0" )" && pwd -P )"
ENV_DIR=${CURR_DIR%/*}
. ${ENV_DIR}/cf-env.sh

function print_usage() {
	echo "Usage : ${0} <active|standby>"
        echo ""
        echo "run only first installed"
        echo "active	: hadoop active format"
        echo "standby	: hadoop standby format"
	echo ""

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

function init_datadir() {

        TARGET=$1
        USER=$2
        HOSTS=$3

        case $TARGET in
                "namenode") DEL_DIR=$CF_HDFS_NN_DIR;;
                "zookeeper") DEL_DIR=$CF_HDFS_NN_DIR;;
                "journalnode") DEL_DIR=$CF_HDFS_NN_DIR;;
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
			case $TARGET in
	        	        "zookeeper")
					echo "ssh $USER@$x find $y/* ! -name myid -delete"
					ssh $USER@$x find $y/* ! -name myid -delete
				;;
                                "datanode")
                                        echo "ssh $USER@$x rm -rf $y/hdfs/data/*"     
                                        ssh $USER@$x rm -rf $y/hdfs/data/*
                                ;;
                                "namenode")
                                        echo "ssh $USER@$x rm -rf $y/hdfs/name/*"     
                                        ssh $USER@$x rm -rf $y/hdfs/name/*
                                ;;
                                "journalnode")
                                        echo "ssh $USER@$x rm -rf $y/hdfs/journalnode/*"     
                                        ssh $USER@$x rm -rf $y/hdfs/journalnode/*
                                ;;
			esac
                        ) &
                done
                wait

                ) &
        done
        wait

}



function active_app() {
		init_datadir "namenode" $CF_HADOOP_USER $CF_NAMENODE_HOSTS
		init_datadir "datanode" $CF_HADOOP_USER $CF_DATANODE_HOSTS
		init_datadir "zookeeper" $CF_HADOOP_USER $CF_ZOOKEEPER_HOSTS
		init_datadir "journalnode" $CF_HADOOP_USER $CF_HA_JOURNALNODE_HOSTS

                $CURR_DIR/cf-zookeeper.sh start
		sleep 2
		$CURR_DIR/cf-zkfc.sh format_active
		sleep 2
                $CURR_DIR/cf-journalnode.sh start
		sleep 2
                $CURR_DIR/cf-namenode.sh format_active
		sleep 2
                $CURR_DIR/cf-journalnode.sh stop
                $CURR_DIR/cf-zookeeper.sh stop
} 

function standby_app() {
                init_datadir "namenode" $CF_HADOOP_USER $CF_NAMENODE_HOSTS
		init_datadir "datanode" $CF_HADOOP_USER $CF_DATANODE_HOSTS
                init_datadir "zookeeper" $CF_HADOOP_USER $CF_ZOOKEEPER_HOSTS
                init_datadir "journalnode" $CF_HADOOP_USER $CF_HA_JOURNALNODE_HOSTS

                $CURR_DIR/cf-zookeeper.sh start
                sleep 2
                $CURR_DIR/cf-zkfc.sh format_standby
                sleep 2
                $CURR_DIR/cf-journalnode.sh start
                sleep 2
                $CURR_DIR/cf-namenode.sh format_standby
                sleep 2
                $CURR_DIR/cf-journalnode.sh stop
                $CURR_DIR/cf-zookeeper.sh stop

}


function echo_start() {
	cf_echo_start $(basename "$0") "all hosts"
}

function echo_end() {
	cf_echo_end ${0}
}

case $TARGET in
        "active") echo_start;active_app;echo_end;;
        "standby") echo_start;standby_app;echo_end;;
        *) print_usage;;
esac
