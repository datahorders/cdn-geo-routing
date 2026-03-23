# DataHorders CDN Geo-Routing Toolkit

Route your users to the nearest CDN server automatically. This self-service toolkit helps you configure geographic DNS routing for your domain, ensuring users connect to the optimal CDN node based on their location.

> **Note:** Most customers do not need this toolkit. DataHorders CDN automatically routes users to the nearest available server when you use `cname.datahorders.org` as your CNAME target. This toolkit is only for advanced users who want to manually control which regions serve their traffic using their own DNS provider.

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

The DataHorders CDN provides 11 regional pools backed by 19 globally distributed edge nodes with built-in automatic failover. Instead of managing complex health checks and failover logic yourself, you simply point your DNS records to our regional endpoints. We handle the rest.

For the simplest setup, use `cname.datahorders.org` as your CNAME target and we handle all geographic routing automatically. This toolkit is for advanced users who want manual control over which regions serve their traffic.

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
| **Global Coverage** | 11 regional pools across 4 continents backed by 19 edge nodes - North America, Europe, Asia, and Oceania. |
| **Simple Setup** | Just create CNAME records. Works with any DNS provider. |
| **No Vendor Lock-in** | Standard DNS CNAMEs mean you can switch providers anytime. |

---

## Quick Start

The fastest way to get started is with a simple CNAME to our automatic geo-routed entry point:

```
cdn.yourdomain.com  CNAME  cname.datahorders.org
```

This automatically routes all your CDN traffic to the nearest available server with built-in failover. **Most customers should use this and stop here.**

If you want to manually control routing to a specific region instead:

```
cdn.yourdomain.com  CNAME  cdn-us-west-1.datahorders.org
```

This routes all your CDN traffic to Los Angeles with automatic failover to Seattle.

For geographic routing (different regions to different nodes), continue reading below.

---

## Available Regional Endpoints

All endpoints include automatic failover. If the primary pool fails health checks, traffic is automatically routed to the failover location.

| Endpoint | Primary Location | Nodes | Automatic Failover |
|----------|-----------------|-------|-------------------|
| `cdn-us-west-2.datahorders.org` | Seattle, WA, USA | 1 | Los Angeles |
| `cdn-us-west-1.datahorders.org` | Los Angeles, CA, USA | 1 | Seattle |
| `cdn-us-central-1.datahorders.org` | Dallas, TX, USA | 1 | Los Angeles |
| `cdn-us-east-1.datahorders.org` | Ashburn, VA, USA | 5 | Los Angeles |
| `cdn-us-east-2.datahorders.org` | Miami, FL, USA | 1 | Los Angeles |
| `cdn-eu-west-2.datahorders.org` | London, UK | 4 | Amsterdam |
| `cdn-eu-west-1.datahorders.org` | Amsterdam, Netherlands | 1 | London |
| `cdn-eu-central-2.datahorders.org` | Warsaw, Poland | 1 | Amsterdam |
| `cdn-ap-southeast-1.datahorders.org` | Singapore | 2 | Los Angeles |
| `cdn-ap-southeast-2.datahorders.org` | Sydney, Australia | 1 | Los Angeles |

### Choosing the Right Endpoint

| Your Users Are In | Recommended Endpoint |
|-------------------|---------------------|
| US West Coast | `cdn-us-west-1.datahorders.org` or `cdn-us-west-2.datahorders.org` |
| US Central | `cdn-us-central-1.datahorders.org` |
| US East Coast | `cdn-us-east-1.datahorders.org` or `cdn-us-east-2.datahorders.org` |
| Canada (Western) | `cdn-us-west-2.datahorders.org` |
| Canada (Eastern) | `cdn-us-east-1.datahorders.org` |
| Mexico / Central America | `cdn-us-central-1.datahorders.org` |
| South America | `cdn-us-east-2.datahorders.org` |
| UK / Ireland / Africa | `cdn-eu-west-2.datahorders.org` |
| Western Europe (NL, FR, ES, PT, Nordics) | `cdn-eu-west-1.datahorders.org` |
| Central Europe (DE, AT, CH, BE, LU, IT, GR) | `cdn-eu-west-1.datahorders.org` |
| Eastern Europe (PL, CZ, SK, HU, RO, BG, Balkans, Baltics, UA) | `cdn-eu-central-2.datahorders.org` |
| Middle East | `cdn-eu-west-1.datahorders.org` |
| Asia / Pacific | `cdn-ap-southeast-1.datahorders.org` |
| Australia / New Zealand | `cdn-ap-southeast-2.datahorders.org` |

