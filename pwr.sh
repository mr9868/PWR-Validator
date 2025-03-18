# Set variables and array URL JDK latest
#cd $HOME;
#if [ ! -d pwrValidator ];
#then
#mkdir pwrValidator;
#cd pwrValidator;
#else
#cd pwrValidator;
#fi

myIP=$( curl -w "\n" ifconfig.me 2>/dev/null );
arch=$(uname -m);
getPwd=${PWD}
if [ $arch == "x86_64" ];
then
arch=x64;
fi

if [ -f validator.jar ];
then
valDir=$( pwd );
fi



# Required package
command -v screen >/dev/null 2>&1 || { echo >&2 "Screen is not found on this machine, Installing screen ... "; sudo apt update -y && sudo apt install -y screen;}
command -v curl >/dev/null 2>&1 || { echo >&2 "Curl is not found on this machine, Installing curl ... "; sudo apt install -y curl;}
command -v wget >/dev/null 2>&1 || { echo >&2 "Wget is not found on this machine, Installing wget ... "; sudo apt install -y wget;}
command -v tar >/dev/null 2>&1 || { echo >&2 "Tar is not found on this machine, Installing tar ... "; sudo apt install -y tar;}
command -v iptables >/dev/null 2>&1 || { echo >&2 "Iptables is not found on this machine, Installing iptables ... "; sudo apt install -y iptables;}
command -v ufw >/dev/null 2>&1 || { echo >&2 "Ufw is not found on this machine, Installing ufw ... "; sudo apt install -y ufw;}
command -v jq >/dev/null 2>&1 || { echo >&2 "JQ is not found on this machine, Installing jq ... "; sudo apt install -y jq;}
command -v bc >/dev/null 2>&1 || { echo >&2 "bc is not found on this machine, Installing bc ... "; sudo apt install -y bc;}


function install_pwr(){
sudo rm -rf validator.jar config.json;
echo "Downloading ... ⏳";
wget https://github.com/pwrlabs/PWR-Validator/releases/latest/download/validator.jar 2>/dev/null;
wget https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json 2>/dev/null;
valDir=$( pwd );
}

function showVer(){
if [ -f validator.jar ]; 
then
pwrVer=$( sudo java -jar validator.jar 2>/dev/null | grep version | awk '{print $3}' ) ;
pwrLtsVer=$( curl https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest 2>/dev/null | jq -r .html_url | sed "s/.*tag\///g" );
myVer=$( echo $pwrVer | sed "s/\.//g" );
ltsVer=$( echo $pwrLtsVer | sed "s/\.//g" );
if [ -n "$pwrVer" ];
then
if [ "$ltsVer" -gt $myVer ];
then
echo "Your PWR node version is : ${pwrVer}"
echo "Latest PWR node version ${pwrLtsVer} found !";
else
echo "Your PWR node version is : ${pwrVer}"
fi
fi
else
echo "Validator not found ! Installing ...";
install_pwr;
fi
}


# My Header
function myHeader(){
clear;
echo  "<=()=====================================================()=>"
echo  "=             PWR validator setup auto installer           ="
echo  "=                    Created by : Mr9868                   ="
echo  "=             Github : https://github.io/Mr9868            ="
echo  "============================================================"
echo  "=                Your OS info : $(uname -s) $(uname -m)               ="
echo  "=                 IP Address : ${myIP}               ="
echo  "<=()=====================================================()=>"
if [ -f /.dockerenv ]; then
echo  -e "\n            You're inside a container, always use"
echo  -e "                    PRESS CTRL+P+Q TO QUIT" 
echo
else
    echo;
fi
}
# End of myHeader


# checkVersion function 
function checkVersion(){
if [ -n "$pwrVer" ];
then
if [ "$ltsVer" -gt "$myVer" ];
then
echo "Latest version found ! installing ... ⏳"
install_pwr;
else
read -p "There is no latest version found, Do you want to redownload config file ? (y/n) => " download
if [[ "$download" == "y" ]];
then
install_pwr;
fi
fi
fi
}
# Enf of checkVersion

