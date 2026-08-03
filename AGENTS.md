Rules for working in this repo: see [CLAUDE.md](CLAUDE.md).

The main one: a change is not finished until the docs in `docs/` describe the
repo correctly again. Every change is checked for which docs it touches and
ends with a clean `tools/gen-catalog.sh --check`. See the section "Main rule:
code and docs change together".

Docs are written for agents: English, dense, no tutorials. The format is
[docs/STYLE.md](docs/STYLE.md).
