# WebSocket Server Documentation

O WebSocketServer do Darto fornece uma API simples e familiar para trabalhar com WebSockets, inspirada no Node.js e Socket.io.

## Índice

- [Configuração Básica](#configuração-básica)
- [Eventos Globais](#eventos-globais)
- [Métodos do Socket](#métodos-do-socket)
- [Broadcasting](#broadcasting)
- [Middlewares](#middlewares)
- [Exemplos Práticos](#exemplos-práticos)
- [Cliente JavaScript](#cliente-javascript)

## Configuração Básica

### Inicializando o WebSocket Server

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  // Cria uma instância do WebSocket server
  final ws = WebSocketServer();

  // Integra o WebSocket server com o Darto
  app.useWebSocket(ws);

  // Inicia o servidor HTTP na porta 8080
  app.listen(8080);
}
```

## Eventos Globais

O WebSocketServer suporta os seguintes eventos globais:

### connection

Disparado quando um novo cliente se conecta ao servidor.

```dart
// Registra um handler para novas conexões
ws.on('connection', (socket) {
  print('Novo cliente conectado: ${socket.id}');

  // Envia uma mensagem de boas-vindas para o cliente recém-conectado
  socket.emit('welcome', 'Bem-vindo ao servidor!');
});
```

### error

Disparado quando ocorre um erro na conexão WebSocket.

```dart
// Registra um handler para erros de conexão
ws.on('error', (socket) {
  print('Erro na conexão WebSocket: ${socket.id}');

  // Fecha a conexão em caso de erro
  socket.destroy();
});
```

### open

Disparado quando uma conexão WebSocket é aberta.

```dart
// Registra um handler para quando a conexão é aberta
ws.on('open', (socket) {
  print('Conexão WebSocket aberta: ${socket.id}');
});
```

### close

Disparado quando uma conexão WebSocket é fechada.

```dart
// Registra um handler para quando a conexão é fechada
ws.on('close', (socket) {
  print('Conexão WebSocket fechada: ${socket.id}');
});
```

### message

Disparado quando uma mensagem é recebida de qualquer cliente.

```dart
// Registra um handler global para mensagens
ws.on('message', (socket) {
  print('Mensagem recebida do cliente: ${socket.id}');
});
```

## Métodos do Socket

### emit(event, data)

Envia um evento específico com dados para o cliente conectado.

```dart
ws.on('connection', (socket) {
  // Envia um evento 'notification' com dados dinâmicos
  socket.emit('notification', {
    'type': 'info',
    'message': 'Você está conectado!',
    'timestamp': DateTime.now().toIso8601String(),
  });

  // Envia dados de diferentes tipos
  socket.emit('userCount', 42); // Número
  socket.emit('status', 'online'); // String
  socket.emit('config', ['option1', 'option2']); // Lista
});
```

### on(event, handler)

Escuta eventos específicos enviados pelo cliente.

```dart
ws.on('connection', (socket) {
  // Escuta evento 'sendMessage' do cliente
  socket.on('sendMessage', (dynamic data) {
    print('Mensagem recebida: $data');

    // Processa a mensagem e faz broadcast para outros clientes
    socket.broadcast.emit('newMessage', {
      'user': data['user'],
      'message': data['message'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  // Escuta evento 'typing' do cliente
  socket.on('typing', (dynamic data) {
    // Informa outros clientes que alguém está digitando
    socket.broadcast.emit('userTyping', {
      'user': data['user'],
      'isTyping': true,
    });
  });

  // Escuta evento 'joinRoom' do cliente
  socket.on('joinRoom', (dynamic data) {
    final roomName = data['room'];
    print('Cliente ${socket.id} entrou na sala: $roomName');

    // Notifica outros clientes sobre o novo membro
    socket.broadcast.emit('userJoined', {
      'user': data['user'],
      'room': roomName,
    });
  });
});
```

### send(data)

Envia dados brutos para o cliente (sem estrutura de evento).

```dart
ws.on('connection', (socket) {
  // Envia uma string simples
  socket.send('Mensagem simples');

  // Envia JSON manualmente
  socket.send('{"type": "raw", "data": "dados brutos"}');
});
```

### sendJson(data)

Envia dados JSON para o cliente.

```dart
ws.on('connection', (socket) {
  // Envia um objeto como JSON
  socket.sendJson({
    'type': 'system',
    'message': 'Sistema inicializado',
    'version': '1.0.0',
  });
});
```

### destroy()

Fecha a conexão WebSocket.

```dart
ws.on('connection', (socket) {
  // Fecha a conexão após 30 segundos (exemplo)
  Timer(Duration(seconds: 30), () {
    socket.destroy();
  });
});

// Ou em caso de erro
ws.on('error', (socket) {
  socket.destroy();
});
```

## Broadcasting

### broadcast.emit(event, data)

Envia um evento para todos os outros clientes conectados (exceto o remetente).

```dart
ws.on('connection', (socket) {
  socket.on('chatMessage', (dynamic data) {
    // Envia a mensagem para todos os outros clientes conectados
    socket.broadcast.emit('newChatMessage', {
      'user': data['user'],
      'message': data['message'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  socket.on('gameMove', (dynamic data) {
    // Envia o movimento do jogo para outros jogadores
    socket.broadcast.emit('opponentMove', {
      'playerId': socket.id,
      'move': data['move'],
      'position': data['position'],
    });
  });
});
```

### broadcast.send(data)

Envia dados brutos para todos os outros clientes conectados.

```dart
ws.on('connection', (socket) {
  socket.on('announcement', (dynamic data) {
    // Envia anúncio para todos os outros clientes
    socket.broadcast.send('Anúncio: ${data['message']}');
  });
});
```

## Middlewares

### Middleware de Autenticação

```dart
// Middleware para verificar autenticação
ws.use((HttpRequest request) async {
  final token = request.uri.queryParameters['token'];

  // Verifica se o token é válido
  if (token == null || !isValidToken(token)) {
    return false; // Rejeita a conexão
  }

  return true; // Aceita a conexão
});

bool isValidToken(String token) {
  // Implementa a lógica de validação do token
  return token == 'valid-token-123';
}
```

### Middleware de Rate Limiting

```dart
final Map<String, int> connectionCounts = {};

// Middleware para limitar conexões por IP
ws.use((HttpRequest request) async {
  final clientIP = request.connectionInfo?.remoteAddress.address ?? 'unknown';

  // Conta conexões por IP
  connectionCounts[clientIP] = (connectionCounts[clientIP] ?? 0) + 1;

  // Limita a 5 conexões por IP
  if (connectionCounts[clientIP]! > 5) {
    return false; // Rejeita conexões excessivas
  }

  return true;
});
```

## Exemplos Práticos

### Chat em Tempo Real

```dart
void setupChatServer() {
  final app = Darto();
  final ws = WebSocketServer();

  app.useWebSocket(ws);

  // Lista de usuários conectados
  final Set<String> connectedUsers = {};

  ws.on('connection', (socket) {
    print('Novo usuário conectado: ${socket.id}');

    // Usuário entra no chat
    socket.on('userJoin', (dynamic data) {
      final username = data['username'];
      connectedUsers.add(username);

      // Notifica todos sobre o novo usuário
      socket.broadcast.emit('userJoined', {
        'username': username,
        'userCount': connectedUsers.length,
      });

      // Envia lista de usuários para o novo cliente
      socket.emit('userList', connectedUsers.toList());
    });

    // Mensagem de chat
    socket.on('chatMessage', (dynamic data) {
      // Retransmite a mensagem para todos os outros clientes
      socket.broadcast.emit('newMessage', {
        'username': data['username'],
        'message': data['message'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Usuário está digitando
    socket.on('typing', (dynamic data) {
      socket.broadcast.emit('userTyping', {
        'username': data['username'],
        'isTyping': data['isTyping'],
      });
    });
  });

  // Cleanup quando usuário desconecta
  ws.on('close', (socket) {
    // Remove usuário da lista (implementação simplificada)
    print('Usuário desconectado: ${socket.id}');
  });

  app.listen(8080);
}
```

### Jogo Multiplayer Simples

```dart
void setupGameServer() {
  final app = Darto();
  final ws = WebSocketServer();

  app.useWebSocket(ws);

  // Estado do jogo
  final Map<String, dynamic> gameState = {
    'players': <String, Map<String, dynamic>>{},
    'gameStarted': false,
  };

  ws.on('connection', (socket) {
    // Jogador entra no jogo
    socket.on('joinGame', (dynamic data) {
      final playerId = socket.id.toString();

      // Adiciona jogador ao estado do jogo
      gameState['players'][playerId] = {
        'name': data['playerName'],
        'score': 0,
        'position': {'x': 0, 'y': 0},
      };

      // Envia estado atual do jogo para o novo jogador
      socket.emit('gameState', gameState);

      // Notifica outros jogadores sobre o novo jogador
      socket.broadcast.emit('playerJoined', {
        'playerId': playerId,
        'playerName': data['playerName'],
      });
    });

    // Movimento do jogador
    socket.on('playerMove', (dynamic data) {
      final playerId = socket.id.toString();

      // Atualiza posição do jogador
      if (gameState['players'].containsKey(playerId)) {
        gameState['players'][playerId]['position'] = data['position'];

        // Envia movimento para outros jogadores
        socket.broadcast.emit('playerMoved', {
          'playerId': playerId,
          'position': data['position'],
        });
      }
    });

    // Ação do jogador (ex: atirar, pular, etc.)
    socket.on('playerAction', (dynamic data) {
      final playerId = socket.id.toString();

      // Processa ação e atualiza pontuação
      if (data['action'] == 'score') {
        gameState['players'][playerId]['score'] += 10;

        // Envia atualização de pontuação
        socket.broadcast.emit('scoreUpdate', {
          'playerId': playerId,
          'newScore': gameState['players'][playerId]['score'],
        });
      }
    });
  });

  // Remove jogador quando desconecta
  ws.on('close', (socket) {
    final playerId = socket.id.toString();
    gameState['players'].remove(playerId);

    // Notifica outros jogadores
    ws.broadcastEmit('playerLeft', {'playerId': playerId});
  });

  app.listen(8080);
}
```

### Sistema de Notificações

```dart
void setupNotificationServer() {
  final app = Darto();
  final ws = WebSocketServer();

  app.useWebSocket(ws);

  // Armazena clientes por tópico de interesse
  final Map<String, Set<WebSocket>> topicSubscriptions = {};

  ws.on('connection', (socket) {
    // Cliente se inscreve em um tópico
    socket.on('subscribe', (dynamic data) {
      final topic = data['topic'];

      // Adiciona cliente à lista de inscritos do tópico
      topicSubscriptions.putIfAbsent(topic, () => {}).add(socket);

      // Confirma inscrição
      socket.emit('subscribed', {
        'topic': topic,
        'message': 'Inscrito com sucesso em $topic',
      });
    });

    // Cliente cancela inscrição
    socket.on('unsubscribe', (dynamic data) {
      final topic = data['topic'];

      // Remove cliente da lista de inscritos
      topicSubscriptions[topic]?.remove(socket);

      // Confirma cancelamento
      socket.emit('unsubscribed', {
        'topic': topic,
        'message': 'Inscrição cancelada em $topic',
      });
    });
  });

  // Função para enviar notificação para um tópico específico
  void sendNotificationToTopic(String topic, Map<String, dynamic> notification) {
    final subscribers = topicSubscriptions[topic] ?? {};

    for (final socket in subscribers) {
      if (socket.readyState == WebSocket.open) {
        socket.emit('notification', {
          'topic': topic,
          'data': notification,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // Exemplo de uso: enviar notificação a cada 30 segundos
  Timer.periodic(Duration(seconds: 30), (timer) {
    sendNotificationToTopic('news', {
      'title': 'Notícia Importante',
      'content': 'Uma nova atualização está disponível!',
      'priority': 'high',
    });
  });

  app.listen(8080);
}
```

## Cliente JavaScript

### Exemplo de Cliente HTML/JavaScript

```html
<!DOCTYPE html>
<html>
  <head>
    <title>WebSocket Client</title>
    <style>
      #messages {
        height: 300px;
        overflow-y: scroll;
        border: 1px solid #ccc;
        padding: 10px;
      }
      .message {
        margin: 5px 0;
      }
      .system {
        color: #666;
        font-style: italic;
      }
      .user {
        color: #333;
      }
      .typing {
        color: #999;
        font-size: 0.9em;
      }
    </style>
  </head>
  <body>
    <div id="messages"></div>
    <input type="text" id="messageInput" placeholder="Digite sua mensagem..." />
    <button onclick="sendMessage()">Enviar</button>
    <button onclick="joinChat()">Entrar no Chat</button>
    <button onclick="startTyping()">Começar a Digitar</button>
    <button onclick="stopTyping()">Parar de Digitar</button>

    <script>
      // Conecta ao servidor WebSocket
      const ws = new WebSocket("ws://localhost:8080");
      let username = "User" + Math.floor(Math.random() * 1000);

      // Quando a conexão é aberta
      ws.onopen = function (event) {
        console.log("Conectado ao WebSocket");
        addMessage("Conectado ao servidor!", "system");
      };

      // Quando uma mensagem é recebida do servidor
      ws.onmessage = function (event) {
        try {
          // Tenta fazer parse da mensagem como JSON estruturado
          const data = JSON.parse(event.data);
          handleStructuredMessage(data);
        } catch (e) {
          // Se não for JSON estruturado, trata como mensagem simples
          addMessage(event.data, "system");
        }
      };

      // Quando a conexão é fechada
      ws.onclose = function (event) {
        console.log("Conexão WebSocket fechada");
        addMessage("Desconectado do servidor", "system");
      };

      // Quando ocorre um erro
      ws.onerror = function (error) {
        console.error("Erro WebSocket:", error);
        addMessage("Erro na conexão", "system");
      };

      // Manipula mensagens estruturadas do servidor
      function handleStructuredMessage(data) {
        switch (data.event) {
          case "welcome":
            addMessage(`Servidor: ${data.data}`, "system");
            break;

          case "newMessage":
            addMessage(`${data.data.username}: ${data.data.message}`, "user");
            break;

          case "userJoined":
            addMessage(`${data.data.username} entrou no chat`, "system");
            break;

          case "userTyping":
            if (data.data.isTyping) {
              showTypingIndicator(`${data.data.username} está digitando...`);
            } else {
              hideTypingIndicator();
            }
            break;

          case "notification":
            addMessage(`Notificação: ${data.data.message}`, "system");
            break;

          case "gameState":
            console.log("Estado do jogo recebido:", data.data);
            break;

          case "playerMoved":
            console.log(
              `Jogador ${data.data.playerId} moveu para:`,
              data.data.position
            );
            break;

          default:
            console.log("Evento desconhecido:", data);
        }
      }

      // Envia uma mensagem de chat
      function sendMessage() {
        const input = document.getElementById("messageInput");
        const message = input.value.trim();

        if (message && ws.readyState === WebSocket.OPEN) {
          // Envia mensagem estruturada para o servidor
          const messageData = {
            event: "chatMessage",
            data: {
              username: username,
              message: message,
            },
          };

          ws.send(JSON.stringify(messageData));

          // Adiciona a própria mensagem na tela
          addMessage(`Você: ${message}`, "user");
          input.value = "";
        }
      }

      // Entra no chat
      function joinChat() {
        if (ws.readyState === WebSocket.OPEN) {
          const joinData = {
            event: "userJoin",
            data: {
              username: username,
            },
          };

          ws.send(JSON.stringify(joinData));
          addMessage(`Entrando no chat como ${username}`, "system");
        }
      }

      // Indica que está digitando
      function startTyping() {
        if (ws.readyState === WebSocket.OPEN) {
          const typingData = {
            event: "typing",
            data: {
              username: username,
              isTyping: true,
            },
          };

          ws.send(JSON.stringify(typingData));
        }
      }

      // Para de indicar que está digitando
      function stopTyping() {
        if (ws.readyState === WebSocket.OPEN) {
          const typingData = {
            event: "typing",
            data: {
              username: username,
              isTyping: false,
            },
          };

          ws.send(JSON.stringify(typingData));
        }
      }

      // Adiciona mensagem na tela
      function addMessage(message, type) {
        const messagesDiv = document.getElementById("messages");
        const messageElement = document.createElement("div");
        messageElement.className = `message ${type}`;
        messageElement.textContent = `[${new Date().toLocaleTimeString()}] ${message}`;
        messagesDiv.appendChild(messageElement);
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
      }

      // Mostra indicador de digitação
      function showTypingIndicator(message) {
        // Remove indicador anterior se existir
        hideTypingIndicator();

        const messagesDiv = document.getElementById("messages");
        const typingElement = document.createElement("div");
        typingElement.className = "message typing";
        typingElement.id = "typing-indicator";
        typingElement.textContent = message;
        messagesDiv.appendChild(typingElement);
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
      }

      // Esconde indicador de digitação
      function hideTypingIndicator() {
        const typingElement = document.getElementById("typing-indicator");
        if (typingElement) {
          typingElement.remove();
        }
      }

      // Permite enviar mensagem com Enter
      document
        .getElementById("messageInput")
        .addEventListener("keypress", function (e) {
          if (e.key === "Enter") {
            sendMessage();
          }
        });

      // Exemplo de cliente para jogo
      function sendGameMove(x, y) {
        if (ws.readyState === WebSocket.OPEN) {
          const moveData = {
            event: "playerMove",
            data: {
              position: { x: x, y: y },
            },
          };

          ws.send(JSON.stringify(moveData));
        }
      }

      // Exemplo de inscrição em notificações
      function subscribeToTopic(topic) {
        if (ws.readyState === WebSocket.OPEN) {
          const subscribeData = {
            event: "subscribe",
            data: {
              topic: topic,
            },
          };

          ws.send(JSON.stringify(subscribeData));
        }
      }

      // Auto-conecta ao chat quando a página carrega
      window.onload = function () {
        // Aguarda um pouco para garantir que a conexão foi estabelecida
        setTimeout(joinChat, 1000);
      };
    </script>
  </body>
</html>
```

```js
// cliente-node.js
const WebSocket = require("ws");

class DartoWebSocketClient {
  constructor(url) {
    this.ws = new WebSocket(url);
    this.eventHandlers = new Map();
    this.setupConnection();
  }

  // Configura a conexão WebSocket
  setupConnection() {
    this.ws.on("open", () => {
      console.log("Conectado ao servidor Darto WebSocket");
      this.emit("connected");
    });

    this.ws.on("message", (data) => {
      try {
        // Tenta fazer parse como JSON estruturado
        const parsed = JSON.parse(data);
        if (parsed.event && parsed.data !== undefined) {
          this.handleEvent(parsed.event, parsed.data);
        } else {
          this.handleEvent("message", parsed);
        }
      } catch (e) {
        // Trata como mensagem simples
        this.handleEvent("message", data.toString());
      }
    });

    this.ws.on("close", () => {
      console.log("Desconectado do servidor");
      this.emit("disconnected");
    });

    this.ws.on("error", (error) => {
      console.error("Erro WebSocket:", error);
      this.emit("error", error);
    });
  }

  // Registra um handler para um evento específico
  on(event, handler) {
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }
    this.eventHandlers.get(event).push(handler);
  }

  // Remove um handler de evento
  off(event, handler) {
    if (this.eventHandlers.has(event)) {
      const handlers = this.eventHandlers.get(event);
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
      }
    }
  }

  // Emite um evento localmente
  emit(event, data = null) {
    if (this.eventHandlers.has(event)) {
      this.eventHandlers.get(event).forEach((handler) => {
        try {
          handler(data);
        } catch (error) {
          console.error(
            `Erro ao executar handler para evento ${event}:`,
            error
          );
        }
      });
    }
  }

  // Manipula eventos recebidos do servidor
  handleEvent(event, data) {
    this.emit(event, data);
  }

  // Envia um evento estruturado para o servidor
  send(event, data) {
    if (this.ws.readyState === WebSocket.OPEN) {
      const message = JSON.stringify({
        event: event,
        data: data,
      });
      this.ws.send(message);
    } else {
      console.warn("WebSocket não está conectado");
    }
  }

  // Envia dados brutos
  sendRaw(data) {
    if (this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(data);
    } else {
      console.warn("WebSocket não está conectado");
    }
  }

  // Fecha a conexão
  close() {
    this.ws.close();
  }

  // Verifica se está conectado
  isConnected() {
    return this.ws.readyState === WebSocket.OPEN;
  }
}

// Exemplo de uso do cliente Node.js
const client = new DartoWebSocketClient("ws://localhost:8080");

// Registra handlers para eventos
client.on("connected", () => {
  console.log("Cliente conectado com sucesso!");

  // Entra no chat
  client.send("userJoin", {
    username: "NodeClient",
  });
});

client.on("welcome", (data) => {
  console.log("Mensagem de boas-vindas:", data);
});

client.on("newMessage", (data) => {
  console.log(`${data.username}: ${data.message}`);
});

client.on("userJoined", (data) => {
  console.log(`${data.username} entrou no chat`);
});

// Envia uma mensagem a cada 5 segundos
setInterval(() => {
  if (client.isConnected()) {
    client.send("chatMessage", {
      username: "NodeClient",
      message: `Mensagem automática: ${new Date().toLocaleTimeString()}`,
    });
  }
}, 5000);

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("Fechando cliente...");
  client.close();
  process.exit(0);
});
```
