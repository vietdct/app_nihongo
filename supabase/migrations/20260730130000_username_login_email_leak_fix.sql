-- Pha 3b — Sửa lỗ hổng bảo mật: RPC get_email_by_username trước đây cấp
-- quyền cho anon/authenticated, cho phép người CHƯA đăng nhập dò được email
-- ứng với 1 username bất kỳ (chỉ cần gọi RPC, không cần mật khẩu đúng).
-- Từ giờ chỉ service_role (Edge Function auth-login-username) mới được gọi
-- RPC này; client không còn tự tra email nữa.

revoke execute on function get_email_by_username(text) from anon, authenticated;
grant execute on function get_email_by_username(text) to service_role;
