#!/bin/bash

#########################################################################
#
# This shell script checks for free disk space on root (/) filesystem.
# It sends email alert based on defined threshold.
#
# Threshold can be configured.
#
#   Default warning alert threshold: 20%
#   Default disk to check: /
#
# Author  : Brahim O.
# Date    : February 2023
# Script  : monitor-filesystem.sh
#
#########################################################################

#----------------------- SMTP region begin ---------------------------------
# Credentials are loaded from .env file — never hardcode credentials here!
# Copy .env.example to .env and fill in your values before running.

if [ ! -f .env ]; then
    echo "ERROR: .env file not found. Please copy .env.example to .env and fill in your credentials."
    exit 1
fi

# Load credentials from .env
source .env
#------------------------- SMTP region end --------------------------------

# FIX 1: Define logfile BEFORE using it
logfile=monitor-filesystem.txt

# Hostname
HOSTNAME=$(hostname)

# Create log file or overwrite if already present
printf "[$HOSTNAME] - Log File - $logfile\n" | tee $logfile
printf "[$HOSTNAME] - logfile location : $logfile\n" | tee -a $logfile
date | tee -a $logfile
date=$(date)
whoami=$(whoami)

printf "[$HOSTNAME] - is localhost name\n" | tee -a $logfile

# Admin email account
ADMIN="$SMTP_ADMIN"
printf "[$HOSTNAME] - Admin email account : $ADMIN\n" | tee -a $logfile

# Set usage alert threshold
THRESHOLD=10
printf "[$HOSTNAME] - Usage alert threshold set value [ $THRESHOLD%% ]\n" | tee -a $logfile

# Mail client
MAIL=/usr/bin/mail

# Store email body here
EMAIL=""

# Get filesystem information
Filesystem=$(df -h | awk '$NF=="/"{printf "%s\t\t", $1}' | xargs)
Size=$(df -h | awk '$NF=="/"{printf "%s\t\t", $2}')
Used=$(df -h | awk '$NF=="/"{printf "%s\t\t", $3}')
Avail=$(df -h | awk '$NF=="/"{printf "%s\t\t", $4}')
# FIX 2: Unified variable name — using Usepercent consistently
Usepercent=$(df -h | awk '$NF=="/"{printf "%s\t\t", $5}')

# Used space without % sign for numeric comparison
Usedspace=$(df -H | awk '$NF=="/"{printf "%s\t\t", $5}' | sed 's/%//g' | xargs)

echo "--------------------------------------------"
echo "-       $HOSTNAME FILESYSTEM INFO :        -"
echo "--------------------------------------------"
echo "Filesystem        :" $Filesystem
echo "Size              :" $Size
echo "Used              :" $Used
echo "Avail             :" $Avail
echo "Use%              :" $Usepercent
echo ""
echo "--------------------------------------------"
echo ""
echo "Info from df -hT command (debug purpose):"
echo "---------------------------------------------"
df -hT /
echo "---------------------------------------------"
echo ""

printf "Comparing filesystem [$Filesystem] on [$HOSTNAME] used space to the defined threshold : [$THRESHOLD]\n" | tee -a $logfile

if [ "$Usedspace" -ge "$THRESHOLD" ]; then
    echo "/!\ BAD NEWS /!\ Used space is greater than threshold $THRESHOLD, alert will be sent !"
    printf "[$HOSTNAME] Used space is greater than $THRESHOLD, alert will be sent !\n" | tee -a $logfile
    echo "UsedSpace         : [ $Usedspace% ]"
    echo "Defined Threshold : [ $THRESHOLD% ]"

    EMAIL="$EMAIL\n [$HOSTNAME] - Here is the Filesystem usage info:"
    EMAIL="$EMAIL\n $Filesystem ($Usedspace%) is greater than the defined threshold ($THRESHOLD%)!"
    EMAIL="$EMAIL\n Please expand disk on server : $HOSTNAME"
    EMAIL="$EMAIL\n Date du check : $date"
    EMAIL="$EMAIL\n Check done by : $whoami"
    EMAIL="$EMAIL\n -.- End message -.-"

    echo -e "$EMAIL" | mailx -v \
        -s "[$HOSTNAME][WARNING] - Disk Usage Alert : Threshold Reached" \
        -S smtp="$SMTP_SERVER" \
        -S smtp-auth-user="$SMTP_USER" \
        -S smtp-auth-password="$SMTP_PASS" \
        "$ADMIN"

    # FIX 2: Fixed typo — was $Usedpercent, now $Usepercent
    printf "[$HOSTNAME] Disk Space on root filesystem is Low : %s\n" "$Usepercent" | tee -a $logfile
    printf "[$HOSTNAME] WARNING! : Disk Space on root filesystem needs attention!\n" | tee -a $logfile

elif [ "$Usedspace" -lt "$THRESHOLD" ]; then
    echo "GOOD NEWS :-D Used space is less than threshold $THRESHOLD, simple communication will be sent."
    echo "UsedSpace         : [ $Usedspace% ]"
    echo "Defined Threshold : [ $THRESHOLD% ]"
    echo ""

    EMAIL="$EMAIL\n [$HOSTNAME] - Here is the Filesystem usage info:"
    EMAIL="$EMAIL\n $Filesystem ($Usedspace%) is less than the threshold ($THRESHOLD%)."
    EMAIL="$EMAIL\n Check occurred on server : $HOSTNAME"
    EMAIL="$EMAIL\n Date du check : $date"
    EMAIL="$EMAIL\n Check done by : $whoami"
    EMAIL="$EMAIL\n -.- End message -.-"

    echo -e "$EMAIL" | mailx -v \
        -s "[$HOSTNAME] - Disk Usage Info : Threshold Not Reached" \
        -S smtp="$SMTP_SERVER" \
        -S smtp-auth-user="$SMTP_USER" \
        -S smtp-auth-password="$SMTP_PASS" \
        "$ADMIN"

    printf "[$HOSTNAME] Disk Space on root filesystem is OK : $Usepercent\n" | tee -a $logfile
fi

echo "----------------------------------"
echo "MAIL VARIABLE BELOW"
echo ""
echo -e "$EMAIL"
echo ""

printf "[$HOSTNAME] End Script - Disk Space on root filesystem\n" | tee -a $logfile
printf "\n" | tee -a $logfile

# END Script
