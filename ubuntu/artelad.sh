#!/bin/bash

# 变量初始化
workDir="$HOME/satea/"
moniker=${MONIKER-""}
walletName=${WALLET_NAME-""}
ALL_SATEA_VARS=("moniker" "walletName")
mkdir $workDir
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

function install() {
    cd $workDir
    git clone https://github.com/artela-network/artela
    cd artela
    git checkout v0.4.7-rc7-fix-execution 
    make install
    cd $HOME
    wget https://github.com/artela-network/artela/releases/download/v0.4.7-rc7-fix-execution/artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
    tar -xvf artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
    mkdir libs
    mv $HOME/libaspect_wasm_instrument.so $HOME/libs/
    mv $HOME/artelad /usr/local/bin/
    echo 'export LD_LIBRARY_PATH=$HOME/libs:$LD_LIBRARY_PATH' >> ~/.bash_profile
    source ~/.bash_profile
    #wget https://github.com/artela-network/artela/releases/download/v0.4.8-rc8/artelad_0.4.8_rc8_Linux_amd64.tar.gz
    #tar -xvf artelad_0.4.8_rc8_Linux_amd64.tar.gz
    artelad config chain-id artela_11822-1
    artelad init "$moniker" --chain-id artela_11822-1
    artelad config node tcp://localhost:3457
    curl -L https://snapshots.dadunode.com/artela/genesis.json > $HOME/.artelad/config/genesis.json
    curl -L https://snapshots.dadunode.com/artela/addrbook.json > $HOME/.artelad/config/addrbook.json
    SEEDS=""
    PEERS="ca8bce647088a12bc030971fbcce88ea7ffdac50@84.247.153.99:26656,a3501b87757ad6515d73e99c6d60987130b74185@85.239.235.104:3456,2c62fb73027022e0e4dcbdb5b54a9b9219c9b0c1@51.255.228.103:26687,fbe01325237dc6338c90ddee0134f3af0378141b@158.220.88.66:3456,fde2881b06a44246a893f37ecb710020e8b973d1@158.220.84.64:3456,12d057b98ecf7a24d0979c0fba2f341d28973005@116.202.162.188:10656,9e2fbfc4b32a1b013e53f3fc9b45638f4cddee36@47.254.66.177:26656,92d95c7133275573af25a2454283ebf26966b188@167.235.178.134:27856,2dd98f91eaea966b023edbc88aa23c7dfa1f733a@158.220.99.30:26680"
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml
    sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.artelad/config/app.toml
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.artelad/config/app.toml
    sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"0\"/" $HOME/.artelad/config/app.toml
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.artelad/config/app.toml
    sed -i -e 's/max_num_inbound_peers = 40/max_num_inbound_peers = 100/' -e 's/max_num_outbound_peers = 10/max_num_outbound_peers = 100/' $HOME/.artelad/config/config.toml

    node_address="tcp://localhost:3457"
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:3458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:3457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:3460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:3456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":3466\"%" $HOME/.artelad/config/config.toml
    sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:3417\"%; s%^address = \":8080\"%address = \":3480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:3490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:3491\"%; s%:8545%:3445%; s%:8546%:3446%; s%:6065%:3465%" $HOME/.artelad/config/app.toml
    #mv $HOME/.artelad $workDir/
    #ln -s $workDir/.artelad $HOME/
    pm2 start artelad -- start && pm2 save && pm2 startup
    
    artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
    echo "导入快照。。。。"
    curl https://snapshots-testnet.nodejumper.io/artela-testnet/artela-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $workDir/.artelad
    #lz4 -dc artela-testnet_latest.tar.lz4 | tar -x -C $projectName/.artelad
  

     pm2 restart artelad

}


function create_validator(){
  artelad tx staking create-validator \
      --amount="1000000000000000000uart" \
      --pubkey=$(artelad tendermint show-validator) \
      --moniker="$moniker" \
      --commission-rate="0.10" \
      --commission-max-rate="0.20" \
      --commission-max-change-rate="0.01" \
      --min-self-delegation="1" \
      --gas="200000" \
      --chain-id=artela_11822-1 \
      --from=$(artelad keys list |grep name |awk '{print $2}') \
      -y
}
function create_wallet(){
  artelad config keyring-backend file
  artelad keys add $walletName 2>&1 |tee $walletName.txt
}
function height(){
  artelad status | jq .SyncInfo.latest_block_height
}
function balances(){
  artelad q bank balances $(artelad keys show $walletName -a)
}

function address(){
  artelad keys show $walletName -a
}

function Val_address(){
  artelad debug addr $(artelad keys show $walletName -a)
}
function import_key(){
  artelad config keyring-backend file
  artelad keys add  $walletName --recover
}
function start() {
    echo "start ..."
    checkVars
  pm2 start artelad
}

function stop() {
    echo "stop ..."
    pm2 stop artelad
}

function clean() {
    projectName="artela"
    workDir="$HOME/satea/$projectName"
    echo "clean ...."
    pm2 stop artelad && pm2 delete artelad && pm2 save 
    rm -rf $workDir
    rm -rf $HOME/.artelad
    rm -rf $(which artelad)
}

function logs() {
    echo "logs ...."
    pm2 logs artelad
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
    start
    ;;
stop)
    stop
    ;;
create_validator)
    create_validator
    ;;
create_wallet)
    create_wallet
    ;;
height)
    height
    ;;
balances)
    balances
    ;;
address)
    address
    ;;
Val_address)
    Val_address
    ;;
import_key)
    import_key
    ;;
clean)
    clean
    ;;
logs)
    logs
    ;;

**)

    #定义帮助信息 例子
    About
    echo "Flag:
  check-packages       Check basic installation package
  install              Install $projectName environment
  start                Start the $projectName service
  stop                 Stop the $projectName service
  create_validator     create validator
  create_wallet        create wallet
  height               show your node height
  balances             show your balances
  address              show your address
  Val_address          show you validator address
  import_key           import your keys
  clean                Remove the $projectName from your service, remove data!!! 
  logs                 Show the logs of the $projectName service"
    ;;
esac
