// Browser metadata monitor — Screens-layer component.
// Must live in Screens/ so that Traktor.Gui 1.0 is available.
// Instantiate once per controller from Screen.qml.
//
// For controllers whose Screen.qml is instantiated per-screen (e.g. S4MK3
// left + right), set active: false on the second instance to suppress
// duplicate sends:
//
//   import "../Common" as LoggerScreens
//   LoggerScreens.ApiBrowser { active: isLeftScreen }

import QtQuick 2.0
import Traktor.Gui 1.0 as Traktor
import "ApiClient.js" as ApiClient

Item {
  id: apiBrowser
  // Zero size + clip keeps this invisible without suppressing child rendering.
  // visible:false would prevent the ListView from instantiating delegates.
  width: 0
  height: 0
  clip: true

  // Set to false on duplicate screen instances to avoid double-posting.
  property bool active: true

  property int pollMs: 250
  property string lastPayload: ""

  // Cache of instantiated delegates keyed by list index.
  // Populated/cleared by delegate onCompleted/onDestruction.
  property var delegateCache: ({})

  Traktor.Browser {
    id: browser
    isActive: true
  }

  ListView {
    id: browserList
    width: 1
    // height covers the window: 10 above + 1 selected + 20 below = 31 items,
    // each 1px tall. StrictlyEnforceRange locks the current item to position
    // 10, so the full window around it stays instantiated.
    height: 31
    clip: true
    model: browser.dataSet
    currentIndex: browser.currentIndex
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: 10
    preferredHighlightEnd: 11

    delegate: Item {
      id: delegateItem
      width: 1
      height: 1
      property var dataType: model.dataType
      property var nodeName: model.nodeName
      property var trackName: model.trackName
      property var artistName: model.artistName
      property var bpm: model.bpm
      property var key: model.key
      property var keyIndex: model.keyIndex
      property var rating: model.rating
      property var prepared: model.prepared
      property var loadedInDeck: model.loadedInDeck

      Component.onCompleted: apiBrowser.delegateCache[index] = delegateItem
      Component.onDestruction: delete apiBrowser.delegateCache[index]
    }
  }

  Timer {
    id: pollTimer
    interval: apiBrowser.pollMs
    repeat: true
    running: apiBrowser.active

    onTriggered: {
      apiBrowser.publishBrowserState()
    }
  }

  function splitPath(pathValue) {
    var raw = String(pathValue || "")
    if (raw.length === 0) {
      return []
    }
    return raw.split(" | ")
  }

  function collectWindowItems() {
    var currentIdx = browser.currentIndex
    var count = browserList.count
    var startIdx = Math.max(0, currentIdx - 10)
    var endIdx = Math.min(count - 1, currentIdx + 20)
    var items = []
    for (var i = startIdx; i <= endIdx; i++) {
      var item = apiBrowser.delegateCache[i]
      if (item) {
        items.push({
          index: i,
          isSelected: i === currentIdx,
          dataType: item.dataType,
          nodeName: item.nodeName || "",
          trackName: item.trackName || "",
          artistName: item.artistName || "",
          bpm: item.bpm !== undefined ? item.bpm : null,
          key: item.key || "",
          keyIndex: item.keyIndex !== undefined ? item.keyIndex : null,
          rating: item.rating !== undefined ? item.rating : null,
          prepared: !!item.prepared,
          loadedInDeck: item.loadedInDeck || []
        })
      }
    }
    return items
  }

  function publishBrowserState() {
    var selected = browserList.currentItem
    var pathSegments = splitPath(browser.currentPath)
    var selectedPlaylist = pathSegments.length > 0 ? pathSegments[pathSegments.length - 1] : ""

    var payload = {
      path: String(browser.currentPath || ""),
      selectedPlaylist: selectedPlaylist,
      selectedIndex: browser.currentIndex,
      listCount: browserList.count,
      isContentList: !!browser.isContentList,
      dataType: selected ? selected.dataType : null,
      nodeName: selected ? (selected.nodeName || "") : "",
      trackName: selected ? (selected.trackName || "") : "",
      artistName: selected ? (selected.artistName || "") : "",
      bpm: selected && selected.bpm !== undefined ? selected.bpm : null,
      key: selected ? (selected.key || "") : "",
      keyIndex: selected && selected.keyIndex !== undefined ? selected.keyIndex : null,
      rating: selected && selected.rating !== undefined ? selected.rating : null,
      prepared: selected ? !!selected.prepared : false,
      loadedInDeck: selected && selected.loadedInDeck ? selected.loadedInDeck : [],
      items: collectWindowItems()
    }

    var serialized = JSON.stringify(payload)
    if (serialized === lastPayload) {
      return
    }

    lastPayload = serialized
    ApiClient.sendMetadata("playlist", payload)
  }
}
