# Focus analytics — đo gì, để vặn nút nào

Dữ liệu một người dùng, `n` nhỏ, không có ý nghĩa thống kê — chỉ có xu hướng so với
chính mình tuần trước. Nên nguyên tắc: **một metric chỉ đáng ghi nếu nó vặn được một
nút.** App có đúng 5 nút: `minutes`, `mode`/`intensity`, `nudgeGrace`, sound preset,
và giờ trong ngày bấm Start.

## Funnel

Không phải funnel sản phẩm — funnel của một buổi làm việc. Rụng ở bước nào là một câu
hỏi khác nhau:

- **Mở panel → Start.** Mở nhiều mà không start ⇒ seed-frontmost đang chọn sai window.
- **Start → sống qua 2 phút đầu.** Dưới 2 phút không phải focus, là bấm nhầm. Lọc khỏi
  mọi số khác.
- **Qua 2 phút → hết quãng.** `ended: timer` vs `user` — đây là completion rate.
- **Hết quãng → session kế trong ngày.** Retention trong một ngày đáng tin hơn tổng giờ.

## Metric ↔ nút

- **Median `first_drift`** → `minutes`. Sức tập trung thô, không bị session dài/ngắn làm
  nhiễu. Median trượt ở phút 9 mà đang đặt 25' thì 25' là con số của Cirillo, không phải
  của bạn.
- **`switches` / giờ** → `nudgeGrace`. Nhiều cú nhảy ngắn là fragmentation; grace quá
  rộng thì chúng không bao giờ bị chặn.
- **`longest`** → thước đo chất lượng thật. 25 phút mà khối liền dài nhất 4 phút thì hôm
  đó chưa focus lần nào.
- **`away` / `actual`** → `mode`/`intensity`. Tổng giờ cao mà drift ratio 40% là số giả.
- **Top app trong `apps`** → tách hai loại: Slack/Mail = bị kéo (chặn được);
  browser/terminal khác = tự đi, thường là việc đang bí. Hai loại cần hai cách sửa ngược nhau.
- **`peeks`** → tự cấp phép thoát. Tăng dần = grace quá ngặt.
- **Giờ bấm Start** → lịch làm việc. Cộng drift ratio theo khung giờ, sau hai tuần sẽ ra
  2–3 khung rẻ và vài khung vô vọng.

**Honest minutes = `on_target`**, không phải tổng giờ. Tổng giờ tính cả lúc đọc Twitter
dưới lớp dim.

**Tự A/B một nút mỗi hai tuần.** Đổi một thứ, giữ nguyên phần còn lại, đọc lại median
`first_drift`. Đây là chỗ app này hơn Toggl/RescueTime: nó vừa đo vừa là biến can thiệp.

## Dữ liệu này không nói được

Frontmost window không phải sự chú ý. Ngồi nhìn trần nhà trước IDE ra một session hoàn
hảo. Số này bắt **fragmentation**, không bắt **engagement** — đừng để nó thành điểm đạo
đức. Nó trả lời đúng một câu: *tôi có ở yên một chỗ không.*

Chưa đo được: lý do dừng khi `ended: user` (xong / bí / bị gọi / chán) — thứ duy nhất
app không suy ra được, cần một câu hỏi bốn nút lúc stop.

## Đang có gì

Trạng thái: **đang thu thập, chưa hiển thị gì.** Commit `d56876f`.

- `Focus/AttentionLog.swift` — thuần, test được không cần window server: `switches`,
  `onTarget`, `away`, `longest`, `firstDrift`, `apps[name] = (count, seconds)`.
- `Focus/SessionLog.swift` — append một dòng JSON mỗi session khi stop, vào
  `~/Library/Application Support/SoundBar/sessions.jsonl`.
- `Focus/FocusSession.swift` — `checkDrift` sample mỗi tick **trước** khi xét grace, nên
  cú liếc 3 giây (ngắn hơn `nudgeGrace`, trước đây vô hình) vẫn được đếm. Hành vi nudge
  không đổi. `stop(ended:)` ghi dòng log.
- `Tests/FocusKitTests/AttentionLogTests.swift` — 7 test.

`.unknown` (panel đang mở, peek, window mất) **đóng băng** đoạn đang chạy chứ không cắt,
nên một peek dài bị cộng vào stretch đang chạy. Tách ra nếu `peeks` lớn dần.

## Đọc lại

```sh
L=~/Library/Application\ Support/SoundBar/sessions.jsonl
wc -l "$L"                                                    # đủ ~20 dòng hẵng kết luận
jq -s 'map(.switches)|add/length' "$L"
jq -s 'map(select(.first_drift))|map(.first_drift)|sort|.[length/2|floor]' "$L"
jq -s 'map(.longest)|max' "$L"
jq -s 'map(select(.ended=="timer"))|length' "$L"
jq -s '[.[].apps|to_entries[]]|group_by(.key)
       |map({app:.[0].key,n:(map(.value.count)|add)})|sort_by(-.n)' "$L"
```

## Làm tiếp

1. Sống với số liệu ~1 tuần, rồi mới quyết metric nào đáng một dòng trong panel.
2. Ứng viên hiển thị, theo thứ tự: `longest` của session vừa xong → `switches` → top 3 app.
3. Weekly review 2 phút, không dashboard: median trượt đầu, drift ratio, top 3 app, lý do
   dừng. Nhìn xong vặn một nút rồi đóng.
4. Chưa làm, cố ý: UI, export, hỏi lý do dừng, fallback tên app khi app thoát giữa session
   (hiện trả `"window"`).
