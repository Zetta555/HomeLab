# Дока по конфигурации периметрового маршрутизатора домашней лаборатории на базе MikroTik RB4011iGS+5HacQ2HnD под управлением RouterOS 7.20.6.
## Dual-WAN Gateway с сегментацией LAN/DMZ/VPN
![RouterOS](https://img.shields.io/badge/RouterOS-7.20.6-blue
)
![Model](https://img.shields.io/badge/Model-RB4011iGS%2B5HacQ2HnD-red)
---

## Введение

Это документация по конфигурации шлюза на базе MikroTik RB4011. Устройство работает как основной маршрутизатор для домашней/небольшой корпоративной сети с двумя интернет-провайдерами, сегментацией сети и VPN-доступом для администрирования.

Основные задачи, которые решает эта конфигурация:
- Автоматический failover между двумя ISP с проверкой реальной доступности интернета
- Изоляция DMZ от внутренней сети
- Удалённый административный доступ через WireGuard
- Мониторинг и оповещения через Telegram
- Защита от типовых атак (сканирование, брутфорс, SYN-flood)

## Предпосылки

Удалёнка, — VPN до рабочего окружения, спорадический удалённый доступ к домашнему компу непонятно откуда, созвоны и т.д, и т.п. Существовавший канал падал редко, но как правило в самое неудобное время. Сейчас пользую двух провайдеров (1 Гбит + 500 Мбит), от каждого по "белому" адресу. Вероятность одновременного падения существует, но значительно меньше, вкрай есть мобильный инет. Плюс у меня нет нужды в балансировке ради скорости. Гиперцель другая: не потерять связь при аварии на одном провайдере, при этом сохранить понятное поведение (что куда ходит).
Путь к текущему решению был, скажем так, итеративным. Сначала переключал вручную — тупо и просто, но отвлекает на первичную диагностику, да и не по феншую)). Потом check-gateway=ping на шлюз провайдера — шлюз отвечает даже когда интернета за ним нет (известная проблема). Пользовал recursive routing с одним check-host на прова — ловил ложные срабатывания (с разной степенью зажимания таймингов проверки в поисках оптимального времени срабатывания failover-а). Добавил второй check-host на каждого провайдера, теперь один check-host в зоне RU, второй - глобальный: failover срабатывает только если оба хоста недоступны. Пока ноль ложных переключений.

---

## 1. Топология и адресация

### 1.1. Физические интерфейсы

```
┌─────────────────────────────────────────────────────────┐
│                     RB4011iGS+5HacQ2HnD                 │
├─────────────┬───────────────────────────────────────────┤
│ ether1-WAN1 │ ISP1 — основной провайдер                 │
│ ether2-WAN2 │ ISP2 — резервный провайдер                │
│ ether3-LAN  │ Порт в bridge br-lan → к "Cudy WR6500H"   │
│ ether4-LAN  │ Порт в bridge br-lan → резерв             │
│ ether5-10   │ Отключены, зарезервированы                │
│ sfp-sfpplus1│ Отключен                                  │
│ wlan1       │ 2.4GHz — отключен, не используется        │
│ wlan2-DMZ   │ 5GHz — точка доступа для DMZ-устройств    │
│ wg-vpn      │ WireGuard туннель для админов             │
└─────────────┴───────────────────────────────────────────┘
```

Cudy WR6500H работает в режиме моста (wireless bridge) и раздаёт Wi-Fi для LAN-клиентов. Вся маршрутизация, DHCP и firewall — на RB4011.

### 1.2. IP-адресация

| Сегмент | Подсеть | Gateway | Интерфейс |
|---------|---------|---------|-----------|
| ISP1 WAN | 203.0.113.0/24 (RFC 5737) | 203.0.113.1 | ether1-WAN1 |
| ISP2 WAN | 198.51.100.0/24 (RFC 5737) | 198.51.100.1 | ether2-WAN2 |
| LAN | 172.30.30.0/24 | 172.30.30.1 | br-lan |
| DMZ | 10.100.100.0/24 | 10.100.100.1 | wlan2-DMZ |
| VPN | 10.200.200.0/24 | 10.200.200.1 | wg-vpn |

