  MMM      MMM       KKK                          TTTTTTTTTTT      KKK
  MMMM    MMMM       KKK                          TTTTTTTTTTT      KKK
  MMM MMMM MMM  III  KKK  KKK  RRRRRR     OOOOOO      TTT     III  KKK  KKK
  MMM  MM  MMM  III  KKKKK     RRR  RRR  OOO  OOO     TTT     III  KKKKK
  MMM      MMM  III  KKK KKK   RRRRRR    OOO  OOO     TTT     III  KKK KKK
  MMM      MMM  III  KKK  KKK  RRR  RRR   OOOOOO      TTT     III  KKK  KKK

  MikroTik RouterOS 7.20.7 (c) 1999-2026       https://www.mikrotik.com/


Press F1 for help


[zestd55@RB4011-GW00] > /export
# 2026-01-11 18:35:14 by RouterOS 7.20.7
# software id = 1111-AAAA
#
# model = RB4011iGS+5HacQ2HnD
# serial number = 000000000000
/interface bridge
add comment="Bridge LAN HomeLAN" name=br-lan
/interface wireless
set [ find default-name=wlan1 ] comment="Disabled - not used" ssid=MikroTik
/interface ethernet
set [ find default-name=ether1 ] comment="ISP1 Primary" name=ether1-WAN1
set [ find default-name=ether2 ] comment="ISP2 Secondary" name=ether2-WAN2
set [ find default-name=ether3 ] comment="HomeLAN to Cudy WR6500H" name=ether3-LAN
set [ find default-name=ether4 ] comment=Reserved name=ether4-LAN
set [ find default-name=ether5 ] comment=Reserved disabled=yes
set [ find default-name=ether6 ] comment=Reserved disabled=yes
set [ find default-name=ether7 ] comment=Reserved disabled=yes
set [ find default-name=ether8 ] comment=Reserved disabled=yes
set [ find default-name=ether9 ] comment=Reserved disabled=yes
set [ find default-name=ether10 ] comment=Reserved disabled=yes
set [ find default-name=sfp-sfpplus1 ] disabled=yes
/interface wireless manual-tx-power-table
set wlan1 comment="Disabled - not used"
/interface wireless nstreme
set wlan1 comment="Disabled - not used"
/interface wireguard
add comment="WireGuard VPN for admins" listen-port=51820 mtu=1420 name=wg-vpn
/interface list
add comment="WAN interfaces" name=WAN
add comment="LAN interfaces" name=LAN
add comment="DMZ interfaces" name=DMZ
add comment="VPN interfaces" name=VPN
add comment="All internal interfaces" name=INTERNAL
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk comment="WPA2 for DMZ" mode=dynamic-keys name=sec-dmz supplicant-identity=MikroTik
/interface wireless
set [ find default-name=wlan2 ] band=5ghz-a/n/ac channel-width=20/40/80mhz-XXXX comment="DMZ Wireless AP 5GHz" default-forwarding=no disabled=no mode=ap-bridge name=wlan2-DMZ \
    security-profile=sec-dmz ssid=HOMELAB-DMZ wps-mode=disabled
/interface wireless manual-tx-power-table
set wlan2-DMZ comment="DMZ Wireless AP 5GHz"
/interface wireless nstreme
set wlan2-DMZ comment="DMZ Wireless AP 5GHz"
/ip pool
add comment="LAN DHCP Pool" name=pool-lan ranges=172.30.30.50-172.30.30.200
add comment="DMZ DHCP Pool" name=pool-dmz ranges=10.100.100.50-10.100.100.99
/ip dhcp-server
add address-pool=pool-lan comment="LAN DHCP Server" interface=br-lan lease-time=1w name=dhcp-lan
# Interface not running
add address-pool=pool-dmz comment="DMZ DHCP Server" interface=wlan2-DMZ lease-time=1w name=dhcp-dmz
/port
set 0 name=serial0
set 1 name=serial1
/routing table
add comment="Routing via ISP1" fib name=to-isp1
add comment="Routing via ISP2" fib name=to-isp2
/interface bridge port
add bridge=br-lan comment="LAN port" interface=ether3-LAN
add bridge=br-lan comment="LAN port" interface=ether4-LAN
/ip firewall connection tracking
set tcp-established-timeout=4h tcp-syn-sent-timeout=10s
/ip neighbor discovery-settings
set discover-interface-list=INTERNAL
/ip settings
set tcp-syncookies=yes
/interface list member
add interface=ether1-WAN1 list=WAN
add interface=ether2-WAN2 list=WAN
add interface=br-lan list=LAN
add interface=wlan2-DMZ list=DMZ
add interface=br-lan list=INTERNAL
add interface=wlan2-DMZ list=INTERNAL
add interface=wg-vpn list=VPN
add interface=wg-vpn list=INTERNAL
/interface wireguard peers
add allowed-address=10.200.200.2/32 comment="Admin Mobile" interface=wg-vpn name=peer1 public-key="00000000000000000000000000000000000000000000"
/ip address
add address=203.0.113.11/24 comment="ISP1 WAN IP" interface=ether1-WAN1 network=203.0.113.0
add address=198.51.100.12/24 comment="ISP2 WAN IP" interface=ether2-WAN2 network=198.51.100.0
add address=172.30.30.1/24 comment="LAN Gateway" interface=br-lan network=172.30.30.0
add address=10.100.100.1/24 comment="DMZ Gateway" interface=wlan2-DMZ network=10.100.100.0
add address=10.200.200.1/24 comment="VPN Gateway" interface=wg-vpn network=10.200.200.0
/ip dhcp-server lease
add address=172.30.30.30 comment="Admin Workstation" mac-address=C8:5E:A9:52:00:00 server=dhcp-lan
add address=172.30.30.105 comment="Admin Laptop" mac-address=A8:7E:EA:71:00:00 server=dhcp-lan
add address=172.30.30.100 comment="Cudy WR6500H" mac-address=10:27:F5:F8:00:00 server=dhcp-lan
/ip dhcp-server network
add address=10.100.100.0/24 comment="DMZ Network" dns-server=8.8.8.8,1.1.1.1 domain=dmz.lab gateway=10.100.100.1
add address=172.30.30.0/24 comment="LAN Network" dns-server=172.30.30.1 domain=home.lan gateway=172.30.30.1
/ip dns
set allow-remote-requests=yes cache-max-ttl=1d cache-size=4096KiB max-concurrent-queries=200 servers=8.8.8.8,77.88.8.88,1.1.1.1,9.9.9.9
/ip firewall address-list
add address=172.30.30.0/24 comment="LAN Network" list=NET-LAN
add address=10.100.100.0/24 comment="DMZ Network" list=NET-DMZ
add address=10.200.200.0/24 comment="VPN Network" list=NET-VPN
add address=172.30.30.0/24 comment="Internal: LAN" list=NET-INTERNAL
add address=10.100.100.0/24 comment="Internal: DMZ" list=NET-INTERNAL
add address=10.200.200.0/24 comment="Internal: VPN" list=NET-INTERNAL
add address=10.0.0.0/8 comment="Private Class A" list=RFC1918
add address=172.16.0.0/12 comment="Private Class B" list=RFC1918
add address=192.168.0.0/16 comment="Private Class C" list=RFC1918
add address=100.64.0.0/10 comment="CGN/Carrier NAT" list=RFC1918
add address=0.0.0.0/8 comment="This network" list=BOGONS
add address=10.0.0.0/8 comment=Private list=BOGONS
add address=100.64.0.0/10 comment=CGN list=BOGONS
add address=127.0.0.0/8 comment=Loopback list=BOGONS
add address=169.254.0.0/16 comment=Link-local list=BOGONS
add address=172.16.0.0/12 comment=Private list=BOGONS
add address=192.0.0.0/24 comment="IETF Protocol" list=BOGONS
add address=192.168.0.0/16 comment=Private list=BOGONS
add address=198.18.0.0/15 comment=Benchmarking list=BOGONS
add address=224.0.0.0/4 comment=Multicast list=BOGONS
add address=240.0.0.0/4 comment=Reserved list=BOGONS
add address=172.30.30.30 comment="Admin Workstation" list=MGMT-SOURCES
add address=172.30.30.105 comment="Admin Laptop" list=MGMT-SOURCES
add address=10.200.200.2 comment="VPN Admins" list=MGMT-SOURCES
add address=10.100.100.50 comment="DMZ Monitoring Server" list=DMZ-MONITORING
add address=10.100.100.100 comment="DMZ Web Server" list=DMZ-WEBSERVER
add address=203.0.113.11 comment="ISP1 WAN IP" list=WAN-IPS
add address=198.51.100.12 comment="ISP2 WAN IP" list=WAN-IPS
add address=87.240.132.72 comment="VKONTAKTE-FRONT - ISP1 check" list=CHECK-HOSTS
add address=95.143.182.1 comment="SELECTEL-NET - ISP2 check" list=CHECK-HOSTS
add comment="TZ: web abuse / scanners (auto)" list=PORT-SCAN
add comment="TZ: generic blacklist 24h" list=BLACKLIST
add address=208.67.222.222 comment="OpenDNS - ISP1 check2" list=CHECK-HOSTS
add address=9.9.9.9 comment="Quad9 - ISP2 check2" list=CHECK-HOSTS
/ip firewall filter
add action=accept chain=input comment="[IN-01] INPUT: Accept established/related" connection-state=established,related
add action=drop chain=input comment="[IN-02] INPUT: Drop invalid state" connection-state=invalid
add action=jump chain=input comment="[IN-03] INPUT: Jump to WAN chain" in-interface-list=WAN jump-target=input-wan
add action=jump chain=input comment="[IN-04] INPUT: Jump to LAN chain" in-interface-list=LAN jump-target=input-lan
add action=jump chain=input comment="[IN-05] INPUT: Jump to DMZ chain" in-interface-list=DMZ jump-target=input-dmz
add action=jump chain=input comment="[IN-06] INPUT: Jump to VPN chain" in-interface-list=VPN jump-target=input-vpn
add action=drop chain=input comment="[IN-07] INPUT: Default drop all"
add action=jump chain=forward comment="[FW-01] FORWARD: SYN Flood check for new TCP" connection-state=new in-interface-list=WAN jump-target=syn-flood protocol=tcp tcp-flags=syn
add action=fasttrack-connection chain=forward comment="[FW-02] FORWARD: FastTrack established/related" connection-mark=no-mark connection-nat-state=!dstnat connection-state=\
    established,related hw-offload=yes
