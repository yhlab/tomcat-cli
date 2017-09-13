#!/bin/bash

#初始化
EXEC_BASE=$(cd `dirname $0`; pwd)
EXEC_HOME=$(cd $EXEC_BASE/../; pwd)
CONFIG_GLOBAL=$EXEC_HOME/global.conf

#加载全局配置
function loadGlobalConfig()
{
    if [ -f "$CONFIG_GLOBAL" ]; then
	source $CONFIG_GLOBAL
    fi
}


#创建实例目录
function createInstance()
{
    if [ ! -n "$1" ]; then
        echo "Please input the Instance name!"
	exit
    else
        INST_HOME=$(pwd)/$1
	
	#实例目录创建逻辑
	if [ -d $INST_HOME ]; then
	    read -p "The Instance Exists, Recreate(y/n)? " doCreate;
	    #判断输入，默认为n
	    if [ ! -n "$doCreate" ]; then
	    	doCreate='n'
	    fi
	
	    #如果选择覆盖，则清除目录
	    if [ $doCreate == 'y' ]; then
		rm -rf $INST_HOME
		mkdir $INST_HOME
	    fi
	else
	    mkdir $INST_HOME 
	fi

	#获取创建路径
	INST_HOME=$(cd $INST_HOME; pwd)
	#创建文件
	copyTemplates
	#生成配置
	configInstance
    fi
}

#复制实例模板
function copyTemplates()
{
    echo -n "Creating...."
    cp -r $EXEC_HOME/template/* $INST_HOME
    chmod +x $INST_HOME/bin/*.sh
    echo " Done."
    echo "" 
}

#配置实例属性
function configInstance()
{
    read -p "Tomcat Control Port: " inst_ctl_port;
    read -p "Tomcat Service Port: " inst_ser_port;
    read -p "HTTPS Service Port(8443): " inst_https_port;
    read -p "Tomcat AJP Port(If disable, please enter 0 or skip): " inst_ajp_port;
    read -p "Tomcat AppBase Path(webapp): " inst_webapp_path;
    read -p "Root Context(ROOT): " inst_root_project;
    
    #check HTTPS
    if [ ! -n "$inst_https_port" ]; then
	inst_https_port=8443
    fi

    #check AJP
    if [ ! -n "$inst_ajp_port" ]; then
	inst_ajp_port="disable"
    elif [ $inst_ajp_port -eq 0 ]; then
	inst_ajp_port="disable"
    fi    
 
    #check Webapp
    if [ ! -n "$inst_webapp_path" ]; then
	inst_webapp_path="webapp"
    fi 

    #信息输出
    echo ""
    echo "----------create Instance----------"
    echo "   Home Path: $INST_HOME"
    echo "Control Port: $inst_ctl_port"
    echo "Service Port: $inst_ser_port"
    echo "  Https Port: $inst_https_port"
    echo "    AJP Port: $inst_ajp_port"
    echo "AppBase Path: $inst_webapp_path"
    echo "Root Context: $inst_root_project"
    echo ""
    read -p "Do you want to continue(y/n)? " doReplace;
  
    #check continue
    if [ ! -n "$doReplace" ]; then
	doReplace=n
    fi
 
    if [ $doReplace == 'y' ]; then
	#执行配置输出
	inst_config=$INST_HOME/conf/instance.conf
	
	echo "#env config" > $inst_config
	echo "JAVA_HOME=" >> $inst_config
	echo "CATALINA_HOME=" >> $inst_config
	echo "JVM_OPTIONS=" >> $inst_config

	echo ""	>> $inst_config
	echo "#instance config" >> $inst_config
	echo "CONTROL_PORT=$inst_ctl_port" >> $inst_config
	echo "SERVICE_PORT=$inst_ser_port" >> $inst_config
	echo "HTTPS_PORT=$inst_https_port" >> $inst_config

	if [ "$inst_ajp_port" != "disable" ]; then
	    echo "AJP_PORT=$inst_ajp_port" >> $inst_config
	fi

	echo "APP_BASE_PATH=$inst_webapp_path" >> $inst_config
	echo "ROOT_CONTEXT=$inst_root_project" >> $inst_config
	
	echo "" >> $inst_config
	echo "#tomcat-cli config" >> $inst_config
	echo "TOMCLI_HOME=$EXEC_HOME" >> $inst_config	
	
	echo ""
	echo "Generate complete. Thank you for using."
	echo ""
    else
	exit;
    fi
}

#main
loadGlobalConfig

read -p "Instance name: " name;
createInstance $name;

