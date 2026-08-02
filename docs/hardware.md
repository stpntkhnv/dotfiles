---
covers:
  features: [printing, bluetooth-fix, earlyoom]
  paths:
    - home/.chezmoiscripts/run_onchange_before_35-nvidia.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_50-bluetooth.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_30-system.sh.tmpl
---

# Железо: NVIDIA, zram, earlyoom, сервисы, печать и Bluetooth-донгл

## Что это даёт

Шесть разных, не связанных друг с другом вещей, которые тем не менее решает
один и тот же слой репозитория:

- **Карта NVIDIA** получает рабочий драйвер и Vulkan сама, без ручного
  `pacman -S nvidia...` и без гадания, какой именно пакет нужен этому
  железу. Спрашивается это один раз, при самой первой настройке машины.
- **Своп** (память на диске, куда сбрасывается то, что не поместилось в
  оперативную) живёт сжатым прямо в оперативной памяти (zram), а не на диске —
  быстрее и не изнашивает SSD.
- **Исчерпание памяти** перестаёт вешать машину намертво: сторож `earlyoom`
  при почти полном исчерпании и памяти, и свопа убивает самый прожорливый
  процесс — вместо бесконечного зависания, которое лечится только кнопкой
  питания.
- **Фоновые сервисы** (сеть, Bluetooth, файрвол, синхронизация времени,
  еженедельная чистка SSD) включаются сами при первой настройке, чтобы не
  держать в голове чеклист «что ещё нужно включить руками».
- **Сетевой принтер** становится видимым в списке принтеров — без этого он
  физически подключён, но программы его не находят.
- **Один конкретный дешёвый USB-адаптер Bluetooth** (`10d7:b012`) перестаёт
  пропадать через пару секунд после каждой загрузки — без фикса он в системе
  виден, но ни с одним устройством не соединяется.

Общее для первых трёх пунктов и печати: за них отвечают всего два скрипта,
`35-nvidia` и большая часть `30-system`. Но `30-system` — не только про это:
тот же файл первым делом настраивает клавиатуру
([keyboard.md](keyboard.md)) и файрвол ([network.md](network.md)), и это уже
не тема этого документа.

## Как это работает

```mermaid
flowchart TD
    subgraph INIT["chezmoi init, только хост"]
        PCI["/sys/bus/pci/devices/*/class + vendor<br/>(напрямую, не lspci)"]
        PCI -->|"класс 0x030*<br/>и vendor 0x10de не найден"| NOASK["Вопроса нет"]
        PCI -->|"карта есть,<br/>driver + Vulkan ICD уже стоят"| INFOMSG["Только сообщение"]
        PCI -->|"карта есть,<br/>чего-то из двух нет"| ASK["promptBoolOnce:<br/>ставить драйвер?<br/>(нужна перезагрузка)"]
        ASK --> TOML["data.nvidia_driver<br/>в chezmoi.toml —<br/>НЕ в data.enabled"]
    end

    TOML --> S35
    subgraph BEFORE["chezmoi apply, before-стадия, только хост"]
        S35["35-nvidia<br/>тело — только если nvidia_driver"] -->|"Vulkan ICD уже есть"| SKIP35["ничего не делает"]
        S35 -->|"иначе"| KCOUNT["pacman -Qq:<br/>сколько ядер и какое"]
        KCOUNT -->|"ровно одно,<br/>это linux"| NOPEN["nvidia-open<br/>(готовый модуль)"]
        KCOUNT -->|"иначе"| NDKMS["nvidia-open-dkms<br/>+ заголовки каждого ядра"]

        S30["30-system<br/>третья часть скрипта"] --> ZCONF["/etc/systemd/zram-generator.conf<br/>zram-size = ram / 2, zstd"]
        S30 --> SVC["enable_unit:<br/>sddm · NetworkManager · bluetooth ·<br/>ufw · timesyncd · fstrim.timer · earlyoom<br/>+ по фиче: cups.socket, tailscaled, docker.socket"]
        S30 --> PODSOCK["podman.socket — user-юнит,<br/>systemctl --user enable --now,<br/>мимо enable_unit (distrobox, always)"]
        SVC -->|"исключение 1"| TSNOW["tailscaled:<br/>ещё и явный systemctl start"]
        SVC -->|"исключение 2"| UFWNOW["ufw --force enable:<br/>действует сейчас, не после ребута"]
        SVC -.->|"фича printing"| CUPSNOTE["cups.socket +<br/>ufw allow mdns — network.md"]

        S50["50-bluetooth<br/>только если bluetooth-fix"] --> MP["/etc/modprobe.d/btusb.conf<br/>enable_autosuspend=0"]
        S50 --> UDEV["/etc/udev/rules.d/50-bt-dongle-nosuspend.rules<br/>10d7:b012, power/control=on"]
    end

    style ASK fill:#4a5568,color:#fff
    style TOML fill:#4a5568,color:#fff
    style TSNOW fill:#2b6cb0,color:#fff
    style UFWNOW fill:#2b6cb0,color:#fff
```