add action=accept chain=forward comment="[FW-03] FORWARD: Accept established/related" connection-state=established,related
add action=drop chain=forward comment="[FW-04] FORWARD: Drop invalid state" connection-state=invalid
add action=jump chain=forward comment="[FW-05] FORWARD: Jump to LAN chain" in-interface-list=LAN jump-target=forward-lan
add action=jump chain=forward comment="[FW-06] FORWARD: Jump to DMZ chain" in-interface-list=DMZ jump-target=forward-dmz
add action=jump chain=forward comment="[FW-07] FORWARD: Jump to VPN chain" in-interface-list=VPN jump-target=forward-vpn
add action=jump chain=forward comment="[FW-08] FORWARD: Jump to WAN chain" in-interface-list=WAN jump-target=forward-wan
add action=log chain=forward comment="[FW-09a] FORWARD: Log (rate-limited) unexpected" limit=5/1m,10:packet log-prefix="[FORWARD-DROP] "
add action=drop chain=forward comment="[FW-09] FORWARD: Default drop all"
add action=accept chain=output comment="[OUT-01] OUTPUT: Accept established/related" connection-state=established,related
add action=drop chain=output comment="[OUT-02] OUTPUT: Drop invalid" connection-state=invalid
add action=accept chain=output comment="[OUT-03] OUTPUT: Allow router-initiated traffic"
add action=add-src-to-address-list address-list=SCANNER address-list-timeout=1d chain=input-wan comment="[IW-01] input-wan: Detect TCP XMAS scan" protocol=tcp tcp-flags=\
    fin,psh,urg,!syn,!rst,!ack
add action=add-src-to-address-list address-list=SCANNER address-list-timeout=1d chain=input-wan comment="[IW-02] input-wan: Detect TCP NULL scan" protocol=tcp tcp-flags=\
    !fin,!syn,!rst,!ack
add action=add-src-to-address-list address-list=SCANNER address-list-timeout=1d chain=input-wan comment="[IW-03] input-wan: Detect SYN-FIN scan" protocol=tcp tcp-flags=fin,syn
add action=add-src-to-address-list address-list=SCANNER address-list-timeout=1d chain=input-wan comment="[IW-04] input-wan: Detect SYN-RST scan" protocol=tcp tcp-flags=syn,rst
add action=add-src-to-address-list address-list=BAD-ACTORS address-list-timeout=1d chain=input-wan comment="[IW-05] input-wan: Escalate SCANNER to BAD-ACTORS" src-address-list=SCANNER
add action=drop chain=input-wan comment="[IW-06] input-wan: Drop SCANNER" src-address-list=SCANNER
add action=drop chain=input-wan comment="[IW-07] input-wan: Drop DNS UDP" dst-port=53 protocol=udp
add action=drop chain=input-wan comment="[IW-08] input-wan: Drop DNS TCP" dst-port=53 protocol=tcp
add action=drop chain=input-wan comment="[IW-09] WireGuard: drop from WG-FLOOD list" connection-state=new dst-port=51820 protocol=udp src-address-list=WG-FLOOD
add action=accept chain=input-wan comment="[IW-10] WireGuard: accept within rate-limit" connection-state=new dst-port=51820 limit=20,5:packet protocol=udp
add action=add-src-to-address-list address-list=WG-FLOOD address-list-timeout=1h chain=input-wan comment="[IW-11] WireGuard: exceed rate -> WG-FLOOD 1h" connection-state=new dst-port=\
    51820 protocol=udp
add action=drop chain=input-wan comment="[IW-12] input-wan: Block ICMP from WAN (policy)" protocol=icmp
add action=drop chain=input-wan comment="[IW-13] input-wan: Drop all other WAN->router"
add action=accept chain=input-lan comment="[IL-01] input-lan: Allow ICMP (policy)" protocol=icmp
add action=accept chain=input-lan comment="[IL-02] input-lan: Allow DNS UDP to router" dst-port=53 protocol=udp
add action=accept chain=input-lan comment="[IL-03] input-lan: Allow DNS TCP to router" dst-port=53 protocol=tcp
add action=accept chain=input-lan comment="[IL-04] input-lan: Allow DHCP" dst-port=67 protocol=udp
add action=accept chain=input-lan comment="[IL-05] input-lan: Allow NTP" dst-port=123 protocol=udp
add action=add-src-to-address-list address-list=LAN-WINBOX-BAD address-list-timeout=1d chain=input-lan comment="[IL-06] Winbox: non-mgmt attempt -> LAN-WINBOX-BAD (24h)" \
    connection-state=new dst-port=8291 protocol=tcp src-address-list=!MGMT-SOURCES
add action=drop chain=input-lan comment="[IL-07] Winbox: drop LAN-WINBOX-BAD" dst-port=8291 protocol=tcp src-address-list=LAN-WINBOX-BAD
add action=accept chain=input-lan comment="[IL-08] input-lan: SSH only from MGMT-ALLOWED" dst-port=22 protocol=tcp src-address-list=MGMT-SOURCES
add action=accept chain=input-lan comment="[IL-09] input-lan: Winbox only from MGMT-ALLOWED" dst-port=8291 protocol=tcp src-address-list=MGMT-SOURCES
add action=accept chain=input-lan comment="[IL-10] input-lan: HTTPS WebUI only from MGMT-ALLOWED" dst-port=443 protocol=tcp src-address-list=MGMT-SOURCES
add action=drop chain=input-lan comment="[IL-11] input-lan: Drop others"
add action=accept chain=input-dmz comment="[ID-01] input-dmz: Accept ICMP DMZ-MONITORING" protocol=icmp src-address-list=DMZ-MONITORING
add action=accept chain=input-dmz comment="[ID-02] input-dmz: Allow DHCP" dst-port=67 protocol=udp
add action=accept chain=input-dmz comment="[ID-03] input-dmz: Allow SNMP from DMZ monitoring" dst-port=161 protocol=udp src-address-list=DMZ-MONITORING
add action=accept chain=input-dmz comment="[ID-04] input-dmz: Allow Syslog from DMZ monitoring" dst-port=514 protocol=udp src-address-list=DMZ-MONITORING
add action=log chain=input-dmz comment="[ID-05] input-dmz: Log mgmt attempts (rate-limited)" dst-port=22,8291,443,8728,8729 limit=2/1m,5:packet log-prefix="[DMZ-MGMT-BLOCK] " \
    protocol=tcp
