
# User Sync Tool installation script
# Danimae Janssen 04/2018

# This script is for all versions of Windows (server and normal) running User-Sync.
# Versions of UST will run all the way back to Server 2008, but due to TLS and default
# Powershell restrictions, this script will run only on Server 2012+, and (Non-Server) Windows 7+

# This cript can be run with or without a GUI platform, and therefore should be applicable to nano
# server builds as well as core (although core technically does include a limited GUI functionality).
# It is very possible to remote into a Windows server instance an run this script via terminal alone
# with successful results, although most clients opt for using a GUI anyways since it makes User-Sync
# configuration significantly easier.

# The minimum Powershell version is 3.0, which is supported by default on server 2012+, but can also be
# installed on server 2008 if the correct .NET support is added as well.  We do not recommend versions
# before older than 2012 for long term support.

# For more documentation on the functional features of this script, please visit
# https://github.com/janssenda-adobe/UST-Install-Scripts

# Simple usage: run in powershell
# (New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;

# Run this first if execution privileges are required:
# Set-ExecutionPolicy Bypass -Scope Process;


########################################################################################################################

param([String]$pythonversion="3.6",
    [Switch]$cleanpy=$false,
    [Switch]$offline=$false,
    [Switch]$test=$false,
    [String]$ustversion="2.2.2")

# Strict mode -- useful for testing, not suited for release
 Set-StrictMode -Version 2.0 -Debug

$ErrorActionPreference = "Stop"

# Check the input arguments for problems
if ($args) {
    Write-Host "Error: $args not recognized!"
    exit
}

if ( -Not ( $ustversion -eq "2.2.2" -or $ustversion -eq "2.3" )) {
    Write-Host "UST Version '$ustversion' - Invalid version (2.2.2 or 2.3 only)"
    exit
}

if ( -Not ( $pythonversion -eq "2.7" -or $pythonversion -eq "3.6" -or $pythonversion -eq "none")) {
    Write-Host "Py Version '$pythonversion' - Invalid version (2.7, 3.6, or none only)"
    exit
}

# These are the collection of URL's that the script must reach to complete successfully.  They are collected at the top of this script
# for convenience, but are used throughout.  Note that all of the dependencies are collectively stored on the install-scripts repo for
# forward compatability and resistance to potential external URL changes.  The static resources are stored on the install-scripts repo,
# (the first block), and the User-Sync related resources are taken from their respective source locations to preserve integrity with
# respect to build updates and file changes.  Python URL's are also directed to the source, since it is reliable and because we intend
# to maintain compatibility with the latest versions.

$notepadURL = "https://github.com/janssenda-adobe/UST-Install-Scripts/raw/master/Util/npp.7.5.6.bin.x64.zip"
$7ZipURL = "https://github.com/janssenda-adobe/UST-Install-Scripts/raw/master/Util/7-Zip64.zip"
$openSSLBinURL = "https://github.com/janssenda-adobe/UST-Install-Scripts/raw/master/Util/openssl-1.0.2l-x64_86-win64.zip"
$openSSLConfigURL = 'https://github.com/janssenda-adobe/UST-Install-Scripts/raw/master/Util/openssl.cnf'
$adobeIOCertScriptURL = "https://github.com/janssenda-adobe/UST-Install-Scripts/raw/master/UST_io_certgen.ps1"

$Python2URL = "https://www.python.org/ftp/python/2.7.14/python-2.7.14.amd64.msi"
#$Python3URL = "https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe"
$Python3URL = "https://www.python.org/ftp/python/3.6.5/python-3.6.5-amd64.exe"

if ( $ustversion -eq "2.3" ) {
    $USTPython2URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3rc4/user-sync-v2.3rc4-win64-py2714.tar.gz"
    $USTPython3URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3rc4/user-sync-v2.3rc4-win64-py363.tar.gz"
    $USTExamplesURL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3rc4/example-configurations.tar.gz"
} else {
    $USTPython2URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-windows-py2714.tar.gz"
    $USTPython3URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-windows-py363.tar.gz"
    $USTExamplesURL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"
}

# Set global parameters for the script. TLS 1.2 is EXTREMELY important, and is the primary reason the scripts cannot run on
# older versions of Windows Server.  The effect of a recent change to security on GitHub.com is that all content is now
# inaccessible unless requests are TLS 1.2 compliant.  This is NOT always the default on Windows, and so must be explicitly set here.

