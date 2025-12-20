#!/bin/zsh
#
# CDN Geo-Routing Generator for External Domains
# Generates DNS records for customers to use datahorders CDN with their own domains
#
# Usage:
#   ./cdn-geo-setup.sh                    Interactive setup
#   ./cdn-geo-setup.sh --domain xyz.org   Start with domain
#   ./cdn-geo-setup.sh --list-endpoints   Show available CDN endpoints
#
# Customers point their DNS to our regional endpoints (cdn-sea.datahorders.org, etc.)
# which have automatic failover with health checks built in.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# CDN Regional Endpoints (with built-in failover)
# Format: endpoint|location|primary_ip|failover_location
declare -A CDN_ENDPOINTS=(
    ["sea"]="cdn-sea.datahorders.org|Seattle, WA|192.169.45.56|Los Angeles"
    ["lax"]="cdn-lax.datahorders.org|Los Angeles, CA|185.193.157.86|Fremont"
    ["zendc"]="cdn-zendc.datahorders.org|Fremont, CA|208.99.62.241|Los Angeles"
    ["dal"]="cdn-dal.datahorders.org|Dallas, TX|192.34.101.21|Los Angeles"
    ["ord"]="cdn-ord.datahorders.org|Chicago, IL|193.239.236.132|New York"
    ["nyc"]="cdn-nyc.datahorders.org|New York, NY|162.249.168.179|Dallas"
    ["mia"]="cdn-mia.datahorders.org|Miami, FL|199.127.63.5|Fremont"
    ["lhr"]="cdn-lhr.datahorders.org|London, UK|57.129.130.174|Amsterdam"
    ["ams"]="cdn-ams.datahorders.org|Amsterdam, NL|94.75.213.19|London"
    ["sgp"]="cdn-sgp.datahorders.org|Singapore|77.83.241.35|Los Angeles"
    ["aus"]="cdn-aus.datahorders.org|Sydney, AU|103.1.215.87|Los Angeles"
)

ENDPOINT_ORDER=("sea" "lax" "zendc" "dal" "ord" "nyc" "mia" "lhr" "ams" "sgp" "aus")

# Continent codes
CONTINENTS=("NA" "SA" "EU" "AF" "AS" "OC")
declare -A CONTINENT_NAMES=(
    ["NA"]="North America"
    ["SA"]="South America"
    ["EU"]="Europe"
    ["AF"]="Africa"
    ["AS"]="Asia"
    ["OC"]="Oceania"
)

# Default/recommended endpoint per continent
declare -A DEFAULT_CONTINENT_ENDPOINT=(
    ["NA"]="lax"
    ["SA"]="mia"
    ["EU"]="ams"
    ["AF"]="lhr"
    ["AS"]="sgp"
    ["OC"]="aus"
)

# User selections
CUSTOMER_DOMAIN=""
declare -A USER_ROUTING
SUBDOMAIN="cdn"  # Default subdomain for CDN

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}       CDN Geo-Routing Setup for External Domains${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${BOLD}${CYAN}▶ $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

get_endpoint_info() {
    local endpoint=$1
    local field=$2
    local info="${CDN_ENDPOINTS[$endpoint]}"

    case $field in
        hostname) echo "$info" | cut -d'|' -f1 ;;
        location) echo "$info" | cut -d'|' -f2 ;;
        ip) echo "$info" | cut -d'|' -f3 ;;
        failover) echo "$info" | cut -d'|' -f4 ;;
    esac
}

show_endpoints() {
    echo -e "${BOLD}Available CDN Regional Endpoints:${NC}"
    echo ""
    printf "  %-6s  %-30s  %-20s  %-15s  %s\n" "Code" "Endpoint" "Location" "Primary IP" "Failover To"
    echo "  ──────  ──────────────────────────────  ────────────────────  ───────────────  ─────────────"

    for ep in "${ENDPOINT_ORDER[@]}"; do
        local hostname=$(get_endpoint_info "$ep" "hostname")
        local location=$(get_endpoint_info "$ep" "location")
        local ip=$(get_endpoint_info "$ep" "ip")
        local failover=$(get_endpoint_info "$ep" "failover")
        printf "  %-6s  %-30s  %-20s  %-15s  %s\n" "$ep" "$hostname" "$location" "$ip" "$failover"
    done
    echo ""
    echo -e "${BOLD}Features:${NC}"
    echo "  • All endpoints have automatic failover with health checks"
    echo "  • If primary goes down, traffic automatically routes to failover"
    echo "  • 60-second TTL for fast failover"
    echo ""
}

