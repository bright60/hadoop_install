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

# Updated by BX, on 2015-06-02

echo "ostype: $ostype"
if [ "$ostype" == "" ];then
        echo "$0 can't be executed directly ..."
        echo ""
        exit
fi

function init_mysql_jdbc()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	#install JDBC driver
	#yum install mysql-connector-java -y
	
	[ -d /usr/share/java ] || mkdir -p /usr/share/java
	[ -f /usr/share/java/mysql-connector-java.jar ] && mv -f /usr/share/java/mysql-connector-java.jar  /usr/share/java/mysql-connector-java.jar.$(date +%Y-%m-%d_%Hh%Mm%Ss)

	cp -vf $BASEDIR/pkg/$MYSQLJDBC_DRIVER_PKG       /usr/share/java/mysql-connector-java.jar
	chmod 644 /usr/share/java/mysql-connector-java.jar

	echo ""
	ls -l /usr/share/java/mysql-connector-java.jar

	echo ""
	echo "Done, $FUNCNAME"
}

 
function jdk_install()
{
	echo ""
	echo "call $FUNCNAME ..."

	echo "====== Start to install $JDK_PKG_VERSION on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	source /etc/profile
 
#====== Install JDK ======
#Check if OpenJDK was installed, by BX, on 2013-08-26
result=`rpm -qav | grep java`
if [ "$result" = "" ]
then
          echo 'OpenJDK is not installed'
else
          echo 'OpenJDK is installed': $result
          echo 'Un-install OpenJDK ...'
          rpm -qav | grep java| xargs rpm -e --nodeps
fi

#Check if Oracle JDK has been installed and if java path is correct, by bright, on 2013-10-21
JDK_IS_INSTALLED=0
result=`rpm -qav | grep jdk`
if [ "$result" = "" ]
then
			echo 'Oracke JDK is not installed'			
else
			echo 'Oracke JDK is installed': $result
			#JDK is installed, now to check if java path has been set correctly..
			type java > /dev/null 2>&1
			if [ $? = 0 ]
			then
				JDK_IS_INSTALLED=1 	
				echo 'Oracle JDK is installed and java path correctly.'
				if [ -z "$JAVA_HOME" ]; then
					echo "Error: Oracle JDK is installed, but JAVA_HOME is not setting, now to re-install JDK using the software_install script."
                        		echo " "
					
					echo 'Force to un-install Oracle JDK, then re-install ...'
					rpm -e --nodeps $result
					JDK_IS_INSTALLED=0
                		else
                        		echo "JAVA_HOME:"$JAVA_HOME
                		fi
				
				if [ $FORCE_JDK_REINSTALL = 1 ]
				then
					echo 'Force to un-install Oracle JDK, then re-install ...'
					rpm -e --nodeps $result
					JDK_IS_INSTALLED=0
				fi
			else
				echo 'Oracle JDK is installed, but java path is not correct, now to un-install and re-install ...'
				rpm -e --nodeps $result
				#rpm -ivh $BASEDIR/pkg/jdk-7u80-linux-x64.rpm
			fi
fi

#if java is not install, then to install java, and set env var
JAVA_HOME=$JDK_INSTALL_BASEPATH/$JDK_PKG_VERSION
echo "---1: $JAVA_HOME"	
if [ "$JDK_IS_INSTALLED" != "1" ];then
	echo 'Start to install Oracle JDK ...'
	
	cd $BASEDIR/pkg
	[ -f $JDK_PKG ] 

	#if java package name doesn't inlcude rpm, this mean it is not rpm package, then using .tar.gz package
	echo "------1: "$JDK_PKG
	JDK_PKG_RPM=0
	if [[ $JDK_PKG == *rpm* ]]
	then
		JDK_PKG_RPM=1
		rpm -ivh $BASEDIR/pkg/$JDK_PKG
		#JAVA_HOME=/usr/java/jdk1.7.0_80	
		JAVA_HOME=/usr/java/$JDK_PKG_VERSION	
		echo "---2: $JAVA_HOME"	
	else
		JDK_PKG_RPM=0 
		#echo "不包含"
		#JDK_INSTALL_BASEPATH=/usr/java #defined in config.sh
		tar xvzf $BASEDIR/pkg/$JDK_PKG -C $JDK_INSTALL_BASEPATH
		JAVA_HOME=$JDK_INSTALL_BASEPATH/$JDK_PKG_VERSION
	fi

	#install JDBC driver
	init_mysql_jdbc
	
	#Setting evn
	JRE_HOME=$JAVA_HOME/jre
	CLASS_PATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib
	PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
	echo '' >> /etc/profile
	grep "JAVA_HOME" /etc/profile || echo 'JAVA_HOME='$JAVA_HOME >> /etc/profile
	grep "JRE_HOME" /etc/profile || echo 'JRE_HOME=$JAVA_HOME/jre' >> /etc/profile
	grep "export JAVA_HOME" /etc/profile || echo 'export JAVA_HOME' >> /etc/profile
	grep "JAVA_HOME/lib/dt.jar" /etc/profile || echo 'export CLASS_PATH=$CLASS_PATH:''.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib' >> /etc/profile
	grep "JAVA_HOME/bin" /etc/profile || echo 'export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin' >> /etc/profile
	source /etc/profile 
	echo 'End to install Oracle JDK and /etc/profile setting.'
fi

source /etc/profile

echo " "
echo "====================================================================================="
echo "== JDK version      : $JDK_PKG_VERSION"
echo "== JDK pkg          : $JDK_PKG"
echo "== JDK install path : $JDK_INSTALL_BASEPATH"
echo "== JAVA_HOME        : $JAVA_HOME"
echo "== "
echo "== $JDK_PKG_VERSION install has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======" 
echo "====================================================================================="
echo " "
}
 

#jdk_install 2>&1 | tee -a $BASEDIR/log/install.log
