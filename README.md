# lab-Terraform — Hub & Spoke Azure + OPNsense + VPN IPsec

Lab étudiant : infrastructure Azure **Hub & Spoke** optimisée coûts (UDR uniquement,
**pas de Route Server**), avec un firewall **OPNsense** (NVA 3 interfaces) et un tunnel
**IPsec IKEv2** vers un Fortigate on-prem.

Versionné ici : https://github.com/Crousti-Bats/lab-Terraform

---

## ⚠️ Deux points à lire avant tout

1. **Image Marketplace OPNsense.** Il n'existe pas, à ma connaissance, d'image
   OPNsense officielle « clé en main » publiée au catalogue Azure Marketplace.
   Les valeurs `publisher/offer/sku` dans `variables.tf` (`opnsense_image`) sont des
   **placeholders FreeBSD** et doivent être vérifiées/remplacées. Vérifie le catalogue réel :

   ```bash
   az vm image list --all --publisher <publisher> -o table
   az vm image terms show --urn <publisher>:<offer>:<sku>:<version>
   ```

   Approches possibles : offre communautaire si disponible, **image custom** (upload du
   VHD OPNsense → `azurerm_image`), ou déploiement sur base FreeBSD puis install OPNsense.
   Tant que l'URN n'est pas confirmé, le module `opnsense` ne provisionnera pas une VM
   OPNsense fonctionnelle.

2. **Provider OPNsense.** Tu as cité `opnsense/opnsense`. Le provider réellement publié
   au registry est **`browningluke/opnsense`** (utilisé ici). Vérifie la dernière version
   sur registry.terraform.io. Surtout, le provider **ne couvre pas tout** :
   - **Interface Assignments (zones WAN/LAN/MGMT)** : non gérables en Terraform → à faire
     au premier boot (console/GUI ou `config.xml`).
   - **Outbound NAT** : configuration non fiable via le provider → à faire en GUI.

   D'où une approche **en deux phases** (voir plus bas). Les règles de filtrage
   (LAN→WAN, Fortigate→Spoke) sont, elles, pilotées en Terraform.

   > Mon socle de connaissances s'arrête début 2026 : confirme les schémas de ressources
   > contre la version du provider que tu installes (`terraform providers schema`).

---

## Structure

```
lab-terraform/
├── providers.tf              # azurerm + opnsense, versions
├── variables.tf              # toutes les variables (adressage, secrets, image)
├── main.tf                   # RG + câblage des modules + peerings
├── outputs.tf                # IPs publiques utiles (VPN, MGMT, WAN)
├── terraform.tfvars.example  # gabarit à copier
├── .gitignore                # spécial Terraform
└── modules/
    ├── network/              # VNet hub + spoke, 5 subnets
    ├── vpn/                  # Public IP, VNG VpnGw1, LNG, connexion IKEv2
    ├── opnsense/             # VM OPNsense, 3 NICs ip_forwarding, NSG MGMT
    ├── spoke-vm/             # VM Ubuntu 24.04 dans snet-test
    ├── routing/              # UDR sur snet-test
    └── opnsense-config/      # règles firewall via provider (phase 2)
```

### Réseau

| Bloc                | CIDR              |
|---------------------|-------------------|
| VNet Hub            | 172.16.100.0/24   |
| `GatewaySubnet`     | 172.16.100.0/27   |
| `snet-lan`          | 172.16.100.64/28  |
| `snet-wan`          | 172.16.100.80/28  |
| `snet-mgmt`         | 172.16.100.96/28  |
| VNet Spoke          | 172.16.104.0/24   |
| `snet-test`         | 172.16.104.0/27   |

### Routage (UDR sur `snet-test`)

- `10.118.255.0/24` (on-prem) → **VirtualNetworkGateway** : trafic vers le tunnel VPN.
- `0.0.0.0/0` → **VirtualAppliance** (IP LAN OPNsense `172.16.100.68`) : sortie Internet
  inspectée / NATée par OPNsense.

Le peering est configuré avec `allow_gateway_transit` (hub) + `use_remote_gateways`
(spoke) pour que le spoke atteigne le tunnel **sans Route Server**.

---

## Prérequis

- Terraform >= 1.6, Azure CLI connecté (`az login`).
- Une souscription Azure (mettre l'ID dans `subscription_id`).
- URN de l'image OPNsense vérifié (voir avertissement plus haut).

---

## Lancer

```bash
cp terraform.tfvars.example terraform.tfvars
# éditer terraform.tfvars : subscription_id, vpn_psk, mots de passe, image OPNsense

terraform init
terraform plan
terraform apply
```

> La VPN Gateway met **~20-45 min** à se provisionner. Les peerings sont créés
> après la gateway (dépendance explicite) pour éviter une erreur `use_remote_gateways`.

### Phase 2 — configuration OPNsense (optionnelle)

1. Boot OPNsense : assigner les interfaces aux zones WAN/LAN/MGMT, activer l'API
   (System > Access > Users → clé/secret API), régler l'**Outbound NAT** (source = Spoke).
2. Récupérer l'IP MGMT : `terraform output opnsense_mgmt_public_ip`.
3. Dans `terraform.tfvars` : `enable_opnsense_config = true`, renseigner
   `opnsense_url`, `opnsense_api_key`, `opnsense_api_secret`.
4. `terraform apply` → applique les règles de filtrage LAN→WAN et Fortigate→Spoke.

---

## 💸 Coûts — `terraform destroy` est OBLIGATOIRE

C'est un lab : **détruis tout dès que tu as fini de tester.**

```bash
terraform destroy
```

Les postes qui coûtent même VM éteintes :

- **VPN Gateway VpnGw1** : facturée à l'heure tant qu'elle existe (~la plus grosse
  ligne du lab, de l'ordre de 100+ €/mois). **Ne s'arrête pas** : seul `destroy` stoppe la facture.
- **Public IP Standard** (x3 : VPN, OPNsense WAN, OPNsense MGMT) : facturées à l'existence.
- **VM** OPNsense + Ubuntu + disques managés.

Astuce : si tu veux garder le code mais couper la dépense la plus lourde sans tout
détruire, tu peux cibler la gateway :

```bash
terraform destroy -target=module.vpn
```

Mais le plus sûr pour un lab reste un `terraform destroy` complet en fin de session.

---

## Secrets

Aucun secret en clair dans le code : `vpn_psk`, mots de passe VM et clés API OPNsense
sont des variables `sensitive`, à fournir via `terraform.tfvars` (ignoré par git) ou des
variables d'environnement `TF_VAR_*`. Le `.gitignore` exclut `*.tfvars`, `*.tfstate`,
`.pem/.key/.env`.

> Le `terraform.tfstate` contient les secrets en clair : ne le commite pas. Pour un usage
> sérieux, passe sur un backend distant chiffré (ex. `azurerm` backend + Storage Account).
