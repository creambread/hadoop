#!/bin/bash

function print_usage() {
	echo "Usage : ${0} <mode> <srcfile> <name> [value]"
	echo ""
	echo "   mode:"
	echo ""
	echo "add	add xml property need value"
	echo "delete	delete xml property"
	echo "update	update xml property need value"
	echo ""
	echo "need xmlstarlet package"
	echo ""
	echo "   Supported xml format:" 
	echo ""
	echo "<configuration>"
	echo " <property>"
	echo "  <name>_your_name_</name>"
	echo "  <value>_your_value_</value>"
	echo " </property>"
	echo "</configuration>"
	echo ""
}
function endScript() {
	echo "end ${0}"
	exit;
}

if [ $# -lt 3 ]; then
	print_usage;
	exit;
fi

MODE=$1; shift;
SRC_FILE=$1; shift;
NAME=$1; shift;
VALUE=$1; shift;

if ! [ -f "$SRC_FILE" ]; then
    echo "$SRC_FILE src file not found."
    endScript;
fi

prop_exists=$(xmlstarlet sel -t -c "boolean(//property[name='$NAME'])" $SRC_FILE)

function add() {
	echo ADD MODE
	### STEP 1 check property
	if [[ $prop_exists == "true" ]] ; then
	        echo "STEP1 $NAME existed property."
	        endScript;
	else
	        echo "STEP1 $NAME checked. create available."
	fi

	### STEP 2 add property
	[ "$prop_exists" = "false" ] && xmlstarlet ed --inplace \
	        -s "//configuration" -t elem -n "property" -v '' \
	        -s "//configuration/property[last()]" -t elem -n "name" -v "$NAME" \
	        -s "//configuration/property[last()]" -t elem -n "value" -v "$VALUE" \
	$SRC_FILE
	echo "STEP2 added name=$NAME value=$VALUE property."
}

function delete() {
	echo DELETE MODE
	### STEP 1 check property
	echo STEP1 is exists target property? $node_exists
        if [[ $prop_exists == "true" ]] ; then
                echo "STEP1 $NAME existed property."
        else
                echo "STEP1 $NAME name not found."
		endScript;
        fi

	### STEP 2 delete property
	[ "$prop_exists" = "true" ] && xmlstarlet ed --inplace \
		-d "//property[name='$NAME']" $SRC_FILE

	if [[ $prop_exists == "true" ]] ; then
		echo "STEP2 deleted $NAME."
	fi
}

function update() {
	echo UPDATE MODE
	### STEP 1 check property
        if [[ $prop_exists == "true" ]] ; then
                echo "STEP1 $NAME existed property."
        else
                echo "STEP1 $NAME name not found."
                endScript;
        fi
	
	### STEP 2 update property
	xmlstarlet ed --inplace -u "//property[name='$NAME']/value/node()" -v "$VALUE" $SRC_FILE
	echo "STEP2 updated $NAME"
}

case $MODE in
        "add") add;;
        "delete") delete;;
        "update") update;;
        *) print_usage;;
esac

### call end funtion 
endScript