# function check if PWR node run properly
function checkPwr(){
{ pwrAddr=$(curl localhost:8085/address/); } 2>/dev/null;
myHeader;
if [ -z "$pwrAddr" ];
then
echo "[ERROR] There is an error on your PWR node !"
read -p "Do you want to run full installation ? (y/n) => " errQn
if [ "$errQn" == "y" ]; 
then
mainInstall;
else
echo -e "There is ERROR on your PWR node !\nPlease restart your PWR node !"
exit 1;
fi
else
echo "[INFO] PWR node running successfully ...";
fi
}
# End of checkPwr



# Kill previous
function kill_apps(){
screen -X -S pwr quit;
pkill -f "java";
pkill -9 java;
pkill java;
screen -X -S pwrBot quit;
echo "Kill previous session ..."

}
# End of kill_apps



# Unblock IPs and domain that blocked by pwr node
function unblockIPs(){
echo "Please wait, unblocking blocked IP ..."
if [ -f listDrops.sh ];
then
chmod  +x listDrops.sh && ./listDrops.sh;
echo -e "Unblocked IPs successfully ✅ \n";
else
echo -e "Unblock IPs from previous PWR node ... ⌛ \n";

listDrops=$(iptables -S | grep DROP | sed "s/DROP/DROP #/g");
echo $listDrops | sed 's/#/\&\& \n/g' | sed 's/-A/iptables -D /g' > listDrops.sh;
echo "echo 'Success ✅'" >> listDrops.sh;
chmod  +x listDrops.sh && ./listDrops.sh;
echo -e "Unblocked IPs successfully ✅ \n"

fi
}
# End of unblockIPs


