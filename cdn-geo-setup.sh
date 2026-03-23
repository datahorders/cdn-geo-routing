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
# Customers point their DNS to our regional pool endpoints
# (cdn-us-west-1.datahorders.org, etc.) which have automatic failover
# with health checks built in.
#
# For the simplest setup, customers can use cname.datahorders.org
# which handles all geographic routing automatically.
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

# CDN Regional Pool Endpoints (with built-in failover)
# Format: endpoint|location|failover_location
declare -A CDN_ENDPOINTS=(
    ["us-west-2"]="cdn-us-west-2.datahorders.org|Seattle, WA|Los Angeles"
    ["us-west-1"]="cdn-us-west-1.datahorders.org|Los Angeles, CA|Seattle"
    ["us-central-1"]="cdn-us-central-1.datahorders.org|Dallas, TX|Los Angeles"
    ["us-east-1"]="cdn-us-east-1.datahorders.org|Ashburn, VA|Los Angeles"
    ["us-east-2"]="cdn-us-east-2.datahorders.org|Miami, FL|Los Angeles"
    ["eu-west-2"]="cdn-eu-west-2.datahorders.org|London, UK|Amsterdam"
    ["eu-west-1"]="cdn-eu-west-1.datahorders.org|Amsterdam, NL|London"
    ["eu-central-2"]="cdn-eu-central-2.datahorders.org|Warsaw, PL|Amsterdam"
    ["ap-southeast-1"]="cdn-ap-southeast-1.datahorders.org|Singapore|Los Angeles"
    ["ap-southeast-2"]="cdn-ap-southeast-2.datahorders.org|Sydney, AU|Los Angeles"
)

ENDPOINT_ORDER=("us-west-2" "us-west-1" "us-central-1" "us-east-1" "us-east-2" "eu-west-2" "eu-west-1" "eu-central-2" "ap-southeast-1" "ap-southeast-2")

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
    ["NA"]="us-west-1"
    ["SA"]="us-east-2"
    ["EU"]="eu-west-1"
    ["AF"]="eu-west-2"
    ["AS"]="ap-southeast-1"
    ["OC"]="ap-southeast-2"
)

# US State routing (matches traffic policy)
# us-west-2: Pacific Northwest
# us-west-1: West Coast / Southwest
# us-central-1: South Central / Southeast
# us-east-1: Northeast / Mid-Atlantic / Midwest
# us-east-2: Florida
declare -A US_STATE_ENDPOINT=(
    # Seattle region (us-west-2)
    ["WA"]="us-west-2" ["OR"]="us-west-2" ["ID"]="us-west-2" ["MT"]="us-west-2" ["AK"]="us-west-2"
    # Los Angeles region (us-west-1)
    ["CA"]="us-west-1" ["NV"]="us-west-1" ["AZ"]="us-west-1" ["UT"]="us-west-1" ["HI"]="us-west-1" ["WY"]="us-west-1"
    # Dallas region (us-central-1)
    ["TX"]="us-central-1" ["OK"]="us-central-1" ["NM"]="us-central-1" ["AR"]="us-central-1" ["LA"]="us-central-1"
    ["KS"]="us-central-1" ["CO"]="us-central-1" ["GA"]="us-central-1" ["AL"]="us-central-1"
    ["MS"]="us-central-1" ["TN"]="us-central-1" ["KY"]="us-central-1"
    # Ashburn region (us-east-1)
    ["VA"]="us-east-1" ["MD"]="us-east-1" ["DC"]="us-east-1" ["DE"]="us-east-1"
    ["WV"]="us-east-1" ["NC"]="us-east-1" ["SC"]="us-east-1"
    ["NY"]="us-east-1" ["NJ"]="us-east-1" ["PA"]="us-east-1" ["CT"]="us-east-1" ["MA"]="us-east-1"
    ["RI"]="us-east-1" ["NH"]="us-east-1" ["VT"]="us-east-1" ["ME"]="us-east-1"
    ["OH"]="us-east-1" ["MI"]="us-east-1" ["IN"]="us-east-1"
    ["IL"]="us-east-1" ["WI"]="us-east-1" ["MN"]="us-east-1" ["IA"]="us-east-1" ["MO"]="us-east-1"
    ["NE"]="us-east-1" ["SD"]="us-east-1" ["ND"]="us-east-1"
    # Miami region (us-east-2)
    ["FL"]="us-east-2"
)

