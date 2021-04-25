#/////////////////////////
#///////About Script//////
#/////////////////////////
<#
Author: Caleb M. Orvis
Reason: Needed to install/upgrade Forticlient VPN using internet resources only. 
Software: Forticlient VPN

Notes: 
Script must be run as system. 

The Forticlient VPN web installer, dumps the offline installer in the C:\Windows\Temp folder if run as System.
If the script is run as a different account, it will dump the installer in c:\users\user\appdata\temp\ thus breaking this script.  
#>
#/////////////////////////
#///////VARIABLES/////////
#/////////////////////////

#Gets battery Level, and inserts into variable.
$batteryLevel = (Get-WmiObject win32_battery).estimatedChargeRemaining

#Sets battery varible with battery properties
$battery = Get-WmiObject Win32_Battery

#Sets batteryStatus variable with the batteries status. 
$batteryStatus = $battery.BatteryStatus

#clearing parameter 
$Update = ""

#Pulls parameter from Ninja, if empty it just attempts to install, if you enter a parameter it will force updates if needed.
$ninjaParameter = $args[0]
$ninjaParameter = "Test"
#Software Name
$software = "FortiClient VPN"

#Forticlient VPN connection name.
$connectionName = "OrvisTech VPN"

#Forticlient VPN description name.
$description = "OrvisTech VPN"

#Forticlient VPN server address.
$serverAddress = "vpn.orvistech.com"

#company name.
$companyName = "OrvisTech"

#Minutes before shutdown
$minutesBeforeShutdown = 15

#/////////////////////////
#///////SETUP/////////////
#/////////////////////////
$time = 0
$install = 1
#download installer
Invoke-WebRequest "https://links.fortinet.com/forticlient/win/vpnagent" -OutFile C:\forticlientVPN.exe

#checking to see if its installed.
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null

#getting newest version info
#$version = get-childitem C:\ForticlientVPN.exe | foreach-object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
#$version = $version.Substring(0,3)

#/////////////////////////
#///////LAPTOPS///////////
#/////////////////////////

#if battery is less than 50% don't run. Therefore if battery is over 50% run. 
#if (50 -lt $batteryLevel) {}

