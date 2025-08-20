# Traktor D2 API Python Example

This is a simple Python example that demonstrates how to receive data from the Traktor D2 API client. It shows how to set up a basic server that listens for events from Traktor Pro and processes the data.

## Features

- Receives data from all Traktor D2 API endpoints
- Processes deck loading events
- Handles deck state updates
- Monitors master clock changes
- Tracks mixer channel updates
- Simple command-line output

## Requirements

- Python 3.6 or higher (no external dependencies)

## Usage

1. Make sure Traktor Pro is running with the modified D2 controller
2. Run the example script:
   ```bash
   python traktor_api_example.py
   ```
3. Load tracks and interact with Traktor to see the data flow

## Endpoints

The server listens on `http://localhost:8080` for the following endpoints:

- `/deckLoaded/<deck>`: Called when a track is loaded into a deck (A, B, C, D)
- `/updateDeck/<deck>`: Called when deck values or state changes
- `/updateMasterClock`: Called when the master deck or BPM changes
- `/updateChannel/<channel>`: Called when mixer channel state changes (1, 2, 3, 4)

## Example Output

```
Traktor D2 API Example Server
Listening on http://localhost:8080
Waiting for data from Traktor D2 controller...
--------------------------------------------------

--- Deck A Loaded ---
Title: Technologic
Artist: Daft Punk
Album: Human After All
BPM: 120.00
Key: A minor

--- Deck A Update ---
Status: Playing
Tempo: 120.00
Elapsed Time: 00:30

--- Master Clock Update ---
Master Deck: A
BPM: 120.00

--- Channel 1 Update ---
Level: 85.5%
Status: On Air
```

## How It Works

The script uses Python's built-in `http.server` module to create a simple HTTP server that handles POST requests from the Traktor D2 controller. When Traktor sends data, the server parses the JSON payload and prints relevant information to the console.

This example is meant to be a starting point for developers who want to build their own applications that interact with Traktor Pro through the D2 API.