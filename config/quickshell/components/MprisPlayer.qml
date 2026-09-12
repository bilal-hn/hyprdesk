import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 105
    color: Theme.surface
    radius: 16
    border.color: Theme.border
    border.width: 1

    property var player: {
        let active = Mpris.players.values.find((p) => p.playbackState === MprisPlaybackState.Playing);
        return active ? active : (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null);
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Album Art / Placeholder
        Rectangle {
            width: 48
            height: 48
            radius: 12
            color: Qt.alpha(Theme.accent, 0.15)
            border.color: Theme.accent
            border.width: 1
            clip: true

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl || ""
                fillMode: Image.PreserveAspectCrop
                visible: !!root.player?.trackArtUrl
            }

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: Theme.iconFont
                font.pixelSize: 22
                color: Theme.accent
                visible: !root.player?.trackArtUrl
            }
        }

        // Track Info & Controls
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.player?.trackTitle || "No media playing"
                color: "white"
                font.pixelSize: 12
                font.weight: Font.Bold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.player?.trackArtist || "Idle"
                color: Theme.subtle
                font.pixelSize: 10
                font.weight: Font.Bold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Controls Row
            RowLayout {
                spacing: 12
                visible: !!root.player

                Text {
                    text: "󰒮"
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    color: Theme.fg
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.previous()
                    }
                }

                Text {
                    text: root.player?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                    color: Theme.accent
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.togglePlaying()
                    }
                }

                Text {
                    text: "󰒭"
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    color: Theme.fg
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.next()
                    }
                }
            }
        }
    }
}
