# Attention log — đang đo gì, đọc thế nào, làm tiếp gì

Trạng thái: **đang thu thập dữ liệu, chưa hiển thị gì.** Commit `d56876f`.

## Vì sao

`FocusStats` chỉ lưu một con số mỗi ngày (tổng giây). Con số đó không phân biệt được
30 cú nhảy 5 giây với 1 lần bỏ đi 150 giây — cùng `away`, nhưng cái đầu tệ hơn nhiều vì
không còn khối liền nào đủ dài để làm việc khó. Nên đếm **số lần chuyển app**, không chỉ
thời gian rời đi.

Điểm mù đã vá: mọi cú liếc ngắn hơn `nudgeGrace` (mặc định 5s) trước đây không nudge,
không vào stats, không để lại dấu vết. Giờ sampling chạy **trước** grace, nên đếm được;
grace vẫn chỉ quyết định có shove hay không. Hành vi nudge không đổi.

## Code

- `Focus/AttentionLog.swift` — thuần, test được không cần window server. Giữ `switches`,
  `onTarget`, `away`, `longest` (khối liền dài nhất), `firstDrift`, `apps[name] = (count, seconds)`.
- `Focus/SessionLog.swift` — append một dòng JSON khi stop, vào
  `~/Library/Application Support/SoundBar/sessions.jsonl`.
- `Focus/FocusSession.swift` — `checkDrift` sample mỗi tick rồi mới xét nudge;
  `stop(ended:)` ghi dòng log. `ended` là `timer` hoặc `user`.
- `Tests/FocusKitTests/AttentionLogTests.swift` — 7 test.

`.unknown` (panel đang mở, peek, window mất) **đóng băng** đoạn đang chạy chứ không cắt.
Nghĩa là một peek dài được cộng vào stretch đang chạy — tách ra nếu `peeks` lớn dần.

## Đọc lại sau vài ngày

```sh
L=~/Library/Application\ Support/SoundBar/sessions.jsonl
wc -l "$L"                                                    # đủ 20 dòng hẵng kết luận
jq -s 'map(.switches)|add/length' "$L"                        # switch trung bình / session
jq -s 'map(select(.first_drift))|map(.first_drift)|sort|.[length/2|floor]' "$L"
jq -s 'map(.longest)|max' "$L"                                # khối liền dài nhất từng có
jq -s 'map(select(.ended=="timer"))|length' "$L"              # completion
jq -s '[.[].apps|to_entries[]]|group_by(.key)
       |map({app:.[0].key,n:(map(.value.count)|add)})|sort_by(-.n)' "$L"
```

**Median `first_drift` chính là độ dài quãng nên đặt.** Đang để 25' mà median trượt ở
phút 9 thì 25' là con số của người khác.

## Làm tiếp

1. Sống với số liệu ~1 tuần. Chỉ sau đó mới quyết metric nào đáng một dòng trong panel.
2. Ứng viên hiển thị, theo thứ tự: `longest` của session vừa xong → switch count → top 3 app.
3. Chưa làm, cố ý: UI, weekly review, export, hỏi lý do dừng khi `ended: user`,
   fallback tên app khi app thoát giữa session (hiện trả `"window"`).
