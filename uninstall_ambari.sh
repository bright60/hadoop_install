#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Updated by BX, on 2008-05-23


# Change log:

# version: v4
#

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# uncomment the follow line to enable the verbose message to show what is being done
if [ "$1" = "-x" ] || [ "$1" = "-debug" ]
then
        echo "=========== Set the shell to verbose debug mode ... ============"
        set -x
fi

#CentOS release 6.9 (Final)
#CentOS Linux release 7.3.1611 (Core)
cat /etc/redhat-release
ostype=`cat /etc/redhat-release|awk '{print $1}'`
version=''

[ "$ostype" == "CentOS" ] && version=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
mainversion=$version

echo "ostype: $ostype"
echo "version: $mainversion.x.x"

hostname -f
hostnamectl status

#if [ "$ostype" != "CentOS" ] || ( [ "$mainversion" != "6" ] && [ "$mainversion" != "7" ] ); then
if [ "$ostype" != "CentOS" ] || [ "$mainversion" != "7" ]; then
	echo "*****: The current OS is $ostype, main version: $version, this installation scriptss only support CentOS 7.x !"
fi

#取得集群的所有主机名，这里需要注意：/etc/hosts配置的IP和主机名只能用一个空格分割
#hostList=$(cat /etc/hosts | tail -n +3 | cut -d ' ' -f 2)

#去掉空行和注释行
hostList=$(cat /etc/hosts | grep -Ev "^$|[#;]" | tail -n +3 | cut -d ' ' -f 2)

alterNativesDir=/etc/alternatives/
ssh_command=ssh
host=""

BASEDIR=$(pwd)

source $BASEDIR/scripts/config.sh
source $BASEDIR/scripts/common-util.sh

# Remove installation log -----
[ -f $BASEDIR/log/uninstall.log ] && mv $BASEDIR/log/uninstall.log $BASEDIR/log/uninstall.log.$(date +%Y-%m-%d_%Hh%Mm%Ss)
[ -d $BASEDIR/log ] || mkdir -p $BASEDIR/log


stop_ambari_services()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""
	echo "* Stop ambari-server and ambari-agent"
	#ambari-server stop
	#ambari-agent stop
	$ssh_command $host "ambari-server stop"
	$ssh_command $host "ambari-agent stop"

	echo ""
	echo "Done, $FUNCNAME"
}

remove_ambari_services()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo "* Remove all services"
	for u in ambari flume hadoop hdfs hbase hive httpfs hue impala llama mapred oozie solr spark sqoop sqoop2 yarn zookeeper ranger storm tez pig slider smartsense nagios
		do 
			echo "$u" 

			echo "ps -u $u -o pid="
			prog_pid=`ps -u $u -o pid=`
			echo "$u $prog_pid" 
			if [ ! -z "$prog_pid" ]; then
				kill "$prog_pid"
			fi
		
			echo ""
			echo "remove all services..."
			echo "yum -y remove $u*"
			$ssh_command $host "yum -y remove $u*"
			$ssh_command $host "yum -y erase ambari-server"
			$ssh_command $host "yum -y erase ambari-agent"
			
		done

	$ssh_command $host "yum remove -y postgresql"
	
	$ssh_command $host "rpm -qav | grep ambari-infra*"
	$ssh_command $host "rpm -qav | grep ambari-infra* | xargs rpm -e --nodeps"

	$ssh_command $host "rpm -qav | grep ambari-metrics*"
	$ssh_command $host "rpm -qav | grep ambari-metrics* | xargs rpm -e --nodeps"

	$ssh_command $host "rpm -qav | grep atlas-metadata*"
	$ssh_command $host "rpm -qav | grep atlas-metadata* | xargs rpm -e --nodeps"

	$ssh_command $host "rpm -qav | grep bigtop-jsvc"
	$ssh_command $host "rpm -qav | grep bigtop-jsvc | xargs rpm -e --nodeps"

	$ssh_command $host "rpm -qav | grep bigtop-tomcat"
	$ssh_command $host "rpm -qav | grep bigtop-tomcat | xargs rpm -e --nodeps"

	$ssh_command $host "rpm -qav | grep ambari-infra-solr-client"
	$ssh_command $host "rpm -qav | grep ambari-infra-solr-client | xargs rpm -e --nodeps"

	$ssh_command $host "rpm -qav | grep ambari-infra-solr"
	$ssh_command $host "rpm -qav | grep ambari-infra-solr | xargs rpm -e --nodeps"

	$ssh_command $host "rpm -qav | grep hdp-select"
	$ssh_command $host "rpm -qav | grep hdp-select | xargs rpm -e --nodeps"
 
	$ssh_command $host "rpm -qav | grep oracle-j2sdk"
	$ssh_command $host "rpm -qav | grep oracle-j2sdk | xargs rpm -e --nodeps"
	
	echo ""
	echo "Done, $FUNCNAME"
}

