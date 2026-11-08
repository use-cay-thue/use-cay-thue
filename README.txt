# USE CÀY THUÊ – Website bản xem thử

## Mở website
- Mở `index.html` bằng trình duyệt hoặc tải cả thư mục lên hosting tĩnh.
- Trang đã có bảng giá tham khảo, form đặt đơn, mã đơn, tra cứu và trang quản trị demo.
- Mật khẩu quản trị demo ban đầu: `123456` (có thể đổi trong giao diện).

## LƯU Ý QUAN TRỌNG – trước khi dùng thật
Đây hiện là **bản frontend demo**. Đơn hàng được lưu bằng `localStorage` trong chính trình duyệt đang dùng. Vì vậy:
- Chủ shop chỉ nhìn thấy đơn được tạo trên cùng trình duyệt/thiết bị.
- Khách dùng điện thoại khác không tự động gửi dữ liệu đến thiết bị chủ shop.
- Đăng nhập demo ở phía trình duyệt không phải bảo mật production.
- Không dùng bản này để thu thập mật khẩu Roblox, OTP hoặc dữ liệu nhạy cảm.

Để triển khai đúng yêu cầu nhiều khách đặt từ nhiều thiết bị và chủ shop nhận đơn tập trung, cần kết nối backend/database (ví dụ Supabase hoặc Firebase), bật xác thực quản trị và cấu hình quyền truy cập ở server/database. Không đưa secret/service-role key vào HTML công khai.

## Thông tin shop
- Tên: USE CÀY THUÊ
- TikTok: https://www.tiktok.com/@usecaythue
- Bảng giá được nhập theo ảnh người dùng cung cấp. Giá Tộc v3 đã được chủ shop xác nhận: 30.000đ.
