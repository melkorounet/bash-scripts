#!/bin/bash
#
#Put new Vm into Active Directory Domain
#Write by Alexandre Paté
#Tested on Centos 7.0
#Version 0.1

if [[ -z "$1" ]]; then echo "Usage $0 {prerequisite|setup|help}"; exit 1; fi
#On verifie que la machine n'est pas déjà dans le domaine
if [[ "$domain" = "$(realm list --name-only)" ]]; then echo "The machine is already in $domain domain"; exit 1; fi
if [[ "root" != "$(whoami)" ]]; then echo "Please run $0 as root." && exit 1; fi
#On verifie que le hostname est =< 15 caractères
if [[ ${#H} -gt 15 ]]; then echo "Hostname must be less than 15 character, please change it using nmtui"; exit 1; fi
set -o errexit
set -o pipefail
set -o nounset

#Déclaration des variables
PKG="sssd realmd oddjob oddjob-mkhomedir adcli samba samba-common samba-common-tools krb5-workstation
openldap-clients policycoreutils-python samba-client ntp cifs-utils wget ftp curl unzip bind-utils net-tools mailx mlocate"
H=$(hostname -s)
domain="example.com"


help() {
    echo "Usage $0 {prerequisite|setup|help}"
    echo "This script is designed to automatically put a new VM in Active Directory domain"
    echo "First modify the domain variable in needed, then run prerequisite options to install and upgrade necessary packages"
    echo "Then, run setup to put the machine in Active Directory domain"
}

prerequisite() {

#yum -y install $PKG
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl mask firewalld
systemctl enable ntpd
systemctl start ntpd
yum -y update

tput setaf1; echo "Please reboot the machine before launching the setup option"; tput sgr0
}

setup() {

if [[ "" = $(pgrep ntpd) ]]; then systemctl start ntpd && systemctl status ntpd; fi
realm join --user=administrator $domain

sleep 30

sed -i "s/ldap_id_mapping = True/ldap_id_mapping = False/g" /etc/sssd/sssd.conf
sed -i "s/use_fully_qualified_names = True/use_fully_qualified_names = False/g" /etc/sssd/sssd.conf
sed -i "s/fallback_homedir = \/home\/%d\/%u/fallback_homedir = \/home\/users\/%u/g" /etc/sssd/sssd.conf
echo "session required pam_mkhomedir.so" >> /etc/pam.d/common-session
sed -i "s/auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success/#auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success/g" /etc/pam.d/password-auth
sed -i "s/auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success/#auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success/g" /etc/pam.d/system-auth

systemctl restart sssd
if [[ "$domain" != "$(realm list --name-only)" ]]; then echo "A problem occur"; else echo "Welcome to $domain domain"; fi

}


function main {
   RETVAL=0
   case "$1" in
      prerequisite)             # Prerequisite installation
         prerequisite
         ;;
      setup)             # put in domain
         setup
         ;;
      *|help)               # display help 
         help
         ;;
      esac
   exit $RETVAL
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

