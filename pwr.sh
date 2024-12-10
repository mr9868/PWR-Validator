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

# Required package
command -v screen >/dev/null 2>&1 || { echo >&2 "Screen is not found on this machine, Installing screen ... "; sleep 5;sudo apt install -y screen;}
command -v wget >/dev/null 2>&1 || { echo >&2 "Wget is not found on this machine, Installing wget ... "; sleep 5;sudo apt install -y wget;}
command -v tar >/dev/null 2>&1 || { echo >&2 "Tar is not found on this machine, Installing tar ... "; sleep 5;sudo apt install -y tar;}
command -v iptables >/dev/null 2>&1 || { echo >&2 "Iptables is not found on this machine, Installing iptables ... "; sleep 5;sudo apt install -y iptables;}
command -v ufw >/dev/null 2>&1 || { echo >&2 "Ufw is not found on this machine, Installing ufw ... "; sleep 5;sudo apt install -y ufw;}


# My Header
function myHeader(){
clear;
echo -e "============================================================\n"
echo -e "=             PWR validator setup auto installer           =\n"
echo -e "=                    Created by : Mr9868                   =\n"
echo -e "=             Github : https://github.io/Mr9868            =\n"
echo -e "=               Your OS info : $(uname -s) $(uname -m)              =\n"
echo -e "=                 IP Address : ${myIP}               =\n"
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
checkWallet;
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
myHeader;
echo -e "Unblock IPs from previous PWR node ... ⌛ \n";
daftarIP=$(sudo iptables -L | grep DROP | awk '$4!="anywhere"{print $4}' |  grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b');
#daftarDm=$(sudo iptables -L | grep DROP | grep -oiE '([a-zA-Z0-9][a-zA-Z0-9-]{1,61}\.){1,}(\.?[a-zA-Z]{2,}){1,}');
list="listAddr=($daftarIP)";
echo $list > listAddr.txt
. listAddr.txt
for i in $(seq 0 ${#listAddr[@]});
do
set | grep ^listAddr= > listAddr.txt;
sudo iptables -I INPUT -s ${listAddr[i]} -j ACCEPT;
sudo iptables -D INPUT -s ${listAddr[i]} -j DROP;
echo "Successful unblock address : ${listAddr[i]} ✅";
done
myHeader;
echo -e "Unblocked IPs successfully ✅ \n"
}
unblockIPs;

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

# run PWR
myHeader;
echo -e "You're currently using $(java --version) \n"
checkWallet &&
myHeader;
echo -e "Running PWR node ... ⌛ \n"
screen -X -S pwr quit;
sudo ufw allow 8085;
sudo ufw allow 8231/tcp;
sudo ufw allow 7621/udp;
sleep 2;
screen -dmS pwr bash -c "sudo java -jar validator.jar password $myIP;exec bash";
myHeader;
echo -e "PWR node running successfully ✅ \n"
echo -e "To view your PWR logs, exec 'screen -r pwr' \n"


