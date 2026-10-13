-- Seed N2 — Kanji (bộ thẻ "Hán tự Tanoshii", nguồn PDF kanji_N2.pdf, 32 trang, lưới ~20 ô/trang).
-- Mỗi ô gồm: chữ Hán, âm Hán Việt, một từ ghép nghĩa tiếng Việt, âm On-yomi katakana, và một
-- câu chuyện/mẹo ghi nhớ (mnemonic) bằng tiếng Việt — đây là điểm mạnh riêng của nguồn này.
-- Tổng số ô kanji đọc được trong PDF: 635 (20 ô/trang cho Trang 1-31, riêng Trang 32 chỉ có
-- 15 ô vì hàng cuối trang bỏ trống — không phải 32 × 20 = 640 như ước tính ban đầu).
-- Trong 635 ô có 6 ô là chính nguồn PDF này lặp lại một ký tự đã giới thiệu ở trang trước đó
-- (穫, 既, 蓄, 描, 謡, 郎) — mỗi ký tự chỉ tạo 1 dòng trong bảng kanji (unique theo character),
-- ô lặp lại chỉ giữ mnemonic của lần xuất hiện đầu tiên, các ô sau bị bỏ qua khi insert (xem
-- ghi chú tại từng insert block bên dưới để biết chính xác ô nào bị bỏ qua và tại trang nào).
-- => Tổng số dòng kanji thực sự được insert (kanji phân biệt): 629.
--
-- Giới hạn đã biết (nguồn PDF không cung cấp, KHÔNG tự bịa):
--   - kunyomi: NULL (nguồn không liệt kê âm Kun riêng).
--   - stroke_count, stroke_data (SVG nét vẽ), components: NULL.
--   - example_jp/example_vi: NULL (nguồn chỉ có 1 từ ghép ngắn, đã đưa vào meaning_vi,
--     không có câu ví dụ đầy đủ).
--   - onyomi: để mảng rỗng ARRAY[]::text[] nếu ô không ghi rõ âm On.
--   - mnemonic: nguyên văn câu chuyện ghi nhớ trong ô (đầy đủ, có giữ chú thích bộ thủ trong
--     ngoặc như trong sách).
--
-- Kanji trùng với chữ đã seed ở N5/N4 (unique index toàn cục trên `character`) sẽ tự bị
-- `on conflict (character) do nothing` bỏ qua — không ảnh hưởng dữ liệu cũ.
--
-- lessons: chia theo "ngày học" (không gắn giáo trình) — nhóm 12 kanji liên tiếp theo đúng thứ
-- tự xuất hiện trong PDF = 1 ngày. order_index bắt đầu từ 1001 (range riêng, không đụng lesson
-- ngữ pháp/từ vựng N2 khác). lesson_items JOIN qua `character` để lấy đúng id thật trong bảng
-- kanji (tránh lệch id khi 1 chữ đã tồn tại từ N5/N4 với id khác id tự sinh ở đây).
--
-- Idempotent: UUID cố định (uuid5, namespace app-nihongo:n2:kanji:<character> /
-- app-nihongo:n2:lesson:kanji:day:<NN>), on conflict an toàn — chạy lại không nhân đôi dữ liệu.
--
-- Chạy: supabase db query --linked -f supabase/seed_content_n2_kanji.sql

-- ─────────────────────────────────────────────────────────────
-- Kanji — Trang 1-4 (kanji 1-80)
-- ─────────────────────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('e6a9b7ea-36ac-543a-95ef-8513c976e6db'::uuid, '握', ARRAY['アク']::text[], ARRAY['ác']::text[], ARRAY['cầm nắm']::text[], 'Kẻ ÁC lấy tay (扌) cầm nắm cả căn phòng ÓC (屋)'),
  ('e9d6284e-83e2-528c-b2d3-bfff1d7c6500'::uuid, '扱', ARRAY['キュウ']::text[], ARRAY['tráp']::text[], ARRAY['đối xử']::text[], 'TAY (扌) run lập CẬP (及) khi bưng TRÁP'),
  ('26aab77f-e3a0-51f0-8ba8-1ad43153f429'::uuid, '依', ARRAY['イ']::text[], ARRAY['ỷ']::text[], ARRAY['ỷ lại']::text[], 'Người (イ) mặc Y (衣) phục thường hay ỉ lại'),
  ('f0a3f3fa-bea7-5342-926d-93f42f10fee9'::uuid, '威', ARRAY['イ']::text[], ARRAY['uy']::text[], ARRAY['uy quyền']::text[], 'MỘT (一) người PHỤ NỮ (女) mà THÀNH CÔNG (成) thì thường có cái UY rất lớn'),
  ('158bff54-67dc-5487-8e5e-d1dfabdfa223'::uuid, '為', ARRAY['イ']::text[], ARRAY['vi']::text[], ARRAY['hành vi']::text[], 'Đốt lửa (灬) dưới ruộng bậc thang là hành vi xấu'),
  ('5196779e-e101-5927-a254-f4c898113e95'::uuid, '偽', ARRAY['ギ']::text[], ARRAY['ngụy']::text[], ARRAY['ngụy biện']::text[], 'Người (イ) mà làm hành vi (為) này là NGỤY BIỆN'),
  ('8bbca087-c57b-5b3e-af49-1b3e1e68394c'::uuid, '偉', ARRAY['イ']::text[], ARRAY['vĩ']::text[], ARRAY['vĩ đại']::text[], 'Người (イ) làm lên điều vĩ đại (韋)'),
  ('4013249f-c566-565a-b16f-a522ea9be242'::uuid, '違', ARRAY['イ']::text[], ARRAY['vi']::text[], ARRAY['sai khác']::text[], 'Vi (韋) làm sai nên chạy (辶) trên đường'),
  ('8d283986-d379-50d4-85d3-96d30b35d9ca'::uuid, '維', ARRAY['イ']::text[], ARRAY['duy']::text[], ARRAY['buộc']::text[], 'Thằng DUY dùng chỉ (糸) buộc chim (隹)'),
  ('8ecd49b3-bf1d-513e-b11d-b2a235ef8259'::uuid, '緯', ARRAY['イ']::text[], ARRAY['vĩ']::text[], ARRAY['vĩ độ']::text[], 'Vi (韋) dùng sợi chỉ (糸) làm vĩ độ (緯)'),
  ('92005a14-73f9-52dd-81dd-1c4c4e073f2b'::uuid, '壱', ARRAY['イチ']::text[], ARRAY['nhất']::text[], ARRAY['số một']::text[], 'Võ sĩ (士) cầm khăn (冖) và thìa (匕) là số 1'),
  ('62441719-59a0-5632-a65c-c395482aaacc'::uuid, '芋', ARRAY['ウ']::text[], ARRAY['dự']::text[], ARRAY['củ khoai']::text[], 'Cô THẢO (艹) DỰ đi đào khoai bằng tay (于)'),
  ('2b71c953-2e09-560d-b180-be03709c6923'::uuid, '陰', ARRAY['イン']::text[], ARRAY['âm']::text[], ARRAY['âm u']::text[], 'Bây giờ (今) hai (二) người đang riêng tư (厶) ở vùng đất (阝) ÂM u'),
  ('f43192e7-2411-5014-aa4c-cfe9ef1855e3'::uuid, '隠', ARRAY['イン']::text[], ARRAY['ẩn']::text[], ARRAY['ẩn giấu']::text[], 'Lấy móng (爪) tay móc tim (心) bạn Yo (ヨ) giấu vào đống đất (阝)'),
  ('d1887c41-2aa2-50bf-b304-e0271947d5f3'::uuid, '影', ARRAY['エイ']::text[], ARRAY['ảnh']::text[], ARRAY['ảnh hưởng']::text[], 'Mặt trời (日) mọc trên KINH ĐÔ (京) bóng (彡) nắng chiếu ngang đẹp như một bức ẢNH'),
  ('6d62512b-ed4b-5e9c-ada2-8278d3b49867'::uuid, '鋭', ARRAY['エイ']::text[], ARRAY['nhuệ']::text[], ARRAY['nhọn sắc']::text[], 'HUYNH (兄) đệ kiếm được nhiều tiền (金) là tinh nhuệ'),
  ('e14f5abb-e53e-5585-9db6-7be474f5166e'::uuid, '越', ARRAY['エツ']::text[], ARRAY['việt']::text[], ARRAY['vượt qua']::text[], 'Qua (戈) nước Hán (厂) là tới nước Việt (越)'),
  ('1f2cacf2-d8d6-595d-8bbf-ad6d246ece6b'::uuid, '援', ARRAY['エン']::text[], ARRAY['viện']::text[], ARRAY['chi viện']::text[], 'Bằng hữu (友) đưa tay (扌) và móng (爫) đến tiếp VIỆN (援)'),
  ('5b455a37-9efc-5e8c-8d79-b608ee6565e6'::uuid, '煙', ARRAY['エン']::text[], ARRAY['yên']::text[], ARRAY['khói']::text[], 'Lửa (火) chảy bốc khói ở vùng đất (土) phía tây (西)'),
  ('54d6f7f1-e9eb-588d-b603-e1d02f2e105d'::uuid, '鉛', ARRAY['エン']::text[], ARRAY['duyên']::text[], ARRAY['chất chì']::text[], 'Cho dù là vàng (金) mà qua tám (八) cái miệng (口) thì cũng thành chì (鉛)'),
  ('69b04ace-792b-5aab-8e8b-3bd633f894e7'::uuid, '縁', ARRAY['エン']::text[], ARRAY['duyên']::text[], ARRAY['duyên phận']::text[], 'Sợi dây (糸) kéo con nhím (彑) và con lợn (豕) thành mối lương duyên'),
  ('495f9fce-207a-549c-9972-e45ac1cd0ba1'::uuid, '汚', ARRAY['オ']::text[], ARRAY['ô']::text[], ARRAY['ô nhiễm']::text[], 'Nước (氵) 5 màu rất bẩn'),
  ('fa4b245b-aede-5367-a992-307f55d28fbc'::uuid, '押', ARRAY['オウ']::text[], ARRAY['áp']::text[], ARRAY['ấn, ép']::text[], 'Dùng tay (扌) đảo ngược tự do (甲) là áp bức, nắm bắt'),
  ('18653d22-2826-59ca-850a-e02d584a372c'::uuid, '奥', ARRAY['オウ']::text[], ARRAY['áo']::text[], ARRAY['bên trong']::text[], 'BÊN TRONG (奥) CHIẾC LỒNG BÀN là một bát CƠM (米) rất TO (大) của bà vợ nấu'),
  ('edc716cd-2d57-57c7-b24c-c9d81744893f'::uuid, '憶', ARRAY['オク']::text[], ARRAY['ức']::text[], ARRAY['kí ức']::text[], 'Ý (意) chí đem cất vào trong tim (忄) làm kí ức'),
  ('db43a229-1ea2-59e9-8afa-1c4797a7e47c'::uuid, '菓', ARRAY['カ']::text[], ARRAY['quả']::text[], ARRAY['bánh kẹo']::text[], 'THẢO (艹) QUẢ (果) là HOA QUẢ để ăn chứ còn gì nữa'),
  ('da6f1e52-5fbe-5270-843d-e5fb480c5126'::uuid, '暇', ARRAY['カ']::text[], ARRAY['hạ']::text[], ARRAY['nhàn hạ']::text[], '1 ngày (日) đi lại nhàn hạ trên cầu thang'),
  ('8d780ff2-07f8-52c0-84fd-cfcf1e475522'::uuid, '箇', ARRAY['カ']::text[], ARRAY['cá']::text[], ARRAY['số đếm']::text[], 'Đếm các con Cá ngoan Cố (固) tình chui vào ống Trúc (竹)'),
  ('0afaadb3-18d5-5ecd-97ff-447de9123964'::uuid, '雅', ARRAY['ガ']::text[], ARRAY['nhã']::text[], ARRAY['nhã nhặn']::text[], 'Người nhã nhặn sẽ không dùng răng (牙) cắn vào con chim (隹)'),
  ('c9d7daa3-206a-5455-8ea5-7fc80f72d344'::uuid, '介', ARRAY['カイ']::text[], ARRAY['giới']::text[], ARRAY['giới thiệu']::text[], 'Hai người đứng dưới mái nhà tự giới thiệu'),
  ('17dec62b-c4de-569e-9c64-ebb076e11cc2'::uuid, '戒', ARRAY['カイ']::text[], ARRAY['giới']::text[], ARRAY['giới luật']::text[], 'Chắp tay (廾) để được qua (戈) biên giới'),
  ('c68f744d-f5b0-5970-8e62-37cd6ec98d33'::uuid, '械', ARRAY['カイ']::text[], ARRAY['giới']::text[], ARRAY['cơ giới']::text[], 'Cây (木) được giới thiệu (戒) thành máy móc cơ giới sao'),
  ('c2c70d39-f8e6-51b8-ac1d-0cb113299e72'::uuid, '皆', ARRAY['カイ']::text[], ARRAY['giai']::text[], ARRAY['mọi người']::text[], 'Đã có giai đoạn tỷ (比) tỷ so sánh với mọi người xem ai trắng hơn'),
  ('cb034887-a9dd-5955-8f43-122beb437487'::uuid, '壊', ARRAY['カイ']::text[], ARRAY['hoại']::text[], ARRAY['hủy hoại']::text[], 'Chôn 10 (十) bộ y phục (衣) vứt xuống đất (土) là hủy hoại'),
  ('73f23fe3-0c8a-5713-b70f-777a15bbc880'::uuid, '較', ARRAY['カク']::text[], ARRAY['giáo']::text[], ARRAY['so sánh']::text[], 'Xe (車) mà giao (交) nhau là giáo (so sánh)'),
  ('8ce045cd-f29b-5f2e-ba2a-b5847391ab4c'::uuid, '獲', ARRAY['カク']::text[], ARRAY['hoạch']::text[], ARRAY['săn bắt']::text[], 'Lại (又) dùng chó (犭) đi săn chim (隹) dưới bụi cỏ (艹)'),
  ('e454defa-cebe-5aae-b9a0-239078badb50'::uuid, '穫', ARRAY['カク']::text[], ARRAY['hoạch']::text[], ARRAY['thu hoạch']::text[], 'Nếu có lúa (禾) vào là thu hoạch'),
  ('026d106f-b177-5370-ab5e-03d6e85759b3'::uuid, '刈', ARRAY['ガイ']::text[], ARRAY['ngải']::text[], ARRAY['sự cắt']::text[], 'Cầm dao (刂) cắt chéo bùa ngải'),
  ('ff8e8939-b477-5347-a797-aea85a69e88c'::uuid, '甘', ARRAY['カン']::text[], ARRAY['cam']::text[], ARRAY['ngọt']::text[], 'Vật ngon ngọt ngậm trong miệng (口)'),
  ('96db96f8-f24c-5b8b-b813-1b92ad5325f2'::uuid, '汗', ARRAY['カン']::text[], ARRAY['hãn']::text[], ARRAY['mồ hôi']::text[], 'Lúc khô nóng (干) mồ hôi chảy như nước (氵)'),
  ('274645ab-451e-5009-b494-cf40151e0427'::uuid, '乾', ARRAY['カン']::text[], ARRAY['can']::text[], ARRAY['cạn']::text[], 'Buổi sáng mặt trời chiếu người cũng phải quỳ ngang vì khô cạn'),
  ('72019188-a1b3-5769-a267-8bf874356c1d'::uuid, '勧', ARRAY['カン']::text[], ARRAY['khuyến']::text[], ARRAY['khuyến khích']::text[], 'Con chim có lực (力) sẽ khuyên bảo được con chim (隹) khác vào giờ ngọ (午)'),
  ('f902eea8-33c7-5570-8609-5e61a0b288e4'::uuid, '歓', ARRAY['カン']::text[], ARRAY['hoan']::text[], ARRAY['hoan hỷ']::text[], 'Giờ ngọ (午) con chim (隹) thiếu (欠) hoan hỉ'),
  ('c0bf12c7-3c28-59ec-8c5d-5a1b255bd393'::uuid, '環', ARRAY['カン']::text[], ARRAY['hoàn']::text[], ARRAY['tuần hoàn']::text[], 'Nhà vua (王) dạy không (不) sai. Mắt (目) mồm (口) luôn tuần hoàn (環) với nhau'),
  ('30e4c954-89fa-5438-9430-a7662137156a'::uuid, '鑑', ARRAY['カン']::text[], ARRAY['giám']::text[], ARRAY['giám định']::text[], 'Một (一) vị thần (臣) đang nằm giám (鑑) sát đĩa (皿) vàng (金)'),
  ('f28f7258-4abb-5cd5-ba10-14b6e7ced012'::uuid, '含', ARRAY['ガン']::text[], ARRAY['hàm']::text[], ARRAY['bao hàm']::text[], 'Ngay cả bây giờ (今) thì miệng (口) vẫn bao gồm cả Hàm'),
  ('176a275d-d657-57d2-8f83-375a56566d04'::uuid, '奇', ARRAY['キ']::text[], ARRAY['kỳ']::text[], ARRAY['diệu kỳ']::text[], 'Người lớn (大) mà có khả năng (可) thì kì diệu'),
  ('d92115f0-3c9e-5379-8df5-68469ebd81c7'::uuid, '祈', ARRAY['キ']::text[], ARRAY['kì']::text[], ARRAY['cầu nguyện']::text[], 'Dòng họ Thị (礻) cầm Cân (斤) ra cầu nguyện thật là kì'),
  ('3887699a-cc10-5f9a-a974-973bfa6a8363'::uuid, '鬼', ARRAY['キ']::text[], ARRAY['quỷ']::text[], ARRAY['ma quỷ']::text[], 'Người chạy (儿) riêng tư một mình (厶) ở ruộng (田) chắc chắn là con quỷ'),
  ('486a00ed-c796-5301-91a4-afdae30cd64d'::uuid, '塊', ARRAY['カイ']::text[], ARRAY['khối']::text[], ARRAY['khối đá']::text[], 'Bản chất ma quỷ (鬼) chỉ là khối đất (土) mà ra'),
  ('705c9a4a-83aa-5c7f-b565-20a9f5dd6124'::uuid, '魂', ARRAY['コン']::text[], ARRAY['hồn']::text[], ARRAY['linh hồn']::text[], 'Linh hồn con quỷ (鬼) bay dưới đám mây (云)'),
  ('1e7c8740-8ada-5fe8-ab6c-d9d2d0f2dfbe'::uuid, '魅', ARRAY['ミ']::text[], ARRAY['mị']::text[], ARRAY['bùa mê']::text[], 'Con quỷ (鬼) cho mình ăn cái vị (未) bùa mê'),
  ('89b8a115-780f-551f-9eaa-14202fa20901'::uuid, '麻', ARRAY['マ']::text[], ARRAY['ma']::text[], ARRAY['cây lanh, cây gai']::text[], 'Dưới hiên nhà (广) có 2 cây ma lanh (林)'),
  ('cc72f2dc-53be-56e0-8c5e-4846e68ea66d'::uuid, '魔', ARRAY['マ']::text[], ARRAY['ma']::text[], ARRAY['ma quỷ']::text[], 'Cây ma (麻) có quỷ (鬼) đương nhiên là ma quỷ'),
  ('8032f142-82ce-5e48-a228-a5599a9189bd'::uuid, '摩', ARRAY['マ']::text[], ARRAY['ma']::text[], ARRAY['ma sát']::text[], 'Ma (麻) có tay (手) là ma sát, xoa bóp'),
  ('111aeb7d-8e44-5c7b-a9f2-200a8173aff7'::uuid, '磨', ARRAY['マ']::text[], ARRAY['ma']::text[], ARRAY['mài']::text[], 'Ma (麻) có đá (石) là ma mài, đánh bóng, mài dũa'),
  ('3119837b-5627-534f-98da-07bd64a38a7a'::uuid, '幾', ARRAY['キ']::text[], ARRAY['cơ']::text[], ARRAY['bao nhiêu']::text[], 'Một người (人) trải qua (戈) 2 lần yêu (幺) mà thì có bao nhiêu kí ức'),
  ('a36120eb-727e-552c-a2a0-b2fc57897d9a'::uuid, '輝', ARRAY['キ']::text[], ARRAY['huy']::text[], ARRAY['huy hoàng']::text[], 'Ánh sáng (光) trong quân đội (軍) là dựa vào huy hiệu người đó'),
  ('479c98c7-5d43-5c8a-9cc2-a48cc1044ae2'::uuid, '儀', ARRAY['ギ']::text[], ARRAY['nghi']::text[], ARRAY['nghi lễ']::text[], 'Người (イ) chính nghĩa (義) thì rất lễ nghi'),
  ('7f13f6c3-dd62-5495-a58a-9d4a68edd4c9'::uuid, '虐', ARRAY['ギャク']::text[], ARRAY['ngược']::text[], ARRAY['ngược đãi']::text[], 'Ngược đãi hổ (卜) là điều không nên'),
  ('a7475d35-d6f8-59ee-8d1e-9bcfe6e027cd'::uuid, '慮', ARRAY['リョ']::text[], ARRAY['lự']::text[], ARRAY['lưỡng lự']::text[], 'Thoáng thấy vằn con hổ (虍) lướt qua nên rất lưỡng lự, tâm tư (思) không biết có phải là có hổ không'),
  ('2036dff9-a80d-5010-9fc0-0e16cdfd3fa0'::uuid, '膚', ARRAY['フ']::text[], ARRAY['phu']::text[], ARRAY['da']::text[], 'Hổ (虍) thì ruột (胃) để ngoài da'),
  ('ef335181-0a00-52ba-9362-d53bae1f0783'::uuid, '虎', ARRAY['コ']::text[], ARRAY['hổ']::text[], ARRAY['con hổ']::text[], 'Hổ (虍) có chân (儿) thì là con hổ'),
  ('159f31ba-59b0-5b62-8e50-c95ea8669b33'::uuid, '虚', ARRAY['キョ']::text[], ARRAY['hư']::text[], ARRAY['hư không']::text[], 'Con hổ (虍) xếp hàng (並) trong hư vô'),
  ('cd9ffa2a-66a5-507a-b557-0f5f79b01791'::uuid, '戯', ARRAY['ギ']::text[], ARRAY['hí']::text[], ARRAY['trò đùa']::text[], 'Lấy cái cây qua chém vào hư vô (虚) rồi cười hí hí là đồ nghịch ngợm'),
  ('25cb7a5e-53cc-5daa-a070-3fb7a35d42f7'::uuid, '詰', ARRAY['キツ']::text[], ARRAY['cật']::text[], ARRAY['chôn lấp']::text[], 'Chôn cất những lời nói (言) tốt lành là "cật"'),
  ('d59ecacc-9386-514f-91c2-adeb3893d7db'::uuid, '却', ARRAY['キャク']::text[], ARRAY['khước']::text[], ARRAY['khước từ']::text[], 'Dùng đao (刂) chặt bỏ khước từ quá khứ (去)'),
  ('aa5c1ecc-74b6-503f-a62e-35799c4c4a1b'::uuid, '脚', ARRAY['キャク']::text[], ARRAY['cước']::text[], ARRAY['chân']::text[], 'Khước (却) từ là ăn ngay một cước của chị nguyệt (月)'),
  ('3a6e50a5-7991-56c2-9449-c6a6d22c3ae9'::uuid, '及', ARRAY['キュウ']::text[], ARRAY['cập']::text[], ARRAY['phổ cập']::text[], 'Phổ cập cấp 3 cho mọi người (人)'),
  ('e5b0b68b-1e08-5190-8c1b-1c70c7296b1e'::uuid, '丘', ARRAY['キュウ']::text[], ARRAY['khâu']::text[], ARRAY['ngọn đồi']::text[], 'Cầm một (一) cây rìu (斤) xuống đất tạo thành quả đồi'),
  ('a0e9b086-7307-51e0-b92b-97a0041a4ad9'::uuid, '朽', ARRAY['キュウ']::text[], ARRAY['hủ']::text[], ARRAY['mục nát']::text[], '5 cái cây (木) mục nát'),
  ('94fbd435-7da7-5d2a-b794-1dcb990e4854'::uuid, '巨', ARRAY['キョ']::text[], ARRAY['cự']::text[], ARRAY['to lớn']::text[], 'Hai (二) cái tủ đựng (匚) to lớn'),
  ('1e2ccbee-22c9-5875-b866-a05a5fdfa46f'::uuid, '距', ARRAY['キョ']::text[], ARRAY['cự']::text[], ARRAY['cự li']::text[], 'Đo cự ly (巨) bằng chân (足)'),
  ('82214992-4e2d-563c-a439-f988c13d50cc'::uuid, '拒', ARRAY['キョ']::text[], ARRAY['cự']::text[], ARRAY['kháng cự']::text[], 'Dùng tay (扌) kháng cự (巨)'),
  ('93aff95b-bf8f-5d5f-a4c3-07d8ab51ac83'::uuid, '拠', ARRAY['キョ']::text[], ARRAY['cứ']::text[], ARRAY['chứng cứ']::text[], 'Muốn xử lí (処) trong tay (扌) phải có chứng cứ (拠)'),
  ('18e7d05c-03ea-5af4-a2fc-31f55506256a'::uuid, '御', ARRAY['ゴ']::text[], ARRAY['ngự']::text[], ARRAY['kính thưa, cai trị']::text[], 'Tà xích (彳) hữu đao (刂) cưỡi bò (牛) ngự trị đường chính (正)'),
  ('6dbb6d42-d0a6-5419-89c1-f5ca9239b660'::uuid, '凶', ARRAY['キョウ']::text[], ARRAY['hung']::text[], ARRAY['hung ác']::text[], 'Kẻ hung ác làm đảo lộn khu (区) đất này'),
  ('d9f1a311-171c-56d4-9645-4b11555c810b'::uuid, '叫', ARRAY['キョウ']::text[], ARRAY['khiếu']::text[], ARRAY['kêu, hét']::text[], '4 cái miệng (口) la hét'),
  ('bde67dde-c8ad-5a9f-8d03-de45ac6573f9'::uuid, '狂', ARRAY['キョウ']::text[], ARRAY['cuồng']::text[], ARRAY['cuồng nhiệt']::text[], 'Con chó (犭) cuồng ông vua (王)'),
  ('74608686-aa47-5c76-93c1-e22e70f956d4'::uuid, '況', ARRAY['キョウ']::text[], ARRAY['huống']::text[], ARRAY['tình huống']::text[], 'Tình huống anh (兄) tôi khóc nhè chảy nước mắt (氵)')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Kanji — Trang 5-8 (kanji 81-160)
