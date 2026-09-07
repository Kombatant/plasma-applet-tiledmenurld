Run from the repository root:

```sh
python3 -B -m unittest discover -s tests -v
c++ -fPIC tests/qml_test_main.cpp -o /tmp/tiledmenu-qml-tests $(pkg-config --cflags --libs Qt6QuickTest Qt6Widgets)
QT_QPA_PLATFORM=offscreen /tmp/tiledmenu-qml-tests -input tests/tst_root_menu.qml
```

The QML tests require Qt 6 development libraries and Plasma QML modules. The
small runner supplies QApplication, which PlasmaExtras.Menu requires; the
standard qmltestrunner only supplies QGuiApplication.

Tests capture the kdesu handoff and exercise harmless commands as the current
user. They never authenticate or run an application as root. To check the live
workflow after installing the plasmoid, select Run as Root from an application's
context menu and authenticate in the kdesu dialog. Also check cancellation.
