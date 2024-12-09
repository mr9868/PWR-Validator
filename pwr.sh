myIP=$(curl -w "\n" ifconfig.me);
arch=$(uname -m);
if [ $arch == " x86_64" ];
then
arch=x64;
fi
javaList=(https://download.oracle.com/java/23/latest/jdk-23_linux-${arch}_bin.tar.gz https://download.java.net/java/early_access/jdk24/27/GPL/openjdk-24-ea+27_linux-${arch}_bin.tar.gz );
jdkList=(jdk-23.0.1 jdk-24);
set | grep ^javaList=
set | grep ^jdkList=


function myHeader(){
clear;
echo -e "============================================================\n"
echo -e "=              EWM light-client auto installer             =\n"
echo -e "=                    Created by : Mr9868                   =\n"
echo -e "=             Github : https://github.io/Mr9868            =\n"
echo -e "============================================================\n"
}


function install_java(){
dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' -e '^java-common' | xargs sudo apt-get -y remove;
sudo apt-get -y autoremove;

sudo bash -c 'ls -d /home/*/.java' | xargs sudo rm -rf &&
sudo rm -rf /usr/lib/jvm/* &&
sudo rm -rf /usr/local/java &&
sudo apt purge -y java-common &&
sudo update-alternatives --remove-all java;

function jdkLts(){
apt install -y java-common &&
wget -O javalts.tar.gz ${javaVer} &&
sudo mkdir /usr/local/java &&
sudo mv javalts.tar.gz /usr/local/java &&
cd /usr/local/java &&
sudo tar zxvf javalts.tar.gz &&
sudo rm -rf javalts.tar.gz &&
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/${jdkVer}/bin/java" 1 &&
cd -;
}

function listJdk(){
apt update-y  && apt upgrade -y &&
apt install -y openjdk-${jdkVer}-jdk &&
apt install -y openjdk-${jdkVer}-jre &&
apt install -y java-common;
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

# end install_java function
}

pJava=("Java already installed, do you want to reinstall them ?" "Java doesn't installed, Do you want to install ?")
function java_found(){
read -p "${qnJava} (y/n): " qJava
if [[ $qJava == "y" ]];
then
install_java;
fi
}
if command -v java 2>&1 >/dev/null
then
qnJava=${pJava[0]};
java_found;
else
qnJava=${pJava[1]};
java_found;
fi

read -p "Do you want to remove blocks and rocksdb directories ? (y/n): " hapus
if [[ $hapus == "y" ]];
then
rm -rf rocksdb blocks;
fi

read -p "Do you want to redowload validator config ? (y/n): " download
if [[ $download == "y" ]];
then
sudo rm -rf validator.jar config.json  &&
wget https://github.com/pwrlabs/PWR-Validator/releases/latest/download/validator.jar &&
wget https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json
fi

# run PWR
myHeader;
echo -e "You're currently using $(java --version) \n"
echo -e "Running PWR node ... \n"
sleep 2;
sudo java -jar validator.jar password $myIP;