---

## Setup Methods

### Method 1: Manual DNS Setup (Any Provider)

This method works with any DNS provider (Cloudflare, GoDaddy, Namecheap, Google Cloud DNS, etc.).

#### Simple Setup (Single Endpoint)

If most of your users are in one region, use a single CNAME:

```
cdn.yourdomain.com    CNAME    cdn-us-west-1.datahorders.org
```

Or for automatic geo-routing without any manual configuration:

```
cdn.yourdomain.com    CNAME    cname.datahorders.org
```

#### Geographic Routing Setup

For providers that support geo-DNS (AWS Route 53, NS1, Cloudflare Enterprise, etc.), create location-based CNAME records:

| Location | Record | Target |
|----------|--------|--------|
| North America | `cdn.yourdomain.com` | `cdn-us-west-1.datahorders.org` |
| South America | `cdn.yourdomain.com` | `cdn-us-east-2.datahorders.org` |
| Europe | `cdn.yourdomain.com` | `cdn-eu-west-1.datahorders.org` |
| Africa | `cdn.yourdomain.com` | `cdn-eu-west-2.datahorders.org` |
| Asia | `cdn.yourdomain.com` | `cdn-ap-southeast-1.datahorders.org` |
| Oceania | `cdn.yourdomain.com` | `cdn-ap-southeast-2.datahorders.org` |
| Default (Fallback) | `cdn.yourdomain.com` | `cdn-us-west-1.datahorders.org` |

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
| Washington, Oregon, Idaho, Montana, Alaska | `cdn-us-west-2.datahorders.org` (Seattle) |
| California, Nevada, Arizona, Utah, Hawaii, Wyoming | `cdn-us-west-1.datahorders.org` (Los Angeles) |

### Central United States

| States | Recommended Endpoint |
|--------|---------------------|
| Texas, Oklahoma, New Mexico, Arkansas, Louisiana, Kansas, Colorado, Georgia, Alabama, Mississippi, Tennessee, Kentucky | `cdn-us-central-1.datahorders.org` (Dallas) |

### Eastern United States

| States | Recommended Endpoint |
|--------|---------------------|
| Virginia, Maryland, Washington DC, Delaware, West Virginia, North Carolina, South Carolina, New York, New Jersey, Pennsylvania, Connecticut, Massachusetts, Rhode Island, New Hampshire, Vermont, Maine, Ohio, Michigan, Indiana, Illinois, Wisconsin, Minnesota, Iowa, Missouri, Nebraska, South Dakota, North Dakota | `cdn-us-east-1.datahorders.org` (Ashburn) |
| Florida | `cdn-us-east-2.datahorders.org` (Miami) |

### State Abbreviation Reference

| Endpoint | State Codes |
|----------|-------------|
| **Seattle (us-west-2)** | WA, OR, ID, MT, AK |
| **Los Angeles (us-west-1)** | CA, NV, AZ, UT, HI, WY |
| **Dallas (us-central-1)** | TX, OK, NM, AR, LA, KS, CO, GA, AL, MS, TN, KY |
| **Ashburn (us-east-1)** | VA, MD, DC, DE, WV, NC, SC, NY, NJ, PA, CT, MA, RI, NH, VT, ME, OH, MI, IN, IL, WI, MN, IA, MO, NE, SD, ND |
| **Miami (us-east-2)** | FL |

---

## International Routing Guide

### North America (Non-US)

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| Canada (Western) | `cdn-us-west-2.datahorders.org` |
| Canada (Eastern) | `cdn-us-east-1.datahorders.org` |
| Mexico | `cdn-us-central-1.datahorders.org` |
| Central America | `cdn-us-central-1.datahorders.org` |
| Caribbean | `cdn-us-east-2.datahorders.org` |

### South America

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| All countries | `cdn-us-east-2.datahorders.org` |

