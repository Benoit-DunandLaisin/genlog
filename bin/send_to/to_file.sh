#!/bin/sh

_on_init ()
{   # This function is called on initialization of the module
    # Given parameters are scripts $*

    while getopts hf: flag; do
        case ${flag} in
            h)
                _info "usage: to_file [-h] -f <file path>"
                _info "  -f: file path where to write raw log."
                exit 0
                ;;
            f)  filepath=$OPTARG;;
        esac
    done

    if [ -z "${filepath}" ]
    then
        _info "ERROR: A file path is mandatory."
        return 1
    else
        if [ "`echo "${filepath}" | cut -c1`" != "/" ]
        then
            filepath=${initdir}/${filepath}
        fi
        _info "Info: Append to ${filepath}"
    fi

    return 0
}
_on_stop ()
{   # This function is called when all raw logs are processed
    # No parameter
    return 0
}
_on_log ()
{   # This function is called for each raw log.
    # Given parameters are a raw log
    echo "$*" >> ${filepath}
    return 0
}

