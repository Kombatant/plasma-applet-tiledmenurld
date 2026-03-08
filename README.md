
# Tiled Menu Reloaded

Tiled Menu Reloaded is a Plasma applet that provides a tiled launcher loosely inspired by Windows 10's start menu. It offers flexible tile layouts, groupable tiles, and configurable shortcuts while targeting Plasma 6 and Qt6 compatibility. 

**Used various LLMs as a playground for code generation and assistance in forking/structuring/coding the project.**

## Origins
- Forked from zren's (kind of abandoned) Tiled Menu: https://github.com/Zren/plasma-applet-tiledmenu

## Key goals:
- Provide an attractive, editable tile-based application launcher.
- Make common launcher workflows (pinning, grouping, quick search) fast and discoverable.
- Support modern Qt6/Plasma 6 environments.

## Highlights
- **New with 0.7 version**: added a AI Chat tab to the sidebar, which can be used to interact with various LLMs. 
- Tile-based launcher with configurable sizes (1×1, 2×2, 4×4, and mixed layouts). 
- Rounded tiles with customizable corner radius now supported.
- Group tiles with headers; move and sort items within groups.
- Drag-and-drop pinning from file manager and search results.
- Animated tile support (GIF, APNG, WEBP) and per-tile background images.
- Configurable sidebar position, shortcuts and search filters.
- Quick search/filtering of applications and files.
- Stores tile layout as a Base64-encoded XML fragment. 
- New default preset images folder: ~/Pictures/TiledMenuReloaded, configurable in settings.

<details>
<summary><h2>Click here for screenshots</h2></summary>

![Main menu](contents/docs/main.png)

![Settings](contents/docs/settings.png)

![Bottom Sidebar position](contents/docs/bottom_sidebar.png)

![AI Chat](contents/docs/aichat.png)

![Animations supported](contents/docs/tiled_rld_animation.gif)
</details>

## Installation

### Option A — Using kpackagetool6 (recommended)

1. Download and extract the release zip, then from inside the extracted folder run:

    ```bash
    kpackagetool6 --type Plasma/Applet --install .
    ```

    (Use `--upgrade` instead of `--install` to update an existing installation.)

2. Restart Plasma Shell:

    ```bash
    kquitapp6 plasmashell && nohup plasmashell --replace > /tmp/plasmashell.log 2>&1 &
    ```

### Option B — Manual copy

1. Extract the zip and rename the folder to match the plugin ID:

    ```bash
    mkdir -p ~/.local/share/plasma/plasmoids/
    unzip <package>.zip
    mv plasma-applet-tiledmenurld-* ~/.local/share/plasma/plasmoids/org.github.kombatant.tiled_rld
    ```

2. Restart Plasma Shell:

    ```bash
    kquitapp6 plasmashell && nohup plasmashell --replace > /tmp/plasmashell.log 2>&1 &
    ```

### Then

Add the applet: right-click your application launcher, choose "Show Alternatives", and select "Tiled Menu Reloaded".

## Usage
- Pin items: right‑click an application or file and select "Pin" or drag it to the tile grid.
- Edit tiles: use the tile editor to change label, icon, background image, size, and placement.
- Groups: create a new group from the grid context menu; drag tiles into groups and use the group header to sort.
- Resize the popup by dragging its edges or just use the auto resize button in the sidebar.

## Configuration
- Settings are available from the applet configuration dialog. Important options include default tile folder, tile scale, grid columns, and search filters.

## Contact
- Report issues at: https://github.com/Kombatant/plasma-applet-tiledmenurld/issues

