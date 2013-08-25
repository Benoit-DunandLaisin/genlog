#!/bin/sh

_on_init ()
{   # This function is called on initialization of the module
    # Given parameters are scripts $*

    while getopts hf: flag; do
        case ${flag} in
            h)
                _print "usage: to_file [-h] -f <file path>"
                _print "  -f: file path where to write raw log."
                exit 0
                ;;
            f)  filepath=$OPTARG;;
        esac
    done

    if [ -z "${filepath}" ]
    then
        _error "A file path is mandatory."
        return 1
    else
        if [ "`echo "${filepath}" | cut -c1`" != "/" ]
        then
            filepath=${initdir}/${filepath}
        fi
        _info "Start appending to ${filepath}"
    fi

    return 0
}
_on_stop ()
{   # This function is called when all raw logs are processed
    # No parameter
    _info "End"
    return 0
}
_on_log ()
{   # This function is called for each raw log.
    # Given parameters are a raw log
    _fire_message "$*" | tee -a ${filepath}
    return 0
}

