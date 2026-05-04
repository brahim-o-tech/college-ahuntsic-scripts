#!/bin/bash
# Lab Automation
# Brahim O.
# usermanager.sh
# February, 2023
# Description: The purpose of this script is to manage linux users and linux groups using a menu. 

# Color  Variables
green='\e[32m'
blue='\e[34m'
clear='\e[0m'
red='\033[0;31m'

# Color Functions
ColorGreen(){
    echo -ne "$green$1$clear"
}
ColorBlue(){
    echo -ne "$blue$1$clear"
}
ColorRed(){
    echo -ne "$red$1$clear"
}

###############################################################
#Checking if script is launched by root or user with privileges
################################################################
CheckRoot()
{
   # If not running as root we exit the program
   if [ $(id -u) != 0 ]
   then
    echo "$(ColorRed 'ERROR: Insufficient privilege')"  
    echo "$(ColorRed 'ERROR: You must be root user to run this program')"
      exit
   fi
}

###############################################################
# Sanity checks
###############################################################
# Are we running as root?
CheckRoot

# Display the menu
function menu () {
    while [ true ]; do
        echo "$(ColorGreen "===========================================")"
        echo "$(ColorGreen '===  User and group management program  ===')"
        echo "$(ColorGreen '===========================================')"
        echo ""
        echo "$(ColorGreen '1)') Information sur un compte"
        echo "$(ColorGreen '2)') Information sur un groupe"
        echo "$(ColorGreen '3)') Afficher les comptes utilisateurs"
        echo "$(ColorGreen '4)') Afficher les comptes de service"
        echo "$(ColorGreen '5)') Gerer le mot de passe d'un compte"
        echo "$(ColorGreen '6)') Afficher les comptes verrouilles ou desactives"
        echo "$(ColorGreen '7)') Activer, deverrouiller un compte ou modifier le mot de passe"
        echo "$(ColorRed 'Q)') Quit"
        echo ""
        echo -n "Enter the letter for the option you want to pick: "
        read -r choice

        # FIX 1: Removed redundant duplicate conditions (e.g. "1" || "1" → just "1")
        if [ "$choice" = "1" ]; then
            getUser
        elif [ "$choice" = "2" ]; then
            getGroup
        elif [ "$choice" = "3" ]; then
            GetUserList
        elif [ "$choice" = "4" ]; then
            GetSvcAccount
        elif [ "$choice" = "5" ]; then
            ManageUserPwd
        elif [ "$choice" = "6" ]; then
            GetLockedAccount
        elif [ "$choice" = "7" ]; then
            UnlockModifyUser
        elif [ "$choice" = "Q" ] || [ "$choice" = "q" ]; then
            Quit 
        else
            clear
            echo $(ColorRed 'Error: Please select a valid option from the list !')
            echo ""
        fi
    done
}

##############

# -1- Information sur un compte
function getUser() { 
    clear
    echo "Information sur un compte"
    echo ""
    echo -n "Entrez un nom d'utilisateur: "
    read username
    echo ""
    if getent passwd "$username" > /dev/null 2>&1; then
        echo User $(ColorGreen "$username") exist, user details bellow : 

        # FIX 2: Moved all variable definitions BEFORE they are used
        username=$(getent passwd "$username" | awk -F: '{print $1}')
        password=$(getent passwd "$username" | awk -F: '{print $2}')
        uid=$(getent passwd "$username" | awk -F: '{print $3}')
        gid=$(getent passwd "$username" | awk -F: '{print $4}')
        comment=$(getent passwd "$username" | awk -F: '{print $5}')
        homedirpath=$(getent passwd "$username" | awk -F: '{print $6}')
        shell=$(getent passwd "$username" | awk -F: '{print $7}')
        primarygroup=$(id -ng "$username")
        secondarygroups=$(id -Gn "$username" | cut -d' ' -f2-)
        homedircapa=$(du -h --max-depth=0 "$homedirpath" | awk '{ print $1 }')

        echo "============================================="
        echo "Username          :" "$username"
        echo "Password          :" "$password"
        echo "UID               :" "$uid"
        echo "GID               :" "$gid"
        echo "PrimaryGrp        :" "$primarygroup"
        echo "SecondaryGrp      :" "$secondarygroups"
        echo "Comment           :" "$comment"
        echo "HomedirPath       :" "$homedirpath"
        echo "HomedirCapacity   :" "$homedircapa"
        echo "Shell             :" "$shell"
        echo "=============================================="
    else 
        echo $(ColorRed 'User Not Found !')  
    echo ""
    fi
    read
    clear
}


