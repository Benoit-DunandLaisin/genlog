#!/bin/sh
# Install script for genlog

_info ()
{
    printf "$*\n"
}

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

_info "Set execution rights"
chmod u+x *.sh
chmod u+x send_to/*.sh

_info "Create main symlink"
test -f ../genlog || ln -s ./bin/genlog.sh ../genlog

_info "Create modules symlinks"
for file in `ls ${curdir}/send_to | grep '.sh'`
do
    symname=`basename ${file} .sh`
    symlink=../${symname}
    _info " - ${symname}"
    test -f ${symlink} || ln -s ./bin/send_to.sh ${symlink}
done
_info "Done"
exit 0

