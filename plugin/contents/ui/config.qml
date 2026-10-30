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
    property alias cfg_Deblock: deblockCheck.checked
    property alias cfg_DeblockStrength: deblockSlider.value

    QQC2.TextField {
        Kirigami.FormData.label: "Stream URL:"
        Layout.fillWidth: true
        text: root.cfg_Source
        onTextChanged: root.cfg_Source = text
    }

    QQC2.ButtonGroup { id: layoutGroup }
    QQC2.RadioButton {
        Kirigami.FormData.label: "Layout:"
        text: "Whole picture on this screen"
        QQC2.ButtonGroup.group: layoutGroup
        checked: root.cfg_Layout === 0
        onToggled: if (checked) root.cfg_Layout = 0
    }
    QQC2.RadioButton {
        text: "One picture spanned across all screens"
        QQC2.ButtonGroup.group: layoutGroup
        checked: root.cfg_Layout === 1
        onToggled: if (checked) root.cfg_Layout = 1
    }

    QQC2.ButtonGroup { id: fillGroup }
    QQC2.RadioButton {
        Kirigami.FormData.label: "Fill mode:"
        text: "Whole picture, black bars"
        QQC2.ButtonGroup.group: fillGroup
        checked: root.cfg_FillMode === 0
        onToggled: if (checked) root.cfg_FillMode = 0
    }
    QQC2.RadioButton {
        text: "Cropped to fill"
        QQC2.ButtonGroup.group: fillGroup
        checked: root.cfg_FillMode === 1
        onToggled: if (checked) root.cfg_FillMode = 1
    }
    QQC2.RadioButton {
        text: "Stretched"
        QQC2.ButtonGroup.group: fillGroup
        checked: root.cfg_FillMode === 2
        onToggled: if (checked) root.cfg_FillMode = 2
    }

    QQC2.CheckBox {
        id: autoPositionCheck
        visible: root.cfg_Layout === 1
        Kirigami.FormData.label: "Physical position:"
        text: "Automatic (from the screen layout)"
    }
    QQC2.SpinBox {
        id: positionXSpin
        visible: root.cfg_Layout === 1
        enabled: !autoPositionCheck.checked
        Kirigami.FormData.label: "Left edge (mm):"
        from: -10000
        to: 10000
        editable: true
    }
    QQC2.SpinBox {
        id: positionYSpin
        visible: root.cfg_Layout === 1
        enabled: !autoPositionCheck.checked
        Kirigami.FormData.label: "Top edge (mm):"
        from: -10000
        to: 10000
        editable: true
    }
    QQC2.Label {
        visible: root.cfg_Layout === 1
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Measure the position of the visible area of each screen (without the bezel) from a common reference point. Physical sizes come from the screen itself."
    }

    QQC2.CheckBox {
        id: deblockCheck
        Kirigami.FormData.label: "Deblocking filter:"
        text: "Smooth blocks and banding"
    }
    QQC2.Slider {
        id: deblockSlider
        enabled: deblockCheck.checked
        Kirigami.FormData.label: "Strength:"
        Layout.fillWidth: true
        from: 0
        to: 100
        stepSize: 5
    }
}
