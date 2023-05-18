#!/bin/bash

################################################################################
# basic directory/file path
################################################################################
#kinit -k -t ~/conf/trendmap.keytab trendmap

hadoop="/home/hadoop/hadoop/bin/hadoop"
gzip="/bin/gzip"
ssh="ssh -i /home/trendmap/.ssh/id_rsa"
scp="scp -i /home/trendmap/.ssh/id_rsa"

export HADOOP_CMD=$hadoop

program_repository="/home/trendmap/association"
#program_repository="/home/trendmap/association/test"
bin_dir="$program_repository/bin"
script_dir="$program_repository/script"
conf_dir="$program_repository/conf"

local_data_dir="/home/trendmap/association/data"

# max line num per each splitted file of association output
split_line_num="1000000"

main_server="cf01"


################################################################################
# script parameters
################################################################################
# MRH : projectId 를 넣기 위해 11 -> 12 로 수정
if [[ $# -eq 12 ]]; then
  server_list_file=$1
  mode="multi"
  shift
else
  mode="single"
fi

# MRH : projectId 를 넣기 위해 10 -> 11 로 수정
if [[ $# -ne 11 ]]; then
  echo "usage: $0 [server_list_file] <projectId> keyword_freq_threshold asso_conf_file group_conf_file power_user_file asso_black_list_file asso_white_list_file start_date end_date hdfs_input_dir hdfs_output_dir"
  exit 1
fi

projectId=$1
keyword_freq_threshold=$2
asso_conf_file=$3
group_conf_file=$4
power_user_file=$5
asso_black_list_file=$6
asso_white_list_file=$7
start_date=$8
end_date=$9
hdfs_input_dir=${10}
hdfs_output_dir=${11}

if [[ $start_date == $end_date ]]; then
  date_tag=$start_date
else
  date_tag="$start_date.$end_date"
fi


################################################################################
# etc parameters (they might need appropriate settings)
################################################################################
data_dir="$local_data_dir/$projectId/$date_tag"
if [[ $mode == "single" ]]; then
  shared_data_dir=$data_dir
else
  shared_data_dir=$hdfs_output_dir/shared
fi
mem_limit=4000
#mem_limit=8000
time_out=10800


################################################################################
# functions
################################################################################

# print elapsed time
print_elapsed_time()
{
  min=`expr $SECONDS / 60`
  sec=`expr $SECONDS % 60`
  echo "# total elapsed time : $min min $sec sec"
  echo
}


# make status file in hdfs and exit script
set_status_and_exit()
{
  local message=$1
  local exit_code=$2

  $hadoop fs -rm -skipTrash $hdfs_output_dir/status >& /dev/null
  echo "$message" | $hadoop fs -put - $hdfs_output_dir/status

  echo "$message"
  exit $exit_code
}


# launch background process into the dist server
launch_dist_process()
{
  local server=$1
  local command=$2

  echo "$ssh $server \"$command && touch $data_dir/flag && $hadoop fs -copyFromLocal $data_dir/flag $shared_data_dir/flag.$server\" &"
  $ssh $server "$command && touch $data_dir/flag && $hadoop fs -copyFromLocal $data_dir/flag $shared_data_dir/flag.$server" &
}


# wait all child processes to be finished
wait_dist_process()
{
  local process=$1
  local check_interval=$2
  local timeout=$3
  local server_list=$4

  echo "# waiting $process : interval($check_interval sec), timeout($timeout)"
  local start_time=$SECONDS

  running=$server_list
  while [ -n "$running" ]; do
    echo "# still running $process at $running"
    echo
    if [[ `expr $SECONDS - $start_time` -ge $timeout ]]; then
      set_status_and_exit "   timeout during $process : $timeout sec"
    fi
    sleep $check_interval

    running=""
    for server in $server_list; do
      if ! $hadoop fs -ls $shared_data_dir/flag.$server >& /dev/null; then
        running="$running $server"
      fi
    done
  done

  $hadoop fs -rm -skipTrash $shared_data_dir/flag.* >& /dev/null

  echo "# finished"
  print_elapsed_time
}


# logging basic informations
print_basic_informations()
{
  echo "##### start #####"
  echo "# projectId          : $projectId"
  echo "# date               : `date`"
  echo "# hdfs_input_dir     : $hdfs_input_dir"
  echo "# hdfs_output_dir    : $hdfs_output_dir"
  echo "# asso_conf_file     : $asso_conf_file"
  echo "# group_conf_file    : $group_conf_file"
  echo "# local_home_dir     : $program_repository"
  echo "# local_data_dir     : $data_dir"
  echo "# doc date range     : $start_date ~ $end_date"
  echo "# mode               : $mode"
  echo
}


# get kf_file_list, kk_file_list from hdfs_input_dir
# - output variables
#   kf_list : kf_file list (hdfs paths)
#   kk_list : kk_file list (hdfs paths)
#   kf_num  : number of kf_files
#   kk_num  : number of kk_files
get_input_file_list()
{
  local hdfs_input_dir=$1
  local start_date=$2
  local end_date=$3

  local all_dates=`$hadoop fs -ls $hdfs_input_dir | sed -e "s/hdfs:\/\///" | awk '{ if (NF!=8) next; n = split($8, tokens, "/"); printf("%s\n", tokens[n]); }' | sort | uniq`
  for one_day in $all_dates; do
    if [[ $one_day -ge $start_date ]] && [[ $one_day -le $end_date ]]; then
      date_list+="$one_day "
    fi
  done

  if [ -z "$date_list" ]; then
    set_status_and_exit "# no input data for the given doc_date : $start_date ~ $end_date" 0
  fi

  echo "# available doc_dates : $date_list"
  echo

  for one_day in $date_list; do
    ls_kf+="`$hadoop fs -ls $hdfs_input_dir/$one_day/kf.txt*.gz 2> /dev/null | sed -e "s/hdfs:\/\///" | awk '{ if (NF==8) printf("%s ", $0) }'`"
    ls_kk+="`$hadoop fs -ls $hdfs_input_dir/$one_day/kk.txt*.gz 2> /dev/null | sed -e "s/hdfs:\/\///" | awk '{ if (NF==8) printf("%s ", $0) }'`"
  done

  if [ -z "$ls_kf" ] || [ -z "$ls_kk" ]; then
    set_status_and_exit "# no kf/kk files" 1
  fi

  kf_list=`echo "$ls_kf" | awk '{ for (i=8; i<=NF; i+=8) printf("hdfs:%s ", $i) }'`
  kk_list=`echo "$ls_kk" | awk '{ for (i=8; i<=NF; i+=8) printf("hdfs:%s ", $i) }'`
  kf_num=`echo "$kf_list" | awk '{ printf("%d", NF) }'`
  kk_num=`echo "$kk_list" | awk '{ printf("%d", NF) }'`
  local kf_size=`echo "$ls_kf" | awk '{ printf("%d", $5); for (i=13; i<=NF; i+=8) printf("+%d", $i); } END { printf("\n"); }' | bc`
  local kk_size=`echo "$ls_kk" | awk '{ printf("%d", $5); for (i=13; i<=NF; i+=8) printf("+%d", $i); } END { printf("\n"); }' | bc`

  echo "# kf_files : $kf_num ($kf_size bytes)"
  echo "$ls_kf" | awk '{ for (i=1; i<=NF; i+=8) { for (j=0; j<8; j++) printf("%s\t", $(i+j)); printf("\n"); } }'
  echo
  echo "# kk_files : $kk_num ($kk_size bytes)"
  echo "$ls_kk" | awk '{ for (i=1; i<=NF; i+=8) { for (j=0; j<8; j++) printf("%s\t", $(i+j)); printf("\n"); } }'
  echo
}


# initialize servers and prepare each local data directory
# - output variables
#   server_list : server list to work with
#   server_num  : number of servers
init_servers()
{
  local mode=$1
  local kk_num=$2
  local server_list_file=$3

  if [[ $mode == "single" ]]; then
    server_list=""
    server_num=1
    return
  fi

  if ! $hadoop fs -ls $server_list_file >& /dev/null; then
    set_status_and_exit "# no server list file: $server_list_file" 1
  fi

  server_list=`$hadoop fs -cat $server_list_file | awk -v main=$main_server '{ for (i=1; i<=NF; i++) if ($i!=main) printf("%s ", $i) }'`
  server_num=`echo "$server_list" | awk '{ printf("%d", NF) }'`

  if [[ $server_num -gt $kk_num ]]; then
    echo "# kk_files($kk_num) are fewer than servers($server_num)"
    server_num=$kk_num
    server_list=`echo "$server_list" | awk -v kk_num=$kk_num '{ for (i=1; i<=kk_num; i++) printf("%s ", $i); }'`
    echo "  adjusted server_list : $server_list"
    echo
  fi

  for server in $server_list; do
    $ssh $server "rm -rf $data_dir; mkdir -p $data_dir"
  done
}


# merge kf_files
# build keyword_table
# copy keyword_table to each server
build_keyword_table()
{
  local keyword_freq_threshold=$1
  local kf_list=$2

  echo "# $bin_dir/keyword_freq_merger 0 $kf_list | $gzip -1 > $data_dir/kf.all.txt.gz"
  if ! $bin_dir/keyword_freq_merger 0 $kf_list | $gzip -1 > $data_dir/kf.all.txt.gz; then
    set_status_and_exit "failed during 'keyword_freq_merger'" 1
  fi
  print_elapsed_time

  if [[ $keyword_freq_threshold -lt 2 ]]; then
    echo "# $gzip -cd $data_dir/kf.all.txt.gz | $bin_dir/keyword_table_builder $data_dir/keyword.string.gz $shared_data_dir/keyword.mphf"
    if ! $gzip -cd $data_dir/kf.all.txt.gz | $bin_dir/keyword_table_builder $data_dir/keyword.string.gz $shared_data_dir/keyword.mphf; then
      set_status_and_exit "failed during 'keyword_table_builder'" 1
    fi
  else
    echo "$gzip -cd $data_dir/kf.all.txt.gz | $bin_dir/keyword_table_builder $keyword_freq_threshold $shared_data_dir/keyword.mphf $shared_data_dir/keyword.bitmap $data_dir/keyword.pruned.string.gz $shared_data_dir/keyword.pruned.mphf"
    if ! $gzip -cd $data_dir/kf.all.txt.gz | $bin_dir/keyword_table_builder $keyword_freq_threshold $shared_data_dir/keyword.mphf $shared_data_dir/keyword.bitmap $data_dir/keyword.pruned.string.gz $shared_data_dir/keyword.pruned.mphf; then
      set_status_and_exit "failed during 'keyword_table_builder'" 1
    fi
  fi
  print_elapsed_time
}


# build keypair_tables in each server
build_keypair_table()
{
  local mem_limit=$1
  local kk_list=$2

  if [[ $mode == "single" ]]; then

    if [[ $keyword_freq_threshold -lt 2 ]]; then
      echo "$hadoop fs -cat $kk_list | $gzip -cd | $bin_dir/keypair_table_builder $mem_limit $group_conf_file $shared_data_dir/keyword.mphf $shared_data_dir/keypair.freq.1.gz $shared_data_dir/variation.freq.1.gz 2> $data_dir/log.invalid_keypair.1"
      if ! $hadoop fs -cat $kk_list | $gzip -cd | $bin_dir/keypair_table_builder $mem_limit $group_conf_file $shared_data_dir/keyword.mphf $shared_data_dir/keypair.freq.1.gz $shared_data_dir/variation.freq.1.gz 2> $data_dir/log.invalid_keypair.1; then
        set_status_and_exit "failed during 'keypair_table_builder'" 1
      fi

    else
      echo "$hadoop fs -cat $kk_list | $gzip -cd | $bin_dir/keypair_table_builder $mem_limit $group_conf_file $shared_data_dir/keyword.mphf $shared_data_dir/keyword.pruned.mphf $shared_data_dir/keyword.bitmap $shared_data_dir/keypair.freq.1.gz $shared_data_dir/variation.freq.1.gz 2> $data_dir/log.invalid_keypair.1"
      if ! $hadoop fs -cat $kk_list | $gzip -cd | $bin_dir/keypair_table_builder $mem_limit $group_conf_file $shared_data_dir/keyword.mphf $shared_data_dir/keyword.pruned.mphf $shared_data_dir/keyword.bitmap $shared_data_dir/keypair.freq.1.gz $shared_data_dir/variation.freq.1.gz 2> $data_dir/log.invalid_keypair.1; then
        set_status_and_exit "failed during 'keypair_table_builder'" 1
      fi
    fi

    print_elapsed_time

  else
    echo "# build keypair_tables at $server_list"
    echo

    $hadoop fs -rm -skipTrash $shared_data_dir/flag.* >& /dev/null

    local server_id=1
    for server in $server_list; do

      local sub_kk_list=`echo $kk_list | awk -v server_id=$server_id -v server_num=$server_num '{ for (i=server_id; i<=NF; i+=server_num) printf("%s ", $i) }'`

      if [[ $keyword_freq_threshold -lt 2 ]]; then
        launch_dist_process $server "$hadoop fs -cat $sub_kk_list | $gzip -cd | $bin_dir/keypair_table_builder $mem_limit $group_conf_file $shared_data_dir/keyword.mphf $shared_data_dir/keypair.freq.$server_id.gz $shared_data_dir/variation.freq.$server_id.gz 2> $data_dir/log.invalid_keypair.$server_id"
      else
        launch_dist_process $server "$hadoop fs -cat $sub_kk_list | $gzip -cd | $bin_dir/keypair_table_builder $mem_limit $group_conf_file $shared_data_dir/keyword.mphf $shared_data_dir/keyword.pruned.mphf $shared_data_dir/keyword.bitmap $shared_data_dir/keypair.freq.$server_id.gz $shared_data_dir/variation.freq.$server_id.gz 2> $data_dir/log.invalid_keypair.$server_id" &
      fi

      let server_id+=1
    done
    echo

    wait_dist_process keypair_table_builder 60 $time_out "$server_list"
    print_elapsed_time
  fi
}


# build representative keyword_table
select_representative_keyword()
{
  if [[ $mode == "single" ]]; then
    local var_freq_list=`ls -1 $shared_data_dir/variation.freq* | awk '{ printf("%s ", $0) }'`
  else
    local var_freq_list=`$hadoop fs -ls $shared_data_dir/variation.freq* 2> /dev/null | awk '{ printf("hdfs:%s ", $8) }'`
  fi

  if [[ $keyword_freq_threshold -lt 2 ]]; then
    echo "$bin_dir/representative_selector $data_dir/keyword.string.gz $shared_data_dir/keyword.mphf $group_conf_file $var_freq_list $shared_data_dir/representative.string.gz $shared_data_dir/representative.group"
    if ! $bin_dir/representative_selector $data_dir/keyword.string.gz $shared_data_dir/keyword.mphf $group_conf_file $var_freq_list $shared_data_dir/representative.string.gz $shared_data_dir/representative.group; then
      set_status_and_exit "failed during 'representative_selector'" 1
    fi
  else
    echo "$bin_dir/representative_selector $data_dir/keyword.pruned.string.gz $shared_data_dir/keyword.pruned.mphf $group_conf_file $var_freq_list $shared_data_dir/representative.string.gz $shared_data_dir/representative.group"
    if ! $bin_dir/representative_selector $data_dir/keyword.pruned.string.gz $shared_data_dir/keyword.pruned.mphf $group_conf_file $var_freq_list $shared_data_dir/representative.string.gz $shared_data_dir/representative.group; then
      set_status_and_exit "failed during 'representative_selector'" 1
    fi
  fi

  print_elapsed_time
}


# merge and split keypair_tables
merge_keypair_tables()
{
  local server_num=$1

  if [[ $mode == "single" ]]; then
    local keypair_freq_list=`ls -1 $shared_data_dir/keypair.freq* | awk '{ printf("%s ", $0) }'`
  else
    local keypair_freq_list=`$hadoop fs -ls $shared_data_dir/keypair.freq* 2> /dev/null | awk '{ printf("hdfs:%s ", $8) }'`
  fi

  echo "$bin_dir/merge_key_pair_freq $server_num $shared_data_dir/keypair.all_freq.gz $shared_data_dir/keypair.unigram.gz $keypair_freq_list"
  if ! $bin_dir/merge_key_pair_freq $server_num $shared_data_dir/keypair.all_freq.gz $shared_data_dir/keypair.unigram.gz $keypair_freq_list; then
    set_status_and_exit "failed during 'merg_key_pair_freq'" 1
  fi
  print_elapsed_time
}


# select associations
select_association()
{
  echo "$bin_dir/power_user_to_id $power_user_file $shared_data_dir/representative.string.gz $group_conf_file $shared_data_dir/representative.group $shared_data_dir/power_user.id"
  if ! $bin_dir/power_user_to_id $power_user_file $shared_data_dir/representative.string.gz $group_conf_file $shared_data_dir/representative.group $shared_data_dir/power_user.id; then
    set_status_and_exit "failed during 'power_user_to_id'" 1
  fi
  echo

  if [[ $mode == "single" ]]; then
    echo "$bin_dir/extract_association $shared_data_dir/keyword.mphf $shared_data_dir/power_user.id $asso_conf_file $shared_data_dir/representative.string.gz $group_conf_file $shared_data_dir/representative.group $shared_data_dir/keypair.unigram.gz $shared_data_dir/keypair.all_freq.1.gz $asso_white_list_file $asso_black_list_file $hdfs_output_dir/association.1.%d.gz $split_line_num"
    if ! $bin_dir/extract_association $shared_data_dir/keyword.mphf $shared_data_dir/power_user.id $asso_conf_file $shared_data_dir/representative.string.gz $group_conf_file $shared_data_dir/representative.group $shared_data_dir/keypair.unigram.gz $shared_data_dir/keypair.all_freq.1.gz $asso_white_list_file $asso_black_list_file $hdfs_output_dir/association.1.%d.gz $split_line_num; then
      set_status_and_exit "failed during 'extract_association'" 1
    fi
    print_elapsed_time

  else
    echo "# select association at $server_list"
    $hadoop fs -rm -skipTrash $shared_data_dir/flag.* >& /dev/null

    local server_id=1
    for server in $server_list; do
      launch_dist_process $server "$bin_dir/extract_association $shared_data_dir/keyword.mphf $shared_data_dir/power_user.id $asso_conf_file $shared_data_dir/representative.string.gz $group_conf_file $shared_data_dir/representative.group $shared_data_dir/keypair.unigram.gz $shared_data_dir/keypair.all_freq.$server_id.gz $asso_white_list_file $asso_black_list_file $hdfs_output_dir/association.$server_id.%d.gz $split_line_num"
      let server_id+=1
    done
    echo

    wait_dist_process extract_association 60 $time_out "$server_list"
    print_elapsed_time
  fi
}


# snapshot data files
snapshot_data_files()
{
  echo "# main server data files (ls -l $data_dir)"
  ls -l $data_dir
  echo

  if [[ $mode == "multi" ]]; then
    for server in $server_list; do
      echo "# ls -l $server:$data_dir"
      $ssh $server "ls -l $data_dir"
      echo
    done
  fi

  echo "# hdfs data files (hadoop fs -ls $hdfs_output_dir/shared)"
  $hadoop fs -ls $hdfs_output_dir/shared 2> /dev/null
  echo

  echo "##### finished #####"
  echo "# date : `date`"
  print_elapsed_time
}


################################################################################
# main script
################################################################################


{
  mkdir -p $data_dir
  rm -f $data_dir/*

  $hadoop fs -rm -skipTrash $hdfs_output_dir/* >& /dev/null
  $hadoop fs -mkdir $hdfs_output_dir $hdfs_output_dir/shared >& /dev/null
}

{
  print_basic_informations

  get_input_file_list $hdfs_input_dir $start_date $end_date

  init_servers $mode $kk_num $server_list_file

  build_keyword_table $keyword_freq_threshold "$kf_list"

  build_keypair_table $mem_limit "$kk_list"

  select_representative_keyword

  merge_keypair_tables $server_num

  select_association

  snapshot_data_files
} >& $data_dir/log.main

{
  $hadoop fs -rmr -skipTrash $hdfs_output_dir/status $hdfs_output_dir/log.* $hdfs_output_dir/shared >& /dev/null

  echo "complete" | $hadoop fs -put - $hdfs_output_dir/status

  $hadoop fs -copyFromLocal $data_dir/log.* $hdfs_output_dir/ >& /dev/null
  rm -rf $data_dir >& /dev/null

  if [[ $mode == "multi" ]]; then
    for server in $server_list; do
      $ssh $server "$hadoop fs -copyFromLocal $data_dir/log.* $hdfs_output_dir/ >& /dev/null"
      $ssh $server "rm -rf $data_dir >& /dev/null"
    done
  fi
}