-- ─────────────────────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('da09bfd0-00c5-534f-b637-7e7a13810af8'::uuid, '狭', ARRAY['キョウ']::text[], ARRAY['hiệp']::text[], ARRAY['hẹp']::text[], 'Con chó (犭) chui qua 2 (二) ngọn lửa (火) hẹp'),
  ('e2df3c11-3ebb-549b-868d-04bbdc1e7f92'::uuid, '恐', ARRAY['キョウ']::text[], ARRAY['khủng']::text[], ARRAY['khủng hoảng']::text[], 'Công (工) kích vào tâm (心) người phàm (凡) cho khủng hoảng tinh thần'),
  ('ec1a74cf-041a-59f1-ba56-316f936ed4c8'::uuid, '響', ARRAY['キョウ']::text[], ARRAY['hưởng']::text[], ARRAY['ảnh hưởng']::text[], 'Âm thanh (音) của quê hương (郷) vang vọng khắp nơi'),
  ('6df7f1c9-e377-59ff-97c5-3b381d1f9f87'::uuid, '驚', ARRAY['キョウ']::text[], ARRAY['kinh']::text[], ARRAY['kinh ngạc']::text[], 'Con ngựa (馬) được tôn kính (敬) thì rất là kinh ngạc'),
  ('3c62a534-801f-56e7-9595-65f48986d2e3'::uuid, '仰', ARRAY['ギョウ']::text[], ARRAY['ngưỡng']::text[], ARRAY['tín ngưỡng']::text[], 'Một người (イ) ngước lên nhìn đĩa CD (卬)'),
  ('a87dd901-d0b9-5b7d-af46-ebc7c4ae40ef'::uuid, '駆', ARRAY['ク']::text[], ARRAY['khu']::text[], ARRAY['tiến đến']::text[], 'Con ngựa (馬) chạy đến chiến khu (区)'),
  ('d8aed20b-9697-5d9a-8b88-2c3d21376187'::uuid, '屈', ARRAY['クツ']::text[], ARRAY['khuất']::text[], ARRAY['bất khuất']::text[], 'Thấy thi ma (尸) mà vẫn xông lên (出) quả thật là bất khuất'),
  ('8d9c5ffe-e457-5c01-a2be-f7de698d1692'::uuid, '掘', ARRAY['クツ']::text[], ARRAY['quật']::text[], ARRAY['đào lên']::text[], 'Dũng cảm bất khuất (屈) dùng tay (扌) đào quật'),
  ('b981bcbd-262e-5c81-adf2-6aba7946f150'::uuid, '繰', ARRAY['ソウ']::text[], ARRAY['sào']::text[], ARRAY['quay tơ']::text[], 'Lấy dây (糸) cột sản phẩm (品) vào cây (木) sào'),
  ('10eb0dd0-a95e-533e-afc0-a6a0a4d90aa7'::uuid, '操', ARRAY['ソウ']::text[], ARRAY['thao']::text[], ARRAY['thao tác']::text[], 'Tay (扌) thao tác đưa sản phẩm (品) lên cây (木)'),
  ('55f4b007-b310-507e-877b-a24b8016280e'::uuid, '燥', ARRAY['ソウ']::text[], ARRAY['táo']::text[], ARRAY['khô ráo']::text[], 'Sản phẩm (品) làm xong từ cây (木) thì dùng lửa (火) để sấy khô'),
  ('6a0ff44e-ce05-51e2-b68f-1194ee01bc01'::uuid, '恵', ARRAY['ケイ']::text[], ARRAY['huệ']::text[], ARRAY['ân huệ']::text[], 'Người có tâm (心) được ban cho ân huệ 10 (十) cái ruộng (田)'),
  ('89253165-c193-5d25-a61b-6818e4017b83'::uuid, '傾', ARRAY['ケイ']::text[], ARRAY['khuynh']::text[], ARRAY['khuynh hướng']::text[], 'Người (イ) đứng cầm thìa (匕) gõ vào tờ giấy (頁) thì có khuynh hướng bị nghiêng'),
  ('0634d8f2-6536-5e14-b2d1-a47c4395c24d'::uuid, '継', ARRAY['ケイ']::text[], ARRAY['kế']::text[], ARRAY['kế tục']::text[], 'Kế bên chỉ (糸) là lúa (米)'),
  ('74ef4696-6fb8-5aeb-ad06-850fd7f40d2d'::uuid, '迎', ARRAY['ゲイ']::text[], ARRAY['nghênh']::text[], ARRAY['nghênh đón']::text[], 'Nghênh đón chính phủ CP (卬) đi trên đường (辶)'),
  ('158ea3ee-ac8b-5748-8764-d2a1062e566b'::uuid, '撃', ARRAY['ゲキ']::text[], ARRAY['kích']::text[], ARRAY['công kích']::text[], 'Tay (手) cầm thù (殳) công kích (撃) xe (車) dịch'),
  ('cda86be3-1035-5d15-a51d-188aef3af0a5'::uuid, '肩', ARRAY['ケン']::text[], ARRAY['kiên']::text[], ARRAY['bờ vai']::text[], 'Chị nguyệt (月) kiên cường dùng vai nâng đỡ cánh cửa (戸)'),
  ('ee422d3c-3160-5b16-a4fb-7e5f0212b408'::uuid, '兼', ARRAY['ケン']::text[], ARRAY['kiêm']::text[], ARRAY['kiêm nhiệm']::text[], 'Người 2 chân phải kiêm nhiệm mang cỏ (艹), yo (ヨ), ô tô (オ)'),
  ('89526a9f-ac66-5091-9f3c-9c2571bfa8ba'::uuid, '嫌', ARRAY['ケン']::text[], ARRAY['hiềm']::text[], ARRAY['hiềm khích']::text[], 'Phụ nữ (女) kiêm (兼) nhiệm nhiều việc thì hay hiềm khích nhau'),
  ('f3ef46ff-6874-5726-8d91-190a9f5abd14'::uuid, '廉', ARRAY['レン']::text[], ARRAY['liêm']::text[], ARRAY['liêm khiết']::text[], 'Người kiêm (兼) nhiệm nhiều việc sống trong mái nhà (广) liêm khiết'),
  ('1a60db87-20bd-5a74-b8f9-b460a27d859f'::uuid, '謙', ARRAY['ケン']::text[], ARRAY['khiêm']::text[], ARRAY['khiêm tốn']::text[], 'Người kiêm (兼) nhiệm nhiều việc nói (言) rất khiêm tốn'),
  ('a104ee32-61a9-5bd9-87b8-c353e6e2eb5d'::uuid, '剣', ARRAY['ケン']::text[], ARRAY['kiếm']::text[], ARRAY['gươm']::text[], '10 người đang đội mũ cầm kiếm'),
  ('fe7e0b99-3a85-5f7b-a776-68d1da960282'::uuid, '軒', ARRAY['ケン']::text[], ARRAY['hiên']::text[], ARRAY['mái nhà, đơn vị đếm nhà']::text[], 'Xe (車) để dưới mái hiên khô (干) ráo'),
  ('445bd245-3819-5b1d-af26-a90412e43bc3'::uuid, '圏', ARRAY['ケン']::text[], ARRAY['quyền']::text[], ARRAY['khí quyển']::text[], 'Quyền (巻) mà có vị (口) vây xung quanh là khí quyển'),
  ('dc78e00b-45d6-5a32-a413-e1151b145314'::uuid, '堅', ARRAY['ケン']::text[], ARRAY['kiên']::text[], ARRAY['kiên cố']::text[], 'Hựu (又) thần (臣) cai quản vùng đất (土) này rất kiên cố'),
  ('92101492-a01b-52c0-9396-e1a09c80efc0'::uuid, '遣', ARRAY['ケン']::text[], ARRAY['khiển']::text[], ARRAY['phái khiển, cử đi']::text[], 'Cử một ông quan (官) đi (辶) sang Trung Quốc (中)'),
  ('3cb502b4-56d4-570f-83b1-e3e290cbd006'::uuid, '玄', ARRAY['ゲン']::text[], ARRAY['huyền']::text[], ARRAY['màu đen']::text[], 'Cái đầu (亠) của yêu (幺) tinh thì rất là huyền bí'),
  ('c5bd941a-cb73-559f-93e1-f2806539a77b'::uuid, '枯', ARRAY['コ']::text[], ARRAY['khô']::text[], ARRAY['khô héo']::text[], 'Cây (木) cổ (古) khô héo'),
  ('e5ba5d93-11a5-5e6e-9c2c-dfbca21b66ec'::uuid, '誇', ARRAY['コ']::text[], ARRAY['khoa']::text[], ARRAY['khoa trương']::text[], 'Nói (言) to (大) gấp 5 lần thật là khoa trương'),
  ('9dcaadd4-5a5e-5489-83e9-818fa1ecacf3'::uuid, '鼓', ARRAY['コ']::text[], ARRAY['cổ']::text[], ARRAY['cái trống']::text[], 'Chi (支) 10 (十) hạt đậu (豆) để mua cái trống (鼓) cổ'),
  ('7564c720-a9b5-537d-aded-b7df0d170be2'::uuid, '互', ARRAY['ゴ']::text[], ARRAY['hỗ']::text[], ARRAY['hỗ trợ']::text[], '2 chữ 二 hỗ trợ trên dưới'),
  ('657925b1-7a24-5cce-b76f-504dc7afd3e4'::uuid, '抗', ARRAY['コウ']::text[], ARRAY['kháng']::text[], ARRAY['đề kháng']::text[], 'Lấy tay (扌) vác ghế (几) đập vào đầu để (亠) phản kháng'),
  ('221c76f4-891d-5017-8e28-f2e758183f75'::uuid, '攻', ARRAY['コウ']::text[], ARRAY['công']::text[], ARRAY['công kích']::text[], 'Công (工) mà bị đánh (攵) thì là công kích'),
  ('2d9db85d-072e-5b60-b337-69fec3846944'::uuid, '更', ARRAY['コウ']::text[], ARRAY['canh']::text[], ARRAY['canh tân']::text[], 'Canh tân đất một (一) ruộng (田) đất trồng nghệ (乂)'),
  ('1e0fa133-9e01-559e-be74-66dc54821e64'::uuid, '恒', ARRAY['コウ']::text[], ARRAY['hằng']::text[], ARRAY['vĩnh hằng']::text[], 'Trái tim (忄) bị nhốt 1001 đêm vĩnh hằng'),
  ('52560c60-b40d-5dd4-899a-7da037e2ac22'::uuid, '荒', ARRAY['コウ']::text[], ARRAY['hoang']::text[], ARRAY['hoang dã']::text[], 'Cảnh hoang tàn bên dòng sông (川) cỏ (艹) cây chết (亡) cả'),
  ('8784007b-2f90-542e-a5e3-8e10c3cbd10c'::uuid, '慌', ARRAY['コウ']::text[], ARRAY['hoảng']::text[], ARRAY['vội vàng']::text[], 'Tâm (忄) hoang (荒) dã thì hoảng hốt'),
  ('414a81b0-4232-5bfc-bcfe-4dbb58d08e21'::uuid, '香', ARRAY['コウ']::text[], ARRAY['hương']::text[], ARRAY['hương thơm']::text[], 'Lúa (禾) phơi một ngày (日) tỏa hương thơm'),
  ('86b5dbe1-1a15-5478-a3b1-4e6533164677'::uuid, '項', ARRAY['コウ']::text[], ARRAY['hạng']::text[], ARRAY['hạng']::text[], 'Hạng mục này được thi công (工) bằng giấy (頁)'),
  ('5d31e01a-7cd0-53be-ad02-5cb54684cfbd'::uuid, '稿', ARRAY['コウ']::text[], ARRAY['cảo']::text[], ARRAY['bản thảo']::text[], 'Cắt cây lúa (禾) cao (高) về làm bản thảo'),
  ('dcc3b481-fd14-5aaf-b01f-5bb9f8f69dfb'::uuid, '豪', ARRAY['ゴウ']::text[], ARRAY['hào']::text[], ARRAY['hào nhoáng']::text[], 'Con lợn (豕) đội cái mũ cao cao (高) trông hào hoa'),
  ('81942fb9-958b-562e-81ed-736c6e13a6ad'::uuid, '込', ARRAY[]::text[], ARRAY['nhập']::text[], ARRAY['nhồi, nhét']::text[], 'Nhập (入) vào đường (辶) đông'),
  ('44353868-dcca-59e2-93b0-12e3d8a41510'::uuid, '婚', ARRAY['コン']::text[], ARRAY['hôn']::text[], ARRAY['kết hôn']::text[], 'Phụ nữ (女) kết hôn (昏) phải đổi họ trong ngày'),
  ('e74920d3-cad5-596e-8f89-d045c1d6b989'::uuid, '鎖', ARRAY['サ']::text[], ARRAY['tỏa']::text[], ARRAY['cái xích, phong tỏa']::text[], 'Lấy tiền (金) tiêu (肖) tỏa đi khắp nơi'),
  ('7619f5fd-6743-5238-9c8f-0ac8972bdc4c'::uuid, '彩', ARRAY['サイ']::text[], ARRAY['thái']::text[], ARRAY['sắc thái']::text[], 'Thái (采) mà có tóc (彡) dài là sắc thái'),
  ('61bf24e5-3425-56d3-b9a5-2259d82880ee'::uuid, '菜', ARRAY['サイ']::text[], ARRAY['thái']::text[], ARRAY['rau']::text[], 'Thái (采) mà lấy móng tay gắt được cái ngọn cây (艹) là rau'),
  ('f11535a1-9bf7-502b-9fac-73db6f32801c'::uuid, '採', ARRAY['サイ']::text[], ARRAY['thái']::text[], ARRAY['hái, chọn nhặt']::text[], 'Thái (采) ngắt hái bằng tay (扌)'),
  ('61c8d6f3-4872-5139-aeb0-2f459271da87'::uuid, '歳', ARRAY['サイ']::text[], ARRAY['tuế']::text[], ARRAY['tuổi']::text[], 'Dừng (止) lại hỏi nhỏ, qua tuổi Tuất (戌) là tuổi con gì?'),
  ('e602530d-3474-5170-8019-237cdd1ce4cf'::uuid, '載', ARRAY['サイ']::text[], ARRAY['tải']::text[], ARRAY['vận tải']::text[], 'Tải 10 (十) cây vũ khí (戈) bằng xe (車)'),
  ('19da9a6c-c457-52c5-9d63-6f65b07fd43e'::uuid, '剤', ARRAY['ザイ']::text[], ARRAY['tễ']::text[], ARRAY['dịch tễ']::text[], 'Tễ (斉) cầm đao (刂) dọa tễ'),
  ('fc6a1944-9eb1-5c11-9858-440720cb005f'::uuid, '咲', ARRAY['ショウ']::text[], ARRAY['tiếu']::text[], ARRAY['nở hoa']::text[], 'Tiếu như miệng (口) ông quan (关)'),
  ('2416c15a-5b5e-52a4-9f3e-c43ed1e0f36b'::uuid, '惨', ARRAY['サン']::text[], ARRAY['thảm']::text[], ARRAY['bi thảm']::text[], 'Tâm (忄) tham (参) sẽ gặp bi thảm'),
  ('d3bb294a-ea39-5196-962c-19776dbb1f17'::uuid, '旨', ARRAY['シ']::text[], ARRAY['chỉ']::text[], ARRAY['ý chỉ, chỉ dụ']::text[], 'Cái thìa (匕) này chỉ (旨) ngày (日) dùng trong ngày'),
  ('107c3161-4e11-5ba1-b475-40dbf05686f4'::uuid, '伺', ARRAY['シ']::text[], ARRAY['tứ']::text[], ARRAY['thăm hỏi']::text[], 'Thăm hỏi người (イ) làm quản lý (司)'),
  ('868d0030-82f7-57a2-a906-c39961f583af'::uuid, '刺', ARRAY['シ']::text[], ARRAY['thích']::text[], ARRAY['đâm thủng']::text[], 'Thích thì lấy đao (刂) vót cây (束) đâm thủng'),
  ('3e81b390-d935-5a66-a8bd-7e8f8fec6194'::uuid, '脂', ARRAY['シ']::text[], ARRAY['chi']::text[], ARRAY['mỡ']::text[], 'Chị nguyệt (月) chỉ (旨) ăn suốt ngày, hèn chi người toàn mỡ'),
  ('026c7de6-6506-55a9-92e8-e42c615d8467'::uuid, '紫', ARRAY['シ']::text[], ARRAY['tử']::text[], ARRAY['màu tím']::text[], 'Dừng lại (止) dùng thìa (匕) luyện hóa sợi chỉ (糸) thành màu tím'),
  ('8ef8233f-8870-534d-b1e3-85d43d154456'::uuid, '雌', ARRAY['シ']::text[], ARRAY['thư']::text[], ARRAY['con mái']::text[], 'Tiểu thư dừng lại (止) dùng thìa (匕) nghịch chim (隹)'),
  ('c67a5bf5-5a21-5ab6-aabc-0d0eb23df6b4'::uuid, '雄', ARRAY['ユウ']::text[], ARRAY['hùng']::text[], ARRAY['giống đực']::text[], 'Con chim (隹) nam (ナム) là con chim đực'),
  ('810eab22-70b4-5211-84e1-dd533f12de26'::uuid, '執', ARRAY['シツ']::text[], ARRAY['chấp']::text[], ARRAY['chấp hành']::text[], 'Muốn hạnh (幸) phúc hoàn (丸) toàn phải chấp hành'),
  ('181320f0-e14b-5bfc-8709-e340a232912c'::uuid, '芝', ARRAY['シ']::text[], ARRAY['chi']::text[], ARRAY['cỏ']::text[], 'Bãi cỏ (艹) hình chữ 乙'),
  ('5cec3464-9c8e-5dd0-997f-eb77d555b05d'::uuid, '斜', ARRAY['シャ']::text[], ARRAY['tà']::text[], ARRAY['mặt nghiêng']::text[], 'Đong (斗) dư (余) nghiêng về 1 bên'),
  ('9a1becf1-f6d7-53ed-851c-08fef165852b'::uuid, '煮', ARRAY['シャ']::text[], ARRAY['chử']::text[], ARRAY['nấu']::text[], 'Học giả (者) nhóm lửa (灬) để nấu'),
  ('37ff1732-6686-52f8-945b-f71d3807369e'::uuid, '釈', ARRAY['シャク']::text[], ARRAY['thích']::text[], ARRAY['giải thích']::text[], 'Không cần phải giải thích hay biện (釆) luận gì cả, hãy xích (尺) hắn lại!'),
  ('d28a451d-2847-5708-9e68-be0e9aaeff71'::uuid, '寂', ARRAY['ジャク']::text[], ARRAY['tịch']::text[], ARRAY['lặng yên']::text[], 'Bác thúc (叔) bị tịch thu mất hết nhà (宀) cửa'),
  ('eceb50c6-350f-5c55-a040-6386e81ed9cb'::uuid, '朱', ARRAY['シュ']::text[], ARRAY['chu']::text[], ARRAY['sắc đỏ']::text[], 'Trẻ vị (未) thành niên hay chu môi đỏ tự sướng'),
  ('14b09729-a28d-5d61-b16c-3a1015b06bd1'::uuid, '狩', ARRAY['シュ']::text[], ARRAY['thú']::text[], ARRAY['săn bắt']::text[], 'Cung thủ (守) dắt chó (犭) đi sở săn thú'),
  ('6796286a-8d5f-5249-8385-dbcd921450df'::uuid, '趣', ARRAY['シュ']::text[], ARRAY['thú']::text[], ARRAY['hứng thú']::text[], 'Lấy (取) việc chạy (走) là sở thích hứng thú'),
  ('8b4f3d8f-5f5d-5327-a543-ea5e94e3aeec'::uuid, '需', ARRAY['ジュ']::text[], ARRAY['nhu']::text[], ARRAY['nhu cầu']::text[], 'Trời mưa (雨) nhi (而) đồng có nhu cầu đi chung dù'),
  ('1898765e-19c1-5f13-8f2d-adf6489603bf'::uuid, '舟', ARRAY['シュウ']::text[], ARRAY['chu']::text[], ARRAY['cái thuyền']::text[], 'Mẹ (母) đi chu (舟) du bằng thuyền'),
  ('bce316d0-6256-55c1-b935-fee52fa91566'::uuid, '秀', ARRAY['シュウ']::text[], ARRAY['tú']::text[], ARRAY['ưu tú']::text[], 'Chọn ra 13 (乃) cây lúa (禾) ưu tú nhất'),
  ('b83326a0-c98f-5bfa-a912-f79863de13fe'::uuid, '襲', ARRAY['シュウ']::text[], ARRAY['tập']::text[], ARRAY['tập kích']::text[], 'Tập kích người mặc y (衣) phục long (龍) bào'),
  ('11a18fad-350c-54bc-b1d0-641f5c1ddb4b'::uuid, '柔', ARRAY['ジュウ']::text[], ARRAY['nhu']::text[], ARRAY['mềm dẻo']::text[], 'Cây mâu (矛) là cái cây (木) rất mềm dẻo'),
  ('e17b872a-7bb7-5bfd-97e8-5d7acc4673c4'::uuid, '獣', ARRAY['ジュウ']::text[], ARRAY['thú']::text[], ARRAY['thú vật']::text[], 'Dùng 10 con chó (犬) để săn thú ăn cỏ ở ngoài đồng (田)'),
  ('27fc2926-90c7-5e31-8821-bb1bc0d4f9eb'::uuid, '瞬', ARRAY['シュン']::text[], ARRAY['thuấn']::text[], ARRAY['thoáng qua']::text[], 'Thời gian trôi nhanh nháy mắt (目) 3 lần đã đến chiều tối (夕) cuối năm (年)'),
  ('006e6927-0b1d-5d58-9b7f-7a3fe92a1def'::uuid, '旬', ARRAY['シュン']::text[], ARRAY['tuần']::text[], ARRAY['10 ngày']::text[], 'Bao (勹) 1 tuần bằng 10 ngày (日)'),
  ('aa5766d6-043a-5fda-8044-0f83e6e3a646'::uuid, '巡', ARRAY['ジュン']::text[], ARRAY['tuần']::text[], ARRAY['tuần tra']::text[], 'Đi (辶) tuần tra trên sông (巛)'),
  ('59637ea6-86e4-5078-a846-962e10121a4a'::uuid, '盾', ARRAY['ジュン']::text[], ARRAY['thuẫn']::text[], ARRAY['mâu thuẫn']::text[], 'Dưới sườn núi (厂) có 10 (十) con mắt (目) mâu thuẫn nhau'),
  ('9a45790d-faf5-5607-b366-7d6eaa6d579d'::uuid, '召', ARRAY['ショウ']::text[], ARRAY['triệu']::text[], ARRAY['triệu gọi']::text[], 'Triệu tập không chỉ dùng mồm (口) mà dùng cả đao kiếm (刀)'),
  ('21c65d5b-ea6b-55f5-b04c-af5a9982dc93'::uuid, '沼', ARRAY['ショウ']::text[], ARRAY['chiểu']::text[], ARRAY['đầm lầy']::text[], 'Ao đầm có hàng triệu (召) giọt nước (氵)')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Kanji — Trang 9-12 (kanji 161-240)