remove_ambari_data()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""

	echo "* Remove all data ..."
	echo ""
				
	echo ""
	echo "Start to execute the remove operations..."
	echo "remove all data..."
	echo ""
	
	$ssh_command $host "rm -rfv /hadoop/*"
	$ssh_command $host "rm -rfv /etc/ambari*"
	$ssh_command $host "rm -rfv /etc/zookeeper/"
	$ssh_command $host "rm -rfv /etc/ranger*"
	$ssh_command $host "rm -rfv /etc/rc.d/init.d/ranger*"
	$ssh_command $host "rm -rfv /etc/hadoop/"
	$ssh_command $host "rm -rfv /etc/hadoop/"
	$ssh_command $host "rm -rfv /etc/hbase/"
	$ssh_command $host "rm -rfv /etc/hive"
	$ssh_command $host "rm -rfv /usr/hdp/"
	$ssh_command $host "rm -rfv /etc/zookeeper/"
	$ssh_command $host "rm -rfv /tmp/ambari-qa"
	$ssh_command $host "rm -rfv /tmp/sqoop-ambari-qa/"
	$ssh_command $host "rm -rfv /kafka-logs/"
	$ssh_command $host "rm -rfv /var/lib/ambari*"
	$ssh_command $host "rm -rfv /var/lib/hive2*"
	$ssh_command $host "rm -rfv /var/run/kafka/"
	$ssh_command $host "rm -rfv /etc/flume"
	$ssh_command $host "rm -rfv /etc/hive-hcatalog"
	$ssh_command $host "rm -rfv /etc/hive-webhcat"
	$ssh_command $host "rm -rfv /etc/phoenix"
	$ssh_command $host "rm -rfv /etc/ambari-metrics-collector"
	$ssh_command $host "rm -rfv /etc/ambari-metrics-monitor"
	$ssh_command $host "rm -rfv /tmp/hdfs"
	$ssh_command $host "rm -rfv /tmp/hcat"	
	$ssh_command $host "rm -rfv /etc/kafka"
	$ssh_command $host "rm -rfv /etc/oozie"	
	$ssh_command $host "rm -rfv /etc/storm"	
	$ssh_command $host "rm -rfv /etc/tez"
	$ssh_command $host "rm -rfv /etc/falcon"
	$ssh_command $host "rm -rfv /etc/slider"	
	$ssh_command $host "rm -rfv /etc/pig"
	$ssh_command $host "rm -rfv /etc/ranger"
	$ssh_command $host "rm -rfv /etc/ambari*"
	
	$ssh_command $host "rm -rfv /var/log/ambari*"
	$ssh_command $host "rm -rfv /var/log/hadoop"	
	$ssh_command $host "rm -rfv /var/log/hbase"
	$ssh_command $host "rm -rfv /var/log/hive"
	$ssh_command $host "rm -rfv /var/log/oozie" 	
	$ssh_command $host "rm -rfv /var/log/sqoop"	
	$ssh_command $host "rm -rfv /var/log/zookeeper"
	$ssh_command $host "rm -rfv /var/log/flume"
	$ssh_command $host "rm -rfv /var/log/storm"	
	$ssh_command $host "rm -rfv /var/log/hive-hcatalog"
	$ssh_command $host "rm -rfv /var/log/falcon"
	$ssh_command $host "rm -rfv /var/log/webhcat" 	
	$ssh_command $host "rm -rfv /var/log/hadoop-hdfs"
	$ssh_command $host "rm -rfv /var/log/hadoop-yarn"	
	$ssh_command $host "rm -rfv /var/log/hadoop-mapreduce"
	$ssh_command $host "rm -rfv /var/log/spark"
	$ssh_command $host "rm -rfv /var/log/ranger" 	
	$ssh_command $host "rm -rfv /var/log/smartsense"

	$ssh_command $host "rm -rfv /var/lib/ambari*"
	$ssh_command $host "rm -rfv /usr/lib/flume"
	$ssh_command $host "rm -rfv /usr/lib/storm"	
	$ssh_command $host "rm -rfv /var/lib/hive"
	$ssh_command $host "rm -rfv /var/lib/oozie" 	
	$ssh_command $host "rm -rfv /var/lib/zookeeper"
	$ssh_command $host "rm -rfv /var/lib/flume"
	$ssh_command $host "rm -rfv /var/lib/hadoop-hdfs"
	$ssh_command $host "rm -rfv /var/lib/slider"
	$ssh_command $host "rm -rfv /var/lib/ranger"	
	$ssh_command $host "rm -rfv /var/tmp/oozie"
	$ssh_command $host "rm -rfv /var/tmp/sqoop"	
	$ssh_command $host "rm -rfv /tmp/hive"
	$ssh_command $host "rm -rfv /tmp/hadoop-hdfs"
	$ssh_command $host "rm -rfv /etc/sqoop"
	$ssh_command $host "rm -rfv /var/log/ambari-metrics-collector"
	$ssh_command $host "rm -rfv /var/log/ambari-metrics-monitor"
	$ssh_command $host "rm -rfv /usr/lib/ambari-metrics-collector"	
	$ssh_command $host "rm -rfv /var/lib/hadoop-yarn"
	$ssh_command $host "rm -rfv /var/lib/hadoop-mapreduce"
	$ssh_command $host "rm -rfv /var/lib/ambari-metrics-collector"
	$ssh_command $host "rm -rfv /var/log/kafka"

	$ssh_command $host "rm -rfv /tmp/hive"
	$ssh_command $host "rm -rfv /tmp/nagios"
	$ssh_command $host "rm -rfv /tmp/ambari-qa"
	$ssh_command $host "rm -rfv /tmp/sqoop-ambari-qa"
	$ssh_command $host "rm -rfv /tmp/hadoop-hive"
	$ssh_command $host "rm -rfv /tmp/hadoop-nagios"
	$ssh_command $host "rm -rfv /tmp/hadoop-hcat"
	$ssh_command $host "rm -rfv /tmp/hadoop-ambari-qa"
	$ssh_command $host "rm -rfv /tmp/hsperfdata*"

	$ssh_command $host "rm -rfv /tmp/hadoop-yarn"
	$ssh_command $host "rm -rfv /hadoop/zookeeper" 	
	$ssh_command $host "rm -rfv /hadoop/hdfs"
	$ssh_command $host "rm -rfv /kafka-logs"	
	$ssh_command $host "rm -rfv /etc/storm-slider-client"
				
	#删除快捷方式				
	$ssh_command $host "cd $alterNativesDir"
	$ssh_command $host "rm -rfv $alterNativesDir/hadoop-etc"
	$ssh_command $host "rm -rfv $alterNativesDir/zookeeper-conf"
	$ssh_command $host "rm -rfv $alterNativesDir/hbase-conf"
	$ssh_command $host "rm -rfv $alterNativesDir/hadoop-log"
	$ssh_command $host "rm -rfv $alterNativesDir/hadoop-lib"
	$ssh_command $host "rm -rfv $alterNativesDir/hadoop-default"
	$ssh_command $host "rm -rfv $alterNativesDir/oozie-conf"
	$ssh_command $host "rm -rfv $alterNativesDir/hcatalog-conf"
	$ssh_command $host "rm -rfv $alterNativesDir/hive-conf"
	$ssh_command $host "rm -rfv $alterNativesDir/hadoop-man"
	$ssh_command $host "rm -rfv $alterNativesDir/sqoop-conf"
	$ssh_command $host "rm -rfv $alterNativesDir/hadoop-confone"
	
	echo ""
	echo "Done, $FUNCNAME"
}

