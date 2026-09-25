import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#181a1f"

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            errorMessage.color = "#3F68EE"
            errorMessage.text = "Entrando..."
        }
        function onLoginFailed() {
            passwordInput.text = ""
            errorMessage.color = "#ff6b6b"
            errorMessage.text = "Usuário ou senha incorretos"
        }
        function onInformationMessage(message) {
            errorMessage.color = "#ff6b6b"
            errorMessage.text = message
        }
    }

    Image {
        id: background
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // clock
    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -160

        color: "#eed6ebff"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 80

        function updateTime() {
            text = Qt.formatTime(new Date(), "HH:mm")
        }

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: clock.updateTime()
        }
        Component.onCompleted: updateTime()
    }

    // date
    Text {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -85

        color: "#cca3d5ff"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20

        function updateDate() {
            text = Qt.locale("pt_BR").toString(new Date(), "dddd, d 'de' MMMM")
        }

        Timer {
            interval: 60000; running: true; repeat: true
            onTriggered: dateLabel.updateDate()
        }
        Component.onCompleted: updateDate()
    }

    // username (editable, prefilled with last user)
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 40
        visible: name.text.length === 0
        text: "usuário"
        color: "#775c6370"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
    }

    TextInput {
        id: name
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 40
        width: 250
        horizontalAlignment: TextInput.AlignHCenter

        color: "#cc00bfff"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16

        text: userModel.lastUser
        clip: true

        KeyNavigation.tab: passwordInput
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                passwordInput.forceActiveFocus()
                event.accepted = true
            }
        }
    }

    // password field, styled like hyprlock's input-field
    Rectangle {
        id: passwordBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 130

        width: 250
        height: 60
        radius: 14
        color: "#ee181a1f"
        border.width: 2
        border.color: passwordInput.activeFocus ? "#3F68EE" : "#5c6370"

        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            visible: passwordInput.text.length === 0
            text: "Digite a senha..."
            color: "#5c6370"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
        }

        TextInput {
            id: passwordInput
            anchors.centerIn: parent
            width: parent.width - 30
            horizontalAlignment: TextInput.AlignHCenter

            color: "#D6EBFF"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20

            echoMode: TextInput.Password
            passwordCharacter: "●"
            clip: true
            focus: true

            KeyNavigation.backtab: name
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    sddm.login(name.text, passwordInput.text, sessionIndex)
                    event.accepted = true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }
    }

    Text {
        id: errorMessage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 175

        color: "#ff6b6b"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        text: ""
    }

    // extra options: session picker + power actions, kept small and unobtrusive
    Row {
        id: extraOptions
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 22
        spacing: 10
        opacity: 0.85

        Dropdown {
            id: session
            width: 150; height: 32
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12

            color: "#ee181a1f"
            borderColor: "#5c6370"
            focusColor: "#3F68EE"
            hoverColor: "#3F68EE"
            menuColor: "#181a1f"
            textColor: "#D6EBFF"

            model: sessionModel
            index: sessionModel.lastIndex
        }

        Button {
            id: loginButton
            text: "Entrar"
            width: 70; height: 32
            radius: 8
            color: "#3F68EE"
            activeColor: "#5c85ff"
            pressedColor: "#2a4bb8"
            textColor: "#0d0f14"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            onClicked: sddm.login(name.text, passwordInput.text, sessionIndex)
        }

        Button {
            id: rebootButton
            text: "↻ Reiniciar"
            width: 100; height: 32
            radius: 8
            color: "#ee181a1f"
            activeColor: "#3F68EE"
            pressedColor: "#2a4bb8"
            textColor: "#D6EBFF"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            onClicked: sddm.reboot()
        }

        Button {
            id: shutdownButton
            text: "⏻ Desligar"
            width: 100; height: 32
            radius: 8
            color: "#ee181a1f"
            activeColor: "#3F68EE"
            pressedColor: "#2a4bb8"
            textColor: "#D6EBFF"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: {
        if (name.text == "")
            name.focus = true
        else
            passwordInput.forceActiveFocus()
    }
}
