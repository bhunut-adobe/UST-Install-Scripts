#!/usr/bin/env bash

# sudo sh -c 'apt-get update &> /dev/null; apt-get install wget openssl libssl-dev -y &> /dev/null;'

# sudo sh -c 'curl -s -L https://git.io/vxnQZ > ins.sh; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'
# sudo sh -c 'wget -O ins.sh https://git.io/vxnQZ &> /dev/null; chmod 777 ins.sh; ./ins.sh -wget; rm ins.sh;'

offlineMode=false
installPython=false
installWarnings=false
ustVer="2.2.2"

while [[ $# -gt 0 ]]
do
key=$1
case $key in
    --install-python)
        installPython=true
        shift ;;
    --offline)
        offlineMode=true
        shift ;;
    --ust-version)
        if [[ $2 == "2.2.2" || $2 == "2.3" ]]; then
            ustVer=$2
        else
            echo "Version '$2' - Invalid version (2.2.2 or 2.3 only)"
            exit
        fi
        shift # past argument
        shift # past value
        ;;
    *)
        echo "Parameter '$1' not recognized"
        exit
        shift # past argument
        shift # past value
esac
done

if $offlineMode ; then installPython=false ; fi

if [[ $ustVer == "2.3" ]]; then
    # UST Version 2.3rc4 Links
    USTExamplesURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3rc4/example-configurations.tar.gz"
    USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3rc4/user-sync-2.3rc4-ubuntu1604-py2712.tar.gz"
    USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3rc4/user-sync-2.3rc4-ubuntu1604-py363.tar.gz"
    reqPython3Versin="3.6"
else
    # UST Version 2.2.2 Links
    USTExamplesURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"
    USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py2712.tar.gz"
    USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py352.tar.gz"
    reqPython3Version="3.5"
fi



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

function validateDownload(){
    if [[ $(wc -c <$1) -le 10000 ]]; then
        printColorOS "Download error!" red
        installWarnings=true
        return 2
    fi
}

function download(){
    url=$1
    output=${url##*/}
    wget -O $output $url &> /dev/null
    echo $output
}


function installPython27(){

   if [[ $hostVersion -eq 17 ]]; then printColorOS "Warning: python 2.7 may fail to install on Ubuntu 18..." yellow; fi

   printColorOS "Installing Python 2.7..."
   apt-get -qq install -y --force-yes python2.7&> /dev/null
}

function installPython35(){
    printColorOS "Adding ppa:fkrull/deadsnakes..."
    add-apt-repository ppa:fkrull/deadsnakes -y &> /dev/null

    printColorOS "Updating repositories..."
    apt-get -qq update &> /dev/null

    printColorOS "Installing Python 3.5..."
    apt-get -qq install --force-yes python3.5&> /dev/null
    add-apt-repository -remove ppa:fkrull/deadsnakes -y  &> /dev/null
}


function installPython36(){

#   Python 3.6 will be supported when 2.3 is offically released
#   Ubuntu 18 will not be supported with python 3.6 until that time -> 2.7 works as a fallback

    if [[ $hostVersion -lt 18 ]]; then
        printColorOS "Adding ppa:jonathonf/python-3.6..."
        add-apt-repository ppa:jonathonf/python-3.6 -y  &> /dev/null
        printColorOS "Updating repositories..."
        apt-get -qq update  &> /dev/null
    fi

    printColorOS "Installing Python 3.6..."
    apt-get -qq install -y --force-yes python3.6 &> /dev/null
    add-apt-repository -remove ppa:jonathonf/python-3.6 -y  &> /dev/null

}


function installpy(){
    banner -m "Installing Python $fullPyVersion"

    # Install python 2
    if [[ $pyversion -eq 2 ]]; then

        installPython27
        pyCommand="python2.7"

    # Install python 3
    else

        apt-get -qq install -y --force-yes software-properties-common &> /dev/null
        apt-get -qq install -y --force-yes python-software-properties&> /dev/null
        apt-get -qq install -y --force-yes python3-software-properties&> /dev/null

        case $ustVer in
           "2.3") installPython36
                  pyCommand="python3.6";;
               *) installPython35
                  pyCommand="python3.5";;
        esac
    fi

    if apt-get -qq install -y --force-yes $pyCommand &> /dev/null; then
        printColorOS "Python installed succesfully!" green
    else
        printColorOS "Python installation failed.. consider using automatic versioning or manually install instead!" red
        installWarnings=true
    fi

    sudo rm -rf pip.py

}

