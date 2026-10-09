# 🛡️ Vibe Arch Guard (Tài liệu Tiếng Việt)

> **Chấm dứt cái bẫy "Phải đập đi làm lại" khi Vibe Coding!**  
> Bộ khung kiểm soát kiến trúc và chống trôi dạt code (Architecture Drift) tối ưu token dành cho **Claude Code**, **Codex**, **Antigravity (Agy)** và **Cursor**.

---

## ⚡ Vấn đề: Cạm bẫy của Vibe Coding

Bạn giao việc cho AI, thấy code chạy được là tưởng đã xong. 3 tháng sau muốn thêm module mới thì kiến trúc đã thành một mớ bòng bong không scale được! Đó là vì AI luôn tìm con đường ngắn nhất để code chạy được (Happy-path), nó không tự quan tâm đến ranh giới module hay kiến trúc tổng thể.

```text
Vibe Coding thông thường:
User Prompt ➔ AI chọn đường ngắn nhất ➔ Code spaghetti ➔ Phá vỡ kiến trúc ➔ Đập đi làm lại 💥

Sử dụng Vibe Arch Guard:
User Prompt ➔ /architecture-plan (27 mục) ➔ Người duyệt ➔ Code + Tự động đồng bộ ➔ Không bao giờ trôi dạt ✅
```

---

## 🏛️ 3 Cấp độ kiểm soát kiến trúc

1. **Cấp độ 1: Test - Hỏi AI hời hợt**: Hỏi vài câu ngắn gọn. Không bao quát, chỉ để test nhanh, đừng dựa vào!
2. **Cấp độ 2: File `ARCHITECTURE.md` (27 mục) - Khuyên dùng hàng ngày**:
   - Dựng chuẩn 27 mục, trích dẫn chính xác 100% đường dẫn `file:line`.
   - Đi kèm rule tự động cập nhật trong cùng lượt làm việc khi AI sửa code.
3. **Cấp độ 3: Vẽ sơ đồ động (Interactive Simulator)**:
   - File HTML độc lập, nhẹ token, mô phỏng luồng request đi qua từng tầng (Browser ➔ Edge ➔ Gateway ➔ API ➔ DB ➔ Workers) khi trình diễn cho khách hàng hoặc sếp.

---

## 🚀 Cài đặt nhanh trong 1 phút

Chạy lệnh sau tại thư mục gốc của dự án:

```bash
curl -fsSL https://raw.githubusercontent.com/kanau-tech/vibe-arch-guard/main/scripts/install.sh | bash
```

Sau khi cài đặt, gõ lệnh `/architecture-plan` trong Claude Code hoặc Antigravity để hệ thống tự động quét code và dựng kiến trúc chuẩn.

---

## 🛡️ Cơ chế kiểm tra vật lý & CI Fail-Closed

Không chỉ dựa vào sự tự giác của AI, Vibe Arch Guard tích hợp cơ chế chặn cứng:

- **Kiểm tra cục bộ (`./scripts/verify-sync.sh`)**:
  - Tự động phát hiện khi có file logic cấu trúc thay đổi nhưng `ARCHITECTURE.md` chưa được cập nhật, trả về mã lỗi **`exit 1`** để chặn commit.
  - Kiểm tra trước khi commit: `./scripts/verify-sync.sh --staged`
- **GitHub Actions CI (`.github/workflows/arch-drift-check.yml`)**:
  - Tự động chạy trên Pull Request và Push vào nhánh `main`. Chặn merge nếu có trôi dạt kiến trúc.
  - Ngoại lệ được kiểm soát: Gắn nhãn PR `arch:no-structural-change` hoặc thêm `[skip-arch-drift]` vào commit message.

---

## 📜 Giấy phép bản quyền

MIT License © 2026 [Kanau Tech™](https://kanautech.jp).

