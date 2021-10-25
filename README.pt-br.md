# Procedimentos e otimizações para o Firmware Padavan

<p align="center">
<img width="300" height="150" src="https://imgur.com/X2MlXSz.png">
</p>

<img src="https://img.shields.io/badge/Licença-GPLv3-blue.svg?style=for-the-badge"> <img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/ciro-mota/padavan-collection?style=for-the-badge"> <img src="https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white">

Este Git reúne alguns procedimentos que podem ser usados para obter o melhor do Firmware Padavan. Estes são procedimentos divulgados publicamente no [Fórum 4pda](https://4pda.to/forum/index.php?showtopic=837667), [Wiki](https://bitbucket.org/padavan/rt-n56u/wiki/browse/RU) e adaptado para uso. Para que os procedimentos abaixo funcionem de maneira ideal, o firmware deve ser compilado no Prometheus com as seguintes opções ativadas:

```
CONFIG_FIRMWARE_INCLUDE_QOS=y
CONFIG_FIRMWARE_INCLUDE_IMQ=y
CONFIG_FIRMWARE_INCLUDE_IFB=y
CONFIG_FIRMWARE_INCLUDE_OPENSSL_EXE=y
CONFIG_FIRMWARE_INCLUDE_OPENSSL_EC=y
```

Todos esses procedimentos foram testados e usados em um **Xiaomi Mi Router 3G**, sendo compatível com o Xiaomi Mi Router 3. No entanto, é possível que possam ser aplicados em outros modelos suportados por este firmware.

## Tabela de conteúdo
1. [Ativando Entware interno](#Ativando-Entware-interno)
2. [AdBlock Integrado](#AdBlock-Integrado)
3. [DNS Over HTTPS](#DNS-Over-HTTPS)
4. [HTTPS com domínio local](#HTTPS-com-domínio-local)
5. [Controle dos LEDs](#LEDs)
6. [Alertas no Telegram](#Alertas-no-Telegram)
7. [ZeroTier](#ZeroTier)
8. [Padaroute](#Padarouter)

## Ativando Entware interno

O Entware interno aproveita um pequeno espaço da memória interna do roteador onde podem ser instalados programas e alguns arquivos salvos, sem a necessidade de um drive USB externo. Muito útil para instalar aplicativos não incluídos na construção de firmware padrão.

Para o procedimento, é necessário determinar o número da partição "RWFS" que possui o espaço livre.

1. Para fazer isso, em uma sessão SSH em um terminal, digite o comando `cat /proc/mtd` e veja a lista de partições. Você verá algo como isto: `mtd11: 06080000 00020000 "RWFS"`

![](/assets/mtd.png)

2. Formate esta partição RWFS com formato UBIFS, digite o comando seguinte para isso: `ubiformat /dev/mtd11`

3. Em seguida, adicionamos o conjunto de linhas de comando abaixo para sua ativação nas configurações do firmware, em **Advanced Settings** » **Customization** » **Scripts** » **Run After Router Started:**:

```
## Enable Internal Entware
ubiattach -p /dev/mtd11
ubimkvol /dev/ubi0 -m -N user
mkdir /mnt/opt
mount -t ubifs ubi0 /mnt/opt
opt-mount.sh /dev/ubi0 /mnt
opkg.sh
```
Aplique e reinicie o roteador depois disso.

4 - Conseguimos verificar se tudo funcionou executando o comando: `opkg update`

![](/assets/opkg.png)

Esta é a lista de [pacotes disponíveis](https://bin.entware.net/armv7sf-k3.2/Packages.html) para instalação, devido ao tamanho pequeno do espaço de disco use-o com cautela.

## AdBlock Integrado

Através do Entware interno ou através do Entware habilitado em um drive USB externo, conseguimos gerar um arquivo host contendo listas de bloqueio de endereços, úteis para o controle dos pais e/ou para um AdBlock interno, trazendo assim maior segurança à rede local.

Este procedimento não é 100% eficaz e ainda pode ser necessário o uso de bloqueadores em navegadores.

Se após a sua instalação algum site não funcionar corretamente, adicione o seu nome de domínio no arquivo `adblock_allow.list`, apenas o nome do domínio, exemplo: `github.com`

Outros sites que precisam ser bloqueados podem ser adicionados no arquivo `adblock_deny.list`, também apenas o nome do domínio.

No meu caso, optei por usar o conjunto de listas do grupo [Energized](https://energized.pro/), que são constantemente atualizados e têm muitas opções de lista para download.

1. Baixe o conteúdo da pasta `codes/adblock` deste repositório e adicione-o ao roteador na pasta `/etc/storage`.

2. Ative o redirecionamento para o novo arquivo de hosts em: **LAN** » **DHCP Server** » **Custom Configuration File "dnsmasq.conf"**. Adicionando estas linhas abaixo:

```
### Internal AdBlock
addn-hosts=/tmp/hosts
```

Se necessário, aplique permissões de execução ao script com `chmod u+x adblock_update.sh`.

3. Execute `mtd_storage.sh save` para salvar as modificações.

4. Você pode forçar a execução do script a qualquer momento usando o comando: `/etc/storage/adblock_update.sh` ou `./adblock_update.sh` se estiver no mesmo diretório do arquivo.

5. Pode ser que você queira criar um cronograma para atualização automática das listas, para isso adicione a linha abaixo com o período desejado em **Administration** » **Services** » **Cron Daemon (Scheduler)?** » **Scheduler tasks (Crontab)**:

```
### Update AdBlock
00 8 * * 6 /etc/storage/adblock_update.sh >/dev/null 2>&1
```
A atualização ocorrerá todos os domingos às 8h00.
Você pode precisar editar regularmente o agente do usuário do script (parâmetro -U na linha wget) para uma versão mais recente do navegador.

![](/assets/energized.png)

## DNS Over HTTPS

O tráfego DNS é geralmente vulnerável a invasores porque existe a possibilidade de "ouvir" sua comunicação e interceptar dados pessoais desprotegidos. Com isso, os provedores de serviços de Internet também podem monitorar seu tráfego e, possivelmente, coletar tudo sobre os sites que você visita.

DoH e DoT são protocolos DNS seguros que podem alterar esse comportamento por meio de um canal criptografado. DNS sobre TLS [RFC7858](https://tools.ietf.org/html/rfc7858) e DNS over HTTPS [RFC8484](https://tools.ietf.org/html/rfc8484) são projetados para proteger o tráfego DNS. Você pode querer se aprofundar no assunto lendo as RFCs listadas aqui.

Através do proxy DNSCrypt é possível habilitar o suporte DoT e/ou DoH neste firmware, com mais opções personalizáveis do que a presente na construção padrão do firmware.

1. Seja em Entware interno ou USB, instale o pacote `dnscrypt-proxy2`:
```
opkg update
opkg install dnscrypt-proxy2
```
2. Em WAN » **WAN DNS Settings** » **Get the DNS Server Address Automatically?** clique em **Disable**. Em **DNS Server 1**: coloque `127.0.0.1`. **WAN** » **WAN DNSv6 Settings** » **Get DNSv6 Servers Automatically?** clique **Disable** também.

3. O pacote irá inserir o arquivo `dnscrypt-proxy.toml` no diretório `/opt/etc` onde algumas edições são necessárias.  

    3.1. Em `server_names`, edite com os servidores DNS que deseja usar. Uma lista dos disponíveis pode ser encontrada em [neste link](https://dnscrypt.info/public-servers/). Exemplo:

    ```
    server_names = ['cloudflare', 'cloudflare-ipv6', 'nextdns', 'nextdns-ipv6']
    ```
    3.2. Em `listen_addresses` mude a porta para uma porta alta, por exemplo. Este procedimento é opcional.

    ```
    listen_addresses = ['127.0.0.1:65053']
    ```

    3.3. Mude `ipv6_servers` para True apenas se você tiver conexões IPv6 ativas.

    3.4. Descomente a linha `tls_cipher_suite = [52392, 49199]`, isso causará um baixo uso de recursos ao usar DNSCrypt neste roteador.

    3.5. `fallback_resolver` e `netprobe_address` pode ser editado em um servidor DNS de sua escolha porém diferentes dos utilizados na configuração padrão (item 3.1).

4. Em uma sessão SSH, execute o comando `/opt/etc/init.d/S09dnscrypt-proxy2 start` para habilitar o DNSCrypt. 

![](/assets/doh-ensi.png)

## HTTPS com domínio local

HTTPs agora é o padrão para endereços da web e Padavan suporta esse recurso, mas com um certificado auto assinado que não é reconhecido nativamente pelos navegadores. Para contornar isso, é possível, com a ajuda de Let's Encrypt e um DDNS válido, ter seu próprio endereço de acesso ao roteador.

Existem muitos serviços DDNS, gratuitos e pagos. Especificamente em nosso caso, é recomendado o uso do [DuckDNS](https://www.duckdns.org/), que permite a criação de um DDNS gratuito e acessível para uso com Let's Encrypt.

1. Ative o suporte a HTTPs em **Administration** » **Services** » **Web Server Protocol.**

2. Mude o campo `List of Allowed SSL Ciphers for HTTPS:` para:
```
TLS_CHACHA20_POLY1305_SHA256:DH+AESGCM:DH+AES256:DH+AES:DH+3DES:RSA+AES:RSA+3DES:!ADH:!MD5:!DSS`
```
3. Baixe o conteúdo da pasta `codes/ca-cert` deste repositório e adicione-o ao roteador na pasta `/etc/storage`.

Se necessário, aplique permissões de execução ao script com `chmod u+x update-cert.sh`.

4. Você precisa editar alguns campos na seção `Variables` do script, como por exemplo **DDNS domain** e **token** gerados pelo DuckDNS. O script precisará ser modificado se outro serviço for usado.

Você também precisará editar a linha 12 do script para apontar para sua interface WAN, no meu caso eu uso o protocolo PPP e isso é conhecido como `ppp0` no script. Execute `ip a s` em uma conexão SSH no Terminal para verificar qual interface recebe um endereço IP público.

5. Execute `mtd_storage.sh save` para salvar as modificações.

6. Você pode forçar a execução do script a qualquer momento usando o comando: `/etc/storage/update-cert.sh` ou `./update-cert.sh` se estiver no mesmo diretório do arquivo.

7. Os certificados são válidos por 90 dias. Você pode querer criar uma programação para atualização automática, para isso adicione a linha abaixo com o período desejado em **Administration** » **Services** » **Cron Daemon (Scheduler)?** » **Scheduler tasks (Crontab)**:

```
### Update Cert
0 9 */90 * * /etc/storage/update-cert.sh >/dev/null 2>&1
```
A atualização ocorrerá a cada 90 dias, às 9h.  

8. Ative o redirecionamento para o endereço em **LAN** » **DHCP Server** » **Custom Configuration File "dnsmasq.conf"** adicionando a linha abaixo:

```
### Internal Cert
address=/seu-dominio.duckdns.org/192.168.0.1
```
Mude para o seu nome de domínio e endereço IP do roteador.

![](/assets/encrypt.png)
## LEDs

Você pode querer controlar quando os LEDs do roteador podem ser acesos ou não. Para fazer isso, adicione um regra no Crontab (**Administration** » **Services** » **Cron Daemon (Scheduler)?** » **Scheduler tasks (Crontab)**) para desligá-los:
```
00 17 * * * leds_front 0
00 17 * * * leds_ether 0  
10 17 * * * leds_front 1
10 17 * * * leds_ether 1
```
0 irá representar desligado e 1 ligado.

## Alertas no Telegram

É possível configurar alertas personalizados para serem enviados a um determinado bot no Telegram. Use o método de criação de um novo bot via [@BotFather](https://t.me/botfather), tenha a API HTTP e ChatID para prosseguir.

1. Baixe o conteúdo da pasta `codes/tbot` deste repositório e adicione-o ao roteador na pasta `/etc/storage`.

Como este é um script de shell simples, você está livre para inserir as alterações que deseja enviar um alerta. No meu caso, usei o padrão para sinalizar mudanças em endereços IP.

2. Mude os campos **API_TOKEN=** e **CHAT_ID=** para as credenciais de acesso ao seu bot.

3. Execute `mtd_storage.sh save` para salvar as modificações.

4. Em seguida, adicionamos a linha de comando abaixo para sua ativação nas configurações do firmware, em **Advanced Settings** » **Customization** » **Scripts** » **Run After WAN Up/Down Events:**

```
### Bot Telegram
sleep 30
/etc/storage/tg_say.sh WAN Up, IP: $3
```

Os parâmetros suportados representam:

* $1 - WAN Ação (Up / Down).
* $2 - WAN nome da interface (por exemplo eth3 ou ppp0).
* $3 - WAN endereço IPv4.

## ZeroTier

O ZeroTier possibilita a implementação de VPNs em ambientes com NAT ou atrás de um firewall onde nenhuma configuração adicional é necessária, ou seja, o roteador não precisa ser exposto através da porta WAN para permitir acesso externo.

1. Seja em Entware interno ou USB, instale o pacote `zerotier`:
```
opkg update
opkg install zerotier
```
2. Execute: `zerotier-one -d`.

3. Execute o comando `zerotier-cli info` onde você receberá algo como:
```
200 info <SUA-ID> <Versão do ZeroTier> ONLINE
```
4. Faça um breve cadastro no [site](https://www.zerotier.com/#) e crie seu próprio segmento de rede. Você receberá uma identificação exclusiva para esta rede.

5. Conecte-se à rede criada com o comando seguinte e o ID de rede obtido na etapa anterior: `zerotier-cli join <NETWORK-ID>`

6. Volte ao site e nas configurações de rede clicando no seu ID, vá para a seção "Membros", você verá o seu roteador lá. Você deve autorizá-lo marcando a caixa de seleção apropriada, também é possível renomear para um novo nome de fácil reconhecimento.

7. Em seguida, adicionamos a linha de comando abaixo para sua ativação nas configurações do firmware, em **Advanced Settings** » **Customization** » **Scripts** » **Run After Firewall Rules Restarted:**:
```
### ZeroTier Rules
iptables -I INPUT -i <NETWORK-IFACE> -j ACCEPT
iptables -t nat -A PREROUTING -d <ZEROTIER-IP-ADDRESS> -p tcp --dport 443 -j DNAT --to-destination 192.168.1.1:443
```

Execute `ip -br a` para obter a interface de rede e o endereço IP da rede ZeroTier que foi configurada anteriormente.

Mude de 443 para 80 se você não usar o acesso HTTPS.

8. Adicione a linha de comando abaixo para ativar o daemon do ZeroTier ao reiniciar o roteador, em **Advanced Settings** » **Customization** » **Scripts** » **Run After Router Started:**:
```
### ZeroTier
/opt/bin/zerotier-one -d
```

9. Instale um cliente [ZeroTier](https://www.zerotier.com/download/) no dispositivo que terá acesso ao roteador remotamente, como um smartphone Android, por exemplo. Digite sua ID de rede e conecte-se.

Você terá que repetir o mesmo procedimento da etapa 6 acima para autorizar o acesso aos clientes que se conectarão a esta rede.

10. Você poderá acessar o roteador através do endereço IP do ZeroTier, o mesmo escolhido para a rede na etapa 4.

## Padarouter

Padarouter traz uma interface de gerenciamento de roteador através de um aplicativo para dispositivos Android. Originalmente chinês, o aplicativo possui uma versão em inglês, russo e português brasileiro, este último traduzido por mim.

* [Download English version](https://github.com/ciro-mota/padavan-collection/raw/main/assets/com.padarouter.manager_en-US.apk) (Não totalmente traduzido, há trechos do aplicativo no idioma russo.)

* [Download Português Brasil version](https://github.com/ciro-mota/padavan-collection/raw/main/assets/com.padarouter.manager_pt-BR.apk) (Alguns erros de tradução são esperados.)

<img src="https://raw.githubusercontent.com/ciro-mota/padavan-collection/main/assets/padarouter.jpg" alt="Padarouter" width="520" height="860"/>