# TLS 1.2 protocol enable - required to download from GitHub, does NOT work on Powershell < 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Array for collecting warnings to display at end of install.  You can think of this as an exception handler which serves only
# to carry forward information about possible errors and warnings to the user in a compact informative way at the end of the script.

$warnings = New-Object System.Collections.Generic.List[System.Object]

# Temporary download location - This is where all files are downloaded to, and is deleted as part of the cleanup process at
# the end of the script.  The location of this folder is determined by Windows.

$DownloadFolder = "$env:TEMP\USTDownload"

# UST folder location - Here we specify the path for our UST install directory.  The convention is to create the directory
# in the context of where the script is run from (hence, it is helpful to navigate to your desired folder BEFORE running the script).
# The naming is User-Sync-2.2.2 for UST 2.2.2 as an example, and User-Sync-$version as a general rule.

$USTInstallDir = (Get-Item -Path ".\" -Verbose).FullName.TrimEnd('\')+"\User-Sync-${ustversion}"

########################################################################################################################

# Simple methods for making output prettier!

function Print-Color ($msg, $color) {
    Write-Host $msg -ForegroundColor $color
}

# Prints a simple banner with message - useful for keeping portions of output better organized
# Available types are info, warning, and error.  These correspond to colors of green, yellow
# and red respectively.  Color can be overridden with the -color argument.

function Banner {
    Param(
        [String]$message,
        [String]$type="Info",
        [String]$color="Green"
    )

    $message = If ($message) {$message} Else {$type}

    if ($color -eq "Green"){
        switch ($type) {
            "Warning" { $color = "Yellow"; break }
            "Error" { $color = "Red"; break }
        }
    }

    $msgChar = "="
    $charLen = 20

    $messageTop = ("`n" + $msgChar*$charLen + " ${message} " + $msgChar*$charLen)
    $messageBottom = $msgChar*($messageTop.length-1)

    Print-Color $messageTop $color
}

########################################################################################################################

# Utility and helper methods

# Expand-Zip uses native windows functionality (backwards compatible through Powershel 2.0) to unzip an archive.
# Usage: Expand-Zip path output

function Expand-Zip() {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $Output
    )

    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($Path)

    foreach($item in $zip.items()) {
        $shell.Namespace($Output).copyhere($item, 0x14)
    }

}

# Expands a .tar.gz file using the portable version of 7-Zip whose URL is located above.  7-Zip is downloaded but not
# installed during the setup proces.  This must be split into a two step process, in order to all for the possibility
# that the install directory has spaces in the name. Piping IO stream output through 7-Zip is more elegant, but does not
# work correctly with spaced paths leading to the 7zip executable. See 7-Zip documentation for command line options.
# Usage: Expand-TarGZ path output

function Expand-TarGZ() {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $Output
    )

    $filename = $Path.Split('\')[-1]
    $filename = $filename.Substring(0,$filename.Length-3)

    try    {
        Start-Process -FilePath $7zpath -ArgumentList "x `"$Path`" -aoa -y -o`"$DownloadFolder`"" -Wait
        Start-Process -FilePath $7zpath -ArgumentList "x `"$DownloadFolder\$filename`" -aoa -ttar -y -o`"$Output`"" -Wait
    } catch {
        Print-Color "Error while extracting $path..." red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }
}

# Expand-Archive consists of a combination of the Expand-Zip and Expand-TarGZ methods in order to simplify archive extraction.
# Instead worrying about the archive type, one must simply use Expand-Archive for either of the bove with a path and destination!
# Usage: Expand-Archive path destination

