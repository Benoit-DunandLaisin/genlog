#!/bin/sh
# Check the validity of the files
#

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
curdir=`pwd`
cd ${initdir}

. ${curdir}/functions.sh || exit 1
topdir=`getProjectDir`

echo "Project directory is ${topdir}"

echo ""
echo "### Trim files and change tabulation ###"
for file in `find ${topdir} -type f | grep -E '\.(sh|md)'`
do
    if [ -f $file ]
    then
        isInSubmodule "${file}"
        if [ $? -eq 1 ]
        then
            has_trailing_space "$file"
            if [ $? -eq 1 ]
            then
                echo "INFO: Remove trailing spaces from $file"
                trim $file
            fi
            has_tabulation "$file"
            if [ $? -eq 1 ]
            then
                echo "INFO: Change tabulation with spaces in $file"
                change_tabulation $file
            fi
        fi
    fi
done
echo ""
echo "Done"
exit 0

