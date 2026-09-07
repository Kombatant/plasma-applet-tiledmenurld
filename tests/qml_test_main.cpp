#include <QApplication>
#include <QtQuickTest/quicktest.h>

int main(int argc, char **argv)
{
	// PlasmaExtras.Menu uses QMenu and therefore requires QApplication.
	QApplication app(argc, argv);
	return quick_test_main(argc, argv, "tiledmenu", nullptr);
}
