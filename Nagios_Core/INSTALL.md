# Installation guide - Nagios Core
This file serves as a guide on how to install Nagios Core and the virtual machine info getting service so that everything works correctly.

## Prerequisites/Versions
This system is running on the following versions and has not been tested with others:
* OS: Linux Ubuntu Version 22.04;

## Installation
Create and copy SSH keys.<br>
Copy the SSH key to your GitHub account that has read access to the repository.
``` 
$ ssh-keygen
$ cat /home/ubuntu/.ssh/id_rsa.pub
``` 
Clone the git project and enter it.
``` 
$ git clone git@github.com:DevOps-TextBook/LabEvalAutomation.git
$ cd LabEvalAutomation/
``` 
Run install_service.sh
``` 
$ sudo bash install_service.sh
``` 
When prompted, give your ETAIS api key (this has to be updated in the "LabEvalAutomation/check-for-vms/key" file, when changed).<br>
When prompted, give the password you wish to have for your NagiosCore. <br>
The default username is nagiosadmin. <br>
<br>
Now we need to restart Apache and start nagios
``` 
$ sudo systemctl restart apache2.service
$ sudo systemctl start nagios.service
``` 
Next up it is needed to install the plugins.<br>
Run install_plugins.sh
``` 
$ sudo bash install_plugins.sh
```
And now we must restart the nagios service
``` 
$ sudo systemctl restart nagios.service
``` 
Next up it is needed to install NRPE plugin.<br>
Run install_nrpe.sh
``` 
$ sudo bash install_nrpe.sh
``` 
We should also add the config files to nagios config. <br>
Run add_configs.sh
``` 
$ sudo bash add_configs.sh
``` 
Finally we need to set up a cronjob, that updates the students list.<br>
Also the update script should be executable.
``` 
$ sudo chmod u+x run_get_students.sh
$ { sudo crontab -l; echo "*/5 * * * * cd /home/ubuntu/LabEvalAutomation && ./run_get_students.sh"; } | sudo crontab -
``` 

#### CI/CD (optional)
As a conveniece, you can also set up the CI/CD script. <br>
It is a script that runs git pull, then restarts the nagios service
``` 
$ sudo chmod u+x ci-cd.sh
$ sudo crontab -e
``` 
And copy the following in there
``` 
*/1 * * * * echo "$(su -s /bin/sh ubuntu -c 'cd ~/LabEvalAutomation && /usr/bin/git pull && echo')" | /home/ubuntu/LabEvaluation/ci-cd.sh
``` 