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

#hostname -f
#hostnamectl status

#if [ "$ostype" != "CentOS" ] || ( [ "$mainversion" != "6" ] && [ "$mainversion" != "7" ] ); then
if [ "$ostype" != "CentOS" ] || [ "$mainversion" != "7" ]; then
	echo "*****: The current OS is $ostype, main version: $version, this installation scriptss only support CentOS 7.x !"
fi

BASEDIR=$(pwd)

source $BASEDIR/scripts/config.sh
source $BASEDIR/scripts/init_repository.sh

# Remove installation log -----
[ -f $BASEDIR/log/install.log ] && mv $BASEDIR/log/install.log $BASEDIR/log/install.log.$(date +%Y-%m-%d_%Hh%Mm%Ss)
[ -d $BASEDIR/log ] || mkdir -p $BASEDIR/log

server_list=()

function init_server_list()
{
	echo ""
	echo "call $FUNCNAME ..."
	num=1
	for((i=0;i<max_server_number;i++));
        	do
                	#server_var_name=`eval echo "server$i"`
                	#echo $server_var_name
                	#server_list[i]=`echo $server_var_name`
                	#echo ${server_list[i}
                	
			server_name=`eval echo '$'server${num}`
                	#echo "1--: $server_name"
                	if [ -z "$server_name" ]; then
                        	#echo "--$server_name"
                        	break;
                	fi
                	#echo $server_name
                	server_list[$i]=$server_name
                	#echo ${server_list[$i]}
                	num=$(($num+1))
        	done

	for i in ${!server_list[@]}
        	do
                	echo "server: ${server_list[$i]}"
        	done

	echo ""
	echo "Done, $FUNCNAME"
}

