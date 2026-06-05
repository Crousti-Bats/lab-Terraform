# Guide de test — pas à pas

Les noms de ressources supposent `prefix = "lab"` et `resource_group_name = "rg_lab_agi"`.

---

## Phase 0 — Avant de lancer

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az vm image terms accept --urn decisosalesbv:opnsense:opnsense-be-2025:26.1.6
```

```bash
cp terraform.tfvars.example terraform.tfvars
```

Remplir au minimum : `subscription_id`, `vpn_psk`, `opnsense_admin_password`,
`spoke_vm_admin_password`. Optionnel : `mgmt_allowed_source` et `allowed_ssh_source`
= ton IP publique.

---

## Phase 1 — Déploiement Azure

```bash
terraform init
terraform plan -out tf.plan
terraform apply tf.plan
```

La VPN Gateway prend **20 à 45 min**.

```bash
terraform output
```

Note :
- `vpn_gateway_public_ip` → côté Fortigate
- `opnsense_mgmt_public_ip` → GUI OPNsense
- `spoke_vm_public_ip` → SSH direct sur la VM Ubuntu

---

## Phase 2 — Côté Fortigate (on-prem)

Paramètres à respecter **à l'identique** :

| Paramètre        | Valeur                          |
|------------------|---------------------------------|
| Remote gateway   | `vpn_gateway_public_ip`         |
| IKE version      | IKEv2                           |
| PSK              | = `vpn_psk`                     |
| Phase 1 chiffre. | AES256 / SHA256 / DH group 14   |
| Phase 1 lifetime | 28800 s                         |
| Phase 2 chiffre. | AES256 / SHA256                 |
| Phase 2 PFS      | DH group 14 (2048 bits)         |
| Local subnet     | 10.118.255.0/24                 |
| Remote subnets   | 172.16.100.0/24 et 172.16.104.0/24 |

---

## Phase 3 — Vérifier le tunnel

```bash
az network vpn-connection show \
  -g rg_lab_agi -n cn-lab-onprem \
  --query "{status:connectionStatus, in:ingressBytesTransferred, out:egressBytesTransferred}"
```

Résultat attendu : `"status": "Connected"`.

---

## Phase 4 — Bootstrap OPNsense (manuel, une fois)

1. Ouvre `https://<opnsense_mgmt_public_ip>` — essaie les identifiants du
   déploiement, sinon `root` / `opnsense`.
2. **Interfaces > Assignments** :
   - WAN  → NIC 172.16.100.84
   - LAN  → NIC **172.16.100.68** (doit matcher l'UDR)
   - MGMT → NIC 172.16.100.100
3. Chaque interface en IP statique /28. WAN gateway = `172.16.100.81`.
4. **Firewall > NAT > Outbound** : mode Hybrid, règle source-NAT
   source `172.16.104.0/24`, interface WAN, translation = adresse WAN.
5. **System > Access > Users** : créer clé/secret API pour la phase 6.

---

## Phase 5 — Tests de connectivité

```bash
# SSH direct sur la VM Ubuntu (elle a une IP publique)
ssh azureuser@<spoke_vm_public_ip>

# Depuis la VM :
ping -c4 10.118.255.1                        # on-prem via tunnel
curl -s --max-time 10 ifconfig.me            # doit retourner opnsense_wan_public_ip
traceroute -m 3 8.8.8.8                      # premier hop = 172.16.100.68 (OPNsense)
```

```bash
# Vérifier les routes effectives
az network nic show-effective-route-table \
  -g rg_lab_agi -n nic-lab-ubuntu -o table
```

Résultat attendu : `0.0.0.0/0` → VirtualAppliance `172.16.100.68`,
`10.118.255.0/24` → VirtualNetworkGateway.

---

## Phase 6 — Config OPNsense par Terraform (optionnel)

```hcl
enable_opnsense_config = true
opnsense_url           = "https://<opnsense_mgmt_public_ip>"
opnsense_api_key       = "<clé>"
opnsense_api_secret    = "<secret>"
```

```bash
terraform apply
```

---

## Phase 7 — DESTRUCTION

```bash
terraform destroy
az resource list -g rg_lab_agi -o table
```

Le RG `rg_lab_agi` reste (data source). Vérifie qu'il ne reste pas de VPN GW
ou Public IPs facturées.

---

## Dépannage

**VM OPNsense — nombre de NICs.** `Standard_B2s` ne supporte pas 3 NICs dans
ta région → `opnsense_vm_size = "Standard_B2ms"`.

**Tunnel `NotConnected`.** PSK ou P1/P2 différents côté Fortigate. Comparer
ligne à ligne avec le tableau Phase 2.

**Spoke sans Internet.** Vérifier : UDR associé, Outbound NAT OPNsense,
WAN gateway `172.16.100.81`, LAN IP = `172.16.100.68`.

**GUI OPNsense injoignable.** NSG `mgmt_allowed_source`, bonne IP (MGMT, pas WAN).
