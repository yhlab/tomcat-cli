#!/bin/bash

#Tomcat Instance

#初始化参数
EXEC_BASE=$(cd `dirname $0`; pwd)
CATALINA_BASE=$(cd $EXEC_BASE/../; pwd)

PATH_CONFIG=$CATALINA_BASE/conf
PATH_LOGS=$CATALINA_BASE/logs

CONFIG_SERVER=$PATH_CONFIG/server.xml
CONFIG_SERVER_TMP=$PATH_CONFIG/server.xml.tmp
CONFIG_INST=$PATH_CONFIG/instance.conf

LOCK_VERSION=$CATALINA_BASE/.lockVer


#初始化环境变量
function initEnv()
{
    #加载实例配置
    if [ -f "$CONFIG_INST" ]; then
	source $CONFIG_INST
    fi

    #加载全局配置
    if [ -n "$TOMCLI_HOME" ]; then
	source $TOMCLI_HOME/global.conf
    fi

    if [ -z "$JAVA_HOME" ] && [ -n "$GLOBAL_JAVA_HOME" ]; then
	export JAVA_HOME=$GLOBAL_JAVA_HOME
    fi

    if [ -z "$CATALINA_HOME" ] && [ -n "$GLOBAL_CATALINA_HOME" ]; then
	export CATALINA_HOME=$GLOBAL_CATALINA_HOME
    fi
    
    export CATALINA_BASE=$CATALINA_BASE
    export CLASSPATH=$CLASSPATH:$CATALINA_HOME/bin/bootstrap.jar:$CATALINA_HOME/bin/tomcat-juli.jar
    
    if [ ! -d "$PATH_LOGS" ]; then
    	mkdir $PATH_LOGS
    fi
}

#生成配置文件
function createConfig()
{
    echo -n "Update Server.xml ...."
    if [ -f "$CONFIG_SERVER" ]; then
	rm -rf $CONFIG_SERVER
    fi

    cp $CONFIG_SERVER_TMP $CONFIG_SERVER
    
    #替换参数
    sed -i "s/\[CONTROL_PORT\]/$CONTROL_PORT/g; s/\[SERVICE_PORT\]/$SERVICE_PORT/g; s/\[HTTPS_PORT\]/$HTTPS_PORT/g; s?\[APP_BASE_PATH\]?$APP_BASE_PATH?g" $CONFIG_SERVER

    #处理AJP
    if [ -n "$AJP_PORT" ] && [ "$AJP_PORT" != "disable" ]; then
    	sed -i "s?\[AJP_PORT\]?<Connector port=\"$AJP_PORT\" protocol=\"AJP/1.3\" redirectPort=\"$HTTPS_PORT\" />?g" $CONFIG_SERVER
    else
	sed -i "s/\[AJP_PORT\]/''/g" $CONFIG_SERVER
    fi    

    #处理Context
    if [ -n "$ROOT_CONTEXT" ]; then
	sed -i "s?\[ROOT_CONTEXT\]?<Context path=\"\" docBase=\"$ROOT_CONTEXT\" debug=\"0\" reloadable=\"true\"/>?g" $CONFIG_SERVER
    else
	sed -i "s/\[ROOT_CONTEXT\]/''/g" $CONFIG_SERVER
    fi
    
    echo -n " Done."
    echo ""
}

#更新配置
#如果配置参数修改过，则应该启动时，进行配置更新
function updateConfig()
{
    #拼接参数字符串
    STR_PARAMS="$CONTROL_PORT|$SERVICE_PORT|$HTTPS_PORT|$AJP_PORT|$APP_BASE_PATH|$ROOT_CONTEXT"

    #md5sum
    MD5SUM_PARAMS=$(echo -n $STR_PARAMS|md5sum|cut -d ' ' -f1)

    #比较版本
    NOW_VERSION="0"
    if [ -f "$LOCK_VERSION" ]; then
        NOW_VERSION=$(cat $LOCK_VERSION)
    fi
    echo "Now Version: $NOW_VERSION"

    if [ "$NOW_VERSION" != "$MD5SUM_PARAMS" ]; then
        echo "Update Version."
        echo -n "$MD5SUM_PARAMS" >$LOCK_VERSION
        createConfig
    fi
}


#Tomcat 辅助函数

#Tomcat 启动
function tomcatStart()
{
    #检查配置
    updateConfig
    #启动
    $CATALINA_HOME/bin/startup.sh    
}


#Tomcat 停止
function tomcatStop()
{
    #停止
    $CATALINA_HOME/bin/shutdown.sh
}

#Tomcat 强制停止
function tomcatKill()
{
    fuser -k -n tcp $SERVICE_PORT
}

#Tomcat 清除日志
function clearLogs()
{
    rm -rf $CATALINA_BASE/logs/*
}

#Tomcat 清除版本锁定
function unlock()
{
    if [ -f "$LOCK_VERSION" ]; then
    	rm -rf $LOCK_VERSION
    fi
}

#Tomcat 帮助
function tomcatHelp()
{
    echo ""
    echo "Help"
}

#main

ACTION=$1

initEnv

if [ ! -n "$ACTION" ]; then
    tomcatHelp
elif [ "$ACTION" == "start" ]; then
    tomcatStart	
elif [ "$ACTION" == "stop" ]; then
    tomcatStop
elif [ "$ACTION" == "kill" ]; then
    tomcatKill
elif [ "$ACTION" == "clear" ]; then
    clearLogs
else
    tomcatHelp
fi




