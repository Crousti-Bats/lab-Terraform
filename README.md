# lab-Terraform — Hub & Spoke Azure + OPNsense + VPN IPsec

Lab étudiant : infrastructure Azure **Hub & Spoke** optimisée coûts (UDR uniquement,
**pas de Route Server**), avec un firewall **OPNsense** (NVA 3 interfaces) et un tunnel
**IPsec IKEv2** vers un Fortigate on-prem.

Repo : https://github.com/Crousti-Bats/lab-Terraform

---

## Structure

```
├── providers.tf              # azurerm + opnsense, versions
├── variables.tf              # toutes les variables (adressage, secrets, image)
├── main.tf                   # data source RG existant (rg_lab_agi)
├── hub.tf                    # VNet hub + 4 subnets (GatewaySubnet, snet-lan/wan/mgmt)
├── spoke.tf                  # VNet spoke + snet-test + VM Ubuntu 24.04
├── vpn.tf                    # Public IP, VNG VpnGw1, LNG Fortigate, connexion IKEv2
├── peering.tf                # peering hub <-> spoke (gateway transit)
├── opnsense.tf               # VM OPNsense Deciso, 3 NICs ip_forwarding, NSG MGMT
├── routing.tf                # UDR sur snet-test (on-prem + default via OPNsense)
├── opnsense-config.tf        # regles firewall via provider OPNsense (phase 2)
├── outputs.tf                # IPs publiques utiles
├── terraform.tfvars.example  # gabarit a copier
├── .gitignore                # special Terraform
├── GUIDE-TEST.md             # runbook de test pas a pas
└── README-LIMITS.md          # limites du provider OPNsense
```

## Réseau

| Bloc                | CIDR              |
|---------------------|-------------------|
| VNet Hub            | 172.16.100.0/24   |
| `GatewaySubnet`     | 172.16.100.0/27   |
| `snet-lan`          | 172.16.100.64/28  |
| `snet-wan`          | 172.16.100.80/28  |
| `snet-mgmt`         | 172.16.100.96/28  |
| VNet Spoke          | 172.16.104.0/24   |
| `snet-test`         | 172.16.104.0/27   |

## Routage (UDR sur `snet-test`)

- `10.118.255.0/24` (on-prem) → **VirtualNetworkGateway** (tunnel VPN).
- `0.0.0.0/0` → **VirtualAppliance** (IP LAN OPNsense `172.16.100.68`).

Le peering utilise `allow_gateway_transit` (hub) + `use_remote_gateways` (spoke).
Les peerings sont dans `peering.tf` avec un `depends_on` sur la VPN Gateway
(sinon `use_remote_gateways` échoue si la gateway n'existe pas encore).

---

## Lancer

```bash
cp terraform.tfvars.example terraform.tfvars
# editer : subscription_id, vpn_psk, mots de passe

terraform init
terraform plan
terraform apply
```

La VPN Gateway prend **20-45 min**. Voir `GUIDE-TEST.md` pour le pas-à-pas complet.

### Phase 2 — configuration OPNsense

1. Assigner les interfaces WAN/LAN/MGMT en GUI, configurer l'Outbound NAT.
2. Activer l'API OPNsense (System > Access > Users → clé/secret).
3. Dans `terraform.tfvars` : `enable_opnsense_config = true` + url/key/secret.
4. `terraform apply` → pousse les règles de filtrage.

Voir `README-LIMITS.md` pour les limites du provider `browningluke/opnsense`.

---

## 💸 Coûts — `terraform destroy` OBLIGATOIRE

```bash
terraform destroy
az resource list -g rg_lab_agi -o table   # verifier qu'il ne reste rien
```

Postes facturés même VM éteintes : **VPN Gateway VpnGw1** (~100+ €/mois),
**Public IP Standard** (x4), VMs + disques.

---

## Secrets

Variables `sensitive` : `vpn_psk`, mots de passe, clés API. Jamais en clair dans le code.
Fournir via `terraform.tfvars` (git-ignoré) ou `TF_VAR_*`.
