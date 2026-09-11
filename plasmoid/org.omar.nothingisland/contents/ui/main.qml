import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "."

// isla dinámica para plasma: píldora en el panel + panel emergente al clic
// mismo contenido y animaciones que hyprland, pero el crecimiento lo maneja plasma
// se intentó crecer en el lugar (ver Island.qml y el readme), plasma se pelea con eso
PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    onExpandedChanged: {
        if (!root.expanded) {
            Cfg.currentOverlay = "";
            Cfg.requestedOverlay = "main";
        }
    }

    // ── preferencias ──
    // los singletons no ven Plasmoid.configuration, se copian a Cfg acá
    // con Binding y no onCompleted, así los cambios se ven al instante
    Binding {
        target: Cfg
        property: "lang"
        value: Plasmoid.configuration.lang
    }
    Binding {
        target: Cfg
        property: "clock24"
        value: Plasmoid.configuration.clock24
    }
    Binding {
        target: Cfg
        property: "ramUsage"
        value: Plasmoid.configuration.ramUsage
    }
    Binding {
        target: Cfg
        property: "showWorkspaces"
        value: Plasmoid.configuration.showWorkspaces
    }
    Binding {
        target: Cfg
        property: "showWeather"
        value: Plasmoid.configuration.showWeather
    }
    Binding {
        target: Cfg
        property: "showClock"
        value: Plasmoid.configuration.showClock
    }
    Binding {
        target: Cfg
        property: "showNetwork"
        value: Plasmoid.configuration.showNetwork
    }
    Binding {
        target: Cfg
        property: "showVolume"
        value: Plasmoid.configuration.showVolume
    }
    Binding {
        target: Cfg
        property: "showBattery"
        value: Plasmoid.configuration.showBattery
    }
    Binding {
        target: Cfg
        property: "showMini"
        value: Plasmoid.configuration.showMini
    }
    Binding {
        target: Cfg
        property: "weatherCity"
        value: Plasmoid.configuration.weatherCity
    }
    Binding {
        target: Cfg
        property: "colorFondo"
        value: Plasmoid.configuration.colorFondo
    }
    Binding {
        target: Cfg
        property: "colorTarjeta"
        value: Plasmoid.configuration.colorTarjeta
    }
    Binding {
        target: Cfg
        property: "colorInvertida"
        value: Plasmoid.configuration.colorInvertida
    }
    Binding {
        target: Cfg
        property: "colorAlerta"
        value: Plasmoid.configuration.colorAlerta
    }
    Binding {
        target: Cfg
        property: "colorTexto"
        value: Plasmoid.configuration.colorTexto
    }
    Binding {
        target: Cfg
        property: "fuenteUi"
        value: Plasmoid.configuration.fuenteUi
    }
    Binding {
        target: Cfg
        property: "fuenteNumeros"
        value: Plasmoid.configuration.fuenteNumeros
    }

    // fondo propio, sin la superficie de plasma
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    toolTipMainText: Qt.formatDateTime(new Date(), "HH:mm")
    toolTipSubText: Weather.ready ? Weather.temp + " · " + Weather.desc : ""

    compactRepresentation: Item {
        id: compact

        readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: horizontal ? Theme.collapsedWidth : -1
        Layout.preferredWidth: horizontal ? Theme.collapsedWidth : -1
        Layout.maximumWidth: Infinity
        Layout.minimumHeight: Theme.collapsedHeight
        Layout.preferredHeight: Theme.collapsedHeight

        implicitWidth: Theme.collapsedWidth
        implicitHeight: Theme.collapsedHeight

        CompactPill {
            anchors.fill: parent
            rootItem: root
        }
    }

    // máximo fijado igual al mínimo a propósito, si no plasma estira el popup
    // y vuelve la franja negra. si se cambia el alto, borrar popupHeight en la config del applet
    fullRepresentation: ExpandedPanel {
        Layout.minimumWidth: Theme.expandedWidth
        Layout.preferredWidth: Theme.expandedWidth
        Layout.maximumWidth: Theme.expandedWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
    }
}