#if there is a battery run this script
if(!$batteryStatus ) 
{

#### installing web installer.
Start-Process C:\forticlientVPN.exe

while (get-process forticlientVPN -ErrorAction SilentlyContinue) 
{
Start-Sleep -S 1
$time++ 
}


#if a parameter has been passed from Ninja 
if ($ninjaParameter)     
    { 
#checks if software is installed. If it is installed, it checks the version, if not it jumps to the installer script.   
     if ($installed) 
        { 
        $install = 0
        
        echo "Checking to see if it needs updated..."
        $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" 
        foreach($obj in $InstalledSoftware)
        {
            if($obj.GetValue('DisplayName') -eq "Forticlient VPN")
                {
                    $currentVersion = $obj.GetValue('DisplayVersion')
                    $currentVersion = $currentVersion.Substring(0,3)
                    $version = "5.16"
                    if($currentVersion -eq $version)
                        {
                  
                
                            #{exit}
                            Echo "Current version is up to date"
                            {exit}
                
                        }
                        else
                        {
                                echo "Uninstalling old version, and scheduling install on next reboot."
                                C:\Windows\Temp\FortiClientVPN.exe /quiet /norestart /uninstall
                                $update = 1
                                Start-Sleep -s 30
                       
                                #how to pass variables into a script  $var = "`$var = `"$var`""
                        
                                #### Creating a script: install_script.ps1 this script will run as System.
                                $connectionName = "`$connectionName = `"$connectionName`""
                                $description = "`$description = `"$description`""
                                $serverAddress = "`$serverAddress = `"$serverAddress`""
                                $install_scriptVar0 = 'cd "c:\Windows\Temp\"'
                                $install_scriptVar1 = '.\FortiClientVPN.exe /quiet /norestart'
                                $install_scriptVar2 = 'Start-Sleep -s 30'
                                $install_scriptVar3 = 'New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\" -Name Tunnels'
                                $install_scriptVar4 = 'New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\" -Name $connectionName' 
                                $install_scriptVar5 = 'New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name promptcertificate -Value 0 -PropertyType DWORD' 
                                $install_scriptVar6 = 'New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name promptusername -Value 1 -PropertyType DWORD' 
                                $install_scriptVar7 = 'Set-Itemproperty -path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name "description" -value $description'
                                $install_scriptVar8 = 'Set-Itemproperty -path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name "Server" -value $serverAddress'
                                $install_scriptVar9 = 'schtasks /Delete /TN "installVPN" /F'
                                $script1 = "
                                #This script uninstalls the software. 
                                $connectionName
                                $description
                                $serverAddress
                                $install_scriptVar0
                                $install_scriptVar1
                                $install_scriptVar2
                                $install_scriptVar3
                                $install_scriptVar4
                                $install_scriptVar5
                                $install_scriptVar6
                                $install_scriptVar7
                                $install_scriptVar8
                                $install_scriptVar9
                                "
                                mkdir c:\scripts
                                $script1 | out-file c:\scripts\install_script.ps1

                                #Creating a task to run install_script.ps1.

                                $taskname = "installVPN"
                                $taskdescription = "Installs VPN on reboot"
                                $action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
                                  -Argument '-ep Bypass -NoProfile -WindowStyle Hidden -command "c:\scripts\install_script.ps1"'
                                $trigger =  New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -minutes 3)
                                $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
                                Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Description $taskdescription -Settings $settings -User "System"
                                
                                
                                #pulling custom time.
                                $secondsBeforeshutdown = $minutesBeforeShutdown*60
                                if($minutesBeforeShutdown -gt 60)
                                {
                                $measurementOfTime = "hours"
                                $timeBeforeShutdown = $minutesBeforeShutdown/60
                                }
                                else
                                {
                                $measurementOfTime = "minutes"
                                $timeBeforeShutdown = $minutesBeforeShutdown
                                if($secondsBeforeshutdown -lt 60 )
                                {
                                $measurementOfTime = "seconds"
                                $timeBeforeShutdown = $secondsBeforeshutdown
                                }
                                }
                                $message = "Forticlient VPN is updating, your computer will reboot in " + $timeBeforeShutdown + " " + $measurementOfTime + "."
                                echo $secondsBeforeshutdown
                                #Restarting computer. 
                                shutdown /r /t $secondsBeforeshutdown /c $message



                                Suspend-BitLocker -MountPoint "c:\" -RebootCount 1
                                Start-Sleep -s 15
                                #### Creating a script: notifyUser.ps1
                                $timeBeforeShutdown = "`$timeBeforeShutdown = `"$timeBeforeShutdown`""
                                $measurementOfTime = "`$measurementOfTime = `"$measurementOfTime`""
                                $companyName = "`$companyName = `"$companyName`""
                                $notifyUserVar0 = 'Add-Type -AssemblyName System.Windows.Forms'
                                $notifyUserVar1 = '$var = "Your machine will reboot in " + $timeBeforeShutdown + " " + $measurementOfTime + ". Would you like to manually restart your computer later?"'
                                $notifyUserVar2 = '$topForm = New-Object System.Windows.Forms.Form'
                                $notifyUserVar3 = '$topForm.TopMost = $true #This makes the box always on top'
                                $notifyUserVar4 = '$answer = [System.Windows.Forms.MessageBox]::Show($topForm, $var,$companyName + " ITS","yesno","Warning")' 
                                $notifyUserVar5 = 'if($answer -eq "yes") {shutdown /a}'

                                $script1 = "
                                #This script uninstalls the software. 
                                $timeBeforeShutdown
                                $measurementOfTime
                                $companyName
                                $notifyUserVar0
                                $notifyUserVar1
                                $notifyUserVar2
                                $notifyUserVar3
                                $notifyUserVar4
                                $notifyUserVar5
                                "
                                $script1 | out-file c:\scripts\notifyUser.ps1


                                #Creating a task to run notifyUser.ps1 it will run as the group BUILTIN\USERS, any logged in user will see the script.

                                $Sta = New-ScheduledTaskAction powershell -argument "-ep Bypass -NoProfile -WindowStyle Hidden -command c:\scripts\notifyUser.ps1"
                                $STPrin = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users"
                                Register-ScheduledTask notifyUser -Action $Sta -Principal $STPrin
                                Start-ScheduledTask -TaskName "notifyUser"
                                schtasks /Delete /TN "notifyUser" /F
                                Start-Sleep -s 15
                                            }
                                    }
                              }
                        }
                        else
                        {
                        $install = 1
                        
                        }
        }
else { 



echo "Attempting to install."
If(!$installed -and $install -eq 1) 
{ 
    #install here
    MsiExec.exe /i "C:\Windows\Temp\FortiClientVPN.msi" /quiet /norestart
                    
    Start-Sleep -s 45
    New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\" -Name Tunnels
    New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\" -Name $connectionName
    New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name promptcertificate -Value 0 -PropertyType DWORD
    New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name promptusername -Value 1 -PropertyType DWORD
    Set-Itemproperty -path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name "description" -value $description
    Set-Itemproperty -path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$connectionName\" -Name "Server" -value $serverAddress
    echo $version + " installed"
        
    echo "Installed latest version."    
}
echo "Latest version already installed"
  
}

}
