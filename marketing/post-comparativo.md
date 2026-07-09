# Darto vs dart_frog vs Serverpod (rascunho de artigo — dev.to / Medium)

> Objetivo: conteúdo de SEO alto e honesto. NÃO atacar concorrentes — posicionar o
> Darto pelo nicho onde ele é a melhor escolha. Conferir fatos de dart_frog/Serverpod
> antes de publicar (versões mudam).

---

## Título sugerido
**Backend em Dart em 2026: Darto vs dart_frog vs Serverpod — qual escolher?**

## Abertura
Dart no servidor amadureceu. Hoje você tem opções reais — e cada uma resolve um
problema diferente. Este guia é honesto: vou dizer quando *não* usar o Darto também.

## Panorama rápido

| | **Darto** | **dart_frog** | **Serverpod** |
|---|---|---|---|
| Estilo | Express/Hono (Context) | Minimalista, rotas por arquivo | Full-stack opinativo |
| Code generation | Não (rotas em código) | Sim (dev server / build) | Sim (modelos, client) |
| Banco de dados | Plugue o que quiser | Plugue o que quiser | ORM + migrations inclusos |
| Cliente Flutter tipado | Via `darto_cli` (gen-client) | Manual | Gerado automaticamente |
| Ecossistema oficial | Auth, WS, cache, jobs, mailer, OpenAPI… | Enxuto + middlewares shelf | Tudo integrado |
| Curva de aprendizado | Baixa | Baixa | Média/alta |
| Melhor para | APIs e serviços com API familiar e plugins | Microsserviços minimalistas | Apps full-stack com backend acoplado ao Flutter |

> ⚠️ Conferir antes de publicar: features e versões de dart_frog e Serverpod.

## Quando escolher cada um

**Serverpod** se você quer uma solução "tudo incluso" fortemente acoplada ao Flutter:
ORM, migrations, auth e client gerado de fábrica. Você troca flexibilidade por
integração.

**dart_frog** se você quer o mínimo absoluto, rotas por convenção de arquivos e está
confortável com code-gen/dev server. Ótimo para microsserviços pequenos.

**Darto** se você quer a ergonomia do Express/Hono em Dart puro — rotas e middleware
como funções, **sem code generation obrigatório** — e um ecossistema de plugins
oficiais para crescer sem fricção (auth, WebSocket, cache, jobs, e-mail, e OpenAPI 3.1
que valida *e* documenta a partir de um schema). E, como bônus, um CLI que gera o
cliente Flutter tipado da sua API.

## O diferencial do Darto na prática

```dart
// um schema. valida o request E gera o OpenAPI.
final userSchema = z.map({
  'name': z.string().min(2).openapi(example: 'Ada'),
  'age':  z.int().min(0).max(150).openapi(example: 28),
}).openapiSchema('User');
```

Sem duplicar tipo, validação e documentação em três lugares. É a DX do
`@hono/zod-openapi`, agora em Dart.

## Conclusão honesta
- Quer um monolito full-stack colado no Flutter → **Serverpod**.
- Quer o mínimo com rotas por arquivo → **dart_frog**.
- Quer API familiar (Express/Hono), pure-Dart, sem code-gen, com plugins → **Darto**.

Docs: https://darto-docs.vercel.app · GitHub: https://github.com/evandersondev/darto

### TODO antes de publicar
- [ ] Verificar afirmações sobre dart_frog e Serverpod (releases atuais).
- [ ] Versão PT (LinkedIn) + EN (dev.to/Medium).
- [ ] Linkar o artigo "API em 5 min" como leitura seguinte.