add action=drop chain=input-dmz comment="[ID-06] input-dmz: Block management access" dst-port=22,8291,443,8728,8729 protocol=tcp
add action=drop chain=input-dmz comment="[ID-07] input-dmz: Drop others"
add action=accept chain=input-vpn comment="[IV-01] input-vpn: Allow ICMP" protocol=icmp
add action=accept chain=input-vpn comment="[IV-02] input-vpn: Allow DNS UDP" dst-port=53 protocol=udp
add action=accept chain=input-vpn comment="[IV-03] input-vpn: Allow DNS TCP" dst-port=53 protocol=tcp
add action=accept chain=input-vpn comment="[IV-04] input-vpn: SSH only from MGMT-ALLOWED" dst-port=22 protocol=tcp src-address-list=MGMT-SOURCES
add action=accept chain=input-vpn comment="[IV-05] input-vpn: Winbox only from MGMT-ALLOWED" dst-port=8291 protocol=tcp src-address-list=MGMT-SOURCES
add action=accept chain=input-vpn comment="[IV-06] input-vpn: HTTPS only from MGMT-ALLOWED" dst-port=443 protocol=tcp src-address-list=MGMT-SOURCES
add action=drop chain=input-vpn comment="[IV-07] input-vpn: Drop others"
add action=accept chain=forward-lan comment="[FL-01] forward-lan: Allow LAN to DMZ" dst-address-list=NET-DMZ
add action=accept chain=forward-lan comment="[FL-02] forward-lan: Allow LAN to VPN (admin access to VPN clients)" dst-address-list=NET-VPN
add action=accept chain=forward-lan comment="[FL-03] forward-lan: Allow LAN to Internet" out-interface-list=WAN
add action=drop chain=forward-lan comment="[FL-04] forward-lan: Drop others"
add action=log chain=forward-dmz comment="[FD-01a] DMZ->LAN log (rate-limited)" dst-address-list=NET-LAN limit=2/1m,5:packet log-prefix="[DMZ->LAN-DROP] "
add action=drop chain=forward-dmz comment="[FD-01] forward-dmz: BLOCK DMZ to LAN" dst-address-list=NET-LAN
add action=log chain=forward-dmz comment="[FD-02a] DMZ->VPN log (rate-limited)" dst-address-list=NET-VPN limit=2/1m,5:packet log-prefix="[DMZ->VPN-DROP] "
add action=drop chain=forward-dmz comment="[FD-02] forward-dmz: BLOCK DMZ to VPN" dst-address-list=NET-VPN
add action=accept chain=forward-dmz comment="[FD-03] forward-dmz: Allow DMZ to Internet" out-interface-list=WAN
add action=drop chain=forward-dmz comment="[FD-04] forward-dmz: Drop others"
add action=accept chain=forward-vpn comment="[FV-01] forward-vpn: Allow VPN to LAN" dst-address-list=NET-LAN
add action=accept chain=forward-vpn comment="[FV-02] forward-vpn: Allow VPN to DMZ" dst-address-list=NET-DMZ
add action=accept chain=forward-vpn comment="[FV-03] forward-vpn: Allow VPN to Internet" out-interface-list=WAN
add action=drop chain=forward-vpn comment="[FV-04] forward-vpn: Drop others"
add action=drop chain=forward-wan comment="[FWN-01] WAN->DMZ web: Drop HTTP from HTTP-ATTACKERS" dst-address=10.100.100.100 dst-port=80,443 protocol=tcp src-address-list=\
    HTTP-ATTACKERS
add action=add-src-to-address-list address-list=HTTP-ATTACKERS address-list-timeout=1h chain=forward-wan comment="[FWN-02] WAN->DMZ web: conn-limit exceeded -> ban 1h" \
    connection-limit=100,32 connection-state=new dst-address=10.100.100.100 dst-port=80,443 protocol=tcp
add action=drop chain=forward-wan comment="[FWN-03] WAN->DMZ web: drop if conn-limit exceeded (after ban)" connection-limit=100,32 connection-state=new dst-address=10.100.100.100 \
    dst-port=80,443 protocol=tcp
add action=accept chain=forward-wan comment="[FWN-04] WAN->DMZ web: allow NEW up to 10 conn/s per src-IP" connection-state=new dst-address=10.100.100.100 dst-limit=\
    10,10,src-address/32s dst-port=80,443 protocol=tcp
add action=add-src-to-address-list address-list=PORT-SCAN address-list-timeout=1d chain=forward-wan comment="[FWN-05] WAN->DMZ web: >10 conn/s per src-IP -> PORT-SCAN 24h" \
    connection-state=new dst-address=10.100.100.100 dst-port=80,443 protocol=tcp
add action=log chain=forward-wan comment="[FWN-06] forward-wan: Log unexpected WAN inbound (rate-limited)" limit=5/1m,10:packet log-prefix="[WAN-IN-DROP] "
add action=drop chain=forward-wan comment="[FWN-07] forward-wan: Drop all other WAN inbound"
add action=return chain=syn-flood comment="[SF-01] SYN-Flood: Return if within limit" in-interface-list=WAN limit=100,5:packet
add action=log chain=syn-flood comment="[SF-02a] SYN-Flood: Log (rate-limited)" in-interface-list=WAN limit=2/1m,5:packet log-prefix="[SYN-FLOOD] "
add action=drop chain=syn-flood comment="[SF-02] SYN-Flood: Drop excess"
/ip firewall mangle
add action=mark-connection chain=prerouting comment="[MNG-01] Mark new conns entering from ISP1" connection-state=new in-interface=ether1-WAN1 new-connection-mark=conn-from-isp1
add action=mark-connection chain=prerouting comment="[MNG-02] Mark new conns entering from ISP2" connection-state=new in-interface=ether2-WAN2 new-connection-mark=conn-from-isp2
add action=mark-routing chain=prerouting comment="[MNG-03] PBR: route traffic of ISP1-marked conns via to-isp1" connection-mark=conn-from-isp1 dst-address-type=!local \
    new-routing-mark=to-isp1 passthrough=no
add action=mark-routing chain=prerouting comment="[MNG-04] PBR: route traffic of ISP2-marked conns via to-isp2" connection-mark=conn-from-isp2 dst-address-type=!local \
    new-routing-mark=to-isp2 passthrough=no
add action=mark-routing chain=output comment="[MNG-05] Output PBR: ISP1-marked conns" connection-mark=conn-from-isp1 dst-address-type=!local new-routing-mark=to-isp1 passthrough=no
add action=mark-routing chain=output comment="[MNG-06] Output PBR: ISP2-marked conns" connection-mark=conn-from-isp2 dst-address-type=!local new-routing-mark=to-isp2 passthrough=no
/ip firewall nat
add action=accept chain=srcnat comment="[NAT-01] No NAT for VPN -> internal" dst-address-list=NET-INTERNAL src-address=10.200.200.0/24
add action=accept chain=srcnat comment="[NAT-02] No NAT for internal -> VPN" dst-address=10.200.200.0/24 src-address-list=NET-INTERNAL
add action=src-nat chain=srcnat comment="[NAT-03] SNAT to ISP1" out-interface=ether1-WAN1 src-address-list=RFC1918 to-addresses=203.0.113.11
add action=src-nat chain=srcnat comment="[NAT-04] SNAT to ISP2" out-interface=ether2-WAN2 src-address-list=RFC1918 to-addresses=198.51.100.12
add action=dst-nat chain=dstnat comment="[NAT-05] HTTP from ISP1 -> DMZ web" dst-address=203.0.113.11 dst-port=80 in-interface=ether1-WAN1 protocol=tcp to-addresses=10.100.100.100 \
    to-ports=80
