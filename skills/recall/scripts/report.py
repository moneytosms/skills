#!/usr/bin/env python3
"""report.py <run-dir>  ->  <run-dir>/report.html

Renders proposals.json (written by the main model) plus stats.json (from collect.py)
into one self-contained HTML page. No network, no dependencies.
"""
import html, json, sys
from pathlib import Path

run = Path(sys.argv[1])
P = json.loads((run / "proposals.json").read_text())
S = json.loads((run / "stats.json").read_text())
e = lambda x: html.escape(str(x))

KIND = {"add": "add", "trim": "trim", "merge": "merge", "setting": "setting", "hook": "hook", "skill": "skill", "memory": "memory"}
IMPACT = {"high": 3, "medium": 2, "low": 1}
props = sorted(P.get("proposals", []), key=lambda p: (-IMPACT.get(p.get("impact", "low"), 1), p["id"]))


def card(p):
    ev = p.get("evidence") or {}
    sessions = ev.get("sessions") or []
    return f"""
<article class="card {e(p.get('impact', 'low'))}" id="p{e(p['id'])}">
  <header><span class="id">#{e(p['id'])}</span><span class="chip {e(KIND.get(p.get('kind'), 'add'))}">{e(p.get('kind', 'add'))}</span>
    <h3>{e(p.get('title', ''))}</h3><span class="impact">{e(p.get('impact', 'low'))}</span></header>
  <div class="target">{e(p.get('target', ''))}</div>
  <div class="change"><pre>{e(p.get('change', ''))}</pre><button class="copy" data-copy="{e(p.get('change', ''))}">copy</button></div>
  <p class="why">{e(p.get('why', ''))}</p>
  <p class="meta"><b>Win:</b> {e(p.get('win', '–'))} · <b>Seen:</b> {e(ev.get('count', '?'))}× in {len(sessions)} session(s)</p>
  {f'<blockquote>{e(ev["quote"])}</blockquote>' if ev.get('quote') else ''}
</article>"""


groups = {}
for p in props:
    groups.setdefault(p.get("target", "other"), []).append(p)

t = S["totals"]
stat = lambda label, value: f'<div class="stat"><span>{e(label)}</span><b>{e(value)}</b></div>'
budgets = "".join(
    f'<div class="budget"><span>{e(b["file"])}</span><div class="bar"><i style="width:{min(100, round(100 * b["lines_after"] / max(1, b["budget"])))}%"'
    f' class="{"over" if b["lines_after"] > b["budget"] else ""}"></i></div><b>{e(b["lines_now"])} → {e(b["lines_after"])} / {e(b["budget"])} lines</b></div>'
    for b in P.get("budgets", []))
fails = "".join(f"<tr><td>{e(f['count'])}</td><td><code>{e(f['cmd'])}</code></td><td>{e(f['error'][:160])}</td></tr>" for f in S["failures"][:12])
def biggest(h):
    return ", ".join(f"{b['cmd'][:40]} ({b['chars'] // 1000}k)" for b in h["big_outputs"][:2])


heavy = "".join(
    f"<tr><td>{e(h['title'] or h['id'][:8])}</td><td>{h['tokens'] / 1e6:.1f}M</td><td>{'$%.2f' % h['cost'] if h['cost'] else '–'}</td>"
    f"<td>{e(h['failures'])}</td><td>{e(biggest(h))}</td></tr>"
    for h in S["heavy_sessions"][:8])
ids = [p["id"] for p in props if p.get("impact") == "high"]

