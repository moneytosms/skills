# Report template

Lead with the answer to the user's symptom. Plain words, numbers over adjectives, every claim backed by an agent finding you verified. Keep it scannable: the user acts on this.

```markdown
# Tuneup: <hostname>, <date>

<One or two sentences: the root cause of the symptom, and the single biggest lever.>

## 1. <Symptom / headline issue>
- **What happened:** evidence with counts and dates (e.g. "systemd-oomd killed Zen 5x, Nov 3-7, swap at 94%").
- **Why:** the mechanism, in one or two lines.
- **Fixes, biggest first:** numbered, each with the command or setting.

## 2. Disk
<partition size/use, structural issues, then the reclaim table>

| Item | Path | Size | Tier |
|---|---|---|---|
| ... | ... | ... | safe / review / risky |

## 3. Software clutter
<duplicates and removal candidates, with sizes; "already clean" items in one line>

## 4. Services, boot, power
<only things worth changing; "already fine" in one line>

## 5. Hardware and firmware
<health table, firmware currency, upgrade options with exact part specs>

## Could not check
<item: reason, and the elevated command that would check it>

## Questions
1. Run the safe tier? (list what that includes)
2. Which of these removals? ...
3. ...
```

Tiers: **safe** regenerates automatically or is pure cache; **review** recoverable but the user may want it (sessions, node_modules, old versions); **risky** user data, profiles, partitions, firmware.

After execution, append:

```markdown
## Applied <date>
- <change> (<freed / effect, measured>)
- Pending for user: <restart X, buy Y, reboot>
```
