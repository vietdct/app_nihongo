-- AI Kaiwa — Hội thoại cùng AI
-- Personas + tình huống là dữ liệu tham chiếu công khai (giống jlpt_levels).
-- Conversations/messages là dữ liệu riêng tư của từng người dùng.

-- ─────────────────────────────────────────────────────────────
-- Nhân vật AI
-- ─────────────────────────────────────────────────────────────
create table kaiwa_personas (
  id                uuid primary key default gen_random_uuid(),
  name              varchar(64)  not null,
  glyph             varchar(8)   not null,
  role              varchar(64)  not null,
  gender            varchar(16)  not null,
  personality       text         not null,
  politeness_level  varchar(16)  not null, -- 'casual' | 'polite' | 'keigo'
  voice_style       varchar(32)  not null default 'ja-JP',
  description       text         not null,
  order_index       int          not null default 0,
  created_at        timestamptz  not null default now()
);

-- ─────────────────────────────────────────────────────────────
-- Tình huống hội thoại
-- ─────────────────────────────────────────────────────────────
create table kaiwa_scenarios (
  id              uuid primary key default gen_random_uuid(),
  title           varchar(64)  not null,
  glyph           varchar(8)   not null,
  category        varchar(32)  not null,
  description     text         not null,
  level_min       varchar(4)   not null default 'N5',
  system_context  text         not null, -- bối cảnh/mục tiêu hội thoại, đưa vào system prompt
  order_index     int          not null default 0,
  created_at      timestamptz  not null default now()
);

-- ─────────────────────────────────────────────────────────────
-- Phiên hội thoại của người dùng
-- ─────────────────────────────────────────────────────────────
create table kaiwa_conversations (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  persona_id        uuid not null references kaiwa_personas(id),
  scenario_id       uuid not null references kaiwa_scenarios(id),
  level_id          uuid references jlpt_levels(id),
  started_at        timestamptz not null default now(),
  last_message_at   timestamptz not null default now(),
  turn_count        int not null default 0
);
create index ix_kaiwa_conversations_user on kaiwa_conversations (user_id, last_message_at desc);