page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Recall report</title><style>
:root{{--bg:#fbfaf8;--fg:#1d1b19;--dim:#6f6a64;--card:#fff;--line:#e8e4de;--acc:#c96442;--add:#2f7d4f;--trim:#b54a3c;--set:#3b6ea8;--sk:#7a52b3}}
@media (prefers-color-scheme:dark){{:root{{--bg:#1a1917;--fg:#ece8e2;--dim:#9a948c;--card:#232220;--line:#35322e;--acc:#e08a63;--add:#6cc28f;--trim:#e07b6c;--set:#7fa8de;--sk:#b394e6}}}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.55 ui-sans-serif,system-ui,sans-serif}}
main{{max-width:960px;margin:0 auto;padding:40px 16px 80px}}h1{{font-size:28px;margin:0 0 4px}}h2{{font-size:18px;margin:40px 0 12px;border-bottom:1px solid var(--line);padding-bottom:6px}}
.sub{{color:var(--dim);margin:0 0 24px}}.stats{{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px}}
.stat{{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px 14px}}.stat span{{display:block;color:var(--dim);font-size:12px;text-transform:uppercase;letter-spacing:.04em}}.stat b{{font-size:22px}}
.apply{{background:var(--card);border:1px solid var(--acc);border-radius:12px;padding:14px 16px;margin:20px 0}}.apply code{{background:var(--bg);padding:2px 6px;border-radius:6px}}
.card{{background:var(--card);border:1px solid var(--line);border-left:4px solid var(--line);border-radius:12px;padding:14px 16px;margin:10px 0}}
.card.high{{border-left-color:var(--acc)}}.card.medium{{border-left-color:var(--dim)}}
.card header{{display:flex;gap:8px;align-items:center}}.card h3{{margin:0;font-size:16px;flex:1}}.id{{font-weight:700;color:var(--acc)}}.impact{{color:var(--dim);font-size:12px}}
.chip{{font-size:11px;padding:1px 8px;border-radius:99px;border:1px solid currentColor}}.chip.add,.chip.memory{{color:var(--add)}}.chip.trim,.chip.merge{{color:var(--trim)}}.chip.setting,.chip.hook{{color:var(--set)}}.chip.skill{{color:var(--sk)}}
.target{{color:var(--dim);font:12px ui-monospace,monospace;margin:4px 0 8px}}.change{{position:relative}}
pre{{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:10px 12px;overflow:auto;font:13px/1.45 ui-monospace,monospace;margin:0}}
.copy{{position:absolute;top:6px;right:6px;border:1px solid var(--line);background:var(--card);color:var(--dim);border-radius:6px;font-size:12px;cursor:pointer}}
.why{{margin:8px 0 2px}}.meta{{color:var(--dim);font-size:13px;margin:0}}blockquote{{margin:8px 0 0;padding-left:10px;border-left:2px solid var(--line);color:var(--dim);font-size:13px}}
table{{width:100%;border-collapse:collapse;font-size:13px}}td,th{{text-align:left;padding:6px 8px;border-bottom:1px solid var(--line);vertical-align:top}}code{{font:12px ui-monospace,monospace}}
.budget{{display:grid;grid-template-columns:1fr 160px 200px;gap:10px;align-items:center;font-size:13px;margin:6px 0}}.bar{{height:6px;background:var(--line);border-radius:3px}}.bar i{{display:block;height:100%;background:var(--add);border-radius:3px}}.bar i.over{{background:var(--trim)}}
@media (max-width:600px){{.budget{{grid-template-columns:1fr}}}}
</style></head><body><main>
<h1>Recall</h1><p class="sub">{e(P.get('meta', {}).get('scope', S['mode']))} · {e(S['sessions_read'])} sessions read · {e(P.get('meta', {}).get('generated', ''))}</p>
<div class="stats">{stat('proposals', len(props))}{stat('cost', '$' + str(t['cost']))}{stat('tokens', f"{t['tokens'] / 1e6:.0f}M")}{stat('failed calls', t['failures'])}{stat('blocked', t['denials'])}{stat('cold cache writes', f"{t['cache_write'] / 1e6:.0f}M")}</div>
<div class="apply">Back in Claude, reply <code>apply {', '.join(map(str, ids)) or '1, 2'}</code> (or <code>apply all high</code>, <code>apply all</code>). Nothing is written until you do.</div>
<h2>Memory budgets</h2>{budgets or '<p class="meta">No memory files touched.</p>'}
{''.join(f'<h2>{e(target)}</h2>' + ''.join(card(p) for p in ps) for target, ps in groups.items()) or '<p>No proposals: memory already covers what the sessions show.</p>'}
<h2>Most frequent failures</h2><table><tr><th>×</th><th>command</th><th>error</th></tr>{fails or '<tr><td colspan=3>none</td></tr>'}</table>
<h2>Heaviest sessions</h2><table><tr><th>session</th><th>tokens</th><th>cost</th><th>fails</th><th>biggest outputs</th></tr>{heavy}</table>
</main><script>
document.querySelectorAll('.copy').forEach(b=>b.onclick=()=>navigator.clipboard.writeText(b.dataset.copy).then(()=>{{b.textContent='copied';setTimeout(()=>b.textContent='copy',1200)}}))
</script></body></html>"""
(run / "report.html").write_text(page)
print(run / "report.html")
