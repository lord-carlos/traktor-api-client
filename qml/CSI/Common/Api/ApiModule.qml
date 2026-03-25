// Based on traktor-api-client by ErikMinekus
// MIT License - https://github.com/ErikMinekus/traktor-api-client
// Merged with traktor-logger for combined functionality

import CSI 1.0

Module {
  ApiChannel { index: 1 }
  ApiChannel { index: 2 }
  ApiChannel { index: 3 }
  ApiChannel { index: 4 }

  ApiDeck { deckId: 0 }
  ApiDeck { deckId: 1 }
  ApiDeck { deckId: 2 }
  ApiDeck { deckId: 3 }

  ApiMasterClock {}
}
