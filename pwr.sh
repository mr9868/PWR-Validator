# Set variables and array URL JDK latest
myIP=$( curl -w "\n" ifconfig.me 2>/dev/null );
arch=$(uname -m);
if [ $arch == "x86_64" ];
then
arch=x64;
fi

if [ -f validator.jar ];
then
valDir=$( pwd );
fi



# Required package
command -v screen >/dev/null 2>&1 || { echo >&2 "Screen is not found on this machine, Installing screen ... "; sudo apt install -y screen;}
command -v wget >/dev/null 2>&1 || { echo >&2 "Wget is not found on this machine, Installing wget ... "; sudo apt install -y wget;}
command -v tar >/dev/null 2>&1 || { echo >&2 "Tar is not found on this machine, Installing tar ... "; sudo apt install -y tar;}
command -v iptables >/dev/null 2>&1 || { echo >&2 "Iptables is not found on this machine, Installing iptables ... "; sudo apt install -y iptables;}
command -v ufw >/dev/null 2>&1 || { echo >&2 "Ufw is not found on this machine, Installing ufw ... "; sudo apt install -y ufw;}
command -v jq >/dev/null 2>&1 || { echo >&2 "JQ is not found on this machine, Installing jq ... "; sudo apt install -y jq;}


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
pwrVer=$( sudo java -jar validator.jar password 2>/dev/null | grep version | awk '{print $3}' ) ;
pwrLtsVer=$( curl https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest 2>/dev/null | jq -r .html_url | sed "s/.*tag\///g" );
myVer=$( echo $pwrVer | sed "s/\.//g" );
ltsVer=$( echo $pwrLtsVer | sed "s/\.//g" );
if [ -n "$pwrVer" ];
then
if [ $ltsVer -gt $myVer ];
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
echo  "<=()====================================================()=>"
echo  "=             PWR validator setup auto installer           ="
echo  "=                    Created by : Mr9868                   ="
echo  "=             Github : https://github.io/Mr9868            ="
echo  "============================================================"
echo  "=                Your OS info : $(uname -s) $(uname -m)               ="
echo  "=                 IP Address : ${myIP}               ="
echo  "<=()====================================================()=>"
echo;
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
if [[ $download == "y" ]];
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
if [ -z $pwrAddr ];
then
echo "[ERROR] There is an error on your PWR node !"
read -p "Do you want to run full installation ? (y/n) => " errQn
if [ $errQn == "y" ]; 
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
screen -X -S tgServer quit;
echo "Kill previous session ..."

}
# End of kill_apps


# Check if PWR wallet password is exist
function checkIfExist(){
if [[ -f password ]];
then
echo -e "Please wait, chacking if PWR wallet is exist ... ⌛";

checkWallet=$(sudo java -jar validator.jar get-private-key password | grep Private | awk '{print $3}');
if [[ -z $checkWallet ]];
then
myHeader;
echo -e "Wallet not found, please generate PWR wallet first !";
read -p "Input your PWR Wallet Private Key without 0x => " pwrPK
until [[ "${pwrPK}" =~ ^[0-9a-fA-F]{64}$ ]];
do
myHeader;
echo -e "Please submit a valid private key !";
read -p "Input your PWR Wallet Private Key without 0x => " pwrPK
done
sudo java -jar validator.jar --import-key ${pwrPK} password;
echo -e "Wallet added ✅ \n"
echo -e "Wallet added ✅" > pwrWallet;
echo -e "Next step ... ⌛ \n"

echo -e "Next step ... ⌛ \n"


else
myHeader;
echo -e "Wallet found ✅ \n"
echo -e "Wallet added ✅" > pwrWallet;
echo -e "Next step ... ⌛ \n"

fi
# End of if check password file


else
echo -e "Password file not found, You must create password File ! \n"
read -p "Input your password => " pwrPass
until [[ -n $pwrPass ]]
do
echo -e "Password file cannot be NULL ! \n"
read -p "Input your password => " pwrPass
done
echo $pwrPass > password;
myHeader;
echo -e "Wallet not found, please generate PWR wallet first !";
read -p "Input your PWR Wallet Private Key without 0x => " pwrPK
until [[ "${pwrPK}" =~ ^[0-9a-fA-F]{64}$ ]];
do
myHeader;
echo -e "Please submit a valid private key !";
read -p "Input your PWR Wallet Private Key without 0x => " pwrPK
done
sudo java -jar validator.jar --import-key ${pwrPK} password
echo -e "Wallet found ✅ \n"
echo -e "Wallet added ✅" > pwrWallet;
echo -e "Next step ... ⌛ \n"

fi
}
# End of checkIfExist function


# Check if PWR wallet is exist
function checkPwrWallet(){
if [[ -f pwrWallet ]];
then
echo -e "Wallet found, next step ... ⌛";

else
checkIfExist;
fi
}
# End of checkWallet

