// App hiện chỉ có bản mobile (native) — client mobile gọi function qua HTTP
// client thường, không đi qua cơ chế CORS của trình duyệt nên không cần
// Access-Control-Allow-Origin. Cố tình KHÔNG đặt "*" để trình duyệt chặn
// mọi website lạ gọi thẳng các function này bằng fetch/XHR. Nếu sau này có
// bản web chính chủ, thêm "Access-Control-Allow-Origin": "https://<domain>"
// vào đây (1 chỗ duy nhất, áp dụng cho mọi function).
export const CORS_HEADERS = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