### Europe

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| UK, Ireland, Iceland | `cdn-eu-west-2.datahorders.org` (London) |
| France, Spain, Portugal, Netherlands, Denmark, Norway, Sweden, Finland | `cdn-eu-west-1.datahorders.org` (Amsterdam) |
| Germany, Austria, Switzerland, Belgium, Luxembourg, Italy, Greece | `cdn-eu-west-1.datahorders.org` (Amsterdam) |
| Poland, Czech Republic, Slovakia, Hungary, Romania, Bulgaria, Balkans, Baltics, Ukraine, Belarus, Moldova | `cdn-eu-central-2.datahorders.org` (Warsaw) |

### Middle East & Africa

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| Sub-Saharan Africa | `cdn-eu-west-2.datahorders.org` (London) |
| North Africa (Morocco, Algeria, Tunisia, Libya, Egypt) | `cdn-eu-west-1.datahorders.org` (Amsterdam) |
| Middle East (UAE, Saudi Arabia, Israel, etc.) | `cdn-eu-west-1.datahorders.org` (Amsterdam) |

### Asia Pacific

| Country/Region | Recommended Endpoint |
|----------------|---------------------|
| China, Hong Kong, Taiwan, Japan, South Korea | `cdn-ap-southeast-1.datahorders.org` |
| Southeast Asia (Singapore, Malaysia, Thailand, Vietnam, Philippines, Indonesia) | `cdn-ap-southeast-1.datahorders.org` |
| India, Pakistan, Bangladesh | `cdn-ap-southeast-1.datahorders.org` |
| Australia, New Zealand | `cdn-ap-southeast-2.datahorders.org` |

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
    |                      cdn-us-west-1.datahorders.org         |
    |<---------------------------|                               |
    |                                                            |
    | 3. Resolve cdn-us-west-1.datahorders.org                   |
    |--------------------------------------------------------------->|
    |                                                            |
    |                            4. Health Check                 |
    |                               Is us-west-1 healthy?       |
    |                                    |                       |
    |                         +----------+----------+            |
    |                         |                     |            |
    |                       YES                    NO            |
    |                         |                     |            |
    |                   Return LAX IP        Return Seattle IP   |
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

