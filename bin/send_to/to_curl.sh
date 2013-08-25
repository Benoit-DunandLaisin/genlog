#!/bin/sh

_on_init ()
{   # This function is called on initialization of the module
    # Given parameters are scripts $*

    while getopts hX:u: flag; do
        case ${flag} in
            h)
                _print "usage: to_curl [-h] [-X PUT|POST|GET] -u <url>"
                _print "  -X: request type (default: GET)."
                _print "  -u: target URL."
                exit 0
                ;;
            X)  request_type=$OPTARG;;
            u)  url=$OPTARG;;
        esac
    done

    which curl 2>&1 1>/dev/null
    if [ $? != 0 ]
    then
        _error "Curl is not installed and is mandatory."
        return 1
    fi

    if [ "${request_type}" != "PUT" -a "${request_type}" != "GET" -a "${request_type}" != "POST" ]
    then
        _info "Request type set to GET."
        request_type="GET"
    fi
    if [ -z "${url}" ]
    then
        _error "An URL is mandatory."
        return 1
    fi

    (curl ${url} 2>&1) >/dev/null
    if [ $? = 0 ]
    then
        _info "Curl correctly connects to ${url}."
    else
        _error "Curl can't connect to ${url}."
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
    _fire_message "$*"
    curl -sS -X${request_type} ${url} -d "$*" \
    -w "http_code=%{http_code} ; time_connect=%{time_connect} ; time_pretransfer=%{time_pretransfer} ; time_total=%{time_total}\n"\
    -o /dev/null >> ${log_dir}/${module_log_name}.stats
    return 0
}