-- ─────────────────────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('459ae15d-f80c-54b5-a510-c77d8173f259'::uuid, '紹', ARRAY['ショウ']::text[], ARRAY['thiệu']::text[], ARRAY['giới thiệu']::text[], 'Triệu (召) tập nhau lại, rồi mỗi người cầm một sợi dây (糸) giới thiệu về mình'),
  ('618a0bd6-f8d9-5db0-96f7-8c4d6564b9b8'::uuid, '床', ARRAY['ショウ']::text[], ARRAY['sàng']::text[], ARRAY['sàn nhà']::text[], 'Ở dưới hiên nhà (广) có cái sàng làm bằng cây (木)'),
  ('41fdaba3-8e74-52dd-8da3-9818e51d7ace'::uuid, '称', ARRAY['ショウ']::text[], ARRAY['xưng']::text[], ARRAY['danh xưng']::text[], 'Danh xưng tôi là tiểu (禾) hòa (禾)'),
  ('7d6e50dd-7846-5f35-8338-feaf7ee88789'::uuid, '詳', ARRAY['ショウ']::text[], ARRAY['tường']::text[], ARRAY['rõ ràng']::text[], 'Con cừu (羊) nói (言) rất rõ ràng'),
  ('249b34f9-d4d3-55c4-a69e-b034fda16650'::uuid, '丈', ARRAY['ジョウ']::text[], ARRAY['trượng']::text[], ARRAY['trượng phu']::text[], 'Trượng phu thì nhất (一) định là có tài nghệ (乂)'),
  ('2f817e70-2538-53b2-9d3a-33418f50c714'::uuid, '畳', ARRAY['ジョウ']::text[], ARRAY['điệp']::text[], ARRAY['cái chiếu']::text[], 'Điệp ra đồng (田) lấy khăn (冖) che mắt (目) lại nằm ngủ'),
  ('44d921d7-2b10-5527-9395-0ac14c2f1563'::uuid, '殖', ARRAY['ショク']::text[], ARRAY['thực']::text[], ARRAY['thực dân']::text[], 'Cái chết (歹) trực tiếp (直) là do thực dân gây ra'),
  ('5e8924ba-8a8d-5f04-97ea-069d817adbeb'::uuid, '飾', ARRAY['ショク']::text[], ARRAY['sức']::text[], ARRAY['trang sức']::text[], 'Người có của ăn của để (食) ở thành thị (市) thường thích làm đẹp, trang trí, đeo trang sức'),
  ('095924bc-bd78-5d03-8a89-beb4e1f28149'::uuid, '触', ARRAY['ショク']::text[], ARRAY['xúc']::text[], ARRAY['sờ vào, chạm vào']::text[], 'Chạm vào xúc giác (角) của côn trùng (虫)'),
  ('f91800fb-b7f1-5cbf-9e1e-b9a624f0568e'::uuid, '寝', ARRAY['シン']::text[], ARRAY['tẩm']::text[], ARRAY['ngủ']::text[], 'Thị Tấm vào trong nhà (宀) đi Yo (ヨ) giường (爿) trùm khăn (冖) lại rồi ngủ chung với hoàng'),
  ('5ba287a0-ae82-5e38-8f42-0f73ceaa639c'::uuid, '侵', ARRAY['シン']::text[], ARRAY['xâm']::text[], ARRAY['xâm lược']::text[], 'Người (イ) mà không ngủ (寝) trong nhà dễ bị xâm hại'),
  ('c310ca13-0c26-5d98-87d8-17c96d6c3bd5'::uuid, '浸', ARRAY['シン']::text[], ARRAY['tẩm']::text[], ARRAY['thẩm thấu']::text[], 'Xả nước (氵) vào bồn, thả tóc (ヨ), buông tay (冖), bắt chéo chân (又), ngâm mình trong nước'),
  ('9ee26c85-6e1c-5092-97ff-40b337588541'::uuid, '振', ARRAY['シン']::text[], ARRAY['chấn']::text[], ARRAY['chấn động']::text[], 'Thần (辰) ra tay (扌) làm chấn động mặt đất'),
  ('2a508c08-9dfe-5b3d-878a-a24ba3cfc32c'::uuid, '慎', ARRAY['シン']::text[], ARRAY['thận']::text[], ARRAY['thận trọng']::text[], 'Tâm (忄) chân (真) thật thì sống rất thận trọng'),
  ('678ac329-4221-5ebb-aa06-8ff0363abbae'::uuid, '震', ARRAY['シン']::text[], ARRAY['chấn']::text[], ARRAY['địa chấn']::text[], 'Đang nắng mà có mưa (雨) rơi xuống làm thần linh (辰) chấn động'),
  ('7bbaac20-be55-50e8-98d5-28b3596e9766'::uuid, '薪', ARRAY['シン']::text[], ARRAY['tân']::text[], ARRAY['củi']::text[], 'Cỏ (艹) mới (新) dùng làm củi'),
  ('2d0ccd36-b5ec-57ff-b041-df6f76c9336f'::uuid, '尽', ARRAY['ジン']::text[], ARRAY['tận']::text[], ARRAY['tận lực']::text[], 'Tận sức phá xích (尺) băng (冫)'),
  ('cfd938f1-b494-512a-a396-d360d09de21a'::uuid, '陣', ARRAY['ジン']::text[], ARRAY['trận']::text[], ARRAY['trận địa']::text[], 'Xe (車) chạy đến ấp (阝) trận địa rồi'),
  ('ea446d4f-67a3-50c0-9061-330f8b7f2c17'::uuid, '尋', ARRAY['ジン']::text[], ARRAY['tầm']::text[], ARRAY['tìm kiếm, dò hỏi']::text[], 'Công (工) kích lấy tay cạy miệng (口) con nhím (ヨ) ra cho thốn (寸) để hỏi'),
  ('4ab25da9-507b-5328-84e5-72da1b0bbec5'::uuid, '吹', ARRAY['スイ']::text[], ARRAY['xuy']::text[], ARRAY['thổi']::text[], 'Phồng mồm (口) lên thổi vì thiếu (欠) hơi'),
  ('2704dc04-3338-56be-b146-35ea67ec331d'::uuid, '是', ARRAY['ゼ']::text[], ARRAY['thị']::text[], ARRAY['thị phi']::text[], 'Hàng ngày (日) chạy (疋) tìm chuyện thị phi để làm chủ đề'),
  ('29dd101a-5720-55b6-bb6f-c8b2f92541be'::uuid, '井', ARRAY['セイ']::text[], ARRAY['tỉnh']::text[], ARRAY['cái giếng']::text[], 'Té giếng bất tỉnh'),
  ('e570c8f9-d07e-54d5-be6e-3c2c5c6037e2'::uuid, '姓', ARRAY['セイ']::text[], ARRAY['tính']::text[], ARRAY['họ (họ tên)']::text[], 'Con gái (女) sinh (生) ra đã được tính theo họ của cha'),
  ('5c584974-7ca6-5be1-89a4-e77f01ddd36f'::uuid, '征', ARRAY['セイ']::text[], ARRAY['chinh']::text[], ARRAY['chinh phục']::text[], 'Bước (彳) đi chính (正) xác để chinh phục'),
  ('b6a14e07-f72f-58e8-812a-3704edae85f2'::uuid, '跡', ARRAY['セキ']::text[], ARRAY['tích']::text[], ARRAY['dấu tích']::text[], 'Cái dấu tích màu đỏ (亦) ở chân (足)'),
  ('189b3895-f217-5bbb-a0e0-8b68e823fdd9'::uuid, '占', ARRAY['セン']::text[], ARRAY['chiếm']::text[], ARRAY['chiếm lấy']::text[], 'Đọc cọc (卜) vào miệng (口) chiếm lấy'),
  ('24935218-f0e2-5f00-91ab-54b28a2069b5'::uuid, '扇', ARRAY['セン']::text[], ARRAY['phiến']::text[], ARRAY['cái quạt']::text[], 'Cầm cái cánh (羽) ngồi quạt ở cửa (戸)'),
  ('0c7b074c-9f3d-5866-870c-bd30f33fbaac'::uuid, '鮮', ARRAY['セン']::text[], ARRAY['tiên']::text[], ARRAY['tươi sống']::text[], 'Thịt cá (魚) và dê (羊) rất tươi mới'),
  ('21ca5c3b-642e-5d35-94dc-ee06877906f6'::uuid, '訴', ARRAY['ソ']::text[], ARRAY['tố']::text[], ARRAY['tố cáo']::text[], 'Tố cáo kẻ dùng búa (斤) chặt cây bằng ngôn từ (言)'),
  ('9a3d1067-d3bf-560c-80c2-ff1701ee30fa'::uuid, '曽', ARRAY['ソウ']::text[], ARRAY['tằng']::text[], ARRAY['chất (trong cháu chắt)']::text[], 'Ngày (日) nào cũng làm ruộng (田) mà cỏ vẫn mọc lên tầng tầng (học để học các từ tiếp theo)'),
  ('5a8fa06b-af00-510a-9c7c-337965ee0482'::uuid, '僧', ARRAY['ソウ']::text[], ARRAY['tăng']::text[], ARRAY['tăng lữ']::text[], 'Tăng tăng nhân (イ) thành nhà sư'),
  ('46ee7b59-66df-5541-914f-276cf01fd361'::uuid, '増', ARRAY['ゾウ']::text[], ARRAY['tăng']::text[], ARRAY['tăng lên']::text[], 'Tăng mua thêm đất (土)'),
  ('7bc3e85c-84d4-54b6-ad28-725465be2671'::uuid, '贈', ARRAY['ゾウ']::text[], ARRAY['tặng']::text[], ARRAY['tặng quà']::text[], 'Tặng được tặng bảo bối (貝)'),
  ('22545c66-60cc-5ecd-8840-715f33bed45c'::uuid, '憎', ARRAY['ゾウ']::text[], ARRAY['tăng']::text[], ARRAY['ghét']::text[], 'Tăng ghét từ tâm (忄)'),
  ('06d3e8c4-f405-5a3c-ac37-b8b486468e18'::uuid, '層', ARRAY['ソウ']::text[], ARRAY['tầng']::text[], ARRAY['cao tầng']::text[], 'Con ma (尸) trên tầng nhà'),
  ('81ec9b84-fa3b-5290-a847-0a9ddb47dc5f'::uuid, '騒', ARRAY['ソウ']::text[], ARRAY['tao']::text[], ARRAY['ồn ào']::text[], 'Con ngựa (馬) lại (又) cãi nhau với con sâu (虫) rất tào lao ồn ào'),
  ('a222c4ad-ade8-57fb-937f-1d456e6e6b5a'::uuid, '即', ARRAY['ソク']::text[], ARRAY['tức']::text[], ARRAY['tức khắc']::text[], 'Tức khắc không lấn cấn (艮) tiểu tiết (卩)'),
  ('5a71384b-2ab3-5490-a0b4-0718cb270f82'::uuid, '俗', ARRAY['ゾク']::text[], ARRAY['tục']::text[], ARRAY['phong tục']::text[], 'Người (イ) sống trong thung lũng (谷) có phong tục tập quán'),
  ('67785fc1-7232-583d-b822-a7c2b1b3e7d2'::uuid, '耐', ARRAY['タイ']::text[], ARRAY['nại']::text[], ARRAY['nhẫn nại']::text[], 'Nhi (而) đồng bị thốn (寸) thì vẫn phải nhẫn nại'),
  ('ef3e8e11-770c-5038-b1eb-ec2c75032c42'::uuid, '替', ARRAY['タイ']::text[], ARRAY['thế']::text[], ARRAY['thay thế']::text[], 'Hai ông chồng (夫) thay thế nhau mỗi ngày (日)'),
  ('0ca56faf-4165-5dda-ab38-74e3f3dba6e1'::uuid, '沢', ARRAY['タク']::text[], ARRAY['trạch']::text[], ARRAY['đầm lầy']::text[], 'Con trạch bị xích (尺) trong đầm lầy đầy nước (氵)'),
  ('960f865c-fb63-5253-b5d1-0c40cfef89a3'::uuid, '拓', ARRAY['タク']::text[], ARRAY['thác']::text[], ARRAY['khai thác']::text[], 'Lấy tay (扌) khai thác đá (石)'),
  ('f00f9a93-55c9-5e52-a3cb-1e186a468862'::uuid, '濁', ARRAY['ダク']::text[], ARRAY['trọc']::text[], ARRAY['vẩn đục']::text[], 'Mắt (罒) nhìn nước (氵) bị bao (勹) bọc bởi côn trùng (虫) làm cho vẩn đục'),
  ('98562117-dc82-558a-b3ac-9ac073ce6d76'::uuid, '脱', ARRAY['ダツ']::text[], ARRAY['thoát']::text[], ARRAY['cởi bỏ']::text[], 'Anh trai (兄) bị cấm sừng nên bỏ chị nguyệt (月)'),
  ('ee850196-a3d1-555a-9b0a-9e45c545ac88'::uuid, '丹', ARRAY['タン']::text[], ARRAY['đan']::text[], ARRAY['viên thuốc']::text[], 'Viên thuốc nhìn như cái thuyền (舟) không mũi không người lái'),
  ('75b310ad-55f4-5536-8e23-8654e86fdd3f'::uuid, '淡', ARRAY['タン']::text[], ARRAY['đạm']::text[], ARRAY['thanh đạm']::text[], 'Nước (氵) xối vào lửa (炎) để làm thanh đạm đi'),
  ('83e138e8-adfb-5bf7-9e06-7730b67f500d'::uuid, '嘆', ARRAY['タン']::text[], ARRAY['thán']::text[], ARRAY['ca thán']::text[], 'Học hán tự (漢) khó quá nên cái miệng (口) hay ca thán'),
  ('60485976-9128-52a8-aefd-6f09fb87db0f'::uuid, '端', ARRAY['タン']::text[], ARRAY['đoan']::text[], ARRAY['cực đoan']::text[], 'Phong tục cực đoan để trẻ (而) tự lập (立) trên núi (山)'),
  ('ac95c1a6-6ced-5b53-be28-62ee94b1bbab'::uuid, '弾', ARRAY['ダン']::text[], ARRAY['đạn']::text[], ARRAY['viên đạn']::text[], 'Đơn giản (単) như bắn cung (弓) thành viên đạn'),
  ('494b26d5-ed45-53f6-9ad1-44cf75df1249'::uuid, '恥', ARRAY['チ']::text[], ARRAY['sỉ']::text[], ARRAY['xấu hổ']::text[], 'Biết lắng nghe (耳) và có tâm (心) thì sẽ xấu hổ'),
  ('1acf2bd2-cc90-53a4-81ef-9a01fc68e27b'::uuid, '致', ARRAY['チ']::text[], ARRAY['trí']::text[], ARRAY['nhất trí']::text[], 'Đánh (攵) cho thằng chí (至) nhất trí thì thôi'),
  ('722b5971-5c39-585f-b495-91c6f1293711'::uuid, '遅', ARRAY['チ']::text[], ARRAY['trì']::text[], ARRAY['muộn']::text[], 'Con dê (羊) bước đi (辶) chậm chạp như cái thây ma (尸) làm muộn giờ'),
  ('593449dc-2e26-5674-a5bf-2ca944d6fb21'::uuid, '蓄', ARRAY['チク']::text[], ARRAY['súc']::text[], ARRAY['tích lũy']::text[], 'Cây cỏ (艹) màu đen (玄) trên ruộng (田) đem về tích trữ'),
  ('857e6b9d-4215-5369-bbf2-2b1257287932'::uuid, '沖', ARRAY['チュウ']::text[], ARRAY['trung']::text[], ARRAY['rộng lớn, trống trải']::text[], 'Trung (中) và có nước (氵) là trùng trùng điệp điệp'),
  ('0d865f2e-e706-5e00-be2a-8674ca850af7'::uuid, '跳', ARRAY['チョウ']::text[], ARRAY['khiêu']::text[], ARRAY['khiêu vũ, nhảy lên']::text[], 'Triệu (兆) cái chân (足) đang nhảy lên cao trong buổi khiêu vũ'),
  ('0b0959b2-2550-5a37-9020-f0b98e9bfd98'::uuid, '徴', ARRAY['チョウ']::text[], ARRAY['trưng']::text[], ARRAY['đặc trưng']::text[], 'Đặc trưng của vua (王) là đội vương miện giống quả núi (山), hai bên quan võ cầm xích (彳), quan văn cầm phọc (夂)'),
  ('eb7a6645-e3f6-57ad-a119-6a096c9b9b19'::uuid, '澄', ARRAY['チョウ']::text[], ARRAY['trừng']::text[], ARRAY['thanh trừng']::text[], 'Thanh trừng sạch nước (氵) để đăng (登) cai'),
  ('d0c8f51a-2e12-5a88-b111-0a4accbff337'::uuid, '沈', ARRAY['チン']::text[], ARRAY['trầm']::text[], ARRAY['trầm tĩnh']::text[], 'Người đi (儿) quàng khăn (冖) trầm ngâm dìm mình xuống nước (氵)'),
  ('5eb26841-a8fe-5a51-90ff-f1bff3f578a7'::uuid, '珍', ARRAY['チン']::text[], ARRAY['trân']::text[], ARRAY['quý hiếm']::text[], 'Ông vua (王) có mái tóc (彡) dài là quý hiếm'),
  ('a32e8e6b-df6c-572e-9491-9f40bdc89164'::uuid, '抵', ARRAY['テイ']::text[], ARRAY['đề']::text[], ARRAY['đề kháng']::text[], 'Dùng tay (扌) thấp (氐) để chống cự'),
  ('2db82461-45cc-5879-9979-db2d3e555efc'::uuid, '堤', ARRAY['テイ']::text[], ARRAY['đê']::text[], ARRAY['con đê']::text[], 'Chạy (疋) dưới mặt trời (日) ra vùng đất (土) đê'),
  ('8efa2f15-9a72-59b1-b2b6-e17025cf9c76'::uuid, '提', ARRAY['テイ']::text[], ARRAY['đề']::text[], ARRAY['đề cử']::text[], 'Chạy (疋) dưới mặt trời (日) dơ tay (扌) đề cử'),
  ('cc3213b7-f3ff-5db4-a29c-0dbfca2b40b4'::uuid, '摘', ARRAY['テキ']::text[], ARRAY['trích']::text[], ARRAY['trích xuất']::text[], 'Đứng (立) vây quanh (冂) mộ cổ (古) dùng tay (扌) trích xuất'),
  ('063bbafb-6ca9-5788-8a31-f6ac16597d43'::uuid, '敵', ARRAY['テキ']::text[], ARRAY['địch']::text[], ARRAY['địch thủ']::text[], 'Đứng (立) vây quanh (冂) mộ cổ (古) để đánh (攵) địch'),
  ('2890d1c7-eb34-5688-8076-e0acbbc5fe0b'::uuid, '適', ARRAY['テキ']::text[], ARRAY['thích']::text[], ARRAY['thích hợp, thích đáng']::text[], 'Vừa đứng (立) vừa chạy (辶) xung quanh (冂) mộ cổ (古) vì yêu thích'),
  ('8d2dc283-2057-5f12-91c6-d98088f1875d'::uuid, '滴', ARRAY['テキ']::text[], ARRAY['trích']::text[], ARRAY['nhỏ giọt']::text[], 'Đứng (立) vây quanh (冂) mộ cổ (古) để trích xuất nước (氵)'),
  ('fed947bb-7d92-5e04-a7ea-c21fb3c1914f'::uuid, '添', ARRAY['テン']::text[], ARRAY['thiêm']::text[], ARRAY['thêm vào']::text[], 'Thêm nước (氵) vào lửa (灬) đang cháy giữa trời (天)'),
  ('1fca9366-9d3d-5bd2-9700-33fb1263aa24'::uuid, '殿', ARRAY['デン']::text[], ARRAY['điện']::text[], ARRAY['cung điện']::text[], 'Cùng nhau cầm vũ khí (殳) tấn công vào cung (共) điện cướp xác ướp (尸)'),
  ('7425653e-eb88-52bb-9026-302b10e81405'::uuid, '途', ARRAY['ト']::text[], ARRAY['đồ']::text[], ARRAY['giữa chừng']::text[], 'Nhớ mang dư (余) tiền trên con đường (辶) gây dựng tiền đồ'),
  ('2552adac-f162-5b30-b8dc-a630e3f31e4f'::uuid, '吐', ARRAY['ト']::text[], ARRAY['thổ']::text[], ARRAY['thổ ra']::text[], 'Mở miệng (口) ói ra đất (土)'),
  ('7cd011f9-4c74-5906-8682-e9b15708e6ac'::uuid, '渡', ARRAY['ト']::text[], ARRAY['độ']::text[], ARRAY['vượt qua']::text[], 'Độ (度) cố vượt qua vùng nước (氵)'),
  ('61c10078-4f33-5ab2-a76e-9eb38fe307e1'::uuid, '奴', ARRAY['ド']::text[], ARRAY['nô']::text[], ARRAY['nô tì']::text[], 'Người nô tì nữ (女) lặp đi lặp lại (又) việc giống nhau'),
  ('ee9fba9e-32b7-5728-a428-7896204f336f'::uuid, '怒', ARRAY['ド']::text[], ARRAY['nộ']::text[], ARRAY['tức giận']::text[], 'Tức giận với nô (奴) tì không có tâm (心)'),
  ('4889fdaa-0782-5604-a223-905d63bcab07'::uuid, '透', ARRAY['トウ']::text[], ARRAY['thấu']::text[], ARRAY['trong suốt']::text[], 'Người ưu tú (秀) đi trên đường (辶) sẽ thấu suốt mọi thứ'),
  ('0e945bd0-b953-51db-b51b-e3a4e886101e'::uuid, '唐', ARRAY['トウ']::text[], ARRAY['đường']::text[], ARRAY['nhà Đường']::text[], 'Miệng (口) Em (ヨ) trong nhà (广) nói ra ngoài Đường'),
  ('598b1f8c-cdc3-56a6-84d8-26748759f098'::uuid, '糖', ARRAY['トウ']::text[], ARRAY['đường']::text[], ARRAY['chất đường']::text[], 'Đường ngọt là đường (唐) làm từ gạo (米)'),
  ('91658f57-d914-5230-b53f-5f05c11edadd'::uuid, '桃', ARRAY['トウ']::text[], ARRAY['đào']::text[], ARRAY['cây đào']::text[], 'Triệu (兆) tập ngay cây (木) đào đến đây'),
  ('ca4131ce-c743-54fc-a693-de3f06546424'::uuid, '逃', ARRAY['トウ']::text[], ARRAY['đào']::text[], ARRAY['đào tẩu']::text[], 'Triệu (兆) tập ngay người đang bỏ trốn trên đường (辶)'),
  ('ce0c152e-7bf5-5c11-aea9-29b9a8b74a2e'::uuid, '盗', ARRAY['トウ']::text[], ARRAY['đạo']::text[], ARRAY['đạo tặc']::text[], 'Cứ tiếp (次) tục làm đạo (盗) chích sẽ có ngày lên dĩa (皿) nằm thôi'),
  ('fcb7634f-dcdc-52bb-981d-420c0f478045'::uuid, '塔', ARRAY['トウ']::text[], ARRAY['tháp']::text[], ARRAY['cái tháp']::text[], 'Tháp thời xưa dựng lên bằng cách trộn cỏ hoa (艹) với đất (土) một cách hợp lý (合)')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Kanji — Trang 13-16 (kanji 241-320)