cdn.example.com  CNAME  cdn-us-west-1.datahorders.org    [US-West: CA, WA, OR, NV, AZ]
cdn.example.com  CNAME  cdn-us-central-1.datahorders.org  [US-Central: TX, CO, etc.]
cdn.example.com  CNAME  cdn-us-east-1.datahorders.org     [US-East: NY, PA, VA, etc.]
cdn.example.com  CNAME  cdn-us-east-2.datahorders.org     [US-Southeast: FL]
cdn.example.com  CNAME  cdn-us-west-1.datahorders.org     [Default fallback]
```

### Example 2: Global Website

For a website serving users worldwide:

```
cdn.example.com  CNAME  cdn-us-west-1.datahorders.org      [North America]
cdn.example.com  CNAME  cdn-us-east-2.datahorders.org      [South America]
cdn.example.com  CNAME  cdn-eu-west-1.datahorders.org      [Europe]
cdn.example.com  CNAME  cdn-eu-west-2.datahorders.org      [Africa]
cdn.example.com  CNAME  cdn-ap-southeast-1.datahorders.org [Asia]
cdn.example.com  CNAME  cdn-ap-southeast-2.datahorders.org [Oceania]
cdn.example.com  CNAME  cdn-us-west-1.datahorders.org      [Default]
```

### Example 3: AWS Route 53 Traffic Policy (Advanced)

For advanced geo-routing with AWS Route 53, you can use a **Traffic Policy** instead of individual records. Traffic policies support hierarchical routing, where a top-level rule routes to region-specific rules, which then route to individual endpoints.

**How Traffic Policies Work:**

1. **StartRule** - The entry point that routes by continent
2. **Geo Rules** - Each continent rule routes to country or US state-level rules
3. **Endpoints** - The final CNAME targets (our CDN regional endpoints)

This example shows a simplified traffic policy with:
- Continent-level routing at the top
- US state-level routing within North America
- Country-level routing for Europe

```json
{
  "AWSPolicyFormatVersion": "2015-10-01",
  "RecordType": "CNAME",
  "StartRule": "geo-start",
  "Endpoints": {
    "ep-us-west-2": {
      "Type": "value",
      "Value": "cdn-us-west-2.datahorders.org"
    },
    "ep-us-west-1": {
      "Type": "value",
      "Value": "cdn-us-west-1.datahorders.org"
    },
    "ep-us-central-1": {
      "Type": "value",
      "Value": "cdn-us-central-1.datahorders.org"
    },
    "ep-us-east-1": {
      "Type": "value",
      "Value": "cdn-us-east-1.datahorders.org"
    },
    "ep-us-east-2": {
      "Type": "value",
      "Value": "cdn-us-east-2.datahorders.org"
    },
    "ep-eu-west-2": {
      "Type": "value",
      "Value": "cdn-eu-west-2.datahorders.org"
    },
    "ep-eu-west-1": {
      "Type": "value",
      "Value": "cdn-eu-west-1.datahorders.org"
    },
    "ep-eu-central-2": {
      "Type": "value",
      "Value": "cdn-eu-central-2.datahorders.org"
    },
    "ep-ap-southeast-1": {
      "Type": "value",
      "Value": "cdn-ap-southeast-1.datahorders.org"
    },
    "ep-ap-southeast-2": {
      "Type": "value",
      "Value": "cdn-ap-southeast-2.datahorders.org"
    }
  },
  "Rules": {
    "geo-start": {
      "RuleType": "geo",
      "Locations": [
        {
          "IsDefault": true,
          "EndpointReference": "ep-us-west-1"
        },
        {
          "Continent": "NA",
          "RuleReference": "geo-northamerica"
        },
        {
          "Continent": "SA",
          "EndpointReference": "ep-us-east-2"
        },
        {
          "Continent": "EU",
          "RuleReference": "geo-europe"
        },
        {
          "Continent": "AF",
          "EndpointReference": "ep-eu-west-2"
        },
        {
          "Continent": "AS",
          "EndpointReference": "ep-ap-southeast-1"
        },
        {
          "Continent": "OC",
          "EndpointReference": "ep-ap-southeast-2"
        }
      ]
    },
    "geo-northamerica": {
      "RuleType": "geo",
      "Locations": [
        {
          "IsDefault": true,
          "EndpointReference": "ep-us-west-1"
        },
        {
          "Country": "US",
          "Subdivision": "WA",
          "EndpointReference": "ep-us-west-2"
        },
        {
          "Country": "US",
          "Subdivision": "OR",
          "EndpointReference": "ep-us-west-2"
        },
        {
          "Country": "US",
          "Subdivision": "ID",
          "EndpointReference": "ep-us-west-2"
        },
        {
          "Country": "US",
          "Subdivision": "CA",
          "EndpointReference": "ep-us-west-1"
        },
        {
          "Country": "US",
          "Subdivision": "NV",
          "EndpointReference": "ep-us-west-1"
        },
        {
          "Country": "US",
          "Subdivision": "AZ",
          "EndpointReference": "ep-us-west-1"
        },
        {
          "Country": "US",
          "Subdivision": "TX",
          "EndpointReference": "ep-us-central-1"
        },
        {
          "Country": "US",
          "Subdivision": "OK",
          "EndpointReference": "ep-us-central-1"
        },
        {
          "Country": "US",
          "Subdivision": "LA",
          "EndpointReference": "ep-us-central-1"
        },
        {
          "Country": "US",
          "Subdivision": "IL",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "WI",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "MN",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "MI",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "NY",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "NJ",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "PA",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "MA",
          "EndpointReference": "ep-us-east-1"
        },
        {
          "Country": "US",
          "Subdivision": "FL",
          "EndpointReference": "ep-us-east-2"
        },
        {
          "Country": "CA",
          "EndpointReference": "ep-us-west-2"
        },
        {
          "Country": "MX",
          "EndpointReference": "ep-us-central-1"
        }
      ]
    },
    "geo-europe": {
      "RuleType": "geo",
      "Locations": [
        {
          "IsDefault": true,
          "EndpointReference": "ep-eu-west-1"
        },
        {
          "Country": "GB",
          "EndpointReference": "ep-eu-west-2"
        },
        {
          "Country": "IE",
          "EndpointReference": "ep-eu-west-2"
        },
        {
          "Country": "FR",
          "EndpointReference": "ep-eu-west-1"
        },
        {
          "Country": "ES",
          "EndpointReference": "ep-eu-west-1"
        },
        {
          "Country": "DE",
          "EndpointReference": "ep-eu-west-1"
        },
        {
          "Country": "NL",
          "EndpointReference": "ep-eu-west-1"
        },
        {
          "Country": "SE",
          "EndpointReference": "ep-eu-west-1"
        },
        {
          "Country": "NO",
          "EndpointReference": "ep-eu-west-1"
        },
        {
          "Country": "PL",
          "EndpointReference": "ep-eu-central-2"
        },
        {
          "Country": "CZ",
          "EndpointReference": "ep-eu-central-2"
        },
        {
          "Country": "HU",
          "EndpointReference": "ep-eu-central-2"
        },
        {
          "Country": "RO",
          "EndpointReference": "ep-eu-central-2"
        }
      ]
    }
  }
}
```

**Key Concepts in This Example:**

| Concept | Description |
|---------|-------------|
| **StartRule** | The `geo-start` rule is evaluated first for every request |
| **RuleReference** | Routes to another rule (e.g., `geo-northamerica`) for further evaluation |
| **EndpointReference** | Routes directly to a CDN endpoint (e.g., `ep-us-east-2`) |
| **IsDefault** | Catches any location not explicitly matched in the rule |
| **Subdivision** | US state codes for state-level routing (e.g., `WA`, `CA`, `TX`) |

**How Routing Flows:**

```
User in Texas
    |
    v
