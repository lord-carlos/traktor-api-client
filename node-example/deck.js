// Get deck ID from URL path
const path = window.location.pathname;
const deckId = path.substring(1).toUpperCase() || 'A';

// DOM Elements
const deckTitle = document.getElementById('deck-title');
const statusIndicator = document.getElementById('status-indicator');
const syncStatus = document.getElementById('sync-status');
const keyLockStatus = document.getElementById('key-lock-status');
const trackTitle = document.getElementById('track-title');
const trackArtist = document.getElementById('track-artist');
const bpmDisplay = document.getElementById('bpm-display');
const keyDisplay = document.getElementById('key-display');
const progressBar = document.getElementById('progress-bar');
const progressMarker = document.getElementById('progress-marker');
const elapsedTime = document.getElementById('elapsed-time');
const remainingTime = document.getElementById('remaining-time');
const connectionStatus = document.getElementById('connection-status');
const fullscreenToggle = document.getElementById('fullscreen-toggle');
const body = document.body;

// Store original BPM from deckLoaded
let originalBpm = 0;

// Set deck title and theme
deckTitle.textContent = `Deck ${deckId}`;
document.body.classList.add(`deck-${deckId.toLowerCase()}-theme`);

// Determine the WebSocket URL based on the current page URL
function getWebSocketUrl() {
    const loc = window.location;
    const protocol = loc.protocol === 'https:' ? 'wss:' : 'ws:';
    return `${protocol}//${loc.host}`;
}

// Fullscreen functionality
function toggleFullscreen() {
    if (!document.fullscreenElement) {
        if (body.requestFullscreen) {
            body.requestFullscreen();
        } else if (body.webkitRequestFullscreen) { // Safari
            body.webkitRequestFullscreen();
        } else if (body.msRequestFullscreen) { // IE11
            body.msRequestFullscreen();
        }
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (document.webkitExitFullscreen) { // Safari
            document.webkitExitFullscreen();
        } else if (document.msExitFullscreen) { // IE11
            document.msExitFullscreen();
        }
    }
}

// Double tap for fullscreen
let lastTap = 0;
document.addEventListener('touchend', function(e) {
    const currentTime = new Date().getTime();
    const tapLength = currentTime - lastTap;
    if (tapLength < 500 && tapLength > 0) {
        toggleFullscreen();
        e.preventDefault();
    }
    lastTap = currentTime;
});

// Click on fullscreen button
fullscreenToggle.addEventListener('click', toggleFullscreen);

// Connect to WebSocket server using dynamic URL
const socket = io(getWebSocketUrl());

// Connection events
socket.on('connect', () => {
    connectionStatus.textContent = 'Connected to server';
    connectionStatus.className = 'connection-status text-center text-sm text-green-500 mt-4';
});

socket.on('disconnect', () => {
    connectionStatus.textContent = 'Disconnected from server';
    connectionStatus.className = 'connection-status text-center text-sm text-red-500 mt-4';
});

// Initial data
socket.on('initialData', (data) => {
    const deckData = data.decks[deckId];
    if (deckData) {
        updateDeckDisplay(deckData);
    }
});

// Deck updates
socket.on('updateDeck', (data) => {
    if (data.deck === deckId) {
        updateDeckDisplay(data.data);
    }
});

socket.on('deckLoaded', (data) => {
    if (data.deck === deckId) {
        // Store the original BPM when a track is loaded
        originalBpm = data.data.bpm || 0;
        updateDeckDisplay(data.data);
    }
});

// Update deck display
function updateDeckDisplay(data) {
    // Update track info
    trackTitle.textContent = data.title || 'No track loaded';
    trackArtist.textContent = data.artist || '-';
    
    // Update BPM - use original BPM multiplied by tempo factor
    const tempo = data.tempo || 1.0;
    const calculatedBpm = originalBpm * tempo;
    bpmDisplay.textContent = calculatedBpm.toFixed(2);
    
    // Update key
    keyDisplay.textContent = data.resultingKey || data.keyText || data.key || '-';
    
    // Update status indicators
    if (data.isPlaying) {
        statusIndicator.className = 'status-indicator status-playing';
    } else if (data.isSynced) {
        statusIndicator.className = 'status-indicator status-synced';
    } else {
        statusIndicator.className = 'status-indicator status-stopped';
    }
    
    // Update sync status
    const syncIndicator = syncStatus.querySelector('.status-indicator');
    if (data.isSynced) {
        syncIndicator.className = 'status-indicator status-synced';
    } else {
        syncIndicator.className = 'status-indicator status-stopped';
    }
    
    // Update key lock status
    const keyLockIndicator = keyLockStatus.querySelector('.status-indicator');
    if (data.isKeyLockOn) {
        keyLockIndicator.className = 'status-indicator status-playing';
    } else {
        keyLockIndicator.className = 'status-indicator status-stopped';
    }
    
    // Update progress
    if (data.trackLength && data.elapsedTime !== undefined) {
        const elapsed = data.elapsedTime;
        const total = data.trackLength;
        const progressPercent = (total > 0) ? (elapsed / total) * 100 : 0;
        
        progressBar.style.width = `${Math.min(100, progressPercent)}%`;
        progressMarker.style.left = `${Math.min(100, progressPercent)}%`;
        
        // Update time displays
        elapsedTime.textContent = formatTime(elapsed);
        remainingTime.textContent = `-${formatTime(total - elapsed)}`;
    }
}

// Format time as MM:SS
function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}