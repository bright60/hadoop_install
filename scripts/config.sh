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

# Updated by bright, on 2012-12-09

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

######################################################################################
###### PLEASE CHAGNE THE FOLLOW PARAMETERS ACCORDING TO YOUR SERVER ENVIRONMENT ######
######################################################################################

BACKUPDIR="/backup" 
PKGSRC="$BASEDIR/pkgsrc"

# server node, config clusters servers
# the server1 is master server by default.
# servrex="ip	servername"
server1="192.168.56.101	node1.hadoop"
server2="192.168.56.102	node2.hadoop"
server3="192.168.56.103	node3.hadoop"
#server4="192.168.56.104	node4.hadoop"
#server5="192.168.56.105	node5.hadoop"
#server6="192.168.56.106	node6.hadoop"
#server7="192.168.56.107	node7.hadoop"
#server8="192.168.56.108	node8.hadoop"
#server9="192.168.56.109	node9.hadoop"
#server10="192.168.56.110	node10.hadoop"

# Don't change max_server_number if the number of server is less then 100
max_server_number=100

# parcel and gplextras config are only for Cloudera.
# parcel files will be downloaded into /opt/cloudera/parcel-repo/ in master server(cloudera server)
#parcel_base_path="https://archive.cloudera.com/cdh6/6.3.1/parcels/"
parcel_base_path="http://192.168.101.65:8181/cloudera-repos/cdh6/6.3.1/parcels"
parcel_pkg="CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel"

# for lzo compress, this path is only for Cloudera.
#gplextras_base_path="https://archive.cloudera.com/gplextras6/6.3.1/parcels"
gplextras_base_path="http://192.168.101.65:8181/cloudera-repos/gplextras6/6.3.1/parcels"
gplextras_pkg="GPLEXTRAS-6.3.1-1.gplextras6.3.1.p0.1470567-el7.parcel"

# ******** MYSQL Configuration  ********
MYSQL_DB_SERVER=127.0.0.1
MYSQL_DB_USER=root
#MYSQL_DB_PASS=%WJLk)_3_HvB
MYSQL_DB_PASS=root
MYSQL_PORT_NUM=3306

# scm config are only for Cloudera.
SCM_DB_NAME=scm
SCM_DB_USER=scm
SCM_DB_PASS=scm8899
SCM_SERVER_NAME=node1.hadoop

# ******** JDK Configuration  ********
FORCE_JDK_REINSTALL=1 # set 1 to reinstall
JDK_PKG_VERSION=jdk1.8.0_121
JDK_PKG=jdk-8u121-linux-x64.rpm
JDK_INSTALL_BASEPATH=/usr/java
MYSQLJDBC_DRIVER_PKG=mysql-connector-java-5.1.46.jar

#Cloudera recommends using only version 5.1 of the JDBC driver.
#MYSQLJDBC_DRIVER_PKG=mysql-connector-java-8.0.18.jar

# 
uninstall_password="remove55tree"
######################################################################################
