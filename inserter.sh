#!/bin/bash

#初始化参数
EXEC_BASE=$(cd `dirname $0`; pwd)

# 自动安装

function download()
{
    echo -n "Begin Download...."
}

#注册全局
#ln -s $EXEC_BASE/bin/tomcat-cli.sh /usr/local/bin/tomcat-cli
