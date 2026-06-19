#include "mainwindow.h"
#include <QFileDialog>
#include <QMessageBox>
#include <QFormLayout>
#include <QGridLayout>
#include <QStatusBar>
#include <QTabWidget>
#include <QScrollArea>
#include <QSignalBlocker>

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent), currentVehicle(0), torqueSeries(nullptr), hpSeries(nullptr), chartView(nullptr) {
    setupUI();
    createMenus();
    setWindowTitle("GPC Vehicle Editor");
    resize(800, 1000);
}

void MainWindow::createMenus() {
    QMenu *fileMenu = menuBar()->addMenu("File");
    loadAction = new QAction("Load", this);
    loadAction->setShortcut(QKeySequence("Ctrl+O"));
    connect(loadAction, &QAction::triggered, this, &MainWindow::loadFile);
    fileMenu->addAction(loadAction);

    saveRawAction = new QAction("Save", this);
    saveRawAction->setShortcut(QKeySequence("Ctrl+S"));
    connect(saveRawAction, &QAction::triggered, this, &MainWindow::saveRawFile);
    fileMenu->addAction(saveRawAction);

    saveAsAsmAction = new QAction("Save as asm", this);
    saveAsAsmAction->setShortcut(QKeySequence("Ctrl+D"));
    connect(saveAsAsmAction, &QAction::triggered, this, &MainWindow::saveAsAsmFile);
    fileMenu->addAction(saveAsAsmAction);
}

