import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.5 as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property alias formLayout: root
    property string cfg_Source
    property int cfg_Layout
    property int cfg_FillMode
    property alias cfg_AutoPosition: autoPositionCheck.checked
    property alias cfg_PositionX: positionXSpin.value
    property alias cfg_PositionY: positionYSpin.value

    QQC2.TextField {
        Kirigami.FormData.label: "Adresse du flux :"
        Layout.fillWidth: true
        text: root.cfg_Source
        onTextChanged: root.cfg_Source = text
    }

    QQC2.ButtonGroup { id: layoutGroup }
    QQC2.RadioButton {
        Kirigami.FormData.label: "Disposition :"
        text: "Image entière sur cet écran"
        QQC2.ButtonGroup.group: layoutGroup
        checked: root.cfg_Layout === 0
        onToggled: if (checked) root.cfg_Layout = 0
    }
    QQC2.RadioButton {
        text: "Une image étalée sur tous les écrans"
        QQC2.ButtonGroup.group: layoutGroup
        checked: root.cfg_Layout === 1
        onToggled: if (checked) root.cfg_Layout = 1
    }

    QQC2.ButtonGroup { id: fillGroup }
    QQC2.RadioButton {
        Kirigami.FormData.label: "Cadrage :"
        text: "Image complète, bandes noires"
        QQC2.ButtonGroup.group: fillGroup
        checked: root.cfg_FillMode === 0
        onToggled: if (checked) root.cfg_FillMode = 0
    }
    QQC2.RadioButton {
        text: "Rognée pour remplir"
        QQC2.ButtonGroup.group: fillGroup
        checked: root.cfg_FillMode === 1
        onToggled: if (checked) root.cfg_FillMode = 1
    }
    QQC2.RadioButton {
        text: "Étirée"
        QQC2.ButtonGroup.group: fillGroup
        checked: root.cfg_FillMode === 2
        onToggled: if (checked) root.cfg_FillMode = 2
    }

    QQC2.CheckBox {
        id: autoPositionCheck
        visible: root.cfg_Layout === 1
        Kirigami.FormData.label: "Position physique :"
        text: "Automatique (d'après la disposition des écrans)"
    }
    QQC2.SpinBox {
        id: positionXSpin
        visible: root.cfg_Layout === 1
        enabled: !autoPositionCheck.checked
        Kirigami.FormData.label: "Bord gauche (mm) :"
        from: -10000
        to: 10000
        editable: true
    }
    QQC2.SpinBox {
        id: positionYSpin
        visible: root.cfg_Layout === 1
        enabled: !autoPositionCheck.checked
        Kirigami.FormData.label: "Bord haut (mm) :"
        from: -10000
        to: 10000
        editable: true
    }
    QQC2.Label {
        visible: root.cfg_Layout === 1
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Mesurer la position de la zone affichée de chaque écran (sans le cadre) depuis un même point de référence. Les tailles physiques viennent de l'écran lui-même."
    }
}
