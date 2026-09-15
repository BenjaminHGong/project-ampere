# Running x86_64 game servers on ARM64 with FEX-Emu

This is the part of the project people usually want to know about: **headless
Satisfactory only ships x86_64 Linux binaries**, yet it runs fine on an
ARM64 Oracle VM. The answer is [FEX-Emu](https://github.com/FEX-Emu/FEX), built
from source and wired into `binfmt_misc` so the kernel transparently hands `x86_64`
executables to the emulator — no wrappers, no `qemu -U` flags at the call site.

## Why FEX

FEX is a fast, userspace x86_64 → AArch64 translator that pairs with the kernel's
`binfmt_misc` to act as a drop-in interpreter: when you `exec` an x86_64 ELF on
ARM64, Linux sees the binary format is unknown, matches the registered FEX magic,
and launches it under FEX automatically. Combined with an Ubuntu x86_64 **rootfs**
(which provides the `ld.so`, libc, and glibc the foreign binary needs), the command
just works.

## The build (mirrors `satisfactory-server/Dockerfile`)

```mermaid
flowchart TD
    A[Ubuntu 22.04 base] --> B[Install clang + lld + cmake + ninja + binfmt-support]
    B --> C[git clone --recurse-submodules FEX]
    C --> D[Enable USE_LEGACY_BINFMTMISC]
    D --> E[cmake: CC=clang CXX=clang++ link=lld LTO=FALSE asserts=off]
    E --> F[ninja install + ninja binfmt_misc(_64)]
    F --> G[FEXRootFSFetcher -y -x fetches x86_64 rootfs]
    G --> H[SteamCMD + Satisfactory under FEXBash]
```

Step by step:

1. **Toolchain** — `clang`, `lld`, `llvm`, `cmake`, `ninja-build`, `binfmt-support`
   are installed first.
2. **Source build** — `git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git`,
   then the CMake configure:
   ```bash
   CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr \
     -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld \
     -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
   ninja && ninja install
   ```
3. **`USE_LEGACY_BINFMTMISC`** — inside a container there's no `systemd`/`systemctl`
   to hand off the new-style binfmt setup, so FEX's `USE_LEGACY_BINFMTMISC` path
   (writing `/proc/sys/fs/binfmt_misc/register` directly) is switched on.
4. **Register interpreters** — `ninja binfmt_misc` and `ninja binfmt_misc_64`
   register the `FEXInterpreter` for the x86-64 (and x86) magic.
5. **Root filesystem** — as the unprivileged `steam` user,
   `FEXRootFSFetcher -y -x` downloads the Ubuntu x86_64 rootfs that FEX uses as the
   emulated ABI. Without it, x86_64 binaries still exec but fail at `ld.so`.
6. **Run foreign binaries** — every container entry is prefixed with
   `FEXBash` (e.g. `FEXBash './steamcmd.sh +login anonymous +app_update 1690800 …'`),
   which runs the surrounding shell and its children under the emulator.

## Gotchas observed in production

| Problem | Fix (in this repo) |
| --- | --- |
| `steamclient.so` not found by the server | `init-server.sh` symlinks `Steam/linux64/steamclient.so` → `~/.steam/sdk64/` on entry |
| `/satisfactory` volume permission errors | Dockerfile creates user `steam` (UID 1000); `init-server.sh` checks `r/w` and prints a `chown -R 1000:1000` hint |
| First boot must always install the full game | `steamcmd.sh +app_update 1690800 … validate` runs at container start when `ALWAYS_UPDATE_ON_START=true` |
| Image build is long the first time | `build-nocache.sh` exists for full rebuilds; normal `build.sh` reuses cache layers |

## Why this matters

The same image pattern applies to any x86_64-only headless binary on ARM64:
build FEX, register binfmt rules, install through the emulator, and isolate the
result behind Docker. Everything the game touches (volumes, ports, restart policy)
is managed by `docker-compose.yml`, so the ARM64 host just runs containers.