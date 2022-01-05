import os
import subprocess
import sys
import platform

#if Windows
if platform.system() == 'Windows':
    
    #check for NPM installer.
    NPM_installer = subprocess.check_output('Powershell.exe test-path c:\\npm.msi')
    #if NPM installer file does not exist.
    if NPM_installer == False:
        #download NPM
        os.system('Powershell.exe Invoke-WebRequest -Uri "https://nodejs.org/dist/v16.13.1/node-v16.13.1-x64.msi" -OutFile "c:\\npm.msi"')
        #install NPM
        subprocess.check_output('Powershell.exe MsiExec.exe /i npm.msi /qn')
        #install cloc
        os.system('npm install -g cloc')
if platform.system() == 'Linux':
    #Just made it for debian
    os.system('sudo apt-get install python3 >/dev/null')
    os.system('sudo apt-get install cloc >/dev/null')
    os.system('sudo apt-get install git >/dev/null')

    


#try repo name, if its block throw exception         
try:
    repo_name = sys.argv[1]
except:
    print("Please enter your Repo name")
    sys.exit(1)
#try repo link, if its block throw exception         
try:
    repo_link = sys.argv[2]
except:
    print("Please enter your Repo link")
    sys.exit(1)

#clone latest code from link given.
os.system('git clone --depth 1 %s' %repo_link)

#get current working directory 
cwd = os.getcwd()
if platform.system() == 'Windows':
    #combines that with the repo name
    nwd = cwd + "\\" + repo_name
    #uses cloc program to search repo.
    cloc_command = 'cloc %s' %nwd
    os.system('Powershell.exe $output = %s ; $output' %cloc_command)
if platform.system() == 'Linux':
    
    path = cwd + "/" + repo_name + "/"
    #setting permissions open for everything, good for a demo not for real life. 
    os.system('chmod 777 %s' %path)
    #cloc command 
    cloc_command = 'cloc %s' %path
    os.system('%s ' %cloc_command)