declare -A US_STATE_NAMES=(
    ["AL"]="Alabama" ["AK"]="Alaska" ["AZ"]="Arizona" ["AR"]="Arkansas"
    ["CA"]="California" ["CO"]="Colorado" ["CT"]="Connecticut" ["DE"]="Delaware"
    ["DC"]="District of Columbia" ["FL"]="Florida" ["GA"]="Georgia" ["HI"]="Hawaii"
    ["ID"]="Idaho" ["IL"]="Illinois" ["IN"]="Indiana" ["IA"]="Iowa"
    ["KS"]="Kansas" ["KY"]="Kentucky" ["LA"]="Louisiana" ["ME"]="Maine"
    ["MD"]="Maryland" ["MA"]="Massachusetts" ["MI"]="Michigan" ["MN"]="Minnesota"
    ["MS"]="Mississippi" ["MO"]="Missouri" ["MT"]="Montana" ["NE"]="Nebraska"
    ["NV"]="Nevada" ["NH"]="New Hampshire" ["NJ"]="New Jersey" ["NM"]="New Mexico"
    ["NY"]="New York" ["NC"]="North Carolina" ["ND"]="North Dakota" ["OH"]="Ohio"
    ["OK"]="Oklahoma" ["OR"]="Oregon" ["PA"]="Pennsylvania" ["RI"]="Rhode Island"
    ["SC"]="South Carolina" ["SD"]="South Dakota" ["TN"]="Tennessee" ["TX"]="Texas"
    ["UT"]="Utah" ["VT"]="Vermont" ["VA"]="Virginia" ["WA"]="Washington"
    ["WV"]="West Virginia" ["WI"]="Wisconsin" ["WY"]="Wyoming"
)

# User selections
CUSTOMER_DOMAIN=""
declare -A USER_ROUTING
declare -A USER_US_STATES
SUBDOMAIN="cdn"  # Default subdomain for CDN
USE_US_STATES=false

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
        failover) echo "$info" | cut -d'|' -f3 ;;
    esac
}

show_endpoints() {
    echo -e "${BOLD}Available CDN Regional Pool Endpoints:${NC}"
    echo ""
    printf "  %-16s  %-40s  %-20s  %s\n" "Pool" "Endpoint" "Location" "Failover To"
    echo "  ────────────────  ────────────────────────────────────────  ────────────────────  ─────────────"

    for ep in "${ENDPOINT_ORDER[@]}"; do
        local hostname=$(get_endpoint_info "$ep" "hostname")
        local location=$(get_endpoint_info "$ep" "location")
        local failover=$(get_endpoint_info "$ep" "failover")
        printf "  %-16s  %-40s  %-20s  %s\n" "$ep" "$hostname" "$location" "$failover"
    done
    echo ""
    echo -e "${BOLD}Features:${NC}"
    echo "  • All endpoints have automatic failover with health checks"
    echo "  • If primary goes down, traffic automatically routes to failover"
    echo "  • 60-second TTL for fast failover"
    echo "  • Each pool may be backed by multiple edge nodes for redundancy"
    echo ""
    echo -e "${BOLD}Simple alternative:${NC}"
    echo "  For automatic geo-routing without manual configuration, use:"
    echo "    cdn.yourdomain.com  CNAME  cname.datahorders.org"
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
        elif [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le 10 ]; then
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
    read -r "choice?Endpoint [us-west-1]: "
    if [[ -z "$choice" ]]; then
        USER_ROUTING["DEFAULT"]="us-west-1"
    else
        USER_ROUTING["DEFAULT"]="$choice"
    fi
}

