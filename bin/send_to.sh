#!/bin/sh
# Receive a raw log from standard input
# Send it with the secified module (ie. the symlink name)
# Write raw log to standard output

TARGET=$0
initdir=`pwd`
if [ -L ${TARGET} ]
then
    LINK=`ls -l $0`
    TARGET=`echo ${LINK} |  sed 's/^.* -> //'`
    cd `dirname $0` && cd `dirname ${TARGET}`
    module=`basename $0 .sh`
else
    cd `dirname $0`
fi
curdir=`pwd`

_info ()
{
    printf "[%s] $*\n" "${module}" >&2
}

_on_init ()
{   # This function is called on initialization of the module
    # It must be overloaded inside module scripts
    # Given parameters are scripts $*
    # If return value is different from 0, then _on_log won't be called

    if [ -z "${module}" ]
    then
        _info "Error: You mustn't call this script directly."
    else
        _info "Error: The sendto module '${module}' doesn't exists."
    fi
    _info "Error: Hit Ctrl+C to quit."
    return 1
}
_on_stop ()
{   # This function is called when all raw logs rae processed
    # It must be overload inside profile scripts
    # No parameter
    return 0
}
_on_log ()
{   # This function is called for each raw log.
    # It must be overloaded inside profile scripts
    # Given parameters are a raw log
    return 0
}

if [ -n "${module}" ]
then
    . "${curdir}/send_to/${module}".sh 2>/dev/null
fi

_on_init $*
init_status=$?
cat | while read log
do
    echo "$log" >&1
    test ${init_status} = 0 && _on_log $log >&2
done
_on_stop
exit 0

