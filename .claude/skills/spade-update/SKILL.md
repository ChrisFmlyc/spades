---
name: spade-update
description: Check for and install SPADE framework updates. Use when someone says "update spade", "upgrade spade", "check for updates", "is spade up to date", or wants to pull the latest version of the framework and reinstall skills.
---

# SPADE Update

You are updating the SPADE framework to the latest version.

## Process

1. Run the following commands using the Bash tool:

```bash
cd ~/.spade && git fetch origin && git log --oneline HEAD..origin/main
```

2. If there are new commits, show them to the user and ask if they want to update.

3. If the user confirms (or didn't need to be asked), run:

```bash
cd ~/.spade && git pull && ~/.spade/setup
```

4. Clear the update check cache so the next skill invocation sees a fresh state:

```bash
rm -f ~/.spade/.state/last-update-check
```

5. Report what was updated:
   - How many commits were pulled
   - Which skills were reinstalled
   - Any new skills that were added

## If Already Up to Date

If `git log HEAD..origin/main` shows no commits, tell the user:

```
SPADE is up to date (v1.0.0).
```

## If ~/.spade Doesn't Exist

Tell the user SPADE is not installed and show the install command:

```bash
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup
```

## If ~/.spade Is Not a Git Repo

This can happen if the directory was created manually or corrupted.
Suggest a fresh install:

```bash
rm -rf ~/.spade
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup
```

Warn the user before running `rm -rf` and get confirmation.