select_us_states() {
    print_step "Step 3: US State-Level Routing (Optional)"

    echo "Do you want granular US state routing? This routes each US state to the nearest CDN node."
    echo ""
    echo "  ${GREEN}1)${NC} Yes - Use recommended state routing (51 states → 5 regional endpoints)"
    echo "     us-west-2:    WA, OR, ID, MT, AK"
    echo "     us-west-1:    CA, NV, AZ, UT, HI, WY"
    echo "     us-central-1: TX, OK, NM, AR, LA, KS, CO, GA, AL, MS, TN, KY"
    echo "     us-east-1:    VA, MD, DC, DE, WV, NC, SC, NY, NJ, PA, CT, MA, RI, NH, VT, ME, OH, MI, IN, IL, WI, MN, IA, MO, NE, SD, ND"
    echo "     us-east-2:    FL"
    echo ""
    echo "  ${YELLOW}2)${NC} No - Use single North America endpoint for all US traffic"
    echo ""

    read -r "choice?Choice [1]: "

    if [[ "$choice" == "2" ]]; then
        USE_US_STATES=false
        print_info "Using single endpoint for all US traffic"
    else
        USE_US_STATES=true
        # Copy default state routing
        for state in "${(@k)US_STATE_ENDPOINT}"; do
            USER_US_STATES[$state]="${US_STATE_ENDPOINT[$state]}"
        done
        print_success "Using granular US state routing (51 records)"
    fi
}

generate_output() {
    print_step "Generated DNS Records"

    local fqdn="${SUBDOMAIN}.${CUSTOMER_DOMAIN}"
    local record_count=0

    echo -e "${BOLD}Add these records to your DNS provider:${NC}"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│ GEOLOCATION DNS RECORDS                                                     │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"

    # US States (if enabled)
    if [[ "$USE_US_STATES" == "true" ]]; then
        printf "│ %-75s │\n" "US State Routing (51 records):"

        # Group states by endpoint for display
        declare -A states_by_ep
        for state in "${(@k)USER_US_STATES}"; do
            local ep="${USER_US_STATES[$state]}"
            if [[ -z "${states_by_ep[$ep]}" ]]; then
                states_by_ep[$ep]="$state"
            else
                states_by_ep[$ep]="${states_by_ep[$ep]}, $state"
            fi
        done

        for ep in "${(@k)states_by_ep}"; do
            local hostname=$(get_endpoint_info "$ep" "hostname")
            printf "│   %-73s │\n" "$ep → $hostname"
            printf "│     %-71s │\n" "States: ${states_by_ep[$ep]}"
        done
        echo "├─────────────────────────────────────────────────────────────────────────────┤"
    fi

    # Continent routing (skip NA if using US states)
    for continent in "${CONTINENTS[@]}"; do
        if [[ "$continent" == "NA" ]] && [[ "$USE_US_STATES" == "true" ]]; then
            continue
        fi
        if [[ -n "${USER_ROUTING[$continent]}" ]]; then
            local ep="${USER_ROUTING[$continent]}"
            local hostname=$(get_endpoint_info "$ep" "hostname")
            printf "│ %-75s │\n" "${CONTINENT_NAMES[$continent]} ($continent):"
            printf "│   %-73s │\n" "$fqdn  CNAME  $hostname"
        fi
    done

    # Canada and Mexico (if using US states)
    if [[ "$USE_US_STATES" == "true" ]]; then
        echo "├─────────────────────────────────────────────────────────────────────────────┤"
        printf "│ %-75s │\n" "Canada (CA):"
        printf "│   %-73s │\n" "$fqdn  CNAME  cdn-us-west-2.datahorders.org"
        printf "│ %-75s │\n" "Mexico (MX):"
        printf "│   %-73s │\n" "$fqdn  CNAME  cdn-us-central-1.datahorders.org"
    fi

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

    # US State records
    if [[ "$USE_US_STATES" == "true" ]]; then
        for state in "${(@k)USER_US_STATES}"; do
            local ep="${USER_US_STATES[$state]}"
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
        "SetIdentifier": "${fqdn}-us-${state:l}",
        "GeoLocation": {"CountryCode": "US", "SubdivisionCode": "${state}"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "${hostname}"}]
      }
    }
EOF
)
            ((record_count++))
        done

        # Canada
        changes+=","
        changes+=$(cat <<EOF

    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${fqdn}",
        "Type": "CNAME",
        "SetIdentifier": "${fqdn}-ca",
        "GeoLocation": {"CountryCode": "CA"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-us-west-2.datahorders.org"}]
      }
    }
EOF
)
        ((record_count++))

        # Mexico
        changes+=","
        changes+=$(cat <<EOF

    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${fqdn}",
        "Type": "CNAME",
        "SetIdentifier": "${fqdn}-mx",
        "GeoLocation": {"CountryCode": "MX"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-us-central-1.datahorders.org"}]
      }
    }
