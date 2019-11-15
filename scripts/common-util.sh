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

# Example: addAppUser 20021 mysql mysql
function addAppUser() {
echo "addAppUser ... "
local user_group_id=$1
local user=$2
local group=$3
echo $folder
echo $srcfile
cd $folder

#user=nginx
#group=nginx
 
###################
#create group if not exists
egrep "^$group" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
    echo "Now to add new group:"$group
	groupadd -g $user_group_id $group
fi

#create user if not exists
egrep "^$user" /etc/passwd >& /dev/null
if [ $? -ne 0 ]
then
    echo "Now to add new user:"$user
	useradd -u $user_group_id -s /sbin/nologin -M -g $group $user
fi
#======================

}

checkInt(){
	expr $1+ 0&>/dev/null
	[ $? -ne 0] && { echo "Args must be integer!";exit 1; }
}

command_exists () {
    type "$1" &> /dev/null ;
}
#command_exists lsaaa
#command_exists_path=$?
#echo $command_exists_path
#if command_exists ls ; then
#     echo "command exists"
#fi

# check if dir is empty or not, return the number of files of dirs in current dir
function is_empty_dir(){ 
    if [ -d "$1" ]; then 	
    	return `ls -A $1|wc -w`
    else
	# the dir doesn't exist, then it's empty
	return 0
    fi
}

#if is_empty_dir $1
#then
#   echo " $1 is empty"
#else
#   echo " $1 is not empty"
#fi

# usage: check_rpm_install memcached
# return value: 1 un-install, 0 keep the rpm package, not un-install
function check_rpm_install() {

local rpm_package=$1
local ret_val=1

echo " " 
echo "====== Start to check if $rpm_package rpm has been installed on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"

#Check if $rpm_package rpm package was installed, by BX, on 2017-05-21
result=`rpm -qav | grep $rpm_package`
if [ "$result" = "" ]
then
	echo "$rpm_package rpm package is not installed"
else
	echo "$rpm_package rpm is installed": $result
	echo " "
	echo "Please un-install $rpm_package to continue the new installation ..."
	echo " "
	while :
	do

		read -p $'Do you sure? [y/N]:\x0a' cmdinput
		case $cmdinput in
			[yY][eE][sS]|[yY])
				echo "Now to un-install $rpm_package ..."
				rpm -qav | grep $rpm_package | xargs rpm -e --nodeps
				echo "Un-install $rpm_package completed."
				ret_val=1
				break
				;;

			[nN][oO]|[nN])
				echo "Keep the current $rpm_package, exit the installation..."
				ret_val=0
	       			break
				;;

	    		*)
				echo "Invalid input, please re-input..."
				continue
				;;
			esac
	done
	
	echo " " 
fi
echo "====== End to check if $rpm_package rpm has been installed on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
echo " " 
return $ret_val

}
#check_rpm_install memcached

# usage: rpm_uninstall memcached
function rpm_uninstall() {

local rpm_package=$1

echo " " 
echo "====== Start to uninstall $rpm_package rpm on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"

#Check if $rpm_package rpm package was installed, by BX, on 2017-05-21
result=`rpm -qav | grep $rpm_package`
if [ "$result" = "" ]
then
	echo "$rpm_package rpm package is not installed"
else
	echo "$rpm_package rpm is installed": $result
	echo " "
	echo "Un-install $rpm_package to continue the new installation ..."
	echo " "
	echo "Now to un-install $rpm_package ..."
	
	rpm -qav | grep $rpm_package | xargs rpm -e --nodeps
	
	echo "Un-install $rpm_package completed."
fi
echo "====== End to uninstall $rpm_package rpm on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
echo " " 

}

ping_test () 
{	
	#检测主机的连通性
	#unPing=$(ping $host -c $pingCount | grep 'Unreachable' | wc -l)
	#unPing=$(ping $host | grep -E "Unreachable|not known")
	#unPing=$(ping $host)
	#ping -c 1 $host > /dev/null 2>&1 
	#echo "-----: $unPing"

    #type "$1" &> /dev/null ;
	ping -c 1 "$1" >/dev/null	

	#-n 如果 string 长度非零，则为真
	#if [ -n "$unPing" ]; then
	#if [ $? -ne 0 ]; then
	#if ping -c 1 $host >/dev/null 2>&1; then
	#if ping -c 1 $host >/dev/null; then
	##	echo ""
	#else
	#	echo -e "$logPre======>$host is Unreachable,please check '/etc/hosts' file"
	#	echo "Nothing to do..."
	#	exit 1
	#fi	
}
#ping_test node2.hadoop
#ping_result=$?
#echo $ping_result
#if ping_test $host ; then
#     echo "ping to $host works"
#fi


#rpm_uninstall memcached