### 1.3. Interface Lists

Для читаемости и удобства управления firewall-правил использую списки интерфейсов:

| Группа     | Интерфейсы                         |
|------------|------------------------------------|
| WAN        | `ether1-WAN1`, `ether2-WAN2`       |
| LAN        | `br-lan`                           |
| DMZ        | `wlan2-DMZ`                        |
| VPN        | `wg-vpn`                           |
| INTERNAL   | `br-lan`, `wlan2-DMZ`, `wg-vpn`    |

Список INTERNAL объединяет все «внутренние» интерфейсы для правил, где нужно отличить трафик «снаружи» от трафика «изнутри».

---

## 2. Маршрутизация: Dual-WAN с Recursive Routing

### 2.1. Проблема

Стандартный check-gateway=ping проверяет только доступность next-hop (шлюза провайдера). Но шлюз может отвечать, а интернета за ним — нет. Бывает при проблемах за провайдером выше по цепочке.

Мне нужно:
1. Проверять реальную доступность интернета через каждого провайдера
2. Автоматически переключаться при падении основного канала (чем быстрее, тем лучше)
3. Избежать ложных срабатываний из-за кратковременной недоступности одного check-host

### 2.2. Решение: Recursive Routing с ДВУМЯ check-hosts на провайдера

Суть идеи: вместо проверки шлюза провайдера, проверяется доступность по ДВА публичных сервера через каждого провайдера.

#### Шаг 1: Привязка check-hosts к провайдерам

```routeros
# ISP1: два check-host привязаны к интерфейсу ISP1
add dst-address=87.240.132.72/32 gateway=<ISP1_GW>%ether1-WAN1 scope=10 target-scope=10
add dst-address=208.67.222.222/32 gateway=<ISP1_GW>%ether1-WAN1 scope=10 target-scope=10

# ISP2: два check-host привязаны к интерфейсу ISP2
add dst-address=95.143.182.1/32 gateway=<ISP2_GW>%ether2-WAN2 scope=10 target-scope=10
add dst-address=9.9.9.9/32 gateway=<ISP2_GW>%ether2-WAN2 scope=10 target-scope=10
```

Синтаксис `gateway%interface` гарантирует, что пакеты к check-host идут именно через указанный интерфейс. Без этого маршрутизатор мог бы выбрать другой путь.

Параметр `scope=10` важен: он определяет, что этот маршрут может быть gateway для маршрутов с `target-scope >= 10`.

#### Шаг 2: Default routes через check-hosts

```routeros
# Основной путь — через ISP1 (distance=1)
add dst-address=0.0.0.0/0 gateway=87.240.132.72 check-gateway=ping distance=1 target-scope=11
add dst-address=0.0.0.0/0 gateway=208.67.222.222 check-gateway=ping distance=1 target-scope=11

# Резервный путь — через ISP2 (distance=2)
add dst-address=0.0.0.0/0 gateway=95.143.182.1 check-gateway=ping distance=2 target-scope=11
add dst-address=0.0.0.0/0 gateway=9.9.9.9 check-gateway=ping distance=2 target-scope=11
```

Параметр `target-scope=11` означает, что этот маршрут ищет gateway среди маршрутов с `scope <= 11`. Поскольку маршруты к check-hosts имеют `scope=10`, рекурсия работает.

#### Шаг 3: Blackhole для недоступных check-hosts

```routeros
add dst-address=87.240.132.72/32 blackhole distance=254
add dst-address=208.67.222.222/32 blackhole distance=254
add dst-address=95.143.182.1/32 blackhole distance=254
add dst-address=9.9.9.9/32 blackhole distance=254
```

Зачем это нужно: если провайдер упал и маршрут к check-host через него исчез, без blackhole маршрутизатор может попытаться достучаться до check-host через другой маршрут (например, через второго провайдера). Это сломает логику проверки.

Blackhole с distance=254 активируется только когда основной маршрут к check-host недоступен. Он «глушит» трафик к этому адресу, что приводит к неудаче ping-проверки и деактивации соответствующего default route.

### 2.3. Почему два check-host на провайдера

