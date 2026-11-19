#!/usr/bin/env python3
"""audit_core — storage core cho audit-trail (BASE 007 §5/§7).

Chỉ extractor B (hook) dùng (A đã bỏ — 007 §10). Thuần stdlib, KHÔNG LLM/network.
Ba trách nhiệm, mỗi cái test riêng được:

  upsert(existing_lines, events)  -> list[str]   # insert-or-replace theo `id`, canonical, idempotent
  render(jsonl)                   -> str          # dựng lại unit input→process→output (group-by unit_ref)
  write_sidecar(root, id, kind, payload) -> str   # payload nặng ra file, trả ref tương đối

Layout (007 §7), tương đối theo `root` (thường = cwd của hook payload):
  <root>/.specs/audit/audit-log.jsonl
  <root>/.specs/audit/diff/<id>            # edit.diff
  <root>/.specs/audit/tool-results/<id>    # tool.result
"""

from __future__ import annotations

import json
import os

# --- Layout (007 §7) ------------------------------------------------------

AUDIT_DIR = os.path.join(".specs", "audit")
LOGS_NAME = "audit-log.jsonl"
DIFF_DIRNAME = "diff"
TOOL_RESULTS_DIRNAME = "tool-results"
SAYS_DIRNAME = "says"

# kind sidecar -> thư mục
_SIDECAR_DIR = {
    "diff": DIFF_DIRNAME,             # edit.diff
    "result": TOOL_RESULTS_DIRNAME,   # tool.result
    "say": SAYS_DIRNAME,              # say.text (lời agent, 011 Bước 9)
}


def audit_dir(root="."):
    return os.path.join(root, AUDIT_DIR)


def logs_path(root="."):
    return os.path.join(audit_dir(root), LOGS_NAME)


def _dumps(obj):
    """Canonical JSON — điều kiện CẦN cho idempotent byte-identical (007 §7).

    sort_keys => thứ tự khoá ổn định; separators khít => 0 khoảng trắng thừa;
    ensure_ascii=False => giữ nguyên tiếng Việt/verbatim (007 §6 copy verbatim).
    """
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


# --- upsert ---------------------------------------------------------------

def upsert(existing_lines, events):
    """insert-or-replace theo `id` (007 §7). KHÔNG regenerate cả file.

    - existing_lines: iterable[str] — nội dung audit-log.jsonl hiện có (mỗi dòng 1 event).
    - events:         iterable[dict] — event(s) distiller vừa sinh (mỗi cái phải có `id`).
    - trả về list[str] dòng canonical, GIỮ thứ tự xuất hiện đầu tiên.

    Bất biến:
      * canonical hoá cả dòng cũ => replay/re-distill hội tụ byte-identical.
      * dedup theo id: id trùng (union-merge để lại 2 dòng) → last-wins → self-heal.
      * dòng hỏng / thiếu id → GIỮ NGUYÊN verbatim tại vị trí cũ (1 dòng hỏng không sập file, 007 §7).
    """
    entries = []       # [ [id_or_None, serialized_str], ... ] — giữ thứ tự
    index = {}         # id -> vị trí trong entries

    def _put(_id, serialized):
        if _id in index:
            entries[index[_id]][1] = serialized   # replace tại chỗ (dedup / self-heal)
        else:
            index[_id] = len(entries)
            entries.append([_id, serialized])

    for line in existing_lines:
        s = line.strip()
        if not s:
            continue
        try:
            obj = json.loads(s)
            _id = obj.get("id") if isinstance(obj, dict) else None
        except (ValueError, TypeError):
            obj, _id = None, None
        if _id is None:
            entries.append([None, s])             # verbatim — không hiểu thì không đụng
        else:
            _put(_id, _dumps(obj))

    for ev in events:
        _put(ev["id"], _dumps(ev))

    return [e[1] for e in entries]


# --- write_sidecar --------------------------------------------------------

def write_sidecar(root, event_id, kind, payload):
    """Ghi payload nặng ra sidecar, trả REF tương đối (007 §7). Tên file = id event.

    kind: "diff" (edit.diff) | "result" (tool.result) | "say" (say.text — lời agent).
    payload: str ghi thẳng; không phải str => canonical JSON.
    Trả: path tương đối từ root (vd ".specs/audit/diff/<id>") để nhét vào log line.
    """
    if kind not in _SIDECAR_DIR:
        raise ValueError("kind sidecar phải là 'diff' | 'result' | 'say', nhận: %r" % (kind,))
    rel = os.path.join(AUDIT_DIR, _SIDECAR_DIR[kind], event_id)
    abspath = os.path.join(root, rel)
    os.makedirs(os.path.dirname(abspath), exist_ok=True)
    text = payload if isinstance(payload, str) else _dumps(payload)
    with open(abspath, "w", encoding="utf-8") as f:
        f.write(text)
    return rel


