# CDN Geo-Routing Toolkit

A self-service tool for configuring geo-based DNS routing to datahorders CDN nodes.

## Overview

This toolkit helps CDN customers set up geolocation-based DNS routing for their domains. Point your domain to our regional CDN endpoints, and get automatic failover with health checks - no AWS access required.

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

### Option 1: Use the Setup Script (Recommended)

```bash
# Clone the repo
git clone https://github.com/datahorders/cdn-geo-routing.git
cd cdn-geo-routing

# List available endpoints
./cdn-geo-setup.sh --list-endpoints

# Interactive setup for your domain
./cdn-geo-setup.sh --domain yourdomain.com
```

### Option 2: Manual Setup

Add CNAME records to your DNS pointing to our regional endpoints:

```
cdn.yourdomain.com  CNAME  cdn-lax.datahorders.org   ; North America
cdn.yourdomain.com  CNAME  cdn-lhr.datahorders.org   ; Europe
cdn.yourdomain.com  CNAME  cdn-sgp.datahorders.org   ; Asia
cdn.yourdomain.com  CNAME  cdn-aus.datahorders.org   ; Oceania
cdn.yourdomain.com  CNAME  cdn-mia.datahorders.org   ; South America
cdn.yourdomain.com  CNAME  cdn-lhr.datahorders.org   ; Africa (default)
```

If your DNS provider supports geolocation routing:
- Route each continent/region to the appropriate endpoint
- The default/fallback should point to your preferred endpoint

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

## DNS Provider Guides

### AWS Route 53

The script generates a ready-to-use JSON change batch:

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://yourdomain-cdn-records.json
```

### Cloudflare

Cloudflare's free tier doesn't support geo DNS. Options:
1. **Cloudflare Load Balancing** (paid) - supports geo steering
2. **Cloudflare Workers** - implement geo routing in code
3. **Single CNAME** - point to one endpoint (e.g., `cdn-lax.datahorders.org`)

### Other Providers

Most enterprise DNS providers support geolocation routing:
- **NS1**: Geo filters in record configuration
- **DNSimple**: Regional records
- **Google Cloud DNS**: Geolocation routing policies

For providers without geo support, use a single CNAME to your preferred regional endpoint.

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