Вот ключевой момент, который стоит объяснить подробнее.

Я использую два default routes с одинаковым distance для каждого провайдера:
- `RT-03` и `RT-03a` — оба distance=1, оба для ISP1
- `RT-04` и `RT-04a` — оба distance=2, оба для ISP2

**Что происходит при нормальной работе:**

Когда оба check-host провайдера доступны (например, 87.240.132.72 и 208.67.222.222 для ISP1), оба маршрута активны. С точки зрения маршрутизации это ECMP — трафик может идти через любой из них. Но поскольку оба check-host маршрутизируются через один и тот же интерфейс (ether1-WAN1), реальный путь трафика не меняется. Это не создаёт проблем.

**Зачем тогда два маршрута?**

Защита от ложных срабатываний. Ситуация:
- ISP1 работает нормально
- Но 87.240.132.72 внезапно недоступен (проблемы у вконтактика, DDoS, routing issue где-то в сети)

Если бы у меня был только один check-host:
1. Ping на 87.240.132.72 не проходит
2. Маршрут RT-03 деактивируется
3. Трафик переключается на ISP2 (distance=2)
4. Теряются сессии, меняется внешний IP

С двумя check-hosts:
1. Ping на 87.240.132.72 не проходит
2. Маршрут RT-03 деактивируется
3. Но RT-03a через 208.67.222.222 всё ещё активен (distance=1)
4. Трафик продолжает идти через ISP1
5. Переключение на ISP2 произойдёт только если оба check-host ISP1 недоступны

**Вывод:** два check-host — это избыточность проверки, а не балансировка. Failover происходит только когда весь провайдер недоступен, а не один конкретный сервер в интернете.

### 2.4. Routing Tables для Policy-Based Routing

Помимо main table, созданы две дополнительные таблицы маршрутизации:

```routeros
/routing table
add name=to-isp1 fib
add name=to-isp2 fib
```

В каждой таблице — свои default routes:

```routeros
# to-isp1: primary через ISP1, failover через ISP2
add dst-address=0.0.0.0/0 gateway=87.240.132.72 distance=1 routing-table=to-isp1
add dst-address=0.0.0.0/0 gateway=95.143.182.1 distance=2 routing-table=to-isp1

# to-isp2: primary через ISP2, failover через ISP1
add dst-address=0.0.0.0/0 gateway=95.143.182.1 distance=1 routing-table=to-isp2
add dst-address=0.0.0.0/0 gateway=87.240.132.72 distance=2 routing-table=to-isp2
```

### 2.5. Routing Rules: распределение трафика по сегментам

```routeros
/routing rule
# Ответы на входящие соединения идут через тот же ISP
add routing-mark=to-isp1 action=lookup-only-in-table table=to-isp1
add routing-mark=to-isp2 action=lookup-only-in-table table=to-isp2

# LAN идёт через ISP1 (с failover на ISP2)
add src-address=172.30.30.0/24 action=lookup-only-in-table table=to-isp1

# DMZ идёт через ISP2 (с failover на ISP1)
add src-address=10.100.100.0/24 action=lookup-only-in-table table=to-isp2

# VPN идёт через ISP1 (с failover на ISP2)
add src-address=10.200.200.0/24 action=lookup-only-in-table table=to-isp1
```

Такое распределение имеет смысл: DMZ-сервер публикует сервисы на обоих провайдерах, но основной трафик из DMZ идёт через ISP2. LAN и VPN — через ISP1 как основной.

### 2.6. Симметричная маршрутизация (Connection Marking)

Проблема: когда на WAN-адрес ISP2 приходит входящее соединение, ответы должны уходить через ISP2, а не через ISP1 (который может быть активным default route).

Решение в mangle:

