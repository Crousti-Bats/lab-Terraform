# =====================================================================
# LIMITES DU PROVIDER OPNsense (browningluke/opnsense)
# =====================================================================
#
# Le provider expose l'API REST d'OPNsense. Tout n'est PAS pilotable
# en Terraform a date. A configurer manuellement au premier boot
# (console/GUI ou config.xml via cloud-init) :
#
#   1. INTERFACE ASSIGNMENTS (zones WAN/LAN/MGMT)
#      Non gere par le provider. L'assignation des cartes reseau aux
#      zones se fait au premier demarrage (Assign interfaces) ou via
#      un config.xml injecte en custom_data. C'est un prerequis : sans
#      zones nommees "wan"/"lan", les regles de filtrage ci-contre
#      n'ont pas d'interface valide.
#
#   2. OUTBOUND NAT (acces Internet du Spoke via WAN)
#      Passer le mode Outbound NAT en "Hybrid" ou "Manual" et creer la
#      regle source-NAT (source = Spoke CIDR, interface = WAN) n'est pas
#      couvert de maniere fiable par le provider. A faire en GUI :
#      Firewall > NAT > Outbound, ou via config.xml.
#
# Strategie recommandee pour ce lab :
#   - Phase 1 : terraform apply (infra Azure, enable_opnsense_config=false)
#   - Bootstrap OPNsense : assigner les interfaces, activer l'API,
#     regler l'Outbound NAT.
#   - Phase 2 : renseigner opnsense_url/api_key/api_secret,
#     enable_opnsense_config=true, puis terraform apply (regles de filtrage).
# =====================================================================
