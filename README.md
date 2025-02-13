# VulnStorm: Unleash the Storm of Vulnerabilities!

VulnStorm is an all-in-one, automated vulnerability scanning tool that combines multiple reconnaissance and scanning utilities into one streamlined Bash script. Unleash a storm of scans against your target—subdomain enumeration, port scanning, web vulnerability testing, and more!

> **Disclaimer:** This tool is for **educational and authorized testing purposes only**. Always obtain explicit permission before scanning any domain or IP that you do not own.

## Features

- **Subdomain Enumeration:**  
  Combines [Amass](https://github.com/OWASP/Amass) and [Sublist3r](https://github.com/aboul3la/Sublist3r) for thorough asset discovery.
- **Port Scanning:**  
  Uses [Nmap](https://nmap.org/) to scan ports and detect running services.
- **Web Vulnerability Scanning:**  
  Leverages [Nikto](https://cirt.net/Nikto2) for common web vulnerabilities.
- **SQL Injection Testing:**  
  Automates SQL injection tests with [SQLMap](https://github.com/sqlmapproject/sqlmap).
- **Directory Brute-forcing:**  
  Brute-forces web directories using [Gobuster](https://github.com/OJ/gobuster) and [Dirsearch](https://github.com/maurosoria/dirsearch).
- **SSL/TLS Analysis:**  
  Checks for SSL/TLS vulnerabilities with [SSLScan](https://github.com/rbsec/sslscan).
- **Comprehensive Vulnerability Scanning:**  
  Integrates with [OpenVAS](https://www.openvas.org/) (via `gvm-cli`) for an in-depth scan.

## Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/heinrihs-s/VulnStorm.git
   cd vulnstorm
   ```

2. **Install Dependencies:**

   Make sure the following tools are installed and in your $PATH:
   - amass
   - sublist3r
   - nmap
   - nikto
   - sqlmap
   - gobuster
   - dirsearch
   - sslscan
   - gvm-cli

   Optional (for faster scans):
   - parallel
   - httprobe (to filter live subdomains)

3. **Make the Script Executable:**
   ```bash
   chmod +x vulnstorm.sh
   ```

## Usage

```bash
./vulnstorm.sh [OPTIONS] <domain_or_ip>
```

### Options:
- `-w, --wordlist <path>`: Use a custom wordlist for directory brute-forcing. (Default: /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt)
- `-p, --parallel`: Enable parallel scanning (requires GNU Parallel).
- `-h, --help`: Display help and usage instructions.

### Example:
```bash
./vulnstorm.sh -p example.com
```
This command starts the full automated scan against example.com with parallel scanning enabled.

### Output Example
After running VulnStorm, you'll see outputs like:

```bash
[+] Starting full automation for vulnerability scanning on: example.com
[+] All results will be saved in: example.com_scan_results

[+] Running Amass for subdomain enumeration...
[+] Running Sublist3r for subdomain enumeration...
[+] Combining subdomain results and checking for live hosts...
[+] Total subdomains found: 15

[+] Running Nmap for port scanning and service detection...
# Nmap scan report for sub.example.com (93.184.216.34)
...
Nmap done: 15 IP addresses (14 hosts up) scanned in 35.68 seconds

[+] Running Nikto for web vulnerability scanning...
[+] Running SQLMap to test for SQL Injection vulnerabilities...
[+] Running Gobuster to brute-force directories...
[+] Running Dirsearch for additional directory brute-forcing...
[+] Running SSLScan for SSL/TLS vulnerability scanning...
[+] Running OpenVAS (gvm-cli) for comprehensive vulnerability scanning...

[+] Full vulnerability scanning automation completed for example.com.
[+] Results are in the example.com_scan_results directory.
[!] Remember to only test domains you have permission to test.
```

Each scan's result is saved in the output directory (e.g., example.com_scan_results) with clearly named files for easy review.

## Contributing

We welcome contributions! If you have ideas to improve VulnStorm, please fork the repository and submit a pull request. Also, feel free to report issues or feature requests.

1. Fork the repository.
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Open a pull request.

## License

This project is licensed under the MIT License.

## Follow & Share

If you find VulnStorm useful, give it a star on GitHub and share it with your network!

**Use VulnStorm responsibly and always ensure you have explicit permission before scanning any target.**
