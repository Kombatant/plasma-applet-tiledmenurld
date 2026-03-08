# Copilot Instructions — Tiled Menu Reloaded (Plasma 6)

## What this is
- KDE Plasma 6 Plasmoid (`KPackageStructure: Plasma/Applet`) — Windows 10–style launcher.
- Plugin id: `org.github.kombatant.tiled_rld` (see [metadata.json](../metadata.json)).

## Architecture map
- Entry point: [contents/ui/main.qml](../contents/ui/main.qml) (`PlasmoidItem`) wires `AppsModel`, `SearchModel`, `AppletConfig`, `Logger`.
- Main popup layout: [contents/ui/Popup.qml](../contents/ui/Popup.qml) = `SearchView` (left) + `TileGrid` (right) + `SidebarView` overlay.
- App discovery/search is via `org.kde.plasma.private.kicker` (RootModel, favorites, RunnerModel).

## Critical project gotchas (don’t break Plasma)
- **Kicker parent-chain crash**: `KickerAppModel` (`Kicker.SimpleFavoritesModel`) must remain a child of `Kicker.RootModel` so `appEntry.actions()` can find `appletInterface` (see [contents/ui/AppsModel.qml](../contents/ui/AppsModel.qml) and [contents/ui/KickerAppModel.qml](../contents/ui/KickerAppModel.qml)).

## Tile layout persistence (Base64 XML)
- Layout lives in `plasmoid.configuration.tileModel` encoded as a Base64-wrapped XML string and exposed as `config.tileModel.value` in [contents/ui/AppletConfig.qml](../contents/ui/AppletConfig.qml).
- The grid binds directly: `TileGrid.tileModel: config.tileModel.value` (see [contents/ui/Popup.qml](../contents/ui/Popup.qml)).
- **After any mutation to the tile data or objects**, call `tileGrid.tileModelChanged()` (see [contents/ui/TileGrid.qml](../contents/ui/TileGrid.qml)). Saving is debounced in Popup (`Timer` → `config.tileModel.save()`); don’t save on every event.
- **Editor stale-reference rule**: the tile editor holds a reference to a tile object; when `save()` reloads, the underlying data may be replaced. [contents/ui/TileEditorView.qml](../contents/ui/TileEditorView.qml) closes on `config.tileModel.loaded()` to avoid editing stale refs—keep this behavior.

## Drag/drop + search specifics
- Always normalize drop URLs before storing: `Utils.parseDropUrl()` strips `applications:` and paths → bare `.desktop` id (see [contents/ui/Utils.js](../contents/ui/Utils.js) and drop handling in [contents/ui/TileGrid.qml](../contents/ui/TileGrid.qml)).
- Search runners: [contents/ui/SearchModel.qml](../contents/ui/SearchModel.qml) uses `filters = []` to mean “all runners” (Qt 6 rejects `undefined`). Defaults come from `searchDefaultFilters` in [contents/config/main.xml](../contents/config/main.xml).
- Runner results: `RunnerMatchesModel.modelForRow()` isn’t implemented; use `runner.data(runner.index(row, 0), role)` (see [contents/ui/SearchResultsModel.qml](../contents/ui/SearchResultsModel.qml)).

## Local dev loop (Plasma 6)
```fish
kpackagetool6 --type Plasma/Applet --upgrade .
# Use fish-friendly sequencing; `nohup` avoids relying on `disown`.
kquitapp6 plasmashell; and nohup plasmashell --replace > /tmp/plasmashell.log 2>&1 &
tail -f /tmp/plasmashell.log
```
- Prefer [contents/ui/lib/Logger.qml](../contents/ui/lib/Logger.qml) (`logger.debug(...)`) over `console.log`; toggle `showDebug` in [contents/ui/main.qml](../contents/ui/main.qml).

## Config & translations
- When adding a new setting: update both [contents/config/main.xml](../contents/config/main.xml) and the “upgrade defaults” in [contents/ui/AppletConfig.qml](../contents/ui/AppletConfig.qml) (`ensureAllSettingsInitialized()`).
- Translation workflow lives in [translate/ReadMe.md](../translate/ReadMe.md) (uses `kpac` + gettext; emits `contents/locale/.../*.mo`).
