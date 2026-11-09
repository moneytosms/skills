#!/usr/bin/env python3
"""collect.py --mode project|global --cwd DIR --out RUN [--max-sessions N]

Reads Claude Code transcripts (~/.claude/projects/*/*.jsonl) and /insights caches
(~/.claude/usage-data) with no model calls. Writes:
  RUN/stats.json      failures, retry loops, heavy sessions, frequent commands, corrections
  RUN/batches/b*.md   condensed session excerpts for the Haiku miners (sessions /insights has not covered)
Prints a short summary.
"""
import argparse, collections, json, os, re, sys
from pathlib import Path

HOME = Path.home()
PROJECTS = HOME / ".claude" / "projects"
USAGE = HOME / ".claude" / "usage-data"
BATCH_CHARS = 60_000
MAX_BATCHES = 6
BIG_OUTPUT = 20_000
# shell plumbing: never worth a memory line
NOISE = set("head tail cat sed grep rg ls wc jq sd awk sort uniq cut tr find fd eza bat xargs tee diff mkdir cp mv rm touch "
            "python3 python bash sh test stat date sleep basename dirname readlink realpath which file printf".split())

CORRECTION = re.compile(
    r"^(no[,.! ]|nope|don'?t |do not |never |always |stop |instead|actually[, ]|remember[: ]|wrong|that'?s not|use \S+ (not|instead of) )",
    re.I,
)
SKIP_PROMPT = re.compile(r"^\s*(<|\[Request interrupted|Base directory for this skill|Caveat:)")
DENIED = re.compile(r"(permission to use .* (has been )?denied|blocked|not allowed|user (rejected|declined))", re.I)


def project_dir(cwd: str) -> Path:
    return PROJECTS / re.sub(r"[^A-Za-z0-9]", "-", cwd)


def text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(b.get("text", "") if isinstance(b, dict) else str(b) for b in content
                         if not isinstance(b, dict) or b.get("type") in ("text", None))
    return ""


def norm_cmd(tool: str, inp: dict) -> str:
    if tool == "Bash":
        cmd = re.sub(r"\s+", " ", str(inp.get("command", ""))).strip()
        cmd = re.sub(r"^(cd \S+ (&&|;) )+", "", cmd)  # drop leading cd
        return cmd[:140]
    for k in ("file_path", "path", "pattern", "url", "query", "skill", "subagent_type"):
        if k in inp:
            return f"{tool} {str(inp[k])[:120]}"
    return tool


def heads(cmd: str):
    """'cd x && pnpm test --filter a | tee y' -> ['pnpm test', 'tee']: what was actually run."""
    out = []
    for part in re.split(r"&&|\|\||;|\|", cmd):
        toks = [t for t in part.strip().split() if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t)]
        if not toks or toks[0] in ("cd", "set", "export", "echo", "printf", "true", "then", "do", "done", "fi", "for", "if", "while"):
            continue
        if os.path.basename(toks[0]) in NOISE:
            continue
        sub = next((t for t in toks[1:3] if re.match(r"^[a-z][a-z0-9:_-]*$", t)), "")
        out.append(f"{os.path.basename(toks[0])} {sub}".strip())
    return out