remove_ambari_users()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo "* Remove all users"
	echo ""

	#ps -u ambari-qa | awk '{print $1}' | grep -vi pid | xargs kill -9 && userdel ambari-qa
	$ssh_command $host "ps -u ambari-qa | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u hadoop | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u accumulo | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u infra-solr | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u ams | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u atlas | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u druid | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u hbase | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u hdfs | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u users | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u hive | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u kafka | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u knox | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u logsearch | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u mapred | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u oozie | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u ranger | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u kms | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u livy | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u spark | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u sqoop | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u storm | awk '{print $1}' | grep -vi pid | xargs kill -9"
	$ssh_command $host "ps -u yarn | awk '{print $1}' | grep -vi pid | xargs kill -9"
	$ssh_command $host "ps -u zookeeper | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u solr | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u sentry | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u hue | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u httpfs | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u kudu | awk '{print $1}' | grep -vi pid | xargs kill -9" 
	$ssh_command $host "ps -u impala | awk '{print $1}' | grep -vi pid | xargs kill -9" 
 
	$ssh_command $host "userdel -rf ambari-qa"
	$ssh_command $host "userdel -rf hadoop"
	$ssh_command $host "userdel -rf accumulo"
 	$ssh_command $host "userdel -rf infra-solr"
	$ssh_command $host "userdel -rf ams"
	$ssh_command $host "userdel -rf atlas"
	$ssh_command $host "userdel -rf druid"
	$ssh_command $host "userdel -rf hbase"
	$ssh_command $host "userdel -rf hdfs"
	$ssh_command $host "userdel -rf users"
	$ssh_command $host "userdel -rf hive"
	$ssh_command $host "userdel -rf kafka" 	
	$ssh_command $host "userdel -rf knox"
	$ssh_command $host "userdel -rf logsearch"
	$ssh_command $host "userdel -rf mapred"
	$ssh_command $host "userdel -rf oozie"
	$ssh_command $host "userdel -rf ranger"
	$ssh_command $host "userdel -rf kms"
	$ssh_command $host "userdel -rf livy"
	$ssh_command $host "userdel -rf spark"
	$ssh_command $host "userdel -rf sqoop"
	$ssh_command $host "userdel -rf storm"
	$ssh_command $host "userdel -rf tez"
	$ssh_command $host "userdel -rf yarn-ats"
	$ssh_command $host "userdel -rf yarn"
	$ssh_command $host "userdel -rf zeppelin"
	$ssh_command $host "userdel -rf zookeeper"	
	
	$ssh_command $host "userdel -rf solr"
	$ssh_command $host "userdel -rf sentry"
	$ssh_command $host "userdel -rf hue"
	$ssh_command $host "userdel -rf httpfs"
	$ssh_command $host "userdel -rf kudu"
	$ssh_command $host "userdel -rf impala"
 
	$ssh_command $host "rm -rfv /home/atlas"
	$ssh_command $host "rm -rfv /home/accumulo"
	$ssh_command $host "rm -rfv /home/hbase"
	$ssh_command $host "rm -rfv /home/hive"
	$ssh_command $host "rm -rfv /home/oozie"
	$ssh_command $host "rm -rfv /home/storm"
	$ssh_command $host "rm -rfv /home/yarn"
	$ssh_command $host "rm -rfv /home/ambari-qa"
	$ssh_command $host "rm -rfv /home/falcon"
	$ssh_command $host "rm -rfv /home/hcat"
	$ssh_command $host "rm -rfv /home/kafka"
	$ssh_command $host "rm -rfv /home/mahout"
	$ssh_command $host "rm -rfv /home/spark"
	$ssh_command $host "rm -rfv /home/tez"
	$ssh_command $host "rm -rfv /home/zookeeper"
	$ssh_command $host "rm -rfv /home/flume"
	$ssh_command $host "rm -rfv /home/hdfs"
	$ssh_command $host "rm -rfv /home/knox"
	$ssh_command $host "rm -rfv /home/mapred"
	$ssh_command $host "rm -rfv /home/sqoop"

	echo ""
	echo "Done, $FUNCNAME"
}
	