geo-start (Continent: NA)
    |
    v
geo-northamerica (Country: US, Subdivision: TX)
    |
    v
ep-us-central-1 -> cdn-us-central-1.datahorders.org
```

**Note:** This is a simplified example. The full DataHorders CDN uses this hierarchical approach with all 50 US states, comprehensive country coverage, and failover rules with health checks. You can point your endpoints to our regional endpoints (like `cdn-us-central-1.datahorders.org`) which already have failover built in.

**To use a Traffic Policy:**

1. Create the traffic policy in Route 53
2. Create a traffic policy instance pointing to your hosted zone
3. Specify the DNS name (e.g., `cdn.example.com`)

```bash
# Create the traffic policy
aws route53 create-traffic-policy \
  --name "CDN-GeoRouting" \
  --document file://traffic-policy.json

# Create an instance of the policy
aws route53 create-traffic-policy-instance \
  --hosted-zone-id YOUR_ZONE_ID \
  --name "cdn.example.com" \
  --ttl 300 \
  --traffic-policy-id POLICY_ID \
  --traffic-policy-version 1
```

### Example 4: Simple Single-Region Setup

If you do not need geo-routing and want the simplest possible setup:

**DNS Record (any provider):**
```
cdn.example.com    300    IN    CNAME    cdn-us-west-1.datahorders.org.
```

Or in a typical DNS control panel:
```
Type:   CNAME
Name:   cdn
Target: cdn-us-west-1.datahorders.org
TTL:    300
```

---

## Testing Your Setup

After configuring your DNS records, verify the setup is working correctly.

### Basic Resolution Test

```bash
# Check that your CNAME resolves
dig cdn.yourdomain.com +short

# Expected output: cdn-us-west-1.datahorders.org (or your chosen endpoint)
# Followed by the IP address of that endpoint
```

### Test Endpoint Health

```bash
# Verify our endpoint is resolving
dig cdn-us-west-1.datahorders.org +short

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

**Q: What is the simplest way to use the CDN?**

A: Just create a CNAME record pointing to `cname.datahorders.org`. We handle all geographic routing and failover automatically. This toolkit is only needed if you want to manually control routing.

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
dig cdn-us-west-1.datahorders.org +short
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
4. Ensure you included the trailing dot if your provider requires it (`cdn-us-west-1.datahorders.org.`)

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
2. Test the endpoint directly: `curl -w "%{time_total}\n" -o /dev/null -s https://cdn-us-west-1.datahorders.org/`
3. Ensure your origin server is responding quickly
4. Contact support if an endpoint appears to have issues

### Failover Not Working

**Symptoms:** Endpoint returns errors when you expect failover to engage

**Solutions:**
1. Failover is handled entirely on our side - no configuration needed from you
2. Verify you are pointing to our endpoint (e.g., `cdn-us-west-1.datahorders.org`), not directly to an IP
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

*Last updated: March 2026*