get_domain() {
    print_step "Step 1: Your Domain"

    if [[ -n "$CUSTOMER_DOMAIN" ]]; then
        echo "Domain: $CUSTOMER_DOMAIN"
    else
        echo "Enter your domain (e.g., example.com, mysite.org):"
        read -r "CUSTOMER_DOMAIN?Domain: "
    fi

    # Validate domain
    if [[ ! "$CUSTOMER_DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]; then
        print_error "Invalid domain format"
        exit 1
    fi

    echo ""
    echo "What subdomain should serve CDN content?"
    echo "  Examples: cdn, assets, static, media"
    read -r "input?Subdomain [cdn]: "
    if [[ -n "$input" ]]; then
        SUBDOMAIN="$input"
    fi

    print_success "Will configure: ${SUBDOMAIN}.${CUSTOMER_DOMAIN}"
}

select_routing() {
    print_step "Step 2: Select CDN Endpoints for Each Region"

    echo "For each continent, choose which CDN endpoint should serve traffic."
    echo "Press Enter to use the recommended endpoint, or enter a number to choose."
    echo ""

    show_endpoints

    for continent in "${CONTINENTS[@]}"; do
        local continent_name="${CONTINENT_NAMES[$continent]}"
        local default_ep="${DEFAULT_CONTINENT_ENDPOINT[$continent]}"
        local default_location=$(get_endpoint_info "$default_ep" "location")

        echo -e "${BOLD}${continent_name} (${continent})${NC} - Recommended: $default_ep ($default_location)"

        local i=1
        for ep in "${ENDPOINT_ORDER[@]}"; do
            local location=$(get_endpoint_info "$ep" "location")
            if [[ "$ep" == "$default_ep" ]]; then
                echo -e "  ${GREEN}$i) $ep - $location (recommended)${NC}"
            else
                echo "  $i) $ep - $location"
            fi
            ((i++))
        done
        echo "  0) Skip this continent"

        read -r "choice?Choice [Enter for $default_ep]: "

        if [[ -z "$choice" ]]; then
            USER_ROUTING[$continent]="$default_ep"
        elif [[ "$choice" == "0" ]]; then
            # Skip
            :
        elif [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le 11 ]; then
            local idx=$((choice - 1))
            USER_ROUTING[$continent]="${ENDPOINT_ORDER[$idx]}"
        else
            print_warning "Invalid choice, using default"
            USER_ROUTING[$continent]="$default_ep"
        fi
        echo ""
    done

    # Default/fallback
    echo -e "${BOLD}Default (Fallback for unlisted regions)${NC}"
    read -r "choice?Endpoint [lax]: "
    if [[ -z "$choice" ]]; then
        USER_ROUTING["DEFAULT"]="lax"
    else
        USER_ROUTING["DEFAULT"]="$choice"
    fi
}

generate_output() {
    print_step "Generated DNS Records"

    local fqdn="${SUBDOMAIN}.${CUSTOMER_DOMAIN}"

    echo -e "${BOLD}Add these records to your DNS provider:${NC}"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│ GEOLOCATION DNS RECORDS                                                     │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"

    for continent in "${CONTINENTS[@]}"; do
        if [[ -n "${USER_ROUTING[$continent]}" ]]; then
            local ep="${USER_ROUTING[$continent]}"
            local hostname=$(get_endpoint_info "$ep" "hostname")
            local location=$(get_endpoint_info "$ep" "location")
            printf "│ %-75s │\n" "${CONTINENT_NAMES[$continent]} ($continent):"
            printf "│   %-73s │\n" "$fqdn  CNAME  $hostname"
        fi
    done

    if [[ -n "${USER_ROUTING[DEFAULT]}" ]]; then
        local ep="${USER_ROUTING[DEFAULT]}"
        local hostname=$(get_endpoint_info "$ep" "hostname")
        echo "├─────────────────────────────────────────────────────────────────────────────┤"
        printf "│ %-75s │\n" "Default (Fallback):"
        printf "│   %-73s │\n" "$fqdn  CNAME  $hostname"
    fi

    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""

    # Route 53 JSON format
    echo -e "${BOLD}Route 53 Format (if using AWS):${NC}"
    echo ""

    local output_file="${CUSTOMER_DOMAIN//\./-}-cdn-records.json"

    local changes=""
    for continent in "${CONTINENTS[@]}"; do
        if [[ -n "${USER_ROUTING[$continent]}" ]]; then
            local ep="${USER_ROUTING[$continent]}"
            local hostname=$(get_endpoint_info "$ep" "hostname")

            if [[ -n "$changes" ]]; then
                changes+=","
            fi
            changes+=$(cat <<EOF

    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${fqdn}",
        "Type": "CNAME",
        "SetIdentifier": "${fqdn}-${continent:l}",
        "GeoLocation": {"ContinentCode": "${continent}"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "${hostname}"}]
      }
    }
EOF
)
        fi
    done

    # Default
    if [[ -n "${USER_ROUTING[DEFAULT]}" ]]; then
        local ep="${USER_ROUTING[DEFAULT]}"
        local hostname=$(get_endpoint_info "$ep" "hostname")
        changes+=","
        changes+=$(cat <<EOF

    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${fqdn}",
        "Type": "CNAME",
        "SetIdentifier": "${fqdn}-default",
        "GeoLocation": {"CountryCode": "*"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "${hostname}"}]
      }
    }
