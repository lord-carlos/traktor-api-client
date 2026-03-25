// Based on traktor-api-client by ErikMinekus
// MIT License - https://github.com/ErikMinekus/traktor-api-client
// Merged with traktor-logger for combined functionality

import CSI 1.0
import QtQuick 2.0
import "ApiClient.js" as ApiClient

Item {
  property int       deckId:  0

  property var       hotcueExists:  []
  property var       hotcuePos:     []
  property var       hotcueName:    []
  property var       hotcueType:    []

  readonly property string    deckLetter:   String.fromCharCode(65 + deckId)
  readonly property var       hotcueTypes:  ["cue", "fadeIn", "fadeOut", "load", "grid", "loop"]
  readonly property string    pathPrefix:   "app.traktor.decks." + (deckId+1) + "."

  AppProperty { path: pathPrefix + "is_loaded";         onValueChanged: deckLoadedTimer.start() }
  AppProperty { path: pathPrefix + "is_loaded_signal";  onValueChanged: deckLoadedTimer.start() }

  AppProperty { id: propTitle;         path: pathPrefix + "content.title" }
  AppProperty { id: propArtist;        path: pathPrefix + "content.artist" }
  AppProperty { id: propAlbum;         path: pathPrefix + "content.album" }
  AppProperty { id: propGenre;         path: pathPrefix + "content.genre" }
  AppProperty { id: propComment;       path: pathPrefix + "content.comment" }
  AppProperty { id: propComment2;      path: pathPrefix + "content.comment2" }
  AppProperty { id: propLabel;         path: pathPrefix + "content.label" }
  AppProperty { id: propMix;           path: pathPrefix + "content.mix" }
  AppProperty { id: propRemixer;       path: pathPrefix + "content.remixer" }
  AppProperty { id: propKey;           path: pathPrefix + "content.musical_key" }
  AppProperty { id: propKeyText;       path: pathPrefix + "content.legacy_key" }
  AppProperty { id: propGridOffset;    path: pathPrefix + "content.grid_offset" }
  AppProperty { id: propFilePath;      path: pathPrefix + "track.content.file_path" }
  AppProperty { id: propTrackLength;   path: pathPrefix + "track.content.track_length" }
  AppProperty { id: propElapsedTime;   path: pathPrefix + "track.player.elapsed_time" }
  AppProperty { id: propNextCuePoint;  path: pathPrefix + "track.player.next_cue_point";  onValueChanged: nextCueChangedTimer.restart() }
  AppProperty { id: propBpm;           path: pathPrefix + "tempo.base_bpm" }
  AppProperty { id: propTempo;         path: pathPrefix + "tempo.tempo_for_display";      onValueChanged: tempoChangedTimer.restart() }
  AppProperty { id: propResultingKey;  path: pathPrefix + "track.key.resulting.precise";  onValueChanged: keyChangedTimer.restart() }
  AppProperty { id: propDeckType;      path: pathPrefix + "type";                          onValueChanged: deckTypeChangedTimer.restart() }
  AppProperty { id: propActiveSlot;    path: pathPrefix + "active_slot";                   onValueChanged: deckTypeChangedTimer.restart() }

  // Stem properties (stems 1-4)
  AppProperty { id: propStem1Volume;    path: pathPrefix + "stems.1.volume";       onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem1Filter;    path: pathPrefix + "stems.1.filter_value"; onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem1FilterOn;  path: pathPrefix + "stems.1.filter_on";    onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem2Volume;    path: pathPrefix + "stems.2.volume";       onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem2Filter;    path: pathPrefix + "stems.2.filter_value"; onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem2FilterOn;  path: pathPrefix + "stems.2.filter_on";    onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem3Volume;    path: pathPrefix + "stems.3.volume";       onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem3Filter;    path: pathPrefix + "stems.3.filter_value"; onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem3FilterOn;  path: pathPrefix + "stems.3.filter_on";    onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem4Volume;    path: pathPrefix + "stems.4.volume";       onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem4Filter;    path: pathPrefix + "stems.4.filter_value"; onValueChanged: stemChangedTimer.restart() }
  AppProperty { id: propStem4FilterOn;  path: pathPrefix + "stems.4.filter_on";    onValueChanged: stemChangedTimer.restart() }

  Repeater {
    model: 8

    delegate: Item {
      readonly property string hotcuePathPrefix: pathPrefix + "track.cue.hotcues." + (index+1) + "."

      AppProperty { path: hotcuePathPrefix + "exists";     onValueChanged: hotcueExists[index] = value }
      AppProperty { path: hotcuePathPrefix + "start_pos";  onValueChanged: hotcuePos[index] = value }
      AppProperty { path: hotcuePathPrefix + "name";       onValueChanged: hotcueName[index] = value }
      AppProperty { path: hotcuePathPrefix + "type";       onValueChanged: hotcueType[index] = hotcueTypes[value] }
    }
  }

  AppProperty {
    id: propIsPlaying
    path: pathPrefix + "play"

    onValueChanged: {
      ApiClient.send("updateDeck/" + deckLetter, {
        elapsedTime: propElapsedTime.value,
        isPlaying: propIsPlaying.value,
      })
    }
  }
  AppProperty {
    id: propIsSynced
    path: pathPrefix + "sync.enabled"

    onValueChanged: {
      ApiClient.send("updateDeck/" + deckLetter, {
        isSynced: propIsSynced.value,
      })
    }
  }
  AppProperty {
    id: propIsKeyLockOn
    path: pathPrefix + "track.key.lock_enabled"

    onValueChanged: {
      ApiClient.send("updateDeck/" + deckLetter, {
        isKeyLockOn: propIsKeyLockOn.value,
      })
    }
  }

  Timer {
    id: deckLoadedTimer
    interval: 250

    onTriggered: {
      var cueIdxs = findCueIdxs()

      ApiClient.send("deckLoaded/" + deckLetter, {
        filePath:     getFilePath(),
        title:        propTitle.value,
        artist:       propArtist.value,
        album:        propAlbum.value,
        genre:        propGenre.value,
        comment:      propComment.value,
        comment2:     propComment2.value,
        label:        propLabel.value,
        mix:          propMix.value,
        remixer:      propRemixer.value,
        key:          propKey.value,
        keyText:      propKeyText.value,
        gridOffset:   propGridOffset.value/1000,
        trackLength:  propTrackLength.value,
        elapsedTime:  propElapsedTime.value,
        nextCuePos:   getOrNull(hotcuePos, cueIdxs.next),
        nextCueName:  getOrNull(hotcueName, cueIdxs.next),
        nextCueType:  getOrNull(hotcueType, cueIdxs.next),
        prevCuePos:   getOrNull(hotcuePos, cueIdxs.prev),
        prevCueName:  getOrNull(hotcueName, cueIdxs.prev),
        prevCueType:  getOrNull(hotcueType, cueIdxs.prev),
        bpm:          propBpm.value,
        tempo:        propTempo.value,
        resultingKey: propResultingKey.value,
        deckType:     propDeckType.value,
        activeSlot:   propActiveSlot.value,
        isPlaying:    propIsPlaying.value,
        isSynced:     propIsSynced.value,
        isKeyLockOn:  propIsKeyLockOn.value,
      })
      
      // If this is a stem deck (type 2), send initial stem data
      if (propDeckType.value === 2) {
        stemChangedTimer.restart()
      }
    }
  }
  Timer {
    id: deckTypeChangedTimer
    interval: 250

    onTriggered: {
      ApiClient.send("updateDeck/" + deckLetter, {
        deckType:   propDeckType.value,
        activeSlot: propActiveSlot.value,
      })
    }
  }
  Timer {
    id: stemChangedTimer
    interval: 250

    onTriggered: {
      ApiClient.send("updateDeckStems/" + deckLetter, {
        stems: [
          { volume: propStem1Volume.value, filter: propStem1Filter.value, filterOn: propStem1FilterOn.value },
          { volume: propStem2Volume.value, filter: propStem2Filter.value, filterOn: propStem2FilterOn.value },
          { volume: propStem3Volume.value, filter: propStem3Filter.value, filterOn: propStem3FilterOn.value },
          { volume: propStem4Volume.value, filter: propStem4Filter.value, filterOn: propStem4FilterOn.value }
        ]
      })
    }
  }
  Timer {
    id: tempoChangedTimer
    interval: 250

    onTriggered: {
      ApiClient.send("updateDeck/" + deckLetter, {
        tempo: propTempo.value,
      })
    }
  }
  Timer {
    id: keyChangedTimer
    interval: 250

    onTriggered: {
      ApiClient.send("updateDeck/" + deckLetter, {
        resultingKey: propResultingKey.value,
      })
    }
  }
  Timer {
    id: nextCueChangedTimer
    interval: 250

    onTriggered: {
      var cueIdxs = findCueIdxs()

      ApiClient.send("updateDeck/" + deckLetter, {
        nextCuePos: getOrNull(hotcuePos, cueIdxs.next),
        nextCueName: getOrNull(hotcueName, cueIdxs.next),
        nextCueType: getOrNull(hotcueType, cueIdxs.next),
        prevCuePos: getOrNull(hotcuePos, cueIdxs.prev),
        prevCueName: getOrNull(hotcueName, cueIdxs.prev),
        prevCueType: getOrNull(hotcueType, cueIdxs.prev),
      })
    }
  }
  Timer {
    interval: 1000
    repeat: true
    running: propIsPlaying.value

    onTriggered: {
      ApiClient.send("updateDeck/" + deckLetter, {
        elapsedTime: propElapsedTime.value,
      })
    }
  }

  function findCueIdxs() {
    var hotcueIdxs = getHotcueOrder()
    var nextCuePos = propNextCuePoint.value/1000
    var prevCueIdx = null

    if (propNextCuePoint.value == -1)
      return { next: null, prev: getOrNull(hotcueIdxs, hotcueIdxs.length - 1) }

    for (var i = 0; i < hotcueIdxs.length; i++) {
      var idx = hotcueIdxs[i]
      if (Math.abs(hotcuePos[idx] - nextCuePos) < 0.00001)
        return { next: idx, prev: prevCueIdx }

      prevCueIdx = idx
    }

    return { next: null, prev: prevCueIdx }
  }
  function getFilePath() {
    if (!propFilePath.value) return ""

    return /^[A-Z]:\\/.test(propFilePath.value) || /^\//.test(propFilePath.value)
      ? propFilePath.value
      : "/Volumes/" + propFilePath.value.replace(/:/g, "/")
  }
  function getHotcueOrder() {
    var hotcueIdxs = []
    for (var i = 0; i < hotcueExists.length; i++) {
      if (hotcueExists[i]) {
        hotcueIdxs.push(i)
      }
    }

    hotcueIdxs.sort(function(a, b) { return hotcuePos[a] - hotcuePos[b] })

    return hotcueIdxs
  }
  function getOrNull(array, index) {
    return array[index] !== undefined ? array[index] : null
  }
}
