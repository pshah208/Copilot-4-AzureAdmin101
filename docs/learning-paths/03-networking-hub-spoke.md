# 03 – Networking: Hub-Spoke, Private Endpoints, and DNS

## Objectives

By the end of this track you will be able to:

- [ ] Explain hub-and-spoke VNet topology and the role of each component
- [ ] Describe VNet peering and its key constraints (non-transitive, bidirectional)
- [ ] Configure User-Defined Routes (UDRs) to force egress traffic through Azure Firewall
- [ ] Explain private endpoints and how they differ from service endpoints
- [ ] Understand Azure Private DNS Zones and the autoregistration / conditional forwarder pattern

---

## Concepts

### VNet Architecture Recap

A **Virtual Network (VNet)** is an isolated layer-3 network segment in Azure. Subnets divide a VNet into smaller address ranges, each with its own Network Security Group (NSG) and optionally a UDR.

```
Hub VNet (10.0.0.0/16)
├── AzureFirewallSubnet     10.0.0.0/26   ← Azure Firewall (no NSG allowed)
├── AzureBastionSubnet      10.0.1.0/27   ← Azure Bastion (no UDR allowed)
├── GatewaySubnet           10.0.2.0/27   ← VPN/ExpressRoute Gateway
└── ManagementSubnet        10.0.3.0/24   ← Jump servers, automation

Spoke VNet (10.1.0.0/16)
├── AppSubnet               10.1.0.0/24   ← Application workloads
├── DataSubnet              10.1.1.0/24   ← Databases, storage
└── PrivateEndpointSubnet   10.1.2.0/24   ← Private endpoints (disable PE policies)
```

### VNet Peering

VNet peering connects two VNets so traffic flows over the Azure backbone at low latency. Key properties:

| Property | Value |
|---|---|
| Transitivity | **Non-transitive** — Hub↔SpokeA and Hub↔SpokeB does NOT mean SpokeA↔SpokeB |
| Directionality | Bidirectional (both peers must be configured) |
| Cost | Charged per GB transferred across peers |
| Gateway transit | Spokes can use hub's VPN/ER gateway via `use_remote_gateways = true` |

**In this repo** (`terraform/landing-zone/modules/hub-network/main.tf`): peerings are configured bidirectionally — the hub-to-spoke peering and the spoke-to-hub peering are separate `azurerm_virtual_network_peering` resources.

### User-Defined Routes (UDRs)

A UDR overrides Azure's system routes. In hub-spoke, spokes need a UDR to send all traffic through the Firewall:

```hcl
resource "azurerm_route_table" "spoke_udr" {
  name                = "rt-spoke-${var.name}-${var.environment}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}
```

This route table is associated with each spoke subnet so all outbound traffic hits the Firewall first.

### NSG Rules: Deny-All Default

Network Security Groups (NSGs) filter traffic at the subnet (and NIC) level. Best practice: **deny all** by default, then explicitly allow required flows.

```hcl
resource "azurerm_network_security_group" "app" {
  # Inbound
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  # All other inbound denied by the default DenyAllInBound rule (priority 65500)
}
```

### Private Endpoints vs. Service Endpoints

| Feature | Private Endpoint (PE) | Service Endpoint |
|---|---|---|
| Traffic path | Private IP in your VNet — traffic stays on private network | Traffic still leaves VNet via public backbone |
| DNS | Requires Private DNS Zone + private DNS resolver | Uses public DNS |
| Network exposure | PaaS service gets a private IP in your subnet | PaaS service is still on public internet |
| Cost | Per-PE hourly + data processing | Free |
| CAF recommendation | **Preferred** for production | Legacy — use PE instead |

**In this repo**: The Terraform modules create `azurerm_private_dns_zone` resources for common PaaS services. Any PaaS private endpoint linked to the hub's private DNS zone resolves correctly from all peered spokes.

### Azure Private DNS Zones

When a private endpoint is created, Azure needs to resolve the service's hostname (e.g., `mystorageaccount.blob.core.windows.net`) to the private IP instead of the public IP. This is done via a **Private DNS Zone**:

```
privatelink.blob.core.windows.net    ← DNS zone
  mystorageaccount  →  10.1.2.4      ← A record auto-registered by PE
```

The DNS zone must be **linked to every VNet** that needs to resolve the private endpoint. In hub-spoke, link it to the hub; spokes inherit DNS via the hub (using the hub as DNS server, or via the spoke-to-hub peering with DNS forwarding).

```hcl
resource "azurerm_private_dns_zone_virtual_network_link" "hub_link" {
  name                  = "pdnslink-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false   # false for PE zones; true only for VM auto-registration
}
```

---

## Repo Code Walkthrough

### Hub network module resources in order

