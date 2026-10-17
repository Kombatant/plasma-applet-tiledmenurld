Run from the repository root:

```sh
python3 -B -m unittest discover -s tests -v
c++ -fPIC tests/qml_test_main.cpp -o /tmp/tiledmenu-qml-tests $(pkg-config --cflags --libs Qt6QuickTest Qt6Widgets)
QT_QPA_PLATFORM=offscreen /tmp/tiledmenu-qml-tests -input tests/tst_root_menu.qml
QT_QPA_PLATFORM=offscreen /tmp/tiledmenu-qml-tests -input tests/tst_most_used.qml
QT_QPA_PLATFORM=offscreen /tmp/tiledmenu-qml-tests -input tests/tst_group_reflow.qml
QT_QPA_PLATFORM=offscreen /tmp/tiledmenu-qml-tests -input tests/tst_tile_grid_group_move.qml
QT_QPA_PLATFORM=offscreen /tmp/tiledmenu-qml-tests -input tests/tst_tile_grid_drag_events.qml
```

The QML tests require Qt 6 development libraries and Plasma QML modules. The
small runner supplies QApplication, which PlasmaExtras.Menu requires; the
standard qmltestrunner only supplies QGuiApplication.

Tests capture the kdesu handoff and exercise harmless commands as the current
user. They never authenticate or run an application as root. To check the live
workflow after installing the plasmoid, select Run as Root from an application's
context menu and authenticate in the kdesu dialog. Also check cancellation.

`tst_most_used.qml` covers the pure helpers behind the Popular tab
(`contents/ui/lib/MostUsedLayout.js`, `contents/ui/lib/TileTabs.js`) and the
`numMostUsedApps` setting staging. The live KDE popularity data can only be
checked in Plasma: launch applications, switch Activity, and reopen the menu.

`tst_group_reflow.qml` covers `contents/ui/lib/GroupReflow.js`, the
make-room placement used when a dragged group lands on other groups or tiles.
`tst_tile_grid_group_move.qml` loads a real `TileGrid` with stubbed Plasma
context and checks that the header, card panel and tiles of each group move
together, in the drag preview and on drop, and how single tiles make room
(inside a group, growing a full group, landing on a header or a loose tile).
It also covers drag targeting: the scroll offset, the snap margin
at cell boundaries, neighbours waiting for the dwell before stepping aside,
and group cards growing in the preview.
The drag gesture itself can only be checked in Plasma: drag a group header or
a tile onto another group or tile and watch it step aside before dropping.

`tst_tile_grid_drag_events.qml` sends real internal drag events from a tile
delegate into the grid. Those events carry the dragged item's top-left
(`Drag.hotSpot`), not the pointer, so no grab offset may be applied on top.
