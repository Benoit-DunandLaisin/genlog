#!/bin/sh
# Receive a raw log from standard input
# Send it with the specified module (ie. the symlink name that point the sendto symlink, which itself point the core.sh)
# Write raw log to standard output

_fire_message ()
{   # This function must be used to write incoming message to output (and continue process chain)
    printf "$*\n" >&1
}

_on_init ()
{   # This function is called on initialization of the module
    # It must be overloaded inside module scripts
    # Given parameters are scripts $*
    # If return value is different from 0, then _on_log won't be called

    if [ -z "${submodule}" ]
    then
        _error "Wrong install. No sendto module given."
    else
        _error "The sendto module '${submodule}' doesn't exists."
    fi
    _error "Hit Ctrl+C to quit."
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

if [ -z "${module}" ]
then
    printf "\033[0;31m[sendto] The sendto script cannot be called directly, but only through symlink.\033[0;0m\n" >&2
    exit 1
fi
if [ -n "${submodule}" ]
then
    . "${basedir}/bin/send_to/${submodule}".sh 2>/dev/null
fi

_on_init $*
init_status=$?

while read log
do
    test ${init_status} = 0 && _on_log $log || _fire_message "$log"
done <&0
_on_stop
exit 0

