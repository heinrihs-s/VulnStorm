#!/usr/bin/env bash
#
# Full Vulnerability Scanning Automation Script
# Author: Heinrihs Skrodelis
# 
# DISCLAIMER:
# This script is for educational and authorized testing purposes only.
# Do NOT scan domains that you do not own or have explicit permission to test.
#

#######################################
#            Configuration            #
#######################################

DEFAULT_WORDLIST="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
TOOLS=("amass" "sublist3r" "nmap" "nikto" "sqlmap" "gobuster" "dirsearch" "sslscan" "gvm-cli")

# Colors for pretty output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

#######################################
#          Helper Functions           #
#######################################

print_banner() {
  echo -e "${BLUE}${BOLD}"
  echo "============================================="
  echo "  Full Vulnerability Scanning Automation    "
  echo "============================================="
  echo -e "${RESET}"
}

usage() {
  echo "Usage: $0 [OPTIONS] <domain_or_ip>"
  echo
  echo "OPTIONS:"
  echo "  -w, --wordlist <path>    Path to custom wordlist (default: $DEFAULT_WORDLIST)"
  echo "  -p, --parallel           Enable parallel scanning where possible"
  echo "  -h, --help               Show this help message"
  echo
  echo "Examples:"
  echo "  $0 example.com"
  echo "  $0 --wordlist /path/to/wordlist.txt 192.168.1.1"
  echo "  $0 -p example.com"
  exit 1
}

check_root() {
  # Some tools may need sudo privileges, check if user is root
  if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}[!] You are not running as root. Some scans may require root privileges.${RESET}"
  fi
}

check_dependencies() {
  for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      echo -e "${RED}[-] Error: $tool is not installed or not in PATH.${RESET}"
      echo "    Please install it before running the script."
      exit 1
    fi
  done
}

#######################################
#         Scanning Functions          #
#######################################

subdomain_enum() {
  local target="$1"
  echo -e "${GREEN}[+] Running Amass for subdomain enumeration...${RESET}"
  amass enum -d "$target" -o amass_subdomains.txt
  
  echo -e "${GREEN}[+] Running Sublist3r for subdomain enumeration...${RESET}"
  sublist3r -d "$target" -o sublist3r_subdomains.txt

  # Combine and remove duplicates
  cat amass_subdomains.txt sublist3r_subdomains.txt | sort -u > all_subdomains_raw.txt

  # Optional: check which subdomains are alive (using httpx or httprobe if installed)
  echo -e "${GREEN}[+] Checking for live subdomains...${RESET}"
  if command -v httprobe &>/dev/null; then
    cat all_subdomains_raw.txt | httprobe | sed 's|http[s]*://||' | sort -u > all_subdomains.txt
  else
    # Fallback: Just rename
    mv all_subdomains_raw.txt all_subdomains.txt
  fi

  echo -e "${GREEN}[+] Total subdomains found: $(wc -l < all_subdomains.txt)${RESET}"
}

nmap_scan() {
  local target_file="$1"
  echo -e "${GREEN}[+] Running Nmap for port scanning and service detection...${RESET}"
  nmap -sC -sV -oN nmap_scan.txt -iL "$target_file"
}

nikto_scan() {
  local subdomains_file="$1"
  local parallel="$2"

  echo -e "${GREEN}[+] Running Nikto for web vulnerability scanning...${RESET}"

  if [[ "$parallel" == "true" ]] && command -v parallel &>/dev/null; then
    cat "$subdomains_file" | parallel -j 10 "nikto -host http://{} -output nikto_scan_{}.txt"
  else
    for subdomain in $(cat "$subdomains_file"); do
      nikto -host "http://$subdomain" -output "nikto_scan_${subdomain}.txt"
    done
  fi
}

sqlmap_scan() {
  local subdomains_file="$1"
  local parallel="$2"

  echo -e "${GREEN}[+] Running SQLMap to test for SQL Injection vulnerabilities...${RESET}"

  if [[ "$parallel" == "true" ]] && command -v parallel &>/dev/null; then
    cat "$subdomains_file" | parallel -j 5 "sqlmap -u http://{} --batch --crawl=3 --output-dir=sqlmap_scan_{}"
  else
    for subdomain in $(cat "$subdomains_file"); do
      sqlmap -u "http://$subdomain" --batch --crawl=3 --output-dir="sqlmap_scan_$subdomain"
    done
  fi
}

