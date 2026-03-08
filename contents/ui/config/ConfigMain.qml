import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

// NOTE: Do not use KCM.SimpleKCM here.
// SimpleKCM is a Kirigami.ScrollablePage with its own internal flickable.
// That causes an "outer" scrollbar (in Plasma's config dialog) and can steal
// mouse wheel events from our custom right-pane ScrollView.
// We manage scrolling ourselves, so use the non-scrollable base.
KCM.AbstractKCM {
    // Two-pane configuration shell:
    // - Left: section list (independently scrollable)
    // - Right: section content (scrollable)
    // The host dialog must not scroll the entire shell (left + right together).

    id: page

    // Force Window color scheme instead of inheriting Plasma theme colors
    // This ensures controls look correct in light mode when Plasma theme is dark
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    // Plasma's config dialog tries to set `cfg_<key>` and `cfg_<key>Default` properties
    // on the root item. We write directly to `plasmoid.configuration` in our pages, but
    // defining these avoids noisy "Setting initial properties failed" warnings.
    property var cfg_icon
    property var cfg_iconDefault
    property var cfg_fixedPanelIcon
    property var cfg_fixedPanelIconDefault
    property var cfg_searchResultsGrouped
    property var cfg_searchResultsGroupedDefault
    property var cfg_searchDefaultFilters
    property var cfg_searchDefaultFiltersDefault
    property var cfg_showRecentApps
    property var cfg_showRecentAppsDefault
    property var cfg_recentOrdering
    property var cfg_recentOrderingDefault
    property var cfg_numRecentApps
    property var cfg_numRecentAppsDefault
    property var cfg_sidebarShortcuts
    property var cfg_sidebarShortcutsDefault
    property var cfg_defaultAppListView
    property var cfg_defaultAppListViewDefault
    property var cfg_terminalApp
    property var cfg_terminalAppDefault
    property var cfg_taskManagerApp
    property var cfg_taskManagerAppDefault
    property var cfg_fileManagerApp
    property var cfg_fileManagerAppDefault
    property var cfg_tileModel
    property var cfg_tileModelDefault
    property var cfg_tileScale
    property var cfg_tileScaleDefault
    property var cfg_tileIconSize
    property var cfg_tileIconSizeDefault
    property var cfg_tileMargin
    property var cfg_tileMarginDefault
    property var cfg_tilesLocked
    property var cfg_tilesLockedDefault
    property var cfg_defaultTileColor
    property var cfg_defaultTileColorDefault
    property var cfg_defaultTileGradient
    property var cfg_defaultTileGradientDefault
    property var cfg_sidebarBackgroundColor
    property var cfg_sidebarBackgroundColorDefault
    property var cfg_hideSearchField
    property var cfg_hideSearchFieldDefault
    property var cfg_searchOnTop
    property var cfg_searchOnTopDefault
    property var cfg_searchFieldFollowsTheme
    property var cfg_searchFieldFollowsThemeDefault
    property var cfg_sidebarFollowsTheme
    property var cfg_sidebarFollowsThemeDefault
    property var cfg_tileLabelAlignment
    property var cfg_tileLabelAlignmentDefault
    property var cfg_groupLabelAlignment
    property var cfg_groupLabelAlignmentDefault
    property var cfg_showGroupTileNameBorder
    property var cfg_showGroupTileNameBorderDefault
    property var cfg_presetTilesFolder
    property var cfg_presetTilesFolderDefault
    property var cfg_appDescription
    property var cfg_appDescriptionDefault
    property var cfg_appListIconSize
    property var cfg_appListIconSizeDefault
    property var cfg_searchFieldHeight
    property var cfg_searchFieldHeightDefault
    property var cfg_appListWidth
    property var cfg_appListWidthDefault
    property var cfg_popupHeight
    property var cfg_popupHeightDefault
    property var cfg_favGridCols
    property var cfg_favGridColsDefault
    property var cfg_sidebarButtonSize
    property var cfg_sidebarButtonSizeDefault
    property var cfg_sidebarIconSize
    property var cfg_sidebarIconSizeDefault
    property var cfg_tileAnimatedPlayOnHover
    property var cfg_tileAnimatedPlayOnHoverDefault
    property var cfg_aiProvider
    property var cfg_aiProviderDefault
    property var cfg_aiApiKey
    property var cfg_aiApiKeyDefault
    property var cfg_aiOllamaUrl
    property var cfg_aiOllamaUrlDefault
    property var cfg_aiOpenWebUiUrl
    property var cfg_aiOpenWebUiUrlDefault
    property var cfg_aiModel
    property var cfg_aiModelDefault
    property var cfg_aiDetectedModels
    property var cfg_aiDetectedModelsDefault
    property var cfg_aiChatHistory
    property var cfg_aiChatHistoryDefault
    property var cfg_aiStreamChat
    property var cfg_aiStreamChatDefault
    readonly property var _cfgKeys: ["icon", "fixedPanelIcon", "searchResultsGrouped", "searchDefaultFilters", "showRecentApps", "recentOrdering", "numRecentApps", "sidebarShortcuts", "defaultAppListView", "aiProvider", "aiApiKey", "aiOllamaUrl", "aiOpenWebUiUrl", "aiModel", "aiDetectedModels", "aiChatHistory", "aiStreamChat", "terminalApp", "taskManagerApp", "fileManagerApp", "tileModel", "tileScale", "tileIconSize", "tileMargin", "tilesLocked", "defaultTileColor", "defaultTileGradient", "sidebarBackgroundColor", "hideSearchField", "searchOnTop", "searchFieldFollowsTheme", "sidebarFollowsTheme", "tileLabelAlignment", "groupLabelAlignment", "showGroupTileNameBorder", "presetTilesFolder", "appDescription", "appListIconSize", "searchFieldHeight", "appListWidth", "popupHeight", "favGridCols", "sidebarButtonSize", "sidebarIconSize", "sidebarPosition", "tileRoundedCorners", "tileCornerRadius", "tileAnimatedPlayOnHover"]
    // Make the initial config window a bit wider so pages lay out cleanly.
    // Do not force shrink: respect user resizing after open.
    readonly property int wideModeMinWidth: Kirigami.Units.gridUnit * 40
    readonly property int preferredWindowWidth: Kirigami.Units.gridUnit * 48
    property string filterText: ""
    property string currentSectionKey: ""
    readonly property var _allSections: [{
        "key": "general",
        "name": i18n("General"),
        "icon": "configure",
        "source": "ConfigGeneral.qml",
        "visible": true
    }, {
        "key": "sidebar",
        "name": i18n("Sidebar"),
        "icon": "sidebar-expand-left",
        "source": "ConfigSidebar.qml",
        "visible": true
    }, {
        "key": "search",
        "name": i18n("Search"),
        "icon": "edit-find",
        "source": "ConfigSearch.qml",
        "visible": true
    }, {
        "key": "aiChat",
        "name": i18n("AI Chat"),
        "icon": "dialog-messages",
        "source": "ConfigAiChat.qml",
        "visible": true
    }, {
        "key": "layout",
        "name": i18n("Import/Export Layout"),
        "icon": "grid-rectangular",
        "source": "ConfigExportLayout.qml",
        "visible": true
    }, {
        "key": "advanced",
        "name": i18n("Advanced"),
        "icon": "applications-development",
        "source": "../lib/ConfigAdvanced.qml",
        "visible": false
    }, {
        "key": "shortcuts",
        "name": i18nd("plasma_shell_org.kde.plasma.desktop", "Keyboard Shortcuts"),
        "icon": "preferences-desktop-keyboard",
        "source": "SectionKeyboardShortcuts.qml",
        "visible": true
    }, {
        "key": "about",
        "name": i18n("About"),
        "icon": "help-about",
        "source": "SectionAbout.qml",
        "visible": true
    }]
    readonly property var filteredSections: {
        var needle = (filterText || "").trim().toLowerCase();
        var out = [];
        for (var i = 0; i < _allSections.length; i++) {
            var s = _allSections[i];
            if (!s || !s.visible)
                continue;

            if (!needle || (s.name || "").toLowerCase().indexOf(needle) !== -1)
                out.push(s);

        }
        return out;
    }
    // --- Keyboard shortcuts: preserve Apply/OK semantics.
    property string _shortcutPending: ""

    signal configurationChanged()

    function _bindCfgToConfiguration() {
        for (var i = 0; i < _cfgKeys.length; i++) {
            var key = _cfgKeys[i];
            var propName = "cfg_" + key;
            if (typeof page[propName] === "undefined")
                continue;

            page[propName] = Qt.binding((function(k) {
                return function() {
                    return plasmoid.configuration[k];
                };
            })(key));
        }
    }

    function _isClassName(item, className) {
        var itemClassName = ("" + item).split("_", 1)[0]
        return itemClassName === className
    }

    function _getAncestor(item, className) {
        var curItem = item
        while (curItem && curItem.parent) {
            curItem = curItem.parent
            if (_isClassName(curItem, className)) {
                return curItem
            }
        }
        return null
    }

    function _getAppletConfigurationRoot() {
        if (typeof root === "undefined" || !root) {
            return null
        }
        return _isClassName(root, "AppletConfiguration") ? root : _getAncestor(root, "AppletConfiguration")
    }

    function _applyWindowWidthConstraints() {
        if (!Window.window || !Window.window.visible)
            return ;

        if (Window.window.width < wideModeMinWidth)
            Window.window.width = wideModeMinWidth;

        if (Window.window.width < preferredWindowWidth)
            Window.window.width = preferredWindowWidth;

    }

    function _sectionByKey(key) {
        for (var i = 0; i < _allSections.length; i++) {
            var s = _allSections[i];
            if (s && s.key === key)
                return s;

        }
        return null;
    }

    function _ensureValidSelection() {
        // Keep the current selection when possible; otherwise select the first item.
        for (var i = 0; i < filteredSections.length; i++) {
            if (filteredSections[i].key === currentSectionKey)
                return ;

        }
        currentSectionKey = filteredSections.length ? filteredSections[0].key : "";
    }

    function _startCollapseOuterNavigation() {
        collapseOuterNavRetry.attemptsLeft = 20;
        collapseOuterNavRetry.restart();
    }

    function saveConfig() {
        // Called by the config dialog on Apply/OK.
        if (("" + Plasmoid.globalShortcut) !== ("" + _shortcutPending))
            Plasmoid.globalShortcut = _shortcutPending;

    }

    function _walk(item, maxDepth, visitor) {
        if (!item || maxDepth < 0)
            return false;

        if (visitor(item))
            return true;

        var kids = item.children;
        if (!kids || kids.length === 0)
            return false;

        for (var i = 0; i < kids.length; i++) {
            if (_walk(kids[i], maxDepth - 1, visitor))
                return true;

        }
        return false;
    }

    function _findFirst(item, maxDepth, predicate) {
        var found = null;
        _walk(item, maxDepth, function(node) {
            if (predicate(node)) {
                found = node;
                return true;
            }
            return false;
        });
        return found;
    }

    function _collapseOuterNavigationOnce() {
        // The outer strip is hard-coded by Plasma's AppletConfiguration.qml.
        // We collapse it so our inner Kate-like sidebar is the only navigation.
        var appletConfiguration = _getAppletConfigurationRoot()
        if (!appletConfiguration) {
            return false
        }

        // Find the outer category strip (a QQC2.ScrollView with fixed width = gridUnit*7).
        var expectedWidth = Kirigami.Units.gridUnit * 7;
        var categoriesStrip = _findFirst(appletConfiguration, 4, function(node) {
            if (!node || typeof node.width === "undefined")
                return false;

            var isScroll = ("" + node).indexOf("ScrollView") !== -1;
            if (!isScroll)
                return false;

            return Math.abs(node.width - expectedWidth) <= 2;
        });
        // Find the Kirigami.ApplicationItem that hosts the page stack.
        var appItem = _findFirst(appletConfiguration, 4, function(node) {
            return node && typeof node.pageStack !== "undefined" && typeof node.footer !== "undefined";
        });
        if (!categoriesStrip || !appItem)
            return false;

        // Collapse & hide the outer strip.
        categoriesStrip.visible = false;
        categoriesStrip.enabled = false;
        categoriesStrip.width = 0;
        // Hide any vertical separator next to it.
        var sep = _findFirst(appletConfiguration, 2, function(node) {
            var isSep = ("" + node).indexOf("Separator") !== -1;
            if (!isSep || !node.anchors)
                return false;

            // Typically the vertical separator has top/left/bottom anchors and no right anchor.
            return node.anchors.top && node.anchors.bottom && node.anchors.left && !node.anchors.right;
        });
        if (sep) {
            sep.visible = false;
            if (typeof sep.width !== "undefined")
                sep.width = 0;

        }
        // Re-anchor the app container to the left edge so it uses full width.
        if (appItem.anchors) {
            appItem.anchors.left = appletConfiguration.left;
            appItem.anchors.leftMargin = 0;
        }
        return true;
    }

    function _hideHostApplyButtonOnce() {
        // Plasma's AppletConfiguration.qml defines an Apply button in the footer.
        // It is often redundant for our settings shell; hide it to avoid a
        // permanently-disabled control in the UI.
        var appletConfiguration = _getAppletConfigurationRoot()
        if (!appletConfiguration) {
            return false
        }

        var applyButton = _findFirst(appletConfiguration, 6, function(node) {
            if (!node)
                return false;

            // Match by icon name; text is translated.
            try {
                return node.icon && node.icon.name === "dialog-ok-apply";
            } catch (e) {
                return false;
            }
        });
        if (!applyButton)
            return false;

        applyButton.visible = false;
        applyButton.enabled = false;
        // Try to also remove any remaining layout allocation.
        if (typeof applyButton.implicitWidth !== "undefined")
            applyButton.implicitWidth = 0;

        if (typeof applyButton.width !== "undefined")
            applyButton.width = 0;

        if (typeof applyButton.Layout !== "undefined") {
            applyButton.Layout.preferredWidth = 0;
            applyButton.Layout.maximumWidth = 0;
        }
        return true;
    }

    // Kate-like: sidebar search + section list + page content.
    title: i18n("Settings")
    Window.onWindowChanged: {
        if (Window.window)
            Window.window.visibleChanged.connect(function() {
            // Defer: Plasma applies its own initial sizing during show.
            _applyWindowWidthConstraints();
            Qt.callLater(_applyWindowWidthConstraints);
        });

    }
    onFilterTextChanged: _ensureValidSelection()
    Component.onCompleted: {
        // Defer initialization to avoid creating graphical objects before
        // the page is attached to the host configuration shell. This
        // prevents intermittent "Created graphical object was not placed
        // in the graphics scene" warnings on some Plasma versions.
        Qt.callLater(function() {
            try {
                _bindCfgToConfiguration();
                _startCollapseOuterNavigation();
                _ensureValidSelection();
                _shortcutPending = ("" + Plasmoid.globalShortcut);
                _applyWindowWidthConstraints();

                // On some Plasma versions, the config page attaches late.
                // Retry once root gets a parent.
                if (typeof root !== "undefined" && root && typeof root.parentChanged === "function") {
                    root.parentChanged.connect(function() {
                        _startCollapseOuterNavigation();
                        _applyWindowWidthConstraints();
                    });
                }
            } catch (e) {
                console.warn('ConfigMain: deferred initialization failed', e)
            }
        })
    }

    Timer {
        id: collapseOuterNavRetry

        property int attemptsLeft: 20

        interval: 50
        repeat: true
        onTriggered: {
            var collapsed = page._collapseOuterNavigationOnce();
            var applyHidden = page._hideHostApplyButtonOnce();
            if (collapsed && applyHidden) {
                stop();
                return ;
            }
            attemptsLeft -= 1;
            if (attemptsLeft <= 0)
                stop();

        }
    }

    // Clamp the outer content's implicit size to the visible page so any host scroll
    // container has nothing to scroll, and then provide an explicit ScrollView only
    // for the right content pane.
    Item {
        id: contentRoot

        anchors.fill: parent
        implicitWidth: page.width
        implicitHeight: page.height

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            QQC2.Frame {
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                Layout.minimumWidth: Kirigami.Units.gridUnit * 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.TextField {
                        // QQC2 TextField doesn't reliably expose a clear button across all
                        // Plasma/Qt6 style versions; avoid using non-portable properties.

                        id: searchField

                        Layout.fillWidth: true
                        placeholderText: i18n("Search...")
                        text: page.filterText
                        onTextChanged: page.filterText = text
                        selectByMouse: true
                    }

                    // Independent scrolling for the section list.
                    ListView {
                        id: sectionList

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: page.filteredSections
                        currentIndex: {
                            for (var i = 0; i < page.filteredSections.length; i++) {
                                if (page.filteredSections[i].key === page.currentSectionKey)
                                    return i;

                            }
                            return -1;
                        }

                        delegate: QQC2.ItemDelegate {
                            width: ListView.view.width
                            text: modelData.name
                            icon.name: modelData.icon
                            highlighted: modelData.key === page.currentSectionKey
                            onClicked: page.currentSectionKey = modelData.key
                        }

                    }

                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 2
                    text: {
                        var s = page._sectionByKey(page.currentSectionKey);
                        return s ? s.name : "";
                    }
                }

                QQC2.Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Provide scrolling for the right pane only.
                    Item {
                        anchors.fill: parent

                        QQC2.ScrollView {
                            id: contentScroll

                            anchors.fill: parent
                            visible: !!page.currentSectionKey
                            enabled: visible
                            clip: true

                            Item {
                                id: scrollContent

                                width: contentScroll.availableWidth
                                implicitHeight: sectionScrollLoader.height

                                // Target source derived from section key.
                                // We disable the outgoing item before
                                // swapping the Loader's source so that
                                // Qt grab cleanup runs while all items
                                // are still alive — avoids a Qt crash in
                                // setEffectiveEnableRecur / removeGrabber
                                // during deep item-tree destruction.
                                property string _targetSectionSource: {
                                    var s = page._sectionByKey(page.currentSectionKey);
                                    return s ? s.source : "";
                                }
                                on_TargetSectionSourceChanged: {
                                    if (sectionScrollLoader.item) {
                                        sectionScrollLoader.item.enabled = false;
                                    }
                                    _sectionSwapTimer.restart();
                                }
                                Timer {
                                    id: _sectionSwapTimer
                                    interval: 1
                                    onTriggered: {
                                        sectionScrollLoader.source = scrollContent._targetSectionSource;
                                    }
                                }

                                Loader {
                                    id: sectionScrollLoader

                                    readonly property real _itemImplicitHeight: item ? item.implicitHeight : 0

                                    width: scrollContent.width
                                    active: !!page.currentSectionKey
                                    // Many pages (especially those containing their own ScrollView)
                                    // report implicitHeight as 0. Ensure we still allocate visible
                                    // space by falling back to the viewport height.
                                    height: Math.max((contentScroll.availableHeight || contentScroll.height || 0), _itemImplicitHeight)
                                    source: scrollContent._targetSectionSource // initial source
                                    onLoaded: {
                                        // Ensure the loaded page uses the right-pane width so
                                        // FormLayouts wrap correctly inside the ScrollView.
                                        if (item && typeof item.width !== "undefined")
                                            item.width = scrollContent.width;

                                        if (item && typeof item.height !== "undefined" && (item.implicitHeight || 0) === 0)
                                            item.height = sectionScrollLoader.height;

                                        if (item && typeof item.Layout !== "undefined")
                                            item.Layout.fillWidth = true;

                                    }
                                }

                            }

                        }

                        // Wheel events can be consumed by nested controls/flickables.
                        // Always scroll the right pane when the wheel is used anywhere over it.
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            enabled: contentScroll.visible
                            onWheel: function(wheel) {
                                var flick = contentScroll.contentItem
                                if (!flick || typeof flick.contentY === "undefined") {
                                    return
                                }

                                var dy = 0
                                if (wheel.pixelDelta && wheel.pixelDelta.y) {
                                    dy = wheel.pixelDelta.y
                                } else if (wheel.angleDelta && wheel.angleDelta.y) {
                                    dy = (wheel.angleDelta.y / 120) * (Kirigami.Units.gridUnit * 3)
                                }
                                if (dy === 0) {
                                    return
                                }

                                var maxY = 0
                                if (typeof flick.contentHeight !== "undefined" && typeof flick.height !== "undefined") {
                                    maxY = Math.max(0, flick.contentHeight - flick.height)
                                }

                                flick.contentY = Math.max(0, Math.min(flick.contentY - dy, maxY))
                                wheel.accepted = true
                            }
                        }
                    }

                }

            }

        }

    }

}