```routeros
/ip firewall mangle
# Маркируем входящие соединения по интерфейсу
add chain=prerouting connection-state=new in-interface=ether1-WAN1 
    action=mark-connection new-connection-mark=conn-from-isp1

add chain=prerouting connection-state=new in-interface=ether2-WAN2 
    action=mark-connection new-connection-mark=conn-from-isp2

# Ставим routing-mark на пакеты маркированных соединений
add chain=prerouting connection-mark=conn-from-isp1 dst-address-type=!local 
    action=mark-routing new-routing-mark=to-isp1

add chain=prerouting connection-mark=conn-from-isp2 dst-address-type=!local 
    action=mark-routing new-routing-mark=to-isp2

# То же для исходящего трафика самого роутера
add chain=output connection-mark=conn-from-isp1 dst-address-type=!local 
    action=mark-routing new-routing-mark=to-isp1

add chain=output connection-mark=conn-from-isp2 dst-address-type=!local 
    action=mark-routing new-routing-mark=to-isp2
```

Теперь при подключении к веб-серверу через ISP2, ответы гарантированно пойдут через ISP2.

---

## 3. Firewall

### 3.1. Общая архитектура

Firewall построен на цепочках (chains). Базовые цепочки (input, forward, output) выполняют общую обработку и делают jump в специализированные цепочки по типу интерфейса.

```
input ──┬── input-wan   (трафик из WAN к роутеру)
        ├── input-lan   (трафик из LAN к роутеру)
        ├── input-dmz   (трафик из DMZ к роутеру)
        └── input-vpn   (трафик из VPN к роутеру)

forward ─┬── forward-lan  (LAN → куда угодно)
         ├── forward-dmz  (DMZ → куда угодно)
         ├── forward-vpn  (VPN → куда угодно)
         ├── forward-wan  (WAN → внутрь, для DNAT)
         └── syn-flood    (проверка SYN-flood)
```

### 3.2. Chain: input

```routeros
[IN-01] Accept established/related  — пропускаем пакеты существующих соединений
[IN-02] Drop invalid                — отбрасываем мусор
[IN-03] Jump to input-wan           — трафик из WAN
[IN-04] Jump to input-lan           — трафик из LAN
[IN-05] Jump to input-dmz           — трафик из DMZ
[IN-06] Jump to input-vpn           — трафик из VPN
[IN-07] Default drop                — всё остальное отбрасываем
```

Порядок важен: сначала established/related (они составляют >95% трафика), потом invalid, потом jump'ы.

### 3.3. Chain: input-wan

Защита роутера от атак из интернета (подход на доработке, по идее можно разрешить явно только то, что нужно, замкнуть дропом всего остального).

```routeros
[IW-01..04] Детекция сканирования портов (XMAS, NULL, SYN-FIN, SYN-RST)
            → добавление в address-list SCANNER на 24 часа

[IW-05]     Эскалация: SCANNER → BAD-ACTORS

[IW-06]     Drop всех из SCANNER

[IW-07..08] Drop DNS-запросов (защита от DNS amplification)

[IW-09..11] WireGuard rate-limiting:
            - Drop если в WG-FLOOD
            - Accept до 20 пакетов/сек
            - Превышение → WG-FLOOD на 1 час

[IW-12]     Drop ICMP (выбрана политика: не отвечать на ping из WAN)

[IW-13]     Drop всего остального
```

### 3.4. Chain: input-lan

```routeros
[IL-01]     ICMP — разрешено (нужно для диагностики)
[IL-02..03] DNS UDP/TCP — разрешено (роутер — DNS-резолвер для LAN)
[IL-04]     DHCP — разрешено
[IL-05]     NTP — разрешено
[IL-06..07] Winbox: попытка подключения не из MGMT-SOURCES 
            → добавление в LAN-WINBOX-BAD, затем drop
[IL-08..10] SSH, Winbox, HTTPS — только из MGMT-SOURCES
[IL-11]     Drop остального
```

Список MGMT-SOURCES содержит:
- 172.30.30.30 (Admin Workstation)
- 172.30.30.105 (Admin Laptop)
- 10.200.200.2 (VPN admin)

Это защита от ситуации, когда кто-то подключит своё устройство к LAN и попытается управлять роутером (маловероятно, но пусть будет).

### 3.5. Chain: input-dmz

DMZ — это зона пониженного доверия. Устройства в DMZ не должны управлять роутером.

