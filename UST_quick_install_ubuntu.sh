#!/usr/bin/env bash

# sudo sh -c 'apt-get update &> /dev/null; apt-get install curl openssl libssl-dev -y &> /dev/null;'

# sudo sh -c 'curl -s -L https://git.io/vxnQZ > ins.sh; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'
# sudo sh -c 'wget -O ins.sh https://git.io/vxnQZ &> /dev/null; chmod 777 ins.sh; ./ins.sh -wget; rm ins.sh;'


pyversion=3
instpy=true

while [[ $# -gt 0 ]]
do
key=$1
case $key in
    -py|--python)
        if [ $2 == "2" ]; then
            pyversion=2
        elif [ $2 == "none" ]; then
            instpy=false
        fi
    shift # past argument
    shift # past value
    ;;
    -wget)
        useWget=true
    shift # past argument
    ;;
    *)
    echo "Parameter '$1' not recognized"
    exit
    shift # past argument
    shift # past value
esac
done

warnings=()

USTExampleURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"
USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py2712.tar.gz"
USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py352.tar.gz"

function download(){
    url=$1
    output=${url##*/}

    if $useWget ; then wget -O $output $url &> /dev/null ; else curl -L $url > $output --progress-bar ; fi

    echo $output
}

function printColor(){

    case $2 in
        "black") col=0;;
          "red") col=1;;
        "green") col=2;;
       "yellow") col=3;;
         "blue") col=4;;
      "magenta") col=5;;
         "cyan") col=6;;
        "white") col=7;;
              *) col=7;;
    esac

    printf "$(tput setaf $col)$1$(tput sgr 0)\n"
}

function printColorOS(){
    printColor "- $1" $2
}

function printUSTBanner(){
 cat << EOM
$(tput setaf 6)
  _   _                 ___
 | | | |___ ___ _ _    / __|_  _ _ _  __
 | |_| (_-</ -_) '_|   \__ \ || | ' \/ _|
  \___//__/\___|_|     |___/\_, |_||_\__|
                            |__/
$(tput sgr 0)
EOM
}

function banner(){

    type="Info"
    color="green"

    while [[ $# -gt 0 ]]
    do
    key=$1
    case $key in
        -m|--message)
        message=$2
        shift # past argument
        shift # past value
        ;;
        -t|--type)
        type=$2
        shift # past argument
        shift # past value
        ;;
        -c|--color)
        color=$2
        shift # past argument
        shift # past value
        ;;
    esac
    done

    if ! [[ $message = *[!\ ]* ]]; then message=${type}; fi

    sep="$(printf -- '=%.0s' {1..20})"

    if [ $color=="green" ]; then
        case $type in
            "Warning") color="yellow";;
            "Error") color="red";;
        esac
    fi

    printColor "\n$sep $message $sep" $color

}

function installpy(){
    banner -m "Installing Python"

    curl "https://bootstrap.pypa.io/get-pip.py" -o "pip.py" &> /dev/null

    printColorOS "Adding ppa:fkrull/deadsnakes..."
    apt-get -qq install -y software-properties-common &> /dev/null
    apt-get -qq install -y python-software-properties&> /dev/null
    apt-get -qq install -y python3-software-properties&> /dev/null
    add-apt-repository ppa:fkrull/deadsnakes -y &> /dev/null

    printColorOS "Updating repositories..."
    apt-get -qq update &> /dev/null

    # Install python 2
    if [[ $pyversion -eq 2 ]]; then

         printColorOS "Installing Python 2.7..."
         apt-get -qq install -y python2.7&> /dev/null
         printColorOS "Installing pip..."
         sudo -H python2.7 pip.py &> /dev/null
         sudo -H pip -qq install --upgrade pip &> /dev/null
         printColorOS "Installing virtualenv..."
         sudo -H pip -qq install virtualenv &> /dev/null

    # Install python 3
    else

         case $hostVersion in

            *)
                printColorOS "Installing Python 3.5..."
                apt-get -qq install --force-yes python3.5&> /dev/null
                printColorOS "Installing pip..."
                python3.5 pip.py &> /dev/null
                printColorOS "Installing virtualenv..."
                sudo -H pip -qq install virtualenv&> /dev/null
                ;;

#   Python 3.6 will be supported when 2.3 is offically released
#   code intentionally left here to be uncommented when that change happens
#   Ubuntu 18 will not be supported with python 3.6 until that time * 2.7 works as a fallback

#            *)
#                if [[ $hostVersion -lt 18 ]]; then
#                    printColorOS "Adding ppa:jonathonf/python-3.6..."
#                    add-apt-repository ppa:jonathonf/python-3.6 -y  &> /dev/null
#                    printColorOS "Updating repositories..."
#                    apt-get -qq update  &> /dev/null
#                fi
#
#                printColorOS "Installing Python 3.6..."
#                apt-get -qq install -y python3.6 &> /dev/null
#                printColorOS "Installing pip..."
#                sudo -H python3.6 pip.py &> /dev/null
#                sudo -H pip3 -qq install --upgrade pip &> /dev/null
#                printColorOS "Installing virtualenv..."
#                sudo -H pip3 -qq install virtualenv &> /dev/null
#                ;;

        esac

    fi

    sudo rm -rf pip.py
    printColorOS "Python installed succesfully!" green

}