remove_ambari_database()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""
	echo "* Remove external databases"
	echo ""
	echo "removing database ..."
	
	mysql_command_path=`which mysql`
       	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS < $BASEDIR/conf/database/uninstall-ambari-mysql-db.sql && echo "done 1/1"
	
	echo ""
	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS -e"show databases"

	echo ""
	echo "Done, $FUNCNAME"
}
 
uninstall_ambari()
{
	main_start_time=$(date +%s)
	
	echo ""
	echo "call $FUNCNAME ..."
	echo "Now to uninstall on $host"
	echo ""

	while true
	do
		read -r -p "Are You Sure to remove ambari? [yes/no] " input
		case $input in
			yes)
				echo "removing ambari ..."
				stop_ambari_services
				remove_ambari_services
				remove_ambari_data
				remove_ambari_users
				remove_ambari_database

				break	
				;;
		
			no)
				echo "nothing to remove ..."
				break
				;;
			*)
				echo "invalid input, please re-input..."
				#exit 1
				;;
		esac
	done
	echo ""

	main_end_time=$(date +%s)
	main_cost_time=$[ $main_end_time-$main_start_time ]

	echo "== master time spend: $main_cost_time(s), $(($main_cost_time/60))min $(($main_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""
	
}

echo " "
echo "*** To run the script with "-x" in debug mode: $0 -x"
echo "************************************************************************************************************************** "
echo "*** This script will uninstall cloudera, remove data and database..."
echo "************************************************************************************************************************** "
echo ""
echo "============================================================"
#read -p $'Please type the password to confirm before uninstalling: \x0a' pass
read -r -p 'Please type the password to confirm before uninstalling: ' pass

if [ "$pass" == "$uninstall_password" ];then
	echo ""
	echo "Start to execute the remove operations..."
	#read -p $'Please type the host to uninstall: \x0a' input
	read -r -p "Please type the host name to uninstall: " input
	host=$input
 
	if ping_test $host ; then
		uninstall_ambari 2>&1 | tee -a $BASEDIR/log/uninstall.log
		echo ""
	else
		echo -e "$logPre======>$host is Unreachable,please check '/etc/hosts' file"
		echo "Nothing to do..."
		echo ""
		exit 1
	fi
	
else
	
	echo ""
	echo "password is wrong, nothing to do..."
	echo ""
fi