add action=dst-nat chain=dstnat comment="[NAT-06] HTTPS from ISP1 -> DMZ web" dst-address=203.0.113.11 dst-port=443 in-interface=ether1-WAN1 protocol=tcp to-addresses=10.100.100.100 \
    to-ports=443
add action=dst-nat chain=dstnat comment="[NAT-07] HTTP from ISP2 -> DMZ web" dst-address=198.51.100.12 dst-port=80 in-interface=ether2-WAN2 protocol=tcp to-addresses=10.100.100.100 \
    to-ports=80
add action=dst-nat chain=dstnat comment="[NAT-08] HTTPS from ISP2 -> DMZ web" dst-address=198.51.100.12 dst-port=443 in-interface=ether2-WAN2 protocol=tcp to-addresses=10.100.100.100 \
    to-ports=443
add action=dst-nat chain=dstnat comment="[NAT-09] Hairpin dstnat to DMZ web" dst-address-list=WAN-IPS dst-port=80,443 protocol=tcp src-address-list=NET-INTERNAL to-addresses=\
    10.100.100.100
add action=src-nat chain=srcnat comment="[NAT-10] Hairpin srcnat (router as source)" dst-address=10.100.100.100 dst-port=80,443 out-interface=wlan2-DMZ protocol=tcp src-address-list=\
    NET-INTERNAL to-addresses=10.100.100.1
/ip firewall raw
add action=drop chain=prerouting comment="[RAW-00] Early drop: BLACKLIST (TZ)" in-interface-list=WAN src-address-list=BLACKLIST
add action=drop chain=prerouting comment="[RAW-01] Early drop: BAD-ACTORS" in-interface-list=WAN src-address-list=BAD-ACTORS
add action=drop chain=prerouting comment="[RAW-01a] Early drop: SCANNER (from input-wan detector)" in-interface-list=WAN src-address-list=SCANNER
add action=drop chain=prerouting comment="[RAW-02] Early drop: BOGONS from WAN" in-interface-list=WAN src-address-list=BOGONS
add action=drop chain=prerouting comment="[RAW-03] Early drop: RFC1918 spoofing" in-interface-list=WAN src-address-list=RFC1918
add action=drop chain=prerouting comment="[RAW-04] Early drop: PORT-SCAN to web" dst-address-list=WAN-IPS dst-port=80,443 in-interface-list=WAN protocol=tcp src-address-list=PORT-SCAN
add action=accept chain=prerouting comment="[RAW-05] SYN-flood: return if within limit" in-interface-list=WAN limit=500,100:packet protocol=tcp tcp-flags=syn
add action=drop chain=prerouting comment="[RAW-06] SYN-flood: drop excess" in-interface-list=WAN protocol=tcp tcp-flags=syn
/ip firewall service-port
set ftp disabled=yes
set tftp disabled=yes
set h323 disabled=yes
set pptp disabled=yes
/ip route
add comment="[RT-01] Check host ISP1 (interface-bound)" disabled=no distance=1 dst-address=87.240.132.72/32 gateway=203.0.113.1%ether1-WAN1 routing-table=main scope=10 \
    suppress-hw-offload=no target-scope=10
add comment="[RT-02] Check host ISP2 (interface-bound)" disabled=no distance=1 dst-address=95.143.182.1/32 gateway=198.51.100.1%ether2-WAN2 routing-table=main scope=10 \
    suppress-hw-offload=no target-scope=10
add check-gateway=ping comment="[RT-03] Default via ISP1 (primary)" disabled=no distance=1 dst-address=0.0.0.0/0 gateway=87.240.132.72 routing-table=main scope=30 suppress-hw-offload=\
    no target-scope=11
add check-gateway=ping comment="[RT-04] Default via ISP2 (failover)" disabled=no distance=2 dst-address=0.0.0.0/0 gateway=95.143.182.1 routing-table=main scope=30 suppress-hw-offload=\
    no target-scope=11
add check-gateway=ping comment="[RT-05] to-isp1: Primary ISP1" disabled=no distance=1 dst-address=0.0.0.0/0 gateway=87.240.132.72 routing-table=to-isp1 scope=30 suppress-hw-offload=no \
    target-scope=11
add check-gateway=ping comment="[RT-06] to-isp1: Failover ISP2" disabled=no distance=2 dst-address=0.0.0.0/0 gateway=95.143.182.1 routing-table=to-isp1 scope=30 suppress-hw-offload=no \
    target-scope=11
add check-gateway=ping comment="[RT-07] to-isp2: Primary ISP2" disabled=no distance=1 dst-address=0.0.0.0/0 gateway=95.143.182.1 routing-table=to-isp2 scope=30 suppress-hw-offload=no \
    target-scope=11
add check-gateway=ping comment="[RT-08] to-isp2: Failover ISP1" disabled=no distance=2 dst-address=0.0.0.0/0 gateway=87.240.132.72 routing-table=to-isp2 scope=30 suppress-hw-offload=\
    no target-scope=11
add blackhole comment="[RT-09] Blackhole for ISP1 check if unreachable" disabled=no distance=254 dst-address=87.240.132.72/32 gateway="" routing-table=main suppress-hw-offload=no
add blackhole comment="[RT-10] Blackhole for ISP2 check if unreachable" disabled=no distance=254 dst-address=95.143.182.1/32 gateway="" routing-table=main suppress-hw-offload=no
add comment="[RT-01a] Check host 2 ISP1 (OpenDNS)" dst-address=208.67.222.222/32 gateway=203.0.113.1%ether1-WAN1 scope=10 target-scope=10
add comment="[RT-02a] Check host 2 ISP2 (Quad9)" dst-address=9.9.9.9/32 gateway=198.51.100.1%ether2-WAN2 scope=10 target-scope=10
add blackhole comment="[RT-11] Blackhole for ISP1 check2" distance=254 dst-address=208.67.222.222/32
add blackhole comment="[RT-12] Blackhole for ISP2 check2" distance=254 dst-address=9.9.9.9/32
add check-gateway=ping comment="[RT-03a] Default via ISP1 check2" distance=1 dst-address=0.0.0.0/0 gateway=208.67.222.222 target-scope=11
add check-gateway=ping comment="[RT-04a] Default via ISP2 check2" distance=2 dst-address=0.0.0.0/0 gateway=9.9.9.9 target-scope=11
/ip service
set ftp disabled=yes
set ssh address=172.30.30.0/24,10.200.200.0/24
set telnet disabled=yes
set www disabled=yes
set www-ssl address=172.30.30.0/24,10.200.200.0/24 disabled=no
set winbox address=172.30.30.0/24,10.200.200.0/24
set api disabled=yes
set api-ssl address=172.30.30.0/24,10.200.200.0/24
/ip ssh
set host-key-type=ed25519 strong-crypto=yes
/routing rule
add action=lookup-only-in-table comment="[RR-01] Replies via ISP1 for marked connections" routing-mark=to-isp1 table=to-isp1
add action=lookup-only-in-table comment="[RR-02] Replies via ISP2 for marked connections" routing-mark=to-isp2 table=to-isp2
add action=lookup-only-in-table comment="[RR-03] LAN via ISP1 (failover ISP2)" src-address=172.30.30.0/24 table=to-isp1
add action=lookup-only-in-table comment="[RR-04] DMZ via ISP2 (failover ISP1)" src-address=10.100.100.0/24 table=to-isp2
add action=lookup-only-in-table comment="[RR-05] VPN via ISP1 (failover ISP2)" src-address=10.200.200.0/24 table=to-isp1
/system clock
set time-zone-name=Europe/Moscow
/system identity
set name=RB4011-GW00
/system leds
add interface=wlan1 leds=wlan1_signal1-led,wlan1_signal2-led,wlan1_signal3-led,wlan1_signal4-led,wlan1_signal5-led type=wireless-signal-strength
add interface=wlan1 leds=wlan1_tx-led type=interface-transmit
add interface=wlan1 leds=wlan1_rx-led type=interface-receive
/system logging
add topics=critical
add topics=firewall
add topics=dhcp
add topics=wireless
add action=disk topics=critical
add action=disk topics=firewall
/system ntp client
set enabled=yes
/system ntp client servers
add address=3.ru.pool.ntp.org
add address=ntp3.vniiftri.ru
add address=time.google.com
/system scheduler
add comment="Daily cleanup of expired dynamic address-list entries" interval=1d name=cleanup-address-lists on-event=\
    ":foreach i in=[/ip firewall address-list find where dynamic] do={:if ([/ip firewall address-list get \$i timeout] = \"00:00:00\") do={/ip firewall address-list remove \$i}}" \
    policy=read,write start-time=startup
