# Nagios Core - How It Works
Unlike NRPE, the Nagios Core machine has many steps to it.

## Basics
Similarly to NRPE, the Nagios Core is also based on configuration files.<br>
To understand Nagios Core, the different types of configurations should be understood.

### Path configurations
* cfg_file=some_file.cfg - This is used to define additional configuration files, which Nagios will check.
    * In the current project, this is used to show where the base configurations and hosts (more on these later) are defined.
* cfg_dir=some_dir - This is used to define a directory, where all files ending with .cfg will be checked for configurations.
    * In the current project, this is used to show where the homework service (more on this later) configurations are defined.
### Configurations 
* host definitions have some fields that define how they work
    * name - the name that the host will have;
    * use - use some predefined host configuration;
    * hostgroups - what hostgroups this host belongs to;
    * check_period - what time period this host will be checked (24x7 means 24/7);
    * check_interval - how many minutes until the next check;
    * retry_interval - in case of an error, how many minutes until the next check;
    * max_check_attempts - in case of error, how many times will Nagios retry to check the machine;
    * check_command - the short name of the command that checks if the host is alive (check-host-alive);
    * notification_period - what time period the host will send out notifications to contacts;
    * notification_interval - the time between re-notifying contacts about problems, in minutes;
    * notification_options - flags, that define when to send notifications (d,r means when the host is d=DOWN and on r=RECOVERIES, which is the OK state);
    * address - the IP-address of the host.
* hostgroup definitons are used to apply services to all hosts in the hostgroup. These currently use 2 required values
    * hostgroup_name - name of the hostgroup;
    * alias - the alias of the hostgroup.
* service definitions are used to define, what tests should be run. The following fields are used
    * name - name of the service;
    * use - use some predefined service definition;
    * hostgroup_name - the hostgroup which this service applies to, each host in this hostgroup will be checked against this service;
    * service_description - the description of the service;
    * check_command - the command which is run when the service is called.
* command definitions are used to define the commands which the services can use, there are 2 fields that are used
    * command_name - name of the command;
    * command_line - the command that will be run when calling this command.

### Base configurations
are used to configure some baseline values to reduce repetition.
* base host definition (used for defining more hosts without having to specify many of the following values, including host_group)
    * name - base-host
    * use - generic-host (this is a Nagios built-in host definition)
    * hostgroups - base-hostgroup (this is the hostgroup that we run the services on)
    * check_period - 24x7
    * check_interval - 5
    * retry_interval - 1
    * max_check_attempts - 10
    * check_command - check-host-alive
    * notification_period - 24x7
    * notification_interval - 30
    * notification_options - d,r
* base hostgroup definition
    * hostgroup_name - base-hostgroup
    * alias - Base Hostgroup
* base service definition (used for defining new services without having to define the hostgroup)
    * name - base-service (placeholder name)
    * use - generic-service (this is a Nagios built-in service definition)
    * hostgroup_name - base-hostgroup (the hostgroup this service applies to, when using this service as a template later on, this field will be automatically used)
    * service_description - base-service (placeholder description)
    * check_command - check-host-alive (placeholder command)
* base command definition (this is the only command definition and used for passing the scripts to the NRPE, more on this later)
    * command_name - check_nrpe
    * command_line - /usr/local/nagios/libexec/check_nrpe -H \$HOSTADDRESS\$ -p 5666 -c run_script -a '\$ARG1\$'

### New host definition
The host definitons are automatically generated using the "LabEvalAutomation/check-for-vms/check_VMs_status.py", which is a script given by the supervisor Chinmaya Kumar Dehury, with slight modifications by the Thesis author Mihkel Hani. <br>
The script will use the key provided in the "LabEvalAutomation/check-for-vms/key" file and get the projects list from the ETAIS platform. There is also an exlcude_project_list list, where excluded projects should be defined (like the project containing the Nagios Core). <br>
For each project it will check for the VMs and get their names and IP-addresses. This can be further modified to check if the name matches a certain requirement (like master) so only certain machines are checked.<br>
The final host name used in the host definition is generated by combining the project name and machine name (example: Project1-Master).<br>
At the end this python script will generate a "students.cfg" file which contains all the host definitions that are needed to be checked. Using a cronjob (more on this later), this script will be called every five minutes and then the Nagios Core configurations updated (the changes must be enforced).


