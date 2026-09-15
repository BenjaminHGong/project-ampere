# Project Ampere

Self-hosted, always-on game servers running concurrently on a single **ARM64 Oracle Cloud**
compute instance. Factorio (Space Age), a modded NeoForge Minecraft server, and Satisfactory —
plus x86_64-only game binaries forced to run on ARM64 via a from-source **FEX-Emu** build.

```
                 ┌──────────────────────────────────────────────────────────┐
                 │  Oracle Cloud ARM64 (Ampere A1, Ubuntu)                   │
                 │                                                          │
                 │   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐ │
   Discord ──────▶│  Factorio      │   │  Minecraft    │   │ Satisfactory │ │
   (FactoCord3 / │  (Space Age)   │   │ (NeoForge 21) │   │  (Docker)    │ │
    Simple Disc.)│  screen + auto │   │  screen + auto│   │ compose +    │ │
                 │  restart       │   │  restart      │   │ FEX-Emu      │ │
                 │                │   │               │   │              │ │
                 │  x86_64 ──FEX──▶ x86_64 ──JVM──┘   │   x86_64 ─FEX──┘ │ │
                 └──────────────────────────────────────────────────────────┘
```

## Highlights

- **x86_64 on ARM64 via FEX-Emu** — built FEX-Emu from source with Clang/LLVM, LLD, and
  `binfmt_misc` inside the Satisfactory Docker image (`satisfactory-server/Dockerfile`), with
  runtime isolation per service.
- **Lifecycle automation in Bash** — `screen`-based supervisors with automatic crash recovery
  and ghost-process cleanup (`factorio-server/run.sh`, `minecraft-server/run.sh`).
- **Safe update pipeline** — Factorio updates back up saves, mods, and configuration before
  downloading and deploying a new headless build (`factorio-server/update_factorio.sh`).
- **Docker Compose** with persistent volumes, explicit port mappings, and `restart: unless-stopped`
  (`satisfactory-server/docker-compose.yml`).
- **Discord ⇄ game integrations** — bidirectional chat relay, player join/leave presence,
  advancement/research notifications, moderation & status events, verified-account linking,
  and administrative commands.
- **SteamCMD**-driven installation and validation for the Satisfactory dedicated server
  (`satisfactory-server/init-server.sh`).

## Repository layout

```
├── factorio-server/         Factorio headless (Space Age) + FactoCord3 Discord bridge
└── minecraft-server/        NeoForge 1.21.1 modpack + Simple Discord Link
└── satisfactory-server/     Dockerized Satisfactory dedicated server on ARM64
```

Game binaries, worlds, saves, and caches are **gitignored** (they're re-downloadable/generated).
Everything tracked here is the engineering: scripts, containers, and configs.

## Factorio — `factorio-server/`

| File | Purpose |
| --- | --- |
| `run.sh` | Screen-supervised launcher for the FactoCord3 bot; kills stale `factorio` processes, clears locks, and auto-restarts on crash. |
| `update_factorio.sh` | Stops the server, backs up `saves/`, `mods/`, and `server-settings.json`, downloads the latest headless Linux build, restores config, restarts. |
| `config/factocord.config.example.json` | FactoCord3 → Discord settings: bot token, chat channel, admin IDs, message templates. |
| `config/server-settings.example.json` | Server name, visibility, RCON, autosave tuning. |
| `config/mod-list.example.json` | Enabled mods: Space Age + quality + elevated rails. |

Home is `/home/ubuntu/factorio-server`. Save: `harvard.zip` (Space Age).

## Minecraft — `minecraft-server/`

NeoForge **1.21.1** modpack (~45 mods: SecurityCraft, TaCZ, Farmer's Delight, Biomes O' Plenty,
and friends). Tuned in `config/`; finds pick up where `user_jvm_args.txt` leaves off.

| File | Purpose |
| --- | --- |
| `run.sh` | Restarts itself inside a `screen` session named `minecraft`, then boots NeoForge with tuned JVM args. |
| `user_jvm_args.txt` | 16 GB heap for the modpack. |
| `server.properties` | MOTD, PvP off, command blocks on, 20-player cap. |
| `config/simple-discord-link/*.example.toml` | Discord ⇄ chat bridge: chat/event relays, player join/leave, deaths, advancements, /discord. |

## Satisfactory — `satisfactory-server/`

Full containerized approach — the reason x86_64-only Satisfactory runs on ARM64 at all:

| File | Purpose |
| --- | --- |
| `Dockerfile` | Ubuntu 22.04 base `→` builds FEX-Emu from source (Clang/LLVM, LLD, Ninja, `binfmt_misc`) `→` installs SteamCMD `→` runs under the `steam` user. |
| `init-server.sh` | Installs/validates the dedicated server via SteamCMD, applies the `steamclient.so` SDK64 symlink fix, launches `FactoryServer.sh`. |
| `docker-compose.yml` | Ports `7777`/`8888`, persistent volumes (`./satisfactory`, `./config`), `restart: unless-stopped`, auto-update on start. |
| `run.sh` / `build.sh` / `interactive-shell.sh` | Lifecycle wrappers. |

## Getting started (from the Oracle box)

```bash
# Satisfactory
cd satisfactory-server
sh build.sh                          # builds the FEX + SteamCMD image (long)
sudo docker compose up -d           # installs & starts the server

# Factorio
cd factorio-server
cp config/factocord.config.example.json FactoCord3/config.json   # fill in token
sh update_factorio.sh                                           # installs + starts

# Minecraft
cd minecraft-server
cp config/simple-discord-link/simple-discord-link.example.toml \
   config/simple-discord-link/simple-discord-link.toml          # fill in token
./run.sh
```

You'll also need to open the relevant ports in the OCI **Security List** and iptables:
`25565` (Minecraft), `7777–7778` (Factorio), `7777`/`8888` (Satisfactory), plus each
Discord bridge's outbound HTTPS.

## Security notes

Real configuration files are **gitignored** — they contain live Discord bot tokens, webhooks,
channel IDs, and RCON credentials. Deploy by copying the `*.example.*` templates and filling in
your own secrets.

## Credits

- [FEX-Emu](https://github.com/FEX-Emu/FEX) — x86_64 → ARM64 translation.
- ARM64 Satisfactory image based on [nitrog0d/palworld-arm64](https://github.com/nitrog0d/palworld-arm64).
- [FactoCord3](https://github.com/edg-l/factocord3) — Factorio ⇄ Discord bridge.
- [Simple Discord Link](https://sdlink.fdd-docs.com/) — Minecraft ⇄ Discord bridge.