# -2- Information sur un groupe
function getGroup() {
    clear
    echo "Information sur un groupe"
    echo ""
    echo -n "Entrez un nom de Groupe: "
    read groupname
    echo ""
    if getent group "$groupname" > /dev/null 2>&1; then
        echo "Group $groupname exist, group details bellow :" 
        grouppwd=$(getent group "$groupname" | awk -F: '{print $2}')
        echo "Groupname     :" "$groupname" 
        if [[ $grouppwd == "x" ]]; then
            echo "Password      : YES" 
        else 
            echo "Password      : NO" 
        fi
        echo "Password-field        :" $(getent group "$groupname" | awk -F: '{print $2}')
        echo "GID                   :" $(grep "$groupname" /etc/group | awk -F: '{print $3}')
        # FIX 3: Replaced hardcoded "marketing" with $groupname variable
        echo "Members               :" $(getent group "$groupname" | awk -F: '{print $4}')
        echo "Primary-Group for     :" $(cut -d: -f1,4 /etc/passwd | grep ":$(getent group "$groupname"|cut -d: -f3)$" | cut -d: -f1) 
        echo "Secondary-Group for   :" $(getent group "$groupname" | cut -d: -f4 | tr ',' '\n') 
        echo "Grp-Administrator     :" test 
    else 
        echo "$(ColorRed 'Groupe Not Found') : " "$groupname"
    fi
    echo ""
    read
    clear
}


# -3- Afficher les comptes utilisateurs
function GetUserList() {
    clear
    echo "Afficher les comptes utilisateurs"
    echo ""
    echo "List of standard users bellow :" 
    echo "------------------------------------------------"
    cat /etc/passwd | awk -F: '$3 > 999 && $3 < 65534 {print $1}'
    echo "------------------------------------------------"
    usercount=$(cat /etc/passwd | awk -F: '$3 > 999 && $3 < 65534 {print $1}' | wc -l)
    echo ""
    echo "------------------------------------------------"
    echo "Nombre total utilisateurs :" "$usercount"
    echo "------------------------------------------------"
    read
    clear
}


# -4- Afficher les comptes de service
function GetSvcAccount() {
    clear
    echo "Afficher les comptes de services"
    echo ""
    echo "List of service accounts bellow :" 
    echo "------------------------------------------------"
    cat /etc/passwd | awk -F: '$3 < 999 && $3 < 65534 {print $1}'
    echo "------------------------------------------------"
    grpcount=$(cat /etc/passwd | awk -F: '$3 < 999 && $3 < 65534 {print $1}' | wc -l)
    echo ""
    echo "------------------------------------------------"
    echo "Nombre total comptes de service :" "$grpcount"
    echo "------------------------------------------------"
    read
    clear
}

###########
# -5- Gerer le mot de passe d'un compte
function ManageUserPwd() { 
    clear
    echo "Information sur un compte"
    echo ""
    echo -n "Entrez un nom d'utilisateur: "
    read username
    echo ""
    if getent passwd "$username" > /dev/null 2>&1; then
        echo User $(ColorGreen $username) exist, setup password policy for user. 

        username=$(getent passwd $username | awk -F: '{print $1}')
        uid=$(getent passwd $username | awk -F: '{print $3}')
        gid=$(getent passwd $username | awk -F: '{print $4}')

        echo "============================================="
        echo "Username      :" $username
        echo "Password      :" $password
        echo "UID           :" $uid
        echo "GID           :" $gid
        echo "=============================================="
        echo ""
        echo "=============================================="
        echo "Fixing password policy like following :"
        echo "Durée maximale du mot de passe : 45 jours"
        echo "Durée minimale du mot de passe : 3 jours"
        echo "Nombre de jours de notifications pour changer le mot de passe : 5 jours"
        echo "Nombre de jours pour désactiver un compte (qui ne change pas son mot de passe) : 3 jours" 
        echo "=============================================="
        echo ""
        read -p "Do you want to proceed with above settings for $username (y/n) ? :" choice1
        case $choice1 in 
        [yY]* ) echo "Updating security Policy for user $username ..."
             chage -I 3 -M 45 -m 3 -W 5 $username
             echo "Operation done for user $username !"
             echo "New pwd policy setup for user $username is now : "
             echo "-------------------------------------------------" 
             chage -l $username
             echo "-------------------------------------------------";;
        [nN]* ) echo "Nothing done on pwd security policy for user $username";;
        *) exit;;
        esac
        read

        read -p "Do you want to set expiration date for user (y/n) :" choice
        case $choice in
        [yY]* ) echo "Change Expiration Date For User Setup"
                echo -n "Please enter a expiration date in the format YYYY-MM-DD for $username : "
                read expire
                usermod -e $expire $username
                echo "Expiration date changed for $username to $expire";;
        [nN]* ) echo "Nothing done for user (expiration date):" $username;;
        *) exit;;
            esac
        read 
        clear

    else
        echo $(ColorRed 'User Not Found !')  
    echo ""
    fi
    read
    clear
}

