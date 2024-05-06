# NRPE - How It Works
The NRPE agent is really simple, it has the 5666/tcp port allocated to the NRPE service. If a trusted IP sends the check_nrpe, then the NRPE service will listen to it and respond according to configurations.

## Configurations
Usually, NRPE requires to have the check_something scripts on the monitored VM (the one running the NRPE daemon). This is most of the time fine, but in the current context, this is a flaw, that allows students to tamper with the response. The response indicates the result of the test, so ideally the machine that holds the NRPE agent, doesn't hold the scripts that check the student machines.

### Solution
Since each command that check_nrpe plugin runs, has to be defined in the NRPE configurations, then there is defined one extra command called "run_scripts".<br>
The "run_scripts" command will run the "/usr/bin/bash" script with the "-c" flag and an extra argument given by the Nagios Core machine. <br>
The "-c" flag stands for command. <br>
Since each Linux script runs on the bash environment (not always, depending on the system, but usually), then passing the script lines to the "/usr/bin/bash" script will result with the same output as running an equivalent bash script. <br>
The "-c" flag allows for executing the command defined after it, without entering the bash command-line.<br>
The resulting configuration line looks something like the following
``` 
command[run_script]=/usr/bin/bash -c $ARG1$
``` 
And it can be called with something like the following (NB! note the quotation marks for '\$ARG1\$').
``` 
$ /usr/local/nagios/libexec/check_nrpe -H $HOSTADDRESS$ -p 5666 -c run_script -a '$ARG1$'
```
To allow proper command passing to this, the following line should also be added to the configurations
```
nasty_metachars=ˇ
```
This will override the default nasty_metachars with "ˇ". The default nasty metachars do not allow to pass certain characters to the command and therefore not allow it to work. <br>
<br>
Finally, the nagios user is configured as a sudoer, since otherwise it cannot execute the scripts properly (this is usually the case even with default commands).

### Formatting checks
The guide on how to format checks is in the [Nagios Core - How It Works](../Nagios_Core/HOW_IT_WORKS.md) file.