import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."

Rectangle {
    id: excelOverlayRoot

    anchors.fill: parent
    z: 50
    visible: isOpen
    color: Theme.alpha(Theme.bgVoid, 0.82)

    property bool isOpen: false
    property string fileName: "Invenesis_Batch_PRJ2026.xlsx"
    property string sourceNote: ""
    property var previewRows: []
    property string remarksText: ""

    readonly property int duplicateCount: {
        var c = 0;
        for (var i = 0; i < previewRows.length; ++i) {
            if (previewRows[i].isDuplicate) c++;
        }
        return c;
    }

    signal confirmed(var importedRows, string remarks)
    signal cancelled()

    function normalizeBaseId(rawId) {
        var s = String(rawId || "").trim().toUpperCase();
        return s.replace(/\s*\(SAMPLE\s+\d+\)$/i, "");
    }

    function recomputeDuplicates(rows) {
        var counts = {};
        for (var i = 0; i < rows.length; ++i) {
            var base = normalizeBaseId(rows[i].baseId || rows[i].id);
            counts[base] = (counts[base] || 0) + 1;
        }
        var seen = {};
        var result = [];
        for (var j = 0; j < rows.length; ++j) {
            var r = Object.assign({}, rows[j]);
            var baseId = normalizeBaseId(r.baseId || r.id);
            r.baseId = baseId;
            if ((counts[baseId] || 0) > 1) {
                seen[baseId] = (seen[baseId] || 0) + 1;
                r.id = baseId + " (Sample " + seen[baseId] + ")";
                r.isDuplicate = true;
            } else {
                r.id = baseId;
                r.isDuplicate = false;
            }
            result.push(r);
        }
        return result;
    }

    function openWithBatch(name, rows, note) {
        fileName = name && name.length > 0 ? name : "Invenesis_Batch_PRJ2026.xlsx";
        sourceNote = note || "SCHEMA PARSER: Sample ID ➔ compound_id  •  Vehicle ➔ solvent  •  Stock ➔ stock_conc  •  Form ➔ form";
        previewRows = recomputeDuplicates(rows || []);
        remarksText = "";
        remarksInput.text = "";
        isOpen = true;
    }

    function removeRow(idx) {
        if (idx < 0 || idx >= previewRows.length) return;
        var next = previewRows.slice();
        next.splice(idx, 1);
        previewRows = recomputeDuplicates(next);
    }

    // Consume background clicks cleanly
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: function(mouse) { mouse.accepted = true; }
    }

    // Centered Modal Card
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 760)
        height: Math.min(parent.height - 36, 520)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: Theme.paletteAccent
        border.width: 2

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true; }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // 1. Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Theme.alpha(Theme.paletteAccent, 0.16)
                    border.color: Theme.paletteAccent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: Theme.paletteAccent
                        text: "description"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "Excel Batch Validation Preview"
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                        text: excelOverlayRoot.sourceNote
                    }
                }

                Rectangle {
                    Layout.preferredWidth: filePillTxt.implicitWidth + 18
                    Layout.preferredHeight: 26
                    radius: Theme.radiusPill
                    color: Theme.alpha(Theme.statusGreen, 0.14)
                    border.color: Theme.statusGreen
                    border.width: 1

                    Text {
                        id: filePillTxt
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.statusGreen
                        text: excelOverlayRoot.fileName
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14
                    color: closeBtnMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "✕"
                    }

                    MouseArea {
                        id: closeBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            excelOverlayRoot.isOpen = false;
                            excelOverlayRoot.cancelled();
                        }
                    }
                }
            }

            // 2. Live Duplicate Sample Disambiguation Banner
            Rectangle {
                visible: excelOverlayRoot.duplicateCount > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: Theme.radiusSm
                color: Theme.alpha(Theme.statusWarning, 0.16)
                border.color: Theme.statusWarning
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        font.family: Theme.fontIcon
                        font.pixelSize: 15
                        color: Theme.terracottaGlow
                        text: "warning"
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "Duplicate Sample ID detected (" + excelOverlayRoot.duplicateCount + " rows) — auto-disambiguated as (Sample 1) / (Sample 2). Remove extra row or keep both."
                    }
                }
            }

            // 3. Parsed Table Header + Scrollable Rows
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.bgVoid
                border.color: Theme.borderCard
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Table Column Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: Theme.bgSurface

                        Row {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                width: parent.width * 0.30; height: parent.height
                                Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: "COMPOUND ID" }
                            }
                            Item {
                                width: parent.width * 0.14; height: parent.height
                                Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: "SOLVENT" }
                            }
                            Item {
                                width: parent.width * 0.14; height: parent.height
                                Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: "STOCK" }
                            }
                            Item {
                                width: parent.width * 0.14; height: parent.height
                                Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: "QTY / VOL" }
                            }
                            Item {
                                width: parent.width * 0.16; height: parent.height
                                Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: "FORM" }
                            }
                            Item {
                                width: parent.width * 0.12; height: parent.height
                                Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: "ACTION" }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent
                            visible: excelOverlayRoot.previewRows.length === 0
                            font.family: Theme.fontBody
                            font.pixelSize: 12
                            color: Theme.textDim
                            text: "No rows remaining. Cancel to return or drop a new spreadsheet."
                        }

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 6
                            contentHeight: rowsCol.implicitHeight
                            clip: true

                            ColumnLayout {
                                id: rowsCol
                                width: parent.width
                                spacing: 4

                                Repeater {
                                    model: excelOverlayRoot.previewRows

                                    Rectangle {
                                        id: rowDelegate
                                        required property int index
                                        required property var modelData

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 4
                                        color: modelData.isDuplicate
                                               ? Theme.alpha(Theme.statusWarning, 0.12)
                                               : (index % 2 === 0 ? Theme.bgSurface : Theme.bgCard)
                                        border.color: modelData.isDuplicate ? Theme.statusWarning : Theme.borderCard
                                        border.width: 1

                                        Row {
                                            anchors.fill: parent
                                            spacing: 0

                                            Item {
                                                width: parent.width * 0.30; height: parent.height
                                                Row {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 10
                                                    spacing: 6
                                                    Rectangle {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: 8; height: 8; radius: 4
                                                        color: Theme.compoundPalette[rowDelegate.index % Theme.compoundPalette.length]
                                                    }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        font.family: Theme.fontMono
                                                        font.pixelSize: 10
                                                        font.weight: Font.Bold
                                                        color: rowDelegate.modelData.isDuplicate ? Theme.terracottaGlow : Theme.textPrimary
                                                        text: rowDelegate.modelData.id
                                                    }
                                                }
                                            }

                                            Item {
                                                width: parent.width * 0.14; height: parent.height
                                                Text {
                                                    anchors.centerIn: parent
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 10
                                                    color: Theme.paletteAccent
                                                    text: rowDelegate.modelData.solvent
                                                }
                                            }

                                            Item {
                                                width: parent.width * 0.14; height: parent.height
                                                Text {
                                                    anchors.centerIn: parent
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 10
                                                    color: Theme.textSecondary
                                                    text: rowDelegate.modelData.stock
                                                }
                                            }

                                            Item {
                                                width: parent.width * 0.14; height: parent.height
                                                Text {
                                                    anchors.centerIn: parent
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 10
                                                    color: Theme.textMuted
                                                    text: rowDelegate.modelData.vol
                                                }
                                            }

                                            Item {
                                                width: parent.width * 0.16; height: parent.height
                                                Text {
                                                    anchors.centerIn: parent
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 9
                                                    color: Theme.textDim
                                                    text: String(rowDelegate.modelData.form || "Solution").toUpperCase()
                                                }
                                            }

                                            Item {
                                                width: parent.width * 0.12; height: parent.height
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 24; height: 24; radius: 12
                                                    color: rmMouse.containsMouse ? Theme.alpha(Theme.cinnabar, 0.22) : Theme.bgCard
                                                    border.color: rmMouse.containsMouse ? Theme.cinnabar : Theme.borderCard
                                                    border.width: 1
                                                    Text {
                                                        anchors.centerIn: parent
                                                        font.family: Theme.fontMono
                                                        font.pixelSize: 10
                                                        color: rmMouse.containsMouse ? Theme.cinnabar : Theme.textMuted
                                                        text: "✕"
                                                    }
                                                    MouseArea {
                                                        id: rmMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: excelOverlayRoot.removeRow(rowDelegate.index)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 4. Special Lab Instructions / Remarks Input
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.textDim
                    text: "LAB REMARKS:"
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 4
                    color: Theme.bgVoid
                    border.color: remarksInput.activeFocus ? Theme.paletteAccent : Theme.borderCard
                    border.width: 1

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        visible: remarksInput.text.length === 0 && !remarksInput.activeFocus
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        color: Theme.textDim
                        text: "Optional lab notes (e.g. max 0.5% DMSO final, store -20°C)"
                    }

                    TextInput {
                        id: remarksInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        color: Theme.textPrimary
                        selectByMouse: true
                        onTextChanged: excelOverlayRoot.remarksText = text
                    }
                }
            }

            // 5. Modal Footer Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                    text: excelOverlayRoot.previewRows.length + " compounds validated (max 8 plated per SBS-96 demo)"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 34
                    radius: Theme.radiusPill
                    color: cancelMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "Cancel"
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            excelOverlayRoot.isOpen = false;
                            excelOverlayRoot.cancelled();
                        }
                    }
                }

                Rectangle {
                    readonly property bool canConfirm: excelOverlayRoot.previewRows.length > 0
                    Layout.preferredWidth: 224
                    Layout.preferredHeight: 34
                    radius: Theme.radiusPill
                    color: canConfirm ? Theme.statusGreen : Theme.bgSurface
                    border.color: canConfirm ? Theme.statusGreen : Theme.borderCard
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: parent.canConfirm ? Theme.textOnGreen : Theme.textDim
                        text: "Confirm & Import (" + excelOverlayRoot.previewRows.length + ") ✓"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canConfirm
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            var outRows = excelOverlayRoot.previewRows.slice();
                            var notes = excelOverlayRoot.remarksText.trim();
                            excelOverlayRoot.isOpen = false;
                            excelOverlayRoot.confirmed(outRows, notes);
                        }
                    }
                }
            }
        }
    }
}
