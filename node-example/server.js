const express = require('express');
const bodyParser = require('body-parser');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const port = 8080;
const webPort = 8081;

// Middleware to parse JSON bodies
app.use(bodyParser.json());

// Serve static files from the visualizer directory
app.use(express.static(path.join(__dirname)));

// Serve the main visualization page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Serve individual deck pages
app.get('/:deck', (req, res) => {
  const deck = req.params.deck.toLowerCase();
  if (['a', 'b', 'c', 'd'].includes(deck)) {
    res.sendFile(path.join(__dirname, 'deck.html'));
  } else {
    res.status(404).send('Deck not found');
  }
});

// Store the latest data for new connections
let latestData = {
  decks: {},
  channels: {},
  masterClock: {},
  browser: {}
};

// Log all requests and broadcast data
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Endpoint for deck loaded
app.post('/deckLoaded/:deck', (req, res) => {
  console.log(`Deck ${req.params.deck} loaded with track:`, req.body.title || 'Unknown');
  const deckData = {
    ...req.body,
    timestamp: new Date().toISOString()
  };
  latestData.decks[req.params.deck] = deckData;
  io.emit('deckLoaded', { deck: req.params.deck, data: deckData });
  res.status(200).send('OK');
});

// Endpoint for deck updates
app.post('/updateDeck/:deck', (req, res) => {
  console.log(`Deck ${req.params.deck} updated:`, req.body);
  const deckData = {
    ...latestData.decks[req.params.deck],
    ...req.body,
    timestamp: new Date().toISOString()
  };
  latestData.decks[req.params.deck] = deckData;
  io.emit('updateDeck', { deck: req.params.deck, data: deckData });
  res.status(200).send('OK');
});

// Endpoint for master clock updates
app.post('/updateMasterClock', (req, res) => {
  console.log('Master clock updated:', req.body);
  const masterData = {
    ...req.body,
    timestamp: new Date().toISOString()
  };
  latestData.masterClock = masterData;
  io.emit('updateMasterClock', masterData);
  res.status(200).send('OK');
});

// Endpoint for channel updates
app.post('/updateChannel/:channel', (req, res) => {
  console.log(`Channel ${req.params.channel} updated:`, req.body);
  const channelData = {
    ...latestData.channels[req.params.channel],
    ...req.body,
    timestamp: new Date().toISOString()
  };
  latestData.channels[req.params.channel] = channelData;
  io.emit('updateChannel', { channel: req.params.channel, data: channelData });
  res.status(200).send('OK');
});

// Endpoint for browser updates
app.post('/updateBrowser', (req, res) => {
  console.log('Browser updated:', req.body);
  const browserData = {
    ...latestData.browser,
    ...req.body,
    timestamp: new Date().toISOString()
  };
  latestData.browser = browserData;
  io.emit('updateBrowser', browserData);
  res.status(200).send('OK');
});

// Handle WebSocket connections
io.on('connection', (socket) => {
  console.log('Visualization client connected');
  
  // Send latest data to new connections
  socket.emit('initialData', latestData);
  
  socket.on('disconnect', () => {
    console.log('Visualization client disconnected');
  });
});

// Start API server (listen on all interfaces)
app.listen(port, '0.0.0.0', () => {
  console.log(`Traktor API server listening at http://0.0.0.0:${port}`);
  console.log(`(Accessible from other devices on the network)`);
});

// Start web server for visualization (listen on all interfaces)
server.listen(webPort, '0.0.0.0', () => {
  const networkInterfaces = require('os').networkInterfaces();
  console.log(`Visualization server listening at http://0.0.0.0:${webPort}`);
  console.log(`(Accessible from other devices on the network)`);
  console.log(`Local access:`);
  console.log(`  Main visualization: http://localhost:${webPort}/`);
  console.log(`  Deck A view: http://localhost:${webPort}/a`);
  console.log(`  Deck B view: http://localhost:${webPort}/b`);
  console.log(`  Deck C view: http://localhost:${webPort}/c`);
  console.log(`  Deck D view: http://localhost:${webPort}/d`);
  console.log(`
Network access (from other devices):`);
  
  // Show all network interfaces
  Object.keys(networkInterfaces).forEach(interfaceName => {
    const interfaces = networkInterfaces[interfaceName];
    interfaces.forEach(interface => {
      if (!interface.internal && interface.family === 'IPv4') {
        console.log(`  Main visualization: http://${interface.address}:${webPort}/`);
        console.log(`  Deck A view: http://${interface.address}:${webPort}/a`);
        console.log(`  Deck B view: http://${interface.address}:${webPort}/b`);
        console.log(`  Deck C view: http://${interface.address}:${webPort}/c`);
        console.log(`  Deck D view: http://${interface.address}:${webPort}/d`);
      }
    });
  });
});