# Unblock IPs and domain that blocked by pwr node
function unblockIPs(){
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

javaList=(https://download.oracle.com/java/23/latest/jdk-23_linux-${arch}_bin.tar.gz https://download.java.net/java/early_access/jdk24/27/GPL/openjdk-24-ea+27_linux-${arch}_bin.tar.gz);
jdkList=(jdk-23.0.1 jdk-24);
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
cd -;
}

# List JDK version provided by default apt list
function listJdk(){
sudo apt update -y  && sudo apt upgrade -y &&
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


if [[ $cJava == "1" ]];
then
jdkVer=17;
listJdk;
elif [[ $cJava == "2" ]];
then
jdkVer=18;
listJdk;
elif [[ $cJava == "3" ]];
then
jdkVer=19;
listJdk;
elif [[ $cJava == "4" ]];
then
jdkVer=21;
listJdk;
elif [[ $cJava == "5" ]];
then
javaVer=${javaList[0]};
jdkVer=${jdkList[0]};
jdkLts;
elif [[ $cJava == "6" ]];
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
screen -X -S tgServer quit;
echo "
valDir=\"${valDir}\";
. ~/.mr9868/pwr/config
urlCek=https://pwrrpc.pwrlabs.io//validator/?validatorAddress=

function showVer(){
pwrVer=\$( cd \$valDir; sudo java -jar validator.jar password 2>/dev/null | grep version | awk '{print \$3}' ) ;
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
delCount=\$( echo \$exStr | jq -r .delegatorsCount );
lastCB=\$( echo \$exStr | jq -r .lastCreatedBlock );
totalShr=\$( echo \$exStr | jq -r .totalShares );
status=\$( echo \$exStr | jq -r .status );

if [ ! \$status == 'active' ];
then
standBy;
else

msgTg=\$( echo -e \"ℹ️ * Your PWR Validator Info * ℹ️ \n\n 🔸Voting Power: \${votePwr} \n 🔸Address: \\\`0x\${addrPwr}\\\` \n 🔸Last Created Block Time: \${diffBT}  \n 🔸IP Address: \\\`\${ipVal}\\\` \n 🔸Delegators Count: \${delCount} \n 🔸Last Created Block: \${lastCB} \n 🔸Status: \${status} \n 🔸Details: [Go to The Explorer](https://explorer\\.pwrlabs\\.io/address/0x\${addrPwr}) \n\nCreator: [Mr9868 ☕](https://www\\.github\\.com/mr9868)\")
echo -e '[INFO] Sending telegram message ... ⏳';
echo -e '[INFO] Message output details : \n';
echo -e \"<=()=======================( BEGIN )=====================()=>\n\"
curl -s -X POST https://api.telegram.org/bot\${tgApiQn}/sendMessage -d chat_id=\${tgIdQn} -d text=\"\${msgTg}\" -d parse_mode='MarkdownV2' | jq -r .result.text ;
echo;
echo -e \"<=()========================( END )======================()=>\n\"
echo -e '[INFO] Telegram message sent ! ✅';

{ cekLastCB=\$( curl \$urlCek\$pwrAddr | jq -r .validator.lastCreatedBlock ); } 2>/dev/null;

until [ \$cekLastCB -gt \$lastCB ];
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
screen -dmS pwr bash -c \"sudo java -jar validator.jar password ${myIP}\"; 
bash ~/.mr9868/pwr/tgInit;
" > ~/.mr9868/pwr/run_pwr;


echo '
screen -X -S tgServer quit;
screen -dmS tgServer bash -c "chmod +x ~/.mr9868/pwr/tgServer && bash ~/.mr9868/pwr/tgServer";
echo "Starting screen ..."

echo "Success ✅"
' > ~/.mr9868/pwr/tgInit;
chmod 777 ~/.mr9868/pwr/tgInit && bash ~/.mr9868/pwr/tgInit;

if [ -f pwr.sh ];
then
sudo rm -rf pwr.sh 2>/dev/null;
fi
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
read -p "Do you want to add telegram monitor ? (y/n)  : " tgQn
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
API_TOKEN=${tgApiQn}
CHAT_ID=${tgIdQn}
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
else
echo "See yaa ..."
fi
}
# end of entryPointTg function

# Check if teleBot variable is exist in config file
function varCheck(){
if { grep -wq "tgApiQn" ~/.mr9868/pwr/config && grep -wq "tgIdQn" ~/.mr9868/pwr/config; } 2>/dev/null;
then
echo "Config file found ! Next ...";
tgConf;
echo "Telegram already configured ✅";

else
myHeader;
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
if [[ $qJava == "y" ]];
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
if [[ $hapus == "y" ]];
then
sudo rm -rf rocksdb blocks;
fi

fi

# Check if the file is exist
if [ -f validator.jar ] && [ -f config.json ];
then

myHeader;
checkVersion;

fi



# Accept all Drop rules
myHeader;
kill_apps;
unblockIPs;


# run PWR
myHeader;
echo -e "You're currently using $(java --version) \n"

checkPwrWallet &&
myHeader;
echo -e "Running PWR node ... ⌛ \n"
sudo ufw allow 8085;
sudo ufw allow 8085/tcp
sudo ufw allow 8231
sudo ufw allow 8231/tcp;
sudo ufw allow 7621
sudo ufw allow 7621/udp;
screen -dmS pwr bash -c "sudo java -jar validator.jar password $myIP" && 
echo "Please wait ... "
sleep 10;
checkPwr;
varCheck;

echo -e "PWR node running successfully ✅ \n"
echo -e "To view your PWR logs, exec 'screen -r pwr' \n"

}
# End of Main install;

# Main menu
function main_Menu(){
myHeader;
showVer;
echo;
echo -e "<=======================( Main Menu )======================>\n"
echo "1. Full Installation"
echo "2. Setup or Re-configure TeleBot Monitor"
echo "3. Exit"
echo;
read -p "Your selection => " mainMenu
until [[ "${mainMenu}" =~ ^[1-3]+$ ]];
do
myHeader;
echo -e "=( Main Menu )=\n"
echo "1. Full Installation"
echo "2. Setup or Re-configure TeleBot Monitor"
echo "3. Exit"
echo;
read -p "Your selection => " mainMenu
done
if [[ $mainMenu == "1" ]];
then
mainInstall;
elif [[ $mainMenu == "2" ]];
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