```routeros
[ID-01]     ICMP — только от DMZ-MONITORING
[ID-02]     DHCP — разрешено
[ID-03..04] SNMP, Syslog — только от DMZ-MONITORING (для мониторинга)
[ID-05]     Log попыток доступа к management-портам
[ID-06]     Block management (SSH, Winbox, HTTPS, API)
[ID-07]     Drop остального
```

### 3.6. Chain: input-vpn

VPN-клиенты (администраторы) имеют привилегированный доступ.

```routeros
[IV-01]     ICMP — разрешено
[IV-02..03] DNS — разрешено
[IV-04..06] SSH, Winbox, HTTPS — только из MGMT-SOURCES
[IV-07]     Drop остального
```

### 3.7. Chain: forward

```routeros
[FW-01] Jump syn-flood        — проверка SYN-flood для new TCP из WAN
[FW-02] FastTrack             — ускорение established/related (hw-offload)
[FW-03] Accept established    — если не попало в FastTrack
[FW-04] Drop invalid
[FW-05..08] Jump в forward-lan/dmz/vpn/wan
[FW-09a] Log unexpected       — логируем то, что не попало в цепочки
[FW-09] Default drop
```

**FastTrack** — это hardware offload. Пакеты established соединений обрабатываются чипом, минуя CPU. Условия:
- connection-mark=no-mark (без маркировки)
- connection-nat-state=!dstnat (не DNAT)
- connection-state=established,related


### 3.8. Chain: forward-lan

```routeros
[FL-01] LAN → DMZ — разрешено
[FL-02] LAN → VPN — разрешено (админ может достучаться до VPN-клиентов)
[FL-03] LAN → Internet (WAN) — разрешено
[FL-04] Drop остального
```

### 3.9. Chain: forward-dmz

DMZ изолирован от LAN и VPN:

```routeros
[FD-01a] Log DMZ → LAN (rate-limited)
[FD-01]  BLOCK DMZ → LAN
[FD-02a] Log DMZ → VPN
[FD-02]  BLOCK DMZ → VPN
[FD-03]  DMZ → Internet — разрешено
[FD-04]  Drop остального
```

Логирование с rate-limit (2/min) нужно, чтобы отследить попытки пробить изоляцию, но не забить логи.

### 3.10. Chain: forward-vpn

VPN-клиенты имеют полный доступ:

```routeros
[FV-01] VPN → LAN — разрешено
[FV-02] VPN → DMZ — разрешено
[FV-03] VPN → Internet — разрешено
[FV-04] Drop остального
```

### 3.11. Chain: forward-wan

Входящий трафик из WAN. Здесь обрабатываются DNAT-соединения (после NAT dst-address уже внутренний).

```routeros
[FWN-01] Drop HTTP/S от HTTP-ATTACKERS
[FWN-02] conn-limit > 100 на /32 → добавить в HTTP-ATTACKERS на 1 час
[FWN-03] Drop если conn-limit превышен
[FWN-04] Accept new до 10 conn/s на source-IP (dst-limit)
[FWN-05] Превышение → PORT-SCAN на 24 часа
[FWN-06] Log неожиданного трафика
[FWN-07] Drop всего
```

Логика защиты DMZ web-сервера:
1. `dst-limit=10,10,src-address/32s` — не более 10 новых соединений в секунду с одного IP (под вопросом, т.к. сервера самого нет)
2. `connection-limit=100,32` — не более 100 одновременных соединений с одного /32
3. Превышение → бан на 1 час или 24 часа

### 3.12. Chain: syn-flood

```routeros
[SF-01] Return если в пределах лимита (100 pps, burst 5)
[SF-02a] Log превышения
[SF-02] Drop excess
```

Это дополнительный уровень защиты. Основная защита от SYN-flood — в RAW.

### 3.13. RAW Table

RAW обрабатывает пакеты ДО connection tracking, эффективнее для отбрасывания мусора.

```routeros
[RAW-00] Drop BLACKLIST (внешний список, заполняется вручную или скриптом)
[RAW-01] Drop BAD-ACTORS (эскалированные сканеры)
[RAW-01a] Drop SCANNER
[RAW-02] Drop BOGONS (немаршрутизируемые адреса)
[RAW-03] Drop RFC1918 spoofing (приватные адреса из WAN)
[RAW-04] Drop PORT-SCAN для web-портов
[RAW-05] SYN-flood: return если < 500 pps (burst 100)
[RAW-06] SYN-flood: drop excess
```