### NVIDIA: вопрос при `init`, а не фича каталога

В `home/.chezmoi.toml.tmpl` есть блок, помеченный комментарием «hardware-dependent
follow-up», который не входит в обычный чеклист фич
(`home/.chezmoidata.yaml`). У него другая механика:

```sh
{{- $hasNvidia := eq (output "sh" "-c" "for d in /sys/bus/pci/devices/*/; do c=$(cat \"$d/class\" 2>/dev/null); v=$(cat \"$d/vendor\" 2>/dev/null); case \"$c\" in 0x030*) [ \"$v\" = 0x10de ] && { echo yes; exit 0; };; esac; done; echo no" | trim) "yes" -}}
{{-   $gpuReady := eq (output "sh" "-c" "[ -e /dev/nvidiactl ] && [ -e /usr/share/vulkan/icd.d/nvidia_icd.json ] && echo yes || echo no" | trim) "yes" -}}
{{-   if and $hasNvidia (not $gpuReady) -}}
{{-     $nvidiaDriver = promptBoolOnce . "nvidia_driver" "Install the NVIDIA driver and Vulkan runtime (needs a reboot)" -}}
```

`0x030*` — класс устройства PCI «Display controller» (VGA-контроллер и его
разновидности), `0x10de` — идентификатор производителя NVIDIA. Комментарий над
блоком объясняет оба выбора буквально:

> Asked at init rather than mid-apply because installing a driver requires a
> reboot, and that has to be said up front. `/sys/bus/pci` is read directly
> because `lspci` lives in `pciutils`, which a minimal install may not have.

Живая проверка на этой машине (2026-07-31, только чтение):

```sh
$ for d in /sys/bus/pci/devices/*/; do c=$(cat "$d/class" 2>/dev/null); v=$(cat "$d/vendor" 2>/dev/null); [ "$c" = 0x030000 ] && [ "$v" = 0x10de ] && echo "$d"; done
/sys/bus/pci/devices/0000:06:00.0/
$ ls /dev/nvidiactl /usr/share/vulkan/icd.d/nvidia_icd.json
/dev/nvidiactl  /usr/share/vulkan/icd.d/nvidia_icd.json
$ pacman -Qi nvidia-open | head -2
Name            : nvidia-open
Version         : 610.43.03-9
```

На этой машине карта уже найдена и готова (`$gpuReady` = true), поэтому вопрос
не задаётся — только сообщение `NVIDIA GPU with a working Vulkan runtime
detected.`.

**Важно, где хранится ответ.** `nvidia_driver` — не элемент `data.enabled` (как
обычные фичи каталога), а отдельное поле `data.nvidia_driver`. Комментарий в
самом файле объясняет почему: «This is not a checklist feature because
whether it is wanted is a property of the machine, not a preference: the probe
answers it». Из этого следует нетривиальное свойство: в отличие от
`data.enabled`, которое `chezmoi init` без `--prompt` не трогает (см.
[install.md](install.md), «Как поменять выбор потом»), `nvidia_driver`
**пересчитывается заново при каждом `chezmoi init`**, а не хранится
неизменно. Переменная `$nvidiaDriver` в шаблоне всегда стартует с `false`;
`promptBoolOnce` вызывается — и может вернуть сохранённый ответ — только если
в момент этого конкретного рендера `$hasNvidia` истинно и `$gpuReady` ложно.
Как только драйвер и Vulkan ICD появились (после перезагрузки и первого
успешного прогона `35-nvidia`), следующий голый `chezmoi init` эту ветку не
войдёт вовсе, и `data.nvidia_driver` в перезаписанном `chezmoi.toml` тихо
станет `false` — не потому что кто-то передумал, а потому что поле не
«помнит» прошлый ответ, а каждый раз заново спрашивает железо. Практических
последствий это не несёт: `35-nvidia` и так не сделал бы ничего лишнего
(у него собственная проверка на файл ICD ниже), но это ключевое отличие от
устройства обычных фич каталога, о котором стоит знать, если когда-нибудь
понадобится читать это поле напрямую.

### `35-nvidia`: nvidia-open против nvidia-open-dkms

Скрипт входит в тело только если `.nvidia_driver` истинно
(`{{- if not .nvidia_driver }} exit 0 {{- else }}`), и первым делом
перепроверяет то же самое, что уже проверял `init`:

```sh
if [[ -e /usr/share/vulkan/icd.d/nvidia_icd.json ]]; then
    echo "==> NVIDIA Vulkan runtime already present, nothing to do."
    exit 0
fi
```

Комментарий объясняет пустое место в списке пакетов: «Note what is NOT here:
the `cuda` package. Nothing in this setup uses CUDA — both the desktop and
Whisper inside Handy reach the GPU through Vulkan». [voice.md](voice.md)
подтверждает то же самое с другой стороны: whisper.cpp внутри Handy на Linux
работает через Vulkan-бэкенд, не CUDA.

Выбор между `nvidia-open` и `nvidia-open-dkms`:

