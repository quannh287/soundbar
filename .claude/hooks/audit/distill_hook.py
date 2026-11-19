#!/usr/bin/env python3
"""distill_hook — extractor B (hook), REALTIME (BASE 007 §8/§10).

Đọc MỘT hook payload trên stdin, upsert 1 (hoặc vài) dòng vào audit-log.jsonl + ghi sidecar.
Chạy do HOOK HARNESS kích (ngoài agent) => giữ Cấp 2, auditor ≠ auditee (007 §8).

  distill_hook.py <label>            # label = tên hook event; payload JSON qua stdin

BẤT BIẾN:
  * exit 0 LUÔN — không bao giờ chặn tool (payload rác cũng nuốt êm).
  * concurrency-safe — read-modify-write audit-log.jsonl dưới flock (nhiều hook bắn gần nhau).
  * chỉ stdlib, 0 network/LLM, 0 đọc lại transcript/file-history (B single-source từ hook — B-Q3).

meta.ts: hook KHÔNG mang timestamp => đóng dấu tại lúc hook chạy (approx event-time,
hợp lệ Cấp 2 vì harness kích đồng bộ). Env AUDIT_NOW cố định clock cho test.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audit_core  # noqa: E402

# label -> kind (007 §5). Ngoài danh sách này => None (bỏ: PermissionDenied + control/UI/env, 010 §B1).
_TOOL_LABELS = {"PreToolUse", "PostToolUse", "PostToolUseFailure", "PostToolBatch"}
_INPUT_LABELS = {"UserPromptSubmit", "UserPromptExpansion"}
# say = lời agent (011 Bước 9). main ← MessageDisplay(final); sub ← SubagentStop. Bỏ Stop (dư),
# StopFailure, thinking (không hook nào mang — 007 §2.B).
_SAY_LABELS = {"MessageDisplay", "SubagentStop"}

_EDIT_OP = {"Write": "create", "Edit": "update"}


def classify(label, payload):
    """label -> kind ('input'|'tool'|'say'|None). None = event bỏ qua."""
    if label in _INPUT_LABELS:
        return "input"
    if label in _TOOL_LABELS:
        return "tool"
    if label in _SAY_LABELS:
        return "say"
    return None


def _now():
    return os.environ.get("AUDIT_NOW") or (
        datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat()
    )


def _git_branch(root):
    """Best-effort, 0 subprocess: đọc .git/HEAD. Không có => None (meta best-effort)."""
    try:
        with open(os.path.join(root, ".git", "HEAD"), encoding="utf-8") as f:
            head = f.read().strip()
        return head[16:] if head.startswith("ref: refs/heads/") else head[:12]
    except OSError:
        return None


def _meta(payload, root):
    m = {"session_id": payload.get("session_id"), "ts": _now()}
    br = _git_branch(root)
    if br:
        m["gitBranch"] = br
    # Sub-agent (007 §11): event SINH BÊN TRONG một sub-agent mang agent_id + agent_type ở
    # top-level payload (mọi event, PostToolBatch cũng top-level chứ không per-tool_calls[]);
    # main-agent thì hai field này vắng/None => tag để render dựng cây, 0 heuristic.
    aid = payload.get("agent_id")
    if aid:
        m["agent_id"] = aid
        at = payload.get("agent_type")
        if at:
            m["agent_type"] = at
    return m


def _extract_input(label, payload, root):
    """input event — mở unit (007 §5). id = prompt_id (segmentation 0-heuristic).

    UserPromptExpansion(slash_command) => type:skill (đè cùng id prompt của UserPromptSubmit).
    Ngược lại UserPromptSubmit => type:prompt.
    """
    pid = payload.get("prompt_id")
    if pid is None:
        return []
    if label == "UserPromptExpansion" and payload.get("expansion_type") == "slash_command":
        ev = {"kind": "input", "id": pid, "type": "skill",
              "input": {"skill": payload.get("command_name"),
                        "args": payload.get("command_args", "")},
              "meta": _meta(payload, root)}
        return [ev]
    if label == "UserPromptSubmit":
        return [{"kind": "input", "id": pid, "type": "prompt",
                 "input": {"prompt_text": payload.get("prompt", "")},
                 "meta": _meta(payload, root)}]
    return []  # UserPromptExpansion không phải slash_command: bỏ (UserPromptSubmit đã mở unit)


def _tool_call_event(call, unit_ref, meta, root, has_result):
    """Dựng 1 tool event (+ edit event nếu Write/Edit) từ 1 tool-call dict.

    `call` mang: tool_name, tool_input, tool_use_id, [tool_response], [error, is_interrupt].
    has_result=True khi payload là Post/Batch (có tool_response) => ghi result sidecar.
    """
    tid = call.get("tool_use_id")
    tool = call.get("tool_name")
    tool_input = call.get("tool_input", {})
    events = []

    ev = {"kind": "tool", "id": tid, "unit_ref": unit_ref,
          "tool": tool, "tool_input": tool_input, "meta": meta}

    if call.get("error") is not None:
        ev["is_error"] = True
        ev["error"] = call.get("error")

    if has_result and "tool_response" in call:
        resp = call["tool_response"]
        # Task/Agent spawn sub-agent => tool_response.agentId = id sub-agent con.
        # Ghi map {child agent_id -> Task tool_use_id} NGAY TRÊN Task event (007 §11):
        # id của event này CHÍNH LÀ tool_use_id, nên chỉ cần đính agent_id con.
        if isinstance(resp, dict) and resp.get("agentId"):
            ev["spawned_agent"] = resp["agentId"]
        # persistedOutputPath: harness đã ghi full ra file => copy trọn (không cắt ~30k)
        payload_out = resp
        if isinstance(resp, dict) and resp.get("persistedOutputPath"):
            try:
                with open(resp["persistedOutputPath"], encoding="utf-8") as f:
                    payload_out = f.read()
            except OSError:
                payload_out = resp
        ev["result_ref"] = audit_core.write_sidecar(root, tid, "result", payload_out)

    events.append(ev)

    # Write/Edit vừa là tool (process) vừa là edit (output) => 2 id rời (011 §Bước2, edit.id = tid+"#edit")
    if tool in _EDIT_OP:
        fp = tool_input.get("file_path")
        if tool == "Edit":
            diff_payload = {"old_string": tool_input.get("old_string", ""),
                            "new_string": tool_input.get("new_string", ""),
                            "replace_all": tool_input.get("replace_all", False)}
        else:  # Write
            diff_payload = tool_input.get("content", "")
        diff_ref = audit_core.write_sidecar(root, tid + "#edit", "diff", diff_payload)
        events.append({"kind": "edit", "id": tid + "#edit", "unit_ref": unit_ref,
                       "file": fp, "op": _EDIT_OP[tool], "diff_ref": diff_ref, "meta": meta})

    return events


def _extract_tool(label, payload, root):
    unit_ref = payload.get("prompt_id")
    meta = _meta(payload, root)
    has_result = label in ("PostToolUse", "PostToolBatch")
    if label == "PostToolBatch":
        events = []
        for call in payload.get("tool_calls", []):
            events.extend(_tool_call_event(call, unit_ref, meta, root, has_result))
        return events
    return _tool_call_event(payload, unit_ref, meta, root, has_result)


def _extract_say(label, payload, root):
    """say event — lời agent (011 Bước 9). TÁCH khỏi spine bằng-chứng, gắn thẻ lọc riêng.

    Lời có thể dài => luôn ghi sidecar says/<id>, giữ `say_ref` (lazy-fetch như tool-result).
    unit_ref = prompt_id (gom vào đúng unit). id namespace "#say" (rời khỏi tool/edit).

      main ← MessageDisplay(final:true): id = message_id+"#say", text = delta (toàn văn segment).
             KHÔNG agent_id => meta không tag => render coi là main. Nhiều say/unit (interleaved).
      sub  ← SubagentStop: id = agent_id+"#say", text = last_assistant_message (câu chốt).
             agent_id top-level => _meta tag agent_id/agent_type => render treo vào block sub-agent.

    Chỉ `final:true` cho MessageDisplay (đo 2026-07-14: final mang TOÀN VĂN segment; delta
    streaming bỏ). Thiếu id/text => bỏ (không đẻ say rỗng).
    """
    unit_ref = payload.get("prompt_id")
    if label == "MessageDisplay":
        if not payload.get("final"):
            return []
        mid = payload.get("message_id")
        text = payload.get("delta")
        if not mid or not text:
            return []
        sid = mid + "#say"
    else:  # SubagentStop
        aid = payload.get("agent_id")
        text = payload.get("last_assistant_message")
        if not aid or not text:
            return []
        sid = aid + "#say"
    say_ref = audit_core.write_sidecar(root, sid, "say", text)
    return [{"kind": "say", "id": sid, "unit_ref": unit_ref,
             "say_ref": say_ref, "meta": _meta(payload, root)}]


def extract(label, payload, root):
    """payload -> list[event dict] (007 §5). Side-effect: ghi sidecar cho result/diff/say."""
    kind = classify(label, payload)
    if kind == "input":
        return _extract_input(label, payload, root)
    if kind == "tool":
        return _extract_tool(label, payload, root)
    if kind == "say":
        return _extract_say(label, payload, root)
    return []


def _resolve_root(payload):
    return os.environ.get("AUDIT_ROOT") or payload.get("cwd") or os.getcwd()


def _drop_input_downgrades(existing_lines, events):
    """skill input là AUTHORITATIVE — 1 prompt input KHÔNG được đè skill cùng id.

    Realtime hook có thể bắn UserPromptExpansion(skill) TRƯỚC UserPromptSubmit(prompt)
    cùng prompt_id (đã thấy trong corpus thật). Nếu để prompt đè, mất phân loại skill.
    Không sniff chữ '/' (B-Q6): chỉ dựa type:skill đã ghi => bỏ prompt event trùng id.
    """
    skill_ids = set()
    for line in existing_lines:
        s = line.strip()
        if not s:
            continue
        try:
            o = json.loads(s)
        except ValueError:
            continue
        if isinstance(o, dict) and o.get("kind") == "input" and o.get("type") == "skill":
            skill_ids.add(o.get("id"))
    if not skill_ids:
        return events
    return [e for e in events
            if not (e.get("kind") == "input" and e.get("type") == "prompt"
                    and e.get("id") in skill_ids)]


def _carry_spawned_agent(existing_lines, events):
    """`spawned_agent` là AUTHORITATIVE — không để event sau xoá nó (007 §11 map).

    Tool Agent/Task bắn CẢ individual PostToolUse (tool_response = dict, mang agentId) LẪN
    PostToolBatch (tool_response = list content, KHÔNG agentId). Upsert last-wins theo id →
    nếu batch (không agentId) bắn sau, nó ghi đè line và xoá spawned_agent. Fix: khi event mới
    cho id X thiếu spawned_agent nhưng line cũ đã có → carry-forward (giống _drop_input_downgrades).
    Order-independent: Post-trước-Batch (carry giữ) hay Batch-trước-Post (Post set thẳng) đều sống.
    """
    have = {}
    for line in existing_lines:
        s = line.strip()
        if not s:
            continue
        try:
            o = json.loads(s)
        except ValueError:
            continue
        if isinstance(o, dict) and o.get("spawned_agent") and o.get("id"):
            have[o["id"]] = o["spawned_agent"]
    if not have:
        return events
    for e in events:
        if e.get("kind") == "tool" and not e.get("spawned_agent") and e.get("id") in have:
            e["spawned_agent"] = have[e["id"]]
    return events


def _write_locked(root, events):
    """read-modify-write audit-log.jsonl dưới flock (concurrency, 007 §7)."""
    import fcntl
    path = audit_core.logs_path(root)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    lock_path = os.path.join(audit_core.audit_dir(root), ".lock")
    with open(lock_path, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            try:
                with open(path, encoding="utf-8") as f:
                    existing = f.readlines()
            except OSError:
                existing = []
            events = _drop_input_downgrades(existing, events)
            events = _carry_spawned_agent(existing, events)
            merged = audit_core.upsert(existing, events)
            tmp = path + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                f.write("\n".join(merged) + ("\n" if merged else ""))
            os.replace(tmp, path)
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def main(argv=None):
    ap = argparse.ArgumentParser(description="distill 1 hook event -> audit log (realtime)")
    ap.add_argument("label", help="tên hook event (UserPromptSubmit|PreToolUse|...)")
    args = ap.parse_args(argv)

    raw = sys.stdin.read()
    payload = json.loads(raw)          # payload rác => ValueError => nuốt ở except dưới
    if not isinstance(payload, dict):
        return
    root = _resolve_root(payload)
    events = extract(args.label, payload, root)
    if events:
        _write_locked(root, events)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass          # BẤT BIẾN: không bao giờ chặn tool (007 §8) — exit 0 luôn
    sys.exit(0)
