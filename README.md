# lab-Terraform — Azure Hub & Spoke

Lab personnel : déploiement d'une infrastructure réseau **Hub & Spoke** sur Azure
via Terraform, avec un tunnel IPsec site-to-site vers un Fortigate on-premise.

## Architecture

```
                          On-premise (domicile)
                          Fortigate 40F  195.46.235.220
                          LAN 10.118.255.0/24
                                  |
                            IPsec (S2S VPN)
                                  |
        ============== HUB  vnet 172.16.100.0/24 ==============
        | GatewaySubnet     172.16.100.0/27   -> VPN Gateway   |
        | RouteServerSubnet 172.16.100.32/27  -> Route Server  |
        | snet-mgmt         172.16.100.96/28  -> Palo Alto NIC0|
        | snet-wan          172.16.100.80/28  -> Palo Alto NIC1|
        | snet-lan          172.16.100.64/28  -> Palo Alto NIC2|
        =======================================================
                                  |
                            VNet Peering (x2)
                                  |
        ====== SPOKE-TEST  vnet 172.16.104.0/24 ===============
        | snet-test  172.16.104.0/28  -> VM Ubuntu 24.04      |
        =======================================================
```

## Composants

- **Hub** : VNet + 5 subnets, VPN Gateway (RouteBased / VpnGw1), Azure Route Server,
  et une VM **Palo Alto VM-Series** (3 NICs : mgmt / wan / lan, déploiement seul, sans config PAN-OS).
- **Spoke "test"** : VNet + VM Ubuntu, peering bidirectionnel avec le Hub.
- **On-premise** : Local Network Gateway + VPN Connection (IPsec) vers le Fortigate.

## Fichiers

| Fichier                   | Rôle                                            |
|---------------------------|-------------------------------------------------|
| `providers.tf`            | Provider azurerm + version Terraform            |
| `variables.tf`            | Déclaration des variables                       |
| `main.tf`                 | Resource group + plan d'adressage (locals)      |
| `hub.tf`                  | VNet Hub, subnets, Route Server, Palo Alto      |
| `spoke.tf`                | VNet Spoke, peering, VM Ubuntu                  |
| `vpn.tf`                  | VPN Gateway, Local Network Gateway, connexion   |
| `outputs.tf`              | IPs publiques et infos utiles                   |
| `terraform.tfvars.example`| Modèle de variables (à copier, **sans secrets**)|

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az login`)

## Utilisation

```bash
az login

# Copier le modèle puis renseigner les valeurs (subscription, mots de passe, PSK)
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan
terraform apply     # tout monter
terraform destroy   # tout casser
```

## Notes importantes

- **Secrets** : `terraform.tfvars` est ignoré par Git. Ne committez **jamais**
  vos mots de passe / PSK sur un repo public.
- **Durée** : le déploiement du VPN Gateway prend ~30-45 min.
- **Coût** : VPN Gateway, Route Server et la VM Palo Alto sont payants — pensez au
  `terraform destroy` après vos tests. La SKU `byol` Palo Alto nécessite une licence.
- **Route Server** : Azure attribue lui-même les IPs BGP dans le RouteServerSubnet
  (l'IP `172.16.100.36` attendue ressort dans l'output `route_server_bgp_ips`).
- **IPsec / Fortigate** : la connexion utilise les politiques IKE/IPsec Azure par défaut.
  Si le tunnel ne monte pas, ajoutez un bloc `ipsec_policy` dans `vpn.tf` pour faire
  correspondre exactement les paramètres (IKE phase 1/2) du Fortigate.
```