```sh
mapfile -t kernels < <(pacman -Qq 2>/dev/null | grep -xE 'linux|linux-lts|linux-zen|linux-hardened' || true)
if [[ ${#kernels[@]} -eq 1 && ${kernels[0]} == linux ]]; then
    pkgs+=(nvidia-open)
else
    pkgs+=(nvidia-open-dkms)
    for k in "${kernels[@]}"; do pkgs+=("${k}-headers"); done
fi
```

Признак простой: ровно один установленный пакет ядра, и это именно `linux`
(обычное, не LTS/zen/hardened) — тогда `nvidia-open`, чей собранный модуль
целится в стоковое ядро. Во всех остальных случаях (несколько ядер сразу,
либо единственное ядро — не `linux`) идёт `nvidia-open-dkms` плюс пакет
заголовков для каждого найденного ядра, чтобы DKMS было из чего собирать
модуль при каждом обновлении ядра. Живая проверка на этой машине (2026-07-31):

```sh
$ pacman -Qq | grep -xE 'linux|linux-lts|linux-zen|linux-hardened'
linux
$ pacman -Qi nvidia-open | head -1
Name            : nvidia-open
$ pacman -Qi nvidia-open-dkms 2>&1
error: package 'nvidia-open-dkms' was not found
```

Ровно один пакет ядра, и это `linux` — ветка `nvidia-open` сработала,
подтверждено фактическим составом пакетов на машине.

### zram: размер `ram / 2` и явный zstd

```sh
ZRAM_CONF=/etc/systemd/zram-generator.conf
if [[ ! -f "$ZRAM_CONF" ]] || ! grep -q 'zram-size = ram / 2' "$ZRAM_CONF"; then
    sudo tee "$ZRAM_CONF" >/dev/null <<'ZRAM'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM
fi
```

Размер задан явно, потому что умолчание самого `zram-generator` (по
`zram-generator.conf(5)`, опция `zram-size=` — «Defaults to
`min(ram / 2, 4096)`» мегабайт) на машине с 31 ГиБ оперативной памяти давало
устройство в 4 ГиБ, и этого дважды не хватило под реальную нагрузку — сессии
агентов, контейнеры и браузеры одновременно. Первый раз машина зависла
намертво 30 июля 2026 (разбор:
[issues/2026-07-30-desktop-hang-out-of-memory.md](issues/2026-07-30-desktop-hang-out-of-memory.md)
— OOM-killer не сработал ни разу, ядро бесконечно перекладывало страницы,
помогла только кнопка питания). Второй раз, 2 августа 2026, своп снова
заполнился до отказа: система ушла в реклейм-трэшинг (45-83% времени
процессора в ядре, чтение с диска ~2,3 ГБ/с — вытесненные страницы кода
читались обратно сразу после вытеснения), а браузер, зажатый потолком
`browser.slice` ([browsers.md](browsers.md)), перестал отвечать, потому что
при полном свопе его cgroup мог освобождать память только выбрасыванием
страниц собственного кода. `ram / 2` — те самые 12-16 ГиБ, которые предлагал
разбор первой аварии.

Из четырёх мер того разбора (разрешить `kernel.sysrq`, поставить `earlyoom`
фичей каталога, поднять zram до 12-16 ГиБ, завести `agents.slice` по образцу
`browser.slice`) в репозитории теперь три: размер zram, `earlyoom`
(следующий раздел) и бюджет памяти для агентов и контейнеров — реализованный
не отдельным `agents.slice`, а потолком на `user.slice` пользовательского
менеджера, где podman и так держит все контейнеры (почему именно так —
[agents.md](agents.md), раздел про бюджет памяти). Не реализован только
`kernel.sysrq`.

Конфиг действует со следующей загрузки: `zram-generator` создаёт устройство
при старте системы, а уже созданное `chezmoi apply` не трогает. Применить
вживую можно, освободив устройство руками — `swapoff /dev/zram0 && systemctl
restart systemd-zram-setup@zram0` (об этом же говорит комментарий в конце
блока zram в самом скрипте).

### earlyoom: убить один процесс вместо зависания всей машины

Фича `earlyoom` (`scope: host`, `always: true`) ставит одноимённый пакет, а
`30-system` включает `earlyoom.service` через общий `enable_unit`. Настройки
пакета не трогаются: демон с умолчаниями срабатывает, когда **одновременно**
доступная память и свободный своп падают ниже 10%, и убивает процесс с
наибольшим потреблением памяти. Это последний рубеж: система теряет один
процесс, но остаётся живой — вместо июльского сценария, где ядро бесконечно
перекладывало страницы и помогла только кнопка питания.

Границу применимости важно понимать: earlyoom смотрит на `MemAvailable` всей
системы. Трэшинг 2 августа 2026 (см. раздел про zram выше) он не поймал бы и
не должен был — своп тогда был в нуле, но доступной памяти ядро показывало
ещё ~15 ГиБ кэша, и глобального исчерпания не было. От того сценария
защищает больший zram; earlyoom — от сценария 30 июля, когда кончается всё.