EOF
)
    fi

    cat > "$output_file" <<EOF
{
  "Comment": "Geo-routing for ${fqdn} using datahorders CDN",
  "Changes": [${changes}
  ]
}
EOF

    echo "Saved to: $output_file"
    echo ""
    echo "To apply (if your domain is in Route 53):"
    echo "  aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch file://$output_file"
    echo ""

    # Cloudflare format
    echo -e "${BOLD}Cloudflare Format:${NC}"
    echo ""
    echo "In Cloudflare Dashboard → DNS → Add Record:"
    echo ""
    for continent in "${CONTINENTS[@]}"; do
        if [[ -n "${USER_ROUTING[$continent]}" ]]; then
            local ep="${USER_ROUTING[$continent]}"
            local hostname=$(get_endpoint_info "$ep" "hostname")
            echo "  Type: CNAME | Name: $SUBDOMAIN | Target: $hostname"
            echo "  (Use Page Rules or Workers for geo-routing)"
        fi
    done
    echo ""
    print_info "Note: Cloudflare's free tier doesn't support geo DNS. Use their Load Balancing product or Workers."
    echo ""

    # Simple format
    echo -e "${BOLD}Simple DNS Format (for other providers):${NC}"
    echo ""
    for continent in "${CONTINENTS[@]}"; do
        if [[ -n "${USER_ROUTING[$continent]}" ]]; then
            local ep="${USER_ROUTING[$continent]}"
            local hostname=$(get_endpoint_info "$ep" "hostname")
            echo "$fqdn.  300  IN  CNAME  $hostname."
        fi
    done
    echo ""
}

show_summary() {
    print_step "Summary"

    echo -e "${BOLD}Your CDN Configuration:${NC}"
    echo ""
    printf "  %-20s  %-10s  %-30s\n" "Region" "Endpoint" "CDN Location"
    echo "  ────────────────────  ──────────  ──────────────────────────────"

    for continent in "${CONTINENTS[@]}"; do
        if [[ -n "${USER_ROUTING[$continent]}" ]]; then
            local ep="${USER_ROUTING[$continent]}"
            local location=$(get_endpoint_info "$ep" "location")
            printf "  %-20s  %-10s  %-30s\n" "${CONTINENT_NAMES[$continent]}" "$ep" "$location"
        fi
    done

    if [[ -n "${USER_ROUTING[DEFAULT]}" ]]; then
        local ep="${USER_ROUTING[DEFAULT]}"
        local location=$(get_endpoint_info "$ep" "location")
        printf "  %-20s  %-10s  %-30s\n" "Default (Fallback)" "$ep" "$location"
    fi

    echo ""
    echo -e "${BOLD}How it works:${NC}"
    echo "  1. User requests ${SUBDOMAIN}.${CUSTOMER_DOMAIN}"
    echo "  2. Their DNS returns our CDN endpoint based on their location"
    echo "  3. Our endpoint (e.g., cdn-lax.datahorders.org) has automatic failover"
    echo "  4. If primary server is down, AWS Route 53 returns the backup server"
    echo ""
    echo -e "${BOLD}Testing:${NC}"
    echo "  # After DNS propagates, test with:"
    echo "  dig ${SUBDOMAIN}.${CUSTOMER_DOMAIN} +short"
    echo ""
    echo "  # Test from different regions using DNS resolvers:"
    echo "  dig ${SUBDOMAIN}.${CUSTOMER_DOMAIN} @8.8.8.8 +short  # Google US"
    echo "  dig ${SUBDOMAIN}.${CUSTOMER_DOMAIN} @1.1.1.1 +short  # Cloudflare"
    echo ""
}

# Main
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                CUSTOMER_DOMAIN="$2"
                shift 2
                ;;
            --list-endpoints|--endpoints)
                print_header
                show_endpoints
                exit 0
                ;;
            --help|-h)
                echo "CDN Geo-Routing Generator"
                echo ""
                echo "Usage:"
                echo "  $0                        Interactive setup"
                echo "  $0 --domain example.com   Start with domain"
                echo "  $0 --list-endpoints       Show available CDN endpoints"
                echo ""
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    print_header

    echo "This tool generates DNS records for your domain to use datahorders CDN."
    echo ""
    echo "Our CDN endpoints have automatic failover built-in:"
    echo "  • If a server goes down, traffic automatically routes to backup"
    echo "  • Health checks run every 30 seconds"
    echo "  • No AWS access required on your end"
    echo ""

    get_domain
    select_routing
    show_summary
    generate_output

    print_success "Configuration complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Add the DNS records above to your DNS provider"
    echo "  2. Wait for DNS propagation (up to 48 hours, usually minutes)"
    echo "  3. Test with: dig ${SUBDOMAIN}.${CUSTOMER_DOMAIN} +short"
    echo ""
}

main "$@"
