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

BASEDIR=$(pwd)

alterNativesDir=/etc/alternatives/
ssh_command=ssh
host=""

source $BASEDIR/scripts/config.sh
source $BASEDIR/scripts/common-util.sh

# Remove installation log -----
[ -f $BASEDIR/log/uninstall.log ] && mv $BASEDIR/log/uninstall.log $BASEDIR/log/uninstall.log.$(date +%Y-%m-%d_%Hh%Mm%Ss)
[ -d $BASEDIR/log ] || mkdir -p $BASEDIR/log


#Refer to: https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_uninstall_cm.html
stop_cloudera_services()
{
	main_start_time=$(date +%s)
	
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""
	echo "* Stop all Services"
	echo "1. For each cluster:"
	echo " ---a. On the Home > Status tab, click (dropdown list) to the right of the cluster name and select Stop"
	echo " ---b. Click Stop in the confirmation screen."
	echo "2. For each service:"
	echo " ---a. On the Home > Status tab, click (dropdown list) to the right of the Cloudera Management Service entry and select Stop"
	echo ""
	echo "* Deactivate and Remove Parcels"
	echo "1. Click the parcel indicator in the main navigation bar."
	echo "2. In the Location selector on the left, select All Clusters."
	echo "3. For each activated parcel, select Actions > Deactivate. When this action has completed, the parcel button changes to Activate."
	ech  "4. For each activated parcel, select Actions > Remove from Hosts. When this action has completed, the parcel button changes to Distribute.2. "
	echo "5. For each activated parcel, select Actions > Delete. This removes the parcel from the local parcel repository."
	echo "6. Remove parces from local repository, in each host, such as:"
	echo " rm -rfv /opt/cloudera/parcel-cache/*"
	echo " rm -rfv /opt/cloudera/parcels/*"
	
	$ssh_command $host "rm -rfv /opt/cloudera/parcel-cache/*"
	$ssh_command $host "rm -rfv /opt/cloudera/parcels/*"

	echo ""
	echo "Done, $FUNCNAME"
}

delete_cloudera_cluster()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""
	echo "* Delete the Cluster"
	echo "1. On the Home page, Click the drop-down list next to the cluster you want to delete and select Delete."

	echo ""
	echo "* Uninstall the Cloudera Manager Server"
	echo "1. stop cloudera-scm-server: systemctl stop cloudera-manager-server"
	$ssh_command $host "systemctl stop cloudera-manager-server"
	$ssh_command $host "systemctl stop cloudera-manager-agent"
	$ssh_command $host "systemctl stop cloudera-manager-daemon"

	echo "2. stop cloudera-scm-server-db (NOT need if use mysql db): systemctl stop cloudera-scm-server-db"
	$ssh_command $host "systemctl stop cloudera-scm-server-db"

	echo "3. remove cloudera-manager-serve amd yum remove cloudera-manager-server-db-2 (Not need if use mysql)"
	echo ""
	while true
	do
		read -r -p "Are You Sure to remove cloudera-manager-serve? [yes/no] " input
		case $input in
			yes)
				echo ""
				echo "Start to execute the remove operations..."
				#yum -y remove cloudera-manager-server
				#yum -y remove cloudera-manager-server-db-2
				
				$ssh_command $host "yum -y remove cloudera-manager-server"
				$ssh_command $host "yum -y remove cloudera-manager-server-db-2"
				echo ""
				break
				;;
			no)
				echo ""
				echo "nothing to do..."
				echo ""
				break
				;;
			*)
				echo ""
				echo "Invalid input, please re-input ..."
				;;
		esac
	done
	
	echo ""
	echo "Done, $FUNCNAME"
}
	
