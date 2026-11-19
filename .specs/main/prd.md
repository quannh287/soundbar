---
id: prd
type: prd
status: draft
owner: "quan.nguyen"
project_name: "SoundBar"
template_version: 2
id_counters:
  feature: 8
  component: 4
---

# Product Requirements Document

## Problem Statement

macOS đã ship 16 Background Sounds nhưng chỉ cho bật **một** sound mỗi lần, volume chôn trong Accessibility settings, và nó tắt theo các toggle hệ thống khác. Người cần nền âm để tập trung hoặc ngủ phải mở app bên thứ ba có tài khoản, quảng cáo, hoặc stream từ mạng.

SoundBar lấy chính bộ sound đó, cho layer nhiều cái một lúc ngay trên menu bar, offline, không tài khoản.

## Target Users

| Persona | Mục tiêu | Pain Point hiện tại |
| --- | --- | --- |
| Knowledge worker | Nền âm che tiếng ồn văn phòng/nhà trong lúc làm việc | Một sound đơn điệu; app ambient khác nặng, có tài khoản/quảng cáo |
| Light sleeper | Mix mưa + đêm nhẹ, tự tắt sau khi đã ngủ | Background Sounds không mix được, không có timer tiện tay |
| Mac tinkerer | App gọn, không telemetry, cài bằng Homebrew | App ambient trên App Store đóng hộp, không kiểm được nó gửi gì ra ngoài |

## Scope

### In Scope

- Mix nhiều sound cùng lúc, volume riêng từng sound cộng một master.
- Tải sound theo nhu cầu từ catalog MobileAsset của Apple, tái dùng bản hệ thống đã tải.
- Preset: 6 cái built-in, cộng preset người dùng (save/update/rename/delete).
- Timer mute toàn bộ sau 30 hoặc 60 phút.
- Icon menu bar động khi đang phát.
- Khôi phục mix và master khi mở lại app.
- Open at Login qua `SMAppService`.
- Chỉ một instance chạy tại một thời điểm.

### Out of Scope

- Sound ngoài 16 cái của Apple (import file riêng) — phạm vi là "mixer cho Background Sounds", không phải player tổng quát.
- Đồng bộ với toggle ComfortSounds của System Settings — app tự phát audio thay vì drive engine của Apple; không có API công khai để đồng bộ hai chiều.
- iOS/iPadOS — menu bar là trung tâm của sản phẩm.
- Notarized DMG / App Store — Homebrew build-from-source nên Gatekeeper không bao giờ thấy file quarantined.
- EQ, fade in/out, crossfade thủ công — shuffle variation đã xử lý chỗ nối.

## Features

| ID | Feature | Mô tả | Priority | Status |
| --- | --- | --- | --- | --- |
| F-001 | sound-mixing | Bật/tắt nhiều sound cùng lúc, mỗi cái một volume, cộng master | High | DONE |
| F-002 | sound-download | Chạm sound chưa có → tải từ catalog Apple kèm progress, xong tự phát | High | DONE |
| F-003 | preset-management | Áp 6 preset built-in; lưu mix hiện tại thành preset riêng, update/rename/delete | High | DONE |
| F-004 | mute-timer | Hẹn tắt toàn bộ sau 30 hoặc 60 phút | Medium | DONE |
| F-005 | menu-bar-indicator | Icon equaliser động khi đang phát, icon tĩnh khi im | Medium | DONE |
| F-006 | session-resume | Mix + master được lưu và tự phát lại khi mở app | High | DONE |
| F-007 | open-at-login | Bật/tắt khởi động cùng macOS, trạng thái đọc lại từ hệ thống | Low | DONE |
| F-008 | instance-takeover | Bản mới mở lên tự đóng bản đang chạy, tránh phát chồng sau `brew upgrade` | Low | DONE |

## Components

| ID | Component | Mô tả ngắn | Status |
| --- | --- | --- | --- |
| C-001 | sound-catalog | Bọc MobileAsset của Apple: parse catalog `mesu.apple.com`, tìm bản hệ thống trong `/System/Library/AssetsV2`, tải + giải nén vào Application Support | DONE |
| C-002 | audio-playback | Nền phát âm dùng chung: một AVAudioEngine, một node mỗi sound, shuffle variation, volume per-node cộng master | DONE |
| C-003 | menu-bar-shell | Status item, popover và layer của icon; mặt UX của icon thuộc F-005 | DONE |
| C-004 | login-item | Bọc `SMAppService`: register/unregister và đọc lại trạng thái thật | DONE |

Boundary của preset store và mix state phụ thuộc cách carve lõi nghiệp vụ → Derived, để `/spec-sad` chốt.

## Non-Functional Requirements

| ID | Category | Requirement | Target | Priority |
| --- | --- | --- | --- | --- |
| NFR-P01 | Performance | CPU của app khi đang phát | ≤ 1.5% một core với 3 sound (Apple silicon, đo bằng `top`) | High |
| NFR-P02 | Performance | Icon động không tốn CPU mỗi frame | 0 công việc app-side mỗi frame — Core Animation chạy, không timer | High |
| NFR-P03 | Performance | Bộ nhớ thường trú khi đang phát | ≤ 25 MB `phys_footprint` với 3 sound | Medium |
| NFR-P04 | Performance | Panel không chạm filesystem khi render | 0 lần stat thư mục / đọc plist trong body của tile | High |
| NFR-P05 | Performance | Chỗ nối khi lặp sound | Không có khoảng lặng — luôn có ≥ 2 file đã queue sẵn mỗi node | High |
| NFR-A01 | Availability | Mất mạng hoặc catalog lỗi | App vẫn mở và phát được mọi sound đã tải; không crash, không chặn UI | High |
| NFR-A02 | Availability | Tránh tải lại sound hệ thống đã có | 0 byte tải về khi `/System/Library/AssetsV2` đã có sound đó | Medium |
| NFR-SE01 | Security | Lưu lượng mạng | Chỉ tới `mesu.apple.com`; không telemetry, không analytics, không tài khoản | High |
| NFR-SE02 | Security | Dữ liệu người dùng | Chỉ UserDefaults (mix, master, preset) cộng audio trong Application Support; không rời máy | High |

## Business Constraints

- macOS 13+ — `SMAppService` và `NSApp.activate()` không có ở bản cũ hơn — constraint
- Không Xcode project, không dependency, toàn bộ trong `main.swift` cộng `build.sh` — constraint
- Phân phối duy nhất qua Homebrew tap (`quannh287/tap/soundbar`), chữ ký ad-hoc — constraint
- Catalog MobileAsset là endpoint công khai không có hợp đồng; Apple đổi schema hoặc URL là app mất khả năng tải sound mới — assumption (hiện 16 sound, self-check `--list` chốt con số này)
- Audio của Apple chỉ được dùng tại chỗ, không redistribute — app tải từ nguồn Apple chứ không host lại — constraint
