#!/bin/bash
if [ "${CF_ENV_LOADED}" == "TRUE" ]; then
   echo "cf_env.sh have been already loaded."
else

# NEED SSH NON PASSWORD SETTINGS ALL TARGET HOSTS
#
# ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
# cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
# chmod 0600 ~/.ssh/authorized_keys

########## common setting #############
export JAVA_HOME=/home/hadoop/java
export HADOOP_HOME=/home/hadoop/hadoop
export HBASE_HOME=/home/hadoop/hbase
export SPARK_HOME=/home/hadoop/spark
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HBASE_HOME/bin:$SPARK_HOME/bin:$PATH

export CF_ENV_LOADED=TRUE
export CF_JAVA_HOME=/home/hadoop/java
export CF_JAVA_SRC=jdk-8u291-linux-x64.tar.gz

export CF_HOSTS=cf01,cf02,cf03,cf04,cf05,cf06,cf07
export CF_NAMENODE_HOSTS=cf01,cf02
export CF_DATANODE_HOSTS=cf03,cf04,cf05,cf06,cf07

export CF_INSTALLER_SRCDIR=/home/trendmap/installer/src
export CF_INSTALLER_HOME=/home/trendmap/installer
export CF_INSTALLER_DOWNLOAD_DIR_NAME=cf_download

export CF_COL_BYELLO='\033[1;33m'
export CF_COL_YELLO='\033[0;33m'
export CF_COL_BGREEN='\033[1;32m'
export CF_COL_BRED='\033[1;31m'
export CF_COL_BWHITE='\033[1;37m'
export CF_COL_END='\033[0m'

########## hadoop setting #############
export CF_HADOOP_USER=hadoop
export CF_HADOOP_INSTALL_DIR=/home/hadoop
export CF_HADOOP_HOME=${CF_HADOOP_INSTALL_DIR}/hadoop
export CF_HADOOP_SRC=hadoop-3.3.4.tar.gz

export CF_HDFS_NN_DIR=/cluster/hadoop
export CF_HDFS_DN_DIR=/cluster/disk1/hadoop,/cluster/disk2/hadoop,/cluster/disk3/hadoop
export CF_NAMENODE_DATA_DIR=${CF_HDFS_NN_DIR}/hdfs/name
export CF_ZOOKEEPER_DATA_DIR=${CF_HDFS_NN_DIR}/zookeeper
export CF_DATANODE_DATA_DIR=/cluster/disk1/hadoop/hdfs/data,/cluster/disk2/hadoop/hdfs/data,/cluster/disk3/hadoop/hdfs/data

# FALSE NOT SUPPORTED
export CF_HA_MODE=TRUE
export CF_HA_NAMESERVER_NAME=ds-cluster
export CF_HA_JOURNALNODE_HOSTS=cf01,cf02,cf03
export CF_HA_ZKFC_HOSTS=cf01,cf02
export CF_HA_ACTIVE_HOSTS=cf01
export CF_HA_STANDBY_HOSTS=cf02

# RM	: resourcemanager
# JHS	: jobhistoryserver
# NM	: nodemanager
export CF_RM_HOSTS=cf01,cf02
export CF_JHS_HOSTS=cf03
export CF_NM_HOSTS=cf03,cf04,cf05,cf06,cf07

######## zookeeper settting ##########
export CF_ZOOKEEPER_USER=${CF_HADOOP_USER}
export CF_ZOOKEEPER_INSTALL_DIR=${CF_HADOOP_INSTALL_DIR}
export CF_ZOOKEEPER_HOME=${CF_ZOOKEEPER_INSTALL_DIR}/zookeeper
export CF_ZOOKEEPER_SRC=apache-zookeeper-3.7.1-bin.tar.gz
export CF_ZOOKEEPER_HOSTS=cf01,cf02,cf03

