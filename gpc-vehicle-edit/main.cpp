#include "mainwindow.h"
#include <QApplication>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs);  // I hate GTK's typeahead!!!
    MainWindow window;
    window.show();
    return app.exec();
}
