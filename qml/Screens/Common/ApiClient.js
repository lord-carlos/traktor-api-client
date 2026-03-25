// Based on traktor-api-client by ErikMinekus
// MIT License - https://github.com/ErikMinekus/traktor-api-client
// Merged with traktor-logger for combined metadata + manual logging

var API_BASE_URL = "http://localhost:8080"

function send(endpoint, data) {
    var request = new XMLHttpRequest(),
        body = JSON.stringify(data)

    request.open("POST", API_BASE_URL + "/" + endpoint, true)
    request.setRequestHeader("Content-Type", "application/json")
    request.setRequestHeader("Content-Length", body.length)
    request.send(body)
}

function sendMetadata(type, state) {
    var request = new XMLHttpRequest(),
        body = JSON.stringify({
            type: type,
            state: state || {},
            timestamp: new Date().toISOString()
        })

    request.open("POST", API_BASE_URL + "/metadata", true)
    request.setRequestHeader("Content-Type", "application/json")
    request.setRequestHeader("Content-Length", body.length)
    request.send(body)
}
