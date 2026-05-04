#!/usr/bin/env python3
"""
Developed on: Python 3.9.14
Author      : Brahim O.
Script      : monitor-filesystem.py
Description : Monitor local filesystem and send alert email if threshold is exceeded.
Date        : February 2023
"""

import os
import platform
import shutil
import smtplib
import socket
import subprocess

from datetime import date, datetime
from email.mime.text import MIMEText
from dotenv import load_dotenv

# FIX 1: Load credentials from .env file — never hardcode credentials !
load_dotenv()

SMTP_SERVER   = os.getenv('SMTP_SERVER')
SMTP_PORT     = int(os.getenv('SMTP_PORT', 587))
SMTP_USER     = os.getenv('SMTP_USER')
SMTP_PASS     = os.getenv('SMTP_PASS')
SMTP_FROM     = os.getenv('SMTP_FROM')
SMTP_ADMIN    = os.getenv('SMTP_ADMIN')

# Variables definition
# ----------------------
THRESHOLD = 4   # Threshold definition (%)
PARTITION = '/' # Drive/filesystem to check
# ----------------------

whoami = os.popen('whoami').read().strip()
today  = date.today()
fdate  = date.today().strftime('%d/%m/%Y')
now    = datetime.now()

print("Today's current date is -", today)


def get_machine_name() -> str:
    """Return the machine hostname."""
    cn = os.getenv('COMPUTERNAME')
    pn = platform.node()
    hn = socket.gethostname()
    return cn if cn else pn if pn else hn


def get_input(message: str) -> str:
    """Display a message and return user input."""
    print(message)
    return input()


def email_report(hostname: str, status: str) -> MIMEText:
    """
    Build an email report.
    status: 'warning' if threshold exceeded, 'info' if all is fine.
    """
    if status == 'warning':
        subject  = f'[{hostname}] : WARNING ! - Disk Usage Alert'
        lines = [
            f'{hostname} is running out of disk space !',
            f'Filesystem usage has exceeded the threshold of {THRESHOLD}%.',
            f'Check done by : {whoami}',
            f'Date of check : {now}',
            '-.- End message -.-'
        ]
    else:
        subject = f'[{hostname}] : INFO - Disk Usage OK'
        lines = [
            f'{hostname} filesystem usage is within normal limits.',
            f'Filesystem usage is below the threshold of {THRESHOLD}%.',
            f'Check done by : {whoami}',
            f'Date of check : {now}',
            '-.- End message -.-'
        ]

    body = '\n'.join(lines)
    mime = MIMEText(body)
    mime['Subject'] = subject
    mime['From']    = SMTP_FROM
    mime['To']      = SMTP_ADMIN
    return mime


def check_disk() -> int:
    """Return current disk usage percentage for the defined partition."""
    df = subprocess.Popen(["df", "-h"], stdout=subprocess.PIPE)
    for line in df.stdout:
        splitline = line.decode().split()
        if splitline[5] == PARTITION:
            return int(splitline[4][:-1])
    return 0


def check_once() -> MIMEText:
    """
    Check disk usage and return appropriate email report.
    Returns a warning email if threshold exceeded, info email otherwise.
    """
    usage = check_disk()
    hostname = get_machine_name()
    if usage > THRESHOLD:
        return email_report(hostname=hostname, status='warning')
    else:
        return email_report(hostname=hostname, status='info')


def send_email(msg: MIMEText) -> None:
    """Send email via SMTP."""
    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.login(SMTP_USER, SMTP_PASS)
        server.sendmail(SMTP_FROM, SMTP_ADMIN, msg.as_string())
        server.quit()
    print("Email sent successfully !")


def print_disk_info() -> None:
    """Display detailed disk usage information."""
    total, used, free = shutil.disk_usage("/")
    print("-------------------------------------")
    print("Total              : %d GiB" % (total // (2 ** 30)))
    print("Used               : %d GiB" % (used  // (2 ** 30)))
    print("Free               : %d GiB" % (free  // (2 ** 30)))
    print("FileSystem %% usage : [{}] %".format(check_disk()))
    print("-------------------------------------")


def main():
    """Main menu loop."""
    hostname = get_machine_name()

    while True:
        print("""
        1. Check Filesystem usage
        Q. Exit/Quit
        """)
        # FIX 2: Removed typo "Quit5" → "Quit"
        ans = get_input("What would you like to do?: ")

        if ans == "1":
            print("Checking Filesystem usage...")
            usage = check_disk()
            print_disk_info()

            if usage > THRESHOLD:
                print(f"WARNING ! FileSystem volume freespace is low on {hostname} !")
                print(f"FileSystem current usage is : [ {usage} % ] — threshold is {THRESHOLD}%")
                print("Alert will be sent to administrator...")
                msg = check_once()
                send_email(msg)

            else:
                # FIX 3: Now sends an INFO email even when usage is OK (aligned with Bash version)
                print(f"Everything is fine on {hostname}. Usage is [ {usage}% ] — below threshold of {THRESHOLD}%.")
                print("Info email will be sent to administrator...")
                msg = check_once()
                send_email(msg)

            break

        elif ans.upper() == "Q":
            print("\nGoodbye !")
            break

        else:
            print("\nNot a valid choice, please try again.")


if __name__ == "__main__":
    main()