######### hbase setting ##############
export CF_HBASE_USE=TRUE
export CF_HBASE_USER=hadoop
export CF_HBASE_INSTALL_DIR=/home/hadoop
export CF_HBASE_HOME=${CF_HBASE_INSTALL_DIR}/hbase
export CF_HBASE_SRC=hbase-2.5.1-bin.tar.gz
export CF_HBASE_INSTALL_HOSTS=cf01,cf02,cf03,cf04,cf05,cf06,cf07
export CF_HBASE_MASTER_HOSTS=cf01,cf02
export CF_HBASE_REGION_HOSTS=cf03,cf04,cf05,cf06,cf07

export CF_HA_HBASE_ACTIVE_HOSTS=cf01
export CF_HA_HBASE_STANDBY_HOSTS=cf02

######### spark setting ##############
export CF_SPARK_USE=FALSE
export CF_SPARK_USER=hadoop
export CF_SPARK_INSTALL_DIR=/home/hadoop
export CF_SPARK_HOME=${CF_SPARK_INSTALL_DIR}/spark
export CF_SPARK_SRC=spark-3.3.1-bin-hadoop3.tgz
export CF_SPARK_INSTALL_HOSTS=cf01,cf03,cf04,cf05,cf06,cf07
export CF_SPARK_MASTER_HOSTS=cf01
export CF_SPARK_SLAVE_HOSTS=cf03,cf04,cf05,cf06,cf07

######### trendmap setting #############
export CF_TRENDMAP_USER=trendmap
export CF_TRENDMAP_INSTALL_DIR=/home/trendmap
export CF_TRENDMAP_HOME=/home/trendmap
export CF_TRENDMAP_MANAGEMENT_HOSTS=cf01
export CF_TRENDMAP_API_HOSTS=cf01
export CF_TRENDMAP_ADMINTOOL_HOSTS=cf01
export CF_TRENDMAP_ANALYSIS_HOSTS=cf03,cf04,cf05,cf06,cf07

######## common function ##############
function cf_ssh() {
        HOSTS=$1
        USER=$2
        MSG=$3

        invalid_parameter $HOSTS "HOSTS"
        invalid_parameter $USER "USER"
        invalid_parameter $MSG "MSG"

        IFS_OLD="$IFS"
        IFS=","
        HOSTS_ARRAY=($HOSTS)
        IFS=$IFS_OLD

        for x in "${HOSTS_ARRAY[@]}"
        do
                (
                	ssh $USER@$x $MSG
                ) &
        done
        wait

}
function cf_ssh_command() {
        HOSTS=$1
        USER=$2
        COMMAND=$3
	
        invalid_parameter $HOSTS "HOSTS"
        invalid_parameter $USER "USER"
        invalid_parameter $COMMAND "COMMAND"

        IFS_OLD="$IFS"
        IFS=","
        HOSTS_ARRAY=($HOSTS)
        IFS=$IFS_OLD

        for x in "${HOSTS_ARRAY[@]}"
        do
                (
 	                echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
                	ssh $USER@$x "bash -ic '$COMMAND'"
                ) &
        done
        wait
}

function cf_ssh_mkdir() {
	HOSTS=$1
	USER=$2
	DIR=$3

        invalid_parameter $HOSTS "HOSTS"
        invalid_parameter $USER "USER"
        invalid_parameter $DIR "DIR"

        IFS_OLD="$IFS"
        IFS=","
        HOSTS_ARRAY=($HOSTS)
        IFS=$IFS_OLD

        for x in "${HOSTS_ARRAY[@]}"
        do
                (
			ssh $USER@$x mkdir -p $DIR
                ) &
        done
        wait
}

function cf_ssh_status() {
	HOSTS=$1
	USER=$2
	JPS=$3
	MODE=$4

	invalid_parameter $HOSTS "HOSTS"
	invalid_parameter $USER "USER"
	invalid_parameter $JPS "JPS"
	invalid_parameter $MODE "MODE"

	IFS_OLD="$IFS"
	IFS=","
	HOSTS_ARRAY=($HOSTS)
	IFS=$IFS_OLD

        for x in "${HOSTS_ARRAY[@]}"
        do
                (
                echo -e "${CF_COL_BWHITE}work in $x check status ... ${CF_COL_END}"
                #JPS_MSG=$(ssh -tt -q $USER@$x "bash -ic 'jps | grep $JPS'")
                JPS_MSG=$(ssh $USER@$x "bash -ic 'jps | grep $JPS'")
                # 0-pid 0-psname
                JPS_ARR=($JPS_MSG)
                if [[ ${JPS_ARR[0]} -eq "" ]] ; then
                        echo -e "${CF_COL_BRED}$x $MODE is stopped.${CF_COL_END}"
                else
                        echo -e "${CF_COL_BGREEN}$x $MODE is running.${CF_COL_END}"
                fi
                ) & 
        done
        wait
}

