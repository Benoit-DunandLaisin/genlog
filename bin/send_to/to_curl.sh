#!/bin/sh

_on_init ()
{   # This function is called on initialization of the module
    # Given parameters are scripts $*

    while getopts hX:u: flag; do
        case ${flag} in
            h)
                _info "usage: to_curl [-h] [-x PUT|POST|GET] -u <url>"
                _info "  -X: request type (default: GET)."
                _info "  -u: target URL."
                exit 0
                ;;
            X)  request_type=$OPTARG;;
            u)  url=$OPTARG;;
        esac
    done

    which curl 2>&1 1>/dev/null
    if [ $? != 0 ]
    then
        _info "Error: Curl is not installed and is mandatory."
        return 1
    fi

    if [ "${request_type}" != "PUT" -a "${request_type}" != "GET" -a "${request_type}" != "POST" ]
    then
        _info "Info: Request type set to GET."
        request_type="GET"
    fi
    if [ -z "${url}" ]
    then
        _info "ERROR: An URL is mandatory."
        return 1
    fi

    (curl ${url} 2>&1) >/dev/null
    if [ $? = 0 ]
    then
        _info "Info: Curl correctly connects on URL."
    else
        _info "ERROR: Curl can't connect on URL."
        return 1
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
    curl -sS -X${request_type} ${url} -d "$*" 1>/dev/null
    return 0
}