function Expand-Archive(){
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $Output
    )

    if ( $Path.Substring($Path.Length-3) -eq "zip" ) {
        Expand-Zip -Path $Path -Output $Output
    } elseif ( $Path.Substring($Path.Length-6) -eq "tar.gz" ) {
        Expand-TarGZ -Path $Path -Output $Output
    } else {
        Print-Color $Path.Split('\')[-1] red
        $fmt = $Path.Split('\')[-1]
        throw ("Unrecognized archive format.. $fmt")
    }

}

# Creates the directories needed for the install process.  This includes the install directory
# as well as the temporary download folder.  This process does not check to see if the directories
# exist before creating them - hence, any existing files will be over-written.

function Set-Directories(){


    Write-Host "- Creating directory $USTInstallDir... "
    New-Item -ItemType Directory -Force -Path $USTInstallDir | Out-Null

    #Create Temp download folder
    New-Item -Path $DownloadFolder -ItemType "Directory" -Force | Out-Null

    return $USTInstallDir

}

# A Get-Util cuntion is defined, which is analogous to the "download" and "extract-archive methods in the linux script.
# This method simply downloads the file at the specified URL, and extracts it to the output location.  The filename
# is determined as everything following the last "/" in the URL and is the same name.

function Get-Util($fileURL, $outputFolder){

    New-Item -Path $outputFolder -ItemType "Directory" -Force | Out-Null

    $filename = $fileURL.Split('/')[-1]
    $filepath = "$DownloadFolder\$filename"

    Write-Host "- Downloading $filename from $fileURL"
    (New-Object net.webclient).DownloadFile($fileURL, $filepath)

    if(Test-Path $filepath){
        Write-Host "- Extracting $filename to $outputFolder"
        Expand-Archive -Path $filepath -Output $outputFolder
        return $outputFolder
    }
}

# Simply cleans up after the install process by removing the temp download folder.  If the script was run in offline mode, this method will
# also delete the install directory, since it has been packaged into a zip file for deployment.

function Cleanup() {
    try {
        if ($offline){
            #Delete UST Folder after archive is built for offline mode
            Remove-Item -Path $USTFolder -Recurse -Confirm:$false -Force
        }

    } catch {}
    try{
        #Delete Temp DownloadFolder for UST, Python and Config files
        Remove-Item -Path $DownloadFolder -Recurse -Confirm:$false -Force
    } catch {}
}

# Packaging function.  This is executed when the -offlinemode flag is used to generate a packaged zip file ready for deployment on a target server.
# This function simply gathers the entire install directory into an archive, and then removes the parent folder.  For more information on the
# offline packaging feature, see the documentation.

function Package(){

    Banner -message "Packaging"

    $filename = "UST_${ustversion}_py${pythonversion}.zip"

    try    {
        Write-Host "- Creating $filename with Python $pythonversion"
        Start-Process -FilePath $7zpath -ArgumentList "a $filename `"$USTFolder\*`"" -Wait -NoNewWindow | Out-Null
    } catch {
        Print-Color "Error while packaging..." red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }
}

########################################################################################################################

# Python Process

# Sometimes it is desirable to remove an existing version of python so that the correct one can be installed.  One such example
# is if a user has a pre-installed version of python, but has and out of date version or the wrong architecture (x86).  This method
# streamlines complete removal of any previous installations by scanning the registry for python uninstaller entries.

# The process is to search through each uninstall string entry, and checking whether that entry contains a regex match to "Python".
# If so, the provided uninstall string will be executed, and the entry is removed from the registry.  If there are unused leftover keys,
# then they are removed as well.

# In addtion, any leftover system folders for python are removed as well (see the $systemPaths array).  The uninstaller will not do anything
# if no matches are found initially.

function Remove-Python(){
    Banner "Uninstalling Python" -type Info
    $errors = $false
    $matches = $false

    # Subkeys from registry for managing installed software state
    $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $reg = [microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$env:computername)
    $UninstallerSubkeys = $reg.OpenSubkey($UninstallKey).GetSubkeyNames()

    # Loop through each key in the set of ininsall keys
    foreach ($k in $UninstallerSubkeys){

        # Get the current key
        $thisKey = $reg.OpenSubKey("${UninstallKey}\\${k}")

        # See if this key's displayname contains Python
        if ($thisKey.GetValue("DisplayName") | Select-String -pattern "(Python)" -Quiet)    {
            $matches = $true
            $id = ([String] $thisKey).Split('\')[-1]
            $rmKey = "HKLM:\\" + $UninstallKey + "\\$id"
            $app = $thisKey.GetValue("DisplayName")

            Write-Host "- Removing" $app

            # Execute the installstring for the matched application
            $instCode = (Start-Process msiexec.exe -ArgumentList("/x $id /q /norestart") -Wait -PassThru).ExitCode

            # If removal succeeds, remove the uninstall key from the registry.  If not, indicate that the install
            # process should be run manually.
            if ($instCode -eq 0 -or $instCode -eq 1603)  {
                if (Test-Path $rmKey) {
                    Remove-Item -Path $rmKey
                }
            } else {
                $errors = $true
                $errmsg =  "- There was a problem removing ($app)`n- Please remove it manually!"
                Print-Color $errmsg red
                Print-Color ("- " + $PSItem.ToString()) red
                $warnings.Add($PSItem.ToString())

            }

        }
    }

    # Python install paths to be removed if they still exist, ensuring a clean uninstall
    $systemPaths = @("C:\Python27","C:\Program Files\Python36","C:\Program Files (x86)\Python36")

    foreach ($p in $systemPaths){
        if (Test-Path $p){
            Write-Host "- Removing $p"
            Remove-Item -path $p -Force -confirm:$false -recurse
        }
    }

    Remove-PythonFromPath

    if (-not ($matches)){
        Write-Host "- Nothing to uninstall!"
    } elseif ($errors){
        Print-Color "`n- Uninstallation completed with some errors..." Yellow
    } else {
        Print-Color "`n- Uninstall completed succesfully!" Green
    }

}