def parse_session(path: Path):
    s = {"id": path.stem, "project": path.parent.name, "title": "", "start": "", "end": "",
         "msgs": 0, "in": 0, "out": 0, "cache_read": 0, "cache_write": 0, "cost": None,
         "prompts": [], "failures": [], "denials": [], "big_outputs": [], "bash_ok": [], "reads": collections.Counter(),
         "last_text": ""}
    uses = {}
    try:
        lines = path.open(encoding="utf-8", errors="replace")
    except OSError:
        return None
    for line in lines:
        try:
            o = json.loads(line)
        except ValueError:
            continue
        t = o.get("type")
        if t == "ai-title":
            s["title"] = o.get("aiTitle", "")
        elif t == "cost-state":
            s["cost"] = o.get("totalCostUSD")
        if t not in ("user", "assistant"):
            continue
        ts = o.get("timestamp", "")
        s["start"] = s["start"] or ts
        s["end"] = ts or s["end"]
        m = o.get("message") or {}
        content = m.get("content")
        if t == "assistant":
            s["msgs"] += 1
            u = m.get("usage") or {}
            s["in"] += u.get("input_tokens", 0)
            s["out"] += u.get("output_tokens", 0)
            s["cache_read"] += u.get("cache_read_input_tokens", 0)
            s["cache_write"] += u.get("cache_creation_input_tokens", 0)
            for b in content if isinstance(content, list) else []:
                if b.get("type") == "tool_use":
                    inp = b.get("input") or {}
                    uses[b.get("id")] = (b.get("name", "?"), inp)
                elif b.get("type") == "text" and b.get("text"):
                    s["last_text"] = b["text"]
            continue
        # user rows: prompts and tool results
        if isinstance(content, list) and any(isinstance(b, dict) and b.get("type") == "tool_result" for b in content):
            for b in content:
                if not isinstance(b, dict) or b.get("type") != "tool_result":
                    continue
                tool, inp = uses.get(b.get("tool_use_id"), ("?", {}))
                body = text_of(b.get("content"))
                cmd = norm_cmd(tool, inp)
                if len(body) > BIG_OUTPUT:
                    s["big_outputs"].append({"cmd": cmd, "chars": len(body)})
                if b.get("is_error") in (True, "True", "true"):
                    rec = {"tool": tool, "cmd": cmd, "error": body.strip()[:300]}
                    (s["denials"] if DENIED.search(body[:400]) else s["failures"]).append(rec)
                elif tool == "Bash":
                    s["bash_ok"].append(cmd)
                if tool == "Read" and "file_path" in inp:
                    s["reads"][inp["file_path"]] += 1
            continue
        if o.get("isMeta"):
            continue
        text = text_of(content).strip()
        if text and not SKIP_PROMPT.match(text):
            s["prompts"].append(text)
    return s


def load_insights():
    out = {}
    for sub in ("facets", "session-meta"):
        d = USAGE / sub
        if not d.is_dir():
            continue
        for f in d.glob("*.json"):
            try:
                out.setdefault(f.stem, {})[sub] = json.loads(f.read_text())
            except (OSError, ValueError):
                pass
    return out


