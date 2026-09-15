# Discord ⇄ game integrations

Both bridges turn a dedicated game channel into a first-class window into the
servers: chat flows both ways, in-game events show up as Discord messages, and
administrative commands/status are available from Discord without touching the box.

`satisfactory` has no Discord bridge, so the integrations cover **Factorio**
(FactoCord3) and **Minecraft** (Simple Discord Link).

## Factorio — FactoCord3

[FactoCord3](https://github.com/edg-l/factocord3) is a Go bot that acts as both the
process supervisor and the chat bridge. It launches the Factorio binary with
`--start-server`, watches its console, and relays messages between Discord and the
game. The tracked template is `factorio-server/config/factocord.config.example.json`.

| Capability | Where it lives |
| --- | --- |
| Bidirectional chat relay | `messages.*` templates + chat listener |
| Player presence (join/leave) | `player_join` / `player_leave` messages |
| Server status & crash alerts | `server_start` / `server_fail` / `bot_start` |
| Moderation + admin commands | `$` prefixed commands; `admin_ids` / `command_roles` scoping |
| Research & in-game event notifications | **custom scenario** `factorio-server/scenario/control.lua` (below) |

### The custom scenario (control.lua)

`factorio-server/scenario/control.lua` is a save-scenario mod that listens to
Factorio's event bus and emits every interesting server event as a line the bot
forwards verbatim to Discord:

```mermaid
flowchart LR
    EV[Factorio event] --> LUA[control.lua handler]
    LUA --> CON[console line: 0000-00-00 00:00:00 [DISCORD] msg]
    CON --> BOT[FactoCord3 parser]
    BOT --> DC[Discord channel]
```

Events wired up: player joined / left, chat, deaths (**with killer entity** —
character name, spidertron vehicle, locomotive, or biter), kick / ban / unban /
mute / unmute, and **research started / finished** (`on_research_started`,
`on_research_finished`) — the "research notifications" on the resume, e.g.

```lua
script.on_event(defines.events.on_research_finished, function(event)
    local research = event.research;
    local by_player = "";
    if event.by_player then
        by_player = " by **" .. game.players[event.by_player].name .. "**";
    end
    FactoCordIntegration.PrintToDiscord(":rocket: Research finished: **"
        .. research.localised_name .. "**" .. by_player);
end)
```

The `[DISCORD]` prefix is the handshake: FactoCord matches console lines carrying
the `0000-00-00 00:00:00 [DISCORD]` tag and posts the remainder raw, so arbitrary
game events become Discord messages without any round-trip through the bot API.

## Minecraft — Simple Discord Link

[Simple Discord Link](https://sdlink.fdd-docs.com/) runs as a normal NeoForge mod
and manages its own bot. The live config (`config/simple-discord-link/simple-discord-link.toml`)
is gitignored — it stores the bot token AES-encrypted along with webhook secrets;
the tracked `…-link.example.toml` is the sanitized template.

Enabled in `config`:

- **Bidirectional chat relay** over webhooks (per-player Discord avatars/names),
  tagged in-game as `[Discord] <user>:`
- **Server lifecycle events** — started / stopped / joining
- **Player presence** — join/leave messages
- **Advancement & death announcements** — ALWAYS
- **Command broadcast** — who ran what, plus a `/discord` invite command
- **Living status** — channel topic & bot status refresh every few minutes:
  `IP: <host> | players/maxplayers | Uptime`
- **Account linking** — Minecraft × Discord identity verification via `/verify`
  (links persisted under gitignored `sdlinkstorage/`)

## Secrets hygiene

- FactoCord3 stores the Discord token **in plaintext** in `config.json`.
- Simple Discord Link stores its token **AES-encrypted at rest** and re-encrypts it
  on first load.
- Every real config is gitignored; the repo ships `*.example.*` templates instead.
  If this backup was ever shared, rotate the bot tokens — see
  [_Security notes_](../README.md#security-notes).