# A non-critical and yet extremely important piece is the installation of python.  Python is of course required in order to run User-Sync,
# but if you wish to install it separately, or if this script fails to install properly, you can continue to use the rest of the script
# to set up the entire environment regardless.  This will happn by default on error, but if you wish to explicitly skip python installation,
# you can run with the flag -py none.

# This method first goes through the same set of uninstall strings as used above.  It is tempting to find a means of refactoring this part
# of the code, but that loses value upon the realization that it is essential for this method to read the up to date, real time registery
# keys to accurately determine python's state.  Reusing previous code will result in a mis-match of states and the script will not be
# able to properly install python.

# Previously of this script used a higher level method for determining whether python was installed:

# Get-CimInstance -ClassName 'Win32_Product' -Filter "Name like 'Python% Core Interpreter (64-bit)'"

# After much testing, this method, while concise and accurate, takes many times longer to complete than a simple registery sweep,
# and may only return a single result.  Lastly, it is not backwards compatible to Powershell 3.  The python version must be specific to
# the version used to compile user-sync.pex - i.e., python 3.5 cannot run user-sync.pex compiled on 3.6, and vice versa, so versioning
# becomes very important here.

# This method includes a packaging function.  If the -offlinemode flag is specified at runtime, the python installer corresponding to the
# user's specification and choice of User-Sync version will be downloaded and included within the utils folder of the final output directory.
# In this case, python is NOT installed on the host machine, and the installer ends up inside the final arhive for deployment.

# Since python 3 occasionally fails to install on some systems, the script will automatically switch to python 2 in that case (even if the
# -py 3 flag is specified).

function Get-Python () {

    if ( $pythonversion -eq "2.7" ){
        $pythonURL = $Python2URL
        $pyPath = "C:\Python27";
    }
    else {
        $pythonversion = "3.6"
        $pythonURL = $Python3URL
        $pyPath = "C:\Program Files\Python36"
    }

    Banner -message "Installing Python $pythonversion"
    $installError = $false

    if ( -not (isPyversionInstalled $pythonversion)) { $install = $true }
    else {
        $install = $false
        Write-Host "- Python $pythonversion already installed! Skipping..."
    }

    # The actual process of installation
    if ($install -or $offline){
        Write-Host "- Python $pythonversion will be downloaded..."

        # Get the python installer from the linkprovided at the top of this script
        $pythonInstaller = $pythonURL.Split('/')[-1]
        $pythonInstallerOutput = "$DownloadFolder\$pythonInstaller"
        Write-Host "- Downloading Python from $pythonURL"
        $wc = New-Object net.webclient

        # If the script is running in offline mode for packaging, the installer is downloaded into the
        # utils folder for later use instead of the temporary download folder.
        if ($offline) {
            if (-not (Test-Path "$USTFolder\Utils\$pythonInstaller")){
                $wc.DownloadFile($pythonURL, "$USTFolder\Utils\$pythonInstaller")
            } else {
                Print-Color "- Python already discovered, skipping... " green
            }

        } else  {

            # Download the installer as normal otherwise
            $wc.DownloadFile($pythonURL, $pythonInstallerOutput)

            if (Test-Path $pythonInstallerOutput)
            {
                # Passive python installation using flags for all users (changes install location to C:\Program Files), and prepend path to add the
                # the environment variable to the path.
                Write-Host "- Begin Python Installation"
                $pythonProcess = Start-Process $pythonInstallerOutput -ArgumentList @('/passive', 'InstallAllUsers=1') -Wait -PassThru

                # Successful result
                if ($pythonProcess.ExitCode -eq 0)
                {
                    Write-Host "- Python Installation - Completed"
                }
                else
                {
                    if ($pythonversion -eq 3.6) {
                        Print-Color "- Warning: Python may have failed to install Windows updates for this version of Windows.`Switching to Python 2..." yellow
                        $pythonversion = 2.7
                        Get-Python
                        return
                    }

                    $errmsg = "- Python Installation - Error with ExitCode: $( $pythonProcess.ExitCode )"
                    Print-Color $errmsg red
                    $installError = $true
                    $warnings.Add($errmsg)
                    $install = $false
                }
            }
        }
    }

    # We will not set the pex root unless we are on the target machine.  If so, this sets the correct variable.
    if (-not $offline) {

        if (-not $installError) {
            Write-Host "- Add Python to path..."
            Set-PythonPath $pyPath
        }

        #Set Environment Variable
        Write-Host "- Set PEX_ROOT System Environment Variable"
        $env:PEX_ROOT = "$env:SystemDrive\PEX"
        [Environment]::SetEnvironmentVariable("PEX_ROOT", "$env:SystemDrive\PEX", "Machine")

    }

    return $pythonversion

}