void MainWindow::setupUI() {
    QWidget *central = new QWidget(this);
    QVBoxLayout *mainLayout = new QVBoxLayout(central);

    vehicleSelector = new QComboBox();
    vehicleSelector->addItems({"Vehicle 1", "Vehicle 2", "Vehicle 3"});
    connect(vehicleSelector, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &MainWindow::selectVehicle);
    mainLayout->addWidget(new QLabel("Select Vehicle:"));
    mainLayout->addWidget(vehicleSelector);

    tabWidget = new QTabWidget();

    // Tab 1: Vehicle Data (3-column layout)
    QWidget *vehicleTab = new QWidget();
    QGridLayout *grid = new QGridLayout(vehicleTab);

    gearsCountSpin = new QSpinBox(); gearsCountSpin->setRange(0, 65535);
    rpmRedlineSpin = new QSpinBox(); rpmRedlineSpin->setRange(0, 65535);
    rpmLimitSpin = new QSpinBox(); rpmLimitSpin->setRange(0, 65535);
    overrevToleranceSpin = new QSpinBox(); overrevToleranceSpin->setRange(0, 65535);
    gripSpin = new QSpinBox(); gripSpin->setRange(0, 65535);
    grip0Spin = new QSpinBox(); grip0Spin->setRange(0, 65535);
    brakingSpeedSpin = new QSpinBox(); brakingSpeedSpin->setRange(0, 65535);
    brakingSpeed0Spin = new QSpinBox(); brakingSpeed0Spin->setRange(0, 65535);
    spinThresholdSpin = new QSpinBox(); spinThresholdSpin->setRange(0, 65535);
    spinThreshold0Spin = new QSpinBox(); spinThreshold0Spin->setRange(0, 65535);
    rpmDownshiftSpin = new QSpinBox(); rpmDownshiftSpin->setRange(0, 65535);

    QString gearNames[10] = {"N (Neutral)", "1", "2", "3", "4", "5", "6", "7", "8", "9"};
    for (int i = 0; i < 10; i++) {
        gearSpins[i] = new QSpinBox(); gearSpins[i]->setRange(0, 65535);
    }

    struct Field { QString label; QSpinBox *spin; };
    std::vector<Field> col1 = {
        {"Gears Count:", gearsCountSpin}, {"RPM Redline:", rpmRedlineSpin},
        {"RPM Limit:", rpmLimitSpin}, {"Overrev Tolerance:", overrevToleranceSpin},
        {"Grip:", gripSpin}, {"Grip*:", grip0Spin},
    };
    std::vector<Field> col2 = {
        {"RPM Downshift:", rpmDownshiftSpin},
        {"Braking Speed:", brakingSpeedSpin}, 
        {"Braking Speed*:", brakingSpeed0Spin},
        {"Spin Threshold:", spinThresholdSpin},
        {"Spin Threshold*:", spinThreshold0Spin}
    };
    std::vector<Field> col3 = {
        {"Gear N:", gearSpins[0]}, {"Gear 1:", gearSpins[1]}, {"Gear 2:", gearSpins[2]},
        {"Gear 3:", gearSpins[3]}, {"Gear 4:", gearSpins[4]}, {"Gear 5:", gearSpins[5]},
        {"Gear 6:", gearSpins[6]}, {"Gear 7:", gearSpins[7]}, {"Gear 8:", gearSpins[8]},
        {"Gear 9:", gearSpins[9]}
    };

    int col_index = 0;
    for (auto const & col : {col1, col2, col3})
    {
        size_t i = 0;
        for (auto const & entry : col)
        {
            grid->addWidget(new QLabel(entry.label), i, col_index);
            grid->addWidget(entry.spin, i, col_index + 1);
            ++i;
        }
        col_index += 2;
    }

    // Add horizontal spacer columns between column pairs
    grid->setColumnStretch(6, 1);
    //grid->setColumnStretch(5, 1);

    int nextRow = col3.size() + 1;
    grid->addWidget(new QLabel("* after pit stop"), nextRow++, 1);

    // No vertical elastic space: push content up by stretching the empty row below
    grid->setRowStretch(nextRow, 1);

    tabWidget->addTab(vehicleTab, "Vehicle Data");

    // Tab 2: Power Curve
    QWidget *powerTab = new QWidget();
    QVBoxLayout *powerLayout = new QVBoxLayout(powerTab);

    torqueSeries = new QLineSeries();
    torqueSeries->setName("Torque");
    hpSeries = new QLineSeries();
    hpSeries->setName("HP");
    hpSeries->setPen(QPen(Qt::red));

    QChart *chart = new QChart();
    chart->addSeries(torqueSeries);
    chart->addSeries(hpSeries);
    //chart->setTitle("Torque and HP vs RPM");
    chart->legend()->show();
    chart->legend()->setAlignment(Qt::AlignTop);

    QValueAxis *axisX = new QValueAxis();
    axisX->setTitleText("RPM x 1000");
    axisX->setRange(0, 12);
    axisX->setTickCount(13);
    axisX->setLabelFormat("%d");

    QValueAxis *axisYTorque = new QValueAxis();
    axisYTorque->setTitleText("Torque");
    axisYTorque->setRange(0, 300);
    axisYTorque->setTickCount(11);
    axisYTorque->setLabelFormat("%d");

    QValueAxis *axisYHP = new QValueAxis();
    axisYHP->setTitleText("HP");
    axisYHP->setRange(0, 1000);
    axisYHP->setTickCount(11);
    axisYHP->setLabelFormat("%d");

    chart->addAxis(axisX, Qt::AlignBottom);
    chart->addAxis(axisYTorque, Qt::AlignLeft);
    chart->addAxis(axisYHP, Qt::AlignRight);

    torqueSeries->attachAxis(axisX);
    torqueSeries->attachAxis(axisYTorque);
    hpSeries->attachAxis(axisX);
    hpSeries->attachAxis(axisYHP);

    chartView = new QChartView(chart);
    chartView->setRenderHint(QPainter::Antialiasing);
    chartView->setMaximumHeight(450);

    powerLayout->addWidget(chartView);

    QScrollArea *scrollArea = new QScrollArea();
    QWidget *scrollWidget = new QWidget();
    QGridLayout *powerGrid = new QGridLayout(scrollWidget);

    for (int i = 0; i < 106; i++) {
        int rpm = 768 + i * 128;
        QLabel *label = new QLabel(QString("RPM %1:").arg(rpm));
        powerSpinBoxes[i] = new QSpinBox();
        powerSpinBoxes[i]->setRange(0, 255);
        powerSpinBoxes[i]->setSingleStep(5);

        connect(powerSpinBoxes[i], QOverload<int>::of(&QSpinBox::valueChanged), this, [this, i](int val) {
            onPowerPointChanged(i, val);
        });
        powerGrid->addWidget(label, i / 5, (i % 5) * 2);
        powerGrid->addWidget(powerSpinBoxes[i], i / 5, (i % 5) * 2 + 1);
    }

    scrollArea->setWidget(scrollWidget);
    scrollArea->setMaximumHeight(300);
    powerLayout->addWidget(scrollArea);

    tabWidget->addTab(powerTab, "Power Curve");

    mainLayout->addWidget(tabWidget);
    setCentralWidget(central);
}

