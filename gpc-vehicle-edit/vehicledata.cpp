#include "vehicledata.h"
#include <iostream>
#include <fstream>
#include <format>

bool VehicleFile::load(const QString &filename) {
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly)) return false;

    QDataStream in(&file);
    in.setByteOrder(QDataStream::LittleEndian);

    for (int i = 0; i < NUM_VEHICLES; i++) {
        VehicleData &v = vehicles[i];
        in >> v.gearsCount >> v.rpmRedline >> v.rpmLimit >> v.overrevTolerance
           >> v.grip >> v.grip0 >> v.brakingSpeed >> v.brakingSpeed0
           >> v.spinThreshold >> v.spinThreshold0 >> v.rpmDownshift;
        for (int j = 0; j < 10; j++) in >> v.gears[j];
        for (int j = 0; j < 106; j++) in >> v.powerCurve[j];
        if (in.status() != QDataStream::Ok) return false;
    }

    return true;
}

QByteArray VehicleFile::toBytes() const
{
    QBuffer buffer;
    buffer.open(QIODevice::WriteOnly);
    QDataStream out(&buffer);
    out.setByteOrder(QDataStream::LittleEndian);

    for (int i = 0; i < NUM_VEHICLES; i++) {
        VehicleData const& v = vehicles[i];
        out << v.gearsCount << v.rpmRedline << v.rpmLimit << v.overrevTolerance
            << v.grip << v.grip0 << v.brakingSpeed << v.brakingSpeed0
            << v.spinThreshold << v.spinThreshold0 << v.rpmDownshift;
        for (int j = 0; j < 10; j++) out << v.gears[j];
        for (int j = 0; j < 106; j++) out << v.powerCurve[j];
        Q_ASSERT(out.status() == QDataStream::Ok);
    }

    return buffer.data();
}

bool VehicleFile::saveRaw(const QString &filename) {
    QFile file(filename);
    if (!file.open(QIODevice::WriteOnly)) return false;

    QByteArray bytes = toBytes();
    file.write(bytes);

    return true;
}


bool VehicleFile::saveAsAsm(const QString &filename) {
    std::ofstream file(filename.toStdString().c_str());

    QByteArray bytes = toBytes();
    for (size_t i = 0; i < bytes.size(); ++i)
    {
        if (i % 16 == 0)
            file << "    db ";
        std::string num = std::format("0x{:02X}", bytes[i]);
        file << num;
        if (i % 16 < 15 && i + 1 < bytes.size())
        {
            file << ", ";
        }
        else
        {
            file << "\n";
        }
    }

    return true;
}