function getPackages(){

    banner -m "Installing Packages"

    printColorOS "Updating repositories..."
    apt-get -qq update  &> /dev/null
    printColorOS "Installing curl..."
    apt-get -qq install -y curl &> /dev/null
    printColorOS "Installing nano..."
    apt-get -qq install -y nano &> /dev/null
    printColorOS "Installing bc..."
    apt-get -qq install -y bc &> /dev/null
    printColorOS "Installing OpenSSL..."
    apt-get -qq install -y openssl &> /dev/null
    apt-get -qq install -y libssl-dev &> /dev/null

    printColorOS "Prequisites installed succesfully!" green

    if $instpy ; then installpy ; fi

}

function getUSTFiles(){
    USTFolder=$1

    # Set URL according to python version
    [[ $pyversion -eq 2 ]] && USTUrl=$USTPython2URL || USTUrl=$USTPython3URL

    # Check UST version
    [[ $USTUrl =~ "v".+"/" ]]
    IFS='/' read -r -a array <<< "$BASH_REMATCH"
    USTVersion=${array[0]}

    banner -m "Configuring UST"

    printColorOS "Using directory $USTFolder..."
    printColorOS "Downloading UST $USTVersion..."
    USTArch=$(download $USTUrl)
    printColorOS "Downloading UST Examples..."
    EXArch=$(download $USTExampleURL)

    printColorOS "Creating directory $USTFolder/examples..."
    mkdir $USTFolder/examples &> /dev/null
    printColorOS "Extracting $USTArch to $USTFolder..."
    tar -zxvf $USTArch -C $USTFolder &> /dev/null
    printColorOS "Extracting $EXArch to $USTFolder..."
    tar -zxvf $EXArch -C $USTFolder &> /dev/null
    printColorOS "Removing temporary files..."
    rm $USTArch $EXArch

    printColorOS "Copying configuration files..."
    cp "$USTFolder/examples/config files - basic/1 user-sync-config.yml" "$USTFolder/user-sync-config.yml"
    cp "$USTFolder/examples/config files - basic/2 connector-umapi.yml" "$USTFolder/connector-umapi.yml"
    cp "$USTFolder/examples/config files - basic/3 connector-ldap.yml" "$USTFolder/connector-ldap.yml"

    printColorOS "Creating shell scripts for running UST..."
    printf "#!/usr/bin/env bash\n./user-sync --users all --process-groups -t" > "$USTFolder/run-user-sync-test.sh"
    printf "#!/usr/bin/env bash\n./user-sync --users all --process-groups" > "$USTFolder/run-user-sync.sh"

    printColorOS "Generating shell script for certificate generation..."
    SSLString="openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout private.key -out certificate_pub.crt"
    printf "#!/usr/bin/env bash\n$SSLString" > "$USTFolder/sslCertGen.sh"

    printColorOS "UST installed succesfully!" green

}

function configureInstallDirectory(){
    local USTInstallDir="${PWD}/UST_Install"
    if [ -d $USTInstallDir ]; then
        rm -rf $USTInstallDir
    fi
    mkdir $USTInstallDir
    echo $USTInstallDir
}

function verifyVersion(){
    version=$(lsb_release -r)

    varr=($(lsb_release -r))
    ver=${varr[1]}

    hostVersion=$(echo $ver | cut -c1-2)

    printf -- "- Ubuntu version: "


    if [ $hostVersion -lt 12 ]; then
        printColor $ver red
        echo "- Your host version is not supported... "
        exit
    else
        printColor $ver green
    fi

    if [[ $hostVersion -eq 18 && $pyversion -eq 3 ]]; then
        printColorOS "Python 3.5 is not supported on Ubuntu 18+ - you will need to use -py 2 instead  \n" red
        exit
    fi

    if (( $hostVersion%2 != 0 )); then
        printColorOS "Only LTS versions are officially supported.  Extra configuration may be required... " yellow
        printColorOS "It is recommended to use -py 2 flag, since python 2 has better support...\n" yellow
    fi

}

function main(){

    printUSTBanner

    verifyVersion
    getPackages
    getUSTFiles $(configureInstallDirectory)

    sudo chmod 777 -R $USTFolder

    banner -m "Install Finish" -c blue
    echo ""
    printColorOS "Completed - You can begin to edit configuration files in:"
    printColorOS "$USTFolder" green
    echo ""
    printColorOS "Folder permissions set to 777 for configuration file editing..." yellow
    printColorOS "When you are finished, please run chmod 555 -R on the folder to reset permissions!" yellow
    echo ""

}

main







#    warnings+=(Test)
#    warnings+=(Tes2222)
#    banner -m "Install Finish" -c blue
#
#    if [ ${#warnings[@]} -gt 0 ]; then
#        printColor "Install completed with some warnings: " yellow
#
#        for w in ${warnings[@]}; do
#            printColorOS $w red
#        done
#
#        echo ""
#    fi