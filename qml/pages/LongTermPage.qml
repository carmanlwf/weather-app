/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Digia Plc and its Subsidiary(-ies) nor the names
**     of its contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import org.qtproject.demo.weather 1.0

BasicPage {
    id: page2
    title1: ApplicationInfo.currentCityModel.cityNameDisplay
    title2: ApplicationInfo.currentCityModel.countryName
    title3: qsTr("10 Days Forecast")

    property bool cityLoaded: false

    onCityLoadedChanged: updateStatusBar(ApplicationInfo.currentCityModel.copyright + " <a href=" + ApplicationInfo.currentCityModel.sourceXml + "\>(source)")

    isLocked: true

    pageComponent: Item {
        TouchScrollView {
            id: scrollview
            anchors.fill: parent
            flickableItem.interactive: true
            flickableItem.flickableDirection: Flickable.VerticalFlick
            ColumnLayout {
                id: layout
                spacing: 0
                Repeater {
                    id: repeat
                    model: cityLoaded ? ApplicationInfo.currentCityModel.daysCount() : null
                    LongTermDayItem {
                        Layout.fillWidth: true
                        last: index === repeat.count
                        onNext: nextPage()
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            opacity: cityLoaded ? 0 : 1
            Behavior on opacity { NumberAnimation{}}
            TouchLabel {
                id: label
                opacity: cityLoaded ? 0 : 1
                Behavior on opacity { NumberAnimation{} }
                anchors.centerIn: parent
                text: qsTr("Loading data...")
                horizontalAlignment: Text.AlignCenter
                verticalAlignment: Text.AlignTop
                pixelSize: 28
                color: ApplicationInfo.colors.mediumGray
                height: label.implicitHeight + 80 * ApplicationInfo.ratio
                BusyIndicator {
                    opacity: 0.8
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    height: implicitHeight * ApplicationInfo.ratio
                    width: implicitWidth * ApplicationInfo.ratio
                }
            }
        }
    }

    Connections {
        id: cityModelConnection
        target: ApplicationInfo.currentCityModel
        onError: {
            cityLoaded = false
            isLocked = false
            previousPage()
            updateStatusBar(errorMessage)
        }
        onContentXmlChanged: weathermodel.getLongTermModel(ApplicationInfo.currentCityModel)
    }

    WeatherModel {
        id: weathermodel
        onShowLongTerm: {
            isLocked = false
            cityLoaded = true
        }
        onError: {
            cityLoaded = false
            lastLoadedCity = ""
            isLocked = false
            previousPage()
            updateStatusBar(qsTr("Problem loading the data: ") + errorMessage)
        }
    }

    Stack.onStatusChanged: if (Stack.status === Stack.Active)
                               ApplicationInfo.currentCityModel.loadData()
}