add interval=10s name=sched-isp-health-monitor on-event="/system script run telegram-init; /system script run isp-health-monitor" policy=read,write,policy,test start-time=startup
add name=sched-notify-startup on-event="/system script run telegram-init; :delay 5s; /system script run notify-startup" policy=read,write,test start-time=startup
add interval=1d name=sched-daily-report on-event="/system script run telegram-init; /system script run daily-report" policy=read,write,test start-date=2026-01-07 start-time=09:00:00
add interval=1m name=sched-notify-resources on-event="/system script run telegram-init; /system script run notify-resources" policy=read,write,test start-time=startup
add interval=30s name=sched-notify-wireguard on-event="/system script run telegram-init; /system script run notify-wireguard" policy=read,write,test start-time=startup
add interval=30s name=sched-notify-interface on-event="/system script run telegram-init; /system script run notify-interface" policy=read,write,test start-time=startup
add interval=30s name=sched-notify-security-lists on-event="/system script run telegram-init; /system script run notify-security-lists" policy=read,write,test start-time=startup
add interval=5m name=sched-notify-dhcp-new on-event="/system script run telegram-init; /system script run notify-dhcp-new" policy=read,write,test start-time=startup
add interval=2m name=sched-notify-login on-event="/system script run telegram-init; /system script run notify-login" policy=read,write,test start-time=startup
add interval=1d name=sched-notify-firmware on-event="/system script run telegram-init; /system script run notify-firmware" policy=read,write,test start-date=2026-01-08 start-time=\
    10:00:00
/system script
add dont-require-permissions=no name=telegram-init owner=admin policy=read,write source="\
    \n    :global TelegramToken \"0000000000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\"\
    \n    :global TelegramChatID \"-0000000000\"\
    \n    :global TelegramEnabled true\
    \n    :global RouterName [/system identity get name]\
    \n"
add dont-require-permissions=no name=telegram-send owner=admin policy=read,write,test source="\
    \n    # Parameters: \$message - text to send, \$silent - true/false for silent notification\
    \n    :global TelegramToken\
    \n    :global TelegramChatID\
    \n    :global TelegramEnabled\
    \n    :global RouterName\
    \n    \
    \n    :local message\
    \n    :if ([:typeof \$0] = \"str\") do={\
    \n        :set message \$0\
    \n    } else={\
    \n        :set message \$1\
    \n    }\
    \n    \
    \n    :local silent false\
    \n    :if ([:typeof \$2] = \"bool\") do={\
    \n        :set silent \$2\
    \n    }\
    \n    \
    \n    :if (\$TelegramEnabled != true) do={\
    \n        :log warning \"[TELEGRAM] Notifications disabled\"\
    \n        :return false\
    \n    }\
    \n    \
    \n    :if ([:len \$TelegramToken] = 0 || [:len \$TelegramChatID] = 0) do={\
    \n        :log error \"[TELEGRAM] Token or ChatID not configured\"\
    \n        :return false\
    \n    }\
    \n    \
    \n    :local url \"https://api.telegram.org/bot\$TelegramToken/sendMessage\"\
    \n    :local fullMessage (\" *\$RouterName*\\n\\n\" . \$message)\
    \n    \
    \n    # URL encode special characters\
    \n    :local encoded \$fullMessage\
    \n    :set encoded [:pick \$encoded 0 [:len \$encoded]]\
    \n    \
    \n    :local silentParam \"\"\
    \n    :if (\$silent) do={\
    \n        :set silentParam \"&disable_notification=true\"\
    \n    }\
    \n    \
    \n    :do {\
    \n        /tool fetch url=\"\$url\" \\\
    \n            http-method=post \\\
    \n            http-data=\"chat_id=\$TelegramChatID&text=\$fullMessage&parse_mode=Markdown\$silentParam\" \\\
    \n            output=none\
    \n        :log info \"[TELEGRAM] Message sent successfully\"\
    \n        :return true\
    \n    } on-error={\
    \n        :log error \"[TELEGRAM] Failed to send message\"\
    \n        :return false\
    \n    }\
    \n"
add dont-require-permissions=no name=tg-send owner=admin policy=read,write,test source="\
    \n    :global TelegramToken\
    \n    :global TelegramChatID\
    \n    :local msg \$1\
    \n    :do {\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=\$msg\" output=none\
    \n        :log info \"[TELEGRAM] Message sent\"\
    \n    } on-error={\
    \n        :log error \"[TELEGRAM] Failed to send message\"\
    \n    }\
    \n"
add dont-require-permissions=no name=notify-startup owner=admin policy=read,write,test source="\
    \n    :delay 30s\
    \n    :global TelegramToken\
    \n    :global TelegramChatID\
    \n    :local uptime [/system resource get uptime]\
    \n    :local version [/system resource get version]\
    \n    :local cpu [/system resource get cpu-load]\
    \n    :do {\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%94%84%20SYSTEM%20REBOOT%0A%0ARouter%20has%20been%20restart\
    ed%0AUptime%3A%20\$uptime%0AVersion%3A%20\$version%0ACPU%3A%20\$cpu%25\" output=none\
    \n    } on-error={\
    \n        :log error \"[TELEGRAM] Failed to send startup notification\"\
    \n    }\
    \n"
add dont-require-permissions=no name=daily-report owner=admin policy=read,write,test source="\
    \n    :global TelegramToken\
    \n    :global TelegramChatID\
    \n    :global ISPMON1STATE\
    \n    :global ISPMON2STATE\
    \n    :local uptime [/system resource get uptime]\
    \n    :local cpu [/system resource get cpu-load]\
    \n    :local mem [/system resource get free-memory]\
    \n    :local totmem [/system resource get total-memory]\
    \n    :local memPct (100 - (\$mem * 100 / \$totmem))\
    \n    :local connCount [/ip firewall connection print count-only]\
    \n    :local dhcpLeases [:len [/ip dhcp-server lease find where status=bound]]\
    \n    :local scanners [:len [/ip firewall address-list find where list=\"SCANNER\"]]\
    \n    :local badactors [:len [/ip firewall address-list find where list=\"BAD-ACTORS\"]]\
    \n    :local blocked (\$scanners + \$badactors)\
    \n    :local isp1 \"UP\"\
    \n    :local isp2 \"UP\"\
    \n    :if (\$ISPMON1STATE = \"DOWN\") do={:set isp1 \"DOWN\"}\
    \n    :if (\$ISPMON2STATE = \"DOWN\") do={:set isp2 \"DOWN\"}\
    \n    :do {\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%93%8A%20DAILY%20REPORT%0A%0AISP1%3A%20\$isp1%0AISP2%3A%20\
    \$isp2%0AUptime%3A%20\$uptime%0ACPU%3A%20\$cpu%25%0ARAM%3A%20\$memPct%25%0AConnections%3A%20\$connCount%0ADHCP%3A%20\$dhcpLeases%0ABlocked%20IPs%3A%20\$blocked\" output=none\
    \n    } on-error={\
    \n        :log error \"[TELEGRAM] Failed to send daily report\"\
    \n    }\
    \n"