Лимит SYN в RAW (500 pps) выше, чем в filter (100 pps). RAW отсекает грубые атаки, filter — более тонкую настройку.

---

## 4. NAT

### 4.1. Source NAT

```routeros
[NAT-01] No NAT: VPN → internal    — VPN-клиенты общаются с LAN/DMZ напрямую
[NAT-02] No NAT: internal → VPN    — и обратно
[NAT-03] SNAT → ISP1               — RFC1918 → <ISP1_IP> через ether1-WAN1
[NAT-04] SNAT → ISP2               — RFC1918 → <ISP2_IP> через ether2-WAN2
```

### 4.2. Destination NAT (Port Forwarding)

```routeros
[NAT-05] HTTP ISP1 → 10.100.100.100:80
[NAT-06] HTTPS ISP1 → 10.100.100.100:443
[NAT-07] HTTP ISP2 → 10.100.100.100:80
[NAT-08] HTTPS ISP2 → 10.100.100.100:443
```

DMZ web-сервер доступен через оба провайдера.

### 4.3. Hairpin NAT

Проблема: когда LAN-клиент обращается к публичному IP веб-сервера, пакет уходит на роутер, DNAT меняет dst на 10.100.100.100, но source остаётся LAN-адресом. Веб-сервер отвечает напрямую в LAN, клиент получает пакет с неожиданного source — соединение не работает.

Решение — два правила:

```routeros
[NAT-09] DNAT: internal → WAN-IPS:80,443 → 10.100.100.100
[NAT-10] SNAT: internal → 10.100.100.100:80,443 → source=10.100.100.1
```

Теперь путь: LAN → роутер (DNAT+SNAT) → DMZ web → роутер → LAN. Работает.

---

## 5. WireGuard VPN

### 5.1. Конфигурация сервера

```routeros
/interface wireguard
add name=wg-vpn listen-port=51820 mtu=1420

/interface wireguard peers
add interface=wg-vpn name=peer1
    public-key="<PEER_PUBLIC_KEY>"
    allowed-address=10.200.200.2/32
    comment="Admin Mobile"
```

MTU 1420 — стандарт для WireGuard (1500 - 80 overhead).

### 5.2. Защита от брутфорса

В input-wan:

```routeros
[IW-09] Drop если в WG-FLOOD
[IW-10] Accept до 20 pps
[IW-11] Превышение → WG-FLOOD на 1 час
```

20 пакетов в секунду достаточно для нормальной работы (handshake, keepalive), но останавливает перебор - (не проверял).

### 5.3. Что доступно VPN-клиенту

- DNS на роутере (172.30.30.1 или 10.200.200.1)
- Полный доступ к LAN (172.30.30.0/24)
- Полный доступ к DMZ (10.100.100.0/24)
- Интернет через роутер
- Управление роутером (SSH, Winbox, HTTPS) — только для адресов из MGMT-SOURCES

---

## 6. DHCP и DNS

### 6.1. DHCP-серверы

| Сервер | Pool | Диапазон | Lease |
|--------|------|----------|-------|
| dhcp-lan | pool-lan | 172.30.30.50-200 | 1 week |
| dhcp-dmz | pool-dmz | 10.100.100.50-99 | 1 week |

Статическое резервирование:
- 172.30.30.30 — Admin Workstation
- 172.30.30.105 — Admin Laptop  
- 172.30.30.100 — Cudy WR6500H (bridge mode)

### 6.2. DNS

Роутер выступает DNS-резолвером для LAN:

```routeros
/ip dns
set allow-remote-requests=yes
    servers=87.240.132.72,77.88.8.88,95.143.182.1,9.9.9.9
    cache-size=4096KiB
    cache-max-ttl=1d
    max-concurrent-queries=200
```

Для DMZ внешние DNS напрямую (8.8.8.8, 1.1.1.1) — DMZ не зависет от роутера для DNS.

---

## 7. Скрипты мониторинга и оповещения

