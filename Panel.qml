import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "eyosyasgg.cpu-clock-slider"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  // Active limit percentage (50%, 70%, 100%)
  property int currentLimit: 100
  property string currentFreq: "---"
  property string currentMaxFreq: "2.0 GHz"
  readonly property bool busy: writeProcess.running

  readonly property string sysPath: "/sys/devices/system/cpu/intel_pstate/max_perf_pct"
  readonly property var tiers: [50, 70, 100]

  function open() {
    root.controller.show()
    readStatus()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function") {
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    }
    return false
  }

  function stepUp() {
    if (currentLimit <= 50) setLimit(70)
    else if (currentLimit <= 70) setLimit(100)
    else setLimit(100)
  }

  function stepDown() {
    if (currentLimit >= 100) setLimit(70)
    else if (currentLimit >= 70) setLimit(50)
    else setLimit(50)
  }

  function setLimit(target) {
    var val = target
    if (val !== 50 && val !== 70 && val !== 100) {
      if (val < 60) val = 50
      else if (val < 85) val = 70
      else val = 100
    }
    currentLimit = val
    var khz = val * 20000
    writeProcess.command = [
      "sh", "-c",
      "echo " + val + " > " + root.sysPath + " 2>/dev/null; " +
      "for p in /sys/devices/system/cpu/cpufreq/policy*; do echo " + khz + " > \"$p/scaling_max_freq\" 2>/dev/null; done"
    ]
    writeProcess.running = true
  }

  function readStatus() {
    readProcess.running = true
  }

  // Periodic refresh of live frequency while panel is open
  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    onTriggered: root.readStatus()
  }

  Process {
    id: readProcess
    command: [
      "bash", "-c",
      "cat " + root.sysPath + " 2>/dev/null || echo 100\n" +
      "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 0\n" +
      "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo 2000000"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.trim().split("\n")
        if (lines.length >= 1) {
          var num = parseInt(lines[0].trim())
          if (!isNaN(num)) {
            if (num <= 55) root.currentLimit = 50
            else if (num <= 75) root.currentLimit = 70
            else root.currentLimit = 100
          }
        }
        if (lines.length >= 2) {
          var khz = parseInt(lines[1].trim())
          if (!isNaN(khz) && khz > 0) {
            root.currentFreq = (khz / 1000000).toFixed(2) + " GHz"
          }
        }
        if (lines.length >= 3) {
          var maxKhz = parseInt(lines[2].trim())
          if (!isNaN(maxKhz) && maxKhz > 0) {
            root.currentMaxFreq = (maxKhz / 1000000).toFixed(1) + " GHz"
          }
        }
      }
    }
  }

  Process {
    id: writeProcess
    onRunningChanged: {
      if (!running) {
        root.readStatus()
      }
    }
  }

  Component.onCompleted: readStatus()

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dx > 0 || dy > 0) root.stepUp()
        else if (dx < 0 || dy < 0) root.stepDown()
      }

      Column {
        id: contentColumn
        width: parent.width
        spacing: Style.space(12)
        topPadding: Style.space(14)
        bottomPadding: Style.space(14)
        leftPadding: Style.space(16)
        rightPadding: Style.space(16)

        // Header: Microchip Icon, Title & Live Frequency
        Row {
          width: parent.width - parent.leftPadding - parent.rightPadding
          spacing: Style.space(10)

          Text {
            text: "\uf2db"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            width: parent.width - parent.spacing - Style.space(40) - badgeText.implicitWidth
            spacing: Style.space(2)

            Text {
              text: "CPU Clock Speed"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Text {
              text: "Cap: " + root.currentMaxFreq + " • Cur: " + root.currentFreq
              color: Qt.darker(root.barForeground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          Text {
            id: badgeText
            text: (root.busy ? "..." : (root.currentLimit + "%"))
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // 3 Clean Toggles: 50%, 70%, 100%
        Row {
          id: presetRow
          width: parent.width - parent.leftPadding - parent.rightPadding
          spacing: Style.spacing.sm
          readonly property real btnWidth: (width - spacing * 2) / 3

          Repeater {
            model: [
              { pct: 50, label: "50%", desc: "1.0 GHz" },
              { pct: 70, label: "70%", desc: "1.4 GHz" },
              { pct: 100, label: "100%", desc: "2.0 GHz" }
            ]

            Button {
              required property var modelData
              width: presetRow.btnWidth
              text: modelData.label + "\n" + modelData.desc
              fontSize: Style.font.caption
              foreground: root.barForeground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              horizontalPadding: Style.spacing.xs
              verticalPadding: Style.spacing.controlPaddingY + 4
              bordered: true
              enabled: !root.busy
              active: root.currentLimit === modelData.pct
              onClicked: root.setLimit(modelData.pct)
            }
          }
        }

        // Helpful footer note
        Text {
          width: parent.width - parent.leftPadding - parent.rightPadding
          text: "Scroll over CPU icon or use Left/Right keys"
          color: Qt.darker(root.barForeground, 1.6)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