add dont-require-permissions=no name=notify-resources owner=admin policy=read,write,test source="\
    \n    :global TelegramToken\
    \n    :global TelegramChatID\
    \n    :global LastResourceAlert\
    \n    :local now [/system clock get time]\
    \n    :if ([:typeof \$LastResourceAlert] != \"nothing\") do={\
    \n        :local diff (\$now - \$LastResourceAlert)\
    \n        :if (\$diff < 00:10:00 && \$diff > 00:00:00) do={:return}\
    \n    }\
    \n    :local cpu [/system resource get cpu-load]\
    \n    :local mem [/system resource get free-memory]\
    \n    :local totmem [/system resource get total-memory]\
    \n    :local memPct (100 - (\$mem * 100 / \$totmem))\
    \n    :if (\$cpu > 80 || \$memPct > 80) do={\
    \n        :set LastResourceAlert \$now\
    \n        :do {\
    \n            /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%E2%9A%A0%EF%B8%8F%20RESOURCE%20ALERT%0A%0ACPU%3A%20\$cpu%25%\
    0ARAM%3A%20\$memPct%25%0AHigh%20resource%20usage%20detected\" output=none\
    \n        } on-error={}\
    \n    }\
    \n"
add dont-require-permissions=no name=notify-wireguard owner=admin policy=read,write,test source="\
    \n    :global TelegramToken\
    \n    :global TelegramChatID\
    \n    :global WGPeerConnected\
    \n    :if ([:typeof \$WGPeerConnected] = \"nothing\") do={:set WGPeerConnected false}\
    \n    :local connected false\
    \n    :foreach peer in=[/interface wireguard peers find] do={\
    \n        :local lastHs [/interface wireguard peers get \$peer last-handshake]\
    \n        :if (\$lastHs < 00:03:00 && \$lastHs > 00:00:00) do={\
    \n            :set connected true\
    \n        }\
    \n    }\
    \n    :if (\$connected != \$WGPeerConnected) do={\
    \n        :set WGPeerConnected \$connected\
    \n        :local tme [/system clock get time]\
    \n        :if (\$connected) do={\
    \n            :do {\
    \n                /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%94%90%20VPN%20CONNECTED%0A%0AWireGuard%20peer%20co\
    nnected%0ATime%3A%20\$tme\" output=none\
    \n            } on-error={}\
    \n        } else={\
    \n            :do {\
    \n                /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%94%93%20VPN%20DISCONNECTED%0A%0AWireGuard%20peer%2\
    0disconnected%0ATime%3A%20\$tme\" output=none\
    \n            } on-error={}\
    \n        }\
    \n    }\
    \n"
add dont-require-permissions=no name=isp-health-monitor owner=admin policy=read,write,test source="\
    \n    :global ISPMON1STATE\
    \n    :global ISPMON2STATE\
    \n    :global ISPMON1FAIL\
    \n    :global ISPMON2FAIL\
    \n    :global ISPMON1OK\
    \n    :global ISPMON2OK\
    \n    :global TelegramToken\
    \n    :global TelegramChatID\
    \n    :global BothDownAlerted\
    \n    :global BothDownTime\
    \n    :global PendingBothDownAlert\
    \n    :if ([:typeof \$ISPMON1STATE] = \"nothing\") do={\
    \n        :set ISPMON1STATE \"UP\"\
    \n        :set ISPMON1FAIL 0\
    \n        :set ISPMON1OK 0\
    \n    }\
    \n    :if ([:typeof \$ISPMON2STATE] = \"nothing\") do={\
    \n        :set ISPMON2STATE \"UP\"\
    \n        :set ISPMON2FAIL 0\
    \n        :set ISPMON2OK 0\
    \n    }\
    \n    :local hyst 2\
    \n    :local p1 0\
    \n    :local p2 0\
    \n    :local p3 0\
    \n    :local p4 0\
    \n    :do {:set p1 [/ping 87.240.132.72 count=2 interface=ether1-WAN1]} on-error={}\
    \n    :do {:set p2 [/ping 208.67.222.222 count=2 interface=ether1-WAN1]} on-error={}\
    \n    :do {:set p3 [/ping 95.143.182.1 count=2 interface=ether2-WAN2]} on-error={}\
    \n    :do {:set p4 [/ping 9.9.9.9 count=2 interface=ether2-WAN2]} on-error={}\
    \n    :if (\$p1 > 0 || \$p2 > 0) do={\
    \n        :set ISPMON1FAIL 0\
    \n        :set ISPMON1OK (\$ISPMON1OK + 1)\
    \n        :if (\$ISPMON1STATE = \"DOWN\" && \$ISPMON1OK >= \$hyst) do={\
    \n            :set ISPMON1STATE \"UP\"\
    \n            :set ISPMON1OK 0\
    \n            :log warning \"[FAILBACK] ISP1 restored\"\
    \n            :local tme [/system clock get time]\
    \n            :if (\$PendingBothDownAlert = true) do={\
    \n                :set PendingBothDownAlert false\
    \n                :do {\
    \n                    /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%9A%A8%20CRITICAL%20EVENT%20%28past%29%0A%0AALL\
    %20ISP%20WERE%20DOWN%0AStarted%3A%20\$BothDownTime%0ARecovered%3A%20\$tme%0ABoth%20links%20were%20unavailable\" output=none\
    \n                } on-error={}\
    \n            }\
    \n            :do {\
    \n                /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%9F%A2%20ISP1%20RESTORED%0A%0AStatus%3A%20UP%0APrim\
    ary%20link%20restored%0ALAN%2FVPN%20returning%20to%20ISP1%0ATime%3A%20\$tme\" output=none\
    \n            } on-error={}\
    \n            :delay 2s\
    \n            :do {/ip firewall connection remove [find src-address~\"172.30.30.\"]} on-error={}\
    \n            :do {/ip firewall connection remove [find src-address~\"10.200.200.\"]} on-error={}\
    \n            :do {/ip arp remove [find interface=ether1-WAN1 dynamic=yes]} on-error={}\
    \n            :log info \"[FAILBACK] ISP1 cleanup complete\"\
    \n        }\
    \n    } else={\
    \n        :set ISPMON1OK 0\
    \n        :set ISPMON1FAIL (\$ISPMON1FAIL + 1)\
    \n        :if (\$ISPMON1STATE = \"UP\" && \$ISPMON1FAIL >= \$hyst) do={\
    \n            :set ISPMON1STATE \"DOWN\"\
    \n            :set ISPMON1FAIL 0\
    \n            :log warning \"[FAILOVER] ISP1 DOWN\"\
    \n            :local tme [/system clock get time]\
    \n            :do {\
    \n                /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%94%B4%20ISP1%20DOWN%0A%0AStatus%3A%20DOWN%0APrimar\
    y%20link%20failure%0ALAN%2FVPN%20switched%20to%20ISP2%0ATime%3A%20\$tme\" output=none\
    \n            } on-error={}\
    \n            :do {/ip firewall connection remove [find src-address~\"172.30.30.\"]} on-error={}\
    \n            :do {/ip firewall connection remove [find src-address~\"10.200.200.\"]} on-error={}\
    \n            :do {/ip arp remove [find interface=ether1-WAN1 dynamic=yes]} on-error={}\
    \n            :log info \"[FAILOVER] ISP1 failover complete\"\
    \n        }\
    \n        :if (\$ISPMON1STATE = \"UP\" && \$ISPMON1FAIL < \$hyst) do={\
    \n            :log warning \"[ISP-MONITOR] ISP1 failing (\$ISPMON1FAIL/\$hyst)\"\
    \n        }\
    \n    }\
    \n    :if (\$p3 > 0 || \$p4 > 0) do={\
    \n        :set ISPMON2FAIL 0\
    \n        :set ISPMON2OK (\$ISPMON2OK + 1)\
    \n        :if (\$ISPMON2STATE = \"DOWN\" && \$ISPMON2OK >= \$hyst) do={\
    \n            :set ISPMON2STATE \"UP\"\
    \n            :set ISPMON2OK 0\
    \n            :log warning \"[FAILBACK] ISP2 restored\"\
    \n            :local tme [/system clock get time]\
    \n            :if (\$PendingBothDownAlert = true) do={\
    \n                :set PendingBothDownAlert false\
    \n                :do {\
    \n                    /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%9A%A8%20CRITICAL%20EVENT%20%28past%29%0A%0AALL\
    %20ISP%20WERE%20DOWN%0AStarted%3A%20\$BothDownTime%0ARecovered%3A%20\$tme%0ABoth%20links%20were%20unavailable\" output=none\
    \n                } on-error={}\
    \n            }\
    \n            :do {\
    \n                /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%9F%A2%20ISP2%20RESTORED%0A%0AStatus%3A%20UP%0ASeco\
    ndary%20link%20restored%0ADMZ%20returning%20to%20ISP2%0ATime%3A%20\$tme\" output=none\
    \n            } on-error={}\
    \n            :delay 2s\
    \n            :do {/ip firewall connection remove [find src-address~\"10.100.100.\"]} on-error={}\
    \n            :do {/ip arp remove [find interface=ether2-WAN2 dynamic=yes]} on-error={}\
    \n            :log info \"[FAILBACK] ISP2 cleanup complete\"\
    \n        }\
    \n    } else={\
    \n        :set ISPMON2OK 0\
    \n        :set ISPMON2FAIL (\$ISPMON2FAIL + 1)\
    \n        :if (\$ISPMON2STATE = \"UP\" && \$ISPMON2FAIL >= \$hyst) do={\
    \n            :set ISPMON2STATE \"DOWN\"\
    \n            :set ISPMON2FAIL 0\
    \n            :log warning \"[FAILOVER] ISP2 DOWN\"\
    \n            :local tme [/system clock get time]\
    \n            :do {\
    \n                /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\?chat_id=\$TelegramChatID&text=%F0%9F%94%B4%20ISP2%20DOWN%0A%0AStatus%3A%20DOWN%0ASecond\
    ary%20link%20failure%0ADMZ%20switched%20to%20ISP1%0ATime%3A%20\$tme\" output=none\
    \n            } on-error={}\
    \n            :do {/ip firewall connection remove [find src-address~\"10.100.100.\"]} on-error={}\
    \n            :do {/ip arp remove [find interface=ether2-WAN2 dynamic=yes]} on-error={}\
    \n            :log info \"[FAILOVER] ISP2 failover complete\"\
    \n        }\
    \n        :if (\$ISPMON2STATE = \"UP\" && \$ISPMON2FAIL < \$hyst) do={\
    \n            :log warning \"[ISP-MONITOR] ISP2 failing (\$ISPMON2FAIL/\$hyst)\"\
    \n        }\
    \n    }\
    \n    :if (\$ISPMON1STATE = \"DOWN\" && \$ISPMON2STATE = \"DOWN\") do={\
    \n        :if (\$BothDownAlerted != true) do={\
    \n            :set BothDownAlerted true\
    \n            :set BothDownTime [/system clock get time]\
    \n            :set PendingBothDownAlert true\
    \n            :log error \"[CRITICAL] ALL ISP DOWN - No internet connectivity\"\
    \n        }\
    \n    } else={\
    \n        :set BothDownAlerted false\
    \n    }\
    \n"
