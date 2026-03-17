# claude-stack Local Notes

Project-specific reminders. Not committed to the repo.

---

## After removing a skill

`./sync` uses `rsync --delete` for the skills directory, so removed skills are cleaned from
the plugin cache automatically on the dev path.

Verify after any removal:
```bash
./sync && ls ~/.claude/plugins/cache/claude-stack/claude-stack/1.0.0/skills/
```

Confirm the deleted skill directory is gone from the cache listing before committing.

The user path (`claude plugin install claude-stack`) reinstalls fresh and also cleans up.
Stale skills only persist if a user has the plugin installed but does not reinstall after
a version bump.