function installPackage(){

    if ! apt-get -qq install -y --force-yes $1 &> /dev/null; then

        case $2 in
            2) printColorOS "Error installing $1 (optional)... install will continue.." yellow;;
            *) printColorOS "Error installing $1 (required)... install will continue..." red;;
        esac

        installWarnings=true
    fi

}


function getPackages(){

    banner -m "Installing Packages"

    printColorOS "Updating repositories..."
    apt-get -qq update  &> /dev/null

    if $useWget ; then
        printColorOS "Installing wget..."
        installPackage wget
    else
        printColorOS "Installing curl..."
        installPackage curl
    fi

    printColorOS "Installing nano..."
    installPackage nano 2

    if [[ $hostVersion -lt 14 ]]; then
        printColorOS "Installing OpenSSL..."
        installPackage openssl
        installPackage libssl-dev
    fi

    printColorOS "Prerequisites installed succesfully!" green

    if $installPython; then installpy; fi

}

function extractArchive(){

    sourceDir=$1
    destination=$2

    printColorOS "Extracting $sourceDir to $destination..."

    if ! tar -zxvf $sourceDir -C "$destination" &> /dev/null; then
        printColorOS "Extraction error!" red
        installWarnings=true
        return 2
    fi

}

function package(){

    filename="UST_${ustVer}_py${fullPyVersion}.tar.gz"

    test -e $filename && rm $filename

    printColorOS "Packaging $PWD/$filename..." green

    tar -czf $filename -C "$USTFolder" .
    rm -rf "$USTFolder"

    printColorOS "Package complete! You can now distribute $filename to your remote server!\n" green

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
    validateDownload $USTArch

    printColorOS "Downloading UST Examples..."
    EXArch=$(download $USTExamplesURL)
    validateDownload $EXArch

    printColorOS "Creating directory $USTFolder/examples..."
    mkdir $USTFolder/examples &> /dev/null

    extractArchive $USTArch "$USTFolder"

    if extractArchive $EXArch "$USTFolder"; then
        printColorOS "Copying configuration files..."
        cp "$USTFolder/examples/config files - basic/1 user-sync-config.yml" "$USTFolder/user-sync-config.yml"
        cp "$USTFolder/examples/config files - basic/2 connector-umapi.yml" "$USTFolder/connector-umapi.yml"
        cp "$USTFolder/examples/config files - basic/3 connector-ldap.yml" "$USTFolder/connector-ldap.yml"
    fi

    printColorOS "Removing temporary files..."
    rm $USTArch $EXArch

    printColorOS "Creating shell scripts for running UST..."
    printf "#!/usr/bin/env bash\n./user-sync --users mapped --process-groups -t" > "$USTFolder/run-user-sync-test.sh"
    printf "#!/usr/bin/env bash\n./user-sync --users mapped --process-groups" > "$USTFolder/run-user-sync.sh"

    printColorOS "Generating shell script for certificate generation..."
    SSLString="openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout private.key -out certificate_pub.crt"
    printf "#!/usr/bin/env bash\n$SSLString" > "$USTFolder/sslCertGen.sh"

    printColorOS "UST installed succesfully!" green

}

function configureInstallDirectory(){
    local USTInstallDir="${PWD}/UST_Install"
    if [ -d "${USTInstallDir}" ]; then
        rm -rf "${USTInstallDir}"
    fi
    mkdir "${USTInstallDir}"
    echo "${USTInstallDir}"
}


function isPyVersionInstalled(){

    desiredVersion=$1
    testPyVersion=($(python$desiredVersion -V 2>&1))

    effVersion=$(echo ${testPyVersion[1]} | cut -c1-3)
    [[ $effVersion == $desiredVersion ]] && echo true || echo false

}

