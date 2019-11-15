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
# 
# Updated by bright on 2010-09-16 
#
# v2.0.0
#  ~ Refactor the script, and support hadoop

# v1.2.4
# ~ add 'vm.overcommit_memory = 1' and vm.swappiness = 1 to /etc/sysctl.conf for redis 
# 如果 CentOS6.x( 内核：< 3.5 ) swapiness 需要设置为 0。这样系统宁愿 swap 也不会 oom killer
# 如果 CentOS7.x( 内核：>= 3.5 ) swapiness 需要设置为 1。这样系统宁愿 swap 也不会 oom killer

# v1.2.3
# ~ fixed the execution issue of /etc/rc.d/rc.local 

# v1.2
# ~ add the disable transparent_hugepage config 
# ~ add the ulimit config for CentOS7
#
# v1.1
# ~ add the display setting function
# ~ add the comment function if the setting exist

# v1.0
# ~ init the script 

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#########################################################################
# DON'T CHANGE THE FOLLOWING SETTINGS IF YOU DON'T HAVE A BETTER SETTINGS
#########################################################################

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

if [ "$ostype" != "CentOS" ] &&  [ "$mainversion" != "7" ]; then
        echo "*****: The current OS is $ostype, main version: $version, this installation scriptss only support 7.x !"
	exit 1
fi

BASEDIR=$(pwd)
[ -d $BASEDIR/log ] || mkdir -p $BASEDIR/log

check_socket_config() {
	
	echo " "
	echo "call $FUNCNAME ..."
	echo "====== Display system config from sysctl on $(date +%Y-%m-%d_%Hh%Mm%Ss) ... ======"
	echo ""
	sysctl -a |grep -E "file-max|nr_open"
	echo ""
	sysctl -a |grep -E "ip_local_port_range|somaxconn|rmem_default|wmem_default|rmem_max|wmem_max|tcp_rmem|tcp_wmem|tcp_mem"
	echo ""
	
	sysctl -a |grep -E "tcp_max_syn_backlog|netdev_max_backlog|tcp_fin_timeout|tcp_tw_reuse|tcp_tw_recycle|tcp_max_orphans"
	echo ""
	echo "Done, $FUNCNAME"
}

check_mem_config() {
	sysctl -a |grep -E "vm.overcommit_memory|vm.swappiness"
	echo ""

	echo "cat /proc/sys/vm/overcommit_memory"
	cat /proc/sys/vm/overcommit_memory
	echo " "

	echo "cat /proc/sys/vm/swappiness"
	cat /proc/sys/vm/swappiness
	
	echo " "
	echo "/etc/security/limits.conf"
	tail -n 6 /etc/security/limits.conf
	
	echo ""
	echo "Done, $FUNCNAME"
}

change_socket_config() {

	echo " "
	echo "call $FUNCNAME ..."
	echo "====== Start to $FUNCNAME on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"

	# The default value of system is calculated based on memory, around 10% of memory
	echo "10% of memory: " `grep MemTotal /proc/meminfo | awk '{printf("%d",$2/10)}'`


	more /proc/sys/fs/file-max
	echo 2000000 > /proc/sys/fs/file-max

	# the default value of nr_open is 1048576
	more /proc/sys/fs/nr_open 
	echo 2000000 > /proc/sys/fs/nr_open


	# sysctl.conf 
	# Commented out the setting if exists
	sed -i "s/^fs./#&/"		/etc/sysctl.conf
	sed -i "s/^net.ipv4/#&/"	/etc/sysctl.conf
	sed -i "s/^net.core/#&/"	/etc/sysctl.conf
	sed -i "s/^vm.overcommit_memory/#&/"	/etc/sysctl.conf

# Add the new setting at the end of file
#grep '^#socket sysctl Updated' /etc/sysctl.conf>/dev/null 2>&1 ||cat >> /etc/sysctl.conf <<SYSCTLCONFIG
cat >> /etc/sysctl.conf <<SYSCTLCONFIG
#socket sysctl Updated $(date +%F_%T)
fs.file-max=2000000
fs.nr_open=2000000

net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 4096
net.core.rmem_default = 262144  
net.core.wmem_default = 262144
net.core.rmem_max = 16777216  
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 4096 16777216  
net.ipv4.tcp_wmem = 4096 4096 16777216
# tcp_mem measured in units of pages (4096 bytes)
net.ipv4.tcp_mem = 786432 2097152 3145728
net.ipv4.tcp_max_syn_backlog = 16348
net.core.netdev_max_backlog = 20000
net.ipv4.tcp_fin_timeout = 15
 
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_orphans = 131072

SYSCTLCONFIG

	sysctl -p

	echo " "
	echo "Done, $FUNCNAME"
}

