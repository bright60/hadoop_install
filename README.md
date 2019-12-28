# hadoop_install
The shell script is to install/uninstall Cloudera and Ambari for Hadoop in Centos7.x. The scripts were initiated from a project in 2012, now have been re-written to support the latest version of hadoop, and support Cloudera and Ambari.

## How to get?

Download zip file or clone from git

The current scripts support Cloudera 6.3.x and Ambari 2.4.x, please to get the old version scripts if you need to use the previous version of Cloudera or Ambari.

You can refer to official documentations for more details:

* Cloudera（CDH）: https://docs.cloudera.com/documentation/enterprise/6/6.3.html , Release Date: October 11, 2019 <br>
CDH 6 is based on Apache Hadoop 3. For more information, see [CDH 6 Packaging Information](https://docs.cloudera.com/documentation/enterprise/6/release-notes/topics/rg_cdh_6_packaging.html "CDH 6 Packaging Information"). <br>
CDH 5 is based on Apache Hadoop 2.3.0 or later. For information on the exact Apache Hadoop version included in each CDH 5 version, see CDH 5 Packaging and Tarball Information.<br>
Please note that you can only install CDH 6.0 or higher on up to **100 hosts **in Cloudera Express. <br><br>
 The version of services lists in https://docs.cloudera.com/documentation/enterprise/6/release-notes/topics/rg_cdh_63_packaging.html#cdh_631_packaging <br>
 
* Ambari (HDP): https://docs.cloudera.com/HDPDocuments/Ambari/Ambari-2.7.4.0/index.html  and https://docs.cloudera.com/HDPDocuments/Ambari-2.7.4.0/bk_ambari-installation/content/ch_Getting_Ready.html <br><br>
 The version of services lists in HDP-3.1.4:  http://public-repo-1.hortonworks.com/HDP/centos7/3.x/updates/3.1.4.0/HDP-3.1.4.0-315.xml <br>


## How to use?

#### 1. System tunning script
In order to make sure the servers are in high performance, the script is to tune some Linux kernal parameters. I suggest to run the tunning script before installing hadoop, the script can be used to tunning some high load server too, such as redis server, netty server and so on.
The script will include the following tunning, please refer to system_tunning.sh for details.

* network/socket,
* file descripts,
* overcommit_memory,
* swappiness,
* transparent_hugepage <br>

 cd hadoop_install <br>
 Run ./system_tunning.sh <br>
 type: all , or specific the tunning options

#### 2. Configuration before installing

* Check or change the database name, dbuser, dbpass which create for Cloudera or Ambari in conf/database/*.sql .
  The database name, dbuser, dbpass will be used during the installation.
  
* Check or change repo files for Cloudera or Ambari in conf/*.repo
  Please make sure you have Cloudera or Ambari repo on local server, or just use the offical repo server.
  
* Check or change the scripts/config.sh
```
# config clusters servers
# server node 
# the server1 is master server by default, the other servers are defined as slaver servers.
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
parcel_base_path="http://192.168.101.65:8181/cdh/cdh6/6.3.1/parcels"
parcel_pkg="CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel"

# for lzo compress, this path is only for Cloudera.
gplextras_base_path="http://192.168.101.65:8181/cdh/gplextras6/6.3.1/parcels"
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
```

* Package files and copy to all servers, all servers will have the same configuration.
```

tar cvfz hadoop_install.2012-09-21.tar.gz hadoop_install/*
#using scp or rz command
scp hadoop_install.2012-09-21.tar.gz  node2.hadoop:~/
```

#### 3. Install script (run in root user)

##### 1) Install Cloudera
###### a. Steps on master server for Cloudera
The master server means the server will install Cloudera server (may install hadoop services too), and config as server1 in scripts/config.sh <br>
* cd hadoop_install
* Run ./cloudera_install.sh <br>
 type: cloudera_install node1.hadoop   ** (Please include master server name in here, master server name is listed as the first server in scripts/config.sh, such as the server name of server1.)**

###### b. Steps on slaver server for Cloudera
The slaver server means the server will install hadoop services, and config as server2 ~ server[n] in scripts/config.sh. <br>
* cd hadoop_install
* Run ./cloudera_install.sh <br>
 type: init_slaver node2.hadoop  **(Please include slaver server name in here, slaver server names are listed from the second server in scripts/config.sh.)**

##### 2) Install Ambari
###### a. Steps on master server for Ambari
The master server means the server will install Ambari server (may install hadoop services too), and config as server1 in scripts/config.sh <br>
* cd hadoop_install
* Run ./ambari_install.sh <br>
 type: ambari_install node1.hadoop  **(Please include master server name in here, master server name is listed as the first server in scripts/config.sh, such as the server name of server1.)

* After running the last step：
 * Copy the value of JAVA_HOME from console which will be used during "ambari-server setup".
 * Follow up the instruction to run "ambari-server setup", then "ambari-server start".

###### b. Steps on slaver server for Ambari
The slaver server means the server will install hadoop services, and config as server2 ~ server[n] in scripts/config.sh. <br>
* cd hadoop_install
* Run ./ambari_install.sh <br>
 type: init_slaver node2.hadoop **(Please include slaver server name in here, slaver server names are listed from the second server in scripts/config.sh.)**
 

#### 4. Uninstall script ( Please make sure you backup the all data before uninstalling. )
 
* cd hadoop_install
* Run ./uninstall_ambari.sh or ./uninstall_cloudera.sh

You have to input the correct password to confirm before uninstalling, the password is configed as uninstall_password in scripts/config.sh.

#### 5. pkg folder ( it stores some rpm files, but some files are larger than 100M which can't be stored in github. )
Please download jdk-8u121-linux-x64.rpm into pkg folder manually if you need to install Oracle jdk using this script.

## NOTES:
In order to make sure the production environment is safe, I strongly recommend you delete all uninstall_ambari.sh and uninstall_cloudera.sh in servers after installing.

* Run the command in servers: rm uninstall_*.sh

# FAQ
## 1. ambari_install.sh or cloudera_install.sh is not not executable.
* chmod +x ambari_install.sh
* chmod +x cloudera_install.sh

## 2. No such torrent: CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel
* try to reboot server and restart cloulder server and agent ( systemctl start cloudera-scm-server,  systemctl start cloudera-scm-agent). Run ./cloudera_install.sh if the problem is still there.

## 3. Chrony time server and client (CentOS7.x uses chrony as time server/client by default instead of ntpd. )
### 1) chrony time server:
* check /etc/chrony.conf on time server (time server can be installed on master server, such as node1.hadoop)
* the follow server config should be in /etc/chrony.conf
```
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
server ntp3.aliyun.com iburst
server ntp4.aliyun.com iburst
```
* the allow config should be in the end of /etc/chrony.conf, 
```
#Allow Server Updated 2012-09-12_18:09:45
allow 10.0.2.0/24
allow 192.168.56.0/24
```
<br>
Please double check if the ip and netmask config are correct, you can run the following commmands to check in Centos7.x: <br>
ip a <br>
ip a |grep -v inet6 | grep -v 127.0.0.1 | grep inet | awk '{print $2}' <br>

### 2) chrony time client:
* check /etc/chrony.conf on slaver server (all servers(slaver) should connect to do the time sync with time server (master server, such as node1.hadoop)
* the follow server config should be in /etc/chrony.conf, at least include the first line with node1.hadoop as time server.(repalcing the actual time server to replace node1.hadoop)
```
server node1.hadoop iburst
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst

```
* all allow config should be commented out by defualt in /etc/chrony.conf, 
```
# Allow NTP client access from local network.
#allow 192.168.0.0/16
```

### 3) some useful chronyc command to check chrony status
* systemctl status chronyd
* chronyc tracking  
* chronyc sources
* chronyc sourcestats
* chronyc activity 
* chronyc ntpdata
* timedatectl

## 4. Database connection issue
### 1) ip and password are wrong
* check scripts/config.sh
* check conf/database/ambari-mysql-db.sql or conf/database/cloudera-mysql-db.sql, database name, dbuser and dbpass will be used during instalation in web page.
* the dbuser and dbpass must be consistent in scripts/config.sh and conf/database/*.sql files.

## 5. Ambari repos
### 1) setup local repos server
Please refer to： https://docs.cloudera.com/HDPDocuments/Ambari-2.7.4.0/bk_ambari-installation/content/setting_up_a_local_repository_with_no_internet_access.html
```
yum install httpd
systemctl enable httpd
systemctl start httpd

mkdir -p /var/www/html/hdp
```

### 2) download three .tar.gz files (Ambari, HDP and HDP-UTILS)
there are the download url of three packages in https://docs.cloudera.com/HDPDocuments/Ambari-2.7.4.0/bk_ambari-installation/content/ambari_repositories.html and https://docs.cloudera.com/HDPDocuments/Ambari-2.7.4.0/bk_ambari-installation/content/hdp_314_repositories.html
```
wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.4.0/ambari-2.7.4.0-centos7.tar.gz
wget http://public-repo-1.hortonworks.com/HDP/centos7/3.x/updates/3.1.4.0/HDP-3.1.4.0-centos7-rpm.tar.gz
wget http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.22/repos/centos7/HDP-UTILS-1.1.0.22-centos7.tar.gz
cp ambari-2.7.4.0-centos7.tar.gz /var/www/html/hdp
cp HDP-3.1.4.0-centos7-rpm.tar.gz /var/www/html/hdp
cp HDP-UTILS-1.1.0.22-centos7.tar.gz /var/www/html/hdp

cd /var/www/html/hdp
tar xvfz ambari-2.7.4.0-centos7.tar.gz
tar xvfz HDP-3.1.4.0-centos7-rpm.tar.gz
tar xvfz HDP-UTILS-1.1.0.22-centos7.tar.gz

chown -R apache.apache /var/www/html/hdp
```

## 6. Cloudera repos
### 1) Cloudera, three repos (Cloudera Manage repos, CDH repos and parcel repos)
Refer to: https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_create_local_package_repo.html#internal_package_repo
#### a. Cloudera Manager repo
* Offical remote RHEL 7 Compatible Repository: https://archive.cloudera.com/cm6/6.3.1/redhat7/yum/
* Create internal RHEL 7 Compatible Repository：http://ip:port/cloudera-repos/cm6/6.3.1/redhat7/yum/ , replace the actual ip and port of http server.
```
yum install httpd
systemctl enable httpd
systemctl start httpd

mkdir -p /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cm6/6.3.1/redhat7/ -P /var/www/html/cloudera-repos
wget https://archive.cloudera.com/cm6/6.3.1/allkeys.asc -P /var/www/html/cloudera-repos/cm6/6.3.1/

chmod -R ugo+rX /var/www/html/cloudera-repos/cm6

```

#### b. CDH repo (Don't require CDH repos if you use parcel installation. )
https://docs.cloudera.com/documentation/enterprise/6/release-notes/topics/rg_cdh_63_download.html#cdh_632-download

* Offical remote RHEL 7 Compatible Parcels Repository: https://archive.cloudera.com/cdh6/6.3.1/redhat7/
* Create internal RHEL 7 Compatible Repository：http://ip:port/cloudera-repos/cdh6/6.3.1/redhat7/ , replace the actual ip and port of http server.
```
Install httpd first if httpd is not installed.

mkdir -p /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/6.3.1/redhat7/ -P /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/gplextras6/6.3.1/redhat7/ -P /var/www/html/cloudera-repos

chmod -R ugo+rX /var/www/html/cloudera-repos/cdh6
chmod -R ugo+rX /var/www/html/cloudera-repos/gplextras6

```
#### c. Parcel repo (includig internal remote repos and local parcel repos)
https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_create_local_parcel_repo.html

* Offical remote RHEL 7 Compatible Parcels Repository: https://archive.cloudera.com/cdh6/6.3.1/parcels/
##### 1) internal remote repos
* Create internal remote RHEL 7 Compatible Repository：http://ip:port/cloudera-repos/cdh6/6.3.1/parcels/ , replace the actual ip and port of http server.
```
Install httpd first if httpd is not installed.

mkdir -p /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/6.3.1/parcels/ -P /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/gplextras6/6.3.1/parcels/ -P /var/www/html/cloudera-repos

chmod -R ugo+rX /var/www/html/cloudera-repos/cdh6
chmod -R ugo+rX /var/www/html/cloudera-repos/gplextras6

```

##### 2) local parcel repos
* 1) Local Parcel Repository path is /opt/cloudera/parcel-repo by default. This path（/opt/cloudera/parcel-repo/ ）exists only on the host where Cloudera Manager Server (cloudera-scm-server) runs. The repos base url can be offical base url or you can build your own internal remote parcel repos to speed up the installation before installation.
* 2) Setting in scripts/config.sh, the parcelthe parcel files will be downloaded into /opt/cloudera/parcel-repo/ during the cloudera install.
```
# parcel and gplextras config are only for Cloudera.
# parcel files will be downloaded into /opt/cloudera/parcel-repo/ in master server(cloudera server)
#parcel_base_path=https://archive.cloudera.com/cdh6/6.3.1/parcels/
parcel_base_path="http://192.168.101.65:8181/cloudera-repos/cdh6/6.3.1/parcels"
parcel_pkg="CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel"

# for lzo compress, this path is only for Cloudera.
#gplextras_base_path="https://archive.cloudera.com/gplextras6/6.3.1/parcels"
gplextras_base_path="http://192.168.101.65:8181/cloudera-repos/gplextras6/6.3.1/parcels"
gplextras_pkg="GPLEXTRAS-6.3.1-1.gplextras6.3.1.p0.1470567-el7.parcel"

```