uninstall_cloudera_software()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""
	echo "* Uninstall Cloudera Manager Agent and Managed Software"
	echo "1. stop cloudera-scm-agent: systemctl stop supervisord"
	#systemctl stop supervisord
	#systemctl stop cloudera-scm-agent
	
	$ssh_command $host "systemctl stop supervisord"
	$ssh_command $host "systemctl stop cloudera-scm-agent"
	$ssh_command $host "systemctl stop cloudera-scm-server"

	echo "2. remove all:  yum remove 'cloudera-manager-*'"
	echo ""
	while true
	do
		read -r -p "Are You Sure to remove cloudera-manager-*? [yes/no] " input
		case $input in
			yes)
				echo ""
				echo "Start to execute the remove operations..."
				$ssh_command $host "yum -y remove 'cloudera-manager-*'"
				echo ""
				break
				;;
			no)	
				echo ""
				echo "nothing to do..."
				echo ""
				break
				;;
			*)
				echo ""
				echo "Invalid input, please re-input ..."
				echo ""
				;;
		esac
	done

	echo "run the clean command: yum clean all"
	$ssh_command $host "yum clean all"
	
	
	echo "Done, $FUNCNAME"
}

remove_cloudera_data()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""
	while true
	do
		read -r -p "Are You Sure to remove all data? [yes/no] " input
		case $input in
			yes)
				echo ""
				echo "* Remove Cloudera Manager and User Data"
				for u in cloudera-scm flume hadoop hdfs hbase hive httpfs hue impala llama mapred oozie solr spark sqoop sqoop2 yarn zookeeper
					do 
						#echo "$u" 
						echo "ps -u $u -o pid="
						#prog_pid=`ps -u $u -o pid=`
						prog_pid=`$ssh_command $host "ps -u $u -o pid="`
						echo "$u $prog_pid" 
						if [ ! -z "$prog_pid" ]; then
							$ssh_command $host “kill $prog_pid”
						fi
						#kill "$(ps -u $u -o pid=)" 
					done
			
				echo ""
				echo "Start to execute the remove operations..."
				echo "* Remove Cloudera Manager Data"
				#umount cm_processes
				#rm -Rf /usr/share/cmf /var/lib/cloudera* /var/cache/yum/cloudera* /var/log/cloudera* /var/run/cloudera*
				$ssh_command $host "umount cm_processes"
				$ssh_command $host "rm -Rfv /usr/share/cmf /var/lib/cloudera* /var/cache/yum/cloudera* /var/log/cloudera* /var/run/cloudera*"

				#删除快捷方式
				$ssh_command $host "cd $alterNativesDir"
				echo "Start remove $alterNativesDir"
				echo ""
				$ssh_command $host "rm -rfv $alterNativesDir/avro-*"
				$ssh_command $host "rm -rfv $alterNativesDir/beeline"
				$ssh_command $host "rm -rfv $alterNativesDir/bigtop-*"
				$ssh_command $host "rm -rfv $alterNativesDir/catalogd"
				$ssh_command $host "rm -rfv $alterNativesDir/cli_mt"
				$ssh_command $host "rm -rfv $alterNativesDir/cli_st"
				$ssh_command $host "rm -rfv $alterNativesDir/flume-*"
				$ssh_command $host "rm -rfv $alterNativesDir/hadoop*"
				$ssh_command $host "rm -rfv $alterNativesDir/hbase*"
				$ssh_command $host "rm -rfv $alterNativesDir/hcat"
				$ssh_command $host "rm -rfv $alterNativesDir/hdfs*"
				$ssh_command $host "rm -rfv $alterNativesDir/hive*"
				$ssh_command $host "rm -rfv $alterNativesDir/hue-*"
				$ssh_command $host "rm -rfv $alterNativesDir/impala*"
				$ssh_command $host "rm -rfv $alterNativesDir/kafka*"
				$ssh_command $host "rm -rfv $alterNativesDir/kite-*"
				$ssh_command $host "rm -rfv $alterNativesDir/kudu*"
				$ssh_command $host "rm -rfv $alterNativesDir/mapred"
				$ssh_command $host "rm -rfv $alterNativesDir/load_gen"
				$ssh_command $host "rm -rfv $alterNativesDir/oozie"
				$ssh_command $host "rm -rfv $alterNativesDir/parquet-tools"
				$ssh_command $host "rm -rfv $alterNativesDir/pig*"
				$ssh_command $host "rm -rfv $alterNativesDir/pyspark"
				$ssh_command $host "rm -rfv $alterNativesDir/sentry*"
				$ssh_command $host "rm -rfv $alterNativesDir/solr*"
				$ssh_command $host "rm -rfv $alterNativesDir/spark*"
				$ssh_command $host "rm -rfv $alterNativesDir/sqoop*"
				$ssh_command $host "rm -rfv $alterNativesDir/statestored"
				$ssh_command $host "rm -rfv $alterNativesDir/yarn"
				$ssh_command $host "rm -rfv $alterNativesDir/zookeeper*"

				echo ""
				echo "* Remove the Cloudera Manager Lock File (run on all agent hosts): rm /tmp/.scm_prepare_node.lock"
				#rm -rf /tmp/.scm_prepare_node.lock
				$ssh_command $host "rm -rf /tmp/.scm_prepare_node.lock"
	 
				echo ""
				echo "* Remove User Data"
				#rm -vRf /var/lib/flume-ng /var/lib/hadoop* /var/lib/hue /var/lib/navigator /var/lib/oozie /var/lib/solr /var/lib/sqoop* /var/lib/zookeeper
				#rm -vRf /dfs /mapred /yarn
				
				$ssh_command $host "rm -vRf /var/lib/flume-ng /var/lib/hadoop* /var/lib/hue /var/lib/navigator /var/lib/oozie /var/lib/solr /var/lib/sqoop* /var/lib/zookeeper"
				$ssh_command $host "rm -vRf /dfs /mapred /yarn"
				
				echo "remove /etc/cloudera-scm-*"
				$ssh_command $host "rm -vRf /etc/cloudera-scm-*"
			
				echo "remove /hadoop*"
				$ssh_command $host "rm -vRf /hadoop*"
	
				echo "remove /opt/cloudera"
				$ssh_command $host "rm -vRf /opt/cloudera"

				echo ""
				break
				;;
			no)
				echo ""
				echo "nothing to do..."
				echo ""
				break
				;;
			*)
				echo ""
				echo "Invalid input, please re-input..."
				echo ""
				;;
		esac
	done
	
	echo ""
	echo "Done, $FUNCNAME"
}