-- ─────────────────────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('31980651-e798-58bf-b997-05ab62bf7dc9'::uuid, '到', ARRAY['トウ']::text[], ARRAY['đáo']::text[], ARRAY['đến nơi']::text[], 'Anh Chí (至) vác dao (刂) đến đáo hạn'),
  ('b6eb4713-9b0d-5472-9fce-fd68f8512d65'::uuid, '倒', ARRAY['トウ']::text[], ARRAY['đảo']::text[], ARRAY['bị đổ']::text[], 'Người (イ) đến hạn không đáo (到) thì bị lật đổ'),
  ('30e4abd5-0454-571b-969a-b7f0f760957b'::uuid, '踏', ARRAY['トウ']::text[], ARRAY['đạp']::text[], ARRAY['dẫm lên']::text[], 'Chân (足) đạp lên nước (水) mỗi ngày (日)'),
  ('435e7518-5966-5aa8-b492-28c388cafe39'::uuid, '稲', ARRAY['トウ']::text[], ARRAY['đạo']::text[], ARRAY['bông lúa']::text[], 'Bông lúa (禾) chín 10 ngày rồi thì dùng trảo (爫) mà gặt'),
  ('446a5872-4ce9-52d3-847e-866a18d79033'::uuid, '闘', ARRAY['トウ']::text[], ARRAY['đấu']::text[], ARRAY['chiến đấu']::text[], 'Chiến đấu cướp đậu (豆) dưới cổng thành (門) là thốn (寸)'),
  ('4247e45c-5da1-5a4a-97dd-0f4877af8705'::uuid, '胴', ARRAY['ドウ']::text[], ARRAY['đồng']::text[], ARRAY['thân người']::text[], 'Cơ thể gì mà cơ thịt (月) cứ đồng (同) đồng'),
  ('59202cfb-aae0-5745-b602-1c0592a19257'::uuid, '峠', ARRAY[]::text[], ARRAY['đèo']::text[], ARRAY['đèo núi']::text[], 'Trên (上) dưới (下) cái núi (山) là cái đèo'),
  ('e9adde3c-e888-517a-b202-38f143513112'::uuid, '突', ARRAY['トツ']::text[], ARRAY['đột']::text[], ARRAY['đột nhiên']::text[], 'Đột nhiên gặp cái huyệt (穴) to (大)'),
  ('813fe586-e18f-5293-98cc-c62cadae7c42'::uuid, '鈍', ARRAY['ドン']::text[], ARRAY['độn']::text[], ARRAY['cùn']::text[], 'Có vàng (金) mà vẫn phải gian truân (屯) đúng là...'),
  ('6bdd8c3b-3410-5e79-9df6-75467fc52027'::uuid, '曇', ARRAY['ドン']::text[], ARRAY['đàm']::text[], ARRAY['trời nhiều mây']::text[], '1 ngày (日) trời nhiều mây (雲)'),
  ('24266a44-a3f0-595d-8d20-9575db3c5845'::uuid, '弐', ARRAY['ニ']::text[], ARRAY['nhị']::text[], ARRAY['số 2']::text[], 'Bọn dặc (弋) nói 1 (一) là 2 (弐)'),
  ('b42d0456-5c4a-5500-a429-466266ddb9d7'::uuid, '悩', ARRAY['ノウ']::text[], ARRAY['não']::text[], ARRAY['phiền não']::text[], 'Con tim (忄) hung (凶) ác thì phiền não'),
  ('f1e788bb-f098-5f8e-8ddf-70fe716ac6ae'::uuid, '濃', ARRAY['ノウ']::text[], ARRAY['nồng']::text[], ARRAY['nồng ấm']::text[], 'Nông (農) mà có nước (氵) thì mùi nồng lên'),
  ('a790d947-91b9-55a8-9c4c-2f8274fce221'::uuid, '輩', ARRAY['ハイ']::text[], ARRAY['bối']::text[], ARRAY['tiền bối']::text[], 'Tiền bối có khác! Phi (非) xe (車) siêu thật!'),
  ('50718f0e-e21a-52cb-aa17-7c692cd4662a'::uuid, '杯', ARRAY['ハイ']::text[], ARRAY['bôi']::text[], ARRAY['chén']::text[], 'Cây (木) mà không (不) tốt thì mang đi làm chén'),
  ('67813d73-8b35-5a9d-9c6f-c70a1044b022'::uuid, '泊', ARRAY['ハク']::text[], ARRAY['bạc']::text[], ARRAY['trọ lại']::text[], 'Trời mưa (氵) trắng (白) xóa lại bị phụ bạc thì phải ở trọ lại'),
  ('c76b1c6f-93e9-5257-a828-e4c75b04a956'::uuid, '拍', ARRAY['ハク']::text[], ARRAY['phách']::text[], ARRAY['vỗ tay']::text[], 'Vỗ tay (扌) đến mức bạch (白) cả tay'),
  ('e321b2b9-58ce-5d57-be3e-82b4bc45a0b4'::uuid, '迫', ARRAY['ハク']::text[], ARRAY['bách']::text[], ARRAY['bức bách']::text[], 'Bị bức bách đi trên con đường (辶) có vạch trắng (白)'),
  ('6f2fe2b8-eb76-526e-a365-5a91dec0fa96'::uuid, '薄', ARRAY['ハク']::text[], ARRAY['bạc']::text[], ARRAY['nhạt']::text[], 'Đồng (田) cỏ (艹) mỏng manh bạc màu vì thiếu thốn (寸) nước (氵)'),
  ('f767b152-3f64-5c15-94bd-826fee5b7300'::uuid, '爆', ARRAY['バク']::text[], ARRAY['bộc']::text[], ARRAY['bộc phát']::text[], 'Bạo (暴) lực mà thêm lửa (火) thì bộc phát'),
  ('52061f98-577e-5ae7-bd7d-15e6c6f2c1b1'::uuid, '髪', ARRAY['ハツ']::text[], ARRAY['phát']::text[], ARRAY['tóc']::text[], 'Phát hiện thằng bạn có 4 đứa em tóc dài'),
  ('b69d970e-ab23-5efc-bf07-93f3f16c8d4e'::uuid, '抜', ARRAY['バツ']::text[], ARRAY['bạt']::text[], ARRAY['rút ra']::text[], 'Lấy tay (扌) bạt tai thằng bạn (友) rồi rút ra khỏi nhóm chơi'),
  ('721e2f66-d370-551c-b64a-66e4b7ceea3e'::uuid, '罰', ARRAY['バツ']::text[], ARRAY['phạt']::text[], ARRAY['hình phạt']::text[], 'Vừa nói (言) chửi vừa lườm con mắt sắc (罒) như dao (刂) là hình phạt đáng sợ'),
  ('8b286339-9985-5521-99ed-066c5cbfc619'::uuid, '敏', ARRAY['ビン']::text[], ARRAY['mẫn']::text[], ARRAY['cần mẫn, mẫn cảm']::text[], 'Mỗi (每) ngày đánh (攵) khẽ mình để cần mẫn chăm chỉ'),
  ('dec58108-7730-5bbe-a4b9-b39cf4bd0d57'::uuid, '繁', ARRAY['ハン']::text[], ARRAY['phồn']::text[], ARRAY['phồn thịnh']::text[], 'Mỗi (每) ngày đánh (攵) khẽ đan sợi chỉ (糸) để được phồn thịnh'),
  ('00985dcb-c4a8-5a15-a931-7481a957ab1b'::uuid, '販', ARRAY['ハン']::text[], ARRAY['phiến']::text[], ARRAY['buôn bán']::text[], 'Mua bán là: lấy đồ trả tiền (貝), hoặc ngược lại (反) bán đồ để lấy tiền (貝)'),
  ('71bea0bf-4800-5ab8-9771-b25f6c240b06'::uuid, '般', ARRAY['ハン']::text[], ARRAY['ban']::text[], ARRAY['bình thường']::text[], 'Thuyền (舟) mà chở vũ khí (殳), ghế là bình thường'),
  ('c108b4e5-0d71-5930-8bf1-238b9f486160'::uuid, '搬', ARRAY['ハン']::text[], ARRAY['ban']::text[], ARRAY['vận chuyển']::text[], 'Dùng tay (扌) ném vũ khí (殳) của kẻ thù lên thuyền (舟) để vận chuyển'),
  ('e3c08f5d-4cab-544d-a87d-ba24724dcb4f'::uuid, '盤', ARRAY['バン']::text[], ARRAY['bàn']::text[], ARRAY['địa bàn']::text[], 'Đặt thuyền (舟) kẻ thù (殳) lên bàn đĩa (皿)'),
  ('7a0413f6-c5a8-52b6-bb0f-444049d85d01'::uuid, '範', ARRAY['ハン']::text[], ARRAY['phạm']::text[], ARRAY['phạm vi']::text[], 'Ở rừng trúc (竹) xe (車) chỉ được chạy trong phạm vi cho phép'),
  ('1b7b8618-cb13-596e-be57-7e1649b87e88'::uuid, '被', ARRAY['ヒ']::text[], ARRAY['bị']::text[], ARRAY['bị hại']::text[], 'Bị hại bị xé rách áo (衣) hở hết cả da (皮)'),
  ('2c7a2f27-f3c2-585e-b551-02cc55f39241'::uuid, '疲', ARRAY['ヒ']::text[], ARRAY['bì']::text[], ARRAY['mệt mỏi']::text[], 'Da (皮) mà bị bệnh (广) thì rất là mệt mỏi'),
  ('4aff42f4-1c78-556d-96ef-0c5a839a2906'::uuid, '彼', ARRAY['ヒ']::text[], ARRAY['bỉ']::text[], ARRAY['anh ta']::text[], 'Một anh chàng chuyên đi (イ) đổ vỏ (皮) bị khinh bỉ'),
  ('065d0569-7b85-5de4-9832-08f382b7230b'::uuid, '避', ARRAY['ヒ']::text[], ARRAY['tỵ']::text[], ARRAY['tị nạn']::text[], 'Trên đường (辶) tị nạn mà nói lời cay đắng trước cửa (辟) thì ai cũng tránh xa'),
  ('2fb10db7-c0c7-5fc6-a6a9-20a7b6809490'::uuid, '壁', ARRAY['ヘキ']::text[], ARRAY['bích']::text[], ARRAY['bức tường']::text[], 'Tích (辟) đất (土) về làm tường'),
  ('e0cc3478-cd35-5ede-b96d-2fc81bbb0ee3'::uuid, '尾', ARRAY['ビ']::text[], ARRAY['vĩ']::text[], ARRAY['cái đuôi']::text[], 'Cái lông (毛) đuôi gì mà to như con ma (尸) vậy'),
  ('c7a16427-b39f-50b3-a6e5-d10686ea74c8'::uuid, '微', ARRAY['ビ']::text[], ARRAY['vi']::text[], ARRAY['hiển vi']::text[], 'Con đường (イ) lên núi (山) còn sót lại dấu chân (儿) nhỏ sau trận đánh (攵) nhau hôm qua'),
  ('e416d331-68ed-57ab-ad4c-8bc23744984f'::uuid, '匹', ARRAY['ヒツ']::text[], ARRAY['thất']::text[], ARRAY['đếm con vật']::text[], 'Đi (儿) tứ phương (匚) đếm động vật'),
  ('6f9f6daa-185b-5887-93ce-765f42af91ed'::uuid, '描', ARRAY['ビョウ']::text[], ARRAY['miêu']::text[], ARRAY['miêu tả']::text[], 'Lấy tay (扌) miêu tả cả cánh đồng cỏ (苗)'),
  ('0070431f-bbae-5934-89d1-19554c34d28e'::uuid, '浜', ARRAY['ヒン']::text[], ARRAY['tân']::text[], ARRAY['bãi biển']::text[], 'Lính (兵) thủy (氵) đang tập trận ở bờ biển'),
  ('3dec20b0-a3fd-5226-a09b-ee121afcc5d8'::uuid, '怖', ARRAY['フ']::text[], ARRAY['bố']::text[], ARRAY['khủng bố']::text[], 'Tâm (忄) sợ khủng bố (布)'),
  ('6341a5b4-5018-5569-ac8c-f33d894f6b01'::uuid, '浮', ARRAY['フ']::text[], ARRAY['phù']::text[], ARRAY['nổi lên']::text[], 'Túm tóc đứa trẻ (孚) đang phập phù nổi trên mặt nước (氵)'),
  ('1e07af60-8350-5e43-a6a1-104eb036e5b4'::uuid, '腐', ARRAY['フ']::text[], ARRAY['hủ']::text[], ARRAY['cổ hủ']::text[], 'Quan phủ (府) cổ hủ cất thịt (肉) trong nhà'),
  ('d622373d-d6dd-5975-b15c-efae529a55d9'::uuid, '敷', ARRAY['フ']::text[], ARRAY['phu']::text[], ARRAY['trải lát']::text[], 'Ông tiều phu (尃) đánh (攵) thằng Nam bắt nó chải chăn mỗi ngày'),
  ('cbb77fd7-8e7a-504e-a22c-715f63f12404'::uuid, '普', ARRAY['フ']::text[], ARRAY['phổ']::text[], ARRAY['phổ biến']::text[], 'Xếp hàng (並) là việc phổ biến hằng ngày ở Nhật (日)'),
  ('9d7ca3a9-a017-5282-bdcb-9e777187603f'::uuid, '賦', ARRAY['フ']::text[], ARRAY['phú']::text[], ARRAY['thiên phú']::text[], 'Người vừa có tiền (貝) vừa có vũ (武) khí thì rất phú quý'),
  ('201e03c2-2ee9-51ba-aff0-e787ff918f9b'::uuid, '舞', ARRAY['ブ']::text[], ARRAY['vũ']::text[], ARRAY['khiêu vũ']::text[], 'Không (無) sai lầm (舛) vì đã học múa'),
  ('f20bae3c-925c-5e08-81a3-9afa4e33b513'::uuid, '幅', ARRAY['フク']::text[], ARRAY['phúc']::text[], ARRAY['chiều rộng']::text[], 'Lấy cái cân (巾) để đo chiều rộng của 10 mảnh ruộng (畐)'),
  ('66ca20c5-9ab1-5369-941b-410a663afcd6'::uuid, '払', ARRAY['フツ']::text[], ARRAY['phất']::text[], ARRAY['trả tiền']::text[], 'Phất tay (扌) lên cứ khư khư (厶) đòi trả tiền'),
  ('cc545f77-5c67-5415-aedb-e9cbfeb575a8'::uuid, '噴', ARRAY['フン']::text[], ARRAY['phún']::text[], ARRAY['phun']::text[], 'Bỏ 30 con số (賁) vào miệng (口) cùng lúc thì phun ra'),
  ('294824f1-95f3-5c31-bc27-d2a505f8f180'::uuid, '柄', ARRAY['ヘイ']::text[], ARRAY['bính']::text[], ARRAY['chuôi cán']::text[], 'Cái chuôi làm bằng phần trong (丙) của cái cây (木)'),
  ('d5b9c8b7-c352-5ea6-86c5-cec442ee9ec0'::uuid, '捕', ARRAY['ホ']::text[], ARRAY['bộ']::text[], ARRAY['bắt']::text[], 'Dùng tay (扌) bắt anh Phủ (甫)'),
  ('da5efa19-e3f9-5eed-9e3c-6c4cf5e94189'::uuid, '舗', ARRAY['ホ']::text[], ARRAY['phố']::text[], ARRAY['phố xá']::text[], 'Đưa A Phủ (甫) lên trạm xá (舎) ở trên phố (舗)'),
  ('fae17b48-8917-52ce-8d93-96d74dc653e1'::uuid, '峰', ARRAY['ホウ']::text[], ARRAY['phong']::text[], ARRAY['núi cao']::text[], 'Truy (夂) đuổi Trương Tam Phong lên đỉnh núi (山)'),
  ('d693e4c7-6372-5f5e-b3f8-3bd237dbf731'::uuid, '抱', ARRAY['ホウ']::text[], ARRAY['bão']::text[], ARRAY['ôm']::text[], 'Lấy tay (扌) bao (包) ôm lấy'),
  ('ecd610d4-bc7b-55b8-b267-3d3d04689ac1'::uuid, '砲', ARRAY['ホウ']::text[], ARRAY['pháo']::text[], ARRAY['khẩu pháo']::text[], 'Lấy đá (石) bao (包) bọc khẩu pháo'),
  ('29a5a3a6-d05d-59e9-90ac-7c88d54c7d74'::uuid, '肪', ARRAY['ボウ']::text[], ARRAY['phương']::text[], ARRAY['mỡ']::text[], 'Nguyệt (月) và phương (方) thì ai nhiều mỡ hơn'),
  ('5b5ac71a-d16c-5e62-a631-816548850e3a'::uuid, '坊', ARRAY['ボウ']::text[], ARRAY['phường']::text[], ARRAY['phố phường']::text[], 'Vùng đất (土) địa phương (方) nay trở thành phường'),
  ('26ce1419-1295-5c60-9109-ccf8c523e8c0'::uuid, '忙', ARRAY['ボウ']::text[], ARRAY['mang']::text[], ARRAY['bận rộn']::text[], 'Tâm (忄) đến chết (亡) vẫn còn mang bận rộn'),
  ('58a1688e-83a9-5f9e-9c28-6276cf0a6555'::uuid, '冒', ARRAY['ボウ']::text[], ARRAY['mạo']::text[], ARRAY['mạo hiểm']::text[], 'Mắt (目) nhìn trực tiếp mặt trời (日) thì mạo hiểm quá'),
  ('2ecc1506-bb2b-558d-8aef-d0da8248f1f6'::uuid, '帽', ARRAY['ボウ']::text[], ARRAY['mạo']::text[], ARRAY['mũ']::text[], 'Mạo (冒) hiểm lấy khăn (巾) làm mũ'),
  ('da525e7c-78ef-5628-97e7-975c9a93d12c'::uuid, '傍', ARRAY['ボウ']::text[], ARRAY['bàng']::text[], ARRAY['bên cạnh']::text[], 'Người (イ) đứng (立) cạnh phương (方) là thằng bàng'),
  ('63c596be-a570-573a-8f0a-82c4f3d1cdce'::uuid, '凡', ARRAY['ボン']::text[], ARRAY['phàm']::text[], ARRAY['tầm thường']::text[], 'Người phàm tục chui xuống gầm ghế (几)'),
  ('7f51a835-34e2-5df7-a636-02b2f7143c30'::uuid, '帆', ARRAY['ハン']::text[], ARRAY['phàm']::text[], ARRAY['thuyền buồm']::text[], 'Vải (巾) thường (凡) dùng làm cánh buồm'),
  ('88093a3a-f6a6-5300-95df-7850b9bb2a6e'::uuid, '盆', ARRAY['ボン']::text[], ARRAY['bồn']::text[], ARRAY['cái khay']::text[], 'Phân (分) cái đĩa (皿) ra làm cái khay'),
  ('adb09d26-3796-5c54-bec9-e5f8b400c9de'::uuid, '漫', ARRAY['マン']::text[], ARRAY['mạn']::text[], ARRAY['lãng mạn, tản mạn']::text[], 'Xem manga (曼) khóc (氵) suốt 1 ngày thật lãng mạn'),
  ('ae8f047c-b7dc-52b4-b1c4-3683bd3fb735'::uuid, '慢', ARRAY['マン']::text[], ARRAY['mạn']::text[], ARRAY['từ từ']::text[], 'Con tim (忄) ngạo mạn (曼) đứng nhìn mặt trời'),
  ('8857bca5-656e-51b1-976b-fa0718012dd7'::uuid, '妙', ARRAY['ミョウ']::text[], ARRAY['diệu']::text[], ARRAY['huyền diệu']::text[], 'Người phụ nữ (女) mặc thiếu (少) tí vải thì rất huyền diệu'),
  ('690354ad-7ac7-5551-892b-c375afbb3d52'::uuid, '眠', ARRAY['ミン']::text[], ARRAY['miên']::text[], ARRAY['ngủ']::text[], 'Mắt (目) của dân (民) chúng bị thôi miên rơi vào giấc ngủ miên man'),
  ('80870c7d-fc91-591a-8e54-8e9184272906'::uuid, '矛', ARRAY['ム']::text[], ARRAY['mâu']::text[], ARRAY['mâu thuẫn']::text[], 'Quỷ xà mâu là một con ma (マ) cầm ô (オ)'),
  ('94b5bfec-1ab6-5d0c-bb8b-b0980621661d'::uuid, '霧', ARRAY['ム']::text[], ARRAY['vụ']::text[], ARRAY['sương mù']::text[], 'Nhiệm vụ (務) của mưa (雨) là tạo ra sương mù'),
  ('d40f71ed-1fc8-51ee-9532-00a813352fc1'::uuid, '娘', ARRAY['ジョウ']::text[], ARRAY['nương']::text[], ARRAY['con gái']::text[], 'Người phụ nữ (女) tốt (良) đó là con gái tôi'),
  ('6f22b29b-6660-5d8c-8f8a-4aeb66a5e1d6'::uuid, '網', ARRAY['モウ']::text[], ARRAY['võng']::text[], ARRAY['cái lưới']::text[], 'Dùng dây (糸) võng (罔) đan lưới'),
  ('b22ed396-28b1-57b2-885d-0d06c68557ac'::uuid, '茂', ARRAY['モ']::text[], ARRAY['mậu']::text[], ARRAY['bụi cây']::text[], 'Thằng Mậu (戊) vác dao phát bụi cây (艹) ở sườn núi'),
  ('5adfe120-4feb-5954-b65d-a0319257caae'::uuid, '猛', ARRAY['モウ']::text[], ARRAY['mãnh']::text[], ARRAY['mãnh liệt']::text[], 'Con chó (犭) tranh đồ ăn trên đĩa (皿) với đứa trẻ (子) mãnh liệt'),
  ('eb37ef9c-4658-5a34-b582-13b65aa7009a'::uuid, '黙', ARRAY['モク']::text[], ARRAY['mặc']::text[], ARRAY['tĩnh mịch, trầm mặc']::text[], 'Lấy lửa (火) đốt con chó (犬) của ông Lý (里) chết, im lặng'),
  ('e502f6f9-7ce4-570e-bd32-f3d8e17b2122'::uuid, '紋', ARRAY['モン']::text[], ARRAY['văn']::text[], ARRAY['hoa văn']::text[], 'Văn (文) mà có dây (糸) thì là hoa văn'),
  ('41b8f7e5-6d97-564d-89f8-27aa0126cb58'::uuid, '躍', ARRAY['ヤク']::text[], ARRAY['dược']::text[], ARRAY['nhảy']::text[], 'Chân (足) chim (隹) nhảy yo yo (ヨ) cả ngày'),
  ('01aef0ad-0e02-56b7-a15f-29398fc959ed'::uuid, '与', ARRAY['ヨ']::text[], ARRAY['dữ']::text[], ARRAY['ban cho']::text[], 'Tham dự hội thảo mỗi 1 năm 1 lần thôi'),
  ('03bf657b-786e-5380-abfb-dd5092f9e2f9'::uuid, '誉', ARRAY['ヨ']::text[], ARRAY['dự']::text[], ARRAY['danh dự']::text[], 'Lời (言) nói mà phát quang (光) bên trên là lời nói có danh dự')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Kanji — Trang 17-20 (80 ô lưới, kanji 321-400; 2 ô là lặp lại ký tự đã có trước đó trong
-- chính nguồn PDF này — 穫 (thu hoạch, đã có ở Trang 4) và 既 (đã, xuất hiện 2 lần ở Trang
-- 19 và Trang 20 — đã bỏ qua ô thứ 2 vì trùng ký tự, không tạo dòng DB mới)
-- ─────────────────────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('f0c8553c-20cb-523e-afe4-168a04f4c71f'::uuid, '腰', ARRAY['ヨウ']::text[], ARRAY['yêu']::text[], ARRAY['cái eo']::text[], 'Chỗ yếu (要) của chị Nguyệt (月) là cái eo'),
  ('27f754ae-6d4b-5fdf-b3ff-3e637aa5f6bd'::uuid, '溶', ARRAY['ヨウ']::text[], ARRAY['dung']::text[], ARRAY['dung dịch']::text[], 'Dung (容) mà có nước (氵) là dung dịch'),
  ('5328e1b4-c5a1-5896-8a3e-1f2340d21870'::uuid, '踊', ARRAY['ヨウ']::text[], ARRAY['dũng']::text[], ARRAY['nhảy múa']::text[], 'Muốn nhảy đẹp thì chân (足) phải thật dũng (甬) mãnh'),
  ('2f688290-7122-50a3-aaf8-39feebb52220'::uuid, '謡', ARRAY['ヨウ']::text[], ARRAY['dao']::text[], ARRAY['ca dao']::text[], 'Vừa nói (言) vừa gõ móng (爫) tay lên cái lon (缶) sẽ ra câu vè ca dao'),
  ('bd731cb8-6ed1-5f7e-a2d0-f3b93e6269f6'::uuid, '翼', ARRAY['ヨク']::text[], ARRAY['dực']::text[], ARRAY['cách']::text[], 'Đôi cánh (羽) chim thật dị (異) thường'),
  ('89e79d5c-712d-5ca8-a514-a5a92cdce4f0'::uuid, '雷', ARRAY['ライ']::text[], ARRAY['lôi']::text[], ARRAY['sấm sét']::text[], 'Mưa (雨) rơi xuống ruộng (田) thiên lôi tạo sét'),
  ('c7567747-4b2b-5a6c-9869-50bdf65d77ec'::uuid, '頼', ARRAY['ライ']::text[], ARRAY['lại']::text[], ARRAY['ỷ lại']::text[], 'Tôi nhờ anh bó (束) lại 1 trang (頁) giấy'),
  ('f1e4882e-25ba-5b68-b101-8d9039bc0750'::uuid, '瀬', ARRAY['ライ']::text[], ARRAY['lại']::text[], ARRAY['nông, cạn']::text[], 'Đừng ỷ lại (頼) rằng nó là vùng nước (氵) nông'),
  ('b8eb3acd-e6ee-5c18-8a14-8d3d71093dea'::uuid, '絡', ARRAY['ラク']::text[], ARRAY['lạc']::text[], ARRAY['buộc']::text[], 'Lấy dây (糸) cột miệng các (各) vị lại làm sợi dây liên lạc'),
  ('41d973ef-fc36-58e6-ac98-710b06b6dd33'::uuid, '欄', ARRAY['ラン']::text[], ARRAY['lan']::text[], ARRAY['lan can']::text[], 'Lan can làm bằng gỗ (木) ở ngoài cửa (門) hướng về phía đông (東)'),
  ('9bc8b412-14ae-5952-b560-a150177884b4'::uuid, '離', ARRAY['リ']::text[], ARRAY['li']::text[], ARRAY['rời khỏi']::text[], 'Cái đầu (亠) hung (凶) ác, chia li 4 (厶) con chim khỏi biên (隹) giới (冂) của nó'),
  ('35422778-c691-573e-bbd7-f230781d127a'::uuid, '粒', ARRAY['リュウ']::text[], ARRAY['lạp']::text[], ARRAY['hạt, hột']::text[], 'Đứng (立) lựa từng hạt gạo (米)'),
  ('00eb3ae5-8619-5422-86cd-4cf540f80f10'::uuid, '療', ARRAY['リョウ']::text[], ARRAY['liệu']::text[], ARRAY['trị liệu']::text[], 'Liệu (寮) bị bệnh (疒) thì phải điều trị'),
  ('c2813c4c-c43d-5f12-80f9-617616823103'::uuid, '寮', ARRAY['リョウ']::text[], ARRAY['liêu']::text[], ARRAY['ký túc xá']::text[], 'Liệu (寮) ở kí túc xá dưới mái nhà (宀)'),
  ('429ec183-ab52-5852-a632-3e483cc55627'::uuid, '僚', ARRAY['リョウ']::text[], ARRAY['liêu']::text[], ARRAY['đồng liêu']::text[], 'Liệu (寮) là người (イ) đồng liêu với mình'),
  ('67ab081b-615d-58b6-924b-d3e732676ea8'::uuid, '隣', ARRAY['リン']::text[], ARRAY['lân']::text[], ARRAY['lân cận']::text[], 'Ấp (阝) lúa (米) bên cạnh ta (夕) quanh năm (年)'),
  ('b4261837-83f4-5fd0-ab9f-e37aa8790b6b'::uuid, '戻', ARRAY['レイ']::text[], ARRAY['lệ']::text[], ARRAY['quay lại']::text[], 'Việc trọng đại (大) mới quay lại cửa (戸) lấy đồ'),
  ('169f389f-bb92-5d17-a00b-3bb8dd2a3e34'::uuid, '涙', ARRAY['ルイ']::text[], ARRAY['lệ']::text[], ARRAY['nước mắt']::text[], 'Chờ người quay lại (戻) trong nước (氵) mắt'),
  ('133cd28d-4213-5bb0-8679-8c7d272b15c9'::uuid, '隷', ARRAY['レイ']::text[], ARRAY['lệ']::text[], ARRAY['nô lệ']::text[], 'Kẻ sĩ (士) bị kì thị (示) và ngược đãi (隶) như nô lệ'),
  ('4ad8816c-851f-511d-96c8-cf7a787a4e1c'::uuid, '麗', ARRAY['レイ']::text[], ARRAY['lệ']::text[], ARRAY['tráng lệ']::text[], 'Hai con mắt của con hươu (鹿) thật diễm lệ'),
  ('1501c16a-d008-533c-93ed-8f56968afc8e'::uuid, '齢', ARRAY['レイ']::text[], ARRAY['linh']::text[], ARRAY['tuổi']::text[], 'Người cao tuổi lạnh (令) hay bị ê răng (歯)'),
  ('5edb639e-1317-5389-b192-67c34a1d6dff'::uuid, '暦', ARRAY['レキ']::text[], ARRAY['lịch']::text[], ARRAY['lịch niên']::text[], 'Ngày xưa hảo hán (厂) đi rừng (林) về nhà là đếm lịch 1 ngày (日)'),
  ('427e8186-3aca-579d-a6d2-8734116b2d0e'::uuid, '劣', ARRAY['レツ']::text[], ARRAY['liệt']::text[], ARRAY['kém hèn']::text[], 'Lực (力) mà ít (少) thì là nằm liệt yếu kém'),
  ('3e4e2c7e-264d-5913-99da-836a898d9b6d'::uuid, '烈', ARRAY['レツ']::text[], ARRAY['liệt']::text[], ARRAY['bùng nổ']::text[], 'Liệt (列) thêm lửa (灬) cho mãnh liệt một hàng'),
  ('670581a8-d715-57e9-9501-2eb4114316b0'::uuid, '恋', ARRAY['レン']::text[], ARRAY['luyến']::text[], ARRAY['tình yêu']::text[], 'Lưu Diệc (亦) Phi làm trái tim (心) tôi lưu luyến'),
  ('dff062bd-07cf-5425-8883-935941a2e813'::uuid, '露', ARRAY['ロ']::text[], ARRAY['lộ']::text[], ARRAY['sương mù, lộ ra']::text[], 'Mưa (雨) ở giao lộ (路) tạo thành giọt sương'),
  ('71a11a31-c23f-5cf6-8fc2-45bf2ce9b285'::uuid, '郎', ARRAY['ロウ']::text[], ARRAY['lang']::text[], ARRAY['con trai']::text[], 'Vùng đất (阝) tốt (良) là vùng đất phải có tân lang'),
  ('df8e74da-deea-5f05-8bbc-4bbc740f3c6e'::uuid, '惑', ARRAY['ワク']::text[], ARRAY['hoặc']::text[], ARRAY['mê hoặc']::text[], 'Con tim bạn (心) đã bị mê hoặc (或)'),
  ('6714d7cb-bd1b-553c-b02e-c3d8803755db'::uuid, '腕', ARRAY['ワン']::text[], ARRAY['oản']::text[], ARRAY['cánh tay']::text[], 'Tay chị nguyệt (月) oản tủ tì rất uyển (宛) chuyển'),
  ('15369122-d1e5-501b-a1dd-1cde0265fd2c'::uuid, '哀', ARRAY['アイ']::text[], ARRAY['ai']::text[], ARRAY['bi ai']::text[], 'Miệng (口) không có y (衣) phục thật là bi ai'),
  ('c7ba9a11-e319-5321-a224-19717bb6f7dc'::uuid, '慰', ARRAY['イ']::text[], ARRAY['úy']::text[], ARRAY['an ủi']::text[], 'Trung úy (尉) an ủi người dân bằng cả trái tim (心)'),
  ('9f00f763-8010-5669-8824-19e20980d9c1'::uuid, '詠', ARRAY['エイ']::text[], ARRAY['vịnh']::text[], ARRAY['làm thơ']::text[], 'Nói (言) lời vĩnh cửu (永) hay như vịnh thơ'),
  ('5f38ac5e-9590-52ab-b90d-88fb0913c734'::uuid, '悦', ARRAY['エツ']::text[], ARRAY['duyệt']::text[], ARRAY['mãn nguyện']::text[], 'Anh trai (兄) mọc 2 cái sừng làm cho trái tim (忄) thật mãn nguyện'),
  ('4e88f581-ecf7-5569-a7b8-3925adb376b6'::uuid, '閲', ARRAY['エツ']::text[], ARRAY['duyệt']::text[], ARRAY['kiểm duyệt']::text[], 'Anh (兄) tui đã duyệt cho tên ấy qua cửa (門) rồi'),
  ('504e0d34-5a71-5fb8-ae17-a1420aa7ccf8'::uuid, '炎', ARRAY['エン']::text[], ARRAY['viêm']::text[], ARRAY['cháy lớn']::text[], 'Đám lửa (火) cháy lớn'),
  ('0d071a95-85fc-5e82-919f-aaddb366f4cb'::uuid, '宴', ARRAY['エン']::text[], ARRAY['yến']::text[], ARRAY['yến tiệc']::text[], 'Cô gái (女) trong nhà (宀) tổ chức yến tiệc nguyên 1 ngày (日)'),
  ('7ff87f61-1a4d-501d-8310-d8e8eb1b74ed'::uuid, '欧', ARRAY['オウ']::text[], ARRAY['âu']::text[], ARRAY['châu Âu']::text[], 'Châu Âu là khu (区) vực không thể thiếu (欠)'),
  ('ed67b477-a2e7-5980-a329-fdefe6563759'::uuid, '殴', ARRAY['オウ']::text[], ARRAY['ẩu']::text[], ARRAY['ẩu đả']::text[], 'Khu (区) đất có nhiều vũ (殳) khí sẽ xảy ra ẩu đả'),
  ('007185ef-5712-55d0-8514-4b17a891eb7a'::uuid, '乙', ARRAY['オツ']::text[], ARRAY['ất']::text[], ARRAY['can thứ 2']::text[], 'Bộ thủ nè'),
  ('bf0d85b1-4690-58c4-b3a3-0fa0f63ae5a3'::uuid, '卸', ARRAY['シャ']::text[], ARRAY['tá']::text[], ARRAY['bán sỉ']::text[], 'Dừng lại (止) nằm (一) bán cả tá đốt tre (卩)'),
  ('73b34678-5cd6-5b8a-ab16-da5071ccf8ee'::uuid, '穏', ARRAY['オン']::text[], ARRAY['ổn']::text[], ARRAY['yên ổn']::text[], 'Trúng (当) mùa lúa (禾) là cái tâm (心) yên ổn (穏)'),
  ('2895e708-4274-554b-a232-43ac67956069'::uuid, '架', ARRAY['カ']::text[], ARRAY['giá']::text[], ARRAY['giá treo']::text[], 'Gia (加) tăng thêm cây (木) làm giá đỡ'),
  ('a2595ccf-9bfd-5e89-b1f9-05b74ced99e1'::uuid, '佳', ARRAY['カ']::text[], ARRAY['giai']::text[], ARRAY['giai nhân']::text[], 'Người (イ) có 2 mảnh đất (圭) là giai nhân'),
  ('3ba2b5c2-23eb-58ea-a028-1dee8d70fe37'::uuid, '華', ARRAY['カ']::text[], ARRAY['hoa']::text[], ARRAY['hoa mĩ']::text[], 'Trồng cỏ (艹) trên 10 (十) cái ruộng (田) thật là hoa mỹ'),
  ('b8f10025-4438-579d-8298-225c8a96c1ed'::uuid, '嫁', ARRAY['カ']::text[], ARRAY['giá']::text[], ARRAY['xuất giá']::text[], 'Sau khi xuất giá (嫁) thì con gái (女) chỉ ở nhà (家) nội trợ'),
  ('49131266-4a97-5713-aa77-41f705685c9d'::uuid, '餓', ARRAY['ガ']::text[], ARRAY['ngạ']::text[], ARRAY['đói']::text[], 'Bản ngã (我) của con người là đói thì ăn (飠)'),
  ('974ff2eb-4bbd-5e04-9de2-4118f1b5c9cc'::uuid, '怪', ARRAY['カイ']::text[], ARRAY['quái']::text[], ARRAY['ma quái']::text[], 'Yêu quái lại có tâm (忄) thánh (圣) thiện thật đáng nghi ngờ'),
  ('eb24c643-18d0-5d73-ac06-cfd33e0068ba'::uuid, '悔', ARRAY['カイ']::text[], ARRAY['hối']::text[], ARRAY['hối hận']::text[], 'Tâm (忄) mỗi (毎) lần làm sai tâm thấy hối hận'),
  ('13ebbc6d-3497-542a-a5f8-1a268518f479'::uuid, '既', ARRAY['キ']::text[], ARRAY['kí']::text[], ARRAY['đã']::text[], 'Xấu hay tốt (艮) thì cũng đã kí (旡) rồi'),
  ('48d73d10-0bcd-554e-a970-10db1fdc37f7'::uuid, '概', ARRAY['ガイ']::text[], ARRAY['khái']::text[], ARRAY['khái niệm']::text[], 'Những cây (木) đã ký (既) xong thì chỉ nói khái quát'),
  ('06c6a547-203e-5d58-922f-50ce6ddcba96'::uuid, '慨', ARRAY['ガイ']::text[], ARRAY['khái']::text[], ARRAY['than thở']::text[], 'Điều đã (既) rồi mà để vào tim (忄) thì là hối tiếc'),
  ('62acd5bc-6cb2-5597-a9b9-ba24f765ce48'::uuid, '郭', ARRAY['カク']::text[], ARRAY['quách']::text[], ARRAY['thành quách']::text[], 'Anh quách nằm hưởng (享) thụ trên quả đất (阝)'),
  ('343611ed-7ea6-55c2-a379-5abbc0733f82'::uuid, '隔', ARRAY['カク']::text[], ARRAY['cách']::text[], ARRAY['ngăn cách']::text[], 'Vùng đất (阝) được chia ra làm 10 tứ hướng'),
  ('a863f157-8333-5a84-ad39-cabc22234891'::uuid, '岳', ARRAY['ガク']::text[], ARRAY['nhạc']::text[], ARRAY['núi cao, nhạc phụ']::text[], 'Nhạc phụ làm lính (丘) trên núi (山)'),
  ('a3b45ae4-810c-5989-8e0c-7c0fc560d3fb'::uuid, '掛', ARRAY['カイ']::text[], ARRAY['quải']::text[], ARRAY['treo']::text[], 'Tay (扌) to (卜) mới quải (掛) được 2 mảnh đất (土)'),
  ('cef8e4a1-ae76-5c83-a29e-9a0bbf0949b6'::uuid, '滑', ARRAY['カツ']::text[], ARRAY['hoạt']::text[], ARRAY['trơn trượt']::text[], 'Xương khớp (骨) bị trượt nước (氵)'),
  ('bd572d40-37c9-56fd-a5f5-74c57ce6cc9e'::uuid, '勘', ARRAY['カン']::text[], ARRAY['khám']::text[], ARRAY['trực giác']::text[], 'Dùng sức lực (力) của 4 mắt (甚) để khám định'),
  ('490251fb-200e-5d5c-ad46-01174b9f9f55'::uuid, '肝', ARRAY['カン']::text[], ARRAY['can']::text[], ARRAY['gan']::text[], 'Chị nguyệt (月) có cái gan khô khan (干)'),
  ('859afcd6-b077-5e7d-99eb-48286e31f4aa'::uuid, '貫', ARRAY['カン']::text[], ARRAY['quán']::text[], ARRAY['nhất quán']::text[], 'Quán (慣) mà mất tâm (忄) thì là nhất quán'),
  ('69293563-51a5-5398-a391-93c6991dd8b4'::uuid, '敢', ARRAY['カン']::text[], ARRAY['cảm']::text[], ARRAY['dũng cảm']::text[], 'Người làm công (工) bị đánh (攵) vào tai (耳) thì sẽ dũng cảm đứng lên'),
  ('04262622-b7d9-5017-9e6b-252d637b30ef'::uuid, '緩', ARRAY['カン']::text[], ARRAY['hoãn']::text[], ARRAY['chậm rãi, lỏng lẻo']::text[], 'Viên (爰) dùng chỉ (糸) trì hoãn việc'),
  ('f55a73fc-5bc8-541a-9c7a-57011c5f16df'::uuid, '暖', ARRAY['ダン']::text[], ARRAY['noãn']::text[], ARRAY['ấm']::text[], 'Viên (爰) đứng dưới mặt trời (日) để sưởi ấm'),
  ('7b8d180a-83b6-5604-a2d7-79e50a830749'::uuid, '冠', ARRAY['カン']::text[], ARRAY['quán']::text[], ARRAY['đứng đầu']::text[], 'Đội nguyên (元) cái mũ (冖) vương miện quán quân cảm giác hơi thốn (寸)'),
  ('727a45c8-323f-5963-b9a3-2a3168164c54'::uuid, '換', ARRAY['カン']::text[], ARRAY['hoán']::text[], ARRAY['hoán đổi']::text[], 'Hoán (奐) dùng tay (扌) hoán đổi tứ đại'),
  ('e30c729c-d1e7-5c0d-bfa3-968ad1b2d836'::uuid, '喚', ARRAY['カン']::text[], ARRAY['hoán']::text[], ARRAY['hô hoán']::text[], 'Hoán (奐) dùng mồm (口) hô hoán'),
  ('21cd07fe-7667-58a8-b7eb-fdf923a2d81c'::uuid, '企', ARRAY['キ']::text[], ARRAY['xí']::text[], ARRAY['xí nghiệp']::text[], 'Nhìn giống cái nhà xí nghiệp nè'),
  ('bd5b106f-2aa9-550a-8dca-a7f0a9417e68'::uuid, '軌', ARRAY['キ']::text[], ARRAY['quỹ']::text[], ARRAY['quỹ đạo']::text[], 'Xe (車) chạy quỹ đạo hình số 9 (九)'),
  ('254100cc-4658-537f-a27a-357af432a203'::uuid, '棄', ARRAY['キ']::text[], ARRAY['khí']::text[], ARRAY['quên, bỏ']::text[], 'Bỏ quên 30 (廿) cây (木) trong quá khứ (去) ngoài không khí'),
  ('915c4a3b-9068-5033-b782-3ab7ff7d38bd'::uuid, '棋', ARRAY['キ']::text[], ARRAY['kì']::text[], ARRAY['quân cờ']::text[], 'Quân cờ (其) làm từ gỗ cây (木)'),
  ('e147409a-0a87-54c3-8a4f-85df71add82f'::uuid, '忌', ARRAY['キ']::text[], ARRAY['kị']::text[], ARRAY['đố kị']::text[], 'Tâm (心) tự kỉ (己) thường đố kị'),
  ('e4343008-9bf5-58ef-b608-7368480ebe7d'::uuid, '欺', ARRAY['ギ']::text[], ARRAY['khi']::text[], ARRAY['lừa dối']::text[], 'Đến kì (其) mà thiếu (欠) mình tiền là lừa mình rồi'),
  ('c2ffaa22-1b90-5198-bb3b-3c0fc2a8ba3e'::uuid, '岐', ARRAY['キ']::text[], ARRAY['kì']::text[], ARRAY['phân nhánh']::text[], 'Núi (山) chia thành 10 chi nhánh (支)'),
  ('f540e37f-739c-53cf-9708-83e8094893e4'::uuid, '騎', ARRAY['キ']::text[], ARRAY['kị']::text[], ARRAY['cưỡi ngựa']::text[], 'Trương vô kị cưỡi ngựa (馬) thật kì (奇) diệu'),
  ('4c049ac4-95e1-58c3-ad62-25ac4ab0f16b'::uuid, '犠', ARRAY['ギ']::text[], ARRAY['hi']::text[], ARRAY['hi sinh']::text[], 'Con trâu (牛) vì chính nghĩa (義) nên đã hi sinh'),
  ('c2a4f0d8-02b9-5993-9edd-546652fc7c68'::uuid, '菊', ARRAY['キク']::text[], ARRAY['cúc']::text[], ARRAY['hoa cúc']::text[], 'Cô thảo (艹) trồng hoa cúc bao (勹) quanh lúa (米)'),
  ('764a39ac-e6b1-54c7-b6da-b8db0e7b7ce1'::uuid, '吉', ARRAY['キチ']::text[], ARRAY['cát']::text[], ARRAY['tốt lành']::text[], 'Kẻ sĩ (士) mồm (口) nói điều tốt lành'),
  ('8c748d10-6879-54f4-9224-3987ef735628'::uuid, '喫', ARRAY['キツ']::text[], ARRAY['khiết']::text[], ARRAY['ăn uống']::text[], 'Ông vua (王) con dùng dao (刀) to (大) và cái miệng (口) để ăn uống tinh khiết'),
  ('587916be-10ef-5d9a-85b5-fcd4f74f40c0'::uuid, '脅', ARRAY['キョウ']::text[], ARRAY['hiếp']::text[], ARRAY['đe dọa']::text[], 'Ba anh lực (力) đe dọa chị nguyệt (月)')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Kanji — Trang 21-24 (kanji 401-480)
-- ─────────────────────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('ec7f0a7b-312b-5f62-bf9b-f1ffa3860f13'::uuid, '峡', ARRAY['キョウ']::text[], ARRAY['hạp']::text[], ARRAY['hẻm núi']::text[], 'Thằng lai (来) đứng bên hẻm núi (山) rất hẹp'),
  ('443c5e9f-4f19-5227-a9b8-ed86e0868034'::uuid, '凝', ARRAY['ギョウ']::text[], ARRAY['ngưng']::text[], ARRAY['đóng băng']::text[], 'Nghi ngờ (疑) việc đóng băng (冫) bị ngưng lại'),
  ('3b3661f8-e35b-5559-b04a-7a68d8656e5f'::uuid, '緊', ARRAY['キン']::text[], ARRAY['khẩn']::text[], ARRAY['khẩn cấp']::text[], 'Khẩn cấp đại thần (臣) lại (又) làm rơi cuộn chỉ (糸) rồi'),
  ('9c120962-bdc5-5ea9-8e47-672ea31c86ce'::uuid, '斤', ARRAY['キン']::text[], ARRAY['cân']::text[], ARRAY['cái búa']::text[], 'Bộ thủ nè'),
  ('7bbe23bd-a0da-54ea-9541-052db51595a1'::uuid, '愚', ARRAY['グ']::text[], ARRAY['ngu']::text[], ARRAY['ngu ngốc']::text[], 'Trái tim (心) ngu (禺) ngốc'),
  ('64393283-f7c0-52eb-8444-6ee677e118da'::uuid, '偶', ARRAY['グウ']::text[], ARRAY['ngẫu']::text[], ARRAY['ngẫu nhiên']::text[], 'Ngẫu nhiên chọn 1 người (イ) ngu ngốc (禺)'),
  ('69208ad7-8d57-5a14-9fd6-b85089ca8d91'::uuid, '遇', ARRAY['グウ']::text[], ARRAY['ngộ']::text[], ARRAY['đãi ngộ']::text[], 'Đãi ngộ người ngu (禺) trên đường (辶)'),
  ('9d386476-e6e3-56c3-97c2-a63d11a013b5'::uuid, '啓', ARRAY['ケイ']::text[], ARRAY['khải']::text[], ARRAY['làm sáng tỏ']::text[], 'Đánh (攵) vào miệng (口) thằng Khải ở cửa (戸) để làm sáng tỏ'),
  ('c81aa63b-2e7e-5697-b8fb-cbce0b8ebbe9'::uuid, '鶏', ARRAY['ケイ']::text[], ARRAY['kê']::text[], ARRAY['gà']::text[], 'Con chim (鳥) mà ông chồng (夫) dùng móng tay (爫) bắt được là con gà'),
  ('83cfba81-af89-5bb5-a649-dee3ae8ffa8a'::uuid, '携', ARRAY['ケイ']::text[], ARRAY['huề']::text[], ARRAY['đi cùng']::text[], 'Tay (扌) nắm 13 con chim (隹) để đi cùng với huề'),
  ('494c39d7-2dd2-56b2-bb79-85ea96c9a625'::uuid, '刑', ARRAY['ケイ']::text[], ARRAY['hình']::text[], ARRAY['hình phạt']::text[], 'Hình phạt là chấp tay (廾) cầm đao (刂)'),
  ('ed9b0e61-51bd-5fb5-9360-4fa274b094cd'::uuid, '憩', ARRAY['ケイ']::text[], ARRAY['khế']::text[], ARRAY['nghỉ ngơi']::text[], 'Lúc nghỉ ngơi lưỡi (舌) và tim (心) vẫn tự (自) hoạt động'),
  ('65aa9cf1-9bf5-5e54-abfe-7197e8ca5a0c'::uuid, '契', ARRAY['ケイ']::text[], ARRAY['khiết']::text[], ARRAY['hợp đồng']::text[], 'Khế ước do ông chủ (王) lớn (大) cầm dao (刀) đề ra'),
  ('4825fdde-1f0c-5f70-8daa-c5b8a4fee867'::uuid, '掲', ARRAY['ケイ']::text[], ARRAY['yết']::text[], ARRAY['niêm yết']::text[], 'Niêm yết rằng tay (扌) cầm cái thìa (匕) bao quanh hết ngày (日)'),
  ('6f9af280-fd17-54d2-ba57-edb631ff46ff'::uuid, '鯨', ARRAY['ゲイ']::text[], ARRAY['kình']::text[], ARRAY['cá voi']::text[], 'Cá (魚) ở kinh (京) đô là con cá kình'),
  ('9a5d68a4-86fc-5dd3-a50d-3a4ee9cb037d'::uuid, '賢', ARRAY['ケン']::text[], ARRAY['hiền']::text[], ARRAY['khôn ngoan']::text[], 'Ông thần (臣) trở lại (又) hiền mờ (ノ) sò (貝) thật khôn ngoan'),
  ('a6e02128-e5c9-5cd8-b1ca-7d634c713ba3'::uuid, '倹', ARRAY['ケン']::text[], ARRAY['kiệm']::text[], ARRAY['tiết kiệm']::text[], 'Người đội nón là người biết tiết kiệm'),
  ('2ef22335-0df4-5620-aeb7-d5d5d97f6b14'::uuid, '幻', ARRAY['ゲン']::text[], ARRAY['ảo']::text[], ARRAY['huyền ảo']::text[], 'Yêu (幺) cái J mà không biết là ảo tưởng'),
  ('e32be6d5-0689-5a23-8a38-eefa14ee8340'::uuid, '雇', ARRAY['コ']::text[], ARRAY['cô']::text[], ARRAY['thuê']::text[], 'Bà cô thuê con chim (隹) canh cửa (戸)'),
  ('21233c6a-7b22-5168-865f-930590b85ea6'::uuid, '顧', ARRAY['コ']::text[], ARRAY['cố']::text[], ARRAY['quay lại']::text[], 'Thấy giấy (頁) thuê (雇) người quay lại (顧) xem'),
  ('ea081512-0fb5-5bba-8bf6-e366ccd0db42'::uuid, '弧', ARRAY['コ']::text[], ARRAY['hồ']::text[], ARRAY['vòng cung']::text[], 'Xách cây cung (弓) chạy ngang qua (瓜) bờ hồ'),
  ('d4ef4c0c-71ed-52dd-ac19-0d92d89dd847'::uuid, '孤', ARRAY['コ']::text[], ARRAY['cô']::text[], ARRAY['cô lập']::text[], 'Trẻ con (子) để móng (瓜) tay sẽ bị cô lập'),
  ('8b7f0840-00c0-5ccf-a52f-eb06452eeb2c'::uuid, '呉', ARRAY['ゴ']::text[], ARRAY['ngô']::text[], ARRAY['nước Ngô']::text[], 'Tôi có năm (五) cái miệng (口) nhai ngô'),
  ('7bd01ec5-9f70-563f-8d18-2b4948a759f9'::uuid, '悟', ARRAY['ゴ']::text[], ARRAY['ngộ']::text[], ARRAY['ngộ ra']::text[], 'Tâm (忄) ăn ngô (吾) rồi thì cũng phải ngộ ra thôi'),
  ('b7c23dd4-b114-544f-833d-e1b7ee45d4fb'::uuid, '娯', ARRAY['ゴ']::text[], ARRAY['ngu']::text[], ARRAY['vui vẻ']::text[], 'Phụ nữ (女) ăn ngô (吾) thường vui vẻ'),
  ('75195143-03fd-5e04-9c16-8eabba48c288'::uuid, '甲', ARRAY['コウ']::text[], ARRAY['giáp']::text[], ARRAY['thiết giáp']::text[], 'Đảo ngược sự tự do là bị bao bọc như thiết giáp'),
  ('3b5b216d-941b-51ac-a42c-d02db8a2c08d'::uuid, '孔', ARRAY['コウ']::text[], ARRAY['khổng']::text[], ARRAY['Khổng Tử']::text[], 'Nuôi con nhỏ (子) chỉ có Zỗ, không có lãi đâu'),
  ('b67aeeca-fbf6-5c3c-b968-c879d1c7dea8'::uuid, '控', ARRAY['コウ']::text[], ARRAY['khống']::text[], ARRAY['khống chế']::text[], 'Dùng tay (扌) khống chế không trung (空)'),
  ('05a778e5-68f6-5f19-a8e1-72859c9a027d'::uuid, '拘', ARRAY['コウ']::text[], ARRAY['câu']::text[], ARRAY['câu nệ']::text[], 'Câu nệ quá đấy, đã bao miệng (句) lại còn dơ tay (扌) làm gì'),
  ('b42cf5a6-4ce7-5a03-908c-ca3d949f09a1'::uuid, '郊', ARRAY['コウ']::text[], ARRAY['giao']::text[], ARRAY['ngoại ô']::text[], 'Mông (阝) giao (交) nhau ở ngoại ô'),
  ('d3937a69-4b51-5871-9875-95b51ef2ebb6'::uuid, '硬', ARRAY['コウ']::text[], ARRAY['ngạnh']::text[], ARRAY['ương ngạnh']::text[], 'Mang hòn đá (石) đi nấu canh (更) thì nó vẫn cứng'),
  ('4589281f-10a0-5d89-802f-9658bc836734'::uuid, '綱', ARRAY['コウ']::text[], ARRAY['cương']::text[], ARRAY['dây thừng']::text[], 'Cương (岡) lên đồi lấy chỉ (糸) làm dây thừng'),
  ('6e7cedb0-a00d-5a04-ae9a-1ce3b3ab1d09'::uuid, '巧', ARRAY['コウ']::text[], ARRAY['xảo']::text[], ARRAY['tinh xảo']::text[], 'Công (工) việc làm 5 (丂) lần sẽ thành kĩ xảo'),
  ('3c6b2185-8a82-5cfc-8310-293c181e022e'::uuid, '坑', ARRAY['コウ']::text[], ARRAY['khanh']::text[], ARRAY['cái hố']::text[], 'Dám kháng (亢) chỉ khanh bị chôn xuống hố đất (土)'),
  ('8ab6ee86-6d1a-5e71-b46a-9b51c1149818'::uuid, '絞', ARRAY['コウ']::text[], ARRAY['giảo']::text[], ARRAY['vắt, thắt']::text[], 'Sợi dây (糸) giao nhau (交) tạo thành nút thắt (絞)'),
  ('ec7a6bfe-27cf-51b8-bb0c-4639878a90a9'::uuid, '酵', ARRAY['コウ']::text[], ARRAY['diệu']::text[], ARRAY['lên men']::text[], 'Ủ rượu (酉) lên men thể hiện sự hiếu (孝) thảo'),
  ('b49c34ef-d988-54de-b5da-23a54663d121'::uuid, '克', ARRAY['コク']::text[], ARRAY['khắc']::text[], ARRAY['khắc phục']::text[], '10 sư Huynh (兄) cùng nhau khắc phục'),
  ('a5e66c17-1c31-55f8-b9e8-3428dfd32002'::uuid, '獄', ARRAY['ゴク']::text[], ARRAY['ngục']::text[], ARRAY['tù ngục']::text[], '2 con chó (犬) và (犭) nói chuyện (言) với nhau trong ngục'),
  ('438446cb-cdfe-5a5c-af27-31f289503573'::uuid, '紺', ARRAY['コン']::text[], ARRAY['cám']::text[], ARRAY['xanh sẫm']::text[], 'Cho chỉ (糸) vào cốc nước cam (甘) sẽ biến thành màu xanh biếc'),
  ('8241b29c-0dc7-5f6c-9785-53a4667927c2'::uuid, '恨', ARRAY['コン']::text[], ARRAY['hận']::text[], ARRAY['hận thù']::text[], 'Tâm (忄) tốt (艮) là tâm không hận thù'),
  ('4dc9b103-5cb0-56a6-916c-1f9cbb3ec6f2'::uuid, '墾', ARRAY['コン']::text[], ARRAY['khẩn']::text[], ARRAY['khai khẩn']::text[], 'Khai khẩn đất (土) làm lương (艮) và nuôi lợn (豕)'),
  ('953cf5ae-778f-5807-9840-3f8b297dec84'::uuid, '催', ARRAY['サイ']::text[], ARRAY['thôi']::text[], ARRAY['thôi thúc']::text[], 'Chim (崔) kêu thôi thúc người (イ) lên núi'),
  ('53c0623b-e38a-5ef2-8d50-24fde614d7bb'::uuid, '債', ARRAY['サイ']::text[], ARRAY['trái']::text[], ARRAY['khoản nợ, trái phiếu']::text[], 'Trách nhiệm (責) của người (イ) dân là phải mua trái phiếu'),
  ('bc8682f6-1667-5b81-990a-2049fadef23c'::uuid, '削', ARRAY['サク']::text[], ARRAY['tước']::text[], ARRAY['bóc vỏ']::text[], 'Dùng dao (刂) tước chị nguyệt (月) làm 3 (肖)'),
  ('78a05599-e38d-50af-a19e-d58773ebcfda'::uuid, '錯', ARRAY['サク']::text[], ARRAY['thác']::text[], ARRAY['lẫn lộn, thác loạn']::text[], 'Người ngày xưa (昔) mà có tiền (金) thì chỉ để thác loạn'),
  ('1b0d3f9b-93c0-553a-97bf-4f0847ebb3b1'::uuid, '搾', ARRAY['サク']::text[], ARRAY['trá']::text[], ARRAY['vắt, ép']::text[], 'Dùng tay (扌) không ép hoa quả bằng cái cào sưa (窄)'),
  ('9804ea14-45b2-562c-bc9b-1ee00e4161b8'::uuid, '撮', ARRAY['サツ']::text[], ARRAY['toát']::text[], ARRAY['chụp ảnh']::text[], 'Sự tối (最) của 1 tay (扌) săn ảnh là phải toát (撮) lên về đẹp'),
  ('25d68f67-cd0e-518c-8cc3-5559bf800de4'::uuid, '擦', ARRAY['サツ']::text[], ARRAY['sát']::text[], ARRAY['ma sát']::text[], 'Cảnh sát dùng tay (扌) xoa xát (察) kẻ phạm tội'),
  ('64e181da-2a90-534a-b524-c84774da277e'::uuid, '暫', ARRAY['ザン']::text[], ARRAY['tạm']::text[], ARRAY['tạm thời']::text[], 'Xe cân (斬) vào ban ngày (日) là điều tạm thời'),
  ('9ef282dd-a04b-5b3a-9bb8-a28364dd4ed0'::uuid, '施', ARRAY['シ']::text[], ARRAY['thi']::text[], ARRAY['thực thi']::text[], 'Phương (方) nằm (亠) dưới đất (也) tha phương khắp nơi vì thực thi nhiệm vụ'),
  ('f65811cb-210a-581c-aa99-989cb9fa137f'::uuid, '祉', ARRAY['シ']::text[], ARRAY['chỉ']::text[], ARRAY['phúc lợi']::text[], 'Dừng lại (止) ở thị trấn (礻) sẽ nhận vào phúc lợi'),
  ('a02783fc-85d7-5d8b-be96-214856c23678'::uuid, '諮', ARRAY['シ']::text[], ARRAY['tư']::text[], ARRAY['hỏi, tư vấn']::text[], 'Tiếp theo miệng nói (言) đòi lời tư (咨) vấn'),
  ('979ff53e-0ae4-5dc7-8ad9-ea7f6142e024'::uuid, '侍', ARRAY['ジ']::text[], ARRAY['thị']::text[], ARRAY['người hầu']::text[], 'Người (イ) đứng trong chùa (寺) là thị hầu'),
  ('a57a1c92-4493-56e7-b165-13148f87ea8f'::uuid, '慈', ARRAY['ジ']::text[], ARRAY['từ']::text[], ARRAY['nhân từ, từ bi']::text[], 'Sự nhân từ là thứ huyền (玄) bí của tâm (心)'),
  ('fcef4e10-2d93-55bc-9c97-e8eb259418ae'::uuid, '軸', ARRAY['ジク']::text[], ARRAY['trục']::text[], ARRAY['trục xe']::text[], 'Xe (車) chạy tự do (由) nhờ trục bánh xe'),
  ('d108e3e6-0749-59e6-8c0e-6b8fdc51824c'::uuid, '湿', ARRAY['シツ']::text[], ARRAY['thấp']::text[], ARRAY['ướt']::text[], 'Đứng xếp (並) hàng giữa trời mưa (氵) ẩm thấp'),
  ('6dcfae25-1a97-59cb-b65b-05dfea3f0fd2'::uuid, '疾', ARRAY['シツ']::text[], ARRAY['tật']::text[], ARRAY['bệnh tật']::text[], 'Tên bắn trong nạch (疒) không bệnh cũng thành tật'),
  ('68a83736-d39e-5a6a-acf8-d44c5607ac09'::uuid, '赦', ARRAY['シャ']::text[], ARRAY['xá']::text[], ARRAY['xá tội']::text[], 'Đánh (攵) chảy máu đỏ (赤) để xin xá tội'),
  ('f2e26c54-6cde-5656-bf2b-54e242c7cd22'::uuid, '邪', ARRAY['ジャ']::text[], ARRAY['tà']::text[], ARRAY['yêu tà']::text[], 'Răng (牙) cắn vào mông (阝) chỉ có yêu tà'),
  ('40383658-0fd3-5f3b-9a1f-6a83ed6ea3b5'::uuid, '殊', ARRAY['シュ']::text[], ARRAY['thù']::text[], ARRAY['đặc thù']::text[], 'Ngạt (歹) xấu xa chu (朱) máu đỏ là đặc thù'),
  ('ee62891b-07f4-5ca2-a0a5-4e21df1dffd2'::uuid, '寿', ARRAY['ジュ']::text[], ARRAY['thọ']::text[], ARRAY['tuổi thọ']::text[], 'Phệt (丿) qua 3 (三) lần thốn (寸) thì sẽ sống thọ'),
  ('7ec81e7f-dfdf-5b65-a9a7-88cd87f0fddc'::uuid, '潤', ARRAY['ジュン']::text[], ARRAY['nhuận']::text[], ARRAY['lợi nhuận']::text[], 'Ông vua đứng dưới cổng (閏) bán nước (氵) tạo ra lợi nhuận'),
  ('cbfc61f5-bf72-50dd-82b9-6da4c4641ef7'::uuid, '遵', ARRAY['ジュン']::text[], ARRAY['tuân']::text[], ARRAY['tuân theo']::text[], 'Trên đường (辶) tôn trọng (尊), tuân thủ luật lệ'),
  ('a99e1875-bf57-5f0f-ba51-dc9ef8252ff7'::uuid, '徐', ARRAY['ジョ']::text[], ARRAY['từ']::text[], ARRAY['từ từ']::text[], 'Đi (彳) mà dư dư (余) thì đi từ từ'),
  ('5ce06ead-a65f-528c-8b98-0df2cf1e4574'::uuid, '如', ARRAY['ニョ']::text[], ARRAY['như']::text[], ARRAY['ví như, như ý']::text[], 'Phụ nữ (女) có miệng (口) như nhau'),
  ('327c28ba-4fed-5d2b-bd7a-c2e26325509a'::uuid, '晶', ARRAY['ショウ']::text[], ARRAY['tinh']::text[], ARRAY['kết tinh']::text[], '3 mặt trời (日) tụ lại là sự kết tinh'),
  ('1a7bb79b-d78b-57d9-96f9-d66394cca92a'::uuid, '掌', ARRAY['ショウ']::text[], ARRAY['chưởng']::text[], ARRAY['lòng bàn tay']::text[], 'Hòa Thượng (尚) giơ tay (手) tung chưởng'),
  ('99d23c33-f2c4-5e9e-af7a-44a63a6f9e31'::uuid, '鐘', ARRAY['ショウ']::text[], ARRAY['chung']::text[], ARRAY['chuông']::text[], 'Đứng (立) xa cả hải lí (里) góp tiền vàng (金) chung để làm chuông'),
  ('ba580eb4-3369-5325-87d8-c7292c5538a3'::uuid, '焦', ARRAY['ショウ']::text[], ARRAY['tiêu']::text[], ARRAY['tiêu điểm, sốt ruột']::text[], 'Lấy lửa (灬) đốt con chim (隹) cháy làm tiêu điểm'),
  ('eb43722c-9198-5d69-9be1-fedfcb18d528'::uuid, '衝', ARRAY['ショウ']::text[], ARRAY['xung']::text[], ARRAY['xung đột']::text[], 'Hành (行) động nặng (重) sẽ tạo ra sự xung đột'),
  ('88485361-854a-5d0e-a875-12c036bd707f'::uuid, '昇', ARRAY['ショウ']::text[], ARRAY['thăng']::text[], ARRAY['thăng chức']::text[], 'Chấp tay (升) 1 ngày (日) chờ thăng chức'),
  ('fd414972-b0de-59a7-9679-299ee4f6dd79'::uuid, '匠', ARRAY['ショウ']::text[], ARRAY['tượng']::text[], ARRAY['thợ']::text[], 'Cầm riu (斤) đục cái tượng ở trong tủ (匚) đứng là người thợ'),
  ('8e2ede2e-db72-5007-b069-e25241edf442'::uuid, '譲', ARRAY['ジョウ']::text[], ARRAY['nhượng']::text[], ARRAY['nhượng bộ']::text[], 'Nói (言) 6 (六) lời nhượng bộ gộp 2 biểu đất (土) và bộ y phục (衣)'),
  ('c9477895-402f-565e-a184-7fb14463c613'::uuid, '嬢', ARRAY['ジョウ']::text[], ARRAY['nương']::text[], ARRAY['cô gái']::text[], 'Nhưỡng nhường nhịn cô nương'),
  ('9f20de67-fa5a-5590-b0e3-5155b50b77fd'::uuid, '壌', ARRAY['ジョウ']::text[], ARRAY['nhưỡng']::text[], ARRAY['thổ nhưỡng']::text[], 'Nhưỡng mua đất thổ nhưỡng'),
  ('bbcf3d3f-8f0d-5a4e-84b4-57104ce8e46b'::uuid, '醸', ARRAY['ジョウ']::text[], ARRAY['nhưỡng']::text[], ARRAY['lên men']::text[], 'Nhưỡng mua rượu (酒) ủ lên men'),
  ('f88b8df8-aebf-5219-98a0-d2d757138d4d'::uuid, '錠', ARRAY['ジョウ']::text[], ARRAY['đĩnh']::text[], ARRAY['cái khóa']::text[], 'Muốn trữ vàng (金) ổn định (定) thì phải dùng đĩnh (khoá)'),
  ('95f2ec6c-acca-595c-80b8-1a31ebd35e98'::uuid, '冗', ARRAY['ジョウ']::text[], ARRAY['nhũng']::text[], ARRAY['dư thừa']::text[], 'Khăn (冖) mà trải lên ghế (几) chỉ có bọn tham nhũng dư thừa'),
  ('e609582d-adb2-5e41-b71e-aa7316714714'::uuid, '嘱', ARRAY['ショク']::text[], ARRAY['chúc']::text[], ARRAY['giao phó']::text[], 'Cái miệng (口) phụ thuộc (属) vào lời chúc để giao phó'),
  ('da3a281c-5037-5ced-b2c5-ed029aaa259e'::uuid, '辱', ARRAY['ジョク']::text[], ARRAY['nhục']::text[], ARRAY['lăng nhục']::text[], 'Thần (辰) mà bị thốn (寸) là sự lăng nhục')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ───────────────────────────────────────────────
-- Kanji — Trang 25-28 (80 ô lưới, kanji 481-560; 1 ô trùng ký tự: 蓄 súc/tích lũy đã có ở Trang 11, đã bỏ qua)
-- ───────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('ce591b16-5cbd-5b6c-85a2-514fc4335be4'::uuid, '審', ARRAY['シン']::text[], ARRAY['thẩm']::text[], ARRAY['thẩm phán']::text[], 'Trong nhà (宀) có phiên (番) toà phúc thẩm'),
  ('856f4976-0479-5cd7-a6ed-ebff8e8eaadf'::uuid, '伸', ARRAY['シン']::text[], ARRAY['thân']::text[], ARRAY['căng ra, duỗi ra']::text[], 'Thân (申) người (イ) duỗi thẳng'),
  ('3fdbec24-2ba5-57f9-98f8-d25d5aa8d556'::uuid, '辛', ARRAY['シン']::text[], ARRAY['tân']::text[], ARRAY['cay']::text[], 'Mười (十) lần đứng (立) cay đắng'),
  ('e84a3a4d-b40e-51f7-8e6a-8517d86a207f'::uuid, '粋', ARRAY['スイ']::text[], ARRAY['túy']::text[], ARRAY['tinh túy']::text[], 'Tinh túy của 9, 10 (卆) hạt gạo (米)'),
  ('96f2b7e1-8bdf-586a-9fe6-3ae9b0b3dca1'::uuid, '酔', ARRAY['スイ']::text[], ARRAY['túy']::text[], ARRAY['say']::text[], '9,10 (卆) chén rượu (酉) thì say'),
  ('518ea908-7675-5ee2-bf4b-56c6675e3a0a'::uuid, '炊', ARRAY['スイ']::text[], ARRAY['xúy']::text[], ARRAY['đun, nấu']::text[], 'Thiếu (欠) lửa (火) nên xúy không thể nấu cơm'),
  ('0f872ef1-539f-516a-bca1-e0139d3e2754'::uuid, '遂', ARRAY['スイ']::text[], ARRAY['toại']::text[], ARRAY['toại nguyện']::text[], 'Con lợn (豕) chạy trên đường (辶) một cách toại nguyện'),
  ('23bf7c19-a1d9-5060-9328-892cf3511aea'::uuid, '衰', ARRAY['スイ']::text[], ARRAY['suy']::text[], ARRAY['suy nhược']::text[], 'Mắc covid nên suy yếu phải đội mũ đeo khẩu trang và mặc quần áo kín mít'),
  ('c68f56ef-09a0-5b4c-be2b-62ca0c8d4663'::uuid, '穂', ARRAY['スイ']::text[], ARRAY['tuệ']::text[], ARRAY['bông lúa']::text[], 'Bông lúa (禾) là ân huệ (惠) mà trí tuệ con người tạo ra'),
  ('d321c004-a351-56dc-9439-beb36fcab26f'::uuid, '随', ARRAY['ズイ']::text[], ARRAY['tùy']::text[], ARRAY['tùy tùng']::text[], 'Thằng hữu (有) đang trên đường (辶) đến vùng đất (阝) đó làm tùy tùng'),
  ('75943a1a-ea80-5f04-acbf-7e11b4ff40bf'::uuid, '髄', ARRAY['ズイ']::text[], ARRAY['tủy']::text[], ARRAY['xương tủy']::text[], 'Thằng cốt (骨) đi trên đường (辶) tìm thằng hữu (有) để hỏi về xương tủy'),
  ('90801548-51e6-5797-8982-6805ef716e29'::uuid, '牲', ARRAY['セイ']::text[], ARRAY['sinh']::text[], ARRAY['hi sinh']::text[], 'Con bò (牛) chưa sinh (生) ra đã hi sinh'),
  ('c74f0c2a-a452-5361-acd3-da0da8832c5e'::uuid, '婿', ARRAY['セイ']::text[], ARRAY['tế']::text[], ARRAY['chú rể']::text[], 'Phụ nữ (女) chân (疋) bước vào đêm trăng (月) là vật tế cho chú rể'),
  ('82f07c4f-3c2c-503d-bd0d-a35f71bf7271'::uuid, '請', ARRAY['セイ']::text[], ARRAY['thỉnh']::text[], ARRAY['thỉnh cầu']::text[], 'Thanh (青) nói (言) lời thỉnh cầu'),
  ('c3b9e118-ca8c-58af-82b6-cf41918fb9a1'::uuid, '隻', ARRAY['セキ']::text[], ARRAY['chích']::text[], ARRAY['đơn vị đếm tàu']::text[], 'Một chú chim (隹) chích đang đứng dạng chân (又)'),
  ('4c619442-5011-5872-9fce-abd06d25dbd5'::uuid, '惜', ARRAY['セキ']::text[], ARRAY['tích']::text[], ARRAY['nuối tiếc']::text[], 'Trái tim (心) khi nhớ về chuyện ngày xưa (昔) thật tiếc nuối'),
  ('3db4baa0-12d1-5d8e-a4d3-0ca0bec64c98'::uuid, '措', ARRAY['ソ']::text[], ARRAY['thố']::text[], ARRAY['trừ ra']::text[], 'Lấy tay (扌) gạt bỏ ra những thứ ngày xưa (昔)'),
  ('38a257c8-cde5-5ea1-bc2e-f8eca0248321'::uuid, '斥', ARRAY['セキ']::text[], ARRAY['xích']::text[], ARRAY['đuổi, bài xích']::text[], 'Bài trừ ông chủ (丶) cầm búa (斤)'),
  ('accdf9a6-32ed-57e1-b205-f33ebd5d7369'::uuid, '籍', ARRAY['セキ']::text[], ARRAY['tịch']::text[], ARRAY['quốc tịch']::text[], 'Ngày xưa (昔) quốc tịch được ghi vào 3 (三) cái cây (木) trúc (竹)'),
  ('fcc6c9c3-6d20-56dd-9d87-5e643e7fac4b'::uuid, '摂', ARRAY['セツ']::text[], ARRAY['nhiếp']::text[], ARRAY['nhiếp chính']::text[], 'Tay (扌) và tai (耳) chụm về một chỗ là nhà nhiếp chính, nhiếp ảnh gia'),
  ('f8c456d3-f1cd-5a44-83ab-30de98d7c741'::uuid, '潜', ARRAY['セン']::text[], ARRAY['tiềm']::text[], ARRAY['tiềm ẩn']::text[], '2 ông chồng (夫) đứng cùng nhau dưới nước (氵) cả ngày (日) tiềm ẩn nhiều nguy cơ'),
  ('7c2d32d6-734c-5ab0-be9b-e244626ec691'::uuid, '繕', ARRAY['ゼン']::text[], ARRAY['thiện']::text[], ARRAY['sửa, chữa']::text[], 'Muốn hoàn thiện (善) sợi tơ (糸) cần phải sửa chữa'),
  ('5d03bbf1-61f6-5f03-b8f5-a929b440e9d9'::uuid, '双', ARRAY['ソウ']::text[], ARRAY['song']::text[], ARRAY['song phương']::text[], 'Lại (又) là 2 đường thẳng song song'),
  ('93e92967-9298-5d1d-899a-55df310df450'::uuid, '阻', ARRAY['ソ']::text[], ARRAY['trở']::text[], ARRAY['cản trở']::text[], 'Vùng đất (阝) cản trở tầm mắt (且)'),
  ('2d98d71b-e77b-5ee1-ac49-5a4828ba5235'::uuid, '粗', ARRAY['ソ']::text[], ARRAY['thô']::text[], ARRAY['thô thiển']::text[], 'Hạt gạo (米) to như mắt (且) nhìn hơi thô'),
  ('9187753d-051a-5117-b6b8-768a7b67b43b'::uuid, '礎', ARRAY['ソ']::text[], ARRAY['sở']::text[], ARRAY['cơ sở']::text[], 'Bước chân (疋) vào rừng (林) lấy đá (石) tảng về xây dựng cơ sở'),
  ('82a2d57f-fb86-5ac6-a26f-7d4b40caaf4b'::uuid, '桑', ARRAY['ソウ']::text[], ARRAY['tang']::text[], ARRAY['cây dâu']::text[], 'Thấy 3 thằng hựu (又) trên cây (木) dâu là có đám tang'),
  ('83850d35-738d-5b62-9ad9-3768e68f67d7'::uuid, '葬', ARRAY['ソウ']::text[], ARRAY['táng']::text[], ARRAY['an táng']::text[], 'Cô thảo (艹) chấp tay (廾) khi gặp người đã chết (死) để an táng'),
  ('4bb070aa-492c-5667-b879-6504cbc1d57d'::uuid, '掃', ARRAY['ソウ']::text[], ARRAY['tảo']::text[], ARRAY['quét dọn']::text[], 'Tay (扌) cầm triều (帚) tản tảo quét dọn'),
  ('55aa1252-7c63-55ed-9001-7067c59ccb28'::uuid, '遭', ARRAY['ソウ']::text[], ARRAY['tao']::text[], ARRAY['bắt gặp']::text[], 'Cô thảo (艹) rẽ vào khúc (曲) của ban ngày (日) trên đường (辶) rồi bắt gặp Tao, Tào Tháo'),
  ('32c3dd5e-62ea-5282-8eae-70877a64ae11'::uuid, '促', ARRAY['ソク']::text[], ARRAY['xúc']::text[], ARRAY['xúc tiến']::text[], 'Người đứng (イ) đưa chân (足) dài ra xúc tiến'),
  ('dc7331cd-8af7-5999-83ad-7bc3b3c26e8f'::uuid, '賊', ARRAY['ゾク']::text[], ARRAY['tặc']::text[], ARRAY['côn đồ, hung ác']::text[], 'Côn đồ dùng 10 vũ khí (戎) để cướp bảo bối (貝)'),
  ('e0bf879b-d6c1-508a-9f59-62c183c39739'::uuid, '逮', ARRAY['タイ']::text[], ARRAY['đãi']::text[], ARRAY['đuổi, bắt']::text[], 'Truy đuổi (辶) kẻ đãi (隶) vàng'),
  ('af10ec53-b315-55a1-9431-7e57d2ad1ffa'::uuid, '胎', ARRAY['タイ']::text[], ARRAY['thai']::text[], ARRAY['phôi thai']::text[], 'Nghe đài (台) báo chị nguyệt (月) mang thai'),
  ('7580c4b8-72c0-5a20-8377-2b41c4bcf0a0'::uuid, '怠', ARRAY['タイ']::text[], ARRAY['đãi']::text[], ARRAY['lười']::text[], 'Đài (台) lười biếng chỉ để tâm (心) đến cái mồm của mình'),
  ('e6ff83a1-018c-57f1-8cd9-a8a3afe36781'::uuid, '滞', ARRAY['タイ']::text[], ARRAY['trệ']::text[], ARRAY['đình trệ']::text[], 'Thủy (氵) vào rừng nhiệt đới (帯) để đình trệ'),
  ('65812920-f7ed-58aa-afc9-b0efb07b00f6'::uuid, '袋', ARRAY['タイ']::text[], ARRAY['đại']::text[], ARRAY['túi']::text[], 'Y (衣) phục thời đại (代) này nhìn cứ như cái túi'),
  ('8a162882-ee7c-5b78-b871-3ab8debe8e36'::uuid, '滝', ARRAY['ロウ']::text[], ARRAY['lang']::text[], ARRAY['thác nước']::text[], 'Con rồng (竜) lang thang trên thác nước (氵)'),
  ('ad5677ff-d4c6-5720-9284-7393c5a4ff1b'::uuid, '託', ARRAY['タク']::text[], ARRAY['thác']::text[], ARRAY['ủy thác']::text[], 'Nói (言) 17 (乇) lời đó là ủy thác cho người khác'),
  ('0453d3f8-82c6-5eb5-95d5-c2119fdcd6e0'::uuid, '卓', ARRAY['タク']::text[], ARRAY['trác']::text[], ARRAY['cái bàn']::text[], 'Bốc (卜) quẻ sớm (早) để được lấy cái bàn từ ông trác'),
  ('558938cd-c9b1-52e8-a3d1-661ce2062cc0'::uuid, '択', ARRAY['タク']::text[], ARRAY['trạch']::text[], ARRAY['lựa chọn']::text[], 'Tay (扌) cầm xích (尺) đi tuyển trạch'),
  ('ef47435f-c672-5583-81de-49ea89229ed6'::uuid, '諾', ARRAY['ダク']::text[], ARRAY['nặc']::text[], ARRAY['đồng ý']::text[], 'Nói (言) cho người trẻ (若) phải nàng nặc đồng ý'),
  ('a5109cbc-1a21-5fe5-9766-fd7c8453583c'::uuid, '奪', ARRAY['ダツ']::text[], ARRAY['đoạt']::text[], ARRAY['cướp đoạt']::text[], 'Lúc chiếm đoạt được con chim (隹) lớn (大) cảm giác hơi thốn (寸)'),
  ('4b1e49c2-ead1-5438-829c-10a5ca3aa711'::uuid, '胆', ARRAY['タン']::text[], ARRAY['đảm']::text[], ARRAY['can đảm']::text[], '1 ngày (日) ở trên mặt trăng (月), thật can đảm'),
  ('b9f6e76f-f3f8-55a1-b545-edf90de6ece1'::uuid, '鍛', ARRAY['タン']::text[], ARRAY['đoán']::text[], ARRAY['rèn luyện']::text[], 'Luyện kim (金) thành từng đoạn (段)'),
  ('f5881059-cd69-5de0-b19b-b3008f481e46'::uuid, '壇', ARRAY['ダン']::text[], ARRAY['đàn']::text[], ARRAY['bệ, bục']::text[], 'Đàn (亶) lập đàn bằng đất (土)'),
  ('20266ca6-d384-5228-aeb8-9fbe9741c289'::uuid, '稚', ARRAY['チ']::text[], ARRAY['trĩ']::text[], ARRAY['thơ bé']::text[], 'Chim (隹) ăn cây lúa (禾) nên bị trĩ từ thời thơ bé'),
  ('002ff1ad-f80c-5f0f-8f96-f1d4690c881d'::uuid, '畜', ARRAY['チク']::text[], ARRAY['súc']::text[], ARRAY['gia súc']::text[], 'Những đốm đen (玄) ngoài đồng (田) là xúc vật'),
  ('13d244e7-553a-5fd2-a2e7-e9e959254313'::uuid, '窒', ARRAY['チツ']::text[], ARRAY['trất']::text[], ARRAY['ngạt thở']::text[], 'Chôn chí (至) vào huyệt (穴) thì ngạt thở'),
  ('bec03132-7034-5cd5-bb54-6e37bb957179'::uuid, '駐', ARRAY['チュウ']::text[], ARRAY['trú']::text[], ARRAY['lưu lại']::text[], 'Con ngựa (馬) cư trú bên ông chủ (主)'),
  ('09f7ad2d-3889-543d-9ce4-45e7ef933dac'::uuid, '抽', ARRAY['チュウ']::text[], ARRAY['trừu']::text[], ARRAY['trừu tượng']::text[], 'Tay (扌) quay tự do (由) rất trừu tượng'),
  ('28cb42b9-f469-5e6f-8e02-00d9a209db57'::uuid, '鋳', ARRAY['チュウ']::text[], ARRAY['chú']::text[], ARRAY['đúc']::text[], 'Chú thọ (寿) tuổi đã cao nhưng vẫn làm đúc kim (金) loại'),
  ('fc9dad63-7d45-54d0-b274-32e985bd1b23'::uuid, '彫', ARRAY['チョウ']::text[], ARRAY['điêu']::text[], ARRAY['điêu khắc']::text[], 'Điêu khắc Chu (周) chỉ nhược có mái tóc dài (彡)'),
  ('73fe6199-0c4b-5349-b7f1-93b1cf40f091'::uuid, '超', ARRAY['チョウ']::text[], ARRAY['siêu']::text[], ARRAY['siêu phàm']::text[], 'Chân chạy (走), miệng ngậm dao (刀) Triệu (召) thật là siêu'),
  ('c6b2e792-a3bd-57c1-85e1-4cdf8b9c667d'::uuid, '聴', ARRAY['チョウ']::text[], ARRAY['thính']::text[], ARRAY['thính giác']::text[], 'Tai (耳) muốn nghe thính phải tập trung bằng cả trái tim (心) và 10 (十) con mắt (罒)'),
  ('df87d4d6-90ce-59b8-8984-c6b8222061b5'::uuid, '陳', ARRAY['チン']::text[], ARRAY['trần']::text[], ARRAY['Trần Liệt']::text[], 'Nhà Trần tuyên bố lập nước ở ấp (阝) phía đông (東)'),
  ('6a1f5f29-3502-5ef0-9656-423cc793b40c'::uuid, '鎮', ARRAY['チン']::text[], ARRAY['trấn']::text[], ARRAY['trấn áp']::text[], 'Chân (真) chính thì cứ dùng tiền vàng (金) mà trấn áp'),
  ('39e5a466-e287-541a-aece-fbb0cdb45222'::uuid, '墜', ARRAY['ツイ']::text[], ARRAY['trụy']::text[], ARRAY['trụy lạc']::text[], 'Vùng đất (土) chiếu fim bạn heo (豕) là vùng đất (阝) trụy lạc'),
  ('0f8d6a47-7a37-5ba9-8c78-cf18c4173d58'::uuid, '訂', ARRAY['テイ']::text[], ARRAY['đính']::text[], ARRAY['đính chính']::text[], 'Đinh (丁) nói (言) lời đính chính'),
  ('3e94f09d-2cca-50dd-a6cb-ec35e4fb55a3'::uuid, '帝', ARRAY['テイ']::text[], ARRAY['đế']::text[], ARRAY['thượng đế']::text[], 'Đứng (立) bên trên cân (巾) tất cả là Hoàng Đế'),
  ('cefd5631-bf8a-55c8-b8fe-0b31a3d580d0'::uuid, '締', ARRAY['テイ']::text[], ARRAY['đế']::text[], ARRAY['ràng buộc']::text[], 'Lấy dây (糸) buộc hoàng đế (帝) lại'),
  ('ca3488c5-566e-510e-bbb8-ea0dbf5a5d8a'::uuid, '哲', ARRAY['テツ']::text[], ARRAY['triết']::text[], ARRAY['triết học']::text[], 'Triết (折) mà có miệng (口) là triết học'),
  ('95be4c3c-56f7-5f94-b051-b5c733119b6a'::uuid, '誓', ARRAY['セイ']::text[], ARRAY['thệ']::text[], ARRAY['lời thề']::text[], 'Triết (折) nói (言) lời thề nguyện'),
  ('fad15703-3814-5643-a50c-8ad57b8e92b2'::uuid, '斗', ARRAY['ト']::text[], ARRAY['đẩu']::text[], ARRAY['cái đấu']::text[], 'Bộ thủ nè'),
  ('cecd0a1a-6c4e-59c5-93c0-55b04bbc4d5b'::uuid, '塗', ARRAY['ト']::text[], ARRAY['đồ']::text[], ARRAY['sơn']::text[], 'Vùng đất (土) mà dư (余) nước (氵) gọi là đồ sơn'),
  ('9090daaf-9608-5ae6-a029-f0a4b445d609'::uuid, '陶', ARRAY['トウ']::text[], ARRAY['đào']::text[], ARRAY['đồ sành sứ']::text[], 'Bao (勹) cái lon (缶) lại bằng đất ở dưới ấp (阝) để làm đồ sành sứ'),
  ('081a91db-d5e0-559c-8980-4462227af89d'::uuid, '凍', ARRAY['トウ']::text[], ARRAY['đông']::text[], ARRAY['đông lạnh']::text[], 'Nước (冫) đông (東) đóng băng lại'),
  ('efd03d10-7792-547f-970c-3ff0980cd909'::uuid, '痘', ARRAY['トウ']::text[], ARRAY['đậu']::text[], ARRAY['đậu mùa']::text[], 'Đậu (豆) mà bị bệnh (疒) là bệnh thủy đậu'),
  ('08d849f2-0051-5cd4-ba9b-b68af3c91493'::uuid, '匿', ARRAY['トク']::text[], ARRAY['nặc']::text[], ARRAY['nặc danh']::text[], 'Người trẻ (若) nằng nặc đòi chơi chỗ chốn vào tủ (匚)'),
  ('b916fb26-dc75-58b9-b4c3-cfe48754e491'::uuid, '篤', ARRAY['トク']::text[], ARRAY['đốc']::text[], ARRAY['đứng đắn, tận tâm']::text[], 'Lấy cây trúc (竹) đánh vào mông con ngựa (馬) để đốc thúc cho tận tâm'),
  ('5e501808-f435-53fc-915b-a38d8ab0c6e1'::uuid, '豚', ARRAY['トン']::text[], ARRAY['đồn']::text[], ARRAY['con lợn']::text[], 'Nghe đồn trên mặt trăng (月) nuôi được lợn (豕)'),
  ('dddef1f4-448b-5e60-b644-8ba7f827903d'::uuid, '尿', ARRAY['ニョウ']::text[], ARRAY['niệu']::text[], ARRAY['nước tiểu']::text[], 'Con ma (尸) sợ nước (水) tiểu'),
  ('40b333fa-0b5b-5892-bf35-635f3b88c17a'::uuid, '粘', ARRAY['ネン']::text[], ARRAY['niêm']::text[], ARRAY['dính']::text[], 'Dính hạt cơm (米) trên miệng (占)'),
  ('1de5e116-8167-56b5-8a38-3ed41cea8a31'::uuid, '婆', ARRAY['バ']::text[], ARRAY['bà']::text[], ARRAY['bà già']::text[], 'Bà là người phụ nữ (女) đẻ ra Ba (波)'),
  ('e4370ccd-cfe4-5797-90da-435d82a7db53'::uuid, '排', ARRAY['ハイ']::text[], ARRAY['bài']::text[], ARRAY['bài trừ']::text[], 'Lấy tay (扌) bài trừ điều phi (非) thường'),
  ('96d35f66-6596-5e86-ac33-2d78b1066a97'::uuid, '陪', ARRAY['バイ']::text[], ARRAY['bồi']::text[], ARRAY['bồi thẩm đoàn']::text[], 'Bộ (部) trưởng mà đổi (阝) lên trước là bồi thẩm đoàn'),
  ('f6036c03-1456-5343-99fe-d91e02edb2ed'::uuid, '縛', ARRAY['バク']::text[], ARRAY['phược']::text[], ARRAY['buộc']::text[], 'Sợi dây (糸) chuyên (専) môn dùng để buộc đi phượt'),
  ('6d04fdcd-82f8-5a24-aece-bfff09691072'::uuid, '伐', ARRAY['バツ']::text[], ARRAY['phạt']::text[], ARRAY['đánh']::text[], 'Người (イ) qua (戈) đây thì sẽ bị phạt đánh'),
  ('e9aae1b7-8951-589b-8714-0b1fe0dc95e3'::uuid, '伴', ARRAY['ハン']::text[], ARRAY['bạn']::text[], ARRAY['bạn, tiếp']::text[], 'Bạn thì dù chỉ còn 1 nửa (半) người (イ) cũng vẫn là bạn')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ───────────────────────────────────────────────
-- Kanji — Trang 29-32 (75 ô lưới, kanji 561-635; Trang 32 chỉ có 3 hàng (15 ô) thay vì 4 hàng
-- vì hàng cuối trang là ô trống. 3 ô trùng ký tự đã có trước đó trong chính nguồn PDF này,
-- đã bỏ qua: 描 (miêu tả, đã có ở Trang 14), 謡 (ca dao, đã có ở Trang 17), 郎 (con trai, đã
-- có ở Trang 18)
-- ───────────────────────────────────────────────
insert into kanji (id, character, onyomi, han_viet, meaning_vi, mnemonic, level_id)
select v.id, v.character, v.onyomi, v.han_viet, v.meaning_vi, v.mnemonic,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('b35dabca-8d1a-58ba-bca5-49fa7aa6d087'::uuid, '畔', ARRAY['ハン']::text[], ARRAY['bạn']::text[], ARRAY['bờ ruộng']::text[], 'Bán 1 nửa (半) bờ ruộng (田) cho bạn'),
  ('9b3019ac-8b3b-5ccd-a7db-b8217331e656'::uuid, '藩', ARRAY['ハン']::text[], ARRAY['phiên']::text[], ARRAY['đất phong, lãnh chúa']::text[], 'Đến phiên (番) lãnh chúa tưới nước (氵) cho cỏ (艹) rồi'),
  ('a862315d-a0a5-5b8b-bdb5-98b812c5c43f'::uuid, '蛮', ARRAY['バン']::text[], ARRAY['man']::text[], ARRAY['man rợ']::text[], 'Con sâu (虫) màu đỏ (亦) nhìn rất man rợ'),
  ('3bc08157-0669-5016-a0a4-63f3884f37a6'::uuid, '泌', ARRAY['ヒ']::text[], ARRAY['bí']::text[], ARRAY['tiết ra']::text[], 'Nước (氵) bí thì tất (必) yếu sẽ tiết ra đường tiết liệu'),
  ('50637cae-b05a-5eb7-9f17-2827c92422cb'::uuid, '卑', ARRAY['ヒ']::text[], ARRAY['ti']::text[], ARRAY['thấp hèn']::text[], 'Làm chủ 4 cái ruộng mà vẫn tự ti'),
  ('5708c50e-2c80-5afe-8300-3a5cb4dda844'::uuid, '碑', ARRAY['ヒ']::text[], ARRAY['bi']::text[], ARRAY['bia mộ']::text[], 'Đá (石) thấp cấp (卑) thì làm bia đá'),
  ('6880a631-2342-5cb3-abfc-f918311b7cec'::uuid, '姫', ARRAY['キ']::text[], ARRAY['cơ']::text[], ARRAY['công chúa']::text[], 'Con gái (女) của đại thần (臣) là công chúa'),
  ('4e698caf-10fa-5607-89e8-041d818068d3'::uuid, '漂', ARRAY['ヒョウ']::text[], ARRAY['phiêu']::text[], ARRAY['nổi, phiêu lưu']::text[], 'Ngân phiêu trôi phiêu (票) du trên nước (票)'),
  ('ded807bb-1d31-51b2-811b-c46e2e2048ea'::uuid, '苗', ARRAY['ビョウ']::text[], ARRAY['miêu']::text[], ARRAY['cây non']::text[], 'Lúa non ngoài ruộng (田) miêu tả bằng hoa cỏ (艹)'),
  ('e7764fb3-47f6-5122-a54b-b582859cfe2c'::uuid, '猫', ARRAY['ビョウ']::text[], ARRAY['miêu']::text[], ARRAY['con mèo']::text[], 'Con chó (犭) xổ vào bụi cỏ (艹) ngoài ruộng (田) để bắt con mèo (猫) hoang'),
  ('dec92cf2-70fb-53f6-821f-b6d4d0d5cd52'::uuid, '赴', ARRAY['フ']::text[], ARRAY['phó']::text[], ARRAY['tới']::text[], 'Chạy (走) tới tô (卜) để nhận chức'),
  ('d04ccd7c-6baf-5e5c-9768-f9dfd1459df3'::uuid, '符', ARRAY['フ']::text[], ARRAY['phù']::text[], ARRAY['phù hiệu']::text[], 'Trúc (竹) được giao phó (付) việc phát phù hiệu'),
  ('098c8c6a-c7d9-5ffd-94af-589a6443a773'::uuid, '封', ARRAY['フウ']::text[], ARRAY['phong']::text[], ARRAY['phong thư']::text[], '2 vùng đất (圭) bị niêm phong thật thốn (寸)'),
  ('3125eb72-90b0-530d-ab55-616023f6404a'::uuid, '伏', ARRAY['フク']::text[], ARRAY['phục']::text[], ARRAY['phục kích']::text[], 'Người (イ) dắt chó (犬) đi phục kích'),
  ('a20315e0-a7f7-5e96-abe7-e54a0e70a83e'::uuid, '覆', ARRAY['フク']::text[], ARRAY['phúc']::text[], ARRAY['bao phủ']::text[], 'Phúc (復) mà có cái che lên trên là bao phủ'),
  ('f3158109-b88f-5286-b75d-b2c08db25840'::uuid, '墳', ARRAY['フン']::text[], ARRAY['phần']::text[], ARRAY['mộ phần']::text[], 'Vùng đất (土) mà chôn 30 con số (賁) thì là ngôi mộ'),
  ('9cdd1c07-f462-50c1-a1dc-8530c532e85a'::uuid, '紛', ARRAY['フン']::text[], ARRAY['phân']::text[], ARRAY['lộn xộn']::text[], 'Phân (分) sợi tơ (糸) bị lộn xộn ra'),
  ('019b56dd-ae6c-5140-9744-82f2dbeeabda'::uuid, '癖', ARRAY['ヘキ']::text[], ARRAY['phích']::text[], ARRAY['thói hư, tật xấu']::text[], 'Thói hư của con ma là thích ăn cay (辟) nên bị bệnh (疒) tật'),
  ('1a313794-e134-5b3a-89f3-203c85def6fe'::uuid, '募', ARRAY['ボ']::text[], ARRAY['mộ']::text[], ARRAY['chiêu mộ']::text[], 'Mộ (莫) mà nhiều lực (力) thì sẽ chiêu mộ được người khác'),
  ('341e7493-63ec-5a58-a699-5879162e9a83'::uuid, '慕', ARRAY['ボ']::text[], ARRAY['mộ']::text[], ARRAY['hâm mộ']::text[], 'Mộ (莫) mà có tâm (心) là hâm mộ'),
  ('2c8aaf54-1951-54d7-9764-110505207b2c'::uuid, '墓', ARRAY['ボ']::text[], ARRAY['mộ']::text[], ARRAY['mộ phần']::text[], 'Mộ (墓) thổ (土) ngôi mộ'),
  ('5cc1026c-b2df-5f6a-b6b5-7c2f07e8d570'::uuid, '暮', ARRAY['ボ']::text[], ARRAY['mộ']::text[], ARRAY['trời tối']::text[], 'Mộ (暮) có mặt trời (日) là đang sống'),
  ('c87cb8f1-0a1a-5eac-93ac-5b04c579d792'::uuid, '模', ARRAY['ボ']::text[], ARRAY['mô']::text[], ARRAY['mô hình']::text[], 'Mô hình cái mộ (莫) được làm bằng cây (木)'),
  ('8713aa2b-d4a9-520b-a48f-7239a893c70d'::uuid, '膜', ARRAY['マク']::text[], ARRAY['mô']::text[], ARRAY['màng']::text[], 'Mộ (莫) mà có thịt (月) là mô màng'),
  ('3a3384e2-66a2-5d09-b062-ecd6fae020d2'::uuid, '簿', ARRAY['ボ']::text[], ARRAY['bộ']::text[], ARRAY['danh sách']::text[], 'Bút tre (竹) mực nước (氵) chuyên (専) để ghi chép bộ (簿) sổ sách'),
  ('9e1b18c4-3942-57e3-8477-ab822157a1ec'::uuid, '崩', ARRAY['ホウ']::text[], ARRAY['băng']::text[], ARRAY['phá hủy, băng hà']::text[], 'Mất 2 tháng (朋) để phá núi (山) tạo thành đường băng'),
  ('7028f7ea-57a1-54af-9716-aab8a0c910ff'::uuid, '芳', ARRAY['ホウ']::text[], ARRAY['phương']::text[], ARRAY['cỏ thơm']::text[], 'Phương (方) mà có thảo (艹) là phương thảo'),
  ('fe6034ec-8903-5140-85d2-df0535476e4a'::uuid, '胞', ARRAY['ホウ']::text[], ARRAY['bào']::text[], ARRAY['tế bào']::text[], 'Bao (包) lấy thịt (月) đó là các tế bào'),
  ('fd56bc96-f39f-5ec1-8c04-2d3de4cc68b1'::uuid, '縫', ARRAY['ホウ']::text[], ARRAY['phùng']::text[], ARRAY['khâu vá']::text[], 'Đường (辶) chỉ (糸) khâu đi khâu lại (夂) may 3 (三) tấm vải thành 1 (丨) áo'),
  ('4cf8e3ff-5711-55f1-8392-6970ca2e0dbe'::uuid, '倣', ARRAY['ホウ']::text[], ARRAY['phỏng']::text[], ARRAY['mô phỏng']::text[], 'Mô phỏng lại người đứng (イ) phóng (放)'),
  ('7ee2f81f-23ce-5668-9f56-162e9001adff'::uuid, '妨', ARRAY['ボウ']::text[], ARRAY['phương']::text[], ARRAY['cản trở']::text[], 'Người phụ nữ (女) tên phương (方) cản trở quá'),
  ('32638adc-b5f2-5fd4-9e36-3f96c6287c77'::uuid, '房', ARRAY['ボウ']::text[], ARRAY['phòng']::text[], ARRAY['buồng']::text[], 'Phương (方) ở trong cửa (戸) buồng là phòng'),
  ('d284b301-f0be-535a-89c9-eb2a4b1d8d29'::uuid, '飽', ARRAY['ホウ']::text[], ARRAY['bão']::text[], ARRAY['no bụng']::text[], 'Ăn (飠) bao (包) lại hết thì no bụng'),
  ('6e1bbdc6-8280-5996-9d84-3b146fedbafd'::uuid, '奉', ARRAY['ホウ']::text[], ARRAY['phụng']::text[], ARRAY['cung phụng']::text[], '3 người tặng bò (牛) chặt sừng rồi để cung phụng'),
  ('bcb04e4a-4700-5751-9ad2-ef2cad2b1017'::uuid, '乏', ARRAY['ボウ']::text[], ARRAY['phạp']::text[], ARRAY['khốn cùng']::text[], 'Khốn cùng thở dài phập phạp'),
  ('9b12e87b-1863-5708-bf2e-297e13f4a13c'::uuid, '某', ARRAY['ボウ']::text[], ARRAY['mỗ']::text[], ARRAY['anh ta']::text[], 'Anh ta nói cây (木) chanh này quả ngọt như cam (甘)'),
  ('de159f55-f4e8-5c9c-a46c-f10c0239d567'::uuid, '謀', ARRAY['ボウ']::text[], ARRAY['mưu']::text[], ARRAY['âm mưu']::text[], 'Lời nói (言) của anh ta (某) ẩn chứa âm mưu'),
  ('a5964507-2259-5413-a7d8-25244c1595ef'::uuid, '膨', ARRAY['ボウ']::text[], ARRAY['bành']::text[], ARRAY['bành trướng']::text[], 'Dưới ánh trăng (月) hạt đậu (豆) mọc rễ (彡) dài bành trướng ra xung quanh'),
  ('917b309d-8f8e-52d9-b562-640b63bb3a9d'::uuid, '墨', ARRAY['ボク']::text[], ARRAY['mặc']::text[], ARRAY['mực đen']::text[], 'Ngày xưa đất (土) đen (黒) dùng làm mực'),
  ('0aae3b2f-d3db-5b46-abd2-d73d09b8ed96'::uuid, '没', ARRAY['ボツ']::text[], ARRAY['một']::text[], ARRAY['chìm, chết']::text[], 'Chém một cái bằng vũ khí (殳) chìm chết xuống nước (氵)'),
  ('725c8f60-cf61-5d7f-bee3-d1b8a4fb110d'::uuid, '翻', ARRAY['ホン']::text[], ARRAY['phiên']::text[], ARRAY['phiên dịch']::text[], 'Phiên (番) dịch toàn nói những điều có cánh (羽)'),
  ('44d12bfc-f65e-58ef-b621-3594a9302629'::uuid, '埋', ARRAY['マイ']::text[], ARRAY['mai']::text[], ARRAY['chôn']::text[], 'Lấy đất (土) mai táng ông Lý (里)'),
  ('ee8cc71d-353c-52c1-8d63-2e54080b5ae9'::uuid, '又', ARRAY['ユウ']::text[], ARRAY['hựu']::text[], ARRAY['lại nữa']::text[], 'Bộ thủ nè'),
  ('f342aa2d-c450-56f3-9f9a-44586f4aedfa'::uuid, '滅', ARRAY['メツ']::text[], ARRAY['diệt']::text[], ARRAY['bất diệt']::text[], '1 (一) ngọn lửa (火) đi qua (戈) sườn núi (厂) gặp nước (氵) mà không tắt là bất diệt'),
  ('758634d1-3534-51a7-a187-9e7cba0bffcb'::uuid, '免', ARRAY['メン']::text[], ARRAY['miễn']::text[], ARRAY['miễn giảm']::text[], 'Miễn (勉) mà mất lực (力) thì là miễn giảm'),
  ('9f348891-de73-55a4-a7b3-f5c203b8609d'::uuid, '幽', ARRAY['ユウ']::text[], ARRAY['u']::text[], ARRAY['tối tăm']::text[], 'Yêu tinh (幺) nhìn thấy núi (山) là u sầu rồi'),
  ('b3e702f4-e9f0-5e44-9791-0ea08dd7cf2b'::uuid, '憂', ARRAY['ユウ']::text[], ARRAY['ưu']::text[], ARRAY['ưu tiên']::text[], 'Ưu phiền trăm sự (百) phủ kín (冖) con tim (心) lê bước chân (夂) mệt nhoài'),
  ('c791ba51-1fe3-5726-98bc-672b34688e5b'::uuid, '優', ARRAY['ユウ']::text[], ARRAY['ưu']::text[], ARRAY['ưu tú']::text[], 'Ưu (憂) mà có nhân (イ) là ưu tú'),
  ('e14b044e-a093-5942-8091-d8f92dcbc3b6'::uuid, '誘', ARRAY['ユウ']::text[], ARRAY['dụ']::text[], ARRAY['lời mời']::text[], 'Người ưu tú (秀) nói (言) ra là mời dụ mình'),
  ('b59ecf62-f3fe-53c4-963c-d7a2bb653cb3'::uuid, '擁', ARRAY['ヨウ']::text[], ARRAY['ủng']::text[], ARRAY['ủng hộ']::text[], 'Dơ tay (扌) ủng hộ con chim (隹) non (幺) đầu (亠) đàn'),
  ('0605606b-5e6c-5c26-917d-0d5f7dedc77e'::uuid, '揚', ARRAY['ヨウ']::text[], ARRAY['dương']::text[], ARRAY['tuyên dương']::text[], 'Dương (易) vật tay (扌) thắng nên được tuyên dương'),
  ('d7efdf96-7d44-58fa-88e8-2f827f7a8255'::uuid, '揺', ARRAY['ヨウ']::text[], ARRAY['dao']::text[], ARRAY['dao động']::text[], 'Trào (爫) mà lấy tay (扌) gõ vào can (缶) làm dao động'),
  ('3f418323-9262-5e17-a3f8-b1c5908189d3'::uuid, '抑', ARRAY['ヨク']::text[], ARRAY['ức']::text[], ARRAY['đè nén, ức chế']::text[], 'Ức quá lấy tay (扌) đè nén'),
  ('33111e8f-2ea7-5418-b93e-da11cd04f30a'::uuid, '裸', ARRAY['ラ']::text[], ARRAY['loã']::text[], ARRAY['trần trụi']::text[], 'Kết quả (果) của việc thoát y (ネ) là khỏa thân'),
  ('a84e6eab-1b1b-5531-9bac-a5714b702cca'::uuid, '濫', ARRAY['ラン']::text[], ARRAY['lạm']::text[], ARRAY['tràn lan, lạm dụng']::text[], 'Giám đốc (監督) lạm dụng chức quyền tiêu tiền như nước (氵)'),
  ('5f9d3290-f738-5687-8f10-4dc081d57035'::uuid, '吏', ARRAY['リ']::text[], ARRAY['lại']::text[], ARRAY['quan lại']::text[], 'Trượng phu (丈) có mồm (口) chính là quan lại'),
  ('8efb7fbd-91e5-5465-ab20-f5aac6bfbd3d'::uuid, '隆', ARRAY['リュウ']::text[], ARRAY['long']::text[], ARRAY['hưng thịnh']::text[], 'Vùng đất (阝) phía sau (夊) sinh (生) sống hưng thịnh nhờ long vương'),
  ('79c1e754-3949-54b1-8deb-c5376067d86d'::uuid, '陵', ARRAY['リョウ']::text[], ARRAY['lăng']::text[], ARRAY['lăng tẩm']::text[], 'Vùng đất (阝) có tiên sinh (先) bị truy đuổi (夊) là lăng tẩm'),
  ('d1992ed6-9ddb-5006-b671-686efedd63ab'::uuid, '了', ARRAY['リョウ']::text[], ARRAY['liễu']::text[], ARRAY['sự kết thúc']::text[], 'Dễ rồi nè'),
  ('98606b43-02b4-5a66-87db-6a25e8afe29d'::uuid, '糧', ARRAY['リョウ']::text[], ARRAY['lương']::text[], ARRAY['thực phẩm']::text[], 'Một lượng (量) gạo (米) làm lương thực'),
  ('159a6f4a-6c2e-572c-94e0-533f7702f77a'::uuid, '厘', ARRAY['リン']::text[], ARRAY['li']::text[], ARRAY['nhỏ, một chút']::text[], 'Ông lý (里) xây nhà sườn núi (厂) tính toán chi li'),
  ('282e7528-28b8-5ea9-a282-8382b2c81926'::uuid, '零', ARRAY['レイ']::text[], ARRAY['linh']::text[], ARRAY['số không, âm độ']::text[], 'Trời mưa (雨) lạnh (令) không độ'),
  ('29a61ea6-0919-5050-b40f-9a4c23d9956a'::uuid, '霊', ARRAY['レイ']::text[], ARRAY['linh']::text[], ARRAY['linh hồn']::text[], 'Xếp hàng (並) dưới mưa (雨) là linh hồn'),
  ('1f925f0d-9ebb-54f0-a0b3-5bc34d738243'::uuid, '励', ARRAY['レイ']::text[], ARRAY['lệ']::text[], ARRAY['khích lệ']::text[], 'Lực (力) treo tiền man (万) dưới vách núi (厂) để khích lệ'),
  ('6ac40e08-669d-5b77-bcb7-45b10cb0cd59'::uuid, '裂', ARRAY['レツ']::text[], ARRAY['liệt']::text[], ARRAY['xé ra']::text[], 'Liệt (列) kê những bộ y (衣) phục bị xé rách'),
  ('b9bcdd97-c188-58cf-b86f-920c62a2e679'::uuid, '錬', ARRAY['レン']::text[], ARRAY['luyện']::text[], ARRAY['luyện kim']::text[], 'Luyện kim (金) ở phía đông (東)'),
  ('e6341e66-99f4-5a6e-8e7f-d93dce7dfaca'::uuid, '炉', ARRAY['ロ']::text[], ARRAY['lô']::text[], ARRAY['lò']::text[], 'Cửa (戸) nhét lửa (火) vào là cửa lò'),
  ('8fce8d34-3572-592d-a0ae-a92bdeb57748'::uuid, '漏', ARRAY['ロウ']::text[], ARRAY['lậu']::text[], ARRAY['lỗ thủng, rò rỉ']::text[], 'Mưa (雨) thấm rò rỉ nước (氵) ra bên ngoài thây (尸) ma'),
  ('1945ce90-70dd-5086-b8f7-c2b3760b3f2d'::uuid, '廊', ARRAY['ロウ']::text[], ARRAY['lang']::text[], ARRAY['hành lang']::text[], 'Vùng đất (阝) tốt (良) trong nhà (广) làm hành lang'),
  ('0c8f7215-8898-50aa-99fb-ceff06f13cdc'::uuid, '浪', ARRAY['ロウ']::text[], ARRAY['lãng']::text[], ARRAY['phóng túng, lãng mạn']::text[], 'Thủy (氵) tốt bụng (良) thì có tình yêu lãng mạn'),
  ('b407bcf5-5919-55ad-9527-7bf722203ef2'::uuid, '楼', ARRAY['ロウ']::text[], ARRAY['lâu']::text[], ARRAY['lầu đài']::text[], 'Người phụ nữ (女) đội gạo (米) đứng trước cây (木) cạnh lâu đài'),
  ('40cb3d5d-fe94-5a76-ac1c-6bf121d71437'::uuid, '湾', ARRAY['ワン']::text[], ARRAY['loan']::text[], ARRAY['vịnh']::text[], 'Vùng vịnh nước (氵) đổ do bắn cung (弓) là Đài Loan')
) as v(id, character, onyomi, han_viet, meaning_vi, mnemonic)
on conflict (character) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Lessons — chia theo "ngày học" (không gắn giáo trình), 12 kanji liên tiếp theo đúng thứ tự
-- xuất hiện lần đầu trong PDF (629 kanji phân biệt / 12 = 53 ngày, ngày cuối còn 5 kanji).
-- order_index bắt đầu từ 1001 (range riêng, không đụng lesson ngữ pháp/từ vựng N2 khác).
-- ─────────────────────────────────────────────────────────────
insert into lessons (id, level_id, title, order_index)
values
  ('4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 01', 1001),
  ('e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 02', 1002),
  ('64a42124-706d-5330-ad95-fe78e66768d2'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 03', 1003),
  ('f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 04', 1004),
  ('ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 05', 1005),
  ('ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 06', 1006),
  ('04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 07', 1007),
  ('f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 08', 1008),
  ('44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 09', 1009),
  ('96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 10', 1010),
  ('fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 11', 1011),
  ('9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 12', 1012),
  ('46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 13', 1013),
  ('1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 14', 1014),
  ('4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 15', 1015),
  ('aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 16', 1016),
  ('8c483c74-46db-5160-8017-ae09b2d06543'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 17', 1017),
  ('330ca902-20c2-54de-b516-c35e7b12769b'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 18', 1018),
  ('a70cb663-574e-5c86-906a-51912b3c4975'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 19', 1019),
  ('de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 20', 1020),
  ('6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 21', 1021),
  ('d1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 22', 1022),
  ('d50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 23', 1023),
  ('608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 24', 1024),
  ('811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 25', 1025),
  ('90b5d983-fadc-5c09-8126-a791068ae958'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 26', 1026),
  ('72dfdb13-33b5-558c-9128-513219c06da2'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 27', 1027),
  ('b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 28', 1028),
  ('8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 29', 1029),
  ('dd010918-588d-5dde-a5ce-f21500eab363'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 30', 1030),
  ('49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 31', 1031),
  ('492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 32', 1032),
  ('9387f363-a514-5fdc-af78-7a9557556e50'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 33', 1033),
  ('476d544d-273a-5164-a341-5aad31d582fc'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 34', 1034),
  ('ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 35', 1035),
  ('45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 36', 1036),
  ('d2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 37', 1037),
  ('e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 38', 1038),
  ('d3f6f51b-a956-58a0-9484-750295a8c982'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 39', 1039),
  ('5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 40', 1040),
  ('8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 41', 1041),
  ('b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 42', 1042),
  ('d8020095-08c6-5697-8868-6cddf1935a69'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 43', 1043),
  ('9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 44', 1044),
  ('e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 45', 1045),
  ('3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 46', 1046),
  ('e33437da-692d-5665-889a-4bc801e3040c'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 47', 1047),
  ('697779da-eefb-52f3-9141-64d09a83d283'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 48', 1048),
  ('19791752-752b-5870-8421-f065b61ebb6c'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 49', 1049),
  ('ca193746-023b-5bce-a820-cbab0b467de0'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 50', 1050),
  ('3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 51', 1051),
  ('8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 52', 1052),
  ('f1959f8c-7a66-57ac-81a3-fa44c713850b'::uuid, (select id from jlpt_levels where code = 'N2'), 'N2 - Kanji - Ngày 53', 1053)
on conflict (id) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Lesson items — gắn kanji vào từng ngày. JOIN qua `character` để lấy đúng id thật trong bảng
-- kanji (tránh lệch id nếu 1 ký tự bị on-conflict bỏ qua ở bước insert kanji vì đã tồn tại
-- từ N5/N4 với id khác).
-- ─────────────────────────────────────────────────────────────
-- Ngày 01
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '握'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '扱'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '依'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '威'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '為'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '偽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '偉'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '違'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '維'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '緯'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '壱'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4a8a399a-ea96-55c3-a5b0-7268b5979d4d'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '芋'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 02
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '陰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '隠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '影'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '鋭'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '越'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '援'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '煙'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '鉛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '縁'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '汚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '押'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e0bebd44-ffcd-5182-92cd-75697270629e'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '奥'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 03
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '憶'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '菓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '暇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '箇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '雅'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '介'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '戒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '械'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '皆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '壊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '較'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '64a42124-706d-5330-ad95-fe78e66768d2'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '獲'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 04
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '穫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '刈'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '甘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '汗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '乾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '勧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '歓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '環'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '鑑'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '含'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '奇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f3fa8e81-e135-50a7-9bda-75b554861d6d'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '祈'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 05
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '鬼'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '塊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '魂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '魅'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '麻'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '魔'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '摩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '磨'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '幾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '輝'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '儀'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ac239318-837e-5274-b7f1-d8f7c207bf14'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '虐'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 06
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '慮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '膚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '虎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '虚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '戯'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '詰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '却'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '脚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '及'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '丘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '朽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ffb4a9d8-0365-5e61-bab5-6fca19c720eb'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '巨'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 07
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '距'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '拒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '拠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '御'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '凶'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '叫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '狂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '況'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '狭'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '恐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '響'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '04e8f6a8-ec61-591f-8cea-f8d730807ac1'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '驚'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 08
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '仰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '駆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '屈'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '掘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '繰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '操'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '燥'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '恵'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '傾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '継'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '迎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f166d3b9-2a55-54c7-b997-3a111d7784ff'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '撃'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 09
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '肩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '兼'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '嫌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '廉'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '謙'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '剣'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '軒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '圏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '堅'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '遣'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '玄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '44b025ec-dbba-5449-8a2b-69af85a0364c'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '枯'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 10
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '誇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '鼓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '互'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '抗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '攻'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '更'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '恒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '荒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '慌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '香'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '項'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '96da83fd-4952-5705-98f3-b97b5f3a2200'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '稿'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 11
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '豪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '込'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '婚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '鎖'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '彩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '菜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '採'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '歳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '載'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '剤'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '咲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'fb47acf1-05c9-5803-81a2-e828c801e60a'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '惨'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 12
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '旨'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '伺'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '刺'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '脂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '紫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '雌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '雄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '執'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '芝'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '斜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '煮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9a4cb732-f844-5ec9-8a4c-f1bc69a2f650'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '釈'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 13
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '寂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '朱'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '狩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '趣'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '需'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '舟'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '秀'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '襲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '柔'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '獣'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '瞬'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '46882aa8-699b-5a04-9fb0-dffc39e9466f'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '旬'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 14
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '巡'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '盾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '召'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '沼'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '紹'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '床'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '称'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '詳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '丈'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '畳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '殖'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '1f25258b-ddee-5714-afa8-ba79a0e85c62'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '飾'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 15
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '触'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '寝'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '侵'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '浸'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '振'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '慎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '震'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '薪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '尽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '陣'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '尋'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '4cffddbc-e8ca-543c-8b08-0ab78f2726f7'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '吹'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 16
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '是'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '井'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '姓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '征'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '跡'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '占'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '扇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '鮮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '訴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '曽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '僧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'aefe6559-d37a-5497-9093-cb4377631e3c'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '増'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 17
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '贈'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '憎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '層'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '騒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '即'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '俗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '耐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '替'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '沢'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '拓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '濁'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c483c74-46db-5160-8017-ae09b2d06543'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '脱'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 18
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '丹'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '淡'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '嘆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '端'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '弾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '恥'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '致'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '遅'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '蓄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '沖'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '跳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '330ca902-20c2-54de-b516-c35e7b12769b'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '徴'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 19
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '澄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '沈'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '珍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '抵'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '堤'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '提'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '摘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '敵'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '適'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '滴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '添'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'a70cb663-574e-5c86-906a-51912b3c4975'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '殿'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 20
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '途'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '吐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '渡'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '奴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '怒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '透'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '唐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '糖'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '桃'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '逃'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '盗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'de974451-ebfd-5448-9a2f-aaaa38c5ba4d'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '塔'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 21
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '到'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '倒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '踏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '稲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '闘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '胴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '峠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '突'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '鈍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '曇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '弐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '6dcaec77-04ef-5015-9949-5fd736d0ef26'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '悩'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 22
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '濃'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '輩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '杯'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '泊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '拍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '迫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '薄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '爆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '髪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '抜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '罰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd1d2cd4c-aa5b-556f-a7f3-b2599f59d8ba'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '敏'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 23
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '繁'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '販'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '般'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '搬'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '盤'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '範'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '被'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '疲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '彼'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '避'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '壁'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd50a775f-f409-5b1d-bfd2-ee798b40fcd3'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '尾'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 24
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '微'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '匹'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '描'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '浜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '怖'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '浮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '腐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '敷'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '普'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '賦'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '舞'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '608ecb07-ad1a-562b-9206-43ae79563d6d'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '幅'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 25
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '払'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '噴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '柄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '捕'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '舗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '峰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '抱'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '砲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '肪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '坊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '忙'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '811010a4-28f4-59e1-aa9c-0b8bbb87d960'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '冒'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 26
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '帽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '傍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '凡'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '帆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '盆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '漫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '慢'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '妙'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '眠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '矛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '霧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '90b5d983-fadc-5c09-8126-a791068ae958'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '娘'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 27
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '網'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '茂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '猛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '黙'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '紋'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '躍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '与'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '誉'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '腰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '溶'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '踊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '72dfdb13-33b5-558c-9128-513219c06da2'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '謡'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 28
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '翼'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '雷'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '頼'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '瀬'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '絡'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '欄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '離'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '粒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '療'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '寮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '僚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b0babb9d-feec-59e7-be58-8403d49a95ca'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '隣'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 29
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '戻'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '涙'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '隷'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '麗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '齢'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '暦'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '劣'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '烈'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '恋'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '露'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '郎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8c987817-2535-59af-8c6c-ae5d0ae97627'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '惑'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 30
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '腕'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '哀'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '慰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '詠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '悦'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '閲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '炎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '宴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '欧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '殴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '乙'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'dd010918-588d-5dde-a5ce-f21500eab363'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '卸'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 31
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '穏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '架'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '佳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '華'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '嫁'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '餓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '怪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '悔'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '既'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '概'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '慨'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '49ccdf49-9a00-5bcd-a2f5-5eebcf961b6d'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '郭'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 32
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '隔'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '岳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '掛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '滑'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '勘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '肝'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '貫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '敢'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '緩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '暖'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '冠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '492c7710-d3e7-5ffd-934d-06b6bd55d599'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '換'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 33
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '喚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '企'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '軌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '棄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '棋'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '忌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '欺'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '岐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '騎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '犠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '菊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9387f363-a514-5fdc-af78-7a9557556e50'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '吉'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 34
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '喫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '脅'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '峡'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '凝'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '緊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '斤'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '愚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '偶'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '遇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '啓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '鶏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '476d544d-273a-5164-a341-5aad31d582fc'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '携'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 35
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '刑'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '憩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '契'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '掲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '鯨'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '賢'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '倹'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '幻'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '雇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '顧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '弧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ee59872e-7164-5f40-af28-6d2047b54d31'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '孤'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 36
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '呉'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '悟'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '娯'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '甲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '孔'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '控'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '拘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '郊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '硬'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '綱'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '巧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '45a66bb0-24b1-520c-a295-499ee585dbd9'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '坑'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 37
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '絞'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '酵'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '克'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '獄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '紺'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '恨'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '墾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '催'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '債'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '削'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '錯'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd2d3d8bc-0fa5-5831-9dc9-bb6073d3f5b1'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '搾'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 38
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '撮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '擦'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '暫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '施'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '祉'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '諮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '侍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '慈'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '軸'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '湿'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '疾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e2ff6c06-1b8a-50ac-904d-7f10b8f4c1f0'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '赦'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 39
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '邪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '殊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '寿'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '潤'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '遵'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '徐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '如'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '晶'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '掌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '鐘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '焦'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd3f6f51b-a956-58a0-9484-750295a8c982'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '衝'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 40
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '昇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '匠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '譲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '嬢'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '壌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '醸'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '錠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '冗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '嘱'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '辱'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '審'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '5f1461ec-2e17-507f-8eb4-0ab55950d668'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '伸'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 41
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '辛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '粋'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '酔'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '炊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '遂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '衰'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '穂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '随'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '髄'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '牲'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '婿'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8d48bc73-cc56-5eb8-9eb6-d763b79656ac'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '請'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 42
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '隻'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '惜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '措'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '斥'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '籍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '摂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '潜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '繕'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '双'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '阻'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '粗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'b2559328-10c0-53c8-b2bf-2c772b21ce35'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '礎'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 43
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '桑'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '葬'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '掃'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '遭'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '促'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '賊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '逮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '胎'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '怠'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '滞'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '袋'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'd8020095-08c6-5697-8868-6cddf1935a69'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '滝'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 44
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '託'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '卓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '択'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '諾'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '奪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '胆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '鍛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '壇'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '稚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '畜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '窒'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '9afe9e06-b408-59e3-b652-47ac0d6236d6'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '駐'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 45
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '抽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '鋳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '彫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '超'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '聴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '陳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '鎮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '墜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '訂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '帝'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '締'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e69f9d7c-1e1d-5194-bccb-75406e7f9754'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '哲'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 46
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '誓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '斗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '塗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '陶'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '凍'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '痘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '匿'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '篤'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '豚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '尿'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '粘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3cb36bbc-cc60-5ee4-8c6b-c4cf6c16ed59'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '婆'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 47
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '排'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '陪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '縛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '伐'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '伴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '畔'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '藩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '蛮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '泌'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '卑'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '碑'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'e33437da-692d-5665-889a-4bc801e3040c'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '姫'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 48
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '漂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '苗'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '猫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '赴'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '符'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '封'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '伏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '覆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '墳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '紛'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '癖'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '697779da-eefb-52f3-9141-64d09a83d283'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '募'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 49
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '慕'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '墓'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '暮'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '模'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '膜'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '簿'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '崩'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '芳'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '胞'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '縫'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '倣'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '19791752-752b-5870-8421-f065b61ebb6c'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '妨'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 50
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '房'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '飽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '奉'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '乏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '某'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '謀'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '膨'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '墨'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '没'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '翻'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '埋'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'ca193746-023b-5bce-a820-cbab0b467de0'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '又'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 51
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '滅'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '免'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '幽'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '憂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '優'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '誘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '擁'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '揚'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '揺'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '抑'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '裸'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '3d179c78-b53c-52ed-b17f-1521b2be8116'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '濫'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 52
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '吏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '隆'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '陵'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '了'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '糧'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 5
from kanji k where k.character = '厘'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 6
from kanji k where k.character = '零'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 7
from kanji k where k.character = '霊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 8
from kanji k where k.character = '励'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 9
from kanji k where k.character = '裂'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 10
from kanji k where k.character = '錬'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), '8e55a9e7-21ae-5cef-aacb-e0bef9e31630'::uuid, 'kanji', k.id, 11
from kanji k where k.character = '炉'
on conflict (lesson_id, item_type, item_id) do nothing;

-- Ngày 53
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f1959f8c-7a66-57ac-81a3-fa44c713850b'::uuid, 'kanji', k.id, 0
from kanji k where k.character = '漏'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f1959f8c-7a66-57ac-81a3-fa44c713850b'::uuid, 'kanji', k.id, 1
from kanji k where k.character = '廊'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f1959f8c-7a66-57ac-81a3-fa44c713850b'::uuid, 'kanji', k.id, 2
from kanji k where k.character = '浪'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f1959f8c-7a66-57ac-81a3-fa44c713850b'::uuid, 'kanji', k.id, 3
from kanji k where k.character = '楼'
on conflict (lesson_id, item_type, item_id) do nothing;
insert into lesson_items (id, lesson_id, item_type, item_id, order_index)
select gen_random_uuid(), 'f1959f8c-7a66-57ac-81a3-fa44c713850b'::uuid, 'kanji', k.id, 4
from kanji k where k.character = '湾'
on conflict (lesson_id, item_type, item_id) do nothing;
