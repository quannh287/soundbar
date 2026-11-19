# `hooks/` — mọi script được một hệ thống khác gọi

`bin/cli.js install` copy thư mục này sang `.claude/hooks/` của consumer và cắm vào `.claude/settings.json`.

**Đây là câu trả lời duy nhất cho "hook ở đâu".** Chia theo **concern**, không theo event:

```
hooks/
├── audit/       hook của audit trail — bắt payload, ghi log
└── implement/   hook + phép kiểm của /implement
```

Hai concern dùng cùng một cơ chế (harness gọi command ngoài agent, JSON qua stdin, đọc exit code) nhưng phục vụ hai mục đích không liên quan gì nhau — trộn chung một dir là để tiện tay quyết định kiến trúc.

## `audit/` — ghi bằng chứng

| File | Được gọi bởi | Làm gì |
| --- | --- | --- |
| `audit-distill.sh` | Claude Code — **8 event**, matcher `*` | Wrapper: đọc payload stdin → `distill_hook.py`. **LUÔN `exit 0`** |
| `distill_hook.py` | `audit-distill.sh` | Distill payload → upsert 1 dòng vào `.specs/audit/logs.jsonl` |
| `audit_core.py` | `distill_hook.py` | Storage core: upsert · sidecar · render · schema |

Phần **xem** log không ở đây — nó ở [`../audit/`](../audit/) (`serve.py` + `audit-log-viewer.html`), gọi bởi skill `/audit-log-viewer`, không phải bởi harness.

## `implement/` — gác vòng lặp `/implement`

| File | Được gọi bởi | Làm gì |
| --- | --- | --- |
| `implement-mark.sh` + `implement_mark.py` | Claude Code — **`UserPromptSubmit`** *và* `PreToolUse` matcher `Skill` | Prompt mở đầu `/implement …` **hoặc** `Skill(implement)` ⇒ ghi marker `.specs/integrations/{slug}/.implement-running` (nội dung = `session_id`). Mọi thứ khác đi qua im lặng |
| `implement-guard.sh` + `implement_guard.py` | Claude Code — `Stop`, matcher `*` | Nhắc lại nếu `implement-log.md` chưa đóng |
| `check-implement-postcondition.sh` | **người**, trước khi merge | Kiểm `todo.md` hết `[ ]` · `reviewed_sha` vòng review cuối `== HEAD` · vòng đó sạch |

**Vì sao marker cắm ở hai event.** Slash command chạy skill **không** sinh tool call `Skill` nào — đo được bằng hook probe: gõ `/probeskill` thì skill chạy nhưng `PreToolUse` matcher `Skill` **không bắn**; bảo model *invoke skill probeskill* thì mới bắn. Chỉ cắm `PreToolUse` là cả tầng hook nằm im đúng ở cách dùng phổ biến nhất (`/implement 004`). `UserPromptSubmit` mang nguyên văn `prompt` + `session_id` + `cwd`, đủ cho marker. Hai event ghi cùng một marker cùng nội dung nên bắn cả hai vô hại.

**`check-implement-postcondition.sh` không phải hook của Claude Code** — nó là phép kiểm người gõ tay. Nó ở đây vì đích dài hạn của nó là một git hook (`pre-push`) hoặc một bước CI, và vì tách một dir riêng cho đúng một script thì tệ hơn.

### Luôn bật — không có công tắc

Hai hook `implement-*` chạy ngay sau khi cài, không cần biến môi trường nào.

Trước đây chúng nằm sau `SPEC_LITE_GUARD=1` (opt-in). Bỏ công tắc vì lý lẽ giữ nó ước lượng sai **bán kính ảnh hưởng**: việc đầu tiên `Stop` hook làm là tìm marker, và

```
không có marker      → exit 0     ← người chưa từng gõ /implement: KHÔNG BAO GIỜ chạm tới
marker session khác  → exit 0     ← marker cũ hoặc của lượt song song: không đụng
marker mình, log đóng→ exit 0 + dọn marker
marker mình, log mở  → chặn
```

Người cài kit mà không dùng `/implement` chỉ trả giá **một lệnh `glob` mỗi lần kết lượt**. Chỉ ai đã thật sự chạy `/implement` rồi bỏ dở mới bị chặn — đúng người cần bị chặn. Một công tắc mặc định tắt thì cơ chế chỉ bảo vệ được người đã biết nó tồn tại, tức không bảo vệ ai cả.

Ba lớp phanh thay cho công tắc: **D18c** chỉ chặn khi *có tiến triển* (kẹt là thả) + trần cứng 10 · **fail-open tuyệt đối** ở mọi nhánh lỗi · **đường thoát in ngay trong thông điệp chặn** (`rm` marker, hoặc gỡ hook khỏi `settings.json`).

## Fail-open — luật chung của cả hai concern

Mọi nhánh lỗi (`python3` vắng · payload lạ · không tìm được `.specs/`) đều `exit 0`. Hook chặn vì **chính nó** lỗi thì người dùng tự khoá mình ra khỏi session, sửa được duy nhất bằng cách vá `settings.json` bằng tay.

## `.capture/`

Payload thô bắt được lúc điều tra, **không commit, không ship** (`.gitignore` riêng bên trong). `bin/cli.js` bỏ qua mọi entry bắt đầu bằng `.` khi copy managed dir.

## Đổi chỗ script = phải viết lại `settings.json`

Bản cài cũ có command trỏ `.claude/audit/audit-distill.sh`. Hook trỏ vào file **không tồn tại** là nguy hiểm thật, không phải rác vô hại: audit cắm cả `PreToolUse` matcher `*`, nên mọi tool call sẽ đi qua một command chết. `bin/cli.js` có `migrateHookPaths` viết lại **tại chỗ** (giữ nguyên argument event, không nhân entry) — thêm đường di chuyển mới vào `HOOK_PATH_MOVES` nếu lại đổi chỗ.
