genlog
=========

Just a random log generator.

It assembles entries from different files to make random messages, displayed in standard output.

Notifications can be displayed in error output.

It now comes with send_to modules that can be piped to genlog and can send logs with special stuff (like curl).

Multiple send_to modules can be chained

# Installation
    sh ./bin/install.sh

This command will ensure execution rights are positionned and will create necessary symlinks.

# Genlog
## Detailled description
### Main algorithm
For n occurs do:

 - pick on line in each given files
 - write the assembled message in standard output

Optionnaly, each n occurs, perform a special treatment wich allow, for example, to send an aggregated message.

### Profile description
A profile must contains:

 - a *.sh file which overload some functions
 - n *.txt files which contain, in fact, assigned shell variables.

One of the assigned variables must be named _MESSAGE_. This is the one which will be printed in standard output.

Overloadable functions are:

 - \_on\_init
 - \_on\_stop
 - \_on\_log
 - \_on\_batch_full

See default profile as an example.

## Current profiles
### default

The generator launches two types of log which are:

 - raw log wich join a user, a message/code and a numerical value in range [0 TO 20].
 - aggregated event which show statistical informations of the last batch raw logs.

uid.list can be modified in 'uid.lst'

message/code.list can be modified in 'messages.lst'

A logstash configuration file is given as an example to feed an elasticsearch database.

### cw
Another example of a simple generator.

## Usage
    genlog.sh [-h] [-m <int_value>] [-t <decimal_value>] [-b <int_value> [-r]] [-p <profile>])
      -m: Number of raw log to fire (Default is 5000)
      -t: Sleep time between each raw log (Default is 0.5 seconds)
      -b: batch size (default is none). Perform a special action each time the batch size is reached.
      -r: Randomize batch size (b is mandatory and its value will be the maximum random value).
      -p: Profile name. Must match a directory name under resources (Default is default).

# Send_to modules
## to_file
### Description
An example that write log in a file.

### Usage
    to_file [-h] -f <file path>
      -f: file path where to write raw log.

### Invocation example
    genlog | to_file -f example.log

## to_curl
### Description
A module that send log via curl (for instance to elasticsearch).

### Usage
    to_curl [-h] [-x PUT|POST|GET] -u <url>
      -X: request type (default: GET).
      -u: target URL.

### Invocation example
    genlog | to_file -f example.log | to_curl -X POST -u http://elasticsearch:9200/myindex/type1

# Development
Please install local hook for pre-commit by running:

    ln -s ../../.utils/pre-commit.sh ./.git/hooks/pre-commit

Before a commit, please run ./.utils/check.sh

