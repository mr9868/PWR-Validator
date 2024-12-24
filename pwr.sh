# Set variables and array URL JDK latest
myIP=$(curl -w "\n" ifconfig.me);
arch=$(uname -m);
if [ $arch == "x86_64" ];
then
arch=x64;
fi
javaList=(https://download.oracle.com/java/23/latest/jdk-23_linux-${arch}_bin.tar.gz https://download.java.net/java/early_access/jdk24/27/GPL/openjdk-24-ea+27_linux-${arch}_bin.tar.gz);
jdkList=(jdk-23.0.1 jdk-24);
set | grep ^javaList=
set | grep ^jdkList=

function kill_apps(){
screen -X -S pwr quit;
pkill -f "java";
pkill -9 java;
pkill java;
screen -X -S tgServer quit;
echo "Kill previous session ..."
sleep 5;
}


# Required package
command -v screen >/dev/null 2>&1 || { echo >&2 "Screen is not found on this machine, Installing screen ... "; sleep 5;sudo apt install -y screen;}
command -v wget >/dev/null 2>&1 || { echo >&2 "Wget is not found on this machine, Installing wget ... "; sleep 5;sudo apt install -y wget;}
command -v tar >/dev/null 2>&1 || { echo >&2 "Tar is not found on this machine, Installing tar ... "; sleep 5;sudo apt install -y tar;}
command -v iptables >/dev/null 2>&1 || { echo >&2 "Iptables is not found on this machine, Installing iptables ... "; sleep 5;sudo apt install -y iptables;}
command -v ufw >/dev/null 2>&1 || { echo >&2 "Ufw is not found on this machine, Installing ufw ... "; sleep 5;sudo apt install -y ufw;}
command -v jq >/dev/null 2>&1 || { echo >&2 "JQ is not found on this machine, Installing jq ... "; sleep 5;sudo apt install -y jq;}


# My Header
function myHeader(){
clear;
echo  "============================================================"
echo  "=             PWR validator setup auto installer           ="
echo  "=                    Created by : Mr9868                   ="
echo  "=             Github : https://github.io/Mr9868            ="
echo  "=                 Your OS info : $(uname -s) $(uname -m)              ="
echo  "=                 IP Address : ${myIP}               ="
echo -e "============================================================\n"
}

function checkIfExist(){
if [[ -f password ]];
then
echo -e "Please wait, chacking if PWR wallet is exist ... ⌛";
sleep 5;
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
sudo java -jar validator.jar --import-key ${pwrPK} password
checkWallet;
echo -e "Next step ... ⌛ \n"
sleep 5;

else
myHeader;
echo -e "Wallet found ✅ \n"
echo -e "Wallet found ✅" > pwrWallet;
echo -e "Next step ... ⌛ \n"
sleep 5;
fi
# End of if checkWallet


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
checkWallet;
echo -e "Next step ... ⌛ \n"
sleep 5;
fi
}
# end of checkIfExist function

function checkWallet(){
if [[ -f pwrWallet ]];
then
echo -e "Wallet found, next step ... ⌛";
sleep 2;
else
checkIfExist;
fi
}

# Unblock IPs and domain that blocked by pwr node
function unblockIPs(){
if [ -f listDrops.sh ];
then
chmod  +x listDrops.sh && ./listDrops.sh;
echo -e "Unblocked IPs successfully ✅ \n";
else
echo -e "Unblock IPs from previous PWR node ... ⌛ \n";
#listDrops=$(iptables -S | grep DROP | sed "s/DROP/ACCEPT #/g");
#echo $listDrops | sed 's/#/\&\& \n/g' | sed 's/-A/iptables -A /g' > listDrops.sh;
#echo "echo 'Success ✅'" >> listDrops.sh;
#chmod  +x listDrops.sh && ./listDrops.sh;

listDrops=$(iptables -S | grep DROP | sed "s/DROP/DROP #/g");
echo $listDrops | sed 's/#/\&\& \n/g' | sed 's/-A/iptables -D /g' > listDrops.sh;
echo "echo 'Success ✅'" >> listDrops.sh;
chmod  +x listDrops.sh && ./listDrops.sh;
echo -e "Unblocked IPs successfully ✅ \n"
fi
}


# Install java function
function install_java(){
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

myHeader;
function java_found(){
read -p "Java already installed, do you want to reinstall them ? (y/n): " qJava
if [[ $qJava == "y" ]];
then
install_java;
fi
}
# end of java_found function


function tgConf(){
echo "
. ~/.mr9868/pwr/config
urlCek=https://pwrrpc.pwrlabs.io//validator/?validatorAddress=
while sleep 2;
do
{ exStr=\$( curl \${urlCek}\${pwrAddr} | jq -r .validator ); } 2>/dev/null;

votePwr=\$( echo \$exStr | jq -r .votingPower );
addrPwr=\$( echo \$exStr | jq -r .address );
lastBT=\$( echo \$exStr | jq -r .lastCreatedBlockTime );
lastBT=\$(( \$lastBT / 1000 ));
lastBTO=\$( TZ='Asia/Jakarta'  date -d @\${lastBT});
lastBTR=\$( echo \$lastBTO | awk '{print \$4}');
lastBTRN=\$( TZ='Asia/Jakarta' date -R | awk '{print \$5}');
lastBTM=\$( echo \$lastBTR | awk -F : '{print \$2 * 60}');
lastBTS=\$( echo \$lastBTR | awk -F : '{print \$3}');
lastBTS=\$( echo \$lastBTS | sed 's/^0*//');
lastBTMN=\$( echo \$lastBTRN | awk -F : '{print \$2 *  60}');
lastBTSN=\$( echo \$lastBTRN | awk -F : '{print \$3}');
lastBTSN=\$( echo \$lastBTSN | sed 's/^0*//');

if [ -z \$lastBTSN ]; 
then 
lastBTSN=0;
fi
if [ -z \$lastBTS ]; 
then 
lastBTS=0;
fi

lastBT=\$(( ( (( \$lastBTMN + \$lastBTSN ) - ( \$lastBTM + \$lastBTS )) / 60 ) ));

if [ \$lastBT -eq 0 ];
then
lastBTq=\"Just Now\";
else
lastBTq=\$( echo \$lastBT \"Minutes ago\" );
fi
ipVal=\$( echo \$exStr | jq -r .ip );
delCount=\$( echo \$exStr | jq -r .delegatorsCount );
lastCB=\$( echo \$exStr | jq -r .lastCreatedBlock );
totalShr=\$( echo \$exStr | jq -r .totalShares );
status=\$( echo \$exStr | jq -r .status );

msgTg=\$( echo -e \"ℹ️ * Your PWR Validator Info * ℹ️ \n\n 🔸Voting Power: \${votePwr} \n 🔸Address: \\\`0x\${addrPwr}\\\` \n 🔸Last Created Block Time : \${lastBTq}  \n 🔸IP Address: \\\`\${ipVal}\\\` \n 🔸Delegators Count: \${delCount} \n 🔸Last Created Block: \${lastCB} \n 🔸Status: \${status} \n 🔸Details: [Go to The Explorer](https://explorer\\.pwrlabs\\.io/address/0x\${addrPwr}) \n\nCreator: [Mr9868 ☕](https://www\\.github\\.com/mr9868)\")
echo -e '[INFO] Sending telegram message ...';
echo -e '[INFO] Message output details : \n';
curl -s -X POST https://api.telegram.org/bot\${tgApiQn}/sendMessage -d chat_id=\${tgIdQn} -d text=\"\${msgTg}\" -d parse_mode='MarkdownV2';
echo;
echo -e '\n[INFO] Telegram message sent ! ✅';

{ cekLastCB=\$( curl \$urlCek\$pwrAddr | jq -r .validator.lastCreatedBlock ); } 2>/dev/null;

until [ \$cekLastCB -gt \$lastCB ];
do
echo \"[INFO] Last created block is: \${cekLastCB}. There is no new created block found ...\";
sleep 30;
{ cekLastCB=\$( curl \$urlCek\$pwrAddr | jq -r .validator.lastCreatedBlock ); } 2>/dev/null;
{ cekStatus=\$( curl \$urlCek\$pwrAddr | jq -r .validator.status ); } 2>/dev/null;
if [ ! \$cekStatus == 'active' ];
then
echo '[ERROR] Your node is Standby, please restart your PWR node !';
{ curl -s -X POST https://api.telegram.org/bot\${tgApiQn}/sendMessage -d chat_id=\${tgIdQn} -d text=\"[ERROR] Your node is Standby, please restart your PWR node !\" -d parse_mode='MarkdownV2' } 2>/dev/null;
echo 'Telegram server bot is Standby, sleep for 3 minutes ...'
sleep 180;
fi
done

echo \"[INFO] New created block found ! block: \${cekLastCB} ✅ \"
done

" > ~/.mr9868/pwr/tgServer;
echo '
screen -dmS tgServer bash -c "chmod +x ~/.mr9868/pwr/tgServer && bash ~/.mr9868/pwr/tgServer";
echo "Starting screen ..."
sleep 5;
echo "Success ✅"
' > ~/.mr9868/pwr/tgInit;
chmod 777 ~/.mr9868/pwr/tgInit && bash ~/.mr9868/pwr/tgInit;

}



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

# Entrypoint for telegram monitor question
function entryPointTg(){
myHeader
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
pwrAddr=$(curl localhost:8085/address/);
if grep -wq "tgApiQn" ~/.mr9868/pwr/config; 
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

function varCheck(){
if grep -wq "tgApiQn" ~/.mr9868/pwr/config && grep -wq "tgIdQn" ~/.mr9868/pwr/config;
then
echo "Config file found ! Next ...";
tgConf;
sleep 2;
echo "Telegram already configured ✅";
sleep 2;
else
entryPointTg;
fi
}

if command -v java 2>&1 >/dev/null
then
java_found;
else
install_java;
fi


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


if [ -f validator.jar ] && [ -f config.json ];
then

myHeader;
echo -e "You must redownload validator config when upgrading PWR node version ! \n";
read -p "Do you want to redowload validator config ? (y/n): " download
if [[ $download == "y" ]];
then
sudo rm -rf validator.jar config.json  &&
wget https://github.com/pwrlabs/PWR-Validator/releases/latest/download/validator.jar &&
wget https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json
fi

fi



# Accept all Drop rules
myHeader;
kill_apps;
unblockIPs;
sleep 2;

# run PWR
myHeader;
echo -e "You're currently using $(java --version) \n"
sleep 2;
checkWallet &&
myHeader;
echo -e "Running PWR node ... ⌛ \n"
sudo ufw allow 8085;
sudo ufw allow 8085/tcp
sudo ufw allow 8231
sudo ufw allow 8231/tcp;
sudo ufw allow 7621
sudo ufw allow 7621/udp;
screen -dmS pwr bash -c "sudo java -jar validator.jar password $myIP" && sleep 5;
sleep 2;
varCheck;
sleep 5;
echo -e "PWR node running successfully ✅ \n"
echo -e "To view your PWR logs, exec 'screen -r pwr' \n"


