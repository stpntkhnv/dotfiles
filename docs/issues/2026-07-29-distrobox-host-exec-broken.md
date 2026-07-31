# Сломано выполнение команд на хосте из контейнера

Найдено 29 июля 2026 при проверке hostового herdr. **Закрыто 30 июля 2026:**
маршрут ссылок переведён с `distrobox-host-exec` на UNIX-сокет. Сам
`distrobox-host-exec` по-прежнему не работает и работать не будет, но им больше
никто не пользуется.

## Симптом

Внутри `digi3`:

```sh
distrobox-host-exec echo hi
# rc=127, ни строчки вывода
host-spawn echo hi
# rc=127, ни строчки вывода
```

`/usr/bin/host-spawn` на месте (3.8 МБ, 28 июля), `/usr/bin/distrobox-host-exec`
тоже. То есть падает не отсутствие бинаря.

## Корень: две причины, обе обязательные

Догадка про session bus оказалась верной, но одной её не хватало.

### A. На хосте нет сервиса, которому звонит host-spawn

`host-spawn` вызывает `org.freedesktop.Flatpak.Development.HostCommand` — это
видно прямо в бинаре:

```sh
strings /usr/bin/host-spawn | grep -o 'org.freedesktop.Flatpak.Development.HostCommand'
strings /usr/bin/host-spawn | grep -o '/org/freedesktop/Flatpak/Development'
```

Имя даёт `flatpak-session-helper` из пакета `flatpak`. Пакета на хосте нет и в
каталоге фич он не появлялся никогда:

```sh
busctl --user call org.freedesktop.Flatpak \
  /org/freedesktop/Flatpak/Development \
  org.freedesktop.Flatpak.Development HostCommand
# Call failed: The name is not activatable
```

Поэтому 127 приходит на любую команду, включая `true`. Сам бинарь при этом
исправен: `host-spawn --version` печатает `v1.6.0` и выходит с нулём. Об отказе
он не сообщает ничего: пустой stdout, пустой stderr.

### B. Переменная шины показывает на контейнерную шину

`/usr/bin/distrobox-create:908`:

```sh
if [ -d "/run/user/${container_user_uid}" ] && [ "${init}" -eq 0 ]; then
    ... --volume /run/user/UID:/run/user/UID
```

Хостовый `XDG_RUNTIME_DIR` монтируется **только при `init=0`**, а в
`home/dot_config/distrobox/distrobox.ini.tmpl` стоит `init=true`. Проверено: в
`podman inspect digi3 --format '{{ .HostConfig.Binds }}'` хостового
`/run/user/1000` нет вовсе, внутри это свой tmpfs со своим systemd-юзером и
своим `dbus-broker`. Унаследованный `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus`
показывает на него.

Лечится переменной, но не помогает: с
`DBUS_SESSION_BUS_ADDRESS=unix:path=/run/host/run/user/1000/bus` контейнер видит
хостовую шину (имена перечисляются), а `host-spawn` всё равно 127 — из-за A.

**Это не регрессия.** Обёртка `xdg-open` из `37-container-links` не доезжала до
хоста ни одного раза с момента появления.

## Чем заменено

`38-linkrouting` поднимает на хосте по слушателю на контекст
(`zenopen-<контекст>.service`, тот же `socat` с `fork`, что у прокси) на сокете
`~/.local/share/wsproxy/<контекст>/links.sock`, который уже смонтирован в
контейнер как `/var/lib/wsproxy`. Обёртка пишет туда одну строку с URL,
`zen-open-recv` её проверяет и зовёт `zen-open`.

Разбор с замерами: [docs/features.md](../features.md#почему-ссылка-уходит-через-сокет-а-не-через-distrobox-host-exec).

## Как проверено, что починилось

Прогнано 30 июля 2026 на живых контейнерах, слушатели из отрендеренного
`38-linkrouting`:

```
digi3    -> ROUTED ctx=digi3    url=https://example.com/hello?from=digi3&n=1
stellium -> ROUTED ctx=stellium url=https://example.com/hello?from=stellium&n=1
personal -> ROUTED ctx=personal url=https://example.com/hello?from=personal&n=1
```

Настоящий запуск браузера, из журнала:

```
Started [systemd-run] /usr/bin/zen-browser "ext+container:name=digi3&url=https%3A%2F%2Fexample.com%2F"
```

Перехваченный argv браузера на URL с параметрами — `?` и `&` доехали
закодированными:

```
ext+container:name=digi3&url=https%3A%2F%2Fexample.com%2Fproof%3Fa%3D1%26b%3D2
```

Пути отказа, каждый с кодом 1 и одной строкой на stderr: пробел в URL
(`bad-url`), длиннее 2048 (`too-long`), не http(s) при записи в сокет в обход
обёртки (`bad-scheme`), остановленный слушатель (`no link socket`). Ни один из
них ничего на хост не пропустил. Аргумент не-URL по-прежнему проваливается в
настоящий `xdg-open` — проверено сравнением со старой обёрткой, поведение
идентичное.

## Что осталось незакрытым

`distrobox-host-exec` в контейнерах остаётся нерабочим. Если он когда-нибудь
понадобится для чего-то другого, нужны оба шага: пакет `flatpak` на хосте и
указание контейнеру на хостовую шину. Цена — `HostCommand` это выполнение
**любой** команды на хосте из любого контейнера, что шире всего, что этому
репозиторию нужно.