EOF
)
        ((record_count++))
    fi

    # Continent records (skip NA if using US states)
    for continent in "${CONTINENTS[@]}"; do
        if [[ "$continent" == "NA" ]] && [[ "$USE_US_STATES" == "true" ]]; then
            continue
        fi
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
            ((record_count++))
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
        ((record_count++))
    fi

    cat > "$output_file" <<EOF
{
  "Comment": "Geo-routing for ${fqdn} using datahorders CDN",
  "Changes": [${changes}
  ]
}
EOF

    echo "Saved to: $output_file"
    echo "Total records: $record_count"
    echo ""
    echo "To apply (if your domain is in Route 53):"
    echo "  aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch file://$output_file"
    echo ""
}

show_summary() {
    print_step "Summary"

    echo -e "${BOLD}Your CDN Configuration:${NC}"
    echo ""

    # US State routing summary
    if [[ "$USE_US_STATES" == "true" ]]; then
        echo -e "${BOLD}US State Routing:${NC} Enabled (51 states → 5 regional endpoints)"
        echo "  us-west-2:    WA, OR, ID, MT, AK"
        echo "  us-west-1:    CA, NV, AZ, UT, HI, WY"
        echo "  us-central-1: TX, OK, NM, AR, LA, KS, CO, GA, AL, MS, TN, KY"
        echo "  us-east-1:    VA, MD, DC, DE, WV, NC, SC, NY, NJ, PA, CT, MA, RI, NH, VT, ME, OH, MI, IN, IL, WI, MN, IA, MO, NE, SD, ND"
        echo "  us-east-2:    FL"
        echo "  + Canada → us-west-2, Mexico → us-central-1"
        echo ""
    fi

    printf "  %-20s  %-16s  %-30s\n" "Region" "Endpoint" "CDN Location"
    echo "  ────────────────────  ────────────────  ──────────────────────────────"

    for continent in "${CONTINENTS[@]}"; do
        if [[ "$continent" == "NA" ]] && [[ "$USE_US_STATES" == "true" ]]; then
            continue
        fi
        if [[ -n "${USER_ROUTING[$continent]}" ]]; then
            local ep="${USER_ROUTING[$continent]}"
            local location=$(get_endpoint_info "$ep" "location")
            printf "  %-20s  %-16s  %-30s\n" "${CONTINENT_NAMES[$continent]}" "$ep" "$location"
        fi
    done

    if [[ -n "${USER_ROUTING[DEFAULT]}" ]]; then
        local ep="${USER_ROUTING[DEFAULT]}"
        local location=$(get_endpoint_info "$ep" "location")
        printf "  %-20s  %-16s  %-30s\n" "Default (Fallback)" "$ep" "$location"
    fi

    echo ""
    echo -e "${BOLD}Failover:${NC}"
    echo "  Each endpoint has automatic failover with health checks."
    echo "  If primary goes down, traffic routes to backup within 60 seconds."
    echo ""
    echo -e "${BOLD}How it works:${NC}"
    echo "  1. User requests ${SUBDOMAIN}.${CUSTOMER_DOMAIN}"
    echo "  2. Their DNS returns our CDN endpoint based on their location"
    echo "  3. Our endpoint (e.g., cdn-us-west-1.datahorders.org) has automatic failover"
    echo "  4. If primary server is down, traffic is routed to the backup server"
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
                echo "For automatic geo-routing without manual configuration, use:"
                echo "  cdn.yourdomain.com  CNAME  cname.datahorders.org"
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
    echo -e "${YELLOW}Note: For the simplest setup, just CNAME to cname.datahorders.org${NC}"
    echo -e "${YELLOW}which handles all geographic routing automatically.${NC}"
    echo -e "${YELLOW}This tool is for advanced users who want manual control.${NC}"
    echo ""
    echo "Our CDN endpoints have automatic failover built-in:"
    echo "  • If a server goes down, traffic automatically routes to backup"
    echo "  • Health checks run every 30 seconds"
    echo "  • No AWS access required on your end"
    echo ""

    get_domain
    select_routing
    select_us_states
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
