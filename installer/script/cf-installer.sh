#!/bin/bash
CURR_DIR=$(cd "${EXEC_FILE%${EXEC_FILE##*/}}./"; echo "$PWD")
. ${CURR_DIR}/cf-env.sh

function print_usage() {
	echo -e "${CF_COL_YELLO}Usage : ${0} <hadoop|hbase|spark> $SCRIPT${CF_COL_END}"
	echo -e "${CF_COL_YELLO} $SCRIPT${CF_COL_END}"
	echo -e "${CF_COL_YELLO}hadoop            : install hadoop system $SCRIPT${CF_COL_END}"
	echo -e "${CF_COL_YELLO}hbase             : install hbase system $SCRIPT${CF_COL_END}"
	echo -e "${CF_COL_YELLO}spark             : install spark system $SCRIPT${CF_COL_END}"
	echo ""
        echo -e "${CF_COL_BYELLO}CHECK1 : setting cf-env.sh, conf files${CF_COL_END}"
        echo -e "$ hadoop,hbase,zookeeper setting"
	echo -e ""
        echo -e "${CF_COL_BYELLO}CHECK2 : Need all commander to all hosts user ssh free setting${CF_COL_END}"
        echo -e "$ ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa"
        echo -e "$ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
        echo -e "$ chmod 600 ~/.ssh/authorized_keys"
	echo ""
        echo -e "${CF_COL_BYELLO}CHECK3 : each user add each program homepath to .bashrc${CF_COL_END}"
        echo -e "export JAVA_HOME=/home/hadoop/java"
        echo -e "export HADOOP_HOME=/home/hadoop/hadoop"
        echo -e "export HBASE_HOME=/home/hadoop/hbase"
        echo -e "export SPARK_HOME=/home/hadoop/spark"
        echo -e "export PATH=\$SPARK_HOME/bin:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HBASE_HOME/bin:\$PATH"
	echo ""
        echo -e "${CF_COL_BYELLO}CHECK4 : hadoop user need Datanode dir and Namenode dir each Hosts${CF_COL_END}"
        echo -e "Namenode dir: $CF_HDFS_NN_DIR"
        echo -e "Datanode dir: $CF_HDFS_DN_DIR"

}
function endScript() {
	echo "end script"
	exit;
}

if [ $# != 1 ]; then
	print_usage
	exit;
fi
MODE=$1

function hadoop() {

	IS_CHECKED_DIR="TRUE"
	echo -e "${CF_COL_BYELLO}checking install dirs ... $x ${CF_COL_END}"

	#CHECK NAMENODE DATA DIR
	check_hadoop_dir "namenode"

	#CHECK DATANODE DATA DIR
	check_hadoop_dir "datanode"

	#CHECK ZOOKEEPER DATA DIR
	check_hadoop_dir "zookeeper"

	#CHECK ZOOKEEPER MYID
	check_hadoop_dir "zookeeper_myid"

	if [ $IS_CHECKED_DIR = "TRUE" ] ; then
		echo -e "${CF_COL_YELLO}check all done. ${CF_COL_END}"
	else
		while true; do
		    echo -e "${CF_COL_BRED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${CF_COL_END}"
		    echo -e "${CF_COL_BRED}!!!!!!!!!!     WARNNING     !!!!!!!!!!!!!!${CF_COL_END}"
		    echo -e "${CF_COL_BRED}!!!!!!!!!!  NEED SUDO USER  !!!!!!!!!!!!!!${CF_COL_END}"
		    echo -e "${CF_COL_BRED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${CF_COL_END}"
		    read -p "Do you wish to make all hadoop directory? (y/n)" yn
		    case $yn in
		        [Yy]* ) break;;
		        [Nn]* ) exit;;
		        * ) echo "Please answer y or n.";;
		    esac
		done
		read -s -p "hadoop user sudo Password: " passwd

		make_hadoop_dir "namenode" $passwd
		make_hadoop_dir "datanode" $passwd
		make_hadoop_dir "zookeeper" $passwd
		make_hadoop_dir "zookeeper_myid" $passwd

        	#CHECK NAMENODE DATA DIR
	        check_hadoop_dir "namenode"

        	#CHECK DATANODE DATA DIR
	        check_hadoop_dir "datanode"

        	#CHECK ZOOKEEPER DATA DIR
	        check_hadoop_dir "zookeeper"

        	#CHECK ZOOKEEPER MYID
	        check_hadoop_dir "zookeeper_myid"
	fi

	${CURR_DIR}/util/copy-package-all.sh hadoop src
	${CURR_DIR}/util/copy-package-all.sh hadoop installer
	${CURR_DIR}/util/unarchive-package-all.sh hadoop
	${CURR_DIR}/util/copy-settings-all.sh hadoop installer

	echo -e "${CF_COL_BYELLO}running format zkfc,namenode ${CF_COL_END}"
	${CURR_DIR}/command/cf-hadoop-format.sh active
}

function hbase() {
        ${CURR_DIR}/util/copy-package-all.sh hbase src
        ${CURR_DIR}/util/copy-package-all.sh hbase installer
        ${CURR_DIR}/util/unarchive-package-all.sh hbase
        ${CURR_DIR}/util/copy-settings-all.sh hbase installer
}

function spark() {
      	${CURR_DIR}/util/copy-package-all.sh spark src
        ${CURR_DIR}/util/copy-package-all.sh spark installer
        ${CURR_DIR}/util/unarchive-package-all.sh spark
        ${CURR_DIR}/util/copy-settings-all.sh spark installer
}