function verifyHostVersion(){

    if ! $offlineMode; then
        longVersionName=($(lsb_release -r))
        numericalVersion=${longVersionName[1]}
        hostVersion=$(echo $numericalVersion | cut -c1-2)
    fi

    if (( $hostVersion%2 != 0 )); then
        printColorOS "Only LTS versions are officially supported.  Extra configuration may be required... \n" yellow
    fi
    if (( $hostVersion == 13 )); then
        printColorOS "You must download tar.gz files manually on Ubuntu 13... (tls 1.2 not supported) " red
        printColorOS "Place them in the current directory and re-run for automated extraction...\n" red
    fi

    printf -- "- Ubuntu version: "

    if [ $hostVersion -lt 12 ]; then
        printColor $numericalVersion red
        echo "- Your host version is not supported... "
        exit
    else
        printColor $numericalVersion green
    fi

}


function choosePythonVersion(){

    [[ $ustVer == "2.3" ]] && py3V="3.6" || py3V="3.5"

    $(isPyVersionInstalled $py3V) && pyversion=3 || pyversion=2

    if $offlineMode; then

        printColor " --- OFFLINE MODE --- "  blue
        echo ""
        echo " Please choose your User-Sync Version: "
        echo ""
        echo " 1. 12.04"
        echo " 2. 13.04"
        echo " 3. 14.04"
        echo " 4. 15.04"
        echo " 5. 16.04"
        echo " 6. 17.04"
        echo " 7. 18.04"
        echo ""

        while [ 1 -eq 1 ]; do
            read -p "> " choice
            case $choice in
                1) numericalVersion="12.04"; break;;
                2) numericalVersion="13.04"; break;;
                3) numericalVersion="14.04"; break;;
                4) numericalVersion="15.04"; break;;
                5) numericalVersion="16.04"; break;;
                6) numericalVersion="17.04"; break;;
                7) numericalVersion="18.04"; break;;
                *) ;;
            esac
        done
        echo ""

        hostVersion=$(echo $numericalVersion | cut -c1-2)

    fi

    # Default python versions for Ubuntu
    if $offlineMode && ! $installPython; then
        if [[ $ustVer == "2.3" ]]; then
            # Must support python 3.6
            case $hostVersion in
                "18")pyversion=3;;
                   *)pyversion=2;;
            esac
        else
            # Must support python 3.5
            case $hostVersion in
                "16")pyversion=3;;
                "17")pyversion=3;;
                   *)pyversion=2;;
            esac
        fi
    fi

    if $installPython; then
        if [[ $ustVer == "2.3" ]]; then
            # Must support python 3.6
            case $hostVersion in
                "12")pyversion=2;;
                "13")pyversion=2;;
                "14")pyversion=3;;
                "15")pyversion=2;;
                "16")pyversion=3;;
                "17")pyversion=2;;
                "18")pyversion=3;;
                   *)pyversion=2;;
            esac
        else
            # Must support python 3.5
            case $hostVersion in
                "12")pyversion=3;;
                "13")pyversion=2;;
                "14")pyversion=3;;
                "15")pyversion=2;;
                "16")pyversion=3;;
                "17")pyversion=3;;
                "18")pyversion=2;;
                   *)pyversion=2;;
            esac
        fi
    fi

    printf -- "- Python version: "
    [[ $pyversion == "3" ]] && fullPyVersion=$py3V || fullPyVersion="2.7"
    printColor $fullPyVersion green

    printf -- "- Install Python: "; printColor $installPython green
}

function main(){

    printUSTBanner

    if [ "$EUID" -ne 0 ]; then
        printColorOS "Please re-run with sudo... \n" yellow
        exit
    fi

    choosePythonVersion
    verifyHostVersion

    printf -- "- User-Sync version: "; printColor $ustVer green
    printf -- "- Offline Mode: "; printColor $offlineMode green

    getPackages
    getUSTFiles "$(configureInstallDirectory)"

    sudo chmod 777 -R "$USTFolder"

    banner -m "Install Finish" -c blue
    echo ""

    if $installWarnings; then
        printColorOS "Install completed with some warnings (see above)... " yellow
        echo ""
    fi

    if $offlineMode; then
        package
    else
        printColorOS "Completed - You can begin to edit configuration files in:"
        printColorOS "$USTFolder" green
        echo ""
        printColorOS "Folder permissions set to 777 for configuration file editing..." yellow
        printColorOS "When you are finished, please run chmod 555 -R on the folder to reset permissions!" yellow
        echo ""
    fi

}

main


