# Project Ampere

> Three always-on game servers — **Factorio (Space Age)**, a modded **NeoForge Minecraft**,
> and **Satisfactory** — running concurrently on a single **ARM64 Oracle Cloud (Ampere A1)**
> instance, including the games that were only ever shipped as **x86_64** binaries.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Why this exists

Oracle's free-tier Ampere A1 (ARM) instances are absurd value for hosting game
servers _if_ your games run on ARM64. Factorio and Minecraft compile/run natively on
ARM, but a lot of gaming software — *cough* Satisfactory *cough* — only ships x86_64
binaries. This repo is the answer: an operator toolkit that runs all three headless
servers on one machine, uses [FEX-Emu](docs/fex-emu-on-arm64.md) to translate
x86_64→ARM64 for the binaries that need it, keeps everything alive with Bash +
`screen` + Docker Compose, and wires the whole thing into Discord.

## The interesting parts

| | |
| --- | --- |
| **ARM64 translation** | FEX-Emu built from source (clang/LLVM/LLD + `binfmt_misc`) so x86_64-only Satisfactory/SteamCMD runs transparently on ARM64. → [`docs/fex-emu-on-arm64.md`](docs/fex-emu-on-arm64.md) |
| **Lifecycle automation** | `screen` supervisors with ghost-process cleanup & auto-restart; idempotent host bootstrap; containers restart automatically. → [`docs/architecture.md`](docs/architecture.md) |
| **Safe updates** | Factorio updates back up saves+mods+config **before** downloading/deploying a new headless build. |
| **Discord integration** | Bidirectional chat, player presence, deaths, **research notifications**, moderation alerts, admin commands, and a custom in-save scenario script. → [`docs/discord-integrations.md`](docs/discord-integrations.md) |

## Repository layout

```
├── README.md                    ← you are here
├── LICENSE                      ← MIT
├── docs/
│   ├── architecture.md          ← topology, ports, storage, supervision
│   ├── fex-emu-on-arm64.md      ← the ARM64 translation story
│   └── discord-integrations.md  ← chat bridges + custom scenario
├── scripts/
│   ├── bootstrap.sh             ← provision an Ubuntu host for this repo
│   └── validate_configs.py      ← CI + local config template checks
├── .github/workflows/validate.yml
├── factorio-server/
│   ├── run.sh                   ← FactoCord3 supervisor loop (auto-restart)
│   ├── update_factorio.sh       ← backup → download → restore → restart
│   ├── scenario/control.lua     ← custom event → Discord scenario
│   └── config/*.example.json    ← FactoCord3 / server-settings / mods templates
├── minecraft-server/
│   ├── run.sh                   ← screen-managed NeoForge launch
│   ├── user_jvm_args.txt        ← 16 GB tuned heap
│   ├── server.properties        ← MOTD, PvP-off, command blocks
│   └── config/                  ← ~45 mods tuned + Simple Discord Link template
└── satisfactory-server/
    ├── Dockerfile               ← FEX build + SteamCMD image
    ├── docker-compose.yml       ← ports 7777/8888, volumes, unless-stopped
    ├── init-server.sh           ← SteamCMD install/validate + launch
    └── *.sh                     ← build/run/interactive wrappers
```

Game installs, worlds, saves and caches are **gitignored** (re-downloadable /
generated); the commits contain only the engineering.

## The servers, quickly

| | Factorio | Minecraft | Satisfactory |
| --- | --- | --- | --- |
| **Version** | Space Age (2.x) | NeoForge 1.21.1 | latest dedicated server |
| **How it runs** | native through FactoCord3 (x86_64 bin) | JVM (x86_64) on ARM64 | Docker + FEX-Emu |
| **Supervision** | `screen` + auto-restart loop | `screen` | Compose `unless-stopped` |
| **Ports** | 34197/udp, 34198/tcp | 25565/tcp | 7777, 8888 (udp+tcp) |
| **Discord** | FactoCord3 + custom scenario | Simple Discord Link | — |
| **Persistence** | `saves/`, `backups/` | `world/` | `config/` volume |

## Day-to-day operations

```bash
# Satisfactory
cd satisfactory-server && sh build.sh && sudo docker compose up -d
docker compose logs -f      # watch live
sudo docker exec -it satisfactory-server bash   # interactive shell

# Factorio (via FactoCord3, which auto-restarts on crash)
cd factorio-server && sh run.sh
sh update_factorio.sh       # safe update: backs up saves/mods/config first

# Minecraft
cd minecraft-server && ./run.sh   # re-execs into `screen -r minecraft`
```

## Getting started

1. Provision a free-tier Ampere A1 instance, then on the box:
   ```bash
   sudo scripts/bootstrap.sh          # docker, compose, screen + Security-List guidance
   ```
2. Clone this repo to `/home/ubuntu/servers`.
3. For each server, copy the `*.example.*` config to its real location and fill
   in **your** tokens/webhooks/passwords. Run `python3 scripts/validate_configs.py`
   to check the templates.
4. Open the ports from [`docs/architecture.md`](docs/architecture.md#network) in the
   Oracle Cloud **Security List**.

## Security notes

Real configs are **gitignored** — they contain live Discord tokens, webhooks, channel
IDs, and RCON credentials (Simple Discord Link stores its token AES-encrypted, then
re-encrypts on load). If this backup was ever shared, **rotate those bot tokens**.
Only `*.example.*` templates are committed.

## Credits

- [FEX-Emu](https://github.com/FEX-Emu/FEX) — x86_64 → ARM64 emulation.
- [nitrog0d/palworld-arm64](https://github.com/nitrog0d/palworld-arm64) — reference for the Satisfactory ARM64 container.
- [FactoCord3](https://github.com/edg-l/factocord3) — Factorio ⇄ Discord bridge.
- [Simple Discord Link](https://sdlink.fdd-docs.com/) — Minecraft ⇄ Discord bridge.
- Factorio, Minecraft, and Satisfactory — property of their respective owners; no game
  content is distributed here.

## License

[MIT](LICENSE)