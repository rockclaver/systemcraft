# SystemCraft Skills

This repository contains reusable AI skill definitions for agent-driven workflows. Each skill is a self-contained capability described in a `SKILL.md` file and organized under `skills/`.

## What is a skill?

A skill is a small, focused instruction set that an AI agent can load and use when a user request matches its purpose.

Each skill folder typically contains:

- `SKILL.md` — required, the core instructions and activation description
- `REFERENCE.md` — optional, for detailed docs or extended examples
- `EXAMPLES.md` — optional, for usage examples and sample prompts
- `scripts/` — optional, for deterministic helper scripts the agent can call

Example structure:

```
skills/
  core/
    write-a-skill/
      SKILL.md
    write-a-prd/
      SKILL.md
    prd-to-plan/
      SKILL.md
    grill-me/
      SKILL.md
```

## How skills are loaded

AI agents use the `SKILL.md` frontmatter description to decide which skill to activate. Your agent runtime must be configured to scan and load skill folders from this repo.

A skill is discovered by:

1. reading the frontmatter metadata
2. matching the user's request against the skill description
3. invoking the corresponding instructions

### Required skill metadata

Each `SKILL.md` must start with YAML frontmatter like:

```md
---
name: write-a-prd
description: Create a PRD through user interview, codebase exploration, and module design, then submit as a GitHub issue. Use when user wants to write a PRD, create a product requirements document, or plan a new feature.
---
```

The `description` is vital because the agent uses it to route requests.

## Installation

This repo is primarily a skill definition repository. There is no build step in this workspace by default. Installing skills into an AI agent means making the skill folders available to that agent runtime.

### Local installation

1. Clone the repository:

```bash
git clone <repo-url>
cd systemcraft
```

2. Point your AI agent's skill loader at the `skills/` directory.

3. Restart or refresh your agent so it rescans available skills.

### If your agent has a skills CLI

Some agent runtimes provide commands to add or remove skill folders. For example:

```bash
npx skills add ./skills/core/write-a-prd
npx skills add ./skills/core/prd-to-plan
npx skills remove ./skills/core/old-skill
```

> Use these commands only if your agent runtime supports them.

### Folder-based installation

If your agent uses a filesystem-based skill registry, install skills by copying or symlinking the folders into the configured location.

Example:

```bash
ln -s $PWD/skills/core/write-a-prd /path/to/agent/skill-store/write-a-prd
```

## Using skills in AI agents

Once the skill folders are available to the agent, you can use them by asking for the capability described in the `description` frontmatter.

### Example user prompts

- `Help me write a PRD for a new feature.`
- `Turn this requirements draft into a product plan.`
- `Grill this architecture proposal for gaps and risks.`
- `Teach me how to write a new agent skill.`

### How the agent chooses a skill

The agent will typically activate a skill when the prompt matches the `Use when ...` clause in the description.

For example, `write-a-prd` is triggered by requests about:

- writing a PRD
- creating a product requirements document
- planning a new feature

If multiple loaded skills overlap, the agent should choose the most specific one based on the descriptions.

## Skill authoring best practices

Use the `skills/core/write-a-skill` skill as the template for new skills.

### Keep skills focused

- One skill = one capability.
- Use short, clear instructions.
- Avoid mixing unrelated domains in the same skill.

### Write a strong description

The description should explain:

- what the skill does
- when to use it

Good example:

```md
Extract text and tables from PDF files. Use when working with PDFs, forms, or document extraction tasks.
```

Bad example:

```md
Helps with documents.
```

### Keep `SKILL.md` concise

- Prefer <100 lines when possible
- If the content is long, split details into `REFERENCE.md`
- Keep the main skill readable

## Existing skills in this repo

- `skills/core/write-a-skill` — guidance for creating new agent skills
- `skills/core/write-a-prd` — write a PRD from user input and codebase context
- `skills/core/prd-to-plan` — turn a PRD into a concrete implementation plan
- `skills/core/write-tests` — write high-value tests and improve practical coverage in an existing codebase
- `skills/core/grill-me` — critique a design or plan and surface risks

## Troubleshooting

If a skill does not appear to load:

- verify the folder is inside `skills/`
- verify `SKILL.md` exists and has valid YAML frontmatter
- check the `description` for clear activation keywords
- refresh your agent or reload the skill manifest

If the agent loads the skill but does not use it:

- make the `Use when ...` clause more specific
- add more explicit examples to the description
- ensure the prompt clearly asks for the skill's capability

## Contributing new skills

1. Create a new folder under `skills/<domain>/`.
2. Add `SKILL.md` with frontmatter and instructions.
3. Optionally add `REFERENCE.md`, `EXAMPLES.md`, or helper scripts.
4. Test the skill by issuing a prompt that matches the `Use when ...` criteria.
5. Submit the new skill for review.

## Summary

This repository is a collection of agent skills designed to be loaded by an AI agent runtime. Installation is primarily about making these skill folders visible to the agent, while usage depends on clear skill descriptions and prompt matching.

If you want to extend the repo, start from `skills/core/write-a-skill` and keep every skill goal-driven, narrow, and easy for the agent to choose.
