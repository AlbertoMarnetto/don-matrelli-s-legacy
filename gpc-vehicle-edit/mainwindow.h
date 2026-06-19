#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QComboBox>
#include <QLineEdit>
#include <QSpinBox>
#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QMenuBar>
#include <QAction>
#include <QTextEdit>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtCharts/QValueAxis>
#include <QtCharts/QChart>
#include <QTabWidget>
#include <QScrollArea>
#include <QGridLayout>
#include "vehicledata.h"

QT_USE_NAMESPACE

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);

private slots:
    void loadFile();
    void saveRawFile();
    void saveAsAsmFile();

    void selectVehicle(int index);
    void updateVehicleFromUI();
    void updateUIFromVehicle();
    void onPowerPointChanged(int index, int value);

private:
    void createMenus();
    void setupUI();
    VehicleFile vehicleFile;
    int currentVehicle;

    QAction *loadAction;
    QAction *saveRawAction;
    QAction *saveAsAsmAction;

    QComboBox *vehicleSelector;
    QTabWidget *tabWidget;
    QSpinBox *powerSpinBoxes[106];

    QSpinBox *gearsCountSpin;
    QSpinBox *rpmRedlineSpin;
    QSpinBox *rpmLimitSpin;
    QSpinBox *overrevToleranceSpin;
    QSpinBox *gripSpin;
    QSpinBox *grip0Spin;
    QSpinBox *brakingSpeedSpin;
    QSpinBox *brakingSpeed0Spin;
    QSpinBox *spinThresholdSpin;
    QSpinBox *spinThreshold0Spin;
    QSpinBox *rpmDownshiftSpin;
    QSpinBox *gearSpins[10];
    QChartView *chartView;
    QLineSeries *torqueSeries;
    QLineSeries *hpSeries;

    void updateChart();
};

#endif
