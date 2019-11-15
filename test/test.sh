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

server1=node1.hadoop
server2=node2.hadoop
server3=node3.hadoop

server_list=()

max_server_number=10
num=1
for((i=0;i<max_server_number;i++));
	do
		#server_var_name=`eval echo "server$i"`
		#echo $server_var_name
		#server_list[i]=`echo $server_var_name`
		#echo ${server_list[i}
		server_name=`eval echo '$'server${num}`
		echo "1--: $server_name"
		if [ -z "$server_name" ]; then
			#echo "--$server_name"
			break;
		fi
		echo $server_name
		server_list[$i]=$server_name
		echo ${server_list[$i]}
		num=$(($num+1))
	done

for i in ${!server_list[@]}
	do
		echo ${server_list[$i]}
	done

	server_name=${server_list[0]}

#grep '^#Server Updated' /etc/hosts || cat >> /etc/hosts <<HOSTS
##Server Updated
#127.0.0.1       $server_name

#HOSTS


if [ `grep -c '^#Server Updated' /etc/hosts` -eq '0' ]; then
	echo ""					>> /etc/hosts
	echo "#Server Updated $(date +%F_%T)"	>> /etc/hosts
	echo "127.0.0.1       $server_name"	>> /etc/hosts
fi