### Command definition
The command definition is a bit complicated, this is why there is a explanation.<br>
When defining a new service, which is supposed to check a NRPE agent, then the defined check_nrpe command should be used.<br>
Nagios by default cannot send a script file to the remote host, but it can pass arguments. Therefore, passing the command as an argument is the solution (also check the NRPE command definition: [NRPE - How It Works](../NRPE/HOW_IT_WORKS.md)).<br>
The check_nrpe command-line can be split into multiple parts:
* /usr/local/nagios/libexec/check_nrpe - the plugin/script that is used to execute this command;
* -H \$HOSTADDRESS\$ - an automatically replaced value, that matches the host's IP-address. Using this, Nagios knows where to send the check_nrpe call;
* -p 5666 - use the port 5666, which is opened in the NRPE configurations;
* -c run_script - run the command run_script, which is defined on the NRPE machine. More on this here: [NRPE - How It Works](../NRPE/HOW_IT_WORKS.md);
* -a '\$ARG1\$' - the argument passed to the check_nrpe command in the service definition. This will be the command script and passed to NRPE (Note the quotation marks!).

### New check/service definition
When creating a new check, the following format should be followed:<br>
insert_name.cfg:
``` 
define service {
        use     base-service
        service_description     Insert_name1
        check_command   check_nrpe!echo "OK - Everything fine"\;exit 0;
}
define service {
        use     base-service
        service_description     Insert_name2
        check_command   check_nrpe!echo "WARNING - Something may cause problems"\;exit 1;
}
define service {
        use     base-service
        service_description     Insert_name3
        check_command   check_nrpe!echo "CRITICAL - Not working"\;exit 2;
}
``` 
Note that:
* There is no limit to service definitions per file;
* There is a cronjob that updates configurations (more on this later) and therefore all config files should be in their designated directories (here LabEvalAutomation/homeworks);
* About the check_command field:
    * check_nrpe is the command called;
    * the exclamation mark separates arguments (-a '\$ARG1\$' is the first argument, -a '\$ARG1\$' '\$ARG2\$' would take 2 arguments, so we would have: check_nrpe!arg1!arg2);
    * Note that only 1 argument is being used, because run_command command takes one argument. The reason for that is that /usr/bin/bash -c takes 1 argument;
    * Note the exit character before the semicolon. This is necessary because a normal semicolon (such as the one at the end of the line), ends the line immediately (even when in a string like "CRITICAL - Not working; or something else");
    * Note that using '' marks will be replaced into the '\$ARG1\$' field and result in '''' which is 2 strings;
* Generally about services:
    * echo is used to display the responding message for the script, the field OK/WARNING/CRITICAL is not necessary and just a convention in Nagios, still recommended;
    * the exit status determines the result of the test, 2 being CRITICAL, 1 being WARNING and 0 being OK;
    * Since in the NRPE agent, this argument will be passed to the bash, then it substitutes as a bash script and everything that works with bash scripts, should work with this, except '' marks;
    * In case the character "ˇ" is wished to use, then the field nasty_metachars in the NRPE configurations (on the NRPE agent machine) should be changed.

## Cronjobs
There are 2 cronjobs:
1. Host configurations updater (Necessary);
2. CI/CD (Unnecessary, but helps when updating configurations).

### Host configurations updater
This cronjob runs every 5 minutes (or depends on what you configure it to) and runs the script "run_get_students.sh".<br>
The script runs the python script "check_VMs_status.py", which creates a students.cfg file. Then it calls the "update_config_files.sh" script, which sends the config files in the "LabEvalAutomation/" directory to the "/usr/local/nagios/etc/objects/" directory, which is necessary because Nagios cannot recognize files in the "LabEvalAutomation/" directory. After that, it restarts the nagios.service, so that the updates are enforced. <br>
This is why the 2nd cronjob is unnecessary, since this also updates the configuration files, but there are 2 key points why this might be less comfortable when updating often:
1. It does not automatically git pull, which the 2nd one does;
2. The cronjob runs every 5 minutes, which might be a bit slow for testing purposes.

### CI/CD
This cronjob runs every minute (or depends on what you configure it to) and sends the git pull command using the ubuntu user (git is not advised to be configured using sudo access). Then it passes the output of the git pull to the "ci-cd.sh" script. This script checks if the output is "Already up to date" and when it is, it does nothing, otherwise it runs the "update_config_files.sh" script and restarts the nagios service.<br>
One might have noticed the && echo after the git pull in the cronjob (git pull && echo). The echo is there, because git pull will not return a value before it is already passed to the "ci-cd.sh" script. The "&& echo" command will force it to wait until git pull has finished.