# -6- Afficher les comptes verrouilles ou desactives
function GetLockedAccount() {
    clear
    echo "Afficher les comptes locked/expired"
    echo ""
    neuser=0
    userlist=$(cat /etc/passwd | awk -F: '$3 > 999 && $3 < 65534 {print $1}')
    for user in $userlist; do
        if chage -l "$user" | grep -i '^Password expires' | grep -q never; then
            echo "Never expired" "$user" 
            neuser=$((neuser+1))
        fi
        passwd -S "$user"
    done | awk 'BEGIN {lockedusers=0} $2 ~ /L/ {lockedusers++} END {print "Total users:",NF;print "Locked users:",lockedusers}'
    echo "Non-expiring users: $neuser"
    echo ""

    for USER in $(grep home /etc/passwd | cut -d':' -f1)
    do
        if [ "$(chage -l "$USER" | grep 'Account expires' | cut -d':' -f2)" != ' never' ] 
        then
            echo "Password expired for user :" "$USER"
        fi

        if [ "$(passwd "$USER" -S | awk '/LK/{print $2}')" == 'LK' ] 
        then
            echo "Account locked for user : " "$USER"
        fi
    done
    read
    clear
}


# -7- Activer, deverrouiller un compte ou modifier le mot de passe
function UnlockModifyUser() { 
    clear
    echo "Information sur un compte"
    echo ""
    echo -n "Entrez un nom d'utilisateur: "
    read username
    echo ""
    if getent passwd "$username" > /dev/null 2>&1; then
        echo User $(ColorGreen "$username") exist, user details bellow : 

        username=$(getent passwd "$username" | awk -F: '{print $1}')
        uid=$(getent passwd "$username" | awk -F: '{print $3}')
        gid=$(getent passwd "$username" | awk -F: '{print $4}')

        echo "============================================="
        echo "Username      :" "$username"
        echo "UID           :" "$uid"
        echo "GID           :" "$gid"
        echo "=============================================="
        echo ""
        echo "Checking if user account is currently locked out..."
        locked=$(passwd $username -S | awk '/LK/{print $2}')
        echo $locked
        if [[ $locked = "LK" ]]; then
            echo "Account locked for user $username !"
            read -p "Do you want to unlock account : $username (y/n) ? :" choice2
            case $choice2 in 
            [yY]* ) echo "Unlocking account for user : $username ..."
                 passwd -u $username 
                 echo "User Account has been unlocked for $username!"
                 echo "New lock status for user account $username is now : "
                 echo "-------------------------------------------------" 
                 passwd -S $username
                 echo "-------------------------------------------------";;
            [nN]* ) echo "Nothing done for user $username";;
            *) exit;;
            esac
        else 
            echo "Account is not locked"
        fi
        read

        echo "Verifying if account is Expired/deactivated..."
        deactivated=$(chage -l "$username" | grep -i '^Password expires' | grep -q never)
        echo $deactivated 
        if [ -z $deactivated ]; then
            echo "User account is deactivated/expired : $username"
            echo "Root will reset user password, and force change at next logon"
            
            read -p "Do you want to change user password for : $username (y/n) ? :" choice3
            case $choice3 in 
            [yY]* ) echo "Password will be changed for user : $username ..."
                echo "Please enter the new password for $username :"
                read -s password1
                echo "Please repeat the new password for $username:"
                read -s password2
                if [ $password1 != $password2 ]; then
                    echo "Passwords do not match !"
                    exit    
                else
                    echo -e "$password1\n$password1" | passwd $username
                    echo "Job done ! Password has been changed for $username "
                    echo "New lock status for user account $username is now : "
                    echo "-------------------------------------------------" 
                    passwd -S $username
                    echo "-------------------------------------------------"
                fi;;
            [nN]* ) echo "Nothing done for user $username";;
            *) exit;;
            esac
            
            echo "Job done for following User account :" "$username"
        fi
                
    else 
        echo $(ColorRed 'User Not Found !')  
        echo ""
    fi
    read
    clear
}

##
# Quit function 
function Quit () {
    echo "Bye !"
    exit 1
}

#RUN MENU
clear
menu
#  *.* FIN DU CODE DU SCRIPT GESTION DES USERS ET GROUPS *.*
