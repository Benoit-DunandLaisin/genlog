#!/bin/sh
# Install script for genlog

_info ()
{
    printf "$*\n"
}
_create_symlink ()
{   # $1: symlink | $2: target
    test -L "$1" && rm "$1"
    ln -s "$2" "$1"
}


TARGET=$0
initdir=`pwd`
if [ -L ${TARGET} ]
then
    LINK=`ls -l $0`
    TARGET=`echo ${LINK} |  sed 's/^.* -> //'`
    cd `dirname $0` && cd `dirname ${TARGET}`
else
    cd `dirname $0`
fi
basedir=`pwd`

_info "Set execution rights"
chmod u+x *.sh
chmod u+x send_to/*.sh

_info "Create main symlink"
_create_symlink ../genlog "./bin/core.sh"

_info "Create sendto symlink"
_create_symlink ./sendto "./core.sh"

_info "Create sendto modules symlinks"
for file in `ls ${basedir}/send_to | grep '.sh'`
do
    symname=`basename ${file} .sh`
    _info " - ${symname}"
    _create_symlink "../${symname}" "./bin/sendto"
done
_info "Done"
exit 0