# Simple regex search to remove ALL versions of python from path, so as to avoid oversaturation and conflicting
# bins.  We also update the local path variable for immediate console level changes.
function Remove-PythonFromPath(){
    $regA="(;|\b)[\\a-zA-Z:\s]+(Python\d\d)\\?(?=(;|))"
    $env:Path = ($env:Path -replace "$regA","").TrimStart(";")
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
}

# Sets the new path including the current version of python.  ALL previous versions are stripped from the path variable
# and the freshly installed version is prepended.
function Set-PythonPath($pyPath){
    Remove-PythonFromPath
    $env:Path = "$pyPath;$env:Path"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
}

function isPyversionInstalled($target){
    # Subkeys from registry for managing installed software state
    $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $reg = [microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$env:computername)
    $UninstallerSubkeys = $reg.OpenSubkey($UninstallKey).GetSubkeyNames()
    $tinstalled = $false

    # See if python is installed, and more specifically if 2.7 or 3.6 are installed (one is required)
    foreach ($k in $UninstallerSubkeys){
        $thisKey = $reg.OpenSubKey("${UninstallKey}\\${k}")
        if ($thisKey.GetValue("DisplayName") | Select-String -pattern "(Python).+(\(64-Bit\))" -Quiet)    {
            $thisKey.GetValue("DisplayVersion") | Select-String -pattern "((3.6)|(2.7))(.)" | foreach-object {
                if ($_.Matches[0].Groups[1].Value -eq $target) {$tinstalled = $true; break}
            }
        }
    }

    return $tinstalled
}


########################################################################################################################

# Fetch required files

# Most of the useful functionality occurs in the Get-USTFiles method.  This method fetches the examples and user-sync archives, and uses them
# to construct a coherent file structure that constitutes the user sync environment.  This includes copying and renaming the configuration
# .yml files from the examples sub-directory to primary install directory, as well as extracting user-sync.pex itself to that directory.

# The UST URL's are set at the beginning of the script for convenience.  The choice of which URL depends on whether the user
# has specified the -py flag. By default, the preferred version of python is 3.6 - however, it may be the case that 3.6 cannot
# be installed on old or non-updated versions of windows, and there is a 2.7 compiled version of user-sync.pex for that case.

