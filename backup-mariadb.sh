#!/bin/bash

WEEKDAY=`date +%w`
BACKUP_BASEDIR=/backup/mariadb
INC_BASEDIR=$BACKUP_BASEDIR/latest
if [ $WEEKDAY -eq 0 -o ! -e $INC_BASEDIR ] ; then
        FULL_BACKUP=Y
        TARGET_DIR=$BACKUP_BASEDIR/full-`date +%y%m%d`
else
        FULL_BACKUP=N
        TARGET_DIR=$BACKUP_BASEDIR/inc-`date +%y%m%d`
fi

if [ -d $TARGET_DIR ] ; then
        echo "ERROR! target dir $TARGET_DIR already exist!"
        exit 1
fi

mkdir $TARGET_DIR

if [ $FULL_BACKUP = Y ] ; then
        mariabackup --backup --target-dir=$TARGET_DIR --compress
else
        mariabackup --backup --target-dir=$TARGET_DIR --incremental-basedir=$INC_BASEDIR --compress
fi

if [ $? -eq 0 ] ; then
        rm $INC_BASEDIR
        ln -s ${TARGET_DIR##*/} $INC_BASEDIR

        if [ $WEEKDAY -eq 0 ] ; then
                # remove backup past 1 month ago
                d1=`date -d "4 weeks ago" +%y%m%d`
                for d in $BACKUP_BASEDIR/{full,inc}-* ; do
                        if [ -d $d -a ${d##*-} -lt $d1 ] ; then
                                rm -rf "$d"
                        fi
                done
        fi
fi
