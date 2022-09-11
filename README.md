</p>

<table align="right">
 <tr><td><a href="https://github.com/ciro-mota/padavan-collection/blob/main/README.md">:us: English</a></td></tr>
 <tr><td><a href="https://github.com/ciro-mota/padavan-collection/blob/main/README.pt-br.md">:brazil: Português</a></td></tr>
</table>

<h2>Procedures and otimizations to Padavan Firmware Router</h2>

<p align="center">
<img width="300" height="150" src="https://imgur.com/X2MlXSz.png">
</p>

![License](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge) 
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)
![GitHub last commit](https://img.shields.io/github/last-commit/ciro-mota/padavan-collection?style=for-the-badge)

## Purpose

This Git brings together some procedures that can be used to get the best out of Padavan Firmware. These are procedures publicly disclosed in the [4pda community](https://4pda.to/forum/index.php?showtopic=837667), [Wiki](https://bitbucket.org/padavan/rt-n56u/wiki/browse/RU) and adapted for use. For the procedures below to work optimally, the firmware must be compiled on Prometheus with the following options enabled:

```
CONFIG_FIRMWARE_INCLUDE_OPENSSL_EXE=y
CONFIG_FIRMWARE_INCLUDE_OPENSSL_EC=y
```

All these procedures have been tested and used in a **Xiaomi Mi Router 3G**, being compatible with the Xiaomi Mi Router 3. However, it is possible that they can be applied in other models supported by this firmware.

## Updates

Upstream with latest updates. [![GitLab stars](https://img.shields.io/gitlab/stars/mahtabctg/padavan-ng?style=social)](https://gitlab.com/mahtabctg/padavan-ng)

## Table of Contents
1. [Enable internal Entware](#Enable-Internal-Entware)
2. [Integrated AdBlock](#Integrated-AdBlock)
3. [DNS Over HTTPS](#DNS-Over-HTTPS)
4. [HTTPS local domain](#HTTPS-local-domain)
5. [LEDs Control](#LEDs)
6. [Telegram Alerts](#Telegram-Alerts)
7. [ZeroTier](#ZeroTier)
8. [Padarouter](#Padarouter)

<a name="readme-top"></a>

## Enable Internal Entware

Internal Entware makes use of a small space in the router's internal memory where programs can be installed and some files saved, without the need for an external USB drive. Very useful for installing applications not included in the standard firmware build.

For the procedure, it is necessary to determine the number of the "RWFS" partition that has the free space. 

1. To do this, in an SSH session on the terminal, type the command `cat /proc/mtd` and look at the list of partitions. You will see something like: `mtd11: 06080000 00020000 "RWFS"`

![](/assets/mtd.png)

2. Format this RWFS partition with UBIFS, type the command to that: `ubiformat /dev/mtd11`

3. Then we add the set of command lines below for your activation on the firmware interface, on **Advanced Settings** » **Customization** » **Scripts** » **Run After Router Started:**:

```
## Enable Internal Entware
ubiattach -p /dev/mtd11
ubimkvol /dev/ubi0 -m -N user
mkdir /mnt/opt
mount -t ubifs ubi0 /mnt/opt
opt-mount.sh /dev/ubi0 /mnt
opkg.sh
```
Apply and restart the router after that.

4 - We were able to verify that everything worked out by running the command: `opkg update`

![](/assets/opkg.png)

This is the list of [packages available](https://bin.entware.net/armv7sf-k3.2/Packages.html) for installation, due to the small size use it with caution.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Integrated AdBlock

Through Internal Entware or through Entware enabled for an external USB drive, we were able to generate a host file containing address block lists, useful for parental control and/or for an internal AdBlock and thus bringing greater security to the local network.

This procedure is not 100% effective and it may still be necessary to use blockers in browsers.

If after your installation some site does not work correctly, add your domain name in the `adblock_allow.list` file, just the domain name, example: `github.com`

Other sites that need to be blocked can be added in the `adblock_deny.list` file, also just the domain name.

In my case, I chose to use the set of lists from the [Energized](https://energized.pro/) group, which are constantly updated and have many downloadable list options.

1. Download the contents of the `codes/adblock` folder from this repository and add it to the router in the `/etc/storage` folder.

2. Activate redirection to the new hosts file in: **LAN** » **DHCP Server** » **Custom Configuration File "dnsmasq.conf"**. And add these lines below:

```
### Internal AdBlock
addn-hosts=/tmp/hosts
```

If necessary, apply execute permissions to the script with `chmod u+x adblock_update.sh`.

3. Execute `mtd_storage.sh save` to save modifications.

4. You can force the script to run at any time using the command: `/etc/storage/adblock_update.sh` or `./adblock_update.sh` if it is in the same directory as the file.

5. You may want to create a schedule for automatic update of the lists, for that add the line below with the desired period in **Administration** » **Services** » **Cron Daemon (Scheduler)?** » **Scheduler tasks (Crontab)**:

```
### Update AdBlock
00 8 * * 6 /etc/storage/adblock_update.sh >/dev/null 2>&1
```
The update will take place every Sunday at 8:00 am.   
You may need to regularly edit the script's user agent (-U parameter in wget line) to a newer version.

![](/assets/energized.png)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## DNS Over HTTPS

DNS traffic is usually vulnerable to attackers because there is the possibility of "hearing" your communication and intercepting unprotected personal data. With this Internet service providers can also monitor your traffic and possibly collect everything about the websites you visit.

DoH and DoT are secure DNS protocols that can change this behavior through an encrypted channel. DNS over TLS [RFC7858](https://tools.ietf.org/html/rfc7858) and DNS over HTTPS [RFC8484](https://tools.ietf.org/html/rfc8484) are designed to secure DNS traffic. You may want to dig deeper into the subject by reading the RFC's listed here.

Through DNSCrypt proxy it is possible to enable DoT and/or DoH support in this firmware, with more customizable options than the one present in the standard build of the firmware.

1. Whether on Internal Entware or USB, install the package `dnscrypt-proxy2`:
```
opkg update
opkg install dnscrypt-proxy2
```
2. In WAN » **WAN DNS Settings** » **Get the DNS Server Address Automatically?** set to **Disable**. In **DNS Server 1**: put `127.0.0.1`. **WAN** » **WAN DNSv6 Settings** » **Get DNSv6 Servers Automatically?** set to **Disable** too.

3. The package will then insert the `dnscrypt-proxy.toml` file into the `/opt/etc` directory where some edits are needed.  

    3.1. In `server_names`, edit with the DNS servers you want to use. A list of available ones can be found at [this link](https://dnscrypt.info/public-servers/). Example:

    ```
    server_names = ['cloudflare', 'cloudflare-ipv6', 'nextdns', 'nextdns-ipv6']
    ```
    3.2. In `listen_addresses` change the port to a high port for example. This procedure is optional.

    ```
    listen_addresses = ['127.0.0.1:65053']
    ```

    3.3. Change `ipv6_servers` to True only if you have active IPv6 connections.

    3.4. Uncomment the line `tls_cipher_suite = [52392, 49199]`, this will cause a low use of resources when using DNSCrypt.

    3.5. `fallback_resolver` and `netprobe_address` can be edited to a DNS server of your choice but different from those used in the default configuration (item 3.1).

4. From an SSH session, run the command `/opt/etc/init.d/S09dnscrypt-proxy2 start` to enable DNSCrypt. 

![](/assets/doh-ensi.png)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## HTTPS local domain

HTTPs is now the standard for web addresses and Padavan supports this feature, but with a self-signed certificate that is not natively recognized by browsers. To get around this it is possible with the help of Let's Encrypt and a valid DDNS to have its own access address to the router.

There are many DDNS services, free and paid. Specifically in our case it is recommended to use [DuckDNS](https://www.duckdns.org/), which allows the creation of a free and accessible DDNS for use with Let's Encrypt.

1. Enable HTTPs support in **Administration** » **Services** » **Web Server Protocol.**

2. Change `List of Allowed SSL Ciphers for HTTPS:` to:
```
TLS_CHACHA20_POLY1305_SHA256:DH+AESGCM:DH+AES256:DH+AES:DH+3DES:RSA+AES:RSA+3DES:!ADH:!MD5:!DSS`
```
3. Download the contents of the `codes/ca-cert` folder from this repository and add it to the router in the `/etc/storage` folder.

If necessary, apply execute permissions to the script with `chmod u+x update-cert.sh`.

4. You need to edit some fields in `Variables` field, such as your **DDNS domain** and the **token** key generated in DuckDNS. The script will need to be modified if another service is used.

You will also need to edit line 12 of the script to point to your WAN interface, in my case I use the PPP protocol and this is referred to as `ppp0` in the script. Run `ip a s` on SSH Terminal to check which interface receives a public IP address.

5. Execute `mtd_storage.sh save` to save modifications.

6. You can force the script to run at any time using the command: `/etc/storage/update-cert.sh` or `./update-cert.sh` if it is in the same directory as the file.

7. Certificates are valid for 90 days. You may want to create a schedule for automatic update, for that add the line below with the desired period in **Administration** » **Services** » **Cron Daemon (Scheduler)?** » **Scheduler tasks (Crontab)**:

```
### Update Cert
0 9 */90 * * /etc/storage/update-cert.sh >/dev/null 2>&1
```
The update will take place every 90 days at 9 am.  

8. Activate the redirect to the address at **LAN** » **DHCP Server** » **Custom Configuration File "dnsmasq.conf"** with the line below:

```
### Internal Cert
address=/your-domain.duckdns.org/192.168.0.1
```
Change to your domain name and router IP address.

![](/assets/encrypt.png)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
## LEDs

You may want to control when the router's LEDs can be lit or not. To do this, add a Crontab (**Administration** » **Services** » **Cron Daemon (Scheduler)?** » **Scheduler tasks (Crontab)**) rule for shutdown:
```
00 17 * * * leds_front 0
00 17 * * * leds_ether 0  
10 17 * * * leds_front 1
10 17 * * * leds_ether 1
```
0 will represent off and 1 on.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Telegram Alerts

It is possible to configure custom alerts to be sent to a particular bot on Telegram. Use the method of creating a new bot via [@BotFather](https://t.me/botfather), have the HTTP API and ChatID to proceed.

1. Download the contents of the `codes/tbot` folder from this repository and add it to the router in the `/etc/storage` folder.

As this is a simple shell script, you are free to enter any changes you want to send an alert. In my case I used the standard for signaling changes in IP addresses.

2. Change the **API_TOKEN=** and **CHAT_ID=** fields to your bot's credentials.

3. Execute `mtd_storage.sh save` to save modifications.

4. Then we add the command line below for your activation on the firmware interface, on **Advanced Settings** » **Customization** » **Scripts** » **Run After WAN Up/Down Events:**

```
### Bot Telegram
sleep 30
/etc/storage/tg_say.sh WAN Up, IP: $3
```

Supported parameters represent:

* $1 - WAN Action (Rise / Fall).
* $2 - WAN interface name (for example eth3 or ppp0).
* $3 - WAN IPv4 address.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ZeroTier

ZeroTier makes it possible to implement VPNs in environments with NAT or behind a firewall where no additional configuration is required, in other words, the router does not need to be exposed through the WAN port to allow external access.

1. Whether on Internal Entware or USB, install the package `zerotier`:
```
opkg update
opkg install zerotier
```
2. Run it: `zerotier-one -d`.

3. Run the command `zerotier-cli info` where you will get something like:
```
200 info <YOU-ID> <ZeroTier Version> ONLINE
```
4. Make a brief registration on the [site](https://www.zerotier.com/#) and create your own network segment. You will receive a unique ID for this network.

5. Connect to the network created with the command and the network ID obtained in the previous step: `zerotier-cli join <NETWORK-ID>`

6. Return to the website and in the network settings by clicking on your ID, go to the "Members" section, you will see your router there. You must authorize it by checking the appropriate checkbox, naming is also possible.

7. Now  we add the set of command lines below on the firmware interface, on **Advanced Settings** » **Customization** » **Scripts** » **Run After Firewall Rules Restarted:**:
```
### ZeroTier Rules
iptables -I INPUT -i <NETWORK-IFACE> -j ACCEPT
iptables -t nat -A PREROUTING -d <ZEROTIER-IP-ADDRESS> -p tcp --dport 443 -j DNAT --to-destination 192.168.1.1:443
```

Run `ip -br a` to get the network interface and IP address of the ZeroTier network that was previously configured.

Change from 443 to 80 if you don't use HTTPS access.

8. Add the command line below for activating the ZeroTier daemon when restarting the router, on **Advanced Settings** » **Customization** » **Scripts** » **Run After Router Started:**:
```
### ZeroTier
/opt/bin/zerotier-one -d
```

9. Install a [ZeroTier client](https://www.zerotier.com/download/) on the device that will gain access to the router remotely, such as an Android smartphone for example. Enter your network ID and connect.

You will have to repeat the same procedure from step 6 above to authorize access to the clients that will connect to this network.

10. You will be able to access the router through ZeroTier's IP address, the same one chosen for the network in step 4.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Padarouter

Padarouter brings a router management interface through an app for Android devices. Originally Chinese, the app has a version in English, Russian and Brazilian Portuguese, the latter translated by me.

* [Download English version](https://github.com/ciro-mota/padavan-collection/raw/main/assets/com.padarouter.manager_en-US.apk) (Not fully translated, there are snippets of the app in Russian language.)
* [Download Português Brasil version](https://github.com/ciro-mota/padavan-collection/raw/main/assets/com.padarouter.manager_pt-BR.apk) (Alguns erros de tradução são esperados.)

<img src="https://raw.githubusercontent.com/ciro-mota/padavan-collection/main/assets/padarouter.jpg" alt="Padarouter" width="520" height="860"/>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Sponsoring

If you like this work, give me it a star on GitHub, and consider supporting it:

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate/?business=VUS6R8TX53NTS&no_recurring=0&currency_code=USD)


<p align="right">(<a href="#readme-top">back to top</a>)</p>