function Get-USTFiles () {
    Banner -message "Download UST Files"
    if ($pythonversion -eq 2.7){
        $URL = $USTPython2URL
    } else {
        $URL = $USTPython3URL
    }


    # Download UST and Extract
    $USTdownloadList = @()
    $USTdownloadList += $URL
    $USTdownloadList += $USTExamplesURL

    foreach($download in $USTdownloadList){
        $filename = $download.Split('/')[-1]
        $downloadfile = "$DownloadFolder\$filename"

        #Download file
        Write-Host "- Downloading $filename from $download"

        $wc = New-Object net.webclient
        $wc.DownloadFile($download,$downloadfile)

        if(Test-Path $downloadfile){
            #Extract downloaded file to UST Folder
            Write-Host "- Extracting $downloadfile to $USTFolder"
            Expand-Archive -Path $downloadfile -Output $USTFolder
        }
    }


    # Copy the example .yml files from "config files - basic" to the root install directory.  The files are renamed
    # so as to remove the leading numbers and make them readable by the User-Sync tool.

    $configExamplePath = "$USTFolder\examples"

    if(Test-Path -Path $configExamplePath){
        Get-ChildItem -Path $configExamplePath -Recurse -Filter '*.yml' | % { ( $_ |  Get-Content ) | Set-Content $_.pspath -Force }
        $configBasicPath = "$configExamplePath\config files - basic"
        Copy-Item -Path "$configBasicPath\3 connector-ldap.yml" -Destination $USTFolder\connector-ldap.yml -Force
        Copy-Item -Path "$configBasicPath\2 connector-umapi.yml" -Destination $USTFolder\connector-umapi.yml -Force
        Copy-Item -Path "$configBasicPath\1 user-sync-config.yml" -Destination $USTFolder\user-sync-config.yml -Force

    }
}


# OpenSSL must be explicitly downloaded for Windows platforms, since there is no native implementation.  OpenSSL is required in order
# to generate the public/private certificate/key pair that the User-Sync tool needs to communicate securley with the UMAPI.  Please note
# that this does not INSTALL OpenSSL - it simple downloads a portable implementation which can be used with a supplied script to make
# the gneration straightforward.  If you use your own CA trusted certificate, the generation process can be skipped and this method
# can be safely ignored.  This method returns the location of openSSL.

function Get-OpenSSL () {

    #Download OpenSSL 1.0.2l binary for Windows and extract to utils folder
    $openSSLBinFileName = $openSSLBinURL.Split('/')[-1]
    $openSSLOutputPath = "$DownloadFolder\$openSSLBinFileName"
    $openSSLUSTFolder = "$USTFolder\Utils\openSSL"
    Write-Host "- Downloading OpenSSL Win32 Binary from $openSSLBinURL"

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLBinURL,$openSSLOutputPath)

    if(Test-Path $openSSLOutputPath){
        #- Extracting downloaded file to UST folder.
        Write-Host "- Extracting $openSSLBinFileName to $openSSLUSTFolder"
        try{
            New-Item -Path $openSSLUSTFolder -ItemType Directory -Force | Out-Null
            Expand-Archive -Path $openSSLOutputPath -Output $openSSLUSTFolder
            Write-Host "- Completed extracting $openSSLBinFileName to $openSSLUSTFolder"
        }catch{
            Write-Error "Unable to extract openSSL"
        }
    }

    #Download Default Openssl.cfg configuration file
    $openSSLConfigFileName = $openSSLConfigURL.Split('/')[-1]
    $openSSLConfigOutputPath = "$USTFolder\Utils\openSSL\$openSSLConfigFileName"
    Write-Host "- Downloading default openssl.cnf config file from $openSSLConfigURL"

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLConfigURL,$openSSLConfigOutputPath)

    return $openSSLUSTFolder

}

########################################################################################################################

# Final steps

# The installation is finalized here with the generation of some helpful batch files.  These include live and test mode scripts so that
# the User-Sync tool can be run quickly and easily with the common parameters post-install.  And additional script is generated for
# convenient editing of the .yml files, which can be occasionally problematic (and hard to read) when edited with notepad.  This
# script uses the portably version of Notepad++ downloaded during the process into the utils folder to instantly open all off the
# necessary files with proper whitespace management and syntax highlighting.  This is provided for convenience and is not an
# essential piece of the srcipt. Also created is a batch file for generating the OpenSSL pair as discussed above.

