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

#

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


if [ "$ostype" != "CentOS" ] || [ "$mainversion" != "7" ]; then
	echo "*****: The current OS is $ostype, main version: $version, this installation scriptss only support CentOS 7.x !"
fi

BASEDIR=$(pwd)

source $BASEDIR/scripts/config.sh

WWWROOT="/var/www/html"

init_web_server()
{
	echo ""
	echo "call $FUNCNAME ..."
	
	yum -y install httpd
	systemctl enable httpd
	systemctl start httpd
	
	echo "If you get an error message: Hash verification failed when trying to download the parcel from a local repository, especially in Cloudera Manager 6 and higher"
	echo "Please add \"AddType application/x-gzip .gz .tgz .parcel\" in <IfModule mime_module> section in /etc/httpd/conf/httpd.conf"
	echo "Please refer to: https://docs.cloudera.com/documentation/enterprise/upgrade/topics/cm_ig_create_local_parcel_repo.html"

	echo ""
	echo "WWWROOT: $WWWWROOT"
	echo ""
	echo "Done, $FUNCNAME"
}

init_cm_repository()
{
	main_start_time=$(date +%s)

	echo ""
	echo "call $FUNCNAME ..."
	
	mkdir -p "$WWWWROOT/cloudera-repos"
        
	wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cm6/6.3.1/redhat7/ -P /var/www/html/cloudera-repos
	wget https://archive.cloudera.com/cm6/6.3.1/allkeys.asc -P /var/www/html/cloudera-repos/cm6/6.3.1/
	chmod -R ugo+rX /var/www/html/cloudera-repos/cm6

	main_end_time=$(date +%s)
	main_cost_time=$[ $main_end_time-$main_start_time ]

	echo "== main time spend: $main_cost_time(s), $(($main_cost_time/60))min $(($main_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""
	
}

init_cdh_repository()
{
	main_start_time=$(date +%s)

	echo ""
	echo "call $FUNCNAME ..."
	
	mkdir -p "$WWWWROOT/cloudera-repos"
       
	wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/6.3.1/redhat7/ -P /var/www/html/cloudera-repos
	wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/gplextras6/6.3.1/redhat7/ -P /var/www/html/cloudera-repos
	chmod -R ugo+rX /var/www/html/cloudera-repos/cdh6
	chmod -R ugo+rX /var/www/html/cloudera-repos/gplextras6 

	main_end_time=$(date +%s)
	main_cost_time=$[ $main_end_time-$main_start_time ]

	echo "== main time spend: $main_cost_time(s), $(($main_cost_time/60))min $(($main_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""
	
}

init_parcel_repository()
{
	main_start_time=$(date +%s)

	echo ""
	echo "call $FUNCNAME ..."
	
	mkdir -p "$WWWWROOT/cloudera-repos"
       
	wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/6.3.1/parcels/ -P /var/www/html/cloudera-repos
	wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/gplextras6/6.3.1/parcels/ -P /var/www/html/cloudera-repos
	chmod -R ugo+rX /var/www/html/cloudera-repos/cdh6
	chmod -R ugo+rX /var/www/html/cloudera-repos/gplextras6

	main_end_time=$(date +%s)
	main_cost_time=$[ $main_end_time-$main_start_time ]

	echo "== main time spend: $main_cost_time(s), $(($main_cost_time/60))min $(($main_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""
}

