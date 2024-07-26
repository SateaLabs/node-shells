#!/bin/bash

# 变量初始化
projectName=${PRJECT_NAME-""}
workDir="$HOME/satea/$projectName"
dataDir="$HOME/satea/$projectName/data"

ALL_SATEA_VARS=("projectName")

# 定义要检查的包列表
packages=(
    jq
    curl
    wget
)

function checkVars() {
    # 循环遍历数组
    for var_name in "${ALL_SATEA_VARS[@]}"; do
        # 动态读取变量的值
        value=$(eval echo \$$var_name)
        if [ -z "$value" ]; then
            # 如果为空，输出错误提示
            echo "Error: Variable $var_name is not set!"
            exit 1
        else
            # 如果不为空，输出变量名及其值
            echo "Variable $var_name value is $value"
        fi
    done
}

#手动模式下 解析并填入变量的函数
function readVariables() {
    >.env.sh
    chmod +x .env.sh
    for var_name in "${ALL_SATEA_VARS[@]}"; do
        read -p "Please input $var_name: " read_value
        echo "$var_name=$read_value" >>.env.sh
    done
}

# 检查并安装每个包
function checkPackages() {
    echo "check packages ..."
    for pkg in "${packages[@]}"; do
        if dpkg-query -W "$pkg" >/dev/null 2>&1; then
            echo "$pkg installed,skip"
        else
            echo "install  $pkg..."
            sudo apt update
            sudo apt install -y "$pkg"
        fi
    done
}

function init() {
    echo "init ..."
    # 按需添加脚本
}

function install() {
    checkVars
    # 按需添加脚本
}

function start() {
    echo "start ..."
    # 按需添加脚本
}

function stop() {
    echo "stop ..."
    # 按需添加脚本
}

function upgrade() {
    echo "upgrade ..."
    # 按需添加脚本
}

function check() {
    echo "check ..."
    # 按需添加脚本
}


function logs() {
    echo "logs ...."
    # 按需添加脚本
    #..........
    ########清理数据#########
    rm -rf $workDir
}

function logs() {
    echo "logs ...."
    # 按需添加脚本
}

function About() {
    echo '   _____    ___     ______   ______   ___
  / ___/   /   |   /_  __/  / ____/  /   |
  \__ \   / /| |    / /    / __/    / /| |
 ___/ /  / ___ |   / /    / /___   / ___ |
/____/  /_/  |_|  /_/    /_____/  /_/  |_|'

    echo
    echo -e "\xF0\x9F\x9A\x80 Satea Node Installer
Website: https://www.satea.io/
Twitter: https://x.com/SateaLabs
Discord: https://discord.com/invite/satea
Gitbook: https://satea.gitbook.io/satea
Version: V1.0.0
Introduction: Satea is a DePINFI aggregator dedicated to breaking down the traditional barriers that limits access to computing resources.  "
    echo""
}

case $1 in
check-packages)
    checkPackages
    ;;
init)
    init
    ;;
install)
    if [ "$2" = "--auto" ]; then
        #这里使用自动模式下的 安装 函数
        install
    else
        #手动模式 使用Manual 获取用户输入的变量
        readVariables #获取用户输入的变量
        . .env.sh     #导入变量
        #其他安装函数
        install
    fi
    ;;
start)
    #创建启动节点的函数

    ;;
stop)
    #创建停止节点的函数

    ;;
upgrade)
    #创建升级节点的函数

    ;;
check)
    #创建一些用于检查节点的函数

    ;;
clean)
    #创建清除节点的函数

    ;;
logs)
    #打印节点信息

    ;;

**)

    #定义帮助信息 例子
    About
    echo "Flag:
  check-packages       Check basic installation package
  install              Install $projectName environment
  init                 Install Dependent packages
  start                Start the $projectName service
  stop                 Stop the $projectName service
  upgrade              Upgrade an existing installation of $projectName
  check                Check $projectName service status
  clean                Remove the $projectName from your service, remove data!!! 
  logs                 Show the logs of the $projectName service"
    ;;
esac
