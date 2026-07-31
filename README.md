# dotfiles

Arch Linux workstation configuration managed with [chezmoi](https://www.chezmoi.io/).
One-line install below; everything past this paragraph — the docs under
`docs/` — is written in Russian.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stpntkhnv/dotfiles/main/install.sh)"
```

## Установка

Команда выше ставит chezmoi (если его ещё нет), клонирует этот репозиторий,
показывает чеклист фич, ставит выбранное и раскладывает конфиги. Работает
одинаково что на голом хосте, что внутри контейнера distrobox — окружение
определяется само, по наличию `/run/.containerenv`.

Если CDN отдаёт устаревший `install.sh`, тот же файл можно взять напрямую
через API GitHub:

```sh
sh -c "$(curl -fsSL https://api.github.com/repos/stpntkhnv/dotfiles/contents/install.sh -H 'Accept: application/vnd.github.raw')"
```

Неинтерактивная установка, смена уже сделанного выбора и подводные камни
`chezmoi init --prompt` — в [`docs/install.md`](docs/install.md).

## Что попадает на машину

Без единого вопроса — потому что без этого машина не работает: базовые
утилиты и оболочка (`git`, `ssh`, starship, eza, bat, fzf, zoxide), на хосте —
рабочий стол niri + DankMaterialShell, сеть и firewall, а также distrobox с
podman; внутри контейнера — обвязка вроде locale-gen и xauth. Список того,
что ставится без вопросов, и почему это не переключить галочкой — в
[`docs/base.md`](docs/base.md), [`docs/desktop.md`](docs/desktop.md) и
[`docs/containers.md`](docs/containers.md).

Всё остальное — чеклист. `home/.chezmoidata.yaml` перечисляет 35 фич, у
каждой свои пакеты и `scope` (хост / контейнер / везде); при установке
чеклист можно поправить (пробел — переключить фичу, Enter — подтвердить), и
выбор сохраняется в `~/.config/chezmoi/chezmoi.toml`. Как каталог фич
устроен изнутри и что делать, если фичу нужно добавить или её выбор — уже не
тот, что нужен, — в [`docs/how-it-works.md`](docs/how-it-works.md).

## Документация

Дальнейшая документация — в [`docs/`](docs/), по-русски, один документ на
тему:

- [`docs/README.md`](docs/README.md) — карта всех документов: что где
  искать.
- [`docs/catalog.md`](docs/catalog.md) — сгенерированная таблица «фича →
  документ», перегенерируется, руками не редактируется.
- [`docs/glossary.md`](docs/glossary.md) — словарь терминов, от простого к
  сложному.
- [`docs/install.md`](docs/install.md) — установка на чистой машине шаг за
  шагом, включая неинтерактивный режим.
- [`docs/isolation.md`](docs/isolation.md) — зачем и как изолированы рабочие
  контексты в браузере: сеть, куки, контейнеры.
- [`docs/agents.md`](docs/agents.md) — Claude Code и Codex: как они
  раскладываются на машину и обновляются.
- [`docs/operations.md`](docs/operations.md) — какими командами проверить,
  что всё применилось как надо, и что делать, когда что-то сломалось.

## Каталог документации

`tools/gen-catalog.sh --check` прогоняет все проверки покрытия документации
(каждая фича и каждый файл из `home/` должны быть перечислены хотя бы в одном
документе), ничего не записывая. Без `--check` тот же скрипт перезаписывает
`docs/catalog.md`.
