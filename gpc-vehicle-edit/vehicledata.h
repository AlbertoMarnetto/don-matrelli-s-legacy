#ifndef VEHICLEDATA_H
#define VEHICLEDATA_H

#include <QBuffer>
#include <QFile>
#include <QDataStream>

#pragma pack(push, 1)
struct VehicleData {
    quint16 gearsCount;
    quint16 rpmRedline;
    quint16 rpmLimit;
    quint16 overrevTolerance;
    quint16 grip;
    quint16 grip0;
    quint16 brakingSpeed;
    quint16 brakingSpeed0;
    quint16 spinThreshold;
    quint16 spinThreshold0;
    quint16 rpmDownshift;
    quint16 gears[10];
    quint8 powerCurve[106];
};
#pragma pack(pop)

class VehicleFile {
public:
    static const int NUM_VEHICLES = 3;
    static const int VEHICLE_SIZE = sizeof(VehicleData);

    VehicleData vehicles[NUM_VEHICLES];

    bool load(const QString &filename);
    bool saveRaw(const QString &filename);
    bool saveAsAsm(const QString &filename);
    QByteArray toBytes() const;
};

#endif