remove_cloudera_repos()
{
	echo ""
	echo "call $FUNCNAME ..."
 
 	echo ""
	echo "Start to execute the remove operations..."
	echo ""
	
 	#$ssh_command $host "rm -rfv /etc/yum.repos.d/ambari.repo"
	#$ssh_command $host "rm -rfv /etc/yum.repos.d/hdp.repo"
	$ssh_command $host "rm -rfv /etc/yum.repos.d/cloudera-manager.repo"  
	
	echo ""
	echo "Done, $FUNCNAME"
}
	
remove_cloudera_database()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	echo ""
	echo "* Remove external databases"
	echo ""
	while true
	do
		read -r -p "Are You Sure to remove all databases? [yes/no] " input
		case $input in
			yes)
				echo "removing database ..."
       		 		mysql_command_path=`which mysql`
        			#$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS < $BASEDIR/conf/database/uninstall-cloudera-mysql-db.sql && echo "done 1/1"
					$ssh_command $host "$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS < $BASEDIR/conf/database/uninstall-cloudera-mysql-db.sql && echo \"done 1/1\""
			
				echo ""
				#$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS -e"show databases"
				$ssh_command $host "$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS -e\"show databases\""

				echo ""
				break
				;;
			
			no)
				echo ""
				echo "nothing to remove on database..."
				echo ""
				break
				;;
			*)
				echo ""
				echo "Invalid input, please re-input..."
				echo ""
				echo "nothing to remove on database..."
				echo "invalid input..."
				#exit 1
				;;
		esac
	done
	echo ""
	echo "Done, $FUNCNAME"
}
	
uninstall_cloudera()
{
	main_start_time=$(date +%s)
	
	echo ""
	echo "call $FUNCNAME ..."
	echo "Now to uninstall on $host"
	echo ""

	stop_cloudera_services
	delete_cloudera_cluster
	uninstall_cloudera_software
	remove_cloudera_data	
	remove_cloudera_database
	remove_cloudera_repos

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
read -r -p 'Please type the password to confirm before uninstalling: ' pass

if [ "$pass" == "$uninstall_password" ];then
	echo ""
	echo "Start to execute the remove operations..."
	read -r -p "Please type the host name to uninstall: " input
	host=$input
 
	if ping_test $host ; then
		echo ""
		uninstall_cloudera 2>&1 | tee -a $BASEDIR/log/uninstall.log
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