function check_hadoop_dir() {
	TARGET=$1
	case $TARGET in
		"namenode") 
		TARGET_HOSTS=$CF_NAMENODE_HOSTS;
		TARGET_DIRS=$CF_NAMENODE_DATA_DIR;;
		"datanode")
		TARGET_HOSTS=$CF_DATANODE_HOSTS;
		TARGET_DIRS=$CF_DATANODE_DATA_DIR;;
		"zookeeper")
		TARGET_HOSTS=$CF_ZOOKEEPER_HOSTS;
		TARGET_DIRS=$CF_ZOOKEEPER_DATA_DIR;;
		"zookeeper_myid")
		TARGET_HOSTS=$CF_ZOOKEEPER_HOSTS;
		TARGET_FILE=$CF_ZOOKEEPER_DATA_DIR/myid;;
		*) exit;;
	esac
        IFS_OLD="$IFS"
        IFS=","
        ARR_HOSTS=($TARGET_HOSTS)
        IFS=$IFS_OLD
        for x in "${ARR_HOSTS[@]}"
        do
		case $TARGET in
			"zookeeper_myid")
                                if ssh $CF_HADOOP_USER@$x [ -f $TARGET_FILE ] ; then
                                        echo -e "checking $x $TARGET file : $TARGET_FILE ........ ${CF_COL_BGREEN}ok${CF_COL_END}"
                                else
                                        echo -e "${CF_COL_BRED}$x $TARGET file does not exist...!!${CF_COL_END}"
                                        echo -e "${CF_COL_BRED}$x host need file:$TARGET_FILE ${CF_COL_END}"
                                        IS_CHECKED_DIR="FALSE"
                                fi
			;;

			*)	
                	IFS_OLD="$IFS"
                	IFS=","
                	ARR_DIRS=($TARGET_DIRS)
	                IFS=$IFS_OLD
        	        for y in "${ARR_DIRS[@]}"
                	do
                        	if ssh $CF_HADOOP_USER@$x [ -d $y ] ; then
                                	echo -e "checking $x $TARGET data dir : $y ........ ${CF_COL_BGREEN}ok${CF_COL_END}"
	                        else
        	                        echo -e "${CF_COL_BRED}$x $TARGET data dir does not exist...!!${CF_COL_END}"
                	                echo -e "${CF_COL_BRED}$x host need directory:$TARGET_DIRS ${CF_COL_END}"
                        	        IS_CHECKED_DIR="FALSE"
	                        fi
        	        done
			;;
		esac
        done
}

function make_hadoop_dir() {
        TARGET=$1
	PASSWD=$2

        case $TARGET in
                "namenode")
                TARGET_HOSTS=$CF_HOSTS;
                TARGET_DIRS=$CF_NAMENODE_DATA_DIR;
		TARGET_CHOWN_DIRS=$CF_HDFS_NN_DIR;;
                "datanode")
                TARGET_HOSTS=$CF_DATANODE_HOSTS;
                TARGET_DIRS=$CF_DATANODE_DATA_DIR;
		TARGET_CHOWN_DIRS=$CF_HDFS_DN_DIR;;
                "zookeeper")	
                TARGET_HOSTS=$CF_ZOOKEEPER_HOSTS;
                TARGET_DIRS=$CF_ZOOKEEPER_DATA_DIR;
		TARGET_CHOWN_DIRS=$CF_HDFS_NN_DIR;;
                "zookeeper_myid")
                TARGET_HOSTS=$CF_ZOOKEEPER_HOSTS;
                TARGET_FILE=$CF_ZOOKEEPER_DATA_DIR/myid;
		MYID_CNT=0;;
                *) exit;;
        esac


        IFS_OLD="$IFS"
        IFS=","
        ARR_HOSTS=($TARGET_HOSTS)
        IFS=$IFS_OLD
        for x in "${ARR_HOSTS[@]}"
        do
                case $TARGET in
                        "zookeeper_myid")
				(( MYID_CNT++ ))
				ssh $CF_HADOOP_USER@$x "echo $MYID_CNT > $CF_ZOOKEEPER_DATA_DIR/myid"					
                        ;;
                        *)
                        	IFS_OLD="$IFS"
	                        IFS=","
        	                ARR_DIRS=($TARGET_DIRS)
                	        IFS=$IFS_OLD
                        	for y in "${ARR_DIRS[@]}"
	                        do
				 	echo "make dirs ... $y"
                	        	ssh $CF_HADOOP_USER@$x "echo $PASSWD | sudo -S mkdir -p $y"
                        	done
			
	                        IFS_OLD="$IFS"
        	                IFS=","
                	        ARR_DIRS=($TARGET_CHOWN_DIRS)
                        	IFS=$IFS_OLD
	                        for y in "${ARR_DIRS[@]}"
        	                do
                	                echo "chown $CF_HADOOP_USER ... $y"
                        		ssh $CF_HADOOP_USER@$x "echo $PASSWD | sudo -S chown -R $CF_HADOOP_USER:$CF_HADOOP_USER $y"
	                        done
                        ;;
                esac
        done
}

function echo_start() {
	cf_echo_start $(basename "$0") $TARGET_HOSTS
}
function echo_end() {
	cf_echo_end ${0}
}

case $MODE in
	"hadoop") hadoop;echo_end;;
	"spark") spark;echo_end;;
	"hbase") hbase;echo_end;;
        *) print_usage;;
esac