На этой машине пакет и юнит появились руками 30 июля 2026 около 18:53 — по
времени сразу после той аварии — и до 2 августа жили мимо репозитория:
переустановку машины такой сторож не пережил бы. Фича каталога закрывает
ровно этот зазор.

### Сервисы: полный список и два отступления от «без `--now`»

```sh
enable_unit() {
    if ! systemctl is-enabled --quiet "$unit" 2>/dev/null; then
        sudo systemctl enable "$unit"
    fi
}
```

Комментарий над функцией объясняет общее правило: «enable without `--now`:
there is no reason to bounce sddm in the middle of a running session,
everything comes up on the next boot». Полный список того, что проходит через
`enable_unit`:

- всегда: `sddm.service` (только если `display-manager.service` ещё ничем не
  занят — иначе занял `greetd`, см. ниже), `NetworkManager.service`,
  `bluetooth.service`, `ufw.service`, `systemd-timesyncd.service`,
  `fstrim.timer`, `earlyoom.service`;
- по фиче `printing`: `cups.socket`;
- по фиче `tailscale` (`always: true`, см. [network.md](network.md)):
  `tailscaled.service`;
- по фиче `docker`: `docker.socket`.

Мимо `enable_unit` — и мимо `sudo` — идёт ещё один сокет: `podman.socket`,
user-юнит rootless podman (ветка `{{- if has "distrobox" .enabled }}`, на
хосте — фактически безусловно). Он включается сразу с `--now`: сокет
обслуживает уже работающие контейнеры (.NET Aspire создаёт через него
контейнеры podman'ом хоста), и ждать перезагрузки ему незачем. Сам канал
контейнер→podman хоста описан в [containers.md](containers.md), раздел
«Podman хоста из контейнера».

Из всей группы `enable_unit` **ровно два** пункта не ждут следующей
перезагрузки:

1. **`tailscaled.service`** получает не только `enable`, но и явный
   `systemctl start`, если ещё не `active`. Причина — прямая зависимость по
   данным, а не по коду: следующий шаг установки, ручной `sudo tailscale up`,
   не может авторизоваться без уже работающего демона (разобрано подробно в
   [network.md](network.md), раздел «Tailscale: безусловно»).
2. **`ufw`** включается не через `enable_unit`, а собственной командой:
   `sudo ufw --force enable` — она меняет действующие правила ядра
   немедленно, а не только юнит для следующей загрузки (подробности и
   идемпотентность — тоже в [network.md](network.md)).

Комментарий отдельно объясняет, почему `set -e` в начале скрипта не рискует
уронить весь `apply` на первом же `enable_unit`: «Every unit below is backed
by a package in the catalogue — `systemctl enable` on a missing unit fails».
Действительно, все семь безусловных юнитов приходят пакетами из каталога
или напрямую из `base`: `NetworkManager.service`/`bluetooth.service`/
`ufw.service`/`sddm.service`/`earlyoom.service` — из фич
`host-base`/`desktop`/`earlyoom`, а
`systemd-timesyncd.service` (пакет `systemd`) и `fstrim.timer` (пакет
`util-linux`) в каталоге вообще не упомянуты — оба входят транзитивно вместе
с метапакетом `base`, тем же путём, что и `kbd` в [keyboard.md](keyboard.md)
(проверено на этой машине: `pacman -Qi base` перечисляет и `systemd`, и
`util-linux` прямо в `Depends On`).

**Отдельно про `sddm`.** Строка `systemctl is-enabled --quiet
display-manager.service || enable_unit sddm.service` не включает `sddm`
безусловно — только если ничто ещё не держит алиас `display-manager.service`.
На этой машине греетер уже переключён на `greetd` ([greeter.md](greeter.md)),
и живая проверка (2026-07-31, см. также [keyboard.md](keyboard.md)) это
подтверждает:

```sh
$ systemctl is-enabled greetd.service sddm.service
enabled
disabled
```

### Печать: сокет-активация CUPS

Фича `printing` (`scope: host`, `default: true`) ставит три пакета —
`cups`, `cups-pk-helper`, `system-config-printer`. Комментарий в каталоге
объясняет, зачем здесь `cups-pk-helper`, хотя это не сам демон печати: «это
также то, что позволяет DankMaterialShell управлять принтерами из
собственного интерфейса, поэтому пакет здесь, а не в фиче рабочего стола».

Сама активация в `30-system`:

```sh
{{- if has "printing" .enabled }}
enable_unit cups.socket
```

`cups.socket` — сокет-активация: systemd слушает Unix-сокет CUPS и запускает
демон `cups.service` только при первом реальном обращении, а не держит его в
памяти вхолостую. Проверено вживую 2026-07-31:

```sh
$ systemctl status cups.socket --no-pager | head -6
● cups.socket - CUPS Scheduler
     Loaded: loaded (/usr/lib/systemd/system/cups.socket; enabled; preset: disabled)
     Active: active (running)
   Triggers: ● cups.service
     Listen: /run/cups/cups.sock (Stream)
```

Следом идёт открытие mDNS в `ufw`, без которого сетевой принтер физически
подключён, но не появляется в списке — это уже собственность
[network.md](network.md) (раздел «Файрвол: закрыто снаружи, открыто изнутри»,
включая находку, что `ufw allow mdns` открывает не только udp, как говорит
соседний комментарий, но и tcp/5353 тоже), здесь не повторяется.

### Bluetooth: лечение донгла `10d7:b012`

Фича `bluetooth-fix` (`scope: host`, без `default` — включается вручную) не
ставит ни одного пакета — только два конфига. Комментарий в начале скрипта
описывает симптом и диагноз буквально:

> Cheap USB Bluetooth dongles do not survive USB runtime autosuspend. On this
> host (`10d7:b012` "Actions general adapter") `btusb` suspends the device 2s
> after `hci0` registers — i.e. in the middle of HCI initialisation — and it
> never answers again. The kernel logs `Bluetooth: hci0: Opcode 0x1004
> failed: -110`.

Опкод `0x1004` (OGF 4, OCF 4) в спецификации HCI — команда «Read Local
Extended Features», один из первых запросов при инициализации контроллера;
код `-110` — это `ETIMEDOUT`. То есть контроллер перестаёт отвечать
буквально посреди штатного диалога инициализации, а не до и не после него.

Лечение двойное:

```sh
sudo tee "$MODPROBE_CONF" >/dev/null <<'EOF'
options btusb enable_autosuspend=0
EOF

sudo tee "$UDEV_RULE" >/dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="10d7", ATTR{idProduct}=="b012", TEST=="power/control", ATTR{power/control}="on"
EOF
sudo udevadm control --reload
```

Первое — параметр модуля `btusb`, второе — правило udev, которое подкладывает
`power/control=on` конкретно этому устройству на случай, если что-то другое
включит автоусыпление обратно уже после того, как `btusb` привязался к
устройству. Оба — задокументированные, штатные механизмы ядра, а не патч
самого драйвера: `modinfo btusb` на этой машине подтверждает существование и
смысл параметра —

```sh
$ modinfo btusb | grep autosuspend
parm:           enable_autosuspend:Enable USB autosuspend by default (bool)
```

— то есть репозиторий не обходит баг `btusb`, а использует его собственную,
предусмотренную ручку. Что здесь всё же является обходом чужого поведения —
сама необходимость трогать эту ручку из-за конкретно этого дешёвого чипа —
разобрано в [реестре обходов](workarounds.md).

Действует со следующей загрузки; скрипт печатает готовую команду, чтобы
применить прямо сейчас без перезагрузки:

```sh
sudo systemctl stop bluetooth && sudo modprobe -r btusb && sudo modprobe btusb && sudo systemctl start bluetooth
```

Эта команда не выполнялась в рамках этой задачи — она трогает загруженные
модули ядра и сам донгл, что здесь под запретом; поведение проверено только
чтением кода и текущего состояния уже исправленной машины ниже.

## Что ставится и что меняется

| Что | Где | Когда |
|---|---|---|
| Пакеты `nvidia-utils`, `libva-nvidia-driver`, `vulkan-icd-loader` + (`nvidia-open` или `nvidia-open-dkms` и заголовки ядер) | хост, pacman | `35-nvidia`, только если `data.nvidia_driver = true` и ICD ещё нет |
| `data.nvidia_driver` | `~/.config/chezmoi/chezmoi.toml`, поле `[data]` | пересчитывается на каждом `chezmoi init` по живому состоянию железа, не хранится как обычная фича |
| `/etc/systemd/zram-generator.conf` | вне дома | `30-system`, если строки `zram-size = ram / 2` ещё нет |
| Устройство `/dev/zram0`, `ram / 2` — 15,6 ГиБ на этой машине | ядро, через `zram-generator` | создаётся при загрузке из конфига выше, chezmoi его не трогает напрямую |
| Пакет `earlyoom` | хост, pacman | фича `earlyoom`, `always: true` |
| Юниты `sddm.service`\*, `NetworkManager.service`, `bluetooth.service`, `ufw.service`, `systemd-timesyncd.service`, `fstrim.timer`, `earlyoom.service` | системные | `30-system`: `enable`, без `--now`, при каждом прогоне |
| Юнит `cups.socket` | системный | `30-system`, если выбрана `printing`: `enable`, без `--now` |
| Юнит `tailscaled.service` | системный | `30-system`, всегда (`tailscale` — `always: true`): `enable` + явный `start` |
| Юнит `docker.socket` | системный | `30-system`, если выбрана `docker`: `enable`, без `--now`; сама фича описана в [dev-tools.md](dev-tools.md) |
| Юнит `podman.socket` | пользовательский (`systemctl --user`) | `30-system`, ветка `distrobox` (`always: true` — на хосте всегда): `enable --now`; канал к контейнерам описан в [containers.md](containers.md) |
| Политика `ufw`: `deny incoming`, `allow outgoing`, `--force enable` | хост | `30-system`, один раз — действует немедленно, не после ребута |
| Пакеты `cups`, `cups-pk-helper`, `system-config-printer` | хост, pacman | фича `printing`, `default: true` |
| `/etc/modprobe.d/btusb.conf` | вне дома | `50-bluetooth`, только если выбрана `bluetooth-fix` |
| `/etc/udev/rules.d/50-bt-dongle-nosuspend.rules` | вне дома | там же |

\* `sddm.service` включается условно — только если ничто ещё не держит
`display-manager.service` (см. «Сервисы» выше и [greeter.md](greeter.md)).

Тот же скрипт `30-system` первой третью настраивает раскладку клавиатуры
([keyboard.md](keyboard.md)) и последней третью — файрвол `ufw` и туннели
([network.md](network.md)); в этой таблице — только его средняя часть
(zram, сервисы) плюс печать и Bluetooth из соседних скриптов.

## Как проверить

Все команды ниже только читают состояние. Сняты на этой машине 2026-07-31.

NVIDIA:

```sh
$ pacman -Qi nvidia-open | head -2
Name            : nvidia-open
Version         : 610.43.03-9
$ ls /dev/nvidiactl /usr/share/vulkan/icd.d/nvidia_icd.json
/dev/nvidiactl  /usr/share/vulkan/icd.d/nvidia_icd.json
```

zram (этот блок снят позже остальных, 2026-08-02, сразу после поднятия
размера до `ram / 2`):

```sh
$ cat /etc/systemd/zram-generator.conf
# Managed by chezmoi -- .chezmoiscripts/run_onchange_before_30-system.sh
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
$ zramctl
NAME       ALGORITHM DISKSIZE DATA COMPR TOTAL STREAMS MOUNTPOINT
/dev/zram0 zstd         15.6G   4K   64B   20K         [SWAP]
$ cat /proc/swaps
Filename                                Type            Size            Used            Priority
/dev/zram0                              partition       16388604        0               100
```

Сервисы:

```sh
$ systemctl is-enabled NetworkManager.service bluetooth.service ufw.service \
    systemd-timesyncd.service fstrim.timer cups.socket docker.socket tailscaled.service
enabled
enabled
enabled
enabled
enabled
enabled
enabled
enabled
$ systemctl is-active tailscaled.service
active
$ systemctl --user is-enabled podman.socket
enabled
$ ls /run/user/1000/podman/podman.sock
/run/user/1000/podman/podman.sock
```

earlyoom (блок снят 2026-08-02, в день оформления фичи; демон на машине
работал с 30 июля):

```sh
$ systemctl is-enabled earlyoom.service && systemctl is-active earlyoom.service
enabled
active
```

Печать:

```sh
$ systemctl status cups.socket --no-pager | head -5
● cups.socket - CUPS Scheduler
     Loaded: loaded (/usr/lib/systemd/system/cups.socket; enabled; preset: disabled)
     Active: active (running)
   Triggers: ● cups.service
     Listen: /run/cups/cups.sock (Stream)
```

Bluetooth-донгл (машина, где фикс уже применён — донгл сейчас является
основным контроллером и работает):

```sh
$ cat /etc/modprobe.d/btusb.conf
options btusb enable_autosuspend=0
$ cat /etc/udev/rules.d/50-bt-dongle-nosuspend.rules
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="10d7", ATTR{idProduct}=="b012", TEST=="power/control", ATTR{power/control}="on"
$ cat /sys/class/bluetooth/hci0/device/uevent | grep PRODUCT
PRODUCT=10d7/b012/8891
$ bluetoothctl list
Controller F4:4E:FC:51:C5:AA tsikhanau-pc [default]
```

`hci0` на этой машине — именно этот донгл (`PRODUCT=10d7/b012/...`), и он
успешно зарегистрирован как контроллер по умолчанию — фикс действует.

## Когда сломалось

| Симптом | Причина | Что делать |
|---|---|---|
| При установке не спросило про драйвер NVIDIA, хотя карта есть | Вопрос задаётся, только если `/dev/nvidiactl` **и** Vulkan ICD ещё не оба на месте — если что-то из этого уже стоит (например, драйвер ставили руками раньше), вопроса не будет | `ls /dev/nvidiactl /usr/share/vulkan/icd.d/nvidia_icd.json` — если оба уже есть, драйвер и не нужен |
| `35-nvidia` ничего не поставил, хотя ответили «да» | Вулкан ICD уже был на диске в момент прогона — скрипт видит готовый файл и молча выходит | `ls /usr/share/vulkan/icd.d/nvidia_icd.json`; если он есть, всё уже поставлено |
| DKMS-сборка `nvidia-open-dkms` падает на нестандартном ядре | Скрипт узнаёт только четыре имени пакета ядра (`linux`, `linux-lts`, `linux-zen`, `linux-hardened`); ядро с другим именем (например, из AUR) не попадёт в список, и заголовки для него не будут добавлены в `pkgs` вовсе | Поставить `<имя-ядра>-headers` руками: `sudo pacman -S <ядро>-headers` |
| Один из юнитов не включился, `apply` упал на `30-system` | Пакет, дающий этот юнит, ещё не установлен (например, `docker` выбрали, но фича не успела поставить пакет из-за сетевого сбоя на `20-packages`) | Проверить `systemctl status <юнит>`; при отсутствии юнита — `pacman -Qo` на его файл, переустановить пакет, повторить `chezmoi apply` |
| Сетевой принтер не виден | Правило `mdns` не открыто в `ufw`, либо принтер сетевой, а не USB | Разобрано в [network.md](network.md#когда-сломалось) |
| Bluetooth: «no adapters found», хотя донгл виден в системе | `enable_autosuspend=0` ещё не применился (машина не перезагружалась после `chezmoi apply` с этой фичой) | `cat /etc/modprobe.d/btusb.conf` — если строка уже там, но не подействовала: `sudo systemctl stop bluetooth && sudo modprobe -r btusb && sudo modprobe btusb && sudo systemctl start bluetooth` (команда из вывода самого скрипта) |
| Тот же симптом на другом донгле (не `10d7:b012`) | Правило udev жёстко привязано к `idVendor`/`idProduct` этого конкретного устройства и на другой донгл не сработает | Добавить отдельное правило udev для нового `idVendor:idProduct`, по образцу существующего |
| Рабочий стол виснет намертво при нехватке памяти (не тормозит — не отвечает совсем), помогает только перезагрузка кнопкой | earlyoom срабатывает лишь когда почти кончились **и** доступная память, **и** своп (по 10%); трэшинг при формально свободном кэше или давка одного cgroup в собственном потолке (случай 2 августа, раздел про zram) под это не подпадают. Разбор первого случая: [issues/2026-07-30-desktop-hang-out-of-memory.md](issues/2026-07-30-desktop-hang-out-of-memory.md) | `systemctl status earlyoom` — работает ли сторож вообще; из мер разбора сделаны zram `ram / 2`, `earlyoom` и бюджет агентов/контейнеров на `user.slice` ([agents.md](agents.md)), а разрешённый `kernel.sysrq` — всё ещё нет |

## Почему именно так

### `/sys/bus/pci` вместо `lspci` — обоснование не подтвердилось для этой машины

Комментарий в `home/.chezmoi.toml.tmpl` называет причину: «`lspci` lives in
`pciutils`, which a minimal install may not have». Проверка по факту, на этой
же машине (2026-07-31):

```sh
$ pacman -Qi pciutils | grep -E 'Required By|Install Reason'
Required By     : base  chromium
Install Reason  : Installed as a dependency for another package
$ pacman -Qi base | grep 'Depends On'
Depends On      : filesystem  gcc-libs  glibc  bash  coreutils  file  findutils  gawk  grep  procps-ng  sed  tar  gettext  pciutils  psmisc  shadow  util-linux  bzip2  gzip  xz  licenses  pacman  archlinux-keyring  systemd  systemd-sysvcompat  iputils  iproute2
```

`pciutils` — прямая, обязательная зависимость самого метапакета `base`
(подтверждено и страницей пакета, [archlinux.org/packages/core/any/base](https://archlinux.org/packages/core/any/base/)).
Эта же машина ставилась именно через `base`
(`/var/log/pacman.log`: `pacman -Sy --noconfirm --needed ... base sudo
linux-firmware mkinitcpio linux amd-ucode`) — значит `lspci` был гарантированно
доступен уже на этапе `chezmoi init`, и обоснование «минимальная установка
может не иметь `lspci`» для машины, поставленной штатным способом из
[install.md](install.md), не подтверждается. Это не значит, что сам приём
плох: чтение `/sys/bus/pci` напрямую работает без единой внешней зависимости
и ничем не хуже `lspci` для этой узкой задачи (определить наличие и вендора
одной карты), но конкретная причина в комментарии проверке не прошла для
штатного пути установки этого репозитория. Отдельная строка про это — в
[реестре обходов](workarounds.md).

### `--now` — только там, где без него следующий шаг не может сработать

Общее правило («никого не перезапускать посреди сессии, всё доедет до
перезагрузки») ломается ровно там, где следующий шаг чеклиста физически не
может обойтись без работающего сервиса прямо сейчас (`tailscaled`, чтобы
`tailscale up` было к чему подключаться) или где сама программа не разделяет
«включено» и «действует» (`ufw enable` — это не юнит, который можно
отложить, а команда, которая меняет таблицы ядра тут же). У всех остальных
юнитов такой немедленной зависимости нет.

### zram: почему `ram / 2`, а не умолчание и не вся память

Умолчание генератора (`min(ram/2, 4096)` МБ,
[zram-generator.conf(5)](https://man.archlinux.org/man/zram-generator.conf.5))
— разумный размер для холостой машины, но рабочий режим этой машины —
несколько сессий агентов, контейнеры distrobox, SQL Server и браузеры
одновременно — дважды съедал эти 4 ГиБ до дна, см. хронику в разделе «zram»
выше. Верхняя граница тоже выбрана не случайно: `zram-size = ram` формально
допустим, но своп такого размера, заполненный плохо сжимаемыми данными,
сам съест значительную часть оперативной памяти (zram хранит сжатые страницы
в ней же). `ram / 2` — середина: втрое больше запаса, чем было, и при этом
даже полностью забитое устройство при обычном для zstd сжатии ~3:1 занимает
порядка 5 ГиБ реальной памяти.

Строка `compression-algorithm = zstd` — страховка, а не действующая
настройка: ядро этой машины само собрано с `zstd` как умолчанием, так что
сегодня строка ничего не меняет — она фиксирует выбор на случай, если
умолчание ядра однажды уедет:

```
$ zcat /proc/config.gz | grep CONFIG_ZRAM_DEF_COMP=
CONFIG_ZRAM_DEF_COMP="zstd"
```

Если эта команда однажды покажет не `zstd`, строка снова начнёт что-то
менять — довод «zstd жмёт заметно лучше `lzo-rle`, а цена процессора рядом
со свопом на диск не имеет значения» вернётся в силу.

## Ссылки

- [`zram-generator.conf(5)`, man.archlinux.org](https://man.archlinux.org/man/zram-generator.conf.5) —
  синтаксис конфига, формула размера по умолчанию.
- [`archlinux.org/packages/core/any/base`](https://archlinux.org/packages/core/any/base/) —
  зависимости метапакета `base`, включая `pciutils`, `systemd`, `util-linux`.
- `modinfo btusb` (локальная команда, не веб-ссылка) — параметр
  `enable_autosuspend`, официальное описание модуля.
- [Bluetooth: Fix issue with Actions Semi ATS2851 based devices, linux-bluetooth](https://www.spinics.net/lists/linux-bluetooth/msg102121.html) —
  патч апстрима для этого же устройства (`10d7:b012`), другая проблема
  (ошибочно заявленная поддержка erroneous data reporting), но подтверждает,
  что модель известна разработчикам ядра.
- [Bluetooth: btusb: Make the CSR clone chip force-suspend workaround more generic, linux-bluetooth](https://yhbt.net/lore/all/906e95ce-b0e5-239e-f544-f34d8424c8da@gmail.com/) —
  прецедент того же класса бага (автоусыпление рвёт инициализацию HCI) на
  другом дешёвом чипе, тот же класс проблемы, не то же устройство.
- [Bug #2056800, Ubuntu launchpad](https://bugs.launchpad.net/bugs/2056800),
  [Arch Linux Forums #280693](https://bbs.archlinux.org/viewtopic.php?id=280693),
  [damentz/liquorix-package#120](https://github.com/damentz/liquorix-package/issues/120) —
  независимые отчёты про этот же `10d7:b012` (UGREEN CM591 / ATS2851) с
  другими опкодами ошибок (`0x204b`, `0xc5a`), не автоусыплением — картина
  устройства с историей разных проблем на Linux, а не одной.
- [`torvalds/linux`, `drivers/bluetooth/btusb.c`](https://github.com/torvalds/linux/blob/master/drivers/bluetooth/btusb.c) —
  запись `USB_DEVICE(0x10d7, 0xb012)` с квирком `BTUSB_ACTIONS_SEMI` (не
  связан с автоусыплением) и функция `btusb_setup_csr` (детектор поддельных
  CSR-чипов, не относится к этому устройству).
- [workarounds.md](workarounds.md) — обходы: чтение `/sys/bus/pci` вместо
  `lspci`, лечение донгла `10d7:b012`.
- [keyboard.md](keyboard.md) — первая треть скрипта `30-system` (клавиатура)
  и приём проверки состояния перед `sudo`.
- [network.md](network.md) — последняя треть того же скрипта (firewall,
  Tailscale, Ziti), включая полный разбор `ufw allow mdns`.
- [greeter.md](greeter.md) — почему `sddm.service` включается условно.
- [install.md](install.md) — установка самого репозитория на машину, где
  система Arch уже есть. Про установку самой системы (`pacstrap`, метапакет
  `base`, откуда берётся `pciutils`) там не написано ничего: доказательство
  про `base` на этой машине — `/var/log/pacman.log`, а не этот документ.
- [issues/2026-07-30-desktop-hang-out-of-memory.md](issues/2026-07-30-desktop-hang-out-of-memory.md) —
  разбор аварии: машина зависла от нехватки памяти, OOM-killer не сработал ни
  разу, своп в 4 ГиБ по умолчанию не был проверкой на реальный рабочий режим.
  После повторения 2 августа 2026 размер поднят до `ram / 2`, а `earlyoom`
  оформлен фичей каталога — см. разделы про zram и earlyoom выше.
- [browsers.md](browsers.md) — `browser.slice`, образец двухступенчатого
  потолка памяти; для агентов и контейнеров тот же приём реализован бюджетом
  на `user.slice` ([agents.md](agents.md)).