def excerpt(s) -> str:
    parts = [f"## session {s['id']} · {s['title'] or 'untitled'} · {s['start'][:10]}"]
    for p in s["prompts"][:25]:
        parts.append(f"USER: {p[:500]}")
    for f in s["failures"][:15]:
        parts.append(f"FAILED {f['cmd']}\n  -> {f['error'][:200]}")
    for d in s["denials"][:8]:
        parts.append(f"BLOCKED {d['cmd']}\n  -> {d['error'][:150]}")
    ok = collections.Counter(h for c in s["bash_ok"] for h in set(heads(c)))
    if ok:
        parts.append("COMMANDS THAT WORKED: " + "; ".join(f"{c} ×{n}" for c, n in ok.most_common(12)))
    if s["last_text"]:
        parts.append(f"LAST REPLY: {s['last_text'][:400]}")
    return "\n".join(parts) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["project", "global"], default="project")
    ap.add_argument("--cwd", default=os.getcwd())
    ap.add_argument("--out", required=True)
    ap.add_argument("--max-sessions", type=int, default=40)
    a = ap.parse_args()

    run = Path(a.out)
    (run / "batches").mkdir(parents=True, exist_ok=True)
    if a.mode == "project":
        dirs = [project_dir(a.cwd)]
        if not dirs[0].is_dir():
            print(f"no transcripts for {a.cwd} (looked in {dirs[0]})", file=sys.stderr)
            sys.exit(1)
    else:
        dirs = [d for d in PROJECTS.iterdir() if d.is_dir()]
    files = sorted((f for d in dirs for f in d.glob("*.jsonl")), key=lambda f: f.stat().st_mtime, reverse=True)
    files = files[: a.max_sessions]
    sessions = [s for s in (parse_session(f) for f in files) if s and s["msgs"]]
    insights = load_insights()

    fails = collections.defaultdict(lambda: {"count": 0, "sessions": set(), "error": ""})
    for s in sessions:
        for f in s["failures"]:
            g = fails[(f["tool"], f["cmd"])]
            g["count"] += 1
            g["sessions"].add(s["id"])
            g["error"] = g["error"] or f["error"]
    failures = sorted(({"tool": t, "cmd": c, "count": g["count"], "sessions": sorted(g["sessions"]), "error": g["error"]}
                       for (t, c), g in fails.items()), key=lambda x: -x["count"])

    retry = []
    for s in sessions:
        for (t, c), n in collections.Counter((f["tool"], f["cmd"]) for f in s["failures"]).items():
            if n >= 3:
                retry.append({"session": s["id"], "tool": t, "cmd": c, "times": n})

    denials = collections.Counter((d["tool"], d["cmd"][:80]) for s in sessions for d in s["denials"])
    ok = collections.Counter(h for s in sessions for c in s["bash_ok"] for h in set(heads(c)))
    reads = collections.Counter()
    for s in sessions:
        for p, n in s["reads"].items():
            if n >= 3:
                reads[p] += n
    corrections = [{"session": s["id"], "text": p[:300]} for s in sessions for p in s["prompts"] if CORRECTION.match(p)]

    def heavy(s):
        return {"id": s["id"], "title": s["title"], "project": s["project"], "start": s["start"], "msgs": s["msgs"],
                "tokens": s["in"] + s["out"] + s["cache_read"] + s["cache_write"], "cache_write": s["cache_write"],
                "cost": s["cost"], "failures": len(s["failures"]), "big_outputs": sorted(s["big_outputs"], key=lambda b: -b["chars"])[:5]}

    stats = {
        "mode": a.mode, "cwd": a.cwd, "sessions_read": len(sessions), "transcripts_found": len(files),
        "totals": {
            "cost": round(sum(s["cost"] or 0 for s in sessions), 2),
            "tokens": sum(s["in"] + s["out"] + s["cache_read"] + s["cache_write"] for s in sessions),
            "cache_write": sum(s["cache_write"] for s in sessions),
            "failures": sum(len(s["failures"]) for s in sessions),
            "denials": sum(len(s["denials"]) for s in sessions),
        },
        "failures": failures[:40],
        "retry_loops": sorted(retry, key=lambda r: -r["times"])[:20],
        "denials": [{"tool": t, "cmd": c, "count": n} for (t, c), n in denials.most_common(20)],
        "frequent_commands": [{"cmd": c, "count": n} for c, n in ok.most_common(30)],
        "repeated_reads": [{"path": p, "count": n} for p, n in reads.most_common(15)],
        "heavy_sessions": sorted((heavy(s) for s in sessions), key=lambda h: -h["tokens"])[:12],
        "corrections": corrections[:60],
        "insights": {sid: {k: json.dumps(v)[:2000] for k, v in d.items()} for sid, d in insights.items()
                     if any(s["id"] == sid for s in sessions)},
    }
    (run / "stats.json").write_text(json.dumps(stats, indent=1))

    # batches for the miners: only sessions /insights has not already analysed
    todo = [s for s in sessions if "facets" not in insights.get(s["id"], {})]
    batches, cur = [], ""
    for s in todo:
        e = excerpt(s)
        if cur and len(cur) + len(e) > BATCH_CHARS:
            batches.append(cur)
            cur = ""
        cur += e[:BATCH_CHARS] + "\n"
    if cur:
        batches.append(cur)
    batches = batches[:MAX_BATCHES]
    for i, b in enumerate(batches, 1):
        (run / "batches" / f"b{i}.md").write_text(b)

    t = stats["totals"]
    print(f"read {len(sessions)}/{len(files)} sessions ({a.mode}) · ${t['cost']} · {t['tokens'] / 1e6:.1f}M tokens · "
          f"{t['failures']} failed tool calls · {t['denials']} blocked · {len(retry)} retry loops · "
          f"{len(stats['insights'])} sessions with /insights data · {len(batches)} batch(es) for miners"
          + (f" (capped at {MAX_BATCHES}; {len(todo)} sessions)" if len(batches) == MAX_BATCHES else ""))


if __name__ == "__main__":
    main()