add dont-require-permissions=no name=notify-interface owner=admin policy=read,write,test source=":global TelegramToken\
    \n:global TelegramChatID\
    \n:local rn [/system identity get name]\
    \n:local tm [/system clock get time]\
    \n:local n1 0\
    \n:local n2 0\
    \n:local nb 0\
    \n:local nw 0\
    \n:do {:if ([/interface get [find name=\"ether1-WAN1\"] running]) do={:set n1 1}} on-error={}\
    \n:do {:if ([/interface get [find name=\"ether2-WAN2\"] running]) do={:set n2 1}} on-error={}\
    \n:do {:if ([/interface get [find name=\"br-lan\"] running]) do={:set nb 1}} on-error={}\
    \n:do {:if ([/interface get [find name=\"wg-vpn\"] running]) do={:set nw 1}} on-error={}\
    \n:local cur \"\$n1\$n2\$nb\$nw\"\
    \n:local prev \"\"\
    \n:do {:set prev [/file get [find name=\"if-state.txt\"] contents]} on-error={:set prev \"\"}\
    \n:if ([:len \$prev] = 0) do={\
    \n    /file print file=if-state\
    \n    :delay 1s\
    \n    /file set [find name=\"if-state.txt\"] contents=\$cur\
    \n    :log info \"[IF] Init: \$cur\"\
    \n} else={\
    \n    :if (\$cur != \$prev) do={\
    \n        :local o1 [:pick \$prev 0 1]\
    \n        :local o2 [:pick \$prev 1 2]\
    \n        :local ob [:pick \$prev 2 3]\
    \n        :local ow [:pick \$prev 3 4]\
    \n        :if ([:tostr \$n1] != \$o1) do={\
    \n            :local s \"DOWN\"\
    \n            :if (\$n1 = 1) do={:set s \"UP\"}\
    \n            :log warning \"[IF] WAN1 \$s\"\
    \n            :do {/tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%94%B4%20INTERFACE%0A%0AWAN1%20\$s%0ARouter%3A%2\
    0\$rn%0ATime%3A%20\$tm\" output=none} on-error={}\
    \n        }\
    \n        :if ([:tostr \$n2] != \$o2) do={\
    \n            :local s \"DOWN\"\
    \n            :if (\$n2 = 1) do={:set s \"UP\"}\
    \n            :log warning \"[IF] WAN2 \$s\"\
    \n            :do {/tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%94%B4%20INTERFACE%0A%0AWAN2%20\$s%0ARouter%3A%2\
    0\$rn%0ATime%3A%20\$tm\" output=none} on-error={}\
    \n        }\
    \n        :if ([:tostr \$nb] != \$ob) do={\
    \n            :local s \"DOWN\"\
    \n            :if (\$nb = 1) do={:set s \"UP\"}\
    \n            :log warning \"[IF] br-lan \$s\"\
    \n            :do {/tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%94%B4%20INTERFACE%0A%0Abr-lan%20\$s%0ARouter%3A\
    %20\$rn%0ATime%3A%20\$tm\" output=none} on-error={}\
    \n        }\
    \n        :if ([:tostr \$nw] != \$ow) do={\
    \n            :local s \"DOWN\"\
    \n            :if (\$nw = 1) do={:set s \"UP\"}\
    \n            :log warning \"[IF] wg-vpn \$s\"\
    \n            :do {/tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%94%B4%20INTERFACE%0A%0Awg-vpn%20\$s%0ARouter%3A\
    %20\$rn%0ATime%3A%20\$tm\" output=none} on-error={}\
    \n        }\
    \n        /file set [find name=\"if-state.txt\"] contents=\$cur\
    \n    }\
    \n}"
