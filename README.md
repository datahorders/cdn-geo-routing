# DataHorders CDN Geo-Routing Toolkit

Route your users to the nearest CDN server automatically. This self-service toolkit helps you configure geographic DNS routing for your domain, ensuring users connect to the optimal CDN node based on their location.

## Table of Contents

- [Overview](#overview)
- [Key Benefits](#key-benefits)
- [Quick Start](#quick-start)
- [Available Regional Endpoints](#available-regional-endpoints)
- [Setup Methods](#setup-methods)
  - [Method 1: Manual DNS Setup (Any Provider)](#method-1-manual-dns-setup-any-provider)
  - [Method 2: Using the Setup Script (AWS Route 53)](#method-2-using-the-setup-script-aws-route-53)
- [US State-Level Routing](#us-state-level-routing)
- [International Routing Guide](#international-routing-guide)
- [How Automatic Failover Works](#how-automatic-failover-works)
- [Configuration Examples](#configuration-examples)
- [Testing Your Setup](#testing-your-setup)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Support](#support)

---

## Overview

The DataHorders CDN provides 10 globally distributed edge nodes with built-in automatic failover. Instead of managing complex health checks and failover logic yourself, you simply point your DNS records to our regional endpoints. We handle the rest.

**How it works:**

1. You create CNAME records in your DNS pointing to our regional endpoints
2. When a user requests content, they are directed to the nearest CDN node
3. If that node becomes unavailable, traffic automatically fails over to a backup node
4. No configuration changes needed on your end - failover is instant and automatic

---

## Key Benefits

| Benefit | Description |
|---------|-------------|
| **Zero Failover Configuration** | Failover is built into our endpoints. No health checks to set up on your side. |
| **Automatic Health Monitoring** | We monitor all nodes continuously. If a primary goes down, the backup takes over automatically. |
| **60-Second Failover** | Low TTL means clients receive updated routing within 60 seconds of any node failure. |
| **Global Coverage** | 10 nodes across 4 continents - North America, Europe, Asia, and Oceania. |
| **Simple Setup** | Just create CNAME records. Works with any DNS provider. |
| **No Vendor Lock-in** | Standard DNS CNAMEs mean you can switch providers anytime. |

---

## Quick Start

The fastest way to get started is with a simple CNAME record:

```
cdn.yourdomain.com  CNAME  cdn-lax.datahorders.org
```

This routes all your CDN traffic to Los Angeles with automatic failover to Dallas.

For geographic routing (different regions to different nodes), continue reading below.

---

## Available Regional Endpoints

All endpoints include automatic failover. If the primary node fails health checks, traffic is automatically routed to the failover location.

| Endpoint | Primary Location | Automatic Failover |
|----------|-----------------|-------------------|
| `cdn-sea.datahorders.org` | Seattle, WA, USA | Los Angeles |
| `cdn-lax.datahorders.org` | Los Angeles, CA, USA | Dallas |
| `cdn-dal.datahorders.org` | Dallas, TX, USA | Los Angeles |
| `cdn-ord.datahorders.org` | Chicago, IL, USA | New York |
| `cdn-nyc.datahorders.org` | New York, NY, USA | Dallas |
| `cdn-mia.datahorders.org` | Miami, FL, USA | Dallas |
| `cdn-lhr.datahorders.org` | London, UK | Amsterdam |
| `cdn-ams.datahorders.org` | Amsterdam, Netherlands | London |
| `cdn-sgp.datahorders.org` | Singapore | Los Angeles |
| `cdn-aus.datahorders.org` | Sydney, Australia | Los Angeles |

### Choosing the Right Endpoint

| Your Users Are In | Recommended Endpoint |
|-------------------|---------------------|
| US West Coast | `cdn-lax.datahorders.org` or `cdn-sea.datahorders.org` |
| US Central | `cdn-dal.datahorders.org` or `cdn-ord.datahorders.org` |
| US East Coast | `cdn-nyc.datahorders.org` or `cdn-mia.datahorders.org` |
| Canada | `cdn-sea.datahorders.org` |
| Mexico / Central America | `cdn-dal.datahorders.org` |
| South America | `cdn-mia.datahorders.org` |
| UK / Western Europe | `cdn-lhr.datahorders.org` |
| Central / Eastern Europe | `cdn-ams.datahorders.org` |
| Middle East | `cdn-ams.datahorders.org` |
| Asia / Pacific | `cdn-sgp.datahorders.org` |
| Australia / New Zealand | `cdn-aus.datahorders.org` |

---

## Setup Methods

### Method 1: Manual DNS Setup (Any Provider)

This method works with any DNS provider (Cloudflare, GoDaddy, Namecheap, Google Cloud DNS, etc.).

#### Simple Setup (Single Endpoint)

If most of your users are in one region, use a single CNAME:

```
cdn.yourdomain.com    CNAME    cdn-lax.datahorders.org
```

#### Geographic Routing Setup

For providers that support geo-DNS (AWS Route 53, NS1, Cloudflare Enterprise, etc.), create location-based CNAME records:

| Location | Record | Target |
|----------|--------|--------|
| North America | `cdn.yourdomain.com` | `cdn-lax.datahorders.org` |
| South America | `cdn.yourdomain.com` | `cdn-mia.datahorders.org` |
| Europe | `cdn.yourdomain.com` | `cdn-ams.datahorders.org` |
| Africa | `cdn.yourdomain.com` | `cdn-lhr.datahorders.org` |
| Asia | `cdn.yourdomain.com` | `cdn-sgp.datahorders.org` |
| Oceania | `cdn.yourdomain.com` | `cdn-aus.datahorders.org` |
| Default (Fallback) | `cdn.yourdomain.com` | `cdn-lax.datahorders.org` |

**Note:** The exact steps vary by provider. Consult your DNS provider's documentation for geo-routing or geolocation DNS setup.

---

### Method 2: Using the Setup Script (AWS Route 53)

If your domain is hosted in AWS Route 53, our setup script generates ready-to-use configuration files.

#### Prerequisites

- AWS CLI installed and configured
- Domain hosted in AWS Route 53
- Appropriate IAM permissions for Route 53

#### Installation

```bash
# Clone the repository
git clone https://github.com/datahorders/cdn-geo-routing.git
cd cdn-geo-routing

# Make the script executable
chmod +x cdn-geo-setup.sh
```

#### Usage

**List available endpoints:**

```bash
./cdn-geo-setup.sh --list-endpoints
```

**Interactive setup for your domain:**

```bash
./cdn-geo-setup.sh --domain yourdomain.com
```

The script will:
1. Ask which subdomain to use (default: `cdn`)
2. Let you choose an endpoint for each continent
3. Generate a Route 53-compatible JSON file
4. Provide the AWS CLI command to apply the changes

**Apply the generated configuration:**

```bash
# Find your hosted zone ID
aws route53 list-hosted-zones --query "HostedZones[?Name=='yourdomain.com.'].Id" --output text

# Apply the configuration
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://yourdomain-com-cdn-records.json
```

---

## US State-Level Routing

For customers requiring granular US routing, our endpoints are optimized for specific regions. When configuring state-level geo-routing in your DNS provider, use this mapping:

### Western United States

| States | Recommended Endpoint |
|--------|---------------------|
| Washington, Oregon, Idaho, Montana, Alaska | `cdn-sea.datahorders.org` (Seattle) |
| California, Nevada, Arizona, Utah, Hawaii, Wyoming | `cdn-lax.datahorders.org` (Los Angeles) |

### Central United States

| States | Recommended Endpoint |
|--------|---------------------|
| Texas, Oklahoma, New Mexico, Arkansas, Louisiana, Kansas, Colorado, Georgia, South Carolina, Alabama, Mississippi, Tennessee, Kentucky | `cdn-dal.datahorders.org` (Dallas) |
| Illinois, Wisconsin, Minnesota, Iowa, Missouri, Nebraska, South Dakota, North Dakota, Michigan, Indiana | `cdn-ord.datahorders.org` (Chicago) |

### Eastern United States

| States | Recommended Endpoint |
|--------|---------------------|
| New York, New Jersey, Pennsylvania, Connecticut, Massachusetts, Rhode Island, New Hampshire, Vermont, Maine, Delaware, Maryland, Washington DC, Ohio, West Virginia, Virginia, North Carolina | `cdn-nyc.datahorders.org` (New York) |
| Florida | `cdn-mia.datahorders.org` (Miami) |

### State Abbreviation Reference

| Endpoint | State Codes |
|----------|-------------|
| **Seattle** | WA, OR, ID, MT, AK |
| **Los Angeles** | CA, NV, AZ, UT, HI, WY |
| **Dallas** | TX, OK, NM, AR, LA, KS, CO, GA, SC, AL, MS, TN, KY |
| **Chicago** | IL, WI, MN, IA, MO, NE, SD, ND, MI, IN |
| **New York** | NY, NJ, PA, CT, MA, RI, NH, VT, ME, DE, MD, DC, OH, WV, VA, NC |
| **Miami** | FL |

---

## International Routing Guide

### North America (Non-US)

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| Canada (Western) | `cdn-sea.datahorders.org` |
| Canada (Eastern) | `cdn-nyc.datahorders.org` |
| Mexico | `cdn-dal.datahorders.org` |
| Central America | `cdn-dal.datahorders.org` |
| Caribbean | `cdn-mia.datahorders.org` |

### South America

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| All countries | `cdn-mia.datahorders.org` |

### Europe

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| UK, Ireland, France, Spain, Portugal, Belgium, Iceland | `cdn-lhr.datahorders.org` |
| Germany, Netherlands, Austria, Switzerland, Scandinavia, Eastern Europe, Italy, Balkans | `cdn-ams.datahorders.org` |

### Middle East & Africa

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| North Africa (Morocco, Algeria, Tunisia, Libya, Egypt) | `cdn-ams.datahorders.org` |
| Sub-Saharan Africa | `cdn-lhr.datahorders.org` |
| Middle East (UAE, Saudi Arabia, Israel, etc.) | `cdn-ams.datahorders.org` |

### Asia Pacific

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| China, Hong Kong, Taiwan, Japan, South Korea | `cdn-sgp.datahorders.org` |
| Southeast Asia (Singapore, Malaysia, Thailand, Vietnam, Philippines, Indonesia) | `cdn-sgp.datahorders.org` |
| India, Pakistan, Bangladesh | `cdn-sgp.datahorders.org` |
| Australia, New Zealand | `cdn-aus.datahorders.org` |

---

## How Automatic Failover Works

Every regional endpoint has automatic failover built in. Here is what happens when you point your DNS to one of our endpoints:

```
Your User                    Your DNS                    Our CDN Infrastructure
    |                            |                               |
    | 1. Request                 |                               |
    |   cdn.yourdomain.com       |                               |
    |--------------------------->|                               |
    |                            |                               |
    |                   2. Return CNAME                          |
    |                      cdn-lax.datahorders.org               |
    |<---------------------------|                               |
    |                                                            |
    | 3. Resolve cdn-lax.datahorders.org                         |
    |--------------------------------------------------------------->|
    |                                                            |
    |                            4. Health Check                 |
    |                               Is LAX healthy?              |
    |                                    |                       |
    |                         +----------+----------+            |
    |                         |                     |            |
    |                       YES                    NO            |
    |                         |                     |            |
    |                   Return LAX IP        Return Dallas IP    |
    |                    (Primary)             (Failover)        |
    |<---------------------------------------------------------------|
    |                                                            |
    | 5. Connect to CDN server                                   |
    |--------------------------------------------------------------->|
```

### Key Points

- **Health checks run continuously** - We monitor all nodes 24/7
- **Failover is automatic** - No action required from you when a node fails
- **Recovery is automatic** - When a node comes back online, it resumes serving traffic
- **60-second TTL** - Clients will route to the backup within 60 seconds of a failure

---

## Configuration Examples

### Example 1: US-Only Website

For a website primarily serving US users:

```
# Route 53 / Geo-DNS Configuration

cdn.example.com  CNAME  cdn-lax.datahorders.org   [US-West: CA, WA, OR, NV, AZ]
cdn.example.com  CNAME  cdn-dal.datahorders.org   [US-Central: TX, CO, etc.]
cdn.example.com  CNAME  cdn-nyc.datahorders.org   [US-East: NY, PA, etc.]
cdn.example.com  CNAME  cdn-mia.datahorders.org   [US-Southeast: FL]
cdn.example.com  CNAME  cdn-lax.datahorders.org   [Default fallback]
```

### Example 2: Global Website

For a website serving users worldwide:

```
cdn.example.com  CNAME  cdn-lax.datahorders.org   [North America]
cdn.example.com  CNAME  cdn-mia.datahorders.org   [South America]
cdn.example.com  CNAME  cdn-ams.datahorders.org   [Europe]
cdn.example.com  CNAME  cdn-lhr.datahorders.org   [Africa]
cdn.example.com  CNAME  cdn-sgp.datahorders.org   [Asia]
cdn.example.com  CNAME  cdn-aus.datahorders.org   [Oceania]
cdn.example.com  CNAME  cdn-lax.datahorders.org   [Default]
```

### Example 3: AWS Route 53 JSON

Complete Route 53 change batch for global geo-routing:

```json
{
  "Comment": "Geo-routing for cdn.example.com using DataHorders CDN",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "cdn.example.com",
        "Type": "CNAME",
        "SetIdentifier": "cdn-na",
        "GeoLocation": {"ContinentCode": "NA"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-lax.datahorders.org"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "cdn.example.com",
        "Type": "CNAME",
        "SetIdentifier": "cdn-sa",
        "GeoLocation": {"ContinentCode": "SA"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-mia.datahorders.org"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "cdn.example.com",
        "Type": "CNAME",
        "SetIdentifier": "cdn-eu",
        "GeoLocation": {"ContinentCode": "EU"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-ams.datahorders.org"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "cdn.example.com",
        "Type": "CNAME",
        "SetIdentifier": "cdn-af",
        "GeoLocation": {"ContinentCode": "AF"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-lhr.datahorders.org"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "cdn.example.com",
        "Type": "CNAME",
        "SetIdentifier": "cdn-as",
        "GeoLocation": {"ContinentCode": "AS"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-sgp.datahorders.org"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "cdn.example.com",
        "Type": "CNAME",
        "SetIdentifier": "cdn-oc",
        "GeoLocation": {"ContinentCode": "OC"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-aus.datahorders.org"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "cdn.example.com",
        "Type": "CNAME",
        "SetIdentifier": "cdn-default",
        "GeoLocation": {"CountryCode": "*"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "cdn-lax.datahorders.org"}]
      }
    }
  ]
}
```

### Example 4: Simple Single-Region Setup

If you do not need geo-routing and want the simplest possible setup:

**DNS Record (any provider):**
```
cdn.example.com    300    IN    CNAME    cdn-lax.datahorders.org.
```

Or in a typical DNS control panel:
```
Type:   CNAME
Name:   cdn
Target: cdn-lax.datahorders.org
TTL:    300
```

---

## Testing Your Setup

After configuring your DNS records, verify the setup is working correctly.

### Basic Resolution Test

```bash
# Check that your CNAME resolves
dig cdn.yourdomain.com +short

# Expected output: cdn-lax.datahorders.org (or your chosen endpoint)
# Followed by the IP address of that endpoint
```

### Test Endpoint Health

```bash
# Verify our endpoint is resolving
dig cdn-lax.datahorders.org +short

# Should return an IP address
```

### Test from Different Regions

Use different public DNS resolvers to simulate queries from various locations:

```bash
# US-based resolution (Google DNS)
dig cdn.yourdomain.com @8.8.8.8 +short

# Global anycast (Cloudflare)
dig cdn.yourdomain.com @1.1.1.1 +short

# Global anycast (Quad9)
dig cdn.yourdomain.com @9.9.9.9 +short
```

### HTTP Test

```bash
# Test actual content delivery
curl -I https://cdn.yourdomain.com/test-file.txt

# Check which server responded (look for server headers)
curl -sI https://cdn.yourdomain.com/ | grep -i server
```

---

## FAQ

### General Questions

**Q: Do I need an AWS account to use the CDN?**

A: No. You only need an AWS account if you want to use our setup script with AWS Route 53. For manual setup, any DNS provider works.

**Q: How much does this cost?**

A: Contact our sales team for pricing information. DNS configuration on your end uses your existing DNS provider's pricing.

**Q: Can I use multiple endpoints for redundancy?**

A: Yes, but it is not necessary. Each endpoint already has automatic failover built in. If you want geographic distribution, use different endpoints for different regions.

**Q: What is the TTL on your endpoints?**

A: Our endpoints use a 60-second TTL, ensuring fast failover propagation.

### Technical Questions

**Q: What happens if a CDN node goes down?**

A: Traffic is automatically routed to the failover node within 60 seconds. You do not need to do anything.

**Q: Can I use these endpoints at my domain apex (example.com without www)?**

A: Most DNS providers do not allow CNAME records at the apex. Use a subdomain like `cdn.example.com` or check if your provider supports CNAME flattening (Cloudflare) or ALIAS records (Route 53).

**Q: Do you support IPv6?**

A: Contact support for IPv6 availability on specific endpoints.

**Q: What ports do the CDN nodes serve traffic on?**

A: Standard HTTP (80) and HTTPS (443). Contact support if you need custom port configurations.

**Q: How do I verify which node is serving my request?**

A: Check the response headers or use:
```bash
dig cdn-lax.datahorders.org +short
```
Then compare with the IP returned for your domain.

### Setup Questions

**Q: Can I route different content to different endpoints?**

A: DNS routing is based on the user's location, not content type. If you need content-based routing, configure that at the application level after the CDN connection is established.

**Q: How long does DNS propagation take?**

A: Typically minutes, but can take up to 48 hours depending on caching. Using a low TTL (300 seconds) helps speed this up.

**Q: Can I change my routing configuration later?**

A: Yes. Simply update your DNS records. Changes propagate according to the TTL.

---

## Troubleshooting

### DNS Not Resolving

**Symptoms:** `dig cdn.yourdomain.com` returns no results or NXDOMAIN

**Solutions:**
1. Wait for DNS propagation (up to 48 hours, usually minutes)
2. Verify the record was created in your DNS provider's dashboard
3. Check for typos in the CNAME target
4. Ensure you included the trailing dot if your provider requires it (`cdn-lax.datahorders.org.`)

### Getting Wrong Geographic Region

**Symptoms:** Users in Europe are being routed to a US endpoint

**Solutions:**
1. Verify your geo-routing rules are configured correctly
2. Check if your DNS provider is actually applying geo-routing
3. Some DNS providers cache aggressively - test with a resolver you have not used before
4. EDNS Client Subnet (ECS) may affect results depending on your DNS provider

### Slow Performance

**Symptoms:** Content loads slowly despite using the CDN

**Solutions:**
1. Verify users are being routed to the nearest endpoint (check with `dig`)
2. Test the endpoint directly: `curl -w "%{time_total}\n" -o /dev/null -s https://cdn-lax.datahorders.org/`
3. Ensure your origin server is responding quickly
4. Contact support if an endpoint appears to have issues

### Failover Not Working

**Symptoms:** Endpoint returns errors when you expect failover to engage

**Solutions:**
1. Failover is handled entirely on our side - no configuration needed from you
2. Verify you are pointing to our endpoint (e.g., `cdn-lax.datahorders.org`), not directly to an IP
3. Failover engages only when our health checks detect a problem, not based on client-side errors
4. Contact support if you believe an endpoint is down but failover has not triggered

### Certificate Errors

**Symptoms:** SSL/TLS certificate warnings when accessing content

**Solutions:**
1. Ensure your origin serves valid certificates
2. Use the correct domain in your requests
3. Contact support if you see certificate errors on our endpoints

---

## Support

### Resources

- **Documentation:** You are reading it
- **GitHub Repository:** [github.com/datahorders/cdn-geo-routing](https://github.com/datahorders/cdn-geo-routing)
- **Issue Tracker:** [GitHub Issues](https://github.com/datahorders/cdn-geo-routing/issues)

### Contact

- **Technical Support:** cdn-support@datahorders.org
- **Sales Inquiries:** sales@datahorders.org

### Reporting Issues

When reporting issues, please include:

1. Your domain name
2. The endpoint(s) you are using
3. The DNS provider you are using
4. Output of `dig cdn.yourdomain.com +short`
5. Any error messages you are seeing
6. Your geographic location (for routing issues)

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

*Last updated: December 2024*
