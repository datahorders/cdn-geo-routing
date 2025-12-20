# CDN Geo-Routing Toolkit

A self-service tool for configuring AWS Route 53 geo-based DNS routing to datahorders CDN nodes.

## Overview

This toolkit helps CDN customers set up geolocation-based DNS routing in **AWS Route 53** for their domains. Point your domain to our regional CDN endpoints, and get automatic failover with health checks.

**Requirements:**
- AWS account with Route 53
- Domain hosted in Route 53
- AWS CLI configured

## Available CDN Endpoints

All endpoints have automatic failover with health checks built in. If the primary server goes down, traffic automatically routes to the backup.

| Endpoint | Location | Failover To |
|----------|----------|-------------|
| `cdn-sea.datahorders.org` | Seattle, WA | Los Angeles |
| `cdn-lax.datahorders.org` | Los Angeles, CA | Fremont |
| `cdn-zendc.datahorders.org` | Fremont, CA | Los Angeles |
| `cdn-dal.datahorders.org` | Dallas, TX | Los Angeles |
| `cdn-ord.datahorders.org` | Chicago, IL | New York |
| `cdn-nyc.datahorders.org` | New York, NY | Dallas |
| `cdn-mia.datahorders.org` | Miami, FL | Fremont |
| `cdn-lhr.datahorders.org` | London, UK | Amsterdam |
| `cdn-ams.datahorders.org` | Amsterdam, NL | London |
| `cdn-sgp.datahorders.org` | Singapore | Los Angeles |
| `cdn-aus.datahorders.org` | Sydney, AU | Los Angeles |

## Quick Start

```bash
# Clone the repo
git clone https://github.com/datahorders/cdn-geo-routing.git
cd cdn-geo-routing

# List available endpoints
./cdn-geo-setup.sh --list-endpoints

# Interactive setup for your domain
./cdn-geo-setup.sh --domain yourdomain.com

# Apply to Route 53
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://yourdomain-com-cdn-records.json
```

## How It Works

```
User Request                    Your DNS                     Our CDN
     │                              │                            │
     ▼                              ▼                            ▼
cdn.example.com  ──►  Geo lookup ──►  cdn-lax.datahorders.org
                      (Europe?)       (or cdn-lhr for EU)
                                              │
                                              ▼
                                      ┌─────────────────┐
                                      │ Route 53 checks │
                                      │ health status   │
                                      └────────┬────────┘
                                               │
                              ┌────────────────┴────────────────┐
                              │                                 │
                        Primary OK?                       Primary Down?
                              │                                 │
                              ▼                                 ▼
                      Return LAX IP                    Return Failover IP
                     (185.193.157.86)                   (208.99.62.241)
```

## Features

- **Automatic Failover**: Health checks run every 30 seconds. If a server fails, traffic routes to backup automatically.
- **60-Second TTL**: Fast failover - clients get new IP within 60 seconds of a failure.
- **No AWS Access Required**: All health checks and failover logic runs on our side.
- **Global Coverage**: 11 nodes across North America, Europe, Asia, and Oceania.

## AWS Route 53 Setup