init_local_parcel_repository()
{
	# Refer to: https://docs.cloudera.com/documentation/enterprise/upgrade/topics/cm_ig_create_local_parcel_repo.html
	main_start_time=$(date +%s)

	echo ""
	echo "call $FUNCNAME ..."

	[ -d /opt/cloudera/parcel-repo ] || mkdir -p /opt/cloudera/parcel-repo

        cd /opt/cloudera/parcel-repo
        pwd

	parcel_manifest="manifest.json"
	parcel_sha="$parcel_pkg".sha
	parcel_sha1="$parcel_sha"1
	parcel_sha256="$parcel_sha"256

	#gpl extras for lzo, compress tool
	gplextras_manifest="manifest.json"
	gplextras_sha="$gplextras_pkg".sha
	gplextras_sha1="$gplextras_sha"1
	gplextras_sha256="$gplextras_sha"256

	#init_wget_display_style

	# wget param: -c : Continue getting a partially-downloaded file
	# --progress=bar:force to only show progress in one line
	# -nc : download when file does not exist
	# wget -c --progress=bar:force http://192.168.101.65:8181/cdh/cdh6/6.3.1/parcels/CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel
        [ -f $parcel_pkg ] ||		wget -c --progress=bar:force "$parcel_base_path/$parcel_pkg"
        [ -f $parcel_manifest ] ||	wget -c --progress=bar:force "$parcel_base_path/$parcel_manifest"
        [ -f $parcel_sha1 ] ||		wget -c --progress=bar:force "$parcel_base_path/$parcel_sha1"
        [ -f $parcel_sha256 ] ||	wget -c --progress=bar:force "$parcel_base_path/$parcel_sha256"

        #cp -vf CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel.sha1  CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel.sha
        echo cp -v "$parcel_sha_name"1  $parcel_sha
        cp -v "$parcel_sha"1    $parcel_sha
	#sha1sum CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel | awk '{ print $1 }' > CDH-6.1.0-1.cdh6.1.0.p0.770702-el7.parcel.sha

	#gpl extras        
        #[ -f $gplextras_pkg ] ||	wget -c --progress=bar:force "$gplextras_base_path/$gplextras_pkg"
        #[ -f $gplextras_manifest ] ||	wget -c --progress=bar:force "$gplextras_base_path/$gplextras_manifest"
        #[ -f $gplextras_sha1 ] ||	wget -c --progress=bar:force "$gplextras_base_path/$gplextras_sha1"
        #[ -f $gplextras_sha256 ] ||	wget -c --progress=bar:force "$gplextras_base_path/$gplextras_sha256"
        #cp -vf "$gplextras_sha"1    $gplextras_sha
	
	chown cloudera-scm.cloudera-scm /opt/cloudera/parcel-repo/*

	cd $BASEDIR
	pwd

        ls -l /opt/cloudera/parcel-repo/

        systemctl restart cloudera-scm-server


	main_end_time=$(date +%s)
	main_cost_time=$[ $main_end_time-$main_start_time ]

	echo "== main time spend: $main_cost_time(s), $(($main_cost_time/60))min $(($main_cost_time%60))s"
	echo "== $FUNCNAME has finished on $(date +%Y-%m-%d_%Hh%Mm%Ss) ======"
	echo "==================================================================================================="
	echo ""
}


function init_yum_ambari_repos()
{
	echo ""
	echo "call $FUNCNAME ..."
	echo ""
	
	#backup cloudera-manager.repo when installing ambari
	[ -f /etc/yum.repos.d/cloudera-manager.repo ] && mv /etc/yum.repos.d/cloudera-manager.repo /etc/yum.repos.d/cloudera-manager.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)

	[ -f /etc/yum.repos.d/ambari.repo ] && mv -vf /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/ambari.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	cp -vf $BASEDIR/conf/ambari.repo	/etc/yum.repos.d/ambari.repo

	[ -f /etc/yum.repos.d/hdp.repo ] && mv -vf /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/hdp.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	cp -vf $BASEDIR/conf/hdp.repo		/etc/yum.repos.d/hdp.repo
	
	yum clean all
	yum makecache
	yum repolist

	echo ""
	echo "Done, $FUNCNAME"
}

function init_yum_cloudera_repos()
{
	echo ""
	echo "call $FUNCNAME ..."
	echo ""

	#backup ambari and hdp when installing cloudera_repos	
	[ -f /etc/yum.repos.d/ambari.repo ] && mv -vf /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/ambari.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	[ -f /etc/yum.repos.d/hdp.repo ] && mv -vf /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/hdp.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)

	[ -f /etc/yum.repos.d/cloudera-manager.repo ] && mv /etc/yum.repos.d/cloudera-manager.repo /etc/yum.repos.d/cloudera-manager.repo.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	cp -vf $BASEDIR/conf/cloudera-manager.repo      /etc/yum.repos.d/cloudera-manager.repo

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
	
	# Todo ...

	echo ""
	echo "Done, $FUNCNAME"
}

program_exists() 
{
	local ret='0'
	command -v $1 >/dev/null 2>&1 || { local ret='1'; }
	
	# fail on non-zero return value
	if [ "$ret" -ne 0 ]; then
		return 1
	fi

	return 0
}

init_wget_display_style()
{

	echo ""
	echo "call $FUNCNAME ..."
	

	if [[ $(program_exists msgunfmit) == 1 ]]; then
		yum -y install gettext
	fi

	msgunfmt /usr/share/locale/zh_CN/LC_MESSAGES/wget.mo -o - | sed 's/eta(英国中部时间)/ETA/' | msgfmt - -o /tmp/zh_CN.mo
	cp -vf /usr/share/locale/zh_CN/LC_MESSAGES/wget.mo  /usr/share/locale/zh_CN/LC_MESSAGES/wget.mo.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	cp -vf /tmp/zh_CN.mo /usr/share/locale/zh_CN/LC_MESSAGES/wget.mo 

}
