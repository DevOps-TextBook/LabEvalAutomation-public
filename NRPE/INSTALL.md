# Installation guide - NRPE
This file serves as a guide on how to install and configure the NRPE agents.

## Prerequisites/Versions
This system is running on the following versions and has not been tested with others:
* OS: Linux Ubuntu Version 22.04;

## Installation
Firstly, download the installation script (NB! subject to change: maybe compile the script file).<br>
Then add execution rights for the user for the script. <br>
And last but not least, run it and pass the Nagios Core public ip to it as an argument. This will allow the script to configure the Nagios Core as a trusted IP.
``` 
$ wget --no-check-certificate -O install.sh https://raw.githubusercontent.com/DevOps-TextBook/LabEvalAutomation-public/main/install.sh
$ sudo chmod u+x install.sh
$ sudo ./install.sh 172.17.89.137
``` 
Finally, make the nagios account a sudoer, so it can properly activate commands. <br>
For that activate the following command.
``` 
$ sudo visudo
``` 
And add the following lines to the end of the opened file.
``` 
Defaults:nagios !requiretty
nagios  ALL=(ALL) NOPASSWD: ALL
``` 