The script generates a ready-to-use JSON change batch. Apply it with:

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://yourdomain-cdn-records.json
```

### Finding Your Hosted Zone ID

```bash
aws route53 list-hosted-zones --query "HostedZones[?Name=='yourdomain.com.'].Id" --output text
```

## US State-Level Routing

The setup script supports granular US state routing (51 states + DC), matching our traffic policy:

| CDN Node | States |
|----------|--------|
| **SEA** (Seattle) | WA, OR, ID, MT, AK |
| **LAX** (Los Angeles) | CA, NV, AZ, UT, HI, WY |
| **DAL** (Dallas) | TX, OK, NM, AR, LA, KS, CO, GA, SC, AL, MS, TN, KY |
| **ORD** (Chicago) | IL, WI, MN, IA, MO, NE, SD, ND, MI, IN |
| **NYC** (New York) | NY, NJ, PA, CT, MA, RI, NH, VT, ME, DE, MD, DC, OH, WV, VA, NC |
| **MIA** (Miami) | FL |
| **SEA** | Canada |
| **DAL** | Mexico |

Each endpoint has automatic failover:
- SEA → LAX
- LAX → ZenDC
- DAL → LAX
- ORD → NYC
- NYC → DAL
- MIA → ZenDC

## Recommended Regional Mapping

| Region | Recommended Endpoint |
|--------|---------------------|
| US West (CA, WA, OR, NV, AZ) | `cdn-lax.datahorders.org` or `cdn-sea.datahorders.org` |
| US Central (TX, IL, CO) | `cdn-dal.datahorders.org` or `cdn-ord.datahorders.org` |
| US East (NY, FL, GA) | `cdn-nyc.datahorders.org` or `cdn-mia.datahorders.org` |
| Canada | `cdn-sea.datahorders.org` |
| Mexico / Central America | `cdn-dal.datahorders.org` |
| South America | `cdn-mia.datahorders.org` |
| Western Europe (UK, FR, ES) | `cdn-lhr.datahorders.org` |
| Central/Eastern Europe | `cdn-ams.datahorders.org` |
| Middle East | `cdn-ams.datahorders.org` |
| Asia | `cdn-sgp.datahorders.org` |
| Australia / Oceania | `cdn-aus.datahorders.org` |

## Testing

After setting up DNS, verify resolution:

```bash
# Basic test
dig cdn.yourdomain.com +short

# Test from different regions (using public DNS)
dig cdn.yourdomain.com @8.8.8.8 +short      # Google (US)
dig cdn.yourdomain.com @1.1.1.1 +short      # Cloudflare
dig cdn.yourdomain.com @9.9.9.9 +short      # Quad9
```

## Customizing Your Routing

### Example: Bypass Australia and Route to Los Angeles

If you want to skip the Australian CDN node and route all Oceania traffic to Los Angeles instead:

1. **During interactive setup**, when prompted for Oceania, select `lax` instead of `aus`

2. **Or edit the generated JSON** - change the Oceania record:

```json
{
  "Action": "UPSERT",
  "ResourceRecordSet": {
    "Name": "cdn.yourdomain.com",
    "Type": "CNAME",
    "SetIdentifier": "cdn.yourdomain.com-oc",
    "GeoLocation": {"ContinentCode": "OC"},
    "TTL": 300,
    "ResourceRecords": [{"Value": "cdn-lax.datahorders.org"}]
  }
}
```

3. **Apply the change:**
```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://yourdomain-com-cdn-records.json
```

Now all Australian/Oceania users will be routed to Los Angeles, with automatic failover to Fremont (ZenDC) if LAX goes down.

### Other Common Customizations

| Scenario | Change Endpoint To |
|----------|-------------------|
| Skip Australia → use LAX | `cdn-lax.datahorders.org` for OC |
| Skip Singapore → use LAX | `cdn-lax.datahorders.org` for AS |
| All Europe → London only | `cdn-lhr.datahorders.org` for EU |
| All US → single endpoint | Remove US state records, use `cdn-lax.datahorders.org` for NA |

## Troubleshooting

### DNS not resolving
- Wait for propagation (up to 48 hours, usually minutes)
- Check your DNS provider's dashboard for errors
- Verify the CNAME target is correct (include the trailing dot in some providers)

### Getting wrong region
- Check your DNS provider's geo routing configuration
- Some providers cache aggressively - try a different resolver
- EDNS Client Subnet may affect routing

### Failover not working
- Failover is handled by our Route 53 - you don't need to configure anything
- If primary is healthy, you'll always get the primary IP
- Test failover by checking: `dig cdn-lax.datahorders.org +short`

## Support

- Issues: [GitHub Issues](https://github.com/datahorders/cdn-geo-routing/issues)
- Email: cdn-support@datahorders.org

## License

MIT License - see [LICENSE](LICENSE)
