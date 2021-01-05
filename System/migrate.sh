#!/bin/bash
#
#Replace all occurence of old hostname on a copied VM
#Wrote by melkorounet
#Tested on centos 7
#

H=`hostname`
OldH=$1

if [[ -z "$1" ]]; then echo "Usage $0 {hostname_to_replace|help}"; exit 1; fi


migration() {

#searching for iterations of the old hostname in every folder and subfolder, ignoring logs
echo "checking for iterations of ${OldH}, ignoring logs files"
grep --exclude=catalina.out --exclude=*.log* -IlR "${OldH}"* * > /tmp/hostname_reference.txt

#checking the number of files found
NbFichiers=`wc -l /tmp/hostname_reference.txt | awk '{print $1}'`
echo "found iteration of ${OldH} in ${NbFichiers} files"

#replacing if necessary
if [ ${NbFichiers} = 0 ]
   then
      echo "nothing to do"
   else
      echo "replacing all iterations of ${OldH} by ${H}"
      cat /tmp/hostname_reference.txt | while read line
         do
	         sed -i 's/'${OldH}'/'${H}'/g' "${line}"
         done
      echo "replacement done"
fi
}

help() {
    echo "Usage $0 {hostname_to_replace|help}"
    echo "This script is designed to automatically replace all occurence of a character chain in all files by a new one"
    echo "Put the chain you want to replace in parameter and it will automatically replace it by the hostname of the machine"
}

function main {
   case "$1" in
      help)             # Prerequisite installation
         help
         ;;
      *)             # put in domain
         migration
         ;;
esac
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
