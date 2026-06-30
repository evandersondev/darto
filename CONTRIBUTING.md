# Contributing to Darto / Contribuindo com o Darto

🇬🇧 English below · 🇧🇷 Português abaixo

First of all: **thank you!** Darto is an open-source project and every issue, idea
and pull request helps. / Antes de tudo: **obrigado!** O Darto é open-source e cada
issue, ideia e pull request ajuda.

---

## 🇬🇧 English

### Repository layout

This is a **monorepo**. The core framework lives in [`darto/`](darto/) and each
plugin is its own publishable package (`darto_auth/`, `darto_ws/`, `darto_openapi/`,
…). Runnable examples live in [`examples/`](examples/) and the docs site in
[`darto-docs/`](darto-docs/).

> **Heads-up:** [`zard`](https://github.com/evandersondev/zard) (the validation
> library used by `darto_validator` and `darto_zard_openapi`) is a **separate
> repository**. For local development, clone it as a **sibling** of this repo so
> the `dependency_overrides` (`../../zard`) resolve:
>
> ```
> some-folder/
> ├── darto/   ← this repo
> └── zard/    ← git clone https://github.com/evandersondev/zard
> ```

### Local setup

```bash
# clone both repos side by side
git clone https://github.com/evandersondev/darto.git
git clone https://github.com/evandersondev/zard.git

cd darto/darto          # or any package you want to work on
dart pub get
dart test
```

### Before opening a PR

Run these in **each package you touched**:

```bash
dart format .
dart analyze
dart test          # if the package has a test/ folder
```

CI runs the same checks per package, so a green local run usually means a green PR.

### Commit messages

We follow [Conventional Commits](https://www.conventionalcommits.org/), scoped by
package:

```
feat(darto_ws): add room broadcast helper
fix(darto): correct query parsing for repeated keys
docs(darto_openapi): document scalarUI options
```

### Releasing a package (maintainers)

1. Bump `version:` in the package `pubspec.yaml` and update its `CHANGELOG.md`.
2. Merge to `main` (CI green).
3. Tag: `<package>-v<version>` (e.g. `darto_ws-v1.1.0`); core uses `vX.Y.Z`.
4. `dart pub publish` from the package directory.

### Good first issues

Look for issues labeled [`good first issue`](https://github.com/evandersondev/darto/labels/good%20first%20issue)
and [`help wanted`](https://github.com/evandersondev/darto/labels/help%20wanted).

---

## 🇧🇷 Português

### Estrutura do repositório

Este é um **monorepo**. O framework principal está em [`darto/`](darto/) e cada
plugin é um pacote publicável próprio (`darto_auth/`, `darto_ws/`, `darto_openapi/`,
…). Exemplos executáveis em [`examples/`](examples/) e a documentação em
[`darto-docs/`](darto-docs/).

> **Atenção:** o [`zard`](https://github.com/evandersondev/zard) (biblioteca de
> validação usada por `darto_validator` e `darto_zard_openapi`) fica em um
> **repositório separado**. Para desenvolvimento local, clone-o como **irmão**
> deste repo, para os `dependency_overrides` (`../../zard`) resolverem:
>
> ```
> uma-pasta/
> ├── darto/   ← este repo
> └── zard/    ← git clone https://github.com/evandersondev/zard
> ```

### Configuração local

```bash
# clone os dois repos lado a lado
git clone https://github.com/evandersondev/darto.git
git clone https://github.com/evandersondev/zard.git

cd darto/darto          # ou qualquer pacote que queira mexer
dart pub get
dart test
```

### Antes de abrir um PR

Rode em **cada pacote que você alterou**:

```bash
dart format .
dart analyze
dart test          # se o pacote tiver a pasta test/
```

O CI roda as mesmas verificações por pacote — verde no local geralmente significa
PR verde.

### Mensagens de commit

Seguimos o [Conventional Commits](https://www.conventionalcommits.org/), com escopo
por pacote:

```
feat(darto_ws): adiciona helper de broadcast por sala
fix(darto): corrige parsing de query para chaves repetidas
docs(darto_openapi): documenta opções do scalarUI
```

### Publicando um pacote (mantenedores)

1. Suba a `version:` no `pubspec.yaml` do pacote e atualize o `CHANGELOG.md`.
2. Faça merge para `main` (CI verde).
3. Crie a tag: `<pacote>-v<versão>` (ex.: `darto_ws-v1.1.0`); o core usa `vX.Y.Z`.
4. `dart pub publish` a partir da pasta do pacote.

### Primeiras contribuições

Procure issues marcadas como [`good first issue`](https://github.com/evandersondev/darto/labels/good%20first%20issue)
e [`help wanted`](https://github.com/evandersondev/darto/labels/help%20wanted).

---

By contributing, you agree that your contributions will be licensed under the
project's [MIT License](LICENSE). / Ao contribuir, você concorda que sua
contribuição será licenciada sob a [Licença MIT](LICENSE) do projeto.
