# example_websocket

What it demonstrates: Running an HTTP server and WebSocket server side by side.

## Features
- HTTP server on port 3000 (Darto)
- WebSocket echo server on port 3001 (DartoWs)
- Both started concurrently with `Future.wait`

## Run
```bash
dart run bin/main.dart
```
Connect a WebSocket client to `ws://localhost:3001` and send any message — it will be echoed back.

<br/>

---

<br/>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
