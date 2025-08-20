"""
Traktor D2 API Client Example

This is a simple example showing how to receive data from the Traktor D2 API client.
The D2 controller sends data to a web server running on http://localhost:8080.

Endpoints:
- /deckLoaded/<deck>: Called when a track is loaded into a deck (A, B, C, D)
- /updateDeck/<deck>: Called when deck values or state changes
- /updateMasterClock: Called when the master deck or BPM changes
- /updateChannel/<channel>: Called when mixer channel state changes (1, 2, 3, 4)

To use this example:
1. Make sure Traktor Pro is running with the modified D2 controller
2. Run this script: python traktor_api_example.py
3. Load tracks and interact with Traktor to see the data flow
"""

import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Store the latest data for reference
latest_data = {
    'decks': {},
    'channels': {},
    'master_clock': {},
    'browser': {}
}

class TraktorAPIHandler(BaseHTTPRequestHandler):
    """Handle incoming requests from the Traktor D2 API client"""
    
    def do_POST(self):
        """Handle POST requests from the Traktor D2 API"""
        # Get the content length
        content_length = int(self.headers['Content-Length'])
        
        # Read the POST data
        post_data = self.rfile.read(content_length)
        
        # Parse JSON data
        try:
            data = json.loads(post_data.decode('utf-8'))
        except json.JSONDecodeError:
            print("Error: Could not decode JSON data")
            self.send_response(400)
            self.end_headers()
            return
        
        # Parse the URL to determine the endpoint
        parsed_path = urlparse(self.path)
        path_parts = parsed_path.path.strip('/').split('/')
        
        # Handle different endpoints
        if len(path_parts) >= 2 and path_parts[0] == 'deckLoaded':
            deck = path_parts[1]
            self.handle_deck_loaded(deck, data)
        elif len(path_parts) >= 2 and path_parts[0] == 'updateDeck':
            deck = path_parts[1]
            self.handle_deck_update(deck, data)
        elif path_parts[0] == 'updateMasterClock':
            self.handle_master_clock_update(data)
        elif len(path_parts) >= 2 and path_parts[0] == 'updateChannel':
            channel = path_parts[1]
            self.handle_channel_update(channel, data)
        else:
            print(f"Unknown endpoint: {self.path}")
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'OK')
    
    def handle_deck_loaded(self, deck, data):
        """Handle when a track is loaded into a deck"""
        print(f"\n--- Deck {deck} Loaded ---")
        print(f"Title: {data.get('title', 'Unknown')}")
        print(f"Artist: {data.get('artist', 'Unknown')}")
        print(f"Album: {data.get('album', 'Unknown')}")
        print(f"BPM: {data.get('bpm', 0.00):.2f}")
        print(f"Key: {data.get('key', 'Unknown')}")
        
        # Store the data
        latest_data['decks'][deck] = data
    
    def handle_deck_update(self, deck, data):
        """Handle when a deck's state changes"""
        # Only print if there's interesting data to show
        if any(key in data for key in ['isPlaying', 'isSynced', 'tempo', 'elapsedTime']):
            print(f"\n--- Deck {deck} Update ---")
            
            if 'isPlaying' in data:
                status = "Playing" if data['isPlaying'] else "Stopped"
                print(f"Status: {status}")
            
            if 'isSynced' in data:
                sync_status = "Synced" if data['isSynced'] else "Not Synced"
                print(f"Sync: {sync_status}")
            
            if 'tempo' in data:
                print(f"Tempo: {data['tempo']:.2f}")
            
            if 'elapsedTime' in data:
                elapsed = data['elapsedTime']
                minutes = int(elapsed // 60)
                seconds = int(elapsed % 60)
                print(f"Elapsed Time: {minutes:02d}:{seconds:02d}")
        
        # Update stored data
        if deck in latest_data['decks']:
            latest_data['decks'][deck].update(data)
        else:
            latest_data['decks'][deck] = data
    
    def handle_master_clock_update(self, data):
        """Handle when the master clock changes"""
        print(f"\n--- Master Clock Update ---")
        print(f"Master Deck: {data.get('deck', 'None')}")
        print(f"BPM: {data.get('bpm', 0.00):.2f}")
        
        # Store the data
        latest_data['master_clock'] = data
    
    def handle_channel_update(self, channel, data):
        """Handle when a mixer channel's state changes"""
        # Only print if there's interesting data to show
        if any(key in data for key in ['onAirLevel', 'isOnAir']):
            print(f"\n--- Channel {channel} Update ---")
            
            if 'onAirLevel' in data:
                level = data['onAirLevel'] * 100  # Convert to percentage
                print(f"Level: {level:.1f}%")
            
            if 'isOnAir' in data:
                on_air = "On Air" if data['isOnAir'] else "Off Air"
                print(f"Status: {on_air}")
        
        # Update stored data
        if channel in latest_data['channels']:
            latest_data['channels'][channel].update(data)
        else:
            latest_data['channels'][channel] = data
    
    def log_message(self, format, *args):
        """Override to disable default logging"""
        return

def run_server(port=8080):
    """Run the Traktor API server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, TraktorAPIHandler)
    
    print(f"Traktor D2 API Example Server")
    print(f"Listening on http://localhost:{port}")
    print(f"Waiting for data from Traktor D2 controller...")
    print(f"Press Ctrl+C to stop the server")
    print("-" * 50)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
        httpd.server_close()

if __name__ == '__main__':
    run_server()
