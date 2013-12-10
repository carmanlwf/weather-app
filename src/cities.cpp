/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the FOO module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia.  For licensing terms and
** conditions see http://qt.digia.com/licensing.  For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights.  These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include <QtCore/QCoreApplication>
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QIODevice>
#include <QtCore/QTextStream>
#include <QtGlobal>

#include "cities.h"
#include "citymodel.h"
#include "applicationpaths.h"
#include <QDebug>

Cities::Cities(QObject *parent) :
    QAbstractListModel(parent)
{
    m_citiesFileName = QString("%1cities.settings").arg(ApplicationPaths::settingsPath());
    readCities();
}

Cities::~Cities()
{
    saveCities();
}

CityModel* Cities::getCityModel(int index)
{
    Q_ASSERT(index > -1);
    Q_ASSERT(index < m_cityMap.count());
    return m_cityMap.at(index).second;
}

void Cities::removeCityModel(int index)
{
    if (index < m_cityMap.count() && index >=0 )
    {
        beginRemoveRows(QModelIndex(), index, index);
        CityModel *modelToDelete = m_cityMap.at(index).second;
        modelToDelete->cleanAll();
        modelToDelete->deleteLater();
        m_cityMap.removeAt(index);
        endRemoveRows();
    }
}

int Cities::addCityModel(CityModel *model)
{
    CityModelPair pair = qMakePair(model->sourceXml(), model);
    int modelIndex = m_cityMap.indexOf(pair);
    if (modelIndex == -1) {
        m_cityMap.prepend(pair);
        connect(model, SIGNAL(contentXmlChanged()), this, SIGNAL(cityModelReady()));
        if (m_cityMap.count() > 15)
            removeCityModel(m_cityMap.count() - 1);
        return 0;
    }
    return modelIndex;
}

void Cities::readCities()
{
    QFile file(m_citiesFileName);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;
    QTextStream in(&file);
    while (!in.atEnd()) {
        QString sourceXml = in.readLine().trimmed();
        processSourceXml(sourceXml);
    }
    file.close();
}

int Cities::processSourceXml(const QString sourceXml)
{
    // Dont add save town/identical sourceXml twice
    for (int i = 0; i <m_cityMap.count(); i++) {
        if (m_cityMap.at(i).first == sourceXml)
            return i;
    }
    CityModel *model = new CityModel(this);
    if (model->setSourceXml(sourceXml))
        return addCityModel(model);

    model->deleteLater();
    return -1;
}

void Cities::saveCities()
{
    QFile file(m_citiesFileName);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return;
    QTextStream out(&file);
    for (int index = m_cityMap.count()-1; index >= 0; index--)
        out << m_cityMap.at(index).first << endl;
    file.close();
}

QVariant Cities::data(const QModelIndex & index, int role) const
{
    CityModel *model = m_cityMap.at(index.row()).second;
    if (model) {
        switch (role) {
        case CityNameRole:
            return model->cityNameDisplay().replace("_", " ");
        case CountryRole:
            return model->countryName().replace("_", " ");
        }
    }
    return QVariant();
}

int Cities::rowCount(const QModelIndex & /*parent*/) const
{
    return m_cityMap.count();
}

QHash<int, QByteArray> Cities::roleNames() const
{
    QHash<int, QByteArray> rn;
    rn[CityNameRole] = "name";
    rn[CountryRole] = "country";
    return rn;
}
