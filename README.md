# College Ahuntsic — Scripts (Bash / Python / SQL)

Scripts developed as part of my studies at **Collège Ahuntsic** in Montreal.  
Author: **Brahim O.**

---

## Repository Structure

```
college-ahuntsic-scripts/
├── bash/
│   └── usermanager.sh      # Linux user & group management tool
├── python/
│   └── ...                 # Python script (coming soon)
└── sql/
    └── ...                 # SQL script (coming soon)
```

---

## Bash — User & Group Manager (`usermanager.sh`)

An interactive menu-driven Bash script for managing Linux users and groups.  
Must be run as **root**.

### Features

| Option | Description |
|--------|-------------|
| 1 | Display information about a user account |
| 2 | Display information about a group |
| 3 | List all standard user accounts |
| 4 | List all service accounts |
| 5 | Manage a user's password policy |
| 6 | Display locked or disabled accounts |
| 7 | Unlock, activate or change a user's password |
| Q | Quit |

### Key functions

- `getUser` — Retrieves user info via `getent`, `id`, `awk`, `du`
- `getGroup` — Retrieves group info via `getent group`, `grep`, `awk`, `cut`
- `GetUserList` — Lists standard users (UID 1000–65533) from `/etc/passwd`
- `GetSvcAccount` — Lists service accounts (UID < 999) from `/etc/passwd`
- `ManageUserPwd` — Manages password policy with `chage` and `usermod`
- `GetLockedAccount` — Detects locked/expired accounts via `passwd -S` and `chage`
- `UnlockModifyUser` — Unlocks accounts and forces password reset at next login
- `CheckRoot` — Verifies the script is executed with root privileges
- `Quit` — Exits the script cleanly

### Usage

```bash
chmod +x usermanager.sh
sudo ./usermanager.sh
```

### Syntax validation

Script syntax verified with [ShellCheck](https://www.shellcheck.net/).

---

## Python — (Coming soon)

---

## MySQL — (Coming soon)

---

## Notes

- Developed in **February 2023** as part of a Linux administration course
- Tested on **Ubuntu / Debian** based systems
- Color-coded output for improved readability (green / blue / red)
