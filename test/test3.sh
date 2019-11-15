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

source ../scripts/config.sh
#source $BASEDIR/scripts/config.sh
#source $BASEDIR/scripts/init_repository.sh

server_list=()
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

function init_chrony_time_server()
{
	echo ""
	echo "call $FUNCNAME ..."
	systemctl stop ntpd.service
	systemctl disable ntpd.service
	
	yum install chrony -y

	[ -f /etc/chrony.conf ] && cp -v /etc/chrony.conf /etc/chrony.conf.$(date +%Y-%m-%d_%Hh%Mm%Ss)	
	#sed -i "s/^server/#&/"  /etc/chrony.conf
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

	local time_server=$1
	init_server_list
	
	if [ -z "$time_server" ]; then
        	echo "Time server is not specify, then use server1 in config.sh as default master server and time server."
		# time_server is master_server, master_server is the first server in server_list
		time_server=${server_list[0]}
		echo "Time server: $time_server"
		echo ""
                #exit 1;
	fi
        
	systemctl stop ntpd.service
	systemctl disable ntpd.service
	
	yum install chrony -y
	
	[ -f /etc/chrony.conf ] && cp -v /etc/chrony.conf /etc/chrony.conf.$(date +%Y-%m-%d_%Hh%Mm%Ss)	
	sed -i "s/^server.*iburst.*/#&/"  /etc/chrony.conf
	echo "" >> /etc/chrony.conf
	echo "#Time Server Updated $(date +%F_%T)"	>>	/etc/chrony.conf
	echo "server $time_server iburst"		>>	/etc/chrony.conf
	echo "server ntp0.aliyun.com iburst"		>>	/etc/chrony.conf
	echo "server ntp1.aliyun.com iburst"		>>	/etc/chrony.conf

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
		# time_server is master_server, master_server is the first server in server_list
		time_server=${server_list[0]}
		echo "Time server: $time_server"
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

#init_chrony_time_server
init_chrony_time_client
#init_ntpdate_time_server