1. `azurerm_virtual_network` — hub VNet with address space
2. `azurerm_subnet` × 4 — FirewallSubnet, BastionSubnet, GatewaySubnet, ManagementSubnet
3. `azurerm_public_ip` — Firewall PIP (zone-redundant)
4. `azurerm_firewall` — Standard SKU, requires FirewallSubnet
5. `azurerm_firewall_network_rule_collection` — allow rules for spoke-to-spoke, spoke-to-internet
6. `azurerm_bastion_host` — requires BastionSubnet /27 minimum, Standard SKU for tunnelling
7. `azurerm_log_analytics_workspace` — sink for all diagnostic logs
8. `azurerm_monitor_diagnostic_setting` — forwards Firewall logs to LAW

### Spoke network module resources

1. `azurerm_virtual_network` — spoke VNet
2. `azurerm_subnet` — AppSubnet, DataSubnet
3. `azurerm_network_security_group` + association
4. `azurerm_route_table` (UDR) + association — default route to Firewall
5. `azurerm_virtual_network_peering` × 2 — hub-to-spoke + spoke-to-hub

---

## Checkpoint Questions

1. You have Hub↔SpokeA peering and Hub↔SpokeB peering. Can SpokeA VMs reach SpokeB VMs by default?
2. What subnet name is required by Azure Firewall and what is the minimum prefix length?
3. A VM in SpokeA cannot reach `mystorageaccount.blob.core.windows.net` via the private endpoint. What are the three most likely causes?
4. Why is `registration_enabled = false` on the private DNS zone link for private endpoints?

<details>
<summary>Answers (reveal after attempting)</summary>

1. No — VNet peering is **non-transitive**. SpokeA and SpokeB cannot reach each other directly unless: (a) they are peered to each other, OR (b) UDRs on both spokes route cross-spoke traffic through the hub Firewall.
2. `AzureFirewallSubnet` (exact name, no deviation). Minimum `/26` (64 IPs).
3. (a) The Private DNS Zone is not linked to SpokeA's VNet — DNS resolves to the public IP instead; (b) the NSG on the PrivateEndpointSubnet blocks port 443; (c) the UDR routes PE traffic through the Firewall but Firewall rules don't allow it.
4. `registration_enabled` auto-registers VM hostnames. For private endpoint DNS zones (`privatelink.*`), Azure auto-registers the PE's A record — enabling VM registration would mix two unrelated record types in the same zone.

</details>

---

## Hands-On Exercise

Create a storage account with a private endpoint and validate DNS resolution from a spoke VM:

```bash
# 1. Create resource group and VNet (simplified — use the landing zone if already deployed)
az group create --name rg-pe-lab-dev-eastus-001 --location eastus

# 2. Create storage account (no public access)
az storage account create \
  --name stlabpedev$(openssl rand -hex 4) \
  --resource-group rg-pe-lab-dev-eastus-001 \
  --sku Standard_LRS \
  --allow-blob-public-access false \
  --https-only true \
  --min-tls-version TLS1_2

STORAGE_ID=$(az storage account show \
  --name <your-storage-name> \
  --resource-group rg-pe-lab-dev-eastus-001 \
  --query id -o tsv)

# 3. Create private endpoint
az network private-endpoint create \
  --name pe-storage-lab \
  --resource-group rg-pe-lab-dev-eastus-001 \
  --vnet-name <your-vnet> \
  --subnet <your-subnet> \
  --private-connection-resource-id $STORAGE_ID \
  --group-id blob \
  --connection-name pe-conn-storage

# 4. Create private DNS zone and link
az network private-dns zone create \
  --resource-group rg-pe-lab-dev-eastus-001 \
  --name privatelink.blob.core.windows.net

az network private-dns link vnet create \
  --resource-group rg-pe-lab-dev-eastus-001 \
  --zone-name privatelink.blob.core.windows.net \
  --name dns-link-spoke \
  --virtual-network <your-vnet> \
  --registration-enabled false

# 5. Add A record (or let PE auto-register)
az network private-endpoint dns-zone-group create \
  --resource-group rg-pe-lab-dev-eastus-001 \
  --endpoint-name pe-storage-lab \
  --name default \
  --private-dns-zone privatelink.blob.core.windows.net \
  --zone-name privatelink.blob.core.windows.net

# 6. Validate DNS from within the VNet (run on a VM in the spoke)
nslookup <your-storage-name>.blob.core.windows.net
# Expected: resolves to 10.x.x.x (private IP), not 52.x.x.x (public IP)
```

**Clean up**:
```bash
az group delete --name rg-pe-lab-dev-eastus-001 --yes --no-wait
```

---

## Further Reading

| Topic | Link |
|---|---|
| Hub-and-spoke topology | https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke |
| Private Endpoint overview | https://learn.microsoft.com/azure/private-link/private-endpoint-overview |
| Azure Private DNS Zones | https://learn.microsoft.com/azure/dns/private-dns-overview |
| NSG best practices | https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview |
| Azure Firewall documentation | https://learn.microsoft.com/azure/firewall/overview |