# --- render ---------------------------------------------------------------

def _iter_events(jsonl):
    """jsonl: str (nội dung file) hoặc iterable[str] dòng. Bỏ dòng hỏng (không sập)."""
    if isinstance(jsonl, str):
        lines = jsonl.splitlines()
    else:
        lines = jsonl
    for line in lines:
        s = line.strip()
        if not s:
            continue
        try:
            obj = json.loads(s)
        except ValueError:
            continue
        if isinstance(obj, dict) and "kind" in obj:
            yield obj


def schema_errors(jsonl):
    """Kiểm mọi dòng khớp contract §5 → list[str] mô tả lỗi (rỗng = sạch).

    Không crash: dòng không parse được / thiếu field → gom vào danh sách lỗi
    (kèm số dòng 1-based) thay vì ném. Dùng cho Bước 3 (lab replay) + Bước 4/5.

    Spine bắt buộc theo [007 §5]:
      chung: kind∈{input,tool,edit,say} · id (str, non-empty) · meta (dict)
      input: type∈{skill,prompt} · input (dict)
      tool:  unit_ref (str) · tool (str) · result_ref (str, nếu có)
      edit:  unit_ref (str) · file (str) · op∈{create,update} · diff_ref (str)
      say:   unit_ref (str) · (text (str) | say_ref (str, non-empty))   # 011 Bước 9 — lời agent, tách spine
    """
    if isinstance(jsonl, str):
        lines = jsonl.splitlines()
    else:
        lines = list(jsonl)
    errs = []

    def _bad(i, msg):
        errs.append("dòng %d: %s" % (i, msg))

    def _nonempty_str(v):
        return isinstance(v, str) and v != ""

    for i, line in enumerate(lines, 1):
        s = line.strip()
        if not s:
            continue
        try:
            o = json.loads(s)
        except ValueError:
            _bad(i, "không parse được JSON")
            continue
        if not isinstance(o, dict):
            _bad(i, "không phải object")
            continue
        kind = o.get("kind")
        if kind not in ("input", "tool", "edit", "say"):
            _bad(i, "kind lạ: %r" % (kind,))
            continue
        if not _nonempty_str(o.get("id")):
            _bad(i, "thiếu id (str)")
        if not isinstance(o.get("meta"), dict):
            _bad(i, "thiếu meta (dict)")
        if kind == "input":
            if o.get("type") not in ("skill", "prompt"):
                _bad(i, "input.type lạ: %r" % (o.get("type"),))
            if not isinstance(o.get("input"), dict):
                _bad(i, "input.input thiếu (dict)")
        elif kind == "tool":
            if not _nonempty_str(o.get("unit_ref")):
                _bad(i, "tool.unit_ref thiếu (str)")
            if not _nonempty_str(o.get("tool")):
                _bad(i, "tool.tool thiếu (str)")
            if "result_ref" in o and not _nonempty_str(o["result_ref"]):
                _bad(i, "tool.result_ref rỗng")
        elif kind == "edit":
            if not _nonempty_str(o.get("unit_ref")):
                _bad(i, "edit.unit_ref thiếu (str)")
            if not _nonempty_str(o.get("file")):
                _bad(i, "edit.file thiếu (str)")
            if o.get("op") not in ("create", "update"):
                _bad(i, "edit.op lạ: %r" % (o.get("op"),))
            if not _nonempty_str(o.get("diff_ref")):
                _bad(i, "edit.diff_ref thiếu (str)")
        elif kind == "say":
            if not _nonempty_str(o.get("unit_ref")):
                _bad(i, "say.unit_ref thiếu (str)")
            if not (isinstance(o.get("text"), str) or _nonempty_str(o.get("say_ref"))):
                _bad(i, "say thiếu text/say_ref")
    return errs


def _agent_type_of(block):
    """agent_type của một block sub-agent — lấy meta.agent_type đầu tiên có, else '?'."""
    for ev in block:
        at = (ev.get("meta") or {}).get("agent_type")
        if at:
            return at
    return "?"