### 7.1. Архитектура системы оповещений

Все скрипты используют Telegram Bot API для отправки уведомлений. Инициализация — в `telegram-init`:

```routeros
:global TelegramToken "<BOT_TOKEN>"
:global TelegramChatID "<CHAT_ID>"
:global TelegramEnabled true
:global RouterName [/system identity get name]
```

### 7.2. isp-health-monitor — ключевой скрипт failover

Запускается каждые 10 секунд через scheduler.

**Логика работы:**

1. Пингует 4 адреса (по 2 на провайдера) через соответствующие интерфейсы:
   - ISP1: 87.240.132.72, 208.67.222.222 через ether1-WAN1
   - ISP2: 95.143.182.1, 9.9.9.9 через ether2-WAN2

2. Провайдер считается UP, если хотя бы один из двух check-hosts отвечает.

3. Использует hysteresis (переменная `hyst=2`):
   - Для перехода UP→DOWN нужно 2 последовательных неудачи
   - Для перехода DOWN→UP нужно 2 последовательных успеха

4. При failover:
   - Очищает connection tracking для затронутых подсетей
   - Очищает ARP-таблицу на WAN-интерфейсе
   - Отправляет уведомление в Telegram

5. Отслеживает ситуацию «оба ISP down» и уведомляет после восстановления.

**Почему hysteresis важен:**

Без него один потерянный ping мог бы вызвать failover. Сеть «флапала» бы туда-сюда при малейших проблемах. С hysteresis=2 нужно 20 секунд (2 × 10 сек) устойчивых проблем для переключения.

**Почему очистка connection tracking:**

При failover старые соединения остаются в conntrack. Они привязаны к старому исходящему интерфейсу и NAT-адресу. Если их не очистить, эти соединения будут «висеть» до timeout, а новые пакеты в них — уходить в никуда.

### 7.3. Другие скрипты

| Скрипт | Интервал | Назначение |
|--------|----------|------------|
| notify-startup | при старте | Уведомление о перезагрузке |
| daily-report | 1 день (09:00) | Сводка: ISP status, uptime, CPU, RAM, connections, blocked IPs |
| notify-resources | 1 мин | Alert при CPU > 80% или RAM > 80% |
| notify-wireguard | 30 сек | Уведомление о подключении/отключении VPN-клиента |
| notify-interface | 30 сек | Уведомление об изменении состояния интерфейсов |
| notify-security-lists | 30 сек | Alert при добавлении новых IP в security-листы |
| notify-dhcp-new | 5 мин | Уведомление о новых DHCP-клиентах |
| notify-login | 2 мин | Отслеживание логинов и brute-force попыток |
| notify-firmware | 1 день (10:00) | Уведомление об обновлении прошивки |

Все скрипты хранят состояние в глобальных переменных или файлах (if-state.txt, sec-count.txt и т.д.), чтобы отправлять уведомления только при изменениях.

---

## 8. Hardening и безопасность

### 8.1. Отключённые сервисы

```routeros
/ip service
set ftp disabled=yes
set telnet disabled=yes
set www disabled=yes
set api disabled=yes
```
Оставлены только SSH, Winbox, HTTPS, API-SSL — и те ограничены по source-address.

### 8.2. Ограничение доступа к сервисам

```routeros
set ssh address=172.30.30.0/24,10.200.200.0/24
set www-ssl address=172.30.30.0/24,10.200.200.0/24
set winbox address=172.30.30.0/24,10.200.200.0/24
```

### 8.3. SSH hardening

```routeros
/ip ssh
set host-key-type=ed25519 strong-crypto=yes
```

### 8.4. Connection tracking tuning

```routeros
/ip firewall connection tracking
set tcp-established-timeout=4h
set tcp-syn-sent-timeout=10s
```

- `tcp-established-timeout=4h` (вместо дефолтного 1d) — быстрее освобождаем ресурсы от idle соединений
- `tcp-syn-sent-timeout=10s` (вместо 2m) — SYN без ответа не должны висеть долго

### 8.5. TCP SYN cookies

```routeros
/ip settings
set tcp-syncookies=yes
```

Защита от SYN-flood на уровне стека TCP.