# make sure call: init_server_list first
function init_hosts_file()
{
	echo ""
	echo "call $FUNCNAME ..."

	init_server_list

	echo ""	>>				/etc/hosts
        echo "#Server Updated $(date +%F_%T)"	>> /etc/hosts
	for i in ${!server_list[@]}
		do
			serverx=${server_list[$i]}
			arr=(${serverx// / })
			if [ ${#arr[@]} -lt "2" ];then
				echo ${arr[0]}
				echo "serverx is not valid: $serverx"
				continue
			fi
			server_name=${arr[1]}
			echo sed -i "s/^.*$server_name/#&/"	/etc/hosts
			sed -i "s/^.*$server_name/#&/"	/etc/hosts
			echo $serverx	>>		/etc/hosts

			#grep -c: is to count if string exists in file
			#if [ `grep -c '^#Server Updated' /etc/hosts` -eq '0' ]; then
        		#	echo ""					>> /etc/hosts
        		#	echo "#Server Updated $(date +%F_%T)"	>> /etc/hosts
        		#	#echo "127.0.0.1       $server_name"	>> /etc/hosts
        		#	echo ${server_list[$i]}			>> /etc/hosts
			#fi
		done
	echo ""
	echo "Done, please check /etc/hosts"
	echo ""
}

# make sure call: init_server_list first
function init_ssh_key()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	init_server_list

	ssh-keygen -t rsa
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

	for i in ${!server_list[@]}
		do
			echo "------------------------"
			serverx=${server_list[$i]}
			arr=(${serverx// / })
			if [ ${#arr[@]} -lt "2" ];then
				echo ${arr[0]}
				echo "serverx is not valid: $serverx"
				continue
			fi
			server_name=${arr[1]}

			echo "run: ssh-copy-id $server_name"
			ssh-copy-id $server_name
			#ssh-copy-id node1.hadoop
			#ssh-copy-id node2.hadoop
			#ssh-copy-id node3.hadoop

			chmod 700 ~/.ssh
			chmod 600 ~/.ssh/authorized_keys
			
			echo ""
			echo "run: ssh $server_name"
			ssh $server_name date ;
		done	
		#ssh node1.hadoop date ;ssh node2.hadoop date;ssh node3.hadoop date;
		echo ""
		echo "Done, please run: ssh node1.hadoop, replace node1.hadoop to check one by one, including all servers."
		echo ""
}

function init_hostname()
{
	echo ""
	echo "call $FUNCNAME ..."
	local my_host_name=$1
	
	if [ -z "$my_host_name" ]; then
        	echo "Please provide hostname, such as: init_hostname node1.hadoop"
		echo ""
                exit 1;
	fi

	hostnamectl set-hostname "$my_host_name"

	echo ""
	hostname -f
	echo ""
	hostnamectl status
	echo ""
	echo "Done, hostname sets to $my_host_name"
}

function init_firewall()
{	
	echo ""
	echo "call $FUNCNAME ..."
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	firewall-cmd --state

	echo ""
	echo "Done, $FUNCNAME"
}


function init_selinux()
{
	echo ""
	echo "call $FUNCNAME ..."
	# set selinux to disabled
	echo "Checking selinux status ..."
	sestatus -v
	echo " "
	echo "Changing selinux status to disabled ..."
	echo " "
	sed -i "s#SELINUX=.*#SELINUX=disabled#g" /etc/selinux/config
	
	echo "Please reboot the server..."

	echo ""
	echo "Done, $FUNCNAME"

}

function init_network()
{
	
	echo ""
	echo "call $FUNCNAME ..."
	# DNS server for guangdong server, change to JP dns server when server is to deploy in JP
	grep 119.29.29.29 /etc/resolv.conf||echo 'nameserver 119.29.29.29' >> /etc/resolv.conf
	grep 202.96.134.133 /etc/resolv.conf||echo 'nameserver 202.96.134.133' >> /etc/resolv.conf
	grep 8.8.8.8 /etc/resolv.conf||echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

	echo ""
	echo "Done, $FUNCNAME"
}

function init_chrony_time_server()
{
	echo ""
	echo "call $FUNCNAME ..."
	systemctl stop ntpd.service
	systemctl disable ntpd.service
	
	yum install chrony -y

	[ -f /etc/chrony.conf ] && cp -v /etc/chrony.conf /etc/chrony.conf.$(date +%Y-%m-%d_%Hh%Mm%Ss)	
	sed -i "s#server.*0.centos.*#server ntp1.aliyun.com iburst#g" /etc/chrony.conf
	sed -i "s#server.*1.centos.*#server ntp2.aliyun.com iburst#g" /etc/chrony.conf
	sed -i "s#server.*2.centos.*#server ntp3.aliyun.com iburst#g" /etc/chrony.conf
	sed -i "s#server.*3.centos.*#server ntp4.aliyun.com iburst#g" /etc/chrony.conf
	
	#sed -i "s#server.*0.centos.*#server 0.pool.ntp.org iburst#g" /etc/chrony.conf
	#sed -i "s#server.*1.centos.*#server 1.pool.ntp.org iburst#g" /etc/chrony.conf
	#sed -i "s#server.*2.centos.*#server 2.pool.ntp.org iburst#g" /etc/chrony.conf
	
	echo ""
	#comment out all existing allow setting
	sed -i "s/^allow/#&/"  /etc/chrony.conf
	echo "" >> /etc/chrony.conf
	echo "#Allow Server Updated $(date +%F_%T)"   >> /etc/chrony.conf
	for element in `ip a |grep -v inet6 | grep -v 127.0.0.1 | grep inet | awk '{print $2}'`
		do
			echo "$element"
			#192.168.56.102/24
			ip_address=${element%/*}
			ip_prefix=${ip_address%.*}
			ip_mask=${element##*/}
	
			allow_ip_str="$ip_prefix".0/"$ip_mask"
			echo "ip_address: $ip_address, ip_prefix: $ip_prefix, ip_mask: $ip_mask"
			echo "allow_ip_str: $allow_ip_str"

			echo "allow $allow_ip_str" >> /etc/chrony.conf

			#echo sed -i "s#allow.*\/#allow $allow_ip_str#g" /etc/chrony.conf
			#sed -i "s#allow.*\/#allow $allow_ip_str#g" /etc/chrony.conf
		done

	systemctl enable chronyd.service
	systemctl start chronyd.service

	echo "Please double check the allow ip in /etc/chrony.conf"

	echo ""
	echo "Done, $FUNCNAME"
}

# make sure call: init_server_list first
# time_client connects to time_server
function init_chrony_time_client()
{
	echo ""
	echo "call $FUNCNAME ..."
        
	init_server_list
        master_server=${arr[1]}
        time_server=$master_server
	
	systemctl stop ntpd.service
	systemctl disable ntpd.service
	
	yum install chrony -y
	
	[ -f /etc/chrony.conf ] && cp -v /etc/chrony.conf /etc/chrony.conf.$(date +%Y-%m-%d_%Hh%Mm%Ss)	
	sed -i "s/^server/#&/"  /etc/chrony.conf
	sed -i "s#server.*0.centos.*#server $time_server iburst#g" /etc/chrony.conf
	sed -i "s#server.*1.centos.*#server ntp0.aliyun.com iburst#g" /etc/chrony.conf
	sed -i "s#server.*2.centos.*#server ntp1.aliyun.com iburst#g" /etc/chrony.conf

	systemctl enable chronyd.service
	systemctl start chronyd.service

	/usr/sbin/ntpdate -u $time_server
	echo ""

	hwclock --systohc
	echo ""

	chronyc ntpdata
	echo ""
	chronyc -a makestep

	echo ""
	echo "Done, $FUNCNAME"
}	

# make sure call: init_server_list first
function init_ntpdate_time_client()
{

	echo ""
	echo "call $FUNCNAME ..."
	
	local time_server=$1

	init_server_list

	if [ -z "$time_server" ]; then
        	echo "Time server is not specify, then use server1 in config.sh as default master server and time server."
		time_server=${server_list[0]}
		echo "Time server: $time_server"
        	#echo "Please provide timeserver name, such as: init_time_client node1.hadoop"
		echo ""
                #exit 1;
	fi
# Config system cron job, by bright on 2011-06-12
grep '# sys crontab' /var/spool/cron/root||cat >> /var/spool/cron/root <<CRONTAB

# sys crontab $(date +%F)
#55 23 * * * /usr/sbin/ntpdate pool.ntp.org
55 23 * * * /usr/sbin/ntpdate $time_server
CRONTAB

	# Please check if you open udp 123 port, if you recieve "no server suitable for synchronization found"
	/usr/sbin/ntpdate -u pool.ntp.org
	hwclock --systohc

	echo ""
	echo "Done, $FUNCNAME"

}

function init_yum_repos()
{
	echo ""
	echo "call $FUNCNAME ..."
	echo ""
	[ -f /etc/yum.repos.d/cloudera-manager.repo ] && mv /etc/yum.repos.d/cloudera-manager.repo /etc/yum.repos.d/cloudera-manager.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)	
	cp -vf $BASEDIR/conf/cloudera-manager.repo	/etc/yum.repos.d/cloudera-manager.repo
	
	[ -f /etc/yum.repos.d/ambari.repo ] && mv /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/ambari.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	cp -vf $BASEDIR/conf/ambari.repo	/etc/yum.repos.d/ambari.repo

	[ -f /etc/yum.repos.d/hdp.repo ] && mv /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/hdp.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)	
	cp -vf $BASEDIR/conf/hdp.repo	/etc/yum.repos.d/hdp.repo

	yum clean all
	yum makecache
	yum repolist

	echo ""
	echo "Done, $FUNCNAME"
}

#Refer to: https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_install_gpl_extras.html
function init_gpl_extras()
{
	echo ""
	echo "call $FUNCNAME ..."
	yum -y install lzo
	
	echo ""
	echo "Done, $FUNCNAME"
}

function init_java()
{
	echo ""
	echo "call $FUNCNAME ..."
	source $BASEDIR/scripts/jdk_install.sh 
	jdk_install

	echo ""
	echo "Done, $FUNCNAME"
}

function init_cloudera_manager_server()
{
	echo ""
	echo "call $FUNCNAME ..."
	yum -y install cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server 
	
	systemctl enable cloudera-scm-server
	systemctl enable cloudera-scm-agent
	
	echo ""
	echo "Done, $FUNCNAME"
}

function init_mysql_server()
{
	echo ""
	echo "call $FUNCNAME ..."
	rpm -ivh https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm
	#yum update
	yum -y install mysql-server
	
	#[ -f /etc/my.cnf ] && mv -v /etc/my.cnf /etc/my.cnf.$(date +%Y-%m-%d_%Hh%Mm%Ss)	
	#cp -vf $BASEDIR/conf/my.cnf	/etc/my.cnf

	mkdir -p $DATADIR/mysql
	mkdir -p $LOGDIR/mysql

	chown -R mysql.mysql $DATADIR/mysql
	chown -R mysql.mysql $LOGDIR/mysql
	
	systemctl enable mysqld
	systemctl start mysqld

	echo "Please to check log file /var/log/mysqld.log to check the defualt password"
	echo ""
	echo "Now to init mysql database server ..."
	/usr/bin/mysql_secure_installation
	
	echo ""
	echo "Done, $FUNCNAME"
}

function init_mysql_client()
{
	echo ""
	echo "call $FUNCNAME ..."
	rpm -ivh https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm
	
	#yum search mysql-community-client	
	yum -y install mysql-community-client

	ls -l /usr/share/java/mysql-connector-java.jar

	echo ""
	echo "Done, $FUNCNAME"
}

function init_cloudera_mysql_database()
{
	echo ""
	echo "call $FUNCNAME ..."
	mysql_command_path=`which mysql` 

	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS < $BASEDIR/conf/database/cloudera-mysql-db.sql && echo "done 1/1"
	#$mysql_command_path -u$MYSQL_DB_USER -p$MYSQL_DB_PASS $MYSQL_DB_NAME < $PKGSRC/$ZABBIX_PKG/database/mysql/schema.sql && echo "done 1/3"

	# To create the /etc/cloudera-scm-server/db.properties, scm database is still no tables. 
	# All tables in scm database will be created when cloudera-scm-server startups in the first time.
	echo "/opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h $MYSQL_DB_SERVER --scm-host $SCM_SERVER_NAME $SCM_DB_NAME $SCM_DB_USER $SCM_DB_PASS"
	/opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h $MYSQL_DB_SERVER --scm-host $SCM_SERVER_NAME $SCM_DB_NAME $SCM_DB_USER $SCM_DB_PASS

	echo ""
	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS -e"show databases"

	echo ""
	$mysql_command_path -h$MYSQL_DB_SERVER -u$MYSQL_DB_USER -p$MYSQL_DB_PASS -e"use ambari; show tables"

	ls -l /usr/share/java/mysql-connector-java.jar
	
	echo ""
	echo "Done, $FUNCNAME"
	
}

function start_cloudera_manager()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	systemctl start cloudera-scm-server
	# All tables in scm database will be created when cloudera-scm-server startups in the first time.

	echo " When you see this log entry, the Cloudera Manager Admin Console is ready "
	echo " INFO WebServerImpl:com.cloudera.server.cmf.WebServerImpl: Started Jetty server. "
	#tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
	
	echo " tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log "

	echo " "	
	echo "Please type: http://<server_host>:7180 to browser cloudera ..."
}

init_slaver()
{
	slaver_start_time=$(date +%s)

	echo ""
	echo "call $FUNCNAME ..."
	local my_host_name=$1
	
	if [ -z "$my_host_name" ]; then
        	echo "Please provide hostname, such as: init_slaver node1.hadoop"
		echo ""
                exit 1;
	fi
	
	init_hostname	$my_host_name

	init_yum_repos
	init_hosts_file
	init_network
	init_firewall
	init_selinux
	init_chrony_time_client
	#init_ntpdate_time_client
	init_java

	slaver_end_time=$(date +%s)
	slaver_cost_time=$[ $slaver_end_time-$slaver_start_time ]

	echo "== slaver time spend: $slaver_cost_time(s), $(($slaver_cost_time/60))min $(($slaver_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""
}

#master server is to install cloudera-manager-server
init_master()
{
	echo ""
	echo "call $FUNCNAME ..."
	local my_host_name=$1

	if [ -z "$my_host_name" ]; then
        	echo "Please provider hostname, such as: init_master node1.hadoop"
		echo ""
                exit 1;
	fi
	
	init_slaver $my_host_name

	init_ssh_key
	init_chrony_time_server
	
	echo ""
	echo "Done, $FUNCNAME"
}

#master to install cloudera-manager-server
cloudera_install()
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
	
	init_master $my_host_name

	init_local_parcel_repository

	init_cloudera_manager_server
	init_cloudera_mysql_database

	start_cloudera_manager
	
	master_end_time=$(date +%s)
	master_cost_time=$[ $master_end_time-$master_start_time ]

	echo "== master time spend: $master_cost_time(s), $(($master_cost_time/60))min $(($master_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""
}