# Install java function
function install_java(){
sudo apt update -y && sudo apt upgrade -y;
javaList=(https://download.oracle.com/java/23/latest/jdk-23_linux-${arch}_bin.tar.gz https://download.java.net/java/early_access/jdk24/27/GPL/openjdk-24-ea+27_linux-${arch}_bin.tar.gz);
jdkList=(jdk-23.0.2 jdk-24);
set | grep ^javaList=
set | grep ^jdkList=

dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' -e '^java-common' | xargs sudo apt-get -y remove;
sudo apt-get -y autoremove;

sudo bash -c 'ls -d /home/*/.java' | xargs sudo rm -rf &&
sudo rm -rf /usr/lib/jvm/* &&
sudo rm -rf /usr/local/java &&
sudo apt purge -y java-common &&
sudo mount /tmp -o remount,exec && 
sudo update-alternatives --remove-all java;

# JDK latest (v23 and v24)
function jdkLts(){
sudo apt install -y java-common &&
wget -O javalts.tar.gz ${javaVer} &&
sudo mkdir /usr/local/java &&
sudo mv javalts.tar.gz /usr/local/java &&
cd /usr/local/java &&
sudo tar zxvf javalts.tar.gz &&
sudo rm -rf javalts.tar.gz &&
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/${jdkVer}/bin/java" 1 &&
cd $getPwd;
}

# List JDK version provided by default apt list
function listJdk(){
sudo apt install -y openjdk-${jdkVer}-jdk &&
sudo apt install -y openjdk-${jdkVer}-jre &&
sudo apt install -y java-common;
}

myHeader;
echo -e "List Supported Java Version : \n"
echo -e "1. Java JDK 17\n"
echo -e "2. Java JDK 18\n"
echo -e "3. Java JDK 19\n"
echo -e "4. Java JDK 21\n"
echo -e "5. Java JDK 23\n"
echo -e "6. Java JDK 24\n" 
echo -e "Press any key to exit\n"

read -p "Choose java version =>  " cJava
until [[ "${cJava}" =~ ^[0-6]+$ ]];
do
myHeader;
echo -e "List Supported Java Version : \n"
echo -e "1. Java JDK 17\n"
echo -e "2. Java JDK 18\n"
echo -e "3. Java JDK 19\n"
echo -e "4. Java JDK 21\n"
echo -e "5. Java JDK 23\n"
echo -e "6. Java JDK 24\n" 
echo -e "0. Exit\n"

echo -e "Error: Please select valid option ! \n"
read -p "Choose java version =>  " cJava
done


if [[ "$cJava" == "1" ]];
then
jdkVer=17;
listJdk;
elif [[ "$cJava" == "2" ]];
then
jdkVer=18;
listJdk;
elif [[ "$cJava" == "3" ]];
then
jdkVer=19;
listJdk;
elif [[ "$cJava" == "4" ]];
then
jdkVer=21;
listJdk;
elif [[ "$cJava" == "5" ]];
then
javaVer=${javaList[0]};
jdkVer=${jdkList[0]};
jdkLts;
elif [[ "$cJava" == "6" ]];
then
javaVer=${javaList[1]};
jdkVer=${jdkList[1]};
jdkLts;
else
exit 1;
fi
}
# end install_java function

# TeleBot Configuration 
function tgConf(){
echo "
valDir=\"${valDir}\";
. ~/.mr9868/pwr/config
API_TOKEN=\${tgApiQn}
CHAT_ID=\${tgIdQn}
msgTg=\$(echo -e \"<b>[ INFO ]</b> Starting PWR bot server ... \")
tgTest=\$(curl -s -X POST https://api.telegram.org/bot\${API_TOKEN}/sendMessage -d chat_id=\${CHAT_ID} -d text=\"\${msgTg}\" -d parse_mode=\"HTML\" | grep 'error_code') 
tgTest=\$(echo \${tgTest})
until [ -z \"\${tgTest}\" ];
do
echo -e \"[ ERROR ] Unauthorized !\nPlease recheck your API and CHAT ID and make sure you starting your bot\"
tgQnCheck
tgTest=\$(curl -s -X POST https://api.telegram.org/bot\${API_TOKEN}/sendMessage -d chat_id=\${CHAT_ID} -d text=\"\${msgTg}\" -d parse_mode=\"HTML\" | grep 'error_code')
tgTest=\$(echo \${tgTest})
done
echo -e \${msgTg}

urlCek=https://pwrrpc.pwrlabs.io//validator/?validatorAddress=
urlBlockCek=https://pwrrpc.pwrlabs.io//block/?blockDetails\&blockNumber=
nodeVer=\$( cd \$valDir; sudo java -jar validator.jar  2>/dev/null | grep version | sed 's/\./\\\\\\\\\./g' ) ;
pwrVer=\$( cd \$valDir; sudo java -jar validator.jar  2>/dev/null | grep version | awk '{print \$3}' ) ;
function showVer(){
pwrVer=\$( cd \$valDir; sudo java -jar validator.jar  2>/dev/null | grep version | awk '{print \$3}' ) ;
pwrLtsVer=\$( curl https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest 2>/dev/null | jq -r .html_url | sed \"s/.*tag\///g\" );
myVer=\$( echo \$pwrVer | sed \"s/\.//g\" );
ltsVer=\$( echo \$pwrLtsVer | sed \"s/\.//g\" );
if [ \$ltsVer -gt \$myVer ];
then
echo \"[INFO] Your PWR node version is : \${pwrVer}\"
echo \"[INFO] Latest PWR node version \${pwrLtsVer} found, Please rerun the installation script !\";
ltsFound=\$( echo -e \"Latest PWR node version \${pwrLtsVer} found !\nPlease rerun this script !\n<pre>wget https://raw.githubusercontent.com/mr9868/PWR-Validator/refs/heads/main/pwr.sh %26%26 chmod %2Bx pwr.sh %26%26 ./pwr.sh; sudo rm pwr.sh </pre>\n\" );
echo -e '[INFO] Sending telegram message ... ⏳';
echo -e '[INFO] Message output details : \n';
echo -e \"<=()=======================( BEGIN )=====================()=>\n\"
curl -s -X POST https://api.telegram.org/bot\${tgApiQn}/sendMessage -d chat_id=\${tgIdQn} -d text=\"\${ltsFound}\" -d parse_mode='HTML' | jq -r .result.text ;
echo;
echo -e \"<=()========================( END )======================()=>\n\"
echo -e '[INFO] Telegram message sent ! ✅';
else
echo \"[INFO] Your PWR node version is : \${pwrVer}\"
fi
}

function standBy(){
echo;
echo \"[ERROR] Your node can't create a block ! ❌\";
echo -e '[INFO] Sending telegram message ... ⏳';
echo -e '[INFO] Message output details : \n';
echo -e \"<=()=======================( BEGIN )=====================()=>\n\"
errFound=\$( echo -e \"Your node can't create a block ! ❌\nYour node status is Standby !\nPlease rerun this script !\n<pre>wget https://raw.githubusercontent.com/mr9868/PWR-Validator/refs/heads/main/pwr.sh %26%26 chmod %2Bx pwr.sh %26%26 ./pwr.sh; sudo rm pwr.sh </pre>\n\" );
curl -s -X POST https://api.telegram.org/bot\${tgApiQn}/sendMessage -d chat_id=\${tgIdQn} -d text=\"\${errFound}\" -d parse_mode='HTML' | jq -r .result.text
echo;
echo -e \"<=()========================( END )======================()=>\n\"
echo -e '[INFO] Telegram message sent ! ✅';
echo '[ERROR] Your node status is Standby, please restart your PWR node !';
echo 'Telegram bot server is Standby, sleep for 3 minutes ... ⏳';
echo;
sleep 180;
curl -s -X POST https://api.telegram.org/bot\${tgApiQn}/sendMessage -d chat_id=\${tgIdQn} -d text=\"\PWR telebot server is down\" -d parse_mode='HTML' | jq -r .result.text
exit 1;
}
while sleep 5;
do
showVer;
{ exStr=\$( curl \${urlCek}\${pwrAddr} | jq -r .validator ); } 2>/dev/null;
votePwr=\$( echo \$exStr | jq -r .votingPower );
addrPwr=\$( echo \$exStr | jq -r .address );
lastBT=\$( echo \$exStr | jq -r .lastCreatedBlockTime );
lastBT=\$(( \$lastBT / 1000 ));                                                                            
lastBT=\$( TZ='Asia/Jakarta'  date -d @\${lastBT} '+%Y-%m-%d %H:%M:%S');                                   
lastBT=\$( date -d \"\${lastBT}\" +%s);                                                                    
lastBTN=\$( TZ='Asia/Jakarta' date '+%Y-%m-%d %H:%M:%S');
lastBTN=\$( date -d \"\$lastBTN\" +%s);
diffBT=\$(( lastBTN - lastBT ));

diffBTH=\$((\$diffBT/3600));
if [[ \"\${diffBTH}\" -gt \"0\" ]];
then
diffBTH=\$( echo \$diffBTH ' hrs ');
else
diffBTH='';
fi

diffBTM=\$((\$diffBT %3600 / 60));

if [ \"\${diffBTM}\" -gt \"0\" ];
then
diffBTM=\$( echo \$diffBTM ' min ');
else
diffBTM='';
fi

diffBTS=\$((\$diffBT % 60));

if [ \"\${diffBTS}\" -gt \"0\" ];
then
diffBTS2=\$( echo \$diffBTS ' sec ');
else
diffBTS2='';
fi

diffBT=\$( echo  \${diffBTH}\${diffBTM}\${diffBTS2} 'ago');
ipVal=\$( echo \$exStr | jq -r .ip );
#delCount=\$( echo \$exStr | jq -r .delegatorsCount );
lastCB=\$( curl https://pwrexplorerv2.pwrlabs.io/blocksCreated/?validatorAddress=0xC20C4C42EB50D83739DD0ED2D3E49376758BE5EB\&page=1\&count=2 2>/dev/null | jq -r .blocks[1].blockHeight );
newCB=\$( curl https://pwrexplorerv2.pwrlabs.io/blocksCreated/?validatorAddress=0xC20C4C42EB50D83739DD0ED2D3E49376758BE5EB\&page=1\&count=2 2>/dev/null | jq -r .blocks[0].blockHeight );
#totalShr=\$( echo \$exStr | jq -r .totalShares );
status=\$( echo \$exStr | jq -r .status );

{ blockDetails=\$( curl \${urlBlockCek}\${newCB} | jq -r 'del(.block|.transactions)' | jq -r .block ); } 2>/dev/null;
blockHash=\$( echo \$blockDetails | jq -r .blockHash );
blockNumber=\$( echo \$blockDetails | jq -r .blockNumber );
blockSize=\$( echo \$blockDetails | jq -r .size );
blockNetVtPwr=\$( echo \$blockDetails | jq -r .networkVotingPower );
blockStatus=\$( echo \$blockDetails | jq -r .success );
blockTxCount=\$( echo \$blockDetails | jq -r .transactionCount);
blockReward=\$( echo \$blockDetails | jq -r .blockReward );
blockReward=\$( echo \"scale=7; 0.0001 * \${blockReward}*10^-5; scale=9\" | bc -l );
blockReward=\$( echo \${blockReward} | sed 's/\./0\\\\\\\\\./g' );
{ totalBlocks=\$( curl https://pwrexplorerv2.pwrlabs.io/blocksCreated/?validatorAddress=0xC20C4C42EB50D83739DD0ED2D3E49376758BE5EB\&page=1\&count=1 | jq -r .metadata.totalItems ); } 2>/dev/null;

if [ ! \$status == 'active' ];
then
standBy;
else
msgTg=\$( echo -e \" \
ℹ️ * Your PWR Validator Info * ℹ️ \n\n \
 🔸\${nodeVer} \n \
 🔸IP address: \\\`\${ipVal}\\\` \n \
 🔸Address: \\\`0x\${addrPwr}\\\` \n \
 🔸Last block number: \${lastCB} \n \
 🔸Status: \${status} \n \
 🔸Validator info: [Go to the Explorer](https://explorer\\.pwrlabs\\.io/address/0x\${addrPwr}) \n \
 🔸New block info: \n \
    🔹Block number: \${blockNumber} \n \
    🔹Block transaction count: \${blockTxCount} Tx\n \
    🔹Timestamp: \${diffBT} \n \
    🔹Block reward: \${blockReward} PWR \n \
    🔹Block Details: [Go to the Explorer](https://explorer\\.pwrlabs\\.io/blocks/\${lastCB}) \n \
 🔸Total blocks created: \${totalBlocks} \n\n \
Creator: [Mr9868 ☕](https://www\\.github\\.com/mr9868)\");

echo -e '[INFO] Sending telegram message ... ⏳';
echo -e '[INFO] Message output details : \n';
echo -e \"<=()=======================( BEGIN )=====================()=>\n\"
curl -s -X POST https://api.telegram.org/bot\${tgApiQn}/sendMessage -d chat_id=\${tgIdQn} -d text=\"\${msgTg}\" -d parse_mode='MarkdownV2' | jq -r .result.text ;
echo;
echo -e \"<=()========================( END )======================()=>\n\"
echo -e '[INFO] Telegram message sent ! ✅';

{ cekLastCB=\$( curl \$urlCek\$pwrAddr | jq -r .validator.lastCreatedBlock ); } 2>/dev/null;

until [ \$cekLastCB -gt \$newCB ];
do
{ cekStatus=\$( curl \$urlCek\$pwrAddr | jq -r .validator.status ); } 2>/dev/null;
if [ ! \$cekStatus == 'active' ];
then
standBy;
else
sleep 30;
echo \"[INFO] Last created block is: \${cekLastCB}. There is no new created block found ...\";
{ cekLastCB=\$( curl \$urlCek\$pwrAddr | jq -r .validator.lastCreatedBlock ); } 2>/dev/null;
fi
done
echo \"[INFO] Finished creating block ✅ \"
echo \"[INFO] Time taken to create block: \${diffBTS}ms \"
echo \"[INFO] Block created: \${cekLastCB} \"
echo \"[INFO] New created block found ! block: \${cekLastCB} ✅ \"
fi
done

" > ~/.mr9868/pwr/tgServer;

echo "
screen -X -S pwr quit;
screen -dmS pwr bash -c \"sudo java -jar validator.jar  ${myIP} --loop-udp-test \"; 
bash ~/.mr9868/pwr/tgInit;
" > ~/.mr9868/pwr/run_pwr;


echo '
pwrAddr=$( curl localhost:8085/address/ 2>/dev/null );
sed -r -i "s/pwrAddr=.*/pwrAddr=${pwrAddr}/g"  ~/.mr9868/pwr/config;
screen -X -S pwrBot quit;
screen -dmS pwrBot bash -c "chmod +x ~/.mr9868/pwr/tgServer && bash ~/.mr9868/pwr/tgServer";
echo "Starting screen ..."

echo "Success ✅"
' > ~/.mr9868/pwr/tgInit;
chmod 777 ~/.mr9868/pwr/tgInit && bash ~/.mr9868/pwr/tgInit;
}
# End of tgConf


# Check if teleBot question is valid
function tgQnCheck(){
read -p "Please provide your bot API Key from @botFather : " tgApiQn
until [ -n "${tgApiQn}" ];
do
myHeader
echo "Please input the API ! "
read -p "Please provide your bot API Key from @botFather : " tgApiQn
done
myHeader
echo "Please provide your bot API Key from @botFather : ${tgApiQn}"
read -p "Please provide your telegram ID's from @getidsbot : " tgIdQn
until [ -n "${tgIdQn}" ];
do
myHeader
echo "Please input chat id !"
echo "Please provide your bot API Key from @botFather : ${tgApiQn}"
read -p "Please provide your telegram ID's from @getidsbot : " tgIdQn
done
}
# End of tgQnCheck

# Entrypoint for telegram monitor question
function entryPointTg(){
if [[ "${tgQn}" =~ ^([yY][eE][sS]|[yY])$ ]];
then   
tgQnCheck
API_TOKEN=${tgApiQn}
CHAT_ID=${tgIdQn}
myHeader
msgTg=$(echo -e "<b>[ INFO ]</b> Authorized !\nPlease wait for up to 1 minute ... ")
tgTest=$(curl -s -X POST https://api.telegram.org/bot${API_TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="${msgTg}" -d parse_mode="HTML" | grep 'error_code') 
tgTest=$(echo ${tgTest})
until [ -z "${tgTest}" ];
do
myHeader
echo -e "[ ERROR ] Unauthorized !\nPlease recheck your API and CHAT ID and make sure you starting your bot"
tgQnCheck
tgTest=$(curl -s -X POST https://api.telegram.org/bot${API_TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="${msgTg}" -d parse_mode="HTML" | grep 'error_code')
tgTest=$(echo ${tgTest})
done
echo -e ${msgTg}

if [ ! -d ~/.mr9868 ];
then
mkdir ~/.mr9868
mkdir ~/.mr9868/pwr
fi
{ pwrAddr=$(curl localhost:8085/address/); } 2>/dev/null;
if { grep -wq "tgApiQn" ~/.mr9868/pwr/config; } 2>/dev/null ;
then    
sed -r -i "s/tgApiQn=.*/tgApiQn=${tgApiQn}/g" ~/.mr9868/pwr/config;
sed -r -i "s/tgIdQn=.*/tgIdQn=${tgIdQn}/g" ~/.mr9868/pwr/config;
sed -r -i "s/pwrAddr=.*/pwrAddr=${pwrAddr}/g"  ~/.mr9868/pwr/config
else         
echo "tgApiQn=${tgApiQn}" > ~/.mr9868/pwr/config
echo "tgIdQn=${tgIdQn}" >> ~/.mr9868/pwr/config
echo "pwrAddr=${pwrAddr}" >> ~/.mr9868/pwr/config
fi

tgConf;
echo "Telegram bot monitor configured ✅";
echo "Telegram bot monitor is running ✅";
else
if [ $tgConfigured == "Yes" ]; then
echo "Telegram bot monitor is running ✅";
else
echo "Running without telegram bot monitor ..."
fi
fi
}
# end of entryPointTg function

# Check if teleBot variable is exist in config file
function varCheck(){
if { grep -wq "tgApiQn" ~/.mr9868/pwr/config && grep -wq "tgIdQn" ~/.mr9868/pwr/config; } 2>/dev/null;
then
tgConfigured="Yes";
read -p "Config file found, Do you want to reconfigure it ? (y/n) : " tgQn
if [[ "${tgQn}" =~ ^([yY][eE][sS]|[yY])$ ]];
then   
myHeader;
entryPointTg;
tgConf;
echo "Telegram bot reconfigured !";
else
myHeader
tgConf;
echo "Telegram bot updated !";
fi
else
myHeader;
read -p "Do you want to add telegram monitor ? (y/n)  : " tgQn
entryPointTg;
fi
}
# End of varCheck


# Main installation
function mainInstall(){

myHeader;
# Check if java is found
function java_found(){
read -p "Java already installed, do you want to reinstall them ? (y/n): " qJava
if [[ "${qJava}" =~ ^([yY][eE][sS]|[yY])$ ]];
then
install_java;
fi
}
# end of java_found function

# java entryPoint
if command -v java 2>&1 >/dev/null
then
java_found;
else
install_java;
fi

# Check if the directories is exist
if [ -d blocks ] && [ -d rocksdb ];
then

myHeader;
echo -e "If you remove blocks and rocksdb, the node will resync from the stratch! \n";
read -p "Do you want to remove blocks and rocksdb directories ? (y/n): " hapus
if [[ "${hapus}" =~ ^([yY][eE][sS]|[yY])$ ]];
then
sudo rm -rf rocksdb blocks;
fi

fi
myHeader;
install_pwr;


# Accept all Drop rules
myHeader;
kill_apps;
unblockIPs;
sed -i "s/\"synchronizationIntervals\": 100,/\"synchronizationIntervals\": 10,/g" config.json;


# run PWR
myHeader;
echo -e "You're currently using $( java --version) \n"

echo -e "Running PWR node ... ⌛ \n"
sudo ufw allow 8085;
sudo ufw allow 8085/tcp
sudo ufw allow 8231
sudo ufw allow 8231/tcp;
sudo ufw allow 7621
sudo ufw allow 7621/udp;
if [ ! -d logs ];
then
mkdir logs;
fi
screen -L -Logfile logs/pwr.log -dmS pwr bash -c "sudo java -jar validator.jar  $myIP --loop-udp-test --enable-native-access=ALL-UNNAMED" && 
echo "Please wait ... "
sleep 10;
checkPwr;
varCheck;

}
# End of Main install;
function dockerInstall(){
myConHead='function myHeader(){ \\ \n
clear; \\ \n
echo  "<=()=====================================================()=>" \\ \n
echo  "=             PWR validator setup auto installer           =" \\ \n
echo  "=                    Created by : Mr9868                   =" \\ \n
echo  "=             Github : https://github.io/Mr9868            =" \\ \n
echo  "============================================================" \\ \n
echo  "=                Your OS info : $(uname -s) $(uname -m)               =" \\ \n
echo  "=                 IP Address : '${myIP}'               =" \\ \n
echo  "<=()=====================================================()=>" \\ \n
echo  "              DONT INTERUPT THE INSTALLING PROCESS !" \\ \n
echo  "                    PRESS CTRL+P+Q TO QUIT" \\ \n
echo \\ \n
}\n'
cmdInstall=$( echo -e "${myConHead}myHeader; rm -rf pwr.sh* ; echo 'Installing dependencies ...' ;apt update -y && apt upgrade -y && apt install -y sudo curl wget && wget https://raw.githubusercontent.com/mr9868/PWR-Validator/refs/heads/main/pwr.sh && chmod +x pwr.sh && myHeader; ./pwr.sh; sudo rm pwr.sh;myHeader; echo \"To exit the container press CTRL+P+Q\"" );

function docCmd(){
myHeader;
sudo docker exec -ti pwrNode bash -c "${cmdInstall}"
}

function chkDocWallet(){
if [ -f wallet ]; then
read -p "Wallet file found !. Do you want to use it ? (y/n) : " qDocWallet
if [[ "${qDocWallet}" =~ ^([yY][eE][sS]|[yY])$ ]];
then
sudo docker cp wallet pwrNode:/;
echo "Copying your wallet file ..."
echo "Your wallet imported !"
echo "Please wait ..."
sleep 3;
else
echo "Please wait ..."
sleep 3;
echo "You are using new wallet"
fi
else
echo "Make sure you running this script as same directory with your PWR wallet..."
echo "You are using new wallet"
echo "Please wait ..."
sleep 5;
fi
}

function mainDocInstall(){
myHeader;
read -p "Set the docker port eg. 8080 : " pwrPort
cekPort=$( eval "sudo lsof -Pi :${pwrPort} -sTCP:LISTEN -t")
until [[ ${pwrPort} =~ ^[0-9]{4}$ ]]
do
myHeader;
echo "Please input in 4 digits number !"
read -p "Set the docker port eg. 8080 : " pwrPort
${cekPort}
done
until [[ -z "$cekPort" ]]
do
myHeader;
echo "Port ${pwrPort} is already in use !"
read -p "Set the docker port eg. 8080 : " pwrPort
${cekPort}
done
myHeader;
echo "Installing docker container"
sudo docker run -it -d -p ${pwrPort}:${pwrPort} -v /sys:/sys --privileged --name pwrNode ubuntu:22.04;
chkDocWallet;
docCmd;
}

# If container exist
dockerCheck=$( sudo docker ps -a | grep "pwrNode" );
if [ -n "$dockerCheck" ]; 
then
read -p "There is pwrNode container found, do you want to remove first ? (y/n): " qDocInstall
if [[ "${qDocInstall}" =~ ^([yY][eE][sS]|[yY])$ ]];
then
sudo docker stop pwrNode && sudo docker rm pwrNode && mainDocInstall
else
# If container stopped
ifExtCont=$( sudo docker ps -f status=exited -f name=pwrNode );
if [ -n "${ifExtCont}" ];
then
sudo docker start pwrNode && docCmd;
fi
fi
else
mainDocInstall
fi

}

# Main menu
function main_Menu(){

function yourSelect(){
myHeader;
echo;
echo -e "<=======================( Main Menu )======================>\n"
echo "1. Full Installation"
echo "2. Full Installation with docker"
echo "3. Setup or Re-configure TeleBot Monitor"
echo "4. Exit"
echo;
}
yourSelect;
read -p "Your selection => " mainMenu
until [[ "${mainMenu}" =~ ^[1-4]+$ ]];
do
yourSelect;
read -p "Your selection => " mainMenu
done
if [[ $mainMenu == "1" ]];
then
mainInstall;
elif [[ $mainMenu == "2" ]];
then
myHeader;
if [ -f /.dockerenv ]; then
    echo -e "You're inside the Matrix ! \nYou can'to do this inside the container ;(";
else
    command -v docker >/dev/null 2>&1 || { echo >&2 "docker is not found on this machine, Installing docker ... "; sudo apt update -y && sudo apt install -y docker.io docker;}
    dockerInstall;
fi
elif [[ $mainMenu == "3" ]];
then
checkPwr;
varCheck;
else
myHeader;
echo "Bye bye !";
if [ -f pwr.sh ];
then
sudo rm -rf pwr.sh 2>/dev/null;
fi
exit 1;
fi
}
# End of mainMenu
main_Menu;

if [ -f /.dockerenv ]; then
    exit;
    echo -e "PWR node running successfully ✅ \n"
    echo -e "To view your PWR logs, exec => docker exec -ti pwrNode bash -c 'screen -r pwr' \n";
else
    echo -e "PWR node running successfully ✅ \n"
    echo -e "To view your PWR logs, exec 'screen -r pwr' \n"
fi

