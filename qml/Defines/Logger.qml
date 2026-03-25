import QtQuick 2.0

/**
 * DebugLogger: Send debug messages to the Traktor Logger Server
 * 
 * Usage:
 *   import "../path/to/traktor-logger/qml" as DebugLog
 *   
 *   property DebugLog.Logger logger: DebugLog.Logger {}
 *   
 *   Component.onCompleted: {
 *       logger.log("Hello world")
 *       logger.warn("This is a warning")
 *       logger.error("An error occurred")
 *       logger.debug("Debug info", { value: 42, name: "test" })
 *   }
 * 
 * Log levels: debug, info, warn, error
 * Server runs at: http://localhost:8080
 */

Item {
    id: root

    /**
     * Send a debug message and optional data
     * @param message {string} The log message
     * @param data {object} Optional JSON object with additional data
     */
    function debug(message, data) {
        sendLog("debug", message, data)
    }

    /**
     * Send an info message and optional data
     * @param message {string} The log message
     * @param data {object} Optional JSON object with additional data
     */
    function info(message, data) {
        sendLog("info", message, data)
    }

    /**
     * Send a warning message and optional data
     * @param message {string} The log message
     * @param data {object} Optional JSON object with additional data
     */
    function warn(message, data) {
        sendLog("warn", message, data)
    }

    /**
     * Send an error message and optional data
     * @param message {string} The log message
     * @param data {object} Optional JSON object with additional data
     */
    function error(message, data) {
        sendLog("error", message, data)
    }

    /**
     * Alias for info() - shorter syntax
     * @param message {string} The log message
     * @param data {object} Optional JSON object with additional data
     */
    function log(message, data) {
        sendLog("info", message, data)
    }

    /**
     * Send deck state metadata (play state, BPM, track info, etc)
     * @param deckId {int} Deck number (0, 1, 2, 3)
     * @param state {object} Deck state object with properties like:
     *   - isPlaying, title, artist, bpm, tempo, key, elapsed_time, track_length
     */
    function sendDeckState(deckId, state) {
        sendMetadata("deck/" + deckId, state)
    }

    /**
     * Send master clock metadata (BPM, tempo)
     * @param state {object} Master state with bpm, tempo, etc
     */
    function sendMasterState(state) {
        sendMetadata("master", state)
    }

    /**
     * Send playlist/browser metadata
     * @param state {object} Playlist info with name, track count, selected track, etc
     */
    function sendPlaylistState(state) {
        sendMetadata("playlist", state)
    }

    /**
     * Send generic metadata to server
     * @param type {string} Metadata type (e.g., "deck/1", "master", "playlist")
     * @param state {object} State object to send
     */
    function sendMetadata(type, state) {
        var xhr = new XMLHttpRequest()
        var payload = {
            type: type,
            state: state || {},
            timestamp: new Date().toISOString()
        }

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status !== 200 && xhr.status !== 204) {
                    console.warn("[DebugLogger] Metadata error:", xhr.status)
                }
            }
        }

        try {
            xhr.open("POST", "http://localhost:8080/metadata", true)
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.send(JSON.stringify(payload))
        } catch (e) {
            console.warn("[DebugLogger] Failed to send metadata:", e.toString())
        }
    }

    /**
     * Internal: Send log to server via HTTP POST
     */
    function sendLog(level, message, data) {
        var xhr = new XMLHttpRequest()
        var payload = {
            level: level,
            message: String(message),
            data: data || null
        }

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status !== 200) {
                    console.warn("[DebugLogger] Server error:", xhr.status)
                }
            }
        }

        try {
            xhr.open("POST", "http://localhost:8080/log", true)
            xhr.setRequestHeader("Content-Type", "application/json")
            xhr.send(JSON.stringify(payload))
        } catch (e) {
            console.warn("[DebugLogger] Failed to send log:", e.toString())
        }
    }
}