function cf_ssh_status_ps() {
        HOSTS=$1
        USER=$2
        PS=$3
        MODE=$4

        invalid_parameter $HOSTS "HOSTS"
        invalid_parameter $USER "USER"
        invalid_parameter $PS "PS"
        invalid_parameter $MODE "MODE"

        IFS_OLD="$IFS"
        IFS=","
        HOSTS_ARRAY=($HOSTS)
        IFS=$IFS_OLD

        for x in "${HOSTS_ARRAY[@]}"
        do
                (
                echo -e "${CF_COL_BWHITE}work in $x check status ... ${CF_COL_END}"
                PS_MSG=$(ssh $USER@$x "bash -ic 'ps -ef | grep $PS | grep -v grep'")
		PS_ARR=($PS_MSG)
                if [[ ${PS_ARR[1]} -eq "" ]] ; then
                        echo -e "${CF_COL_BRED}$x $MODE is stopped.${CF_COL_END}"
                else
                        echo -e "${CF_COL_BGREEN}$x $MODE is running.${CF_COL_END}"
                fi
                ) &
        done
        wait
}


function cf_scp() {
	HOSTS=$1
	USER=$2
	SRC_DIR=$3
	DEST_DIR=$4

        IFS_OLD="$IFS"
        IFS=","
        HOSTS_ARRAY=($HOSTS)
        IFS=$IFS_OLD
	
	#echo "HOSTS:$HOSTS"
	#echo "USER:$USER"
	#echo "SRC_DIR:$SRC_DIR"
	#echo "DEST_DIR:$DEST_DIR"
	
        invalid_parameter $HOST "HOST"
        invalid_parameter $USER "USER"
        invalid_parameter $SRC_DIR "SRC_DIR"
        invalid_parameter $DEST_DIR "DEST_DIR"
	
	DIR_ARRAY=($SRC_DIR)
	for x in "${DIR_ARRAY[@]}"
	do
	        if [ -d $x ] || [ -f $x ]; then
        	        echo -e "${CF_COL_BWHITE}exists $x source file or directory${CF_COL_END}"
	        else
        	        echo -e "${CF_COL_BRED}not exists $x source file or directory${CF_COL_END}"
	                exit;
        	fi
	done

        for x in "${HOSTS_ARRAY[@]}"
        do
                (
                echo -e "${CF_COL_BWHITE}work in $x ${CF_COL_END}"
                scp -r $SRC_DIR $USER@$x:$DEST_DIR
		echo -e "${CF_COL_BWHITE}scp -r $SRC_DIR $USER@$x:$DEST_DIR${CF_COL_END}"
                ) &
        done
        wait
}

function cf_echo_start() {
	FULL_SCRIPT=$1
	HOSTS=$2
	echo -e "${CF_COL_BYELLO}start $FULL_SCRIPT target hosts ... [$HOSTS]${CF_COL_END}"
}
function cf_echo_end() {
	SCRIPT=$1
	echo -e "${CF_COL_YELLO}end $SCRIPT${CF_COL_END}"
}

function invalid_parameter() {
        PARAM=$1
        PARAM_NAME=$2
        if [ $PARAM = "" ];
        then
                echo -e "${CF_COL_BRED}[ERROR] parameter is null"
                echo -e "$PARAM_NAME:$PARAM"
                exit;
        fi
}

export -f cf_ssh
export -f cf_ssh_command
export -f cf_ssh_mkdir
export -f cf_ssh_status
export -f cf_ssh_status_ps
export -f cf_echo_start
export -f cf_echo_end
export -f cf_scp
export -f invalid_parameter

fi
