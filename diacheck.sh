#!/bin/sh
#edit by liuhuan@ebupt.com
##-------------------------variable----------------------##
#servername
user=`whoami`
DIR=`pwd`
#serverID=`ps -ef | grep diameterfep | grep $user | awk '{print $10}' | sed '/^$/d' | sed -n '1p'`
SERVERNAME=`sed -n "/<domain id=${DOMAINID}/,/<\/domain>/p" $DIAMETERFEPDIR/etc/config.comm | grep "INTER"  | awk '{print $3}' | awk -F "=" '{print $2}'`

#echo $serverID
#case $serverID in
#        51) SERVERNAME=INTERHCG
#                ;;
#        52) SERVERNAME=INTERHSS
#                ;;
#        53) SERVERNAME=INTERINGW
#                ;;
#        54) SERVERNAME=INTERDSGW
#                ;;
#esac



ETC=$HOME/diameter/etc
LOG=$HOME/diameter/log/
result=result
DIACHECK=$user@diameterfepcheck
#SERVERNAME="fe=INTERDSGW"
ERROR_LIST=error_list

#name of diameterfep
#FENAME=`grep "$SERVERNAME" $DIAMETERFEPDIR/etc/config.comm | awk '{print $3}' | awk -F "=" '{print $2}' | grep INTER`
FENAME=$SERVERNAME

#initialnumber
#INITIALNUM=`grep "fe=INTER*" $DIAMETERFEPDIR/etc/config.comm | awk '{print $6}' | awk -F "=" '{print $2}'`
#INITIALNUM=`grep "fe=$SERVERNAME" $DIAMETERFEPDIR/etc/config.comm | awk '{print $6}' | awk -F "=" '{print $2}'`
INITIALNUM=` sed -n "/<domain id=${DOMAINID}/,/<\/domain>/p" $DIAMETERFEPDIR/etc/config.comm | grep "INTER" | awk '{print $6}' | awk -F "=" '{print $2}'`

#startinstance
#STARTNUM=`grep "fe=INTER*" $DIAMETERFEPDIR/etc/config.comm | awk '{print $4}' | awk -F "=" '{print $2}'`
#STARTNUM=`grep "fe=$SERVERNAME" $DIAMETERFEPDIR/etc/config.comm | awk '{print $4}' | awk -F "=" '{print $2}'`
STARTNUM=`sed -n "/<domain id=${DOMAINID}/,/<\/domain>/p" $DIAMETERFEPDIR/etc/config.comm   | grep "INTER" | awk '{print $4}' | awk -F "=" '{print $2}'`

COREFILE=`find $HOME -name *core*`
echo $COREFILE

##-------------------------variable end----------------------##



#-----------------------function-------------------------##
i=0
while ( test "$i" -lt "$INITIALNUM" )
do
	server_log[$i]=$LOG$FENAME$DOMAINID.$STARTNUM.log 
	i=$(( $i+1 ))
	STARTNUM=$(($STARTNUM+1))
done

LINE ()
{
	echo 
	echo "##-------------------line----------------------------##"
	echo 
}
read_file ()
{
echo "*********************************************************************************************************" >> $2
echo "$1 " >> $2

if [  -s $1 ]
then 
   lines=`sed -n '$=' $1`
   if ( test "$lines" -lt "200" )
   then
      cat $1 >> $2

   else
      lines=`expr $lines - 199`
      sed -n "${lines},$"p $1 >> $2
   fi

else
   echo "!!!!!!!!!!!!!!!!!!!!file $1 does not exist or it's a empty file!!!!!!!!!!!!!!!!!!" >> $2 
fi

}

read_log () 
{

echo "##########################################################################################################" >> $result
echo "log of diaresult " >> $result


for diaserver_logs in ${server_log[*]}
do
	read_file $diaserver_logs $result

    
done

read_file ${LOG}diameterinit$DOMAINID.1.log $result
read_file ${LOG}alarm.diameterfep.log $result
}


print_error ()
{
#ERROR=`grep ERROR $1 | sed -n '1p' | awk '{print $1}' | awk -F ":" '{print $4}'`
if [ ! -e $1 ]
then
	echo "******************$1*****************************" >>$result
	echo "the $1 is empty or exist" >> $result
	return
else
	ERROR=`grep ERROR $1 | sed -n '1p' | awk '{print $1}' | awk -F ":" '{print $4}'`
fi
if [ -z $ERROR ]
then
	echo "******************$1**************************" >> $result
	echo "ok" >> $result
	return
fi

if [ $ERROR = ERROR1 -o  $ERROR  = ERROR2 -o $ERROR  = ERROR3 -o $ERROR  = ERROR4 ]
then
	echo "*****************$1**********************" >> $result
	echo  "error" >> $result 
	
	echo "***************$1**********************" >> $ERROR_LIST
	grep "ERROR" $1 | tail -n 200 >> $ERROR_LIST
else
	echo "***************$1**************************" >> $result
	echo "ok" >> $result
fi
	
}

is_ok ()
{
	for error_log in ${server_log[*]}
	do
		#echo "********************$error_log******************"  
		#echo	  
		print_error $error_log 
	done
	error_log=${LOG}diameterinit$DOMAINID.1.log
#	echo "************************diameterinit$DOMAINID.1.log***********************"
	print_error $error_log
#	echo "***********************ininit$DOMAINID.1.log******************************"
	error_log=${LOG}ininit$DOMAINID.1.log
	print_error $error_log

}
#is_ok > error




##----------------------function end--------------------------------##
{
LINE
echo -n "date: "
date +%Y%m%d

echo -n "time: "
date +%X
echo -n "\$user: "
whoami
echo
LINE
echo "*************************diameterfep process*****************************"
echo "************************initialnumber***************************************"
ps -ef | grep diameter | grep `whoami` | sed '/grep/d'
ps -ef | grep inaccessd | grep `whoami` | sed '/grep/d'
if [ -e $DIACHECK ]
then
	rm -rf $DIACHECK 
fi

cd $DIR

mkdir $DIACHECK 
mkdir $DIACHECK/config

LINE
echo "########environment variable###########" 
echo 
env | grep '^HOME\|DIAMETERFEPDIR\|DOMAINID\|CLUSTER'
LINE
#copy configuration file
cp -r $ETC/config.* $DIR/$DIACHECK/config
cp $ETC/CER.dat $DIR/$DIACHECK/config
cp $ETC/dictionary.xml $DIR/$DIACHECK/config
cp $ETC/numbertab $DIR/$DIACHECK/config
echo "code version"

cd $HOME/diameter/bin
strings  -a diameterfep | grep '$Name'
LINE

cd $DIR

echo "######core file###### "
if [ -e $COREFILE ]
then
    echo "core is exist."
    echo "$COREFILE"
else
    echo "core is not exist."
fi
LINE
cd $DIR

} >> $result
is_ok 
read_log
mv $ERROR_LIST $DIR/$DIACHECK 
mv $result $DIR/$DIACHECK

exit 0



