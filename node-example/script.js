// Traktor API Visualizer Client
const socket = io();

// DOM Elements
const connectionStatus = document.getElementById('connection-status');
const masterDeck = document.getElementById('master-deck');
const masterBpm = document.getElementById('master-bpm');

// Store original BPM for each deck
const deckOriginalBpm = {};

// Deck elements
const deckElements = {
  'A': {
    status: document.getElementById('deck-a-status'),
    title: document.getElementById('deck-a-title'),
    artist: document.getElementById('deck-a-artist'),
    bpm: document.getElementById('deck-a-bpm'),
    key: document.getElementById('deck-a-key')
  },
  'B': {
    status: document.getElementById('deck-b-status'),
    title: document.getElementById('deck-b-title'),
    artist: document.getElementById('deck-b-artist'),
    bpm: document.getElementById('deck-b-bpm'),
    key: document.getElementById('deck-b-key')
  },
  'C': {
    status: document.getElementById('deck-c-status'),
    title: document.getElementById('deck-c-title'),
    artist: document.getElementById('deck-c-artist'),
    bpm: document.getElementById('deck-c-bpm'),
    key: document.getElementById('deck-c-key')
  },
  'D': {
    status: document.getElementById('deck-d-status'),
    title: document.getElementById('deck-d-title'),
    artist: document.getElementById('deck-d-artist'),
    bpm: document.getElementById('deck-d-bpm'),
    key: document.getElementById('deck-d-key')
  }
};

// Channel elements
const channelElements = {
  '1': {
    level: document.getElementById('channel-1-level'),
    value: document.getElementById('channel-1-value'),
    onair: document.getElementById('channel-1-onair')
  },
  '2': {
    level: document.getElementById('channel-2-level'),
    value: document.getElementById('channel-2-value'),
    onair: document.getElementById('channel-2-onair')
  },
  '3': {
    level: document.getElementById('channel-3-level'),
    value: document.getElementById('channel-3-value'),
    onair: document.getElementById('channel-3-onair')
  },
  '4': {
    level: document.getElementById('channel-4-level'),
    value: document.getElementById('channel-4-value'),
    onair: document.getElementById('channel-4-onair')
  }
};

// Browser elements
const browserElements = {
  path: document.getElementById('browser-path'),
  selectedName: document.getElementById('browser-selected-name'),
  selectedArtist: document.getElementById('browser-selected-artist'),
  selectedTitle: document.getElementById('browser-selected-title'),
  selectedBpm: document.getElementById('browser-selected-bpm'),
  position: document.getElementById('browser-position')
};

// Connection events
socket.on('connect', () => {
  connectionStatus.textContent = 'Connected to server';
  connectionStatus.className = 'connection-status text-center mt-3 text-sm text-green-500';
});

socket.on('disconnect', () => {
  connectionStatus.textContent = 'Disconnected from server';
  connectionStatus.className = 'connection-status text-center mt-3 text-sm text-red-500';
});

// Initial data
socket.on('initialData', (data) => {
  // Update decks
  Object.keys(data.decks).forEach(deckId => {
    updateDeck(deckId, data.decks[deckId]);
  });
  
  // Update channels
  Object.keys(data.channels).forEach(channelId => {
    updateChannel(channelId, data.channels[channelId]);
  });
  
  // Update master clock
  updateMasterClock(data.masterClock);
  
  // Update browser
  updateBrowser(data.browser);
});

// Deck events
socket.on('deckLoaded', (data) => {
  // Store the original BPM when a track is loaded
  if (data.data && data.data.bpm) {
    deckOriginalBpm[data.deck] = data.data.bpm;
  }
  updateDeck(data.deck, data.data);
});

socket.on('updateDeck', (data) => {
  updateDeck(data.deck, data.data);
});

// Master clock event
socket.on('updateMasterClock', (data) => {
  updateMasterClock(data);
});

// Channel event
socket.on('updateChannel', (data) => {
  updateChannel(data.channel, data.data);
});

// Update deck display
function updateDeck(deckId, data) {
  const elements = deckElements[deckId];
  if (!elements) return;
  
  // Update track info
  elements.title.textContent = data.title || 'No track loaded';
  elements.artist.textContent = data.artist || '-';
  
  // Update BPM - use original BPM multiplied by tempo factor
  if (data.tempo !== undefined) {
    // If we have tempo data, use it to calculate the current BPM
    const originalBpm = deckOriginalBpm[deckId] || (data.bpm || 0);
    const calculatedBpm = originalBpm * data.tempo;
    elements.bpm.textContent = calculatedBpm.toFixed(2);
  } else if (data.bpm !== undefined) {
    // If we have direct BPM data (from deckLoaded), store it and display it
    deckOriginalBpm[deckId] = data.bpm;
    elements.bpm.textContent = data.bpm.toFixed(2);
  } else if (!deckOriginalBpm[deckId]) {
    // If we have no BPM data at all, show 0.00
    elements.bpm.textContent = '0.00';
  }
  
  // Update key
  elements.key.textContent = data.resultingKey || data.keyText || data.key || '-';
  
  // Update status indicator
  elements.status.classList.remove('bg-red-500', 'bg-green-500', 'bg-blue-500', 'playing', 'synced');
  
  if (data.isPlaying) {
    elements.status.classList.add('bg-green-500', 'playing');
  } else if (data.isSynced) {
    elements.status.classList.add('bg-blue-500', 'synced');
  } else {
    elements.status.classList.add('bg-red-500');
  }
}

// Update master clock display
function updateMasterClock(data) {
  masterDeck.textContent = data.deck || '-';
  masterBpm.textContent = data.bpm ? data.bpm.toFixed(2) : '0.00';
}

// Update channel display
function updateChannel(channelId, data) {
  const elements = channelElements[channelId];
  if (!elements) return;
  
  // Update level meter
  if (data.onAirLevel !== undefined) {
    const percentage = Math.min(100, Math.max(0, data.onAirLevel * 100));
    elements.level.style.height = `${percentage}%`;
    elements.value.textContent = `${percentage.toFixed(0)}%`;
  }
  
  // Update on-air indicator
  elements.onair.classList.toggle('visible', !!data.isOnAir);
}