gobuster_scan() {
  local subdomains_file="$1"
  local wordlist="$2"
  local parallel="$3"

  echo -e "${GREEN}[+] Running Gobuster to brute-force directories...${RESET}"

  if [[ "$parallel" == "true" ]] && command -v parallel &>/dev/null; then
    cat "$subdomains_file" | parallel -j 5 "gobuster dir -u http://{} -w $wordlist -o gobuster_{}.txt"
  else
    for subdomain in $(cat "$subdomains_file"); do
      gobuster dir -u "http://$subdomain" -w "$wordlist" -o "gobuster_${subdomain}.txt"
    done
  fi
}

dirsearch_scan() {
  local subdomains_file="$1"
  local parallel="$2"

  echo -e "${GREEN}[+] Running Dirsearch for additional directory brute-forcing...${RESET}"

  if [[ "$parallel" == "true" ]] && command -v parallel &>/dev/null; then
    cat "$subdomains_file" | parallel -j 5 "dirsearch -u http://{} -e php,html,js -o dirsearch_{}.txt"
  else
    for subdomain in $(cat "$subdomains_file"); do
      dirsearch -u "http://$subdomain" -e php,html,js -o "dirsearch_${subdomain}.txt"
    done
  fi
}

ssl_scan() {
  local subdomains_file="$1"
  local parallel="$2"

  echo -e "${GREEN}[+] Running SSLScan for SSL/TLS vulnerability scanning...${RESET}"

  if [[ "$parallel" == "true" ]] && command -v parallel &>/dev/null; then
    cat "$subdomains_file" | parallel -j 5 "sslscan {} > sslscan_{}.txt"
  else
    for subdomain in $(cat "$subdomains_file"); do
      sslscan "$subdomain" > "sslscan_${subdomain}.txt"
    done
  fi
}

openvas_scan() {
  local target="$1"
  echo -e "${GREEN}[+] Running OpenVAS (gvm-cli) for comprehensive vulnerability scanning...${RESET}"
  # Example command, modify as needed
  gvm-cli tls --hostname "$target" --xml "<get_tasks/>" > "openvas_scan_${target}.txt"
}

#######################################
#               Main                  #
#######################################

main() {
  print_banner
  check_root
  check_dependencies

  local WORDLIST="$DEFAULT_WORDLIST"
  local PARALLEL="false"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--wordlist)
        WORDLIST="$2"
        shift 2
        ;;
      -p|--parallel)
        PARALLEL="true"
        shift
        ;;
      -h|--help)
        usage
        ;;
      *)
        TARGET="$1"
        shift
        ;;
    esac
  done

  # If no target is provided
  if [[ -z "$TARGET" ]]; then
    usage
  fi

  # Prepare output directory
  OUTPUT_DIR="${TARGET}_scan_results"
  mkdir -p "$OUTPUT_DIR"
  cd "$OUTPUT_DIR" || {
    echo -e "${RED}[-] Failed to enter directory $OUTPUT_DIR${RESET}"
    exit 1
  }

  echo -e "${GREEN}[+] Starting full automation for vulnerability scanning on: $TARGET${RESET}"
  echo -e "${GREEN}[+] All results will be saved in: $OUTPUT_DIR${RESET}"
  echo

  # 1. Subdomain Enumeration
  subdomain_enum "$TARGET"

  # 2. Port Scanning with Nmap (on subdomains)
  nmap_scan "all_subdomains.txt"

  # 3. Web Vulnerability Scanning
  nikto_scan "all_subdomains.txt" "$PARALLEL"

  # 4. SQL Injection Scanning
  sqlmap_scan "all_subdomains.txt" "$PARALLEL"

  # 5. Directory Brute-forcing (Gobuster & Dirsearch)
  gobuster_scan "all_subdomains.txt" "$WORDLIST" "$PARALLEL"
  dirsearch_scan "all_subdomains.txt" "$PARALLEL"

  # 6. SSL/TLS Vulnerability Scanning
  ssl_scan "all_subdomains.txt" "$PARALLEL"

  # 7. Vulnerability Scanning with OpenVAS
  openvas_scan "$TARGET"

  echo -e "${GREEN}[+] Full vulnerability scanning automation completed for ${TARGET}.${RESET}"
  echo -e "${GREEN}[+] Results are in the ${OUTPUT_DIR} directory.${RESET}"
  echo -e "${GREEN}[!] Remember to only test domains you have permission to test.${RESET}"
}

# Execute main
main "$@"
