#!/bin/sh
# log generator

_log ()
{
    echo "$MESSAGE"
}

_loadresources ()
{
    RESOURCES_FILE=${TMPDIR}/genlog_$$.resources.txt
    test -f "${RESOURCES_FILE}" || ls -1 "${profile_dir}/${profile_name}"/*.txt > "${RESOURCES_FILE}"
    while read resource
    do
        rname=`basename "${resource}" ".txt" | tr '-' '_'`
        eval "max_line=\${max_${rname}}"
        test -z "${max_line}" && max_line=`wc -l "${resource}" | sed 's/^[ \t]*//' | cut -d' ' -f1` && eval "export max_${rname}=\${max_line}"
        random_line=`_randomize ${max_line}`
        eval `sed -n -e "${random_line}p" -e "${random_line}q" "${resource}"`
    done < "${RESOURCES_FILE}"
}

_on_init ()
{   # This function is called right before entering the main loop
    # It must be overloaded inside profile scripts
    MESSAGE="[`timestamp`] [EVENT] START genlog"
    _info "START genlog"
    _log
    return 0
}
_on_stop ()
{   # This function is called right after exiting the main loop
    # It must be overload inside profile scripts
    _info "STOP genlog"
    MESSAGE="[`timestamp`] [EVENT] STOP genlog"
    _log
    return 0
}
_on_log ()
{   # This function is called right before each raw log is fired.
    # It must be overloaded inside profile scripts
    return 0
}
_on_batch_full ()
{   # This function is called right after n raw logs are fired
    # It must be overload inside profile scripts
    return 0
}
_on_sigint()
{   # This function is called if process is killed
    # It must be overload inside profile scripts
    MESSAGE="[`timestamp`] [EVENT] SIGINT genlog"
    _log
}

_genlog_sigint()
{
    _wait
    _on_sigint | tee -a "${generated_log}"
    exit 1
}

if [ -z "${module}" ]
then
    printf "\033[0;31m[genlog] The genlog script cannot be called directly, but only through symlink.\033[0;0m\n" >&2
    exit 1
fi

trap "_genlog_sigint" INT
trap "rm -f ${TMPDIR}/genlog_$$.*.txt" EXIT

profile_dir="${basedir}"/profiles
default_max_message=5000
default_sleep_duration=0.5
default_profile_name="default"
randomize_batch_size=

while getopts hrm:t:b:p: flag; do
    case ${flag} in
        h)
            _print "usage: genlog.sh [-h] [-m <int_value>] [-t <decimal_value>] [-b <int_value> [-r]] [-p <profile>])"
            _print "  -m: Number of raw log to fire (Default is ${default_max_message})"
            _print "  -t: Sleep time between each raw log (Default is ${default_sleep_duration})"
            _print "  -b: batch size (default is none). Perform a special action each time the batch size is reached."
            _print "  -r: Randomize batch size ('b' is mandatory and its value will be the maximum random value)."
            _print "  -p: Profile name. Must match a directory name under resources (Default is ${default_profile_name})."
            exit 0
            ;;
        m)  max_occurs=$OPTARG;;
        t)  sleep_duration=$OPTARG;;
        b)  batch_size=$OPTARG;;
        r)  randomize_batch_size=y;;
        p)  profile_name=$OPTARG;;
    esac
done

# Parameters check
test -z "${profile_name}"&& profile_name=${default_profile_name}
if [ -n "${profile_name}" -a ! -d "${profile_dir}/${profile_name}" ]
then
    _error "profile '${profile_name}' doesn't exist."
    profile_name=
fi
if [ -n "${max_occurs}" ]
then
    param_occurs=`echo "${max_occurs}" | sed -n '/^[0-9]*$/p'`
    if [ "${param_occurs}" != "${max_occurs}" ]
    then
        _warning "'m' value wasn't an integer. Max message will be set with default value."
        max_occurs=""
    fi
fi
if [ -n "${sleep_duration}" ]
then
    param_occurs=`echo "${sleep_duration}" | sed -n '/^[0-9]*[.0-9][0-9]*$/p'`
    if [ "${param_occurs}" != "${sleep_duration}" ]
    then
        _warning "'t' value wasn't a valid value. Sleep duration will be set with default value."
        sleep_duration=""
    fi
fi
if [ -n "${batch_size}" ]
then
    param_occurs=`echo "${batch_size}" | sed -n '/^[0-9]*$/p'`
    if [ "${param_occurs}" != "${batch_size}" ]
    then
        _warning "'b' value wasn't an integer. Batch treatment will be disabled."
        batch_size=""
    else
        if [ -z "${randomize_batch_size}" ]
        then
            current_batch_size=${batch_size}
        else
            current_batch_size=`_randomize ${batch_size}`
        fi
    fi
fi
if [ -n "${randomize_batch_size}" -a -z "${batch_size}" ]
then
    _warning "'r' parameter is set without a 'b' parameter. It will be ignored."
    randomize_batch_size=
fi

test -z "${profile_name}" && exit 1
test -z "${max_occurs}" && max_occurs=${default_max_message}
test -z "${sleep_duration}" && sleep_duration=${default_sleep_duration}

# Load profile
. "${profile_dir}/${profile_name}"/*.sh 2>/dev/null

_info "Profile is ${profile_name}."
_info "${max_occurs} raw logs will be fired each ${sleep_duration} seconds."
expected_duration=`awk "BEGIN{print (${max_occurs} - 1) * (${sleep_duration} + 0.01)}"`
_info "Expected duration is ${expected_duration} seconds."

rm -f "${log_dir}"/*
generated_log=${log_dir}/log.txt

starting_time=`date +%s%N | cut -b1-13 | sed -e 's/%N/000/'`
{
occur=0
batch_elt=0
_on_init
while [ ${occur} -lt ${max_occurs} ]
do
    occur=`expr ${occur} + 1`
    _wait &&  batch_elt=`expr ${batch_elt} + 1` || batch_elt=1
    if [ ${occur} -ne ${max_occurs} ]
    then
        sleep ${sleep_duration} &
        _child_to_wait $!
    fi
    (
        # This subshell have to exit 1 if _on_batch_full is fired
        TIMESTAMP=`timestamp`
        _on_log
        _loadresources
        _log
        if [ -n "${current_batch_size}" ]
        then
            if [ ${batch_elt} -ge ${current_batch_size} ]
            then
                _on_batch_full
                test -n "${randomize_batch_size}" && current_batch_size=`_randomize ${batch_size}`
                exit 1
            fi
        fi
        exit 0
    ) &
    _child_to_wait $!
done
_wait
if [ -n "${current_batch_size}" -a ${batch_elt} -eq 1 ]
then
    _on_batch_full
fi
_on_stop
} | tee "${generated_log}"
ending_time=`date +%s%N | cut -b1-13 | sed -e 's/%N/000/'`
reel_duration=`awk "BEGIN{print (${ending_time} - ${starting_time})/1000}"`
delta=`awk "BEGIN{print ${reel_duration} - ${expected_duration}}"`
_info "Finish job in ${reel_duration} seconds. Delta with expected duration is ${delta} seconds."
exit 0