change_mem_config() {

	echo " "
	echo "call $FUNCNAME ..."
	echo "====== Start to $FUNCNAME on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"


	# sysctl.conf 
	# Commented out the setting if exists
	sed -i "s/^vm.overcommit_memory/#&/"	/etc/sysctl.conf
	sed -i "s/^vm.swappiness/#&/"		/etc/sysctl.conf

# Add the new setting at the end of file
#grep '^#mem sysctl Updated' /etc/sysctl.conf>/dev/null 2>&1 ||cat >> /etc/sysctl.conf <<SYSCTLCONFIG
cat >> /etc/sysctl.conf <<SYSCTLCONFIG

#mem sysctl Updated $(date +%F_%T)
vm.overcommit_memory = 1
# swappiness value from 0 to 100, 0 is disable swapp.
# 1 is to prevent the system from swapping too frequently, but still allow for emergency swapping
vm.swappiness = 1

SYSCTLCONFIG

	sysctl -p

	echo " "
	echo "Done, $FUNCNAME"
}


change_ulimit_config() {

	echo " "
	echo "call $FUNCNAME ..."
	echo "====== Start to $FUNCNAME on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"

	
	echo "Change /etc/security/limits.conf file ..."
	# Limits Config
	# Commented out the setting if exists
	sed -i 's/^*.*soft.*noproc/#&/'	/etc/security/limits.conf
	sed -i 's/^*.*hard.*noproc/#&/'	/etc/security/limits.conf
	sed -i 's/^*.*soft.*nofile/#&/'	/etc/security/limits.conf
	sed -i 's/^*.*hard.*nofile/#&/'	/etc/security/limits.conf

	# Add the new setting at the end of file
	#sed -i '$a\\n'					/etc/security/limits.conf
	sed -i '$G'					/etc/security/limits.conf
	sed -i '$a#Limits Updated  '`date +%F_%T`	/etc/security/limits.conf
	sed -i '$a*   soft    noproc  1048576'		/etc/security/limits.conf
	sed -i '$a*   hard    noproc  1048576'		/etc/security/limits.conf
	sed -i '$a*   soft    nofile  1048576'		/etc/security/limits.conf
	sed -i '$a*   hard    nofile  1048576'		/etc/security/limits.conf

	#ulimit -HSn 63536
	#ulimit -HSn 1048576


	if [ "$mainversion" == "7" ]; then
		echo "Change /etc/systemd/system.conf file in CentOS7.x ..."

		[ -f /etc/systemd/system.conf ] && cp /etc/systemd/system.conf /etc/systemd/system.conf.$(date +%Y-%m-%d_%Hh%Mm%Ss)
		#sed -i 's/^#\(DefaultLimitCORE=infinity\)/\1/'	 /etc/systemd/system.conf
		#sed -i "s/^#DefaultLimitCORE=.*/DefaultLimitCORE=infinity/"	/etc/systemd/system.conf 
		#sed -i "s/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1024000/"	/etc/systemd/system.conf 
		#sed -i "s/^#DefaultLimitNPROC=.*/DefaultLimitNPROC=1024000/"	/etc/systemd/system.conf 

		grep "^DefaultLimitCORE="	/etc/systemd/system.conf
		if [ $? -eq 0 ]; then
			sed -i 's/^DefaultLimitCORE/#&/'	/etc/systemd/system.conf
		fi

		#sed -i '$G'				/etc/systemd/system.conf
		sed -i '$aDefaultLimitCORE=infinity'	/etc/systemd/system.conf	


		grep "^DefaultLimitNOFILE="	/etc/systemd/system.conf
		if [ $? -eq 0 ]; then
			sed -i 's/^DefaultLimitNOFILE/#&/'	/etc/systemd/system.conf
		fi	
		sed -i '$aDefaultLimitNOFILE=1024000'	/etc/systemd/system.conf	

		grep "^DefaultLimitNPROC="	/etc/systemd/system.conf
		if [ $? -eq 0 ]; then
			sed -i 's/^DefaultLimitNPROC/#&/'	/etc/systemd/system.conf
		fi	
		sed -i '$aDefaultLimitNPROC=1024000'	/etc/systemd/system.conf	

		echo "Change /etc/security/limits.d/20-nproc.conf file in CentOS7.x ..."
		# Commented out the setting if exists
		sed -i 's/^*.*soft.*nproc/#&/'	/etc/security/limits.d/20-nproc.conf
		sed -i 's/^root.*soft.*nproc/#&/'	/etc/security/limits.d/20-nproc.conf

		# Add the new setting at the end of file
		#sed -i '$a\\n'					/etc/security/limits.d/20-nproc.conf
		sed -i '$G'					/etc/security/limits.d/20-nproc.conf
		sed -i '$a#Limits 20-nproc Updated  '`date +%F_%T`	/etc/security/limits.d/20-nproc.conf
		sed -i '$a*	soft    nproc	1024000'			/etc/security/limits.d/20-nproc.conf
		sed -i '$aroot	soft    nproc	unlimited'		/etc/security/limits.d/20-nproc.conf
	fi

	echo " "
	echo "Done, $FUNCNAME"

}

