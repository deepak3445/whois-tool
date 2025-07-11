#!/bin/bash

###############################################################################
# Smart Domain Analyzer - Shell Script Version
#
# Features:
# - WHOIS lookup
# - DNS record analysis
# - SSL certificate inspection
# - Hosting/Server information
# - IP geolocation
# - Blacklist checking
# - Response time measurement
###############################################################################

# Ensure required commands are installed
check_dependencies() {
    local required=("whois" "dig" "curl" "openssl" "ping" "nslookup" "jq")
    local missing=()
    
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing required dependencies:"
        printf ' - %s\n' "${missing[@]}"
        
        # Provide installation commands based on OS
        if [ -f "/etc/os-release" ]; then
            source /etc/os-release
            case $ID in
                debian|ubuntu)
                    echo "Install with: sudo apt-get install ${missing[*]}"
                    ;;
                fedora|centos|rhel)
                    echo "Install with: sudo yum install ${missing[*]}"
                    ;;
                alpine)
                    echo "Install with: sudo apk add ${missing[*]}"
                    ;;
                *)
                    echo "Please install the missing packages using your system's package manager"
                    ;;
            esac
        else
            echo "Please install the missing packages using your system's package manager"
        fi
        exit 1
    fi
}

# Validate domain format (simplified check)
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        echo "Error: Invalid domain format"
        echo "Examples of valid domains:"
        echo " - example.com"
        echo " - subdomain.example.org"
        echo " - new-domain.co.uk"
        return 1
    fi
    return 0
}

# Get WHOIS information with multiple fallback servers
get_whois() {
    local domain="$1"
    echo -e "\n=== WHOIS Information ===\n"
    
    # Try different WHOIS servers if the primary fails
    local whois_servers=("whois.internic.net" "whois.iana.org" "whois.verisign-grs.com")
    
    for server in "${whois_servers[@]}"; do
        echo "Trying server: $server"
        whois -H -h "$server" "$domain" | grep -vE "^%|^#" | grep -v "^$"
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            return 0
        fi
    done
    
    echo "Failed to retrieve WHOIS information from all servers"
    return 1
}

# Get comprehensive DNS records
get_dns_records() {
    local domain="$1"
    echo -e "\n=== DNS Records ===\n"
    
    # Record types to check
    local record_types=("A" "AAAA" "MX" "TXT" "NS" "CNAME" "SOA")
    
    for type in "${record_types[@]}"; do
        echo "--- $type Records ---"
        dig +short "$type" "$domain"
        echo ""
    done
    
    # Detect DNSSEC
    echo "--- DNSSEC Validation ---"
    if dig +dnssec "$domain" | grep -q "ad"; then
        echo "DNSSEC is enabled and valid"
    else
        echo "DNSSEC is not enabled or validation failed"
    fi
}

# Check SSL certificate details
get_ssl_info() {
    local domain="$1"
    echo -e "\n=== SSL Certificate Info ===\n"
    
    # Get certificate details
    echo | openssl s_client -showcerts -servername "$domain" -connect "$domain":443 2>/dev/null | \
        openssl x509 -noout -text | \
        grep -E "Issuer:|Subject:|Validity|DNS:|Not Before|Not After"
    
    # Check HSTS (HTTP Strict Transport Security)
    echo -e "\n--- HSTS Status ---"
    if curl -s -I "https://$domain" | grep -q "Strict-Transport-Security"; then
        echo "HSTS is enabled"
    else
        echo "HSTS is not enabled"
    fi
}

# Get hosting/server information
get_hosting_info() {
    local domain="$1"
    echo -e "\n=== Hosting/Server Information ===\n"
    
    # Get IP address(es)
    local ips=($(dig +short "$domain"))
    echo "Server IP(s): ${ips[*]}"
    
    # Get nameservers
    echo "Nameservers:"
    dig +short NS "$domain" | while read ns; do
        echo " - $ns ($(dig +short "$ns"))"
    done
    
    # Get server headers
    echo -e "\n--- HTTP Headers ---"
    curl -I "https://$domain" 2>/dev/null | grep -E "Server:|X-Powered-By:"
    
    # Check CDN
    local cdn_info=$(curl -sI "https://$domain" | grep -E "CF-RAY|X-Sucuri-ID|X-Akamai-Request-ID")
    if [ -n "$cdn_info" ]; then
        echo -e "\nCDN Detected:"
        echo "$cdn_info"
    else
        echo -e "\nNo CDN detected or information unavailable"
    fi
}

# Check blacklist status (simplified version)
check_blacklist() {
    local domain="$1"
    echo -e "\n=== Blacklist Check ===\n"
    echo "Note: This checks against public blacklist APIs"
    
    local blacklists=(
        "https://www.dnsbl.info/lookup?ip=${ips[0]}" 
        "http://multi.surbl.org/api?ip=${ips[0]}"
    )
    
    for list in "${blacklists[@]}"; do
        echo -n "Checking $list... "
        if curl -fs "$list" | grep -q "not listed"; then
            echo "Clean"
        else
            echo "Potential issue found"
        fi
    done
}

# Get ping statistics
get_ping_stats() {
    local domain="$1"
    echo -e "\n=== Network Performance ===\n"
    echo "Ping statistics (10 packets):"
    ping -c 10 "$domain" | grep -E "packet loss|min/avg/max"
}

# Main function to coordinate all checks
analyze_domain() {
    local domain="$1"
    
    echo -e "\nStarting analysis for: $domain\n"
    
    # Run all checks
    get_whois "$domain"
    get_dns_records "$domain"
    get_ssl_info "$domain"
    get_hosting_info "$domain"
    check_blacklist "$domain"
    get_ping_stats "$domain"
    
    echo -e "\nAnalysis complete for $domain"
}

# Helper function to display IP information
check_ip_info() {
    echo -e "\n=== Your Public IP Information ===\n"
    local ipinfo=$(curl -s https://ipinfo.io/json)
    
    echo "IP Address: $(jq -r '.ip' <<< "$ipinfo")"
    echo "Hostname: $(jq -r '.hostname' <<< "$ipinfo")"
    echo "City: $(jq -r '.city' <<< "$ipinfo")"
    echo "Region: $(jq -r '.region' <<< "$ipinfo")"
    echo "Country: $(jq -r '.country' <<< "$ipinfo")"
    echo "Location: $(jq -r '.loc' <<< "$ipinfo")"
    echo "ISP: $(jq -r '.org' <<< "$ipinfo")"
}

# Main script execution
main() {
    check_dependencies
    
    if [ "$1" == "ip" ]; then
        check_ip_info
        exit 0
    fi
    
    if [ -z "$1" ]; then
        echo "Usage: $0 <domain>"
        echo "       $0 ip (to check your own IP info)"
        exit 1
    fi
    
    if ! validate_domain "$1"; then
        exit 1
    fi
    
    analyze_domain "$1"
}

main "$@"
