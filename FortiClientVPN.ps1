#/////////////////////////
#///////VARIABLES/////////
#/////////////////////////

#Gets battery Level, and inserts into variable.
$batteryLevel = (Get-WmiObject win32_battery).estimatedChargeRemaining

#Sets battery varible with battery properties
$battery = Get-WmiObject Win32_Battery

#Sets batteryStatus variable with the batteries status. 
$batteryStatus = $battery.BatteryStatus

#/////////////////////////
#///////SETUP/////////////
#/////////////////////////
#download installer
Invoke-WebRequest "https://links.fortinet.com/forticlient/win/vpnagent" -OutFile C:\forticlientVPN.exe
$time = 0
$software = "FortiClient VPN";
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null
#/////////////////////////
#///////LAPTOPS///////////
#/////////////////////////

#if battery is less than 50% don't run. Therefore if battery is over 50% run. 
#if (50 -lt $batteryLevel) {}
if($batteryStatus ) 
{

#### installing web installer.
Start-Process C:\forticlientVPN.exe

while (get-process forticlientVPN)
{
Start-Sleep -S 1
$time++ 
}
echo $time "seconds to run web installer"

#### check to see what version is installed.
$version = get-childitem C:\ForticlientVPN.exe | foreach-object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }


$version = $version.Substring(0,3)
$InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" 
foreach($obj in $InstalledSoftware)
{
    if($obj.GetValue('DisplayName') -eq "Forticlient VPN")
        {
            $currentVersion = $obj.GetValue('DisplayVersion')
            $currentVersion = $currentVersion.Substring(0,3)
            if($currentVersion -eq $version)
                {
                  
                
                    #{exit}
                    Echo "Current version is up to date"
                    $update = 0
                
                }
                else
                {
                     MsiExec.exe /x "C:\Windows\Temp\FortiClientVPN.msi" /quiet /norestart
                     $update = 1
                     Start-Sleep -s 30
                     Echo "Old version uninstalled. Install set to occur on reboot scheduled for 10 minutes from now."
                }
        }
}



if($update -eq 1) 
{


    #### Creating install_script.ps1
    $uninstallVar0 = 'MsiExec.exe /i "C:\Windows\Temp\FortiClientVPN.msi" /quiet /norestart'
    $uninstallVar1 = 'Start-Sleep -s 30'
    $test = 'echo test > c:\log.txt'
    $uninstallVar2 = 'New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\" -Name Tunnels'
    $uninstallVar3 = 'New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\" -Name "Geneva College VPN"' 
    $uninstallVar4 = 'New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN" -Name promptcertificate -Value 0 -PropertyType DWORD' 
    $uninstallVar5 = 'New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN" -Name promptusername -Value 1 -PropertyType DWORD' 
    $uninstallVar6 = 'Set-Itemproperty -path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN\" -Name "Description" -value "Geneva College VPN"'
    $uninstallVar7 = 'Set-Itemproperty -path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN\" -Name "Server" -value "@yourVPNAddress"'
    $uninstallVar8 = 'schtasks /Delete /TN "installVPN" /F'
    $script1 = "
    #This script uninstalls the software. 
    $uninstallVar0
    $uninstallVar1
    $test
    $uninstallVar2
    $uninstallVar3
    $uninstallVar4
    $uninstallVar5
    $uninstallVar6
    $uninstallVar7
    $uninstallVar8
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

    #Restarting computer. 
    shutdown /r /t 600 /c "ForticlientVPN is updating, your computer will reboot in 10 minutes."
    Start-Sleep -s 15
    #### Creating notifyUser.ps1
    $uninstallVar0 = 'Add-Type -AssemblyName System.Windows.Forms'
    $uninstallVar1 = '$var = "Your machine will reboot in 10 minutes. Would you like to manually restart your computer later?"'
    $uninstallVar2 = '$topForm = New-Object System.Windows.Forms.Form'
    $uninstallVar3 = '$topForm.TopMost = $true #This makes the box always on top'
    $uninstallVar4 = '$answer = [System.Windows.Forms.MessageBox]::Show($topForm, $var,"Geneva College ITS","yesno","Warning")' 
    $uninstallVar5 = 'if($answer -eq "yes") {shutdown /a}'

    $script1 = "
    #This script uninstalls the software. 
    $uninstallVar0
    $uninstallVar1
    $uninstallVar2
    $uninstallVar3
    $uninstallVar4
    $uninstallVar5
    "
    $script1 | out-file c:\scripts\notifyUser.ps1


    #Creating a task to run notifyUser.ps1.

    $Sta = New-ScheduledTaskAction powershell -argument "-ep Bypass -NoProfile -WindowStyle Hidden -command c:\scripts\notifyUser.ps1"
    $STPrin = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users"
    Register-ScheduledTask notifyUser -Action $Sta -Principal $STPrin
    Start-ScheduledTask -TaskName "notifyUser"
    schtasks /Delete /TN "notifyUser" /F
    Start-Sleep -s 15

}


If(!$installed) 



{
    #install here
    MsiExec.exe /i "C:\Windows\Temp\FortiClientVPN.msi" /quiet /norestart
                    
    $time = 0 
    Start-Sleep -s 45
    echo $time "seconds to install software" 

    #Creates tunnels
    New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\" -Name Tunnels
    #Creates a tunnel
    New-Item -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\" -Name "Geneva College VPN" 

    #Creates several needed files, to configure the tunnel.  
    New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN" -Name promptcertificate -Value 0 -PropertyType DWORD 
    New-ItemProperty -Path "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN" -Name promptusername -Value 1 -PropertyType DWORD 
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN\' -Name 'Description' -value 'Geneva College VPN'
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Geneva College VPN\' -Name 'Server' -value '@yourVPNAddress'
}
    

}
#/////////////////////////
#///////Desktops//////////
#/////////////////////////

#checks if battery status is null, which is the case on any desktop. If its a desktop, with no battery the script executes. 
if(!$batteryStatus ){Echo "This is a desktop."}
        
