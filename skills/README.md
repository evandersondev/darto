# Darto Skills (for Claude / AI agents)

Task-scoped **Skills** that teach an AI assistant how to perform common tasks in
a [Darto](https://pub.dev/packages/darto) (Dart) web project. Each skill is a
folder with a `SKILL.md` file; the assistant loads it on demand when your
request matches the skill's description — so it only consumes context when
relevant, and can carry detailed, step-by-step procedures.

These are complementary to the other two "AI-readable docs" layers Darto ships:

- **`llms.txt`** (on the docs site) — helps models find and read the docs.
- **`AGENTS.md`** (repo root) — conventions for writing code in this repo.
- **Skills** (here) — executable procedures for specific tasks, loaded on demand.

## Available skills

| Skill | Use it when you want to… |
| --- | --- |
| [`darto-add-route`](./darto-add-route/) | Add or change HTTP endpoints (verbs, params, body, response helpers) |
| [`darto-validate-request`](./darto-validate-request/) | Validate request body / query / params with `zValidator` + `zard` |
| [`darto-write-middleware`](./darto-write-middleware/) | Write and register middleware; error & 404 handling |
| [`darto-scaffold-project`](./darto-scaffold-project/) | Scaffold a new Darto project with the CLI (module structure) |

## Installing

Skills are discovered from a `skills/` directory inside `.claude/`. Copy the
folders you want into your project (or your home directory):

```sh
# Project-scoped (shared with your team via git)
mkdir -p .claude/skills
cp -r path/to/darto/skills/darto-* .claude/skills/

# Or user-scoped (available in all your projects)
mkdir -p ~/.claude/skills
cp -r path/to/darto/skills/darto-* ~/.claude/skills/
```

Restart your assistant (or start a new session) so it picks up the new skills.
You can confirm they loaded by asking it to list available skills, or just ask
it to "add a Darto endpoint" and watch it apply the conventions.

> These skills target Darto **1.2+** (the Context-based API). They assume
> `darto: ^1.2.0`, and the relevant ecosystem packages where noted.