function Finalize-Installation ($openSSLUSTFolder) {

    # It is also helpful to generate a shell script which can be used to create the public/private key pair needed by User Sync to talk
    # to the UMAPI. The shell script will prompt the users for specific information, and the deposit certificate_pub.crt and private.key
    # into the install directory.

    #Download Adobe.IO Cert generation Script and put it into utils\openSSL folder
    $adobeIOCertScript = $adobeIOCertScriptURL.Split('/')[-1]
    $adobeIOCertScriptOutputPath = "$USTFolder\Utils\openSSL\$adobeIOCertScript"
    Write-Host "- Downloading Adobe.IO Cert Generation Script from $adobeIOCertScriptURL"

    $wc = New-Object net.webclient
    $wc.DownloadFile($adobeIOCertScriptURL,$adobeIOCertScriptOutputPath)

    if(Test-Path $adobeIOCertScriptOutputPath){

        $batchfile = '@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -file ' + $adobeIOCertScript
        $batchfile | Out-File "$openSSLUSTFolder\Adobe_IO_Cert_Generation.bat" -Force -Encoding ascii

    }

    # Here we create some simple shell scripts for running UST in test and live mode with the commonly used flags of --users mapped and
    # --process-groups.  Refer to the User Sync documentation for more information.

    if(Test-Path $USTFolder){
        Write-Host "- Creating Open_Config_Files.bat... "
        $openCFG_batchfile = @"
start "" .\Utils\Notepad++\notepad++.exe *.yml *.crt
exit
"@
        $openCFG_batchfile | Out-File "$USTFolder\Open_Config_Files.bat" -Force -Encoding ascii

        Write-Host "- Creating Run_UST_Test_Mode.bat... "
        $test_mode_batchfile = @"
REM "Running UST in TEST-MODE"
python user-sync.pex --process-groups --users mapped -t
pause
"@
        $test_mode_batchfile | Out-File "$USTFolder\Run_UST_Test_Mode.bat" -Force -Encoding ascii

        Write-Host "- Creating Run_UST_Live.bat... "
        $live_mode_batchfile = @"
REM "Running UST"
python user-sync.pex --process-groups --users mapped
"@
        $live_mode_batchfile | Out-File "$USTFolder\Run_UST_Live.bat" -Force -Encoding ascii
    }

}

########################################################################################################################

# Pseudo Main

# All of the above are executed by this psuedo Main method in a proper structered programmatic way, as would be the case were we
# using a programming language.  HOWEVER, a fundamental difference between shell script and standard languages is the notion of
# scoping and memory management.  In powershell, we work at a lower level - so while you can observe "Main" as conceptual main class,
# bear in mind that all variables and functions share global scope and there is no sense of encapsulation.  As such, the variables
# in this script are used in a traditionally "blind" sense, where we rely on code executed before they are used to set them.  There
# is no TRUE concept of structure and local scope.

