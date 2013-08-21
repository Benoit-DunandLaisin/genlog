#!/bin/sh
# pre-commit git hook to check the validity of the scripts
#
# Install:
#  ln -s /path/to/repo/.utils/pre-commit.sh /path/to/repo/.git/hooks/pre-comit

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

syntax_is_bad=0
echo ""
echo "### Trim files and change tabulation ###"
for file in `git diff --name-only --cached | grep -E '\.(sh|md)'`
do
    if [ -f $file ]
    then
        has_trailing_space $file
        if [ $? -eq 1 ]
        then
            echo "INFO: Remove trailing space from $file"
            syntax_is_bad=1
            trim $file
        fi
        has_tabulation "$file"
        if [ $? -eq 1 ]
        then
            echo "INFO: Change tabulation with spaces in $file"
            change_tabulation $file
        fi
    fi
done
echo ""

if [ $syntax_is_bad -eq 1 ]
then
    echo "FATAL: Some files have been modified. Please add them and commit again."
    echo "Bailing"
    exit 1
else
    echo "Trim is good"
fi
exit 0

