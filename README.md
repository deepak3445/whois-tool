WHOIS Lookup Tool (Bash Script)
===============================

A simple Linux Bash shell script that performs WHOIS lookups to retrieve domain registration information such as registrar, creation/expiration dates, and name servers.

---

Features
--------
- Runs directly in Linux Bash shell
- Uses the native `whois` command-line tool
- Easy to use with a simple command-line interface
- Outputs clear, formatted WHOIS domain information

---

Requirements
------------
- Linux system with Bash shell
- `whois` command installed (usually pre-installed or available via package manager)

To install `whois` on Debian/Ubuntu:
    sudo apt-get install whois

To install `whois` on RedHat/CentOS:
    sudo yum install whois

---

Usage
-----
1. Clone the repository:
    git clone https://github.com/deepak3445/whois-tool.git
    

2. Make the script executable:
    chmod +x whois_lookup.sh

3. Run the script with a domain name argument:
    ./whois_lookup.sh example.com

Example output:
    Domain Name: EXAMPLE.COM
    Registrar: IANA
    Creation Date: 1995-08-14
    Expiration Date: 2025-08-14
    Name Servers:
      - NS1.EXAMPLE.COM
      - NS2.EXAMPLE.COM

---

File Structure
--------------
whois-lookup-tool/
├── whois_lookup.sh
└── README.txt

---

Future Enhancements
-------------------
- Add domain validation checks
- Support bulk domain lookups from a file
- Output formatting improvements (e.g., colors, summaries)

---

Author
------
Developed by [Ranga Deepak]  
GitHub: https://github.com/deepak3445

---

License
-------
MIT License. See LICENSE file for details.
