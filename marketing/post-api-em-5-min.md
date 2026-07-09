# REST API em Dart em 5 minutos com Darto (rascunho — dev.to / Medium / LinkedIn)

> Público: devs Flutter/Dart que nunca fizeram backend, ou que usam Node/Express e
> querem ficar em Dart. Tom: direto, copia-e-cola, sem enrolação.

---

## Título sugerido
**REST API em Dart em 5 minutos — sem trocar de linguagem**

## Subtítulo
Você já escreve Dart no Flutter. Que tal escrever o backend também? Vou te mostrar do
zero a uma API rodando, com validação e documentação OpenAPI, em 5 minutos.

---

## 1. Instale o CLI e crie o projeto (30s)

```sh
dart pub global activate darto_cli

# Já quer validação + docs OpenAPI prontas? Use o template:
darto create my_api --template openapi
cd my_api
darto dev      # servidor com hot-reload; docs em /docs
```

> O `--template openapi` já entrega tudo da seção 4 abaixo (schema que valida E
> documenta + Scalar em `/docs` + testes). Os passos seguintes mostram como cada
> peça funciona por baixo.

## 2. Sua primeira rota

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  app.get('/health', [], (Context c) => c.ok({'status': 'up'}));

  app.get('/users/:id', [], (Context c) {
    final id = c.req.param('id');
    return c.ok({'id': id});
  });

  app.listen(3000);
}
```

Tudo passa por um único objeto: o **Context** (`c`). Se você já usou Express ou Hono,
o modelo mental é idêntico — só que em Dart puro, sem ponte JS.

## 3. Middleware é só uma função

```dart
Future<void> logger(Context c, Next next) async {
  print('${c.req.method} ${c.req.path}');
  await next();
}

app.use(logger);
```

## 4. Validação que também vira documentação (o pulo do gato)

Com `darto_zard_openapi`, você define um schema **uma vez** e ele valida o request
**e** gera o OpenAPI 3.1 (com UI do Scalar):

```dart
final userSchema = z.map({
  'name': z.string().min(2).openapi(example: 'Ada', description: 'Nome completo'),
  'age':  z.int().min(0).max(150).openapi(example: 28),
}).openapiSchema('User');

final route = createRoute(
  method: 'post',
  path: '/users',
  request: Req(json: userSchema),
  responses: [Res(201, 'Criado', body: userSchema)],
);

api.openapi(route, [], (c) async => c.created(c.req.valid('json')));
api.doc('/openapi.json', info: Info(title: 'API', version: '1.0.0'));
app.get('/docs', [], scalarUI(url: '/openapi.json'));
```

Abra `/docs` e sua API já está documentada. Request inválido? `400` automático com os
erros do schema.

## 5. Pronto. E agora?
- Auth, WebSocket, cache, jobs, e-mail: tudo plugin oficial (`darto_auth`, `darto_ws`,
  `darto_cache`, `darto_jobs`, `darto_mailer`).
- Compila AOT para um binário nativo rápido.
- Docs: https://darto-docs.vercel.app

**Mesma linguagem, do app ao servidor.** Se curtir, deixa uma ⭐ no
[GitHub](https://github.com/evandersondev/darto).

---

### Hashtags (LinkedIn)
#Dart #Flutter #BackendDevelopment #OpenSource #API #Dartlang #WebDev

### TODO antes de publicar
- [ ] Conferir cada snippet rodando contra a versão publicada atual.
- [ ] Gravar GIF do `darto dev` + `/docs` para a capa.
- [ ] Versão EN para dev.to/Medium.