add dont-require-permissions=no name=notify-security-lists owner=admin policy=read,write,test source=":global TelegramToken\
    \n:global TelegramChatID\
    \n:local rn [/system identity get name]\
    \n:local tme [/system clock get time]\
    \n:local scanners [:len [/ip firewall address-list find where list=\"SCANNER\" dynamic=yes]]\
    \n:local badactors [:len [/ip firewall address-list find where list=\"BAD-ACTORS\" dynamic=yes]]\
    \n:local httpatt [:len [/ip firewall address-list find where list=\"HTTP-ATTACKERS\" dynamic=yes]]\
    \n:local wgflood [:len [/ip firewall address-list find where list=\"WG-FLOOD\" dynamic=yes]]\
    \n:local portscan [:len [/ip firewall address-list find where list=\"PORT-SCAN\" dynamic=yes]]\
    \n:local total (\$scanners + \$badactors + \$httpatt + \$wgflood + \$portscan)\
    \n:local prevTotal 0\
    \n:do {:set prevTotal [:tonum [/file get [find name=\"sec-count.txt\"] contents]]} on-error={:set prevTotal 0}\
    \n:if ([:len [/file find name=\"sec-count.txt\"]] = 0) do={\
    \n    /file print file=sec-count\
    \n    :delay 1s\
    \n    /file set [find name=\"sec-count.txt\"] contents=\"\$total\"\
    \n    :log info \"[SECURITY] Init: \$total\"\
    \n} else={\
    \n    :if (\$total > \$prevTotal) do={\
    \n        :local diff (\$total - \$prevTotal)\
    \n        :log warning \"[SECURITY] New threats: +\$diff (total: \$total)\"\
    \n        :do {\
    \n            /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%9A%A8%20SECURITY%20ALERT%0A%0ANew%20blocked%3A%20%2B\
    \$diff%0ASCANNER%3A%20\$scanners%0ABAD-ACTORS%3A%20\$badactors%0AHTTP-ATT%3A%20\$httpatt%0AWG-FLOOD%3A%20\$wgflood%0APORT-SCAN%3A%20\$portscan%0ATotal%3A%20\$total%0ARouter%3A%20\$\
    rn%0ATime%3A%20\$tme\" output=none\
    \n        } on-error={}\
    \n    }\
    \n    /file set [find name=\"sec-count.txt\"] contents=\"\$total\"\
    \n}"
add dont-require-permissions=no name=notify-dhcp-new owner=admin policy=read,write,test source=":global TelegramToken\
    \n:global TelegramChatID\
    \n:global DHCPCount\
    \n:global DHCPInit\
    \n:local current [:len [/ip dhcp-server lease find where status=bound]]\
    \n:if ([:typeof \$DHCPInit] != \"bool\") do={\
    \n    :set DHCPInit true\
    \n    :set DHCPCount \$current\
    \n    :log info \"[DHCP] Init: \$current leases\"\
    \n} else={\
    \n    :if (\$current > \$DHCPCount) do={\
    \n        :local rn [/system identity get name]\
    \n        :local tme [/system clock get time]\
    \n        :local lastMAC \"\"\
    \n        :local lastIP \"\"\
    \n        :local lastHost \"unknown\"\
    \n        :foreach lease in=[/ip dhcp-server lease find where status=bound] do={\
    \n            :set lastMAC [/ip dhcp-server lease get \$lease mac-address]\
    \n            :set lastIP [/ip dhcp-server lease get \$lease address]\
    \n            :do {:set lastHost [/ip dhcp-server lease get \$lease host-name]} on-error={}\
    \n        }\
    \n        :if ([:len \$lastHost] = 0) do={:set lastHost \"unknown\"}\
    \n        :log warning \"[DHCP] New: \$lastMAC (\$lastIP)\"\
    \n        :do {\
    \n            /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%86%95%20NEW%20DHCP%20DEVICE%0A%0AIP%3A%20\$lastIP%0A\
    MAC%3A%20\$lastMAC%0AHost%3A%20\$lastHost%0ARouter%3A%20\$rn%0ATime%3A%20\$tme\" output=none\
    \n        } on-error={}\
    \n    }\
    \n    :set DHCPCount \$current\
    \n}"
add dont-require-permissions=no name=notify-login owner=admin policy=read,write,test source=":global TelegramToken\
    \n:global TelegramChatID\
    \n:local rn [/system identity get name]\
    \n:local tme [/system clock get time]\
    \n:local failCount 0\
    \n:local lastSuccess \"\"\
    \n:local lastSuccessTime \"\"\
    \n:foreach i in=[/log find where message~\"login failure\" topics~\"system\"] do={\
    \n    :set failCount (\$failCount + 1)\
    \n}\
    \n:foreach i in=[/log find where message~\"logged in\" topics~\"system\"] do={\
    \n    :local msg [/log get \$i message]\
    \n    :local logTime [/log get \$i time]\
    \n    :if ([:find \$msg \"logged in\"] > 0) do={\
    \n        :set lastSuccess \$msg\
    \n        :set lastSuccessTime \$logTime\
    \n    }\
    \n}\
    \n:local prevFail 0\
    \n:local prevSuccessTime \"\"\
    \n:do {:set prevFail [:tonum [/file get [find name=\"login-fail.txt\"] contents]]} on-error={:set prevFail 0}\
    \n:do {:set prevSuccessTime [/file get [find name=\"login-success.txt\"] contents]} on-error={:set prevSuccessTime \"\"}\
    \n:if ([:len [/file find name=\"login-fail.txt\"]] = 0) do={\
    \n    /file print file=login-fail\
    \n    :delay 1s\
    \n}\
    \n:if ([:len [/file find name=\"login-success.txt\"]] = 0) do={\
    \n    /file print file=login-success\
    \n    :delay 1s\
    \n}\
    \n:if (\$failCount > \$prevFail && \$failCount >= 3) do={\
    \n    :local diff (\$failCount - \$prevFail)\
    \n    :log warning \"[LOGIN] Brute-force: +\$diff (total: \$failCount)\"\
    \n    :do {\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%9A%A8%20BRUTE-FORCE%20ALERT%0A%0ANew%20failed%3A%20%2B\$\
    diff%0ATotal%20failed%3A%20\$failCount%0ARouter%3A%20\$rn%0ATime%3A%20\$tme\" output=none\
    \n    } on-error={}\
    \n}\
    \n/file set [find name=\"login-fail.txt\"] contents=\"\$failCount\"\
    \n:if ([:len \$lastSuccessTime] > 0 && \$lastSuccessTime != \$prevSuccessTime) do={\
    \n    :local user \"unknown\"\
    \n    :local via \"unknown\"\
    \n    :local fromIP \"\"\
    \n    :if ([:find \$lastSuccess \"user \"] >= 0) do={\
    \n        :local start ([:find \$lastSuccess \"user \"] + 5)\
    \n        :local end [:find \$lastSuccess \" logged\"]\
    \n        :if (\$end > \$start) do={:set user [:pick \$lastSuccess \$start \$end]}\
    \n    }\
    \n    :if ([:find \$lastSuccess \"via \"] >= 0) do={\
    \n        :local start ([:find \$lastSuccess \"via \"] + 4)\
    \n        :set via [:pick \$lastSuccess \$start [:len \$lastSuccess]]\
    \n    }\
    \n    :log info \"[LOGIN] Success: \$user via \$via\"\
    \n    :do {\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%E2%9C%85%20LOGIN%20SUCCESS%0A%0AUser%3A%20\$user%0AVia%3A%20\$\
    via%0ARouter%3A%20\$rn%0ATime%3A%20\$lastSuccessTime\" output=none\
    \n    } on-error={}\
    \n    /file set [find name=\"login-success.txt\"] contents=\"\$lastSuccessTime\"\
    \n}"
add dont-require-permissions=no name=notify-firmware owner=admin policy=read,write,test source=":global TelegramToken\
    \n:global TelegramChatID\
    \n:global FWVersion\
    \n:local current [/system resource get version]\
    \n:if ([:typeof \$FWVersion] = \"nothing\") do={\
    \n    :set FWVersion \$current\
    \n    :log info \"[FIRMWARE] Init: \$current\"\
    \n} else={\
    \n    :if (\$FWVersion != \$current) do={\
    \n        :local rn [/system identity get name]\
    \n        :local tme [/system clock get time]\
    \n        :log warning \"[FIRMWARE] Updated: \$FWVersion -> \$current\"\
    \n        :do {\
    \n            /tool fetch url=\"https://api.telegram.org/bot\$TelegramToken/sendMessage\\\?chat_id=\$TelegramChatID&text=%F0%9F%94%84%20FIRMWARE%20UPDATED%0A%0APrevious%3A%20\$FWVe\
    rsion%0ACurrent%3A%20\$current%0ARouter%3A%20\$rn%0ATime%3A%20\$tme\" output=none\
    \n        } on-error={}\
    \n        :set FWVersion \$current\
    \n    }\
    \n}"
/tool bandwidth-server
set enabled=no
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
/tool mac-server ping
set enabled=no
/user settings
set minimum-password-length=12
[admin@RB4011-GW00] > 