-- ─────────────────────────────────────────────────────────────
-- Từng lượt tin nhắn (user hoặc ai) trong phiên hội thoại
-- ─────────────────────────────────────────────────────────────
create table kaiwa_messages (
  id               uuid primary key default gen_random_uuid(),
  conversation_id  uuid not null references kaiwa_conversations(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  role             varchar(8) not null check (role in ('user', 'ai')),
  content_jp       text not null,
  translation_vi   text,
  furigana         text,
  feedback         jsonb, -- {rating, naturalness, grammar, vocabulary, politeness, native_likeness, explanation, common_mistake, better_phrasing}
  created_at       timestamptz not null default now()
);
create index ix_kaiwa_messages_conversation on kaiwa_messages (conversation_id, created_at);
create index ix_kaiwa_messages_user on kaiwa_messages (user_id);

-- ─────────────────────────────────────────────────────────────
-- Row Level Security
-- ─────────────────────────────────────────────────────────────
alter table kaiwa_personas enable row level security;
create policy "kaiwa_personas_read_all" on kaiwa_personas for select using (true);

alter table kaiwa_scenarios enable row level security;
create policy "kaiwa_scenarios_read_all" on kaiwa_scenarios for select using (true);

alter table kaiwa_conversations enable row level security;
create policy "kaiwa_conversations_select_own" on kaiwa_conversations for select using (auth.uid() = user_id);
create policy "kaiwa_conversations_insert_own" on kaiwa_conversations for insert with check (auth.uid() = user_id);
create policy "kaiwa_conversations_update_own" on kaiwa_conversations for update using (auth.uid() = user_id);

alter table kaiwa_messages enable row level security;
create policy "kaiwa_messages_select_own" on kaiwa_messages for select using (auth.uid() = user_id);
create policy "kaiwa_messages_insert_own" on kaiwa_messages for insert with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- Seed: nhân vật AI
-- ─────────────────────────────────────────────────────────────
insert into kaiwa_personas (name, glyph, role, gender, personality, politeness_level, description, order_index) values
('田中先生', '師', 'Giáo viên', 'nữ', 'Kiên nhẫn, ân cần, sửa lỗi nhẹ nhàng và luôn giải thích rõ vì sao sai.', 'keigo', 'Cô giáo dạy tiếng Nhật, nói chuẩn mực và khích lệ người học.', 1),
('山田先生', '師', 'Giáo viên', 'nam', 'Nghiêm túc nhưng hài hước, hay đưa ví dụ thực tế để dễ nhớ.', 'keigo', 'Thầy giáo dạy tiếng Nhật, phong cách gần gũi.', 2),
('ゆい', '友', 'Bạn cùng lớp', 'nữ', 'Năng động, thân thiện, nói chuyện tự nhiên như bạn bè.', 'casual', 'Bạn học cùng lớp tiếng Nhật, rủ rê nói chuyện phiếm hằng ngày.', 3),
('けんた', '僚', 'Đồng nghiệp', 'nam', 'Chuyên nghiệp, lịch sự vừa phải, hay hỏi thăm công việc.', 'polite', 'Đồng nghiệp cùng công ty, trò chuyện trong giờ làm việc.', 4),
('さくら', '恋', 'Người yêu', 'nữ', 'Ngọt ngào, quan tâm, hay hỏi về sở thích và cảm xúc.', 'casual', 'Người yêu Nhật Bản, trò chuyện tình cảm đời thường.', 5),
('店員', '店', 'Nhân viên cửa hàng', 'nữ', 'Lịch sự, nhiệt tình giới thiệu sản phẩm/món ăn.', 'polite', 'Nhân viên bán hàng/phục vụ tại cửa hàng, nhà hàng.', 6),
('お客さん', '客', 'Khách hàng', 'nam', 'Lịch sự nhưng có yêu cầu cụ thể, đôi khi phàn nàn nhẹ.', 'polite', 'Khách hàng — luyện tập khi bạn đóng vai nhân viên phục vụ.', 7),
('部長', '長', 'Quản lý / Sếp', 'nam', 'Nghiêm khắc, nói ngắn gọn, dùng kính ngữ chuẩn mực.', 'keigo', 'Trưởng phòng — luyện giao tiếp công sở cấp trên.', 8),
('おばあちゃん', '祖', 'Người Nhật lớn tuổi', 'nữ', 'Nói chậm rãi, ấm áp, hay kể chuyện xưa.', 'casual', 'Bà cụ hàng xóm, trò chuyện đời thường thong thả.', 9),
('けん', '童', 'Trẻ em', 'nam', 'Ngây thơ, tò mò, câu ngắn và đơn giản.', 'casual', 'Một em bé Nhật Bản — hội thoại đơn giản, phù hợp luyện phản xạ cơ bản.', 10);

-- ─────────────────────────────────────────────────────────────
-- Seed: tình huống hội thoại
-- ─────────────────────────────────────────────────────────────
insert into kaiwa_scenarios (title, glyph, category, description, level_min, system_context, order_index) values
('Giới thiệu bản thân', '介', 'Cơ bản', 'Luyện chào hỏi và giới thiệu bản thân lần đầu gặp mặt.', 'N5', 'Đây là lần đầu hai người gặp nhau. AI chủ động chào hỏi, hỏi tên/quê quán/sở thích và khuyến khích người học giới thiệu về bản thân.', 1),
('Trò chuyện tự do', '談', 'Tự do', 'Không giới hạn chủ đề — AI chủ động đặt câu hỏi, trò chuyện tự nhiên.', 'N5', 'Không có kịch bản cố định. AI chủ động dẫn dắt chủ đề đa dạng (sở thích, thời tiết, công việc, phim ảnh...), không lặp lại chủ đề cũ.', 2),
('Nhà hàng', '食', 'Đời sống', 'Gọi món, hỏi thực đơn, thanh toán tại nhà hàng.', 'N5', 'Bối cảnh: nhà hàng Nhật Bản. AI đóng vai nhân viên phục vụ, hỏi số người, giới thiệu món, ghi order, hỏi thêm đồ uống, tính tiền.', 3),
('Siêu thị', '購', 'Đời sống', 'Hỏi giá, tìm đồ, thanh toán tại siêu thị.', 'N5', 'Bối cảnh: siêu thị. AI đóng vai nhân viên hoặc thu ngân, hỗ trợ tìm sản phẩm, giải thích khuyến mãi, tính tiền.', 4),
('Ga tàu & hỏi đường', '道', 'Đời sống', 'Hỏi đường, mua vé, hỏi giờ tàu.', 'N5', 'Bối cảnh: nhà ga. AI đóng vai nhân viên nhà ga hoặc người qua đường, hướng dẫn đường đi, giờ tàu, cách mua vé.', 5),
('Quán cafe', '喫', 'Đời sống', 'Gọi đồ uống, trò chuyện phiếm tại quán cafe.', 'N5', 'Bối cảnh: quán cafe. AI đóng vai nhân viên pha chế hoặc bạn cùng ngồi cafe, trò chuyện nhẹ nhàng.', 6),
('Trường học', '校', 'Đời sống', 'Trò chuyện với bạn học/giáo viên ở trường.', 'N5', 'Bối cảnh: trường học. AI đóng vai bạn học hoặc giáo viên, hỏi về môn học, bài tập, câu lạc bộ.', 7),
('Khách sạn', '宿', 'Du lịch', 'Nhận phòng, yêu cầu dịch vụ tại khách sạn.', 'N4', 'Bối cảnh: quầy lễ tân khách sạn. AI đóng vai lễ tân, hỗ trợ nhận/trả phòng, yêu cầu dịch vụ, giải đáp thắc mắc.', 8),
('Du lịch Nhật Bản', '旅', 'Du lịch', 'Hỏi thông tin du lịch, địa điểm tham quan.', 'N4', 'Bối cảnh: khách du lịch hỏi người địa phương về địa điểm tham quan, ẩm thực, phương tiện di chuyển.', 9),
('Hẹn hò', '恋', 'Đời sống', 'Trò chuyện tình cảm, rủ đi chơi, bày tỏ cảm xúc.', 'N4', 'Bối cảnh: buổi hẹn hò. AI đóng vai người yêu/bạn hẹn hò, trò chuyện thân mật, hỏi cảm xúc và sở thích.', 10),
('Công ty & công việc', '務', 'Công việc', 'Báo cáo công việc, trao đổi với đồng nghiệp/cấp trên.', 'N3', 'Bối cảnh: văn phòng công ty Nhật Bản. AI đóng vai đồng nghiệp hoặc cấp trên, trao đổi công việc, dùng kính ngữ phù hợp.', 11),
('Phỏng vấn xin việc', '接', 'Công việc', 'Luyện trả lời phỏng vấn xin việc bằng tiếng Nhật.', 'N2', 'Bối cảnh: buổi phỏng vấn xin việc. AI đóng vai nhà tuyển dụng, hỏi về kinh nghiệm, điểm mạnh/yếu, lý do ứng tuyển — dùng kính ngữ nghiêm túc.', 12),
('Bệnh viện', '院', 'Đời sống', 'Mô tả triệu chứng, trao đổi với bác sĩ/y tá.', 'N4', 'Bối cảnh: phòng khám bệnh viện. AI đóng vai bác sĩ hoặc y tá, hỏi triệu chứng, đưa lời khuyên đơn giản.', 13);