def render(jsonl):
    """audit-log.jsonl -> markdown, on-demand (007 §7). group-by unit_ref dựng lại audit-unit.

    KHÔNG inline nội dung sidecar (đó là việc mở rộng của renderer sau); chỉ hiện REF.
    Dangling tool/edit (unit_ref không khớp input nào) → nhóm riêng, KHÔNG bịa (B-Q4).

    Sub-agent (007 §11): event có meta.agent_id = sinh bên trong sub-agent → gom thành block,
    treo dưới đúng Task event qua map {agent_id → Task.tool_use_id} (đọc spawned_agent). Cây
    dựng Ở ĐÂY (render offline → miễn nhiễm thứ-tự realtime). Task cha thiếu → nhóm riêng, không bịa.

    Say (011 Bước 9): event kind:say = lời agent (tách spine bằng-chứng) → hiện thành "Say" trong
    scope tương ứng (main trong unit, sub trong block agent_id — chung cơ chế agent_id với tool/edit).
    """
    events = list(_iter_events(jsonl))

    inputs = {}                # id -> input event
    input_order = []           # id theo thứ tự xuất hiện
    children = {}              # unit_ref -> [tool|edit event ...] theo thứ tự log
    agent_map = {}             # child agent_id -> spawning Task tool_use_id (id)

    for ev in events:
        kind = ev.get("kind")
        if kind == "input":
            _id = ev.get("id")
            if _id not in inputs:
                input_order.append(_id)
            inputs[_id] = ev
        elif kind in ("tool", "edit", "say"):
            children.setdefault(ev.get("unit_ref"), []).append(ev)
            if kind == "tool" and ev.get("spawned_agent"):
                agent_map[ev["spawned_agent"]] = ev.get("id")

    task_to_agent = {tid: aid for aid, tid in agent_map.items()}
    out = ["# Audit trail", ""]

    def _emit_scope(scope, sub_by_agent, indent):
        """Render process/output của MỘT scope (main-agent hoặc 1 sub-agent).

        Khi gặp Task event đã spawn sub-agent (task_to_agent), nest block con NGAY DƯỚI
        (pop khỏi sub_by_agent để không render lại). Đệ quy → hỗ trợ agent lồng agent.
        """
        pad = "  " * indent
        procs = [k for k in scope if k.get("kind") == "tool"]
        edits = [k for k in scope if k.get("kind") == "edit"]
        says = [k for k in scope if k.get("kind") == "say"]
        if procs:
            out.append("")
            out.append("%s**Process:**" % pad)
            for k in procs:
                res = k.get("result_ref")
                tail = "result: `%s`" % res if res else "result: (thiếu)"
                if k.get("is_error"):
                    tail = "ERROR: %s" % (k.get("error") or "(không rõ)")
                out.append("%s- `%s` — %s" % (pad, k.get("tool", "?"), tail))
                aid = task_to_agent.get(k.get("id"))
                if aid and aid in sub_by_agent:
                    blk = sub_by_agent.pop(aid)
                    out.append("%s  ↳ sub-agent `%s` [%s]" % (pad, aid, _agent_type_of(blk)))
                    _emit_scope(blk, sub_by_agent, indent + 2)
        if edits:
            out.append("")
            out.append("%s**Output:**" % pad)
            for k in edits:
                out.append("%s- [%s] `%s` — diff: `%s`" % (
                    pad, k.get("op", "?"), k.get("file", "?"), k.get("diff_ref") or "(thiếu)"))
        if says:
            out.append("")
            out.append("%s**Say:**" % pad)
            for k in says:
                # render offline không đọc sidecar → hiện con trỏ (viewer inline nội dung thật)
                ref = k.get("say_ref") or ("inline" if isinstance(k.get("text"), str) else "(thiếu)")
                out.append("%s- 💬 `%s`" % (pad, ref))

    def _emit_unit(header, kids):
        out.append(header)
        # tách main-agent (không agent_id) vs sub-agent (gom theo agent_id) — 007 §11
        own, sub_by_agent = [], {}
        for k in kids:
            aid = (k.get("meta") or {}).get("agent_id")
            if aid:
                sub_by_agent.setdefault(aid, []).append(k)
            else:
                own.append(k)
        _emit_scope(own, sub_by_agent, 0)
        # sub-agent còn sót = Task cha thiếu (bị cắt / chưa đóng) → không bịa, nêu rõ (B-Q4)
        for aid, blk in sub_by_agent.items():
            out.append("")
            out.append("**sub-agent `%s` [%s] — Task cha thiếu:**" % (aid, _agent_type_of(blk)))
            _emit_scope(blk, {}, 1)
        out.append("")

    for _id in input_order:
        ev = inputs[_id]
        typ = ev.get("type", "?")
        inp = ev.get("input", {}) or {}
        if typ == "skill":
            label = "skill `/%s %s`" % (inp.get("skill", "?"), inp.get("args", "") or "")
        else:
            label = "prompt: %s" % (inp.get("prompt_text", "") or "")
        _emit_unit("## Unit %s — %s" % (_id, label.rstrip()), children.pop(_id, []))

    # dangling: tool/edit không có input mở unit (B-Q4 — hiển thị thật, không bịa)
    for unit_ref, kids in children.items():
        _emit_unit("## Unit %s — (input event thiếu)" % unit_ref, kids)

    return "\n".join(out).rstrip() + "\n"
