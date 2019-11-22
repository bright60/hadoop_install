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

# Refer to: https://docs.cloudera.com/HDPDocuments/Ambari/Ambari-2.7.4.0/index.html

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

source $BASEDIR/scripts/config.sh
source $BASEDIR/scripts/init_repository.sh
source $BASEDIR/scripts/init_environment.sh

# Remove installation log -----
[ -f $BASEDIR/log/install.log ] && mv $BASEDIR/log/install.log $BASEDIR/log/install.log.$(date +%Y-%m-%d_%Hh%Mm%Ss)
[ -d $BASEDIR/log ] || mkdir -p $BASEDIR/log

#server_type: master | slaver
# the first server in server_list is master server by default, which will be installed cloudera server
#server_list=()

function init_ambari_agent()
{
	echo ""
	echo "call $FUNCNAME ..."
	echo ""
	yum -y install ambari-agent

	# if mysql-connector-java.jar doesn't exist, please install: init_mysql_client 
	#yum -y install mysql-community-client

	echo ""
	echo "Done,$FUNCNAME"
}

function init_ambari_server()
{
	echo ""
	echo "call $FUNCNAME ..."
	echo ""
	yum -y install ambari-server

	# if mysql-connector-java.jar doesn't exist, please install: init_mysql_client 
	#yum -y install mysql-community-client

	ls -l /usr/share/java/mysql-connector-java.jar
	ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar

	echo ""
	echo "Done,$FUNCNAME"
}	

function init_ambari_mysql_database()
{
	echo ""
	echo "call $FUNCNAME ..."
	echo ""
        mysql_command_path=`which mysql`

	# init database and user
	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS < $BASEDIR/conf/database/ambari-mysql-db.sql && echo "done 1/1"
       
	echo ""
	# init ambari tables to ambari database 
	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS ambari < /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql && echo "done 1/1"
	
	echo ""
	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS -e"show databases"
	
	echo ""
	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS -e"use ambari; show tables"

	ls -l /usr/share/java/mysql-connector-java.jar

	echo ""
	echo "Done,$FUNCNAME"
}

{
	echo ""
	echo "call $FUNCNAME ..."

	
	echo ""
	echo "Done,$FUNCNAME"
}

function ambari_install()
{
	master_start_time=$(date +%s)

	echo ""
	echo "call $FUNCNAME ..."
	local my_host_name=$1

	if [ -z "$my_host_name" ]; then
		echo "Please provider hostname, such as: init_master node1.hadoop"
		echo ""
		exit 1;
	fi

	init_yum_ambari_repos

	init_master $my_host_name

	init_ambari_server
	init_ambari_agent
	init_ambari_mysql_database
	
	echo ""
	echo "JDK: choose [2] Custom JDK, and then input the path of JAVA_HOME"
	echo "Database: Enter advanced database, choose yes"
	echo "Choose 3 - MySQL / MariaDB"
	echo "other options will just type enter, using default choice..."

	echo ""
	echo "****** IMPORTANT ******"
	echo ""
	echo "JAVA_HOME: $JAVA_HOME"
	echo ""
	echo "Please run: ambari-server setup "

	echo ""
	echo "Please run: ambari-server start "
	echo ""

	echo "Please run: ambari-server status "

	echo ""
	echo "tail -f /var/log/ambari-server/ambari-server.log"

	echo " "
	echo "Please type: http://<server_host>:8080 to browser Ambari ..."
	echo " "

	master_end_time=$(date +%s)
	master_cost_time=$[ $master_end_time-$master_start_time ]

	echo "== master time spend: $master_cost_time(s), $(($master_cost_time/60))min $(($master_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""

}
	

echo " "
echo "*** To run the script with "-x" in debug mode: $0 -x"
echo "************************************************************************************************************************** "
echo "*** servername as param which is the value of serverX variable from config.sh"
echo "*** such as: server1=node1.hadoop, then use node1.haddop as servername"
echo "*** server1 is the master server by default, server1=node1.hadoop, then node1.haddop is master server"
echo "*** To init master server: init_master node1.hadoop"
echo "*** To init slaver server: init_slaver node2.hadoop or init_slaver node3.hadoop, and so on"
echo "*** To install ambari server: ambari_install node1.hadoop"
echo "*** To set hostname: set_hostname node1.hadoop, or set_hostname node2_hadoop , and so on"
echo "************************************************************************************************************************** "
echo ""
echo "============================================================"
echo "1 Install master server( cloudera server and agent ), type: init_master servername"
echo "2 Install slaver, type: 		init_slaver servername"
echo "3 Install mysql server, type: 	mysqlserver"
echo "4 Install mysql client, type: 	mysqlclient"
echo "5 Install jdk, type: 		jdk"
echo "6 Set hostname, type: 		set_hostname servername"
echo "7 Set /etc/hosts file, type: 	set_hosts_file"
echo "8 Set ssh key ( from master server ), type: set_ssh_key"
echo "10 exit, say goodbye ..."
echo "============================================================"
echo " "
read -p $'Please type { init_master | init_slaver | ambari_install | mysqlserver | mysqlclient | jdk | init_hostname | set_hosts_file | set_ssh_key | init_local_parcel_repository | exit }:\x0a' cmd

init_server_list

serverx=${server_list[$i]}
param_arr=(${cmd// / })

cmd=${param_arr[0]}

if [ ${#param_arr[@]} -gt "1" ];then
	param=${param_arr[1]}
fi

echo ""
echo "cmd: $cmd"
echo "param: $param"

# See how we were called.
case "$cmd" in
	init_master)
		init_master $param 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	init_slaver)
		init_slaver $param 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	ambari_install)
		ambari_install $param 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	init_hostname)
		init_hostname $param 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	set_hosts_file)
		init_hosts_file 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	set_ssh_key)
		init_ssh_key 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	mysqlserver)
		init_mysql_server 2>&1 | tee -a $BASEDIR/log/install.log
		
		;;
	mysqlclient)
		init_mysql_client 2>&1 | tee -a $BASEDIR/log/install.log
		
		;;
	jdk)
		init_java 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	init_local_parcel_repository)
		init_local_parcel_repository 2>&1 | tee -a $BASEDIR/log/install.log
		;;
	*)
		echo " "
		echo $"Usage: Please type what you want to install as shown above ..."
		echo " "
		RETVAL=2
esac

exit $RETVAL

#cloudera_install 2>&1 | tee -a $BASEDIR/log/install.log
#scp hadoop_install.20191106-v0.2.tar.gz node3.hadoop:~/