#Refer to: https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cdh_admin_performance.html#cdh_performance
#Most Linux platforms supported by CDH include a feature called transparent hugepages, which interacts poorly with Hadoop workloads and can seriously degrade performance
#Symptom: top and other system monitoring tools show a large percentage of the CPU usage classified as "system CPU". 
#If system CPU usage is 30% or more of the total CPU usage, your system may be experiencing this issue.
disable_transparent_hugepage() {

	echo " "
	echo "call $FUNCNAME ..."
	echo "====== Start to $FUNCNAME on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"

	# Config rc.local, by bright on 2008-03-09
	if [ `grep -c '#rc.local update' /etc/rc.local` -eq '0' ]; then
		echo "" >> /etc/rc.local
		echo "#rc.local update $(date +%F)" >> /etc/rc.local
		if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
			echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
		fi

		if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
			echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
		fi
	fi
		
#grep '#rc.local update' /etc/rc.local || cat >> /etc/rc.local <<RCLOCALUPDATE

#rc.local update $(date +%F)
#if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
#       	echo never > /sys/kernel/mm/transparent_hugepage/enabled
#fi

#if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
#        	echo never > /sys/kernel/mm/transparent_hugepage/defrag
#fi

#RCLOCALUPDATE

	chmod +x /etc/rc.d/rc.local

	grep "transparent_hugepage=never"	/etc/default/grub
	if [ $? -eq 0 ]; then
		echo " "
		echo "transparent_hugepage=never has been configed in /etc/default/grub"
		echo "now we will do nothing ... "
		echo " "
		echo "Done, $FUNCNAME"
 		return
	fi
	
	# Only support for Centos 7.X
	[ -f /etc/default/grub ] && cp /etc/default/grub /etc/default/grub.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	# add  transparent_hugepage=never to 
	sed -i '/GRUB_CMDLINE_LINUX.*/s/$/transparent_hugepage=never"/'		/etc/default/grub
	sed -i 's/"transparent_hugepage.*/ transparent_hugepage=never"/'	/etc/default/grub

	grub2-mkconfig -o /boot/grub2/grub.cfg

	cat /etc/default/grub

	echo ""
	echo "Please make sure GRUB_CMDLINE_LINUX line is correct, and then reboot system ..."
	echo 'Correct line: GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=cl/root rd.lvm.lv=cl/swap rhgb quiet transparent_hugepage=never" '
	echo ""

	echo "PLEASE RUN THE FOLLOWING COMMANDS TO CHECK AFTER REBOOT ..."
	echo "cat /sys/kernel/mm/transparent_hugepage/enabled"
	echo "cat /sys/kernel/mm/transparent_hugepage/defrag"
	echo "grep Huge /proc/meminfo"
	echo ""
	echo "After reboot: AnonHugePages is 0, this means hugepage has been disabled."
	echo ""
	echo "Done, $FUNCNAME"
}

check_transparent_hugepage() {
	echo " "
	echo "call $FUNCNAME ..."
	echo "====== Start to $FUNCNAME on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo ""
	echo "[always] madvise never means that transparent hugepages is enabled."
	echo "always madvise [never] means that transparent hugepages is disabled."
	echo ""
	echo "cat /sys/kernel/mm/transparent_hugepage/enabled"
	cat /sys/kernel/mm/transparent_hugepage/enabled
	echo " "

	echo "cat /sys/kernel/mm/transparent_hugepage/defrag"
	cat /sys/kernel/mm/transparent_hugepage/defrag
	echo " "

	echo "grep Huge /proc/meminfo"
	grep Huge /proc/meminfo
	echo ""
	echo "After reboot: AnonHugePages is 0, this means hugepage has been disabled."
	echo ""

}

disable_tuned_Service() {
	echo " "
	echo "call $FUNCNAME ..."
	if [ "$mainversion" == "7" ]; then
		echo "Disable tuned service in CentOS7.x ..."
		systemctl start tuned
		tuned-adm off
		tuned-adm list
		echo ""
		echo "The output should contain the following line: No current active profile"
		echo ""
	
		systemctl stop tuned
		systemctl disable tuned
	fi
	echo ""
	echo "Done, $FUNCNAME"
}

echo " "
echo "============================================================"
echo " "
read -p $'Please type { change_all | check_socket_config | socket-tunning | check_mem_config | change_mem_config | change_ulimit_config | check_transparent_hugepage | disable_transparent_hugepage |  exit }:\x0a' cmd
echo " "

# See how we were called.

case "$cmd" in
	change_all)
		change_socket_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		change_mem_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		change_ulimit_config 2>&1 | tee -a $BASEDIR/log/install.log
		disable_transparent_hugepage 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	check_socket_config)
		check_socket_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	socket-tunning)
		change_socket_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		check_socket_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	check_mem_config)
		check_mem_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	change_mem_config)
		change_mem_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		check_mem_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	change_ulimit_config)
		change_ulimit_config 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	check_transparent_hugepage)
		check_transparent_hugepage 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	disable_transparent_hugepage)
		disable_transparent_hugepage 2>&1 | tee -a $BASEDIR/log/system_tunning.log
		;;
	exit)
		echo ""
		exit 1		
		;;
	*)
		echo ""
		echo  $"Usage: Please type what you want to do as shown above ..."
		echo ""
		RETVAL=2
		exit 0
		
esac