if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){


    $introBanner = "
==========================================================

         _   _                 ___
        | | | |___ ___ _ _    / __|_  _ _ _  __
        | |_| (_-</ -_) '_|   \__ \ || | ' \/ _|
         \___//__/\___|_|     |___/\_, |_||_\__|
                                   |__/

"
    $introText=
    "Windows Quick Install 2.0 for UST v2.2.2 - 2.3rc4
https://github.com/janssenda-adobe/UST-Install-Scripts"

    Print-Color $introBanner cyan
    Print-Color $introText green
    Print-Color "==========================================================`n" cyan


    # Show which parameters are set
    if ($test) {Print-Color "*** TEST MODE *** " blue}
    Print-Color "*** Parameter List ***`n" Green
    Write-Host "- User-Sync Version: " $ustversion
    Write-Host "- Python Version: " $pythonversion
    Write-Host "- Clean Py Install: " $cleanpy
    Write-Host "- Offline Package: " $offline

    # If -cleanpy is specified, try to remove python
    if ($cleanpy -and (-not $offline)) {
        try {
            Remove-Python
        } catch {
            $errmsg = "- Failed to completely remove python... "
            Print-Color $errmsg red
            $warnings.Add($errmsg)
        }
    }

    # Create the necessary install directories
    Banner -message "Creating UST Directory"
    $USTFolder = Set-Directories

    # The setup process begins here.  Each chunk is run in a try/catch structure in order
    # to maintain clean program flow and handle exceptions.  The end goal is for the script to
    # run no matter what, doing its best to produce a usable environment, even if some elements
    # still require manual setup afterwards.

    # Some 3rd party utilities are downloaded automatically.  Portable versions are used in order
    # to maintain a least intrusive process.  7-Zip is a required element that is needed to
    # extract the UST related files and UST itself.  Notepad++ is highly recommended as a free
    # application for editing the UST configuration files (as compared to the native notepad) 
    # and is automatically included as a standalone application which can be simply deleted 
    # after UST is setup.

    Banner -message "Download Utilities"
    try    {
        Write-Host "- Downloading Notepad++..."
        Get-Util $notepadURL "$USTFolder\Utils\Notepad++\" | Out-Null
    } catch {
        Print-Color "- Failed to download Notepad++ resources with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }

    try    {
        Write-Host "- Downloading 7-Zip..."
        $7zpath = Get-Util $7ZipURL "$USTFolder\Utils\"
        $7zpath = "$7zpath\7-Zip\7z.exe"
    } catch {
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())

        if (Test-Path "$USTFolder\Utils\7-Zip\7z.exe") {
            $7zpath = "$USTFolder\Utils\7-Zip\7z.exe"
        } else {
            throw "Error getting 7zip, setup cannot continue... "
            exit
        }
    }

    # Initiate the python installation, unless the "none" option was used, in which case the script
    # will skip python installation completely.
    
    try    {
        if ($pythonversion -ne "none"){
            $pythonversion = Get-Python
        }
    } catch {
        Banner -type Error
        Print-Color "- Failed to install Python with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }

    # Get UST and the related files

    try    {
        Get-USTFiles
    } catch {
        Banner -type Error
        Print-Color "- Failed to download UST resources with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }

    # Downloading the openSSL files - a loop is used because connection occasionally fails the first time.  After 5 failures, the
    # loop will automaticall terminate.

    Banner -message "Download OpenSSL"
    $i = 0
    while ($true)  {
        $i++
        try {
            $openSSLUSTFolder = Get-OpenSSL
            $openSSLUSTFolder = ([String]$openSSLUSTFolder).Trim()
            break
        }
        catch {
            Print-Color "- Connection failed... retrying... ctrl-c to abort..." Yellow
        }
        if ($i -eq 5) {
            Banner -type Warning
            $errmsg = "- Open SSL failed to download... retry or download manually..."
            Print-Color $errmsg red
            $warnings.Add($errmsg)
            break
        }
    }

    # Finalize the installation by creating the batch scripts as described above.
    try  {
        Banner -message "Create Batch Scripts"
        Finalize-Installation $openSSLUSTFolder
    } catch {
        Banner -type Error
        Print-Color "- Failed to create batch files with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }


    ####################################
    # REMOVE FROM PROD VERSION
    ####################################

    # User Sync Test Files
    # This small block runs if the flag -test was specified at runtime.  It retrieves preconfigured .yml files for the perficientads.com
    # directory and replaces the defaults with them.  This allows you to run the script, and then immediately cd into the install directory
    # and run User-Sync.  This is a good way to make sure everything has indeed installed correctly and User-Sync runs on the current
    # platform.  This information is not intended for release to public, and will be stripped out from versions moving to the primary public
    # repository (yet to be defined).  The entry flag of -test should also be removed.

    if ($test) {
        Print-Color "- Getting test mode files... " blue
        $download = "https://github.com/janssenda-adobe/UST-Install-Scripts/raw/master/Util/utilities.tar.gz"
        $downloadfile = "${PWD}\utilities.tar.gz"
        $wc = New-Object net.webclient
        $wc.DownloadFile($download, $downloadfile)

        if (Test-Path $downloadfile)
        {
            #Extract downloaded file to UST Folder
            Write-Host "- Extracting $downloadfile to $USTFolder"
            Expand-Archive -Path $downloadfile -Output $USTFolder
            Remove-Item -Path $downloadfile -Recurse -Confirm:$false -Force
        }
    }
    #####################################


    # If the -offline mode was called at runtime, the packager is run at this point.  The packager gathers up the install directory and builds
    # a package archive (see the package function above).  The archive can be easily deployed on a target machine that may not have the rights
    # or network access to run this script.

    if ($offline) { Package  }

    # Remove the temporary folder(s)
    Cleanup

    Banner -message "Install Finish" -color Blue

    # Along the way, the script collects any exceptions or warnings produced into the $warnings array.  Here, we check if the array contains any
    # elements, and if so we print them out along with a warning message.
    if ($warnings.Count -gt 0){
        Print-Color "- Install completed with some warnings: " yellow

        foreach($w in $warnings){
            Print-Color "$w" red
        }
        Write-Host ""
    }

    Write-Host "- Completed - You can begin to edit configuration files in:`n"
    Print-Color "  $USTFolder" Green
    Write-Host ""

# This script must be elevated to run succesfully
}else{
    Write-host "Not elevated. Re-run the script with elevated permission"
}


