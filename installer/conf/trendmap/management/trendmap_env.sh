#!/bin/bash

if [ "${TRENDMAP_ENV_LOADED}" == "TRUE" ]; then
   echo "trendmap_env.sh have been already loaded."
else

#kinit -k -t ~/conf/trendmap.keytab trendmap

export TRENDMAP_ENV_LOADED=TRUE

export JAVA_HOME=/usr/java/jdk1.8.0_291/jre

export LANG=ko_KR.UTF-8

export TRENDMAP_HOME=/home/trendmap
export TRENDMAP_CONF_DIR=${TRENDMAP_HOME}/conf
export TRENDMAP_LIB_DIR=${TRENDMAP_HOME}/lib
export TRENDMAP_LOG_DIR=$TRENDMAP_HOME/logs
export TRENDMAP_JAR=${TRENDMAP_LIB_DIR}/trendmap-analysis-1.0.0-SNAPSHOT.jar

# LIBJARS 와 HADOOP_CLASSPATH 가 같은 내용일 필요는 없다

##############################################################################################
# LIBJARS : MapReduce 에서 사용할 jar 파일들
# => 이 파일들은 hdfs 의 .staging 디렉토리를 통해서 각 노드로 복사되어 M/R 실행시 사용된다.
##############################################################################################
LIBJARS=${LIBJARS},${TRENDMAP_LIB_DIR}/trendmap-nlp-jeromq-1.0.0-SNAPSHOT-jar-with-dependencies.jar
LIBJARS=${LIBJARS},${TRENDMAP_LIB_DIR}/trendmap-core-1.0.0-SNAPSHOT.jar
LIBJARS=${LIBJARS},${TRENDMAP_LIB_DIR}/trendmap-project-1.0.0-SNAPSHOT.jar
LIBJARS=${LIBJARS},${TRENDMAP_LIB_DIR}/twitter-text-1.12.1.jar
LIBJARS=${LIBJARS},${TRENDMAP_LIB_DIR}/commons-lang-2.6.jar
LIBJARS=${LIBJARS},`hbase mapredcp | tr  ":" ","`
export LIBJARS=`echo $LIBJARS | sed -e "s/[ ]//g" -e "s/,,*,/,/g" -e "s/^,//" -e "s/,$//"`

##############################################################################################
# HADOOP_CLASSPATH : MapReduce Driver (Tool) 에서 사용할 classpath (jars, dirs ...)
# => 이 파일(및 디렉토리) 들은 Driver 구동시에만 사용된다.
##############################################################################################
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TRENDMAP_CONF_DIR}
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TRENDMAP_LIB_DIR}/trendmap-analysis-1.0.0-SNAPSHOT.jar
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TRENDMAP_LIB_DIR}/trendmap-core-1.0.0-SNAPSHOT.jar
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TRENDMAP_LIB_DIR}/trendmap-project-1.0.0-SNAPSHOT.jar
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TRENDMAP_LIB_DIR}/twitter-text-1.12.1.jar
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TRENDMAP_LIB_DIR}/commons-lang-2.6.jar
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:`hbase mapredcp`
export HADOOP_CLASSPATH;

export NUM_SERVER=5

export PATH=$TRENDMAP_HOME/bin:$TRENDMAP_HOME/bin/mapreduce:$TRENDMAP_HOME/bin/util:$PATH
fi
