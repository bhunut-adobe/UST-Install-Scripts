<img src="Screenshots/cce2.png" height="150"> | <h1>Install Scripts <br/>Adobe User Sync Tool</h1>
------------ | -------------


### Screenshots

<img src="Screenshots/windows_ust.jpg" height="200"> <img src="Screenshots/ubuntu_ust.jpg" height="200">

<a href="sample.md"> See sample output from Windows version </a>

These scripts will help you install and configure Adobe's User Sync tool.  User Sync runs behind your enterprise firewall on a virtual machine 
and quietly keeps your named user accounts in sync with your local LDAP compliant directory!

Overview:
https://spark.adobe.com/page/E3hSsLq3G1iVz/<br/>
User Sync Tool:
https://github.com/adobe-apiplatform/user-sync.py

<hr/>

### Quick Reference:

**Windows:**<br/> <code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>

**Linux/MacOS:**<br/> <code>sudo sh -c 'wget -O ins.sh https://git.io/vpIy6; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'</code>
<hr/>

## Windows Powershell:
You should set the execution policy for powershell to allow your VM to run scripts temporarily:

<code>Set-ExecutionPolicy Bypass -Scope Process;</code> 

Run the install script:

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>

### Incudes:
<ul>
<li>Python 2.7 or 3.64</li>
<li>UST Application and configuration files</li>
<li>Open SSL for certificate/key generation</li>
<li>7-Zip portable version for extracting .tar.gz archives</li>
<li>Notepad++ portable version for better YAML editing </li>
</ul>

### Generated Batch Files:
<b>Run_UST_Live.bat:</b> Runs UST in live mode with options -users mapped --process-groups<br/>
<b>Run_UST_Test.bat:</b> Runs UST in test mode with options -users mapped --process-groups<br/>
<b>Adobe_IO_Cert_Generation.bat:</b> Located in Utils/OpenSSL, generates a certificate-key pair for use with the UMAPI integration.  Places private.key and certificate.crt in the primary
install directory.<br/>
<b>Open_Config_Files.bat:</b> Conveniently opens all the .yml configuration files using the included portable Notepad++ instance.
<b>examples</b> Directory of example configuration files for reference.

### Arguments

<code>-py <2 | 3 | none></code>

You can choose which python version to use by changing the -py flag
on the call. Values of 2 and 3 are allowed.  You can also choose none, if you wish to skip python.

<code>-cleanpy</code>

This feature is useful! When used, the script will remove <b>all existing python installations for all versions</b>, which
leaves the VM clean so that the correct versions can be used.  User Sync <b>requires</b> that the installed python version be
64 bit! This flag helps to smooth and clean up the install process.

<code>-offline</code>

This option builds a complete UST package, and includes the appropriate python installer as part of the archive.  You can use this
to generate install packages for VM's that are not able to run the script.  You can also use "-py none" to create a package
with no installer.

Example calls with flags:

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1 <b>-py 2</b>; rm -Force .\inst.ps1;</code>

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1 <b>-cleanpy</b>; rm -Force .\inst.ps1;</code>

<hr/>

### Linux (Ubuntu 12.04+ CentOs 7+, Fedora, Redhat, Suse) and MacOS (OS-X 10)

The following will install User Sync and related packages on all of the above platforms (includes python if desired):

<code>sudo sh -c 'wget -O ins.sh https://git.io/vpIy6; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'</code>

#### Prerequisites

For Cent Os/Fedora/Redhat, you may need to run the following to install wget:

<code>sudo sh -c 'yum-check update; yum install wget -y;' &> /dev/null </code>

For older versions of Ubuntu (12.04), you may need to run this line first to enable the proper security protocols:

<code>sudo sh -c 'apt-get update; apt-get install wget openssl libssl-dev -y -qq;' &> /dev/null</code>

For Mac OS, you will need ssl secure wget:

<code>sh -c 'brew update --force; brew install wget --with-libressl'</code>

### Generated Shell Scripts:
<b>run-user-sync.sh:</b> Runs UST in live mode with options -users mapped --process-groups<br/>
<b>run-user-sync-test.sh:</b> Runs UST in test mode with options -users mapped --process-groups<br/>
<b>sslCertGen.sh:</b> Generates a certificate-key pair for use with the UMAPI integration.  Places private.key and certificate.crt in the primary
install directory.<br/>
<b>examples</b> Directory of example configuration files for reference.

### Arguments

<code>--ust-Version <2.2.2 | 2.3></code>

Specify which version of UST you want to install.  The recommended version at this time is 2.2.2, since 2.3 is currently 2.3rc4. By default, 2.2.2 will be installed.
The version of UST to be used along with your host Ubuntu version determine which python version shoudl be used, and fetches the appropriate user-sync package.

<code>--install-python</code>

By default, python is neither installed nor updated.  The script will determine which version of the user-sync tool to fetch based on which python versions are native to your
host Ubuntu version.  If you add the <b/>--install-python</b> flag, the script will determine the highest possible python version that can be installed on your host to work with
the selected UST version, and install/update that python version before downloading the tool.  This command can also be used in conjunction with the --offline flag to build
deployment archives for a target host and optimal python version.  The general behavior is: find which version of python 3 the UST version requires.  If that version is available, install it.
Otherwise, revert to python 2.7.

<code>--offline</code>

This option builds a complete UST package in .tar.gz format on your local machine. You can use this
to deploy the tool to VM's that are not able to run the script. Use this in combination with the above commands
to produce a target UST/python version package for your host.

Example calls with flags:

<code>sudo sh -c 'wget -O ins.sh https://git.io/vpIy6; chmod 777 ins.sh; ./ins.sh --install-python; rm ins.sh;'</code>

<code>sudo sh -c 'wget -O ins.sh https://git.io/vpIy6; chmod 777 ins.sh; ./ins.sh --install-python --ust-version 2.3; rm ins.sh;'</code>

<hr/>

### Release Notes

#### V2.1
Extends functionality to cover additional platforms (Fedora, Redhat, Suse, MacOS). User sync tool functions as expected on Fedora/Redhat, but is not supported on Suse platforms.  Nevertheless,
this script will setup the directory structure and python environment as needed, should the end user wish to build User Sync  themselves.  The extension to MacOS introduces some subtle changes
in script execution, further refactoring, and adds another block to the host_libs file.  Mac OS version relies on home brew to function.

#### V2.0
This release introduces smart versioning. The script will choose which python build of the User Sync tool to download, depending on your host 
Ubuntu version and the User Sync version you have selected. Running the script with no arguments will automatically fetch the latest release 
version of User Sync (currently 2.2.2), and check your system to determine which build to get. User Sync version can be specified by --ust-version. 
The default version is 2.2.2, but 2.3rc4 can be fetched by using --ust-version 2.3.

Python install has moved to a command line argument of --install-python. When specified, versioning is affected. The script will calculate the maximum 
supported python version for your host that corresponds to the max python version of the user-sync executable for the chosen UST version. The script install 
or update that version of python during the process. This is now the recommended option, but is intentionally left out of default. The script can correctly map 
versioning for Ubuntu 12.04 - 18.04. All LTS (even) releases are fully supported. Intermediate (odd) releases are supported, but special cases are required for 
some. The user will be prompted for those options during install.

Version 2.0 also incorporates packaging. Using the --offline flag along with --ust-version and --install-python, you can build a .tar.gz archive of the fully 
configured UST instance for any of the supported Ubuntu distributions and any of their supported python/user-sync combinations. Leave off --install-python to 
build a compatible package for any distro that will not require any python modification.

