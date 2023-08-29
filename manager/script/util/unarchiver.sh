#!/bin/bash

function print_usage() {
	echo "Usage : ${0} <hadoop|spark|hbase|zookeeper|java|jdk> <srcfile> <destdir>"
	echo " "
	echo "srcfile	: source file - unarchiver only support tar.gz srcfile"
	echo "destdir	: destination directory"
}
function endScript() {
	echo "end script"
	exit;
}

if [ $# != 3 ] || [[ $2 != *".tar.gz" && $2 != *".tgz" ]] ; then
	echo tests;
	print_usage
	exit;
fi

TARGET=$1
SRC_FILE=$2
DEST_DIR=$3

### STEP 1 check dest directory ...
if [ -d $DEST_DIR ] 
then
	echo "STEP1 Create Directory $DEST_DIR exists."
else
	echo "STEP1 Create Directory $DEST_DIR done."
	mkdir -p $DEST_DIR
fi

### STEP 2 unarchive ...
if [[ $SRC_FILE == *".tar.gz" || $SRC_FILE == *".tgz" ]] ; then
	tar -xf $SRC_FILE -C $DEST_DIR
	echo "STEP2 Unarchive $SRC_FILE"
else
	echo "STEP2 Unarchive fail"
	endScript
fi

### STEP 3 active symbolic link ...
GREP_TARGET="$TARGET"
if [ $TARGET == "java" ] ; then
GREP_TARGET="jdk"
fi

if [[ $SRC_FILE == *".tar.gz" || $SRC_FILE == *".tgz" ]] ; then
	
	#get folder name 
	OLD_IFS="$IFS"
	IFS=" "
	STR_ARRAY=$(ls $DEST_DIR | grep $GREP_TARGET)
	IFS="$OLD_IFS"
	INSTALLED_NAME=${STR_ARRAY[0]}

	#echo DEBUG $INSTALLED_NAME
	cd $DEST_DIR
	ln -s $INSTALLED_NAME $TARGET
	echo "STEP3 Active Symbolic Link $TARGET"
fi

#sudo chown $USER:$USER -R $DEST_DIR/$TARGET
#sudo chown $USER:$USER -R $DEST_DIR/$INSTALLED_NAME

echo done.
