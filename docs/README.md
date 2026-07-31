---
covers:
  features: []
  paths: []
---

# Карта документации

Один документ — одна тема. Список ниже сгруппирован по смыслу; внутри каждой
группы строка — ссылка на документ и одно предложение о том, что внутри.

Три входа в документацию, в зависимости от того, что уже известно:

- Знаешь имя фичи из `home/.chezmoidata.yaml` (например `zen` или `killswitch`)
  — иди в [`catalog.md`](catalog.md), это сгенерированная таблица «фича →
  документ».
- Не знаешь термин (`netns`, `space`, `pathspec`...) — ищи его в
  [`glossary.md`](glossary.md), там определения строятся друг на друге с нуля.
- Хочешь прочитать про уже расследованный баг или странность — загляни в
  [`issues/`](issues/), это журнал расследований с фактами и датами.

## Механика

- [`how-it-works.md`](how-it-works.md) — как устроен chezmoi в этом
  репозитории: единый источник правды в `.chezmoidata.yaml`, порядок скриптов
  и файлов при `apply`.
- [`install.md`](install.md) — установка на чистой машине одной командой, что
  спрашивает chezmoi и как поставить всё неинтерактивно.

## Изоляция

- [`isolation.md`](isolation.md) — зачем вообще нужна изоляция рабочих
  контекстов и как устроена общая картина моста между браузером и сетью.
- [`containers.md`](containers.md) — distrobox-контейнеры рабочих контекстов:
  из чего собираются и что в них живёт.
- [`isolation-network.md`](isolation-network.md) — мост через UNIX-сокет и
  `socat` между браузером на хосте и сетью внутри контейнера.
- [`isolation-browser.md`](isolation-browser.md) — расширения Zen,
  Multi-Account Containers и привязка space к прокси контейнера.
- [`isolation-links.md`](isolation-links.md) — маршрутизация внешних ссылок в
  правильный контейнер.
- [`killswitch.md`](killswitch.md) — что рубит сеть контейнера, если его VPN
  падает.

## Рабочее место

- [`base.md`](base.md) — базовые утилиты, оболочка, git, приглашение
  командной строки.
- [`desktop.md`](desktop.md) — niri, DankMaterialShell, обои рабочего стола.
- [`greeter.md`](greeter.md) — экран входа в систему: greetd и оболочка DMS
  вместо sddm.
- [`terminal.md`](terminal.md) — ghostty и alacritty, темы оформления.
- [`keyboard.md`](keyboard.md) — раскладка клавиатуры и её защита от
  `localectl`.
- [`multiplexer.md`](multiplexer.md) — herdr, tmux и скрипт `work` для
  переключения между рабочими контекстами.
- [`browsers.md`](browsers.md) — systemd-слайсы браузеров, ограничение
  памяти, ярлыки запуска.

## Голос

- [`voice.md`](voice.md) — голосовой ввод через Handy: горячие клавиши, запись
  и печать распознанного текста.

## Данные и сеть

- [`sync.md`](sync.md) — Syncthing и Obsidian, какие папки синхронизируются и
  между какими машинами.
- [`network.md`](network.md) — Tailscale, Ziti и firewall.
- [`secrets.md`](secrets.md) — Bitwarden и SSH-ключи.

## Инструменты

- [`dev-tools.md`](dev-tools.md) — neovim, VS Code, node, go, dotnet, rider,
  инструменты для баз данных и API, docker, azure, teams, gh.
- [`agents.md`](agents.md) — Claude Code и Codex, что раскладывается на
  машину для работы с ними.

## Железо

- [`hardware.md`](hardware.md) — принтеры, известный баг Bluetooth-донгла,
  настройки NVIDIA и zram.

## Эксплуатация

- [`workarounds.md`](workarounds.md) — реестр обходов чужих багов: чей баг,
  какое доказательство и как проверить, что он ещё жив.
- [`operations.md`](operations.md) — какими командами проверить, что всё
  применилось как надо, и что делать, когда что-то сломалось.
