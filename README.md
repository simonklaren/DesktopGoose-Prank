# Desktop Goose – Prank Edition

A private, customized fork of **Desktop Goose by Sam Chiet (samperson)**. It keeps the original goose movement and beak-drag animation, but distributes delivered meme, notepad, and donation windows around the desktop instead of dropping them near the entry edge every time. The defaults are deliberately more active while remaining configurable and non-destructive.

Use this only on computers where you have permission. The included watchdog is visible in Windows Task Scheduler as `GooseWatchdog`, can be disabled independently, and is completely removed by `cleanup.bat`.

## Attribution and source status

- Original project/download: [Desktop Goose on itch.io](https://samperson.itch.io/desktop-goose)
- Recovered C# source used as this fork's history: [arkangel-dev/desktop-goose-source](https://github.com/arkangel-dev/desktop-goose-source)
- Original upstream README: [`docs/UPSTREAM_README.md`](docs/UPSTREAM_README.md)
- Original runtime credits, notices, patrons, changelog, and meme attribution are preserved under `Runtime/` and copied into releases.

The recovered repository is an early, decompiled .NET Framework source tree. It did **not** contain a `LICENSE` file and it predates v0.31's mod-loader implementation. This fork does not claim ownership of Desktop Goose, does not add a new license over upstream code/assets, and does not claim that the preserved `Assets/Mods` binary is loaded by this rebuilt executable. Consult the preserved `Runtime/Read me! Honk.txt` before redistributing anything; this repository is private by design.

## Changes in Prank Edition

- Random window placement across a configurable grid (3×3 by default).
- Avoids both recently selected zones whenever the grid has enough alternatives.
- Random point selection inside a zone; windows are not simply centered.
- Edge margins and final clamping account for the delivered window's actual size.
- The goose physically walks to the destination while the window continues to follow its beak.
- Existing edge-based behavior remains available with `RandomizeWindowDropPosition=False`.
- More aggressive defaults: random mouse attacks enabled, first wander 4 seconds, later wander periods 8–15 seconds.
- Stock v0.31-style `config.ini` key names with tolerant parsing, defaults for missing keys, ignored unknown keys, and clamped invalid ranges.
- Notepad messages are loaded from `Assets/Text/NotepadMessages/*.txt` rather than only the embedded phrases.
- The existing custom memes, text, sounds, and mod assets were copied byte-for-byte into `Runtime/Assets`.
- Cleaned setup/watchdog/cleanup tools, including the fix that makes `watchdog.vbs` actually read the `debug.enabled` file created by setup.

## Window drop algorithm

`WindowDropPlanner` divides the primary working area into the configured rows and columns. For each collected window it:

1. Builds a list of zones excluding the last two selections when possible.
2. Selects a random eligible zone.
3. Chooses a random window-center point within that zone.
4. Converts that center to a top-left window coordinate.
5. Clamps the coordinate using the real window dimensions and edge margin.
6. Continuously steers the goose by the difference between the current and desired window positions; the existing per-frame beak attachment moves the form.

The recovered application creates one transparent overlay sized to `Screen.PrimaryScreen.WorkingArea`, so this fork deliberately keeps primary-monitor coordinates. True per-monitor behavior would require changing the application's overlay architecture, not only the drop calculation.

Implementation locations:

- Grid selection and clamping: `Source/GooseDesktop/WindowDropPlanner.cs`
- Collect-window lifecycle and physical dragging: `Source/GooseDesktop/TheGoose.cs`
- Compatible config parsing/defaults: `Source/GooseDesktop/GooseConfig.cs`
- Lightweight deterministic tests: `tests/Program.cs`

## Configuration

Edit `config.ini` next to `GooseDesktop.exe`:

| Setting | Default | Meaning |
| --- | ---: | --- |
| `Task_CanAttackMouse` | `True` | Allows mouse attacks when poked and as a task. |
| `AttackRandomly` | `True` | Allows mouse attacks to be selected randomly. |
| `FirstWanderTimeSeconds` | `4` | Initial wandering duration. |
| `MinWanderingTimeSeconds` | `8` | Minimum later wandering duration. |
| `MaxWanderingTimeSeconds` | `15` | Maximum later wandering duration. |
| `RandomizeWindowDropPosition` | `True` | Uses the new grid planner; `False` restores edge-based drops. |
| `WindowDropGridColumns` | `3` | Grid columns, clamped to 1–10. |
| `WindowDropGridRows` | `3` | Grid rows, clamped to 1–10. |
| `WindowDropEdgeMargin` | `50` | Requested pixel margin, clamped to 0–500 and reduced for small screens. |
| `AvoidRecentDropZones` | `True` | Avoids the two most recently used zones when possible. |

Missing custom keys use these defaults. Unknown keys from newer stock configs (for example `EnableMods`, colors, or sound toggles) are ignored because this recovered source does not implement those later subsystems. Malformed known values retain defaults; timing and grid values are sanitized.

## Memes, messages, and other assets

- Memes: `Runtime/Assets/Images/Memes/`
- Notepad messages: `Runtime/Assets/Text/NotepadMessages/`
- Sounds: `Runtime/Assets/Sound/`
- Preserved mod assets: `Runtime/Assets/Mods/`

Add or remove supported image files in the meme directory. Add or remove `.txt` files in the notepad directory. Re-run `build.ps1` to copy the changed runtime tree into `dist` (the application also reads these folders directly at runtime, so rebuilding the executable is unnecessary for asset-only changes).

## Build and test

Requirements:

- Windows
- .NET SDK 9 or newer for the build/test commands
- Internet access for the first restore of Microsoft's official `Microsoft.NETFramework.ReferenceAssemblies.net452` package
- .NET Framework 4.5.2 or later installed to run the executable (modern Windows systems normally have a later compatible .NET Framework 4.x runtime)

The application still targets the upstream framework (`.NET Framework 4.5.2`); it was not migrated. From PowerShell in the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The script restores reference assemblies, performs a Release rebuild, runs the deterministic planner/config checks, creates `dist/DesktopGoose-Prank`, and writes `DesktopGoose-Prank.zip`.

Manual commands:

```powershell
dotnet restore .\Source\GooseDesktop.sln
dotnet msbuild .\Source\GooseDesktop.sln /t:Rebuild /p:Configuration=Release "/p:Platform=Any CPU"
dotnet run --project .\tests\WindowDropPlanner.Tests.csproj -c Release
```

## Run, install, and remove

For a one-off run, open `dist/DesktopGoose-Prank/GooseDesktop.exe`. Hold Escape for several seconds to exit, as in upstream Desktop Goose.

For the optional watchdog installation, run `dist/DesktopGoose-Prank/tools/setup.bat`. It requests administrator rights, copies the distribution to `%USERPROFILE%\GoosePrank\DesktopGoose-Prank`, creates a plainly named `GooseWatchdog` scheduled task at logon with a five-minute delay, and offers normal or debug mode. Existing installed files are backed up into `%USERPROFILE%\GoosePrank\DesktopGoose-Prank.backup` before replacement.

- Disable restarts but leave files installed: `tools/disable-watchdog.bat`.
- Fully remove the scheduled task and Prank Edition files: `tools/cleanup.bat`. Unrelated or legacy files already present under `%USERPROFILE%\GoosePrank` are left intact.
- Debug mode is controlled by `%USERPROFILE%\GoosePrank\debug.enabled`; setup creates/removes it and the watchdog reads it on startup.

The repository also preserves untouched copies of the original incoming scripts in `docs/original-prank-tools/` for auditability.
