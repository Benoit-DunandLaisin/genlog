#!/bin/sh
# Main core.
# It must not be called directly but through a symlink which name match an existing script in core's directory

# Some useful functions
timestamp() {
    echo `date -u +%Y-%m-%dT%H:%M:%S.%NZ | sed -e 's/[0-9][0-9][0-9][0-9][0-9][0-9]Z/Z/' -e 's/%N/000/'`
}
_print ()
{
    printf "%b[%s] [%s] $1\033[0;0m\n" "$2" "${module_log_name}" `timestamp` >&2
}
_info ()
{
    _print "Info: $*" "\033[0;34m"
}
_warning ()
{
    _print "Warning: $*" "\033[0;35m"
}
_error ()
{
    _print "Error: $*" "\033[0;31m"
}
_wait ()
{
    if [ -n "${child_to_wait}" ]
    then
        wait ${child_to_wait}
        return_value=$?
    else
        return_value=0
    fi
    child_to_wait=
    return ${return_value}
}
_child_to_wait ()
{
    test -n "${child_to_wait}" && child_to_wait="${child_to_wait} $*" || child_to_wait="$*"
}
_randomize ()
{
    awk "BEGIN{print (`od -vAn -N4 -tu4 < /dev/urandom` % $1) + 1}"
}
_on_sigint ()
{
    _error "Trap SIGINT signal" 2>&1 | tee ${log_name}_$$.2 >&2
    exit 1
}
_on_exit ()
{
    rm -f "${out}" "${err}"
    cat -v "${log_name}_$$" "${log_name}_$$.2" 2>/dev/null | sed -e "s/\^\[\[[^m]*m//g" > "${log_dir}/${log_name}"
    rm -f "${log_name}_$$" "${log_name}_$$.2" "${TMPDIR}/core.timestamp.$$"
}

TARGET=$0
chain_call=
initdir=`pwd`
# Resolve the symlink chain which lead to the current core script
while [ -L ${TARGET} ]
do
    cd "`dirname ${TARGET}`"
    TARGET=`basename ${TARGET}`
    chain_call="`basename ${TARGET} .sh`/${chain_call}"
    LINK=`ls -l ${TARGET}`
    TARGET=`echo ${LINK} | sed 's/^.* -> //'`
done
cd "`dirname ${TARGET}`" && cd ..
chain_call="`basename ${TARGET} .sh`/${chain_call}"

module=`echo "${chain_call}" | cut -d/ -f2`
if [ -z "${module}" ]
then
    module_log_name="core"
    _error "The core script cannot be called directly, but only through symlink."
    exit 1
fi
submodule=`echo "${chain_call}" | cut -d/ -f3`

TMPDIR="${TMPDIR:-/tmp}"

date -u +%Y%m%d_%H%M%S.%N | cut -b1-19 | sed -e 's/%N/000/' > "${TMPDIR}/core.timestamp.$$"

# Resolve the position of the current process in the piped chain (not fully trustable)
parent_pid=`ps -o ppid -p $$ --no-headers | sed 's/^[ \t]*\([0-9]*\).*$/\1/'`
chain_id=`ps -o "pid cmd" --ppid ${parent_pid} --no-headers | grep "/bin/sh" | sort | grep -n $$ | cut -d: -f1`
first_pid=`ps -o "pid cmd" --ppid ${parent_pid} --no-headers | grep "/bin/sh" | sort | head -n1 | sed 's/^[ \t]*\([0-9]*\).*$/\1/'`

basedir=`pwd`
baselog=`cat "${TMPDIR}/core.timestamp.${first_pid}" 2>/dev/null`
log_dir="${basedir}/logs/${baselog}"
test -d "${log_dir}" || mkdir -p "${log_dir}"
rm -f "${basedir}"/logs/latest
ln -s "./${baselog}" "${basedir}"/logs/latest

test -n "${submodule}" && module_log_name="${submodule}" || module_log_name="${module}"
module_log_name="${module_log_name}_${chain_id}"
log_name="${module_log_name}.log"

if [ -f "${basedir}/bin/${module}.sh" ]
then
    out="${TMPDIR}/core.out.$$"
    err="${TMPDIR}/core.err.$$"

    test -e "${out}" || mkfifo "${out}"
    test -e "${err}" || mkfifo "${err}"

    tee < "${out}" &
    tee "${log_name}_$$" < "${err}" >&2 &

    trap '_on_sigint' INT
    trap '_on_exit' EXIT

    (. "${basedir}/bin/${module}".sh) >"${out}" 2>"${err}"
    exit 0
else
    _error "Module '${module}' doesn't exist."
    exit 1
fi