void MainWindow::loadFile() {
    // Vehicle file: extract the DS segment at offset 75f2 and length 444:
    // dd if=data-segment.bin of=memdump-2--vehicles.bin bs=1 skip=$(( 0x75f2 )) count=444
    QString filename = QFileDialog::getOpenFileName(this, "Load Vehicle File");
    if (filename.isEmpty()) return;

    if (vehicleFile.load(filename)) {
        updateUIFromVehicle();
        statusBar()->showMessage("Loaded: " + filename);
    } else {
        QMessageBox::critical(this, "Error", "Failed to load file");
    }
}

void MainWindow::saveRawFile() {
    QString filename = QFileDialog::getSaveFileName(this, "Save Vehicle File");
    if (filename.isEmpty()) return;

    updateVehicleFromUI();
    if (vehicleFile.saveRaw(filename)) {
        statusBar()->showMessage("Saved: " + filename);
    } else {
        QMessageBox::critical(this, "Error", "Failed to save file");
    }
}

void MainWindow::saveAsAsmFile() {
    QString filename = QFileDialog::getSaveFileName(this, "Save .asm fragment");
    if (filename.isEmpty()) return;

    updateVehicleFromUI();
    if (vehicleFile.saveAsAsm(filename)) {
        statusBar()->showMessage("Saved: " + filename);
    } else {
        QMessageBox::critical(this, "Error", "Failed to save file");
    }
}

void MainWindow::selectVehicle(int index) {
    updateVehicleFromUI();
    currentVehicle = index;
    updateUIFromVehicle();
}

void MainWindow::updateVehicleFromUI() {
    VehicleData &v = vehicleFile.vehicles[currentVehicle];
    v.gearsCount = gearsCountSpin->value();
    v.rpmRedline = rpmRedlineSpin->value();
    v.rpmLimit = rpmLimitSpin->value();
    v.overrevTolerance = overrevToleranceSpin->value();
    v.grip = gripSpin->value();
    v.grip0 = grip0Spin->value();
    v.brakingSpeed = brakingSpeedSpin->value();
    v.brakingSpeed0 = brakingSpeed0Spin->value();
    v.spinThreshold = spinThresholdSpin->value();
    v.spinThreshold0 = spinThreshold0Spin->value();
    v.rpmDownshift = rpmDownshiftSpin->value();
    for (int i = 0; i < 10; i++) v.gears[i] = gearSpins[i]->value();
    for (int i = 0; i < 106; i++) v.powerCurve[i] = static_cast<quint8>(powerSpinBoxes[i]->value());
}

void MainWindow::updateUIFromVehicle() {
    VehicleData &v = vehicleFile.vehicles[currentVehicle];
    gearsCountSpin->setValue(v.gearsCount);
    rpmRedlineSpin->setValue(v.rpmRedline);
    rpmLimitSpin->setValue(v.rpmLimit);
    overrevToleranceSpin->setValue(v.overrevTolerance);
    gripSpin->setValue(v.grip);
    grip0Spin->setValue(v.grip0);
    brakingSpeedSpin->setValue(v.brakingSpeed);
    brakingSpeed0Spin->setValue(v.brakingSpeed0);
    spinThresholdSpin->setValue(v.spinThreshold);
    spinThreshold0Spin->setValue(v.spinThreshold0);
    rpmDownshiftSpin->setValue(v.rpmDownshift);
    for (int i = 0; i < 10; i++) gearSpins[i]->setValue(v.gears[i]);

    QSignalBlocker blocker(powerSpinBoxes[0]);
    for (int i = 0; i < 106; i++) {
        powerSpinBoxes[i]->setValue(v.powerCurve[i]);
    }

    updateChart();
}

void MainWindow::updateChart() {
    VehicleData &v = vehicleFile.vehicles[currentVehicle];
    torqueSeries->clear();
    hpSeries->clear();
    qreal maxHP = 0;
    for (int i = 0; i < 106; i++) {
        qreal rpm = 768 + i * 128;
        qreal krpm = rpm / 1000;
        qreal torque = v.powerCurve[i];
        qreal hp = torque * rpm / 8.72 / 128 * 0.73; // Empirical
        maxHP = qMax(maxHP, hp);
        torqueSeries->append(krpm, torque);
        hpSeries->append(krpm, hp);
    }
    //QValueAxis *axisYHP = static_cast<QValueAxis*>(hpSeries->attachedAxes()[1]);
}

void MainWindow::onPowerPointChanged(int index, int value) {
    vehicleFile.vehicles[currentVehicle].powerCurve[index] = static_cast<quint8>(value);
    updateChart();
}
