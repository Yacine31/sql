#!/bin/bash
#. /home/oracle/.bash_profile

# Find the FULL path of the script, and add the directory it is in to the PATH,
# Thus effectively allowing all ohter scripts to be used
# (They shoud be in the same directory....)
MYFULLNAME="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
MYDIR=`dirname ${MYFULLNAME}`
PATH=${PATH}:${MYDIR} 
MYNAME=`basename ${0}`

LANG=C
#############
test_instance()
{
        ps -ef | grep pmon_${ORACLE_SID} | grep -v grep | grep -- ${ORACLE_SID} >/dev/null
        if [ $? -eq 1 ]; then
                return 1
        else
                return 0
        fi
}

usage()
{
cat << EOF
usage: ${MYNAME} options

This script purges the listener's logfile(s)

OPTIONS:
   -h      Show this message
   -l      Listener name (default LISTENER)
   -k      Keeptime: Keep the last 'n' days of files (Default: 60 days)
   -v      Verbose
   -d      Dry-run: only list the files, do not actually delete them.
EOF
}

LISTENERS_LIST=
KEEPTIME=60
CMD="rm"
DRY=0

while getopts "hdvl:k:" OPTION; do
        case ${OPTION} in
          h)
                usage
                exit 0
                ;;
          l)
                LISTENERS_LIST=${OPTARG}
                ;;
          v)
                VERBOSE=1
                ;;
          d)
                CMD="ls"
		DRY=1
                ;;
          k)
                KEEPTIME=${OPTARG}
		;;
          ?)
                usage
                exit 0
                ;;
        esac
done

if [ -z ${LISTENERS_LIST} ];
then
	# No listener given?  Catch them all!
	LISTENERS_LIST=`ps -ef | grep tnslsnr | grep -v grep |awk '{ print $9 }'`
	if [[ $VERBOSE -ne 0 ]];
	then
		echo "Currently active listeners:
${LISTENERS_LIST}."
	fi
fi

for LISTENER in ${LISTENERS_LIST};
do
	if [[ $VERBOSE -ne 0 ]]; then
		echo "Treating listener ${LISTENER}:"
	fi
	
	# Fetching the ORACLE_HOME for the listener, based on the executable's name...
	OH_BIN=`ps -ef | grep "tnslsnr ${LISTENER} " | grep -v grep | awk '{ print $8 }'`
	OH_BIN=`dirname ${OH_BIN}`
	export ORACLE_HOME=`dirname ${OH_BIN}`
	if [[ $VERBOSE -ne 0 ]]; 
	then
		echo "The ORACLE_HOME is ${ORACLE_HOME}"
	fi
	if ${ORACLE_HOME}/bin/lsnrctl status ${LISTENER} >/dev/null 2>&1 ;
	then
		LOGFILE=`${ORACLE_HOME}/bin/lsnrctl status ${LISTENER} | grep "^Listener Log File" | awk '{print $4}'`
		BASE=`basename ${LOGFILE}`
		DIR=`dirname ${LOGFILE}`
	
		if [[ ${BASE} == "log.xml" ]]; then
			VERSION=11
		else
			VERSION=10
		fi
	
		if [[ $VERBOSE -ne 0 ]]; then
			PRINT="-print "
			echo "this is a v${VERSION} listener, with logfile ${BASE} in ${DIR}." 
		else
			PRINT=""
		fi
	
		if [[ ${VERSION} -eq 11 ]];
		then
			# Purge the lingering *.xlm logfiles in there
			find ${DIR} -name "log_*.xml" -mtime +${KEEPTIME} ${PRINT} -exec ${CMD} {} \;
	
			# now forge the ${DIR} into some v10 compatible one:
			DIR=`dirname ${DIR}`/trace
			# and ${LOGFILE} as well:
			# First some magic to get the filename (Oracls ${DIR} | grep -i ${LISTENER}".log$"le uses lowercase sometimes)
			LOGFILE=`ls ${DIR} | grep -i ${LISTENER}".log$"`
			# And prepend the directory's name
			LOGFILE=${DIR}"/"${LOGFILE}
			# And continue as if we were in v10...
			BASE=`basename ${LOGFILE}`
			DIR=`dirname ${LOGFILE}`
		fi
	
		# Copy the listener*.log 
		DATETIME=`date +%Y%m%d_%H%M%S` 
		if [[ $VERBOSE -ne 0 ]]; then
			echo "Saving ${LOGFILE} to ${LOGFILE}_${DATETIME}"
		fi
		if [[ ${DRY} -eq 0 ]]; then
			cp ${LOGFILE} ${LOGFILE}_${DATETIME} && > ${LOGFILE}
		else
			echo "Would have moved ${LOGFILE} to ${LOGFILE}_${DATETIME}, and truncated ${LOGFILE}".
		fi
		
		find ${DIR} -name "${BASE}_*" -mtime +${KEEPTIME} ${PRINT} -exec ${CMD} {} \;
	else
		echo "Listener ${LISTENER} not responding."
	fi
done