### 8.6. Отключённые service ports (ALG)

```routeros
/ip firewall service-port
set ftp disabled=yes
set tftp disabled=yes
set h323 disabled=yes
set pptp disabled=yes
```

### 8.7. Минимальная длина пароля

```routeros
/user settings
set minimum-password-length=12
```

### 8.8. Отключение служебных сервисов

```routeros
/tool bandwidth-server
set enabled=no

/tool mac-server ping
set enabled=no
```
---

## 9. Address Lists

### 9.1. Статические списки

| Список | Содержимое | Назначение |
|--------|------------|------------|
| NET-LAN | 172.30.30.0/24 | LAN-подсеть |
| NET-DMZ | 10.100.100.0/24 | DMZ-подсеть |
| NET-VPN | 10.200.200.0/24 | VPN-подсеть |
| NET-INTERNAL | все внутренние | Для правил NAT и firewall |
| RFC1918 | 10/8, 172.16/12, 192.168/16, 100.64/10 | Приватные адреса для NAT |
| BOGONS | приватные + loopback + multicast + reserved | Для anti-spoofing |
| MGMT-SOURCES | admin workstation, laptop, VPN | Разрешённые источники управления |
| WAN-IPS | публичные IP обоих ISP | Для hairpin NAT |
| CHECK-HOSTS | 87.240.132.72, 95.143.182.1, 208.67.222.222, 9.9.9.9 | Check-hosts для failover |

### 9.2. Динамические списки (заполняются автоматически)

| Список | Timeout | Заполняется правилами |
|--------|---------|----------------------|
| SCANNER | 24h | Детекция сканирования в input-wan |
| BAD-ACTORS | 24h | Эскалация из SCANNER |
| PORT-SCAN | 24h | Превышение rate к веб-серверу |
| HTTP-ATTACKERS | 1h | conn-limit к веб-серверу |
| WG-FLOOD | 1h | Rate-limit на WireGuard |
| LAN-WINBOX-BAD | 24h | Попытки Winbox не из MGMT-SOURCES |
| BLACKLIST | - | Для ручного добавления или внешних скриптов |

---

## 10. Логирование

### 10.1. Настройки

```routeros
/system logging
add topics=critical
add topics=firewall
add topics=dhcp
add topics=wireless
add topics=critical action=disk
add topics=firewall action=disk
```

Critical и firewall пишутся и в memory, и на disk. Пригодится для post-mortem анализа.

### 10.2. Log prefixes в firewall

Все правила логирования используют характерные префиксы:
- `[FORWARD-DROP]` — невалидный forward-трафик
- `[DMZ->LAN-DROP]` — попытка DMZ пробить в LAN
- `[DMZ-MGMT-BLOCK]` — попытка DMZ управлять роутером
- `[SYN-FLOOD]` — SYN-flood detection
- `[WAN-IN-DROP]` — отброшенный входящий трафик из WAN

---

## 11. Scheduler

| Task | Интервал | Описание |
|------|----------|----------|
| sched-isp-health-monitor | 10s | Мониторинг ISP и failover |
| cleanup-address-lists | 1d | Очистка expired entries (хотя RouterOS делает это сам, для подстраховки) |
| sched-notify-* | разные | Все скрипты уведомлений |

---

## 12. Потенциальные улучшения

Что планирую добавить в будущем:

1. **Backup configuration** — регулярное(еженедельное) автоматическое сохранение конфига на email или внешний сервер
2. **Внешний syslog** — вынос логов на централизованный сервер
3. **GeoIP blocking** — блокировка стран, откуда не ожидается легитимный трафик
4. **IDS/IPS integration** — отправка трафика на Suricata/Snort для глубокого анализа - под вопросом.

---

## Заключение

Конфигурация обеспечивает:
- Надёжный failover между провайдерами с проверкой реальной доступности интернета
- Сегментацию сети (LAN/DMZ/VPN) с контролируемым доступом между сегментами
- Защиту от типовых атак на периметре
- Удалённое администрирование через WireGuard и доступ к внутренним ресурсам LAN/DMZ
- Оперативные уведомления о проблемах и инцидентах

