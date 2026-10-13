-- Seed N2 — Ngữ pháp đầy đủ (173 điểm — TOÀN BỘ nội dung sách), trích xuất từ PDF nguồn:
--   "完全マスター 日本語能力試験２級 文法" (bunpo_N2.pdf, 80 trang, biên dịch
--   tiếng Việt sẵn — điền/翻訳 阮登貴, 武氏河宣, Kobe/Hanoi 2008).
--   Mục lục đầu sách (trang 2-5) liệt kê 155 mục theo thứ tự bài học; sách còn có
--   thêm 18 điểm nằm ngoài mục lục đầu sách đó (nhưng vẫn có trong nội dung chính
--   trang 6-75 và trong 索引 — mục lục tra cứu theo abc — ở cuối sách trang 76-80):
--   #156-159 (～得る／～得ない, ～かねない, ～かねる, ～ことか) phát hiện ở phiên
--   trước, và #160-173 (～ことだ, ～ざるを得ない, ～次第だ／～次第で（は）,
--   ～っこない, ～というものだ, ～というものではない／～というものでもない,
--   ～ないことはない／～ないこともない, ～ないではいられない／～ずにはいられない,
--   ～に限る／～に限り／～に限って, ～に限らず, ～にほかならない, ～もの,
--   ～ものがある, ～ようがない／～ようもない) đọc tiếp ở phiên này (trang 65-75).
--   Trang 75 là trang nội dung cuối cùng của sách (số thứ tự cao nhất trong 索引
--   là #173, khớp với item cuối trang 75) — trang 76-80 chỉ là 索引 tra cứu, không
--   có nội dung mới nên dừng lại đúng ở #173.
-- Mỗi điểm ngữ pháp lấy nguyên: title (mẫu câu, giữ dạng có ～), explanation
--   (viết lại mạch lạc bằng tiếng Việt từ phần 意味/giải thích gốc — giữ đúng
--   nội dung, không bịa; các điểm có nhiều nghĩa A/B/C... được gộp lại có đánh
--   dấu A)/B)/C) tương ứng đúng thứ tự trong PDF), example_jp/example_vi (ví dụ
--   đầu tiên trong PDF), extra_examples_jp/extra_examples_vi (toàn bộ ví dụ còn
--   lại, mảng song song theo đúng thứ tự PDF).
--
-- Giới hạn đã biết (không tự bịa, để làm giàu ở phiên sau như đã làm cho N5/N4):
--   - common_mistake, memory_tip, comparison_note: để trống (NULL/'{}').
--   - practice_tokens, practice_blank_index: để trống (tính năng riêng, không
--     thuộc phạm vi yêu cầu).
--   - Điểm #9 (～に対して...): PDF gốc chỉ có 4 ví dụ đánh số ①③④⑤ (thiếu số
--     ②, có vẻ lỗi in ấn/OCR nguồn — không tự bịa thêm ví dụ ②).
--   - Điểm #16 (～を問わず): PDF có thêm 1 câu 参考 (không đánh số ví dụ) —
--     không đưa vào extra_examples vì đó là ghi chú tham khảo, không phải ví dụ.
--   - Điểm #163 (～っこない) và #167 (～ないではいられない...): PDF có thêm 1 câu
--     注意 (ghi chú ngữ pháp, không phải ví dụ) — không đưa vào extra_examples.
--
-- extra_examples_jp/extra_examples_vi là cột NOT NULL DEFAULT '{}' (xem migration
-- 20260810100000_grammar_extra_examples.sql) nên khi chỉ có 1 ví dụ, dùng mảng
-- rỗng ARRAY[]::text[] thay vì NULL.
--
-- id: uuid5 (NAMESPACE_URL, 'app-nihongo:n2:grammar:<title>') — cố định, idempotent.
--
-- Lessons: 173 điểm chia thành 58 "ngày" (mỗi ngày 3 điểm liên tiếp theo đúng thứ tự
--   trong file, riêng ngày 58 chỉ có 2 điểm), title "N2 - Ngữ pháp - Ngày 01".."58",
--   id uuid5 (NAMESPACE_URL, 'app-nihongo:n2:lesson:grammar:day:<NN>').
--
-- Chạy: supabase db query --linked -f supabase/seed_content_n2_grammar.sql

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('1921b09f-1fbf-5365-93a8-19df0f52dc2a'::uuid, '～として（は）／～としても／～としての',
   'Nói về lập trường, tư cách, chủng loại của một sự vật/người nào đó — dùng để chỉ rõ vị trí, tư cách hay loại việc đang được nói tới.',
   '彼は国費留学生として日本へ来た。', 'Anh ấy đã đến Nhật với tư cách là lưu học sinh ngân sách nhà nước',
   ARRAY['この病気は難病として認定された。','彼は医者であるが、小説家としても有名である。','あの人は学者としては立派だが、人間としては尊敬できない。','日本はアジアの一員としての役割を果たさなければならない。']::text[],
   ARRAY['Căn bệnh này được nhận định là một bệnh nan y.','Tuy ông ấy là một bác sĩ, nhưng cũng nổi tiếng với tư cách là một tiểu thuyết gia.','Người kia tuy là một học giả xuất sắc, nhưng là một con người không đáng kính trọng.','Nhật Bản phải đóng vai trò như là một thành viên của Châu Á.']::text[]),

  ('b52c5fac-a86e-557a-9a97-6e18a027bc8d'::uuid, '～とともに',
   'A) ～と一緒に: cùng với... (danh từ + とともに). B) ～であると同時に: đồng thời với việc gì, cùng lúc với (động từ/tính từ/danh từ thể từ điển, い形-い, な形-である, 名-である + とともに). C) diễn tả khi một sự thay đổi xảy ra thì một sự thay đổi khác cũng diễn ra theo (động từ thể từ điển/danh từ + とともに).',
   'お正月は家族とともに過ごしたい。', 'Tôi muốn ăn Tết cùng gia đình.',
   ARRAY['大阪は東京とともに日本経済の中心地である。','小林氏は、学生を指導するとともに、研究にも力を入れている。','代表に選ばれなくてくやしいとともに、ほっとする気持ちもあった。','この製品の開発は、困難であるとともに、費用がかかる。','義務教育は、国民の義務であるとともに、権利でもある。','年をとるとともに、体力が衰える。','自動車が普及するとともに、交通事故も増えてきた。','経済成長とともに、国民の生活も豊かになった。']::text[],
   ARRAY['Osaka cùng với Tokyo là các trung tâm kinh tế của Nhật.','Cùng với việc hướng dẫn sinh viên, ông Kobayashi còn tận lực trong nghiên cứu.','Vừa tiếc vì không được chọn làm đại biểu, tôi cũng thấy bớt căng thẳng hơn.','Việc phát triển sản phẩm này, cùng với những khó khăn còn tốn chi phí nữa.','Giáo dục phổ cập vừa là nghĩa vụ, còn là quyền lợi của nhân dân.','Cùng với tuổi cao, thể lực cũng yếu đi.','Cùng với việc ô tô trở nên phổ biến, tai nạn giao thông cũng tăng lên.','Cùng với tăng trưởng kinh tế, đời sống nhân dân cũng sung túc hơn.']::text[]),

  ('9bb0d0f6-5878-51c2-a134-6e7efa2374b1'::uuid, '～において（は）／～においても／～における',
   '～で (biểu thị địa điểm, thời gian). Nghĩa: ở, tại, trong, về việc, đối với — chỉ địa điểm hoặc thời gian mà sự việc diễn ra.',
   '会議は第一会議室において行われる。', 'Hội nghị được tổ chức ở phòng họp số 1.',
   ARRAY['現代においては、コンピューターは不可欠なものである。','我が国においても、青少年の犯罪が増えている。','それは私の人生における最良の日であった。']::text[],
   ARRAY['Ngày nay, máy tính là vật không thể thiếu được.','Ở nước ta cũng thế, tội phạm thanh thiếu niên đang tăng lên.','Đó là ngày đẹp nhất đời tôi.']::text[]),

  ('983b21b1-3f11-5cdb-aaac-1449ab9892b2'::uuid, '～に応じて／～に応じ／～に応じた',
   '～にしたがって・～に適している. Nghĩa: phụ thuộc vào, ứng với, tuỳ theo.',
   '保険金は被害状況に応じて、払われる。', 'Tiền bảo hiểm sẽ được trả tuỳ theo tình trạng thiệt hại.',
   ARRAY['季節に応じ、体の色を変えるウサギがいる。','無理をしないで体力に応じた運動をしてください。']::text[],
   ARRAY['Có loại thỏ mà màu sắc cơ thể biến đổi theo mùa.','Hãy vận động tuỳ theo thể lực, đừng quá sức.']::text[]),

  ('7a5bdce1-c437-59d1-9d9b-46ef8dc7916b'::uuid, '～にかわって／～にかわり',
   'A) Bây giờ thì không... nữa — biểu thị việc thay đổi một thứ đã được sử dụng thành một thứ khác. B) đại lý, đại diện — biểu thị việc làm đại diện cho một người khác.',
   'ここでは、人間にかわってロボットが作業をしている。', 'Ở đây, robot đang làm việc thay cho con người.',
   ARRAY['今はタイプライターにかわり、ワープロが使われている。','父にかわって、私が結婚式に出席しました。','首相にかわり、外相がアメリカを訪問した。']::text[],
   ARRAY['Bây giờ, thay cho bàn đánh máy, máy vi tính (đánh chữ) được sử dụng.','Tôi đã đi đám cưới thay cho bố.','Thay mặt cho thủ tướng, bộ trưởng ngoại giao đã đi thăm Mỹ.']::text[]),

  ('960445c3-aa9b-57e2-9948-bb88b409af8f'::uuid, '～に比べて／～に比べ',
   '～を基準にして程度の違いなどを言う. Nghĩa: so với..., lấy làm chuẩn để nói về mức độ khác nhau.',
   '兄に比べて、弟はよく勉強する。', 'So với anh trai, ông em học chăm hơn.',
   ARRAY['諸外国に比べて、日本は食料品が高いと言われている。','今年は去年に比べ、雨の量が多い。']::text[],
   ARRAY['So với ngoại quốc, giá thực phẩm ở Nhật được cho là cao.','Năm nay so với năm ngoái thì lượng mưa nhiều hơn.']::text[]),

  ('491bbfa2-cf02-582f-94d1-d9b80014d682'::uuid, '～にしたがって／～にしたがい　従い／したがい',
   '～と一緒に. Nghĩa: cùng với ~ — biểu thị việc cùng với sự thay đổi theo một hướng nào đó thì một hướng khác cũng thay đổi theo.',
   '高く登るにしたがって、見晴らしがよくなった。', 'Khi lên cao, tầm nhìn cũng rõ hơn.',
   ARRAY['工業化が進むにしたがって、自然環境の破壊が広がった。','電気製品の普及にしたがって、家事労働が楽になった。','試験が近づくにしたがって、緊張が高まる。']::text[],
   ARRAY['Cùng với sự tiến triển của công nghiệp hoá, sự phá hoại môi trường tự nhiên ngày càng lan rộng.','Theo sự phổ cập của đồ điện máy, việc nhà cũng nhàn nhã hơn.','Khi kỳ thi càng đến gần, độ căng thẳng càng cao (càng thấy căng thẳng hơn).']::text[]),

  ('2b817f7e-e626-547d-9bb6-4baae56d3dc5'::uuid, '～につれて／～につれ',
   '～と一緒に. Nghĩa: cùng với ~ — biểu thị việc cùng với sự thay đổi theo một hướng nào đó thì một hướng khác cũng thay đổi theo (ý nghĩa gần giống ～にしたがって nhưng thiên về sự thay đổi tự nhiên, dần dần).',
   '品質がよくなるにつれて、値段が高くなる。', 'Khi chất lượng tốt lên, giá cũng trở nên đắt.',
   ARRAY['時代の変化につれて、結婚の形も変わってきた。','年をとるにつれ、昔のことが懐かしく思い出される。']::text[],
   ARRAY['Thời đại thay đổi, các hình thức kết hôn cũng thay đổi.','Về già, càng nhớ tiếc về ngày xưa.']::text[]),

  ('d77a1e12-f7d4-5ac2-8d62-de3e71d9312d'::uuid, '～に対して（は）／～に対し／～に対しても／～に対する',
   '～に (biểu thị đối tượng, đối phương). Nghĩa: về việc, đối với ~ — chỉ đối tượng hoặc đối phương của hành động/thái độ.',
   'お客様に対して失礼なことを言ってはいけません。', 'Đối với khách hàng, cấm nói điều thất lễ.',
   ARRAY['いいことをした人に対し、表彰状が贈られる。','陳さんは日本の経済だけではなく日本の文化に対しても、興味を持っている。','被害者に対する補償問題を検討する。']::text[],
   ARRAY['Với người làm việc tốt, sẽ được tặng giấy khen.','Anh Trần không chỉ có hứng thú với kinh tế Nhật Bản mà còn cả với văn hoá Nhật nữa.','Chúng tôi xem xét vấn đề bồi thường với người bị hại.']::text[]),

  ('2cf50cce-fb26-520c-a819-aed92216a848'::uuid, '～について（は）／～につき／～についても／～についての',
   '話したり考えたりする内容を表す. Nghĩa: về, liên quan đến... — biểu thị nội dung của suy nghĩ, lời nói.',
   '日本の経済について研究しています。', 'Tôi đang nghiên cứu về kinh tế Nhật Bản.',
   ARRAY['この病気の原因については、いくつかの説がある。','我が社の新製品につき、ご説明いたします。','日本の習慣についても、自分の国の習慣と比べながら考えてみよう。','コンピューターの使い方についての本がほしい。']::text[],
   ARRAY['Về nguyên nhân của căn bệnh này, có một vài giả thuyết (được đưa ra).','Tôi xin phép trình bày về sản phẩm mới của công ty chúng tôi.','Về tập quán của Nhật Bản, hãy thử suy nghĩ khi so sánh với tập quán của đất nước bạn.','Tôi muốn có cuốn sách nói về cách sử dụng máy tính.']::text[]),

  ('86cc8574-9590-5229-8ef0-1af4e4fc68a0'::uuid, '～にとって（は）／～にとっても／～にとっての',
   '～の立場からみると (sau đó thường là phán đoán, bình phẩm). Nghĩa: đối với..., nhìn từ lập trường của ~.',
   'この写真は私にとって、何よりも大切なものです。', 'Bức ảnh này đối với tôi là thứ quan trọng hơn tất cả (hơn bất cứ thứ gì).',
   ARRAY['社員にとっては、給料は高いほうがいい。','だれにとっても一番大切なのは健康です。','環境問題は、人類にとっての課題だ。']::text[],
   ARRAY['Với nhân viên công ty thì, lương cao sẽ tốt hơn.','Với bất kỳ ai, sức khoẻ là quan trọng nhất.','Vấn đề môi trường là thách thức (nhiệm vụ) đối với nhân loại.']::text[]),

  ('7df4deaf-d5fc-5a27-8f02-26215b350a62'::uuid, '～に伴って／～に伴い／～に伴う',
   'A) ～にしたがって・～につれて: cùng với, đi kèm... B) ～と一緒に (同時に起きる): cùng với, xảy ra đồng thời.',
   '人口が増えるに伴って、いろいろな問題が起こってきた。', 'Đi kèm với việc tăng dân số, nhiều vấn đề đa dạng nảy sinh.',
   ARRAY['円高に伴い、来日する外国人旅行者が少なくなった。','経済発展にともなう環境破壊が問題になっている。','地震に伴って、火災が発生することが多い。','自由には、それに伴う責任がある。']::text[],
   ARRAY['Kèm theo việc đồng Yên tăng giá, khách du lịch đến Nhật cũng giảm đi.','Việc phá hoại môi trường đi kèm với sự phát triển kinh tế đang trở thành vấn đề (cần giải quyết).','Cùng với động đất, hoả hoạn cũng phát sinh nhiều.','Tự do luôn đi kèm với trách nhiệm.']::text[]),

  ('721e6341-58cf-51ef-97ef-80504a084229'::uuid, '～によって／～により／～による／～によっては',
   'A) 動作の主体（主に受身文で）: nhờ vào, do, bởi ~ — chỉ chủ thể của hành động (chủ yếu trong câu bị động). B) 原因・理由: chỉ lý do, nguyên nhân. C) 手段・方法: chỉ phương thức, biện pháp. D) ～に応じて、それぞれ違う: biểu thị việc ứng với ~ mà có sự khác nhau. E) ある～の場合には（～によっては）: có trường hợp ~ mà...',
   'アメリカ大陸はコロンブスによって発見された。', 'Châu Mỹ do Columbus phát hiện ra.',
   ARRAY['この法案は国会により承認された。','医師による診断の結果を報告します。','不注意によって大事故が起こることもある。','首相が暗殺されたことにより、A国の政治は混乱した。','今回の地震による被害は数兆円にのぼると言われている。','問題は話し合いによって解決した方がいい。','先生はテストにより、学生が理解したかどうかをチェックする。','バスによる移動は便利だが時間がかかる。','習慣は国によって違う。','努力したかどうかにより、成果も違うと思う。','服装の時代による変化について研究したい。','この薬は人によっては副作用が出ることがあります。','宗教によっては肉を食べることを禁じられている。']::text[],
   ARRAY['Dự luật này đã được quốc hội thông qua (thừa nhận).','Tôi sẽ báo cáo kết quả chẩn đoán bởi bác sỹ.','Có những tai nạn lớn xảy ra do thiếu chú ý.','Vì việc thủ tướng bị ám sát, chính trị nước A đã hỗn loạn.','Nghe nói thiệt hại do trận động đất lần này lên tới hàng triệu Yên.','Các vấn đề nên giải quyết bằng đối thoại.','Thầy giáo dựa vào việc cho bài thi, kiểm tra xem sinh viên có hiểu chưa.','Đi lại bằng xe bus thì tiện nhưng tốn thời gian.','Tập quán thì khác nhau theo từng nước.','Tôi nghĩ là tuỳ theo có nỗ lực hay không, kết quả cũng khác nhau.','Tôi muốn nghiên cứu về sự thay đổi y phục theo thời đại.','Loại thuốc này có thể có tác dụng phụ với một số người.','Có tôn giáo mà việc ăn thịt là bị cấm.']::text[]),

  ('8cfd8bee-b151-5705-a88a-1012faef7b87'::uuid, '～によると／～によれば',
   '伝聞の根拠を示す. Nghĩa: theo, y theo ~ — chỉ căn cứ của tin đồn/thông tin nghe được.',
   '今朝の新聞によると、来年度、二つの大学が新設されるそうだ。', 'Theo báo ra sáng nay, sang năm, hai trường đại học mới sẽ được thành lập.',
   ARRAY['天気予報によると、あしたは雨が降るそうです。','友達の話によれば、あの映画はとても面白いということです。']::text[],
   ARRAY['Theo dự báo thời tiết, ngày mai nghe nói sẽ mưa.','Nghe bạn tôi kể thì bộ phim đó có vẻ khá thú vị.']::text[]),

  ('5bdfa8a2-646b-5039-a65a-dd9f9a9853ee'::uuid, '～を中心に（して）／～を中心として',
   '～を真ん中にして・～を一番重要なものとして. Nghĩa: lấy ~ làm trung tâm, lấy ~ là thứ quan trọng nhất.',
   '駅を中心にたくさんの商店が集まっている。', 'Nhiều cửa hàng tập trung quanh ga.',
   ARRAY['この国は自動車産業を中心に工業を進めている。','地球は太陽を中心にして回っている。','21世紀の経済はアジアを中心として発展するでしょう。']::text[],
   ARRAY['Nước này lấy công nghiệp sản xuất ô tô làm trung tâm cho phát triển công nghiệp.','Trái đất quay quanh tâm là mặt trời.','Kinh tế thế kỷ 21 sẽ phát triển với trung tâm là Châu Á.']::text[]),

  ('76dd1cae-6d93-5532-b6ec-fb6962b5e348'::uuid, '～を問わず／～は問わず',
   '～に関係なく・～に影響されないで. Nghĩa: không kể, bất kể — không liên quan đến ~, không bị ảnh hưởng bởi ~.',
   '留学生ならどなたでも国籍、年齢、性別を問わず申し込めます。', 'Nếu là lưu học sinh, bất cứ ai, không kể quốc tịch, tuổi tác, giới tính đều có thể đăng ký.',
   ARRAY['この病院では昼夜を問わず救急患者を受け付けます。','学歴、経験は問わず、やる気のある社員を募集します。']::text[],
   ARRAY['Bệnh viện này không kể ngày đêm đều tiếp nhận bệnh nhân cấp cứu.','Không kể đến học vấn, kinh nghiệm, chúng tôi tuyển nhân viên có sự say mê.']::text[]),

  ('1bf5b207-3099-59c4-bb34-0eb2c51a94f4'::uuid, '～をはじめ／～をはじめとする',
   '一つの主な例を出す言い方. Nghĩa: cách nói đưa ra một ví dụ chính, tiêu biểu, ngụ ý còn nhiều thứ khác tương tự.',
   '上野動物園にはパンダをはじめ、子供たちに人気がある動物がたくさんいます。', 'Ở vườn thú Ueno, những động vật mà trẻ em yêu thích, như gấu trúc, có rất nhiều.',
   ARRAY['ご両親をはじめ、ご家族の皆様、お元気でいらっしゃいますか。','国会議員をはじめとする視察団が被災地を訪れた。']::text[],
   ARRAY['Hai bác nhà mình và toàn thể gia đình vẫn mạnh khoẻ chứ ạ?','Bao gồm các nghị sĩ, đoàn thị sát đã đến thăm các vùng bị thiên tai.']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('be4d2740-8b3b-5dcf-962d-868b11600255'::uuid, '～をもとに／～を元にして',
   '～を判断の基準・材料などにして. Nghĩa: lấy ~ làm cơ sở, tài liệu cho phán đoán.',
   'ファンの人気投票をもとに審査し、今年の歌のベストテンが決まります。', 'Bảng xếp hạng ca khúc top ten năm nay sẽ được quyết định dựa trên sự thẩm tra phiếu bình chọn của fan.',
   ARRAY['ノンフィクションというのは事実を元にして書かれたものです。']::text[],
   ARRAY['Loại (sách) Non fiction là loại được viết dựa trên sự thật.']::text[]),

  ('04ad6c89-1aec-5959-bc3a-0f91f9ba351c'::uuid, '～上（に）',
   '～だけでなく・～に加えて. Nghĩa: không chỉ ~, thêm vào với ~.',
   '今年のインフルエンザは高熱が出る上、せきもひどい。', 'Dịch cúm năm nay không chỉ có sốt cao, mà còn ho dữ dội nữa.',
   ARRAY['林さんのお宅でごちそうになった上、おみやげまでいただきました。','彼女は頭がいいうえに、性格もよい。','この機械は使い方が簡単なうえに、軽いので大変便利だ。','このアルバイトは好条件のうえに通勤時間も短いので、ありがたい。']::text[],
   ARRAY['Ở nhà bác Hayashi, tôi không chỉ được ăn ngon, còn được cả quà mang về nữa.','Cô ấy đã thông minh, tính cách lại tốt nữa.','Máy này không chỉ dễ sử dụng, lại nhẹ nữa nên rất tiện.','Việc làm thêm này ngoài điều kiện tốt, thời gian đi làm cũng ngắn, rất sướng.']::text[]),

  ('0b4b8464-a058-5549-b080-6159eb9c051c'::uuid, '～うちに／～ないうちに',
   'A) その間に (trong lúc..., làm việc gì đó trước khi trạng thái đó thay đổi). B) ～の間に (trong khoảng thời gian đó, xảy ra việc mà lúc đầu không có).',
   '日本にいるうちに、一度京都を訪ねたいと思っている。', 'Trong lúc còn ở Nhật, tôi định sẽ đi thăm Kyoto một lần.',
   ARRAY['子供が寝ているうちに、掃除をしてしまいましょう。','若いうちに、いろいろ経験したほうがいい。','花がきれいなうちに、花見に行きたい。','今日のうちに、旅行の準備をしておこう。','冷めないうちに、どうぞ召し上がってください。','寒かったが、走っているうちに体が暖かくなった。','彼女の話を聞いているうちに、涙が出てきました。','何度も話し合ううちに、互いの理解が深まった。','しばらく合わないうちに、日本語が上手になりましたね。']::text[],
   ARRAY['Trong khi con đang ngủ, làm xong việc dọn dẹp nào.','Khi còn trẻ, nên tích luỹ nhiều kinh nghiệm (nên có nhiều trải nghiệm).','Muốn đi ngắm hoa lúc nó còn đang đẹp.','Trong ngày hôm nay, hãy chuẩn bị cho chuyến du lịch.','Mời bác ăn ngay khi nó chưa nguội ạ.','Dù trời lạnh, trong lúc đang chạy cơ thể trở nên ấm.','Trong lúc đang nghe câu chuyện của cô ấy, tôi đã rơi nước mắt.','Nhiều lần trao đổi, sự hiểu biết lẫn nhau ngày càng sâu đậm (tăng cường).','Chỉ trong thời gian ngắn không gặp, tiếng Nhật của bác đã giỏi thế!']::text[]),

  ('6dcbe538-f87a-5430-840f-02ab7852f884'::uuid, '～おかげで／～おかげだ',
   '～ために（それが原因で、いい結果になって感謝する気持ちを表す。）Nghĩa: nhờ, do có... — biểu thị lòng biết ơn vì nhờ nguyên nhân đó mà có kết quả tốt.',
   '科学技術が発達したおかげで、我々の生活は便利になった。', 'Nhờ khoa học kỹ thuật phát triển, đời sống của chúng ta trở nên tiện lợi hơn.',
   ARRAY['家が海に近いおかげで、新鮮な魚が食べられる。','山本さんは中国語が上手なおかげで、いい仕事が見つかったそうです。','仕事が早く済んだのは、山田さんのおかげです。']::text[],
   ARRAY['Nhờ nhà em gần biển nên lúc nào cũng có cá tươi ăn.','Bác Yamamoto vì giỏi tiếng Trung Quốc nên nghe nói đã tìm được một công việc tốt.','Công việc làm xong nhanh chóng là nhờ có bác Yamada.']::text[]),

  ('adaa166d-4593-5550-89f4-c56c6a99588d'::uuid, '～かわりに',
   'A) ～をしないで: thay vì không làm ~ mà làm một việc khác. B) ～の代理で・の代用として: làm đại lý, thay thế cho ~. C) ～に相当する分だけ: chỉ có phần tương đương với ~ (đánh đổi, bù lại).',
   '私立大学を一つ受けるかわりに、国立大学を三つ受けたい。', 'Không đăng ký vào một trường tư nào, tôi muốn đăng ký 3 trường quốc lập.',
   ARRAY['音楽会に行くかわりに、CDを3枚買うほうがいいと思う。','病気の父のかわりに、私が参りました。','包帯のかわりに、ハンカチで傷口を縛った。','私が料理するかわりに、あなたは掃除してください。','この部屋は狭いかわりに、家賃が安い。','私のマンションは静かなかわりに、駅から遠くて不便だ。']::text[],
   ARRAY['Thay vì đi nghe hoà nhạc, tôi nghĩ mua 3 đĩa CD có khi tốt hơn.','Thay cho bố đang bị ốm, tôi đã đi.','Thay vì dùng băng gạc, tôi đã dùng khăn tay để băng miệng vết thương.','Em nấu ăn, anh quét nhà đi.','Căn phòng này nhỏ hẹp, tương ứng là giá thuê cũng rẻ.','Khu nhà tôi ở khá yên tĩnh, bù lại đường từ ga đến lại xa, khá bất tiện.']::text[]),

  ('11d8b93c-d18f-5ebe-ba5f-8265ea914125'::uuid, '～くらい／～ぐらい／～くらいだ／～ぐらいだ',
   'A) biểu thị mức độ trạng thái (~ đến mức...). B) biểu thị mức độ nhẹ (chí ít cũng ~).',
   '棚から物が落ちるくらい大きい地震があった。', 'Trận động đất mạnh đến mức các đồ vật bị rơi xuống từ trên giá.',
   ARRAY['この辺りは夜になると、寂しいくらい静かだ。','木村さんは楽しみにしていた旅行に行けなくなって、かわいそうなぐらいがっかりしていた。','彼くらい日本語が話せれば、通訳ができるだろう。','おなかが痛くて、がまんできないぐらいだった。','忙しくても電話を掛けるくらいはできたでしょう。','外国語は、1か月習ったぐらいでは、上手に話せるようにはならないだろう。','人に会ったら、あいさつぐらいしてほしい。']::text[],
   ARRAY['Khi đêm xuống, vùng quanh đây yên tĩnh đến cô quạnh.','Anh Kimura đã thất vọng đến tội nghiệp khi không đi được chuyến du lịch mà anh ấy đã mong chờ.','Nói được tiếng Nhật cỡ như tui, làm phiên dịch được không nhỉ?','Bụng đau đến mức không chịu được.','Dù bận nhưng ít ra một cuộc điện thoại anh cũng gọi được chứ?','Ngoại ngữ thì học cỡ một tháng không thể giao tiếp giỏi được.','Tôi muốn anh khi gặp mọi người, chí ít cũng phải chào hỏi.']::text[]),

  ('adba2ced-32cf-54ce-9253-63a6d0c53582'::uuid, '～最中に／～最中だ',
   '何かをしているちょうどその時に. Nghĩa: ngay trong lúc đang làm việc gì đó.',
   '考えている最中に、話しかけられて困った。', 'Đang nghĩ, cứ bị nói xen vào, đến khổ.',
   ARRAY['試合の最中に、雨が降ってきた。','その事件については、今調査している最中です。']::text[],
   ARRAY['Giữa trận đấu, trời lại đổ mưa.','Về vụ tai nạn này, bây giờ đang điều tra.']::text[]),

  ('b0de3c0d-9b20-52b2-926c-e509a4e2cdff'::uuid, '～次第',
   '～したら、すぐ（～が終わったらすぐ後のことをすることを表す。）Nghĩa: ngay khi ~ — chỉ việc làm ngay sau khi ~ kết thúc.',
   '新しい住所が決まり次第、連絡します。', 'Ngay sau khi quyết định được địa chỉ mới, chúng tôi sẽ liên lạc.',
   ARRAY['向こうに着き次第、電話をしてください。','雨がやみ次第、出発しましょう。','12時に式が終わります。終了次第パーティーを始めますから、皆様ご参加ください。']::text[],
   ARRAY['Ngay sau khi đến nơi, hãy gọi điện nhé.','Ngay sau khi mưa tạnh, xuất phát nhé.','Buổi lễ sẽ kết thúc lúc 12h. Ngay sau khi kết thúc sẽ bắt đầu liên hoan, mọi người cùng tham gia nhé.']::text[]),

  ('83440e36-c0e8-5348-ae59-ac6c1b5fb8d9'::uuid, '～せいだ／～せいで／～せいか',
   'ために（それが原因で悪い結果になったことを表す。）Nghĩa: tại vì ~ — do nguyên nhân đó mà có kết quả xấu.',
   '私が失敗したのは、彼のせいだ。', 'Tôi thất bại là tại thằng ấy.',
   ARRAY['電車が遅れたせいで、遅刻した。','甘いものが好きなせいで、食べ過ぎて太ってしまった。','暑いせいか、食欲がない。','気のせいか、彼は今日は何となく元気がなく感じられた。','写真がうまく撮れなかったのをカメラのせいにしている。']::text[],
   ARRAY['Vì tàu chậm nên tôi đã đến muộn.','Tại vì thích ăn đồ ngọt, tôi đã ăn nhiều quá và phát phì.','Trời nóng, chả cá thèm ăn.','Tôi có cảm tưởng hôm nay anh ấy cứ không khoẻ làm sao ấy.','Ảnh chụp không được đẹp là do camera.']::text[]),

  ('de24af09-ce78-51e3-9cd9-12a84e2d15c3'::uuid, '～たとたん（に）',
   '～するとすぐに. Nghĩa: ngay sau ~.',
   '犯人は警官の姿を見たとたん、逃げ出した。', 'Ngay khi thấy bóng cảnh sát, tên phạm nhân đã chạy trốn.',
   ARRAY['疲れていたので、ベッドに入ったとたんに、眠ってしまった。','先生はいつもベルが鳴ったとたんに、教室に入ってくる。']::text[],
   ARRAY['Vì mệt quá, lên giường cái là ngủ mất ngay.','Thầy giáo lúc nào cũng vào lớp ngay sau khi chuông kêu.']::text[]),

  ('fecf43ad-1cd9-56c3-84b1-50d6991ed506'::uuid, '～たび（に）',
   '～する時はいつも. Nghĩa: mỗi khi, mỗi dịp ~.',
   'その歌を歌うたび、幼い日のことを思い出す。', 'Mỗi lần nghe bài hát đó, tôi lại nhớ về những ngày thơ ấu.',
   ARRAY['人は新しい経験をするたびに、何かを学ぶ。','私は旅行のたびに、絵葉書を買います。','その川は大雨のたびに、水があふれて被害が起きている。']::text[],
   ARRAY['Con người mỗi khi có một trải nghiệm mới, đều học được điều gì đó.','Tôi mỗi lần đi du lịch đều mua bưu ảnh.','Con sông đó mỗi lần mưa lớn, nước dâng lên gây ra thiệt hại.']::text[]),

  ('0f965e51-bdba-5f79-92b8-086e2979c5b8'::uuid, '～て以来',
   'それから後ずっと. Nghĩa: suốt từ đó về sau… Sử dụng với những việc diễn ra liên tục từ một thời điểm trong quá khứ cho đến hiện tại.',
   '日本に来て以来、日本に対する考え方が少しずつ変わってきた。', 'Từ ngày đến nước Nhật, cách nghĩ của tôi về Nhật Bản cũng thay đổi dần dần từng chút một.',
   ARRAY['昨年夏に手紙を受け取って以来、彼から連絡がまったくない。','そのことがあって以来、彼は彼女に好意をもつようになった。']::text[],
   ARRAY['Từ khi nhận được thư hè năm ngoái, hoàn toàn không có thông tin gì về anh ấy cả.','Kể từ khi xảy ra chuyện đó, anh ấy đã có cảm tình với cô ấy.']::text[]),

  ('422637ac-2be5-57e6-bf68-cb2483b22929'::uuid, '～とおり（に）／～どおり（に）',
   '～と同じに. Nghĩa: làm giống như ~.',
   '説明書に書いてあるとおりにやってみてください。', 'Hãy thử làm như được viết trong bản hướng dẫn.',
   ARRAY['あの人の言ったとおりにすれば、大丈夫です。','彼はA大学に合格した。私の思ったとおりだった。','矢印のとおりに進んでください。','その企画は計画どおりには進まなかった。','予想どおり、Aチームが優勝した。']::text[],
   ARRAY['Nếu làm như ông kia nói thì không sao cả.','Anh ấy đã đỗ vào đại học A. Đúng như tôi đã nghĩ.','Hãy tiến theo hướng mũi tên chỉ.','Kế hoạch đó đã không đi theo dự định.','Đúng như dự đoán, đội A đã vô địch.']::text[]),

  ('02785054-b90e-57c4-823d-7c37ddb975b4'::uuid, '～ところに／～ところへ／～ところを',
   'そういう時に／そういう場へ／そういう場面を. Nghĩa: đúng lúc, đúng địa điểm, đúng hoàn cảnh ấy…',
   'ちょうど金さんのうわさをしているところに、本人がやって来た。', 'Vừa lúc đang tán gẫu về anh Kim, thì anh ấy đã đến.',
   ARRAY['これから寝ようとしたところへ、友達が訪ねてきた。','いいところへ来ましたね。今ちょうどスイカを切ったんです。一緒に食べましょう。','こっそりタバコを吸っているところを、妹に見られた。']::text[],
   ARRAY['Đang định đi ngủ thì bạn lại đến chơi.','Đến đúng lúc thế nhỉ. Tớ vừa bổ dưa hấu này. Cùng ăn nào!','Đang lúc hút thuốc lá trộm lại bị cô em bắt gặp.']::text[]),

  ('dcc89bc9-11ac-559d-9700-deb776657468'::uuid, '～ほど／～ほどだ／～ほどの',
   'A) ～くらい（程度を表す。）: chừng, mức ~. B) ～が一番・・・だ（dùng ở dạng ～ほど・・・はない）: ~ là nhất.',
   '会場にはあふれるほど、ギターを持った若者が集まっていた。', 'Các thanh niên mang đàn ghi ta tụ tập đông đến mức tràn ngập cả hội trường.',
   ARRAY['子供をなくしたご両親の悲しみが痛いほど分かる。','私にも言いたいことが山ほどある。','久しぶりに国の母の声を聞いて、うれしくて泣きたいほどだった。','持ちきれないほどの荷物があったのでタクシーで帰った。','仲のいい友達と旅行するほど楽しいことはない。','彼女ほど頭のいい人には会ったことがない。','戦争ほど悲惨なものはない。']::text[],
   ARRAY['Tôi hiểu được nỗi đau buồn của những bậc cha mẹ mất con.','Những điều tôi muốn nói nhiều như núi.','Đã lâu mới được nghe giọng nói của mẹ từ trong nước, tôi hạnh phúc đến muốn khóc.','Nhiều hành lý đến mức mang không xuể, tôi đi taxi về nhà.','Đi chơi với bạn thân (tốt) là vui nhất.','Tôi chưa gặp ai thông minh như cô ấy.','Không có gì bi thảm bằng chiến tranh.']::text[]),

  ('074c29ad-b1a7-5397-a22c-e803f8bf57c9'::uuid, '～ばかりに',
   '～だけのために（それだけが原因で悪い結果になった残念な気持ちを表す。）Nghĩa: chỉ vì ~ — biểu thị tâm trạng tiếc vì chỉ tại nguyên nhân đó mà trở thành kết quả xấu.',
   'うそをついたばかりに恋人に嫌われてしまった。', 'Chỉ tại nói dối mà bị người yêu ghét/giận.',
   ARRAY['お金がないばかりに大学に進学できなかった。','日本語が下手なばかりに、いいアルバイトが探せません。','長女であるばかりに、弟や妹の世話をさせられる。']::text[],
   ARRAY['Chỉ vì thiếu tiền mà không học lên đại học được.','Chỉ tại kém tiếng Nhật nên không tìm được việc làm thêm tốt.','Chỉ vì là chị gái lớn mà tôi phải giúp hết em trai đến em gái.']::text[]),

  ('d13193ab-9376-5d91-99eb-1d128c2ad1b8'::uuid, '～ものだから',
   '～ので（理由。言い訳の時よく使う。）Nghĩa: tại vì ~ — hay dùng khi nói lý do, phân trần, biện bạch.',
   '事故で電車が遅れたものですから、遅くなってすみません。', 'Do tai nạn nên tàu bị trễ, tôi xin lỗi vì đã đến muộn.',
   ARRAY['日本の習慣を知らないものですから、失礼なことをするかもしれません。','あまり悲しかったものだから、大声で泣いてしまった。','家が狭いものですから、大きい家具は置けません。','一人っ子なものだから、わがままに育ててしまいました。']::text[],
   ARRAY['Vì không biết tập quán của Nhật, có thể làm điều thất lễ chăng.','Vì điều không đáng buồn mấy mà khóc rống lên.','Do nhà chật nên không bày biện đồ gia dụng gì to được.','Vì là con một nên (tôi) lớn lên khá ích kỷ.']::text[]),

  ('ee7e301d-9344-507b-925b-95e909465bd7'::uuid, '～ように／～ような',
   'A) （例を表す。）biểu thị ví dụ, như là ~. B) （目標を表す。）chỉ mục tiêu. Ngoài ra còn dùng để: so sánh/ví dụ, suy đoán, mệnh lệnh gián tiếp, biến đổi.',
   'ここに書いてあるように申込書に記入してください。', 'Hãy điền vào đơn đăng ký như viết ở mẫu này.',
   ARRAY['東京のように人口が集中すると、交通渋滞は避けられない。','ケーキのような甘いものはあまり好きではありません。','この本は小学生でも読めるようにルビがつけてあります。','予定通り終わるように計画を立ててやってください。','風邪を引かないように気をつけてください。','魚のように泳ぎたい。','彼は部屋にいないようです。','ここに、タバコを吸わないようにと書いてある。','自転車に乗れるようになりました。']::text[],
   ARRAY['Cứ tập trung dân số như ở Tokyo, khó mà tránh khỏi giao thông ùn tắc.','Tôi không thích những thứ ngọt như bánh ga tô.','Cuốn sách này, để cho học sinh tiểu học cũng đọc được, phiên âm được đính vào.','Hãy lập lịch để có thể kết thúc theo kế hoạch.','Hãy cẩn thận để không bị trúng gió.','Tôi muốn bơi như cá. (Ví dụ)','Anh ấy dường như không có trong phòng. (Suy đoán)','Ở đây có ghi là không hút thuốc. (Mệnh lệnh gián tiếp)','Tôi đã biết đi xe đạp. (Biến đổi)']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('74403438-1728-5da6-aae7-216051b284ab'::uuid, '～一方だ',
   '（その傾向がますます進むことを示す。）Nghĩa: diễn tả việc xu hướng đó ngày càng tiếp diễn. Sử dụng cùng với động từ chỉ sự thay đổi.',
   '最近、パソコン通信の利用者は増える一方だ。', 'Gần đây người dùng máy tính để trao đổi thông tin ngày càng tăng lên.',
   ARRAY['都市の環境は悪くなる一方なのに、若者は都会にあこがれる。','最近英語を使わないので、忘れる一方で困っている。']::text[],
   ARRAY['Dù môi trường đô thị ngày càng xấu đi, giới trẻ vẫn mơ ước sống nơi đô hội.','Gần đây vì không sử dụng tiếng Anh, quên ngày càng nhiều, thật khổ.']::text[]),

  ('0dc53113-6a7c-5cce-b145-edae7f422710'::uuid, '～おそれがある',
   '～する心配がある. Nghĩa: có sự lo lắng là ~, e là ~.',
   '早く手術しないと、手遅れになる恐れがある。', 'Nếu không phẫu thuật nhanh, e là muộn mất.',
   ARRAY['台風がこのまま北上すると、日本に上陸する恐れがある。','こんなに赤字が続くと、この会社は倒産の恐れがある。','この病気は伝染の恐れはありません。']::text[],
   ARRAY['Nếu bão vẫn cứ tiến theo hướng Bắc như thế này, có khả năng sẽ đổ bộ vào Nhật Bản.','Cứ tiếp tục thua lỗ như thế, công ty này có ngày phá sản.','Căn bệnh này không lo bị truyền nhiễm.']::text[]),

  ('917cc76e-220b-5483-bb52-d0c164e256cd'::uuid, '～ことになっている',
   '（予定・規則などを表す。）Nghĩa: biểu thị dự định, quy tắc… Khi dùng ý chỉ quy tắc, được dùng nhiều cùng với các từ ngữ như CẤM CHỈ, CHO PHÉP.',
   '今度の日曜日には、友達と会うことになっています。', 'Chủ Nhật tới tôi định gặp mặt bạn bè.',
   ARRAY['この寮では、玄関は12時に閉まることになっている。','法律で、子供を働かせてはいけないことになっている。','この席はタバコを吸ってもいいことになっている。']::text[],
   ARRAY['Ở khu ký túc xá này, cửa vào đóng lúc 12h.','Theo pháp luật, cấm bắt trẻ em phải lao động.','Ở ghế này, hút thuốc lá cũng được.']::text[]),

  ('62735d76-82f7-5e51-a68d-b559c3b527b9'::uuid, '～ことはない',
   '～する必要はない. Nghĩa: không cần phải làm ~.',
   '時間は十分あるから、急ぐことはない。', 'Vẫn có đủ thời gian, không cần phải vội.',
   ARRAY['旅行かばんならわざわざ買うことはありませんよ。私が貸してあげます。','検査の結果、異常ありませんでしたから心配することはありませんよ。']::text[],
   ARRAY['Vali du lịch thì không cần phải lo mua đâu. Tớ cho mượn.','Vì kết quả kiểm tra không có gì khác thường nên không cần lo lắng đâu.']::text[]),

  ('ed4c8c54-0f96-5d0c-8d1f-1c66a4904774'::uuid, '～しかない',
   '～ほかに方法がない・～しなければならない. Nghĩa: không có cách nào khác ngoài ~; cần phải làm ~.',
   '事故で電車が動かないから、歩いて行くしかない。', 'Do tai nạn nên tàu không chạy, chả có cách nào khác là đi bộ.',
   ARRAY['だれにも頼めないから、自分でやるしかありません。','約束したのだから、行くしかないだろう。']::text[],
   ARRAY['Không nhờ ai được, tự mình phải làm thôi.','Đã hẹn rồi, phải đi thôi.']::text[]),

  ('b5bf7b83-ce89-5b9e-a4bb-cff2490b208c'::uuid, '～ということだ',
   'A) ～ということを聞いた（伝聞。聞いたことをそのまま引用する言い方。）: nghe thấy nói là ~ (cách nói dẫn dụng y nguyên điều nghe được; văn thư tín dùng とのこと thay vì ということだ). B) ～という意味だ: có nghĩa là ~.',
   '新聞によると、また地下鉄の運賃が値上げされるということだ。', 'Theo báo nói, giá vé tàu điện ngầm lại bị tăng lên.',
   ARRAY['事故の原因はまだわからないということです。','天気予報によると今年は雨が多いだろうということです。','A社の就職には推薦状が必要だということです。','母の手紙では、父の病気はたいしたことはないとのことなので、安心した。','道子さんが結婚なさったとのこと、おめでとうございます。','「あしたは、ちょっと忙しいんです。」「えっ。じゃ、パーティーには来られないということですか。」','ご意見がないということは賛成ということですね。']::text[],
   ARRAY['Nghe nói vẫn chưa biết nguyên nhân của tai nạn.','Nghe dự báo thời tiết thì năm nay mưa nhiều đấy.','Thấy nói là để xin việc ở công ty A cần phải có thư giới thiệu.','Trong thư mẹ viết, bệnh của bố không có vấn đề gì nên tôi thấy yên tâm.','Nghe nói là chị Michiko đã kết hôn, xin chúc mừng ạ.','"Mai tớ bận tí." "Thế à. Thế nghĩa là không đến liên hoan à?"','Không có ý kiến gì tức là tán thành phải không ạ.']::text[]),

  ('9fad7ab0-1d4a-5af6-8365-914a013cad80'::uuid, '～まい／～まいか',
   'A) ～ないだろう（否定の推量を表す。）: có lẽ không phải ~ (thể hiện suy đoán phủ định). B) 絶対～するのをやめよう（否定の意志を表す。）: tuyệt đối muốn từ bỏ việc ~ (chỉ ý muốn phủ định). Chủ ngữ thường là "tôi"; ngôi thứ 3 dùng dạng ～まいと思っているらしい/ようだ.',
   'あの民族紛争は容易に解決するまいと思うが、平和的解決への努力が必要だ。', 'Tuy tôi nghĩ là cuộc phân tranh sắc tộc đó không dễ giải quyết nhưng những nỗ lực để giải quyết một cách hoà bình là cần thiết.',
   ARRAY['彼はベテランの登山家だから、あんな低い山で遭難することはあるまい。','小さな地震が続いている。大きな地震が起こるのではあるまいか。','こんなまずいレストランへは二度と来るまい。','ケーキは買うまいと思っても、見るとつい買ってしまう。','彼は何も言うまいと思っているらしい。']::text[],
   ARRAY['Ông ấy là nhà leo núi nhiều kinh nghiệm nên việc gặp nạn trên núi thấp cỡ đó chắc là không có đâu.','Vẫn tiếp diễn các địa chấn nhỏ, chắc là không có việc xảy ra động đất lớn.','Cái nhà hàng tồi cỡ này thì không muốn đến lần thứ hai.','Đã định không mua bánh ngọt rồi, nhìn thấy lại sơ ý mua mất.','Hình như anh ấy không định nói gì.']::text[]),

  ('a639da1f-8b8f-5b2d-9751-786159697347'::uuid, '～わけがない／～わけはない',
   '～（の）はずがない. Nghĩa: không có nghĩa là ~, không chắc ~.',
   'あんな下手な絵が売れるわけがない。', 'Bức tranh tệ thế không chắc đã bán được.',
   ARRAY['チャンさんは中国人だから漢字が書けないわけがありません。','あんなやせた人が、相撲とりのわけがない。','ここは海から遠いので、魚が新鮮なわけはない。']::text[],
   ARRAY['Vì anh Chan là người Trung Quốc nên không lí gì lại không viết được chữ Hán.','Người gầy cỡ này thì không thể là lực sĩ Sumo được.','Chỗ này ở xa biển nên cá không thể tươi được.']::text[]),

  ('256e8bf6-7e89-5cef-9b96-2ca27fcb4c93'::uuid, '～わけにはいかない／～わけにもいかない',
   'A) 理由があって～できない: có lý do nên không làm ~ được. B) ～しなければならない: phải làm ~.',
   '絶対にほかの人に言わないと約束したので、話すわけにはいかない。', 'Vì đã hứa là tuyệt đối không nói với người khác nên không thể kể được.',
   ARRAY['帰りたいけれども、この論文が完成するまでは帰国するわけには行かない。','一人でやるのは大変ですが、みんな忙しそうなので、手伝ってもらうわけにもいきません。','あした試験があるので、勉強しないわけにはいかない。','家族がいるから、働かないわけにはいかない。']::text[],
   ARRAY['Dù muốn về nhưng tuy nhiên, đến khi hoàn thành luận văn này thì không về nước được.','Làm một mình thì khó khăn nhưng vì mọi người cũng đang bận rộn, nên không nhờ ai được.','Vì ngày mai có bài thi nên không thể không học được.','Vì có gia đình nên không đi làm không được.']::text[]),

  ('81b0db01-98ae-5b1d-80c7-e5191aff4639'::uuid, '～から～にかけて',
   '～から～までの間に（時間・場所の大体の範囲を表す。）Nghĩa: từ khoảng ~ đến ~ — chỉ chung phạm vi thời gian, địa điểm.',
   '昨夜から今朝にかけて雨が降りました。', 'Trời đã mưa từ đêm qua đến sáng nay.',
   ARRAY['台風は毎年、夏から秋にかけて日本を襲う。','関東地方から東北地方にかけて、大きな地震があった。','一丁目から三丁目にかけて、道路工事が行われている。']::text[],
   ARRAY['Các cơn bão hàng năm đổ bộ vào Nhật từ mùa hè đến mùa thu.','Đã có động đất mạnh trong khu vực từ Kanto đến Tohoku.','Đang tiến hành làm đường từ khu phố 1 đến khu phố 3.']::text[]),

  ('72fa61cf-d235-5ba7-9a95-783c9a4499a7'::uuid, 'たとえ～ても／たとえ～でも',
   'もし～ても. Nghĩa: ví dụ; nếu như; dù cho; ngay cả nếu; tỉ như ~ thì vẫn ~.',
   '自分で決めた道だから、たとえ失敗しても後悔しない。', 'Vì con đường đi do tôi tự quyết định nên nếu có thất bại thì cũng không hối tiếc.',
   ARRAY['たとえ難しくてもやりがいのある仕事をしたい。','この仕事は、たとえ困難でも最後まで頑張らなければならない。','たとえお世辞でも、子供をほめられれば親はうれしいものだ。']::text[],
   ARRAY['Cho dù có khó khăn thì tôi vẫn muốn làm những công việc có nhiều thử thách.','Công việc này, dù cho có vất vả khó khăn, vẫn cần phải cố gắng đến cùng.','Ngay cả nếu là lời nịnh nọt, con được khen là bố mẹ vẫn sướng.']::text[]),

  ('4486b45f-2f83-5c4e-bf43-1b73db957c34'::uuid, '～さえ～ば',
   '（それだけあれば／なければ、後ろの状態が成立する。）Nghĩa: chỉ cần có ~ hay thành ~, trạng thái sau đó sẽ được thành lập.',
   'インスタントラーメンはお湯を入れさえすれば食べられる便利な食品だ。', 'Mì ăn liền là thứ đồ ăn tiện lợi, chỉ cần cho nước nóng vào là ăn được.',
   ARRAY['道が込みさえしなければ、駅までタクシーで10分ぐらいだ。','交通が便利でさえあれば、この辺も住みやすいのだが。','建設的なご意見でさえあれば、どんな小さなものでも大歓迎です。','住所さえわかれば、地図で探していきます。','あなたのご都合さえよければ、今度の日曜日のコンサートのチケットを買っておきます。','体さえ丈夫なら、どんな苦労にも耐えられると思う。','言葉さえ共通なら、お互いにもっとコミュニケーションがよくできたでしょう。']::text[],
   ARRAY['Chỉ cần đường không đông, đi taxi đến ga mất chừng 10 phút.','Chỉ cần giao thông tiện lợi, sống ở quanh đây cũng dễ.','Miễn là ý kiến có tính xây dựng, dù ít dù nhiều cũng rất hoan nghênh.','Biết địa chỉ thì đi tìm bằng bản đồ ngay.','Chỉ cần anh thấy thuận lợi, em sẽ mua sẵn vé xem hoà nhạc Chủ Nhật tới ạ.','Chỉ cần cơ thể khoẻ mạnh, tôi nghĩ là khổ đến mấy cũng chịu được.','Thậm chí chỉ cần chung tiếng nói, giao tiếp lẫn nhau sẽ tốt hơn nhiều.']::text[]),

  ('d3c375f5-c444-52a2-bdea-bc03fb182ab2'::uuid, '～も～ば～も／～も～なら～も',
   '～も～し、～も（前に述べたことの上に後のことを加える時の表現。プラスとプラス、またはマイナスとマイナスの言葉が使われる。）Nghĩa: cũng ~ cũng ~ — mẫu câu dùng khi thêm một việc nữa vào những điều trình bày đằng trước, các từ ngữ tiêu cực + tiêu cực hoặc tích cực + tích cực được sử dụng.',
   '父はお酒も飲めばタバコも吸うので、健康が心配だ。', 'Bố rượu cũng uống, thuốc cũng hút, vì thế nên sức khoẻ rất đáng lo.',
   ARRAY['新しくできたレストランは値段も安ければ味もいいと評判です。','彼は歌も上手なら踊りもうまい、パーティーの人気者だ。']::text[],
   ARRAY['Nhà hàng mới mở có tiếng là giá vừa rẻ, khẩu vị cũng ngon.','Anh ấy hát cũng hay, nhảy cũng giỏi, rất được yêu mến ở buổi tiệc.']::text[]),

  ('792bbf45-d4ab-59a2-a63a-5e1830d763e1'::uuid, '～やら～やら',
   '～や～など. Nghĩa: liệt kê nhiều thứ, nhiều việc.',
   '帰国前は飛行機を予約するやらおみやげを買うやらで忙しい。', 'Trước khi về nước, tất bật với đặt vé máy bay, mua quà lưu niệm…',
   ARRAY['お酒を飲みすぎて、頭が痛いやら苦しいやらで、大変だった。','部屋を借りるのに敷金やら礼金やら、たくさんお金を使った。']::text[],
   ARRAY['Uống quá nhiều rượu, đau đầu, mệt mỏi, đến là sợ.','Lúc thuê nhà tốn bao nhiêu là tiền, nào thì tiền đặt cọc, tiền lễ…']::text[]),

  ('79dfd539-f264-59f6-b1c4-f0f3fd3bb1df'::uuid, '～だらけ',
   '～がたくさんある・～がたくさんついている（汚いもの、いやなものがたくさんあったり、表面についたりしていることを表す。）Nghĩa: ~ có đầy, được gắn đầy — nói về những thứ bẩn, đáng ghét có đầy hoặc đang dính đầy.',
   'このレポートは字が間違いだらけで読みにくい。', 'Bản báo cáo này đầy chữ đánh nhầm, đọc khó.',
   ARRAY['事故現場に血だらけの人が倒れている。','畳の上に座って食事をしたら、ズボンがしわだらけになってしまった。','世界各地を旅行したので、私の旅行かばんはきずだらけだ。']::text[],
   ARRAY['Ở hiện trường vụ tai nạn, một người dính đầy máu đang nằm bất tỉnh.','Nếu ngồi trên chiếu mà ăn thì quần sẽ đầy nếp nhăn.','Vì đi du lịch nhiều nơi trên thế giới nên vali du lịch của tôi đầy vết xước.']::text[]),

  ('b18dba91-a707-501d-9c7c-11545cc0d4f2'::uuid, '～っぽい',
   'A) ～のように感じる・～のように見える: cảm thấy như là ~; thấy như là ~. B) ～しやすい・よく～する: dễ làm ~.',
   'このテーブルは高いのに安っぽく見える。', 'Cái bàn này dù đắt nhưng nhìn rẻ tiền.',
   ARRAY['あの黒っぽい服を着た人はだれですか。','彼女はいたずらっぽい目で私を見た。','あの子はまだ中学生なのに、とても大人っぽい。','彼は怒りっぽいけれど、本当は優しい人です。','最近忘れっぽくなったのは、年のせいだろう。']::text[],
   ARRAY['Người mặc bộ quần áo trông đen đen kia là ai?','Cô ta nhìn tôi với con mắt đầy tinh quái.','Thằng nhỏ đó tuy vẫn là học sinh trung học nhưng trông rất người lớn.','Anh ấy là người dễ nổi nóng nhưng thực ra là người rất hiền lành.','Gần đây mau quên thế là tại tuổi cao rồi chăng?']::text[]),

  ('87c3f6a3-91df-5663-92d5-4a49c80176ed'::uuid, '～がたい',
   '～するのは難しい・なかなか～することができない. Nghĩa: khó làm ~; gần như không thể ~.',
   '彼女がそんなことをするのは、信じがたい。', 'Cô ấy đến việc đó mà cũng làm được, thật khó tin.',
   ARRAY['この仕事は私には引き受けがたい。','幼い子供に対する犯罪は許しがたい。','あした帰国するが、仲良くなった友達と別れがたい気持ちで一杯だ。']::text[],
   ARRAY['Công việc này với tôi thật khó đảm nhận.','Tội phạm đối với trẻ nhỏ là không thể tha thứ được.','Ngày mai về nước rồi nhưng vẫn đầy tâm trạng khó chia tay với những người bạn tốt.']::text[]),

  ('5f85e3b8-45e9-597a-a36e-c2e474a6655b'::uuid, '～がちだ／～がちの',
   '～することが多い・～しやすい. Nghĩa: việc làm ~ là nhiều; dễ làm; có chiều hướng ~. Hay được dùng với nghĩa xấu.',
   '雪が降ると、電車は遅れがちだ。', 'Khi tuyết rơi, tàu thường hay trễ.',
   ARRAY['彼は最近、体調を崩して、日本語のクラスを休みがちです。','春は曇りがちの日が多い。','母は病気がちなので、あまり働けない。']::text[],
   ARRAY['Anh ấy gần đây do cơ thể không khoẻ, hay nghỉ lớp học tiếng Nhật.','Mùa xuân thì những ngày râm mát nhiều.','Mẹ hay ốm nên chẳng làm việc được mấy.']::text[]),

  ('5fb295b1-250c-5589-9d92-113a71996c03'::uuid, '～気味',
   '少し～の感じがある. Nghĩa: hơi có cảm giác là ~.',
   '仕事が忙しくて、最近少し疲れ気味だ。', 'Vì công việc bận nên gần đây hơi thấy mệt.',
   ARRAY['このごろ、太り気味だから、ジョギングを始めた。','［日本語能力試験］が近づいたので、焦り気味だ。','昨日から風邪気味で、頭が痛い。']::text[],
   ARRAY['Gần đây vì thấy hơi béo lên, tôi đã bắt đầu chạy bộ.','Kỳ thi năng lực tiếng Nhật đã đến gần, tôi thấy hơi sốt ruột/vội vàng.','Từ hôm qua hơi bị trúng gió nên đầu bị đau.']::text[]),

  ('3849c416-5eaa-53c3-85ef-3b00b31965ef'::uuid, '～げ',
   '～そう（見てその人の気持ちが感じられる様子を表す。）Nghĩa: chỉ trạng thái cảm nhận được về tâm trạng của một người khi nhìn vào họ.',
   '彼女は悲しげな様子で話した。', 'Cô ấy đã nói chuyện với dáng vẻ buồn thảm.',
   ARRAY['彼は寂しげに、一人で公園のベンチに座っていた。','老人が、何か言いたげに近づいて来た。','彼は得意げな顔で、みんなに新しい家を見せた。']::text[],
   ARRAY['Anh ta ngồi một mình trên ghế đá công viên với vẻ khá cô đơn.','Ông lão như muốn nói gì đó đã tiến lại gần.','Anh ấy đã giới thiệu với mọi người về nhà mới với vẻ khá đắc ý.']::text[]),

  ('140f881f-f9a7-5fc5-9e1d-d656a31326b3'::uuid, '～かけだ／～かけの／～かける',
   '～し始めて、まだ～終わっていない途中の状態を表す。Nghĩa: chỉ trạng thái giữa chừng, mới bắt đầu ~, chưa kết thúc ~.',
   'この仕事はやりかけですから、そのままにしておいてください。', 'Công việc này mới bắt đầu làm nên cứ để như thế.',
   ARRAY['テーブルの上に飲みかけのコーヒーが置いてある。','何か言いかけてやめるのはよくない。','私は子供のころ、病気で死にかけたことがあるそうだ。']::text[],
   ARRAY['Trên bàn có đặt một cốc café uống dở.','Nói cái rồi thôi là không tốt.','Hình như lúc bé có lần bị ốm gần chết.']::text[]),

  ('7789a2ae-6ab9-5f87-b72b-5804d8b8d670'::uuid, '～きる／～きれる／～きれない',
   'すっかり～する／最後まで～できる／最後まで～できない. Nghĩa: hoàn toàn, hết cả ~ / đến cuối cùng có thể, không thể ~.',
   '木村さんは疲れきった顔をして帰って来た。', 'Anh Kimura với bộ mặt mệt phờ đã về.',
   ARRAY['42.195キロを走りきるのは大変なことだ。','そんなにたくさん食べきれますか。','数えきれないほどたくさんの星が光っている。']::text[],
   ARRAY['Chạy hết 42.195 km quả là gian nan.','Ăn bao nhiêu hết sạch cả thế này à.','Các vì sao nhiều không đếm hết đang toả sáng (trên bầu trời).']::text[]),

  ('52481372-d585-571e-b6eb-92a9bb273562'::uuid, '～ぬく',
   '最後まで頑張って～する・非常に～する. Nghĩa: đến cùng — cố gắng đến cuối cùng làm ~ / làm ~ một cách phi thường.',
   '途中、失敗もありましたが、何とかこの仕事をやりぬくことができました。', 'Giữa chừng tuy cũng có thất bại, nhưng dù thế nào thì công việc này đã được làm đến cùng.',
   ARRAY['戦争の苦しい時代を生きぬいてきた人たちは、精神的にも強い。','これは考えぬいて、出した結論です。','ジョンさんは、困りぬいて相談に来た。']::text[],
   ARRAY['Những người sống sót sau thời kỳ chiến tranh khổ cực thì tinh thần cũng rất mạnh mẽ.','Đây là kết luận rút ra sau khi đã suy nghĩ đến cùng.','Anh John đã đến để trao đổi với tôi khi đã đến đường cùng.']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('8461602d-154e-5ec3-b1b8-c5f5019c8e69'::uuid, '～こそ／～からこそ',
   '強調を表す. Nghĩa: thể hiện ý nhấn mạnh.',
   '今度こそ試合に勝ちたい。', 'Muốn thắng trận trong chính năm nay.',
   ARRAY['これこそみんながほしいと思っていた製品です。','「どうぞよろしく。」「こちらこそ。」','あなたが手伝ってくれたからこそ、仕事が早くできたのです。']::text[],
   ARRAY['Đây chính là mặt hàng mà chúng tôi nghĩ mọi người đang mong đợi.','"Mong bác giúp đỡ ạ!" "Chính tôi mới cần anh giúp ạ."','Chính vì nhờ có anh giúp đỡ, công việc mới làm xong nhanh.']::text[]),

  ('77b4f91c-ed61-5c6a-a0ba-4642619e4072'::uuid, '～さえ／～でさえ',
   '～も・～でも（特に、ある極端なものを例に出して、他のものも、[もちろん～]という時に使う。）Nghĩa: lấy cái ví dụ cực đoan, đáo để để diễn đạt những thứ khác (ở mức độ thấp hơn) là đương nhiên. Khi gắn さえ vào danh từ, trợ từ が, を được tỉnh lược; các trợ từ khác thì giữ nguyên.',
   'そこは電気さえない山奥だ。', 'Chỗ đó ở tít trong núi, đến điện cũng không có.',
   ARRAY['急に寒くなって、今朝はもうコートを着ている人さえいた。','専門家でさえわからないのだから、私たちには無理でしょう。','親にさえ相談しないで、結婚を決めた。','私の故郷は地図にさえ書いてない小さな村です。']::text[],
   ARRAY['Trời trở lạnh quá, sáng nay đã có người mặc đến áo khoác.','Đến chuyên còn không hiểu thì chúng ta chịu thôi.','Đến bố mẹ còn trả trao đổi, đã định cưới rồi.','Quê tôi là một làng nhỏ đến không cả có tên trên bản đồ.']::text[]),

  ('ca07e76b-c745-54a5-be8a-efc20cbd1279'::uuid, '～など／～なんか／～なんて',
   'A) （例としてあげ、表現を軽く、やわらかくしたい時に使う。）: dùng khi muốn nêu lên một ví dụ để làm nhẹ, đánh giá thấp. B) （あまりたいしたものでないと軽視した気持ちや否定的に言う時に使う。）: dùng khi nói mang tính phủ định hoặc coi nhẹ một thứ là không quan trọng lắm. なんか/なんて chủ yếu dùng khi nói chuyện (văn nói).',
   '「この機械に詳しい人はいませんか。」「彼など詳しいと思いますよ。」', '"Có ai biết tường tận về cái máy này không?" "Tôi nghĩ như anh ấy là người biết rõ đấy."',
   ARRAY['ネクタイなんかしめて、どこ行くの。','お見舞いならカーネーションなんてどうかしら。','忙しくて、テレビなど見ていられない。','本当です。うそなんかつきませんよ。','スキーなんて簡単ですよ。だれでもすぐできるようになります。']::text[],
   ARRAY['Thắt ca vát thế này, đi đâu vậy?','Đi thăm người ốm thì tôi phân vân xem là như (mua) hoa cẩm chướng (carnation) có được không?','Bận ghê, đến như cả xem TV còn chả được.','Đúng thật đấy ạ. Không nói mấy lời dối trá đâu.','Cỡ như trượt tuyết thì dễ không mà. Ai cũng biết trượt tuyết ngay.']::text[]),

  ('4ff96bde-949b-55f7-bde5-62010d6f9679'::uuid, '～に関して（は）／～に関しても／～に関する',
   '～について（の）. Nghĩa: liên quan đến, về ~.',
   '計画変更に関しては、十分検討する必要がある。', 'Cần phải kiểm tra kỹ càng về việc thay đổi kế hoạch.',
   ARRAY['外国へ行くなら言葉だけでなく、習慣に関しても知っておいたほうがいい。','経済に関する本はたくさんある。']::text[],
   ARRAY['Đi ra nước ngoài thì không chỉ là ngôn ngữ, cũng nên biết về tập quán của họ.','Có rất nhiều sách liên quan đến kinh tế.']::text[]),

  ('b3743175-3ba4-55f2-b20c-41584e7e80aa'::uuid, '～に加えて／～に加え',
   '～の上にさらに. Nghĩa: ngoài ra; thêm vào đó.',
   '電気代に加えて、ガス代までが値上がりした。', 'Giá điện rồi đến giá gas cũng tăng lên.',
   ARRAY['大気汚染が進んでいることに加え、海洋汚染も深刻化してきた。']::text[],
   ARRAY['Thêm vào việc ô nhiễm không khí ngày càng tiếp diễn, ô nhiễm biển đã nghiêm trọng hơn.']::text[]),

  ('b9855857-1ce7-53fa-80e1-e1b739a31536'::uuid, '～に答えて／～にこたえ／～にこたえる／～にこたえた',
   '～に応じて（ほかからのはたらきかけに応じる。）Nghĩa: ứng với, đối với ~ — đáp ứng với tác động từ bên ngoài.',
   '社員の要求にこたえて、労働時間を短縮した。', 'Đáp ứng yêu cầu của nhân viên, thời gian làm việc đã được rút ngắn.',
   ARRAY['国民の声にこたえた政策が期待されています。']::text[],
   ARRAY['Một chính sách đáp ứng tiếng nói của nhân dân đang được kỳ vọng.']::text[]),

  ('dcc94866-8278-5fbc-9e5b-45d458fab014'::uuid, '～に沿って／～に沿い／～に沿う／～に沿った',
   '～に従って・～のとおりに. Nghĩa: sở dĩ, vì vậy, do vậy, theo ~.',
   '決まった方針に沿って、新しい計画を立てましょう。', 'Theo phương châm đã quyết định, hãy lập kế hoạch mới.',
   ARRAY['東京都では新しい事業計画に沿い、新年度予算を立てている。','皆様のご希望に沿う結果が出るように努力いたします。','国益に沿った外交政策が進められている。']::text[],
   ARRAY['Ở Tokyo theo quy hoạch mới, dự toán ngân sách năm tài chính mới đang được lập.','Xin nỗ lực để đạt kết quả như hi vọng của mọi người.','Chính sách ngoại giao phù hợp với lợi ích quốc gia đang được áp dụng.']::text[]),

  ('843e56f6-7498-5c28-91f3-e40bbd75e4f2'::uuid, '～に反して／～に反し／～に反する／～に反した',
   '～と反対に・～と逆に. Nghĩa: trái ngược với; tương phản với.',
   '神の意向に反して、人間は自然を破壊している。', 'Trái với ý hướng của thần linh, con người đang phá hoại tự nhiên.',
   ARRAY['人々の予想に反し、土地の値段が下がりつづけている。','弟は、親の期待に反することばかりしている。','予想に反した実験結果が出てしまった。']::text[],
   ARRAY['Ngược với dự đoán của nhiều người, giá đất đang tiếp tục giảm.','Em tớ toàn làm những việc trái với mong đợi của bố mẹ.','Kết quả thực nghiệm đã trái với dự kiến.']::text[]),

  ('5f8e77a7-de5a-5b71-9b66-64e268f9c313'::uuid, '～に基づいて／～に基づき／～に基づく／～に基づいた',
   '～を基礎にして・～を根拠にして. Nghĩa: lấy ~ làm cơ sở, căn cứ.',
   '調査した資料に基づいて、レポートを書かなければならない。', 'Cần phải viết báo cáo dựa trên các tư liệu đã điều tra.',
   ARRAY['実際にあった事件に基づき、この映画が作られた。','彼の意見は、長い経験に基づくものだから納得できる。','虚偽の証言に基づいたこの裁判を認めることはできない。']::text[],
   ARRAY['Bộ phim này đã được làm ra dựa trên sự cố đã có trong thực tế.','Ý kiến của anh ấy dựa trên kinh nghiệm lâu dài nên có thể tin cậy được.','Không thể công nhận sự kết án dựa trên lời khai nguỵ tạo này được.']::text[]),

  ('32b4a3e9-e90d-50f9-826f-4daff0de76f9'::uuid, '～にわたって／～に渡り／～にわたる／～にわたった',
   '時間的、空間的にその範囲全体に広がっていることを表す。Nghĩa: biểu thị sự trải rộng trên phạm vi toàn thể mang tính thời gian, không gian.',
   '陳さんは病気のため、2か月に渡って学校を休んだ。', 'Anh Trần do bị bệnh nên đã nghỉ học trong suốt hai tháng.',
   ARRAY['西日本全域にわたり、台風の被害を受けた。','兄は5時間にわたる大手術を受けた。','広範囲にわたった海の汚染が、問題になっている。']::text[],
   ARRAY['Suốt cả vùng phía tây Nhật Bản đã gánh chịu sự phá hoại của bão.','Anh trai đã phải phẫu thuật trong suốt 5 giờ đồng hồ.','Biển ô nhiễm trong cả phạm vi rộng lớn thực sự là vấn đề (nghiêm trọng).']::text[]),

  ('3fe7a7f3-f3ee-5c6c-b3cf-0bdef57d61c3'::uuid, '～ばかりか／～ばかりでなく',
   '～だけでなく・その上. Nghĩa: không chỉ ~, ngoài ra còn…',
   '林さんのお宅でごちそうになったばかりか、おみやげまでいただいた。', 'Ở nhà anh Hayashi, không chỉ được ăn ngon mà còn có cả quà mang về nữa.',
   ARRAY['アンナさんは頭がいいばかりでなく、親切で心の優しい人です。','この地方は気候が穏やかなばかりでなく、海の幸、山の幸にも恵まれている。','彼はサッカーばかりでなく、水泳もダンスも上手なんですよ。']::text[],
   ARRAY['Cô Ana không chỉ thông minh, lại là người chu đáo, dịu dàng.','Khu vực này không chỉ có khí hậu ôn hoà, còn được trời phú cho hải sản và rau quả trên núi nữa.','Anh ấy không chỉ bóng đá mà còn bơi, nhảy đều giỏi.']::text[]),

  ('ad6d170d-972c-5c40-94f0-c91dc1e343d9'::uuid, '～はもとより／～はもちろん',
   '～は、言う必要がないくらい当然で. Nghĩa: ~ thì đương nhiên đến mức không cần nói. So với ～はもちろん thì ～はもとより là cách nói trang trọng hơn.',
   '私が生まれた村は、電車はもとより、バスも通っていない。', 'Ngôi làng mà tôi đã sinh ra thì xe điện là đương nhiên, xe bus cũng không lưu thông.',
   ARRAY['地震で被害を受けた人々の救援のために、医者はもとより、多くのボランティアも駆けつけた。','病気の治療はもちろん、予防のための医学も重要だ。']::text[],
   ARRAY['Để cứu viện cho những người chịu thiệt hại của động đất, ban đầu là bác sĩ, sau là nhiều tình nguyện viên cũng đã đến gấp.','Việc trị bệnh đương nhiên là cần thiết nhưng y học dự phòng cũng quan trọng.']::text[]),

  ('110dd542-cf98-5797-a447-02d58948b232'::uuid, '～もかまわず',
   '～を気にしないで・～に気を使わず平気で. Nghĩa: không bận tâm đến ~ / dửng dưng không đếm xỉa đến ~.',
   '人の迷惑もかまわず、電車の中で携帯電話で話している人がいる。', 'Không cần quan tâm đến việc làm phiền người khác, vẫn có người nói chuyện di động trong tàu điện.',
   ARRAY['弟は家族の心配もかまわず、危険な冬山へ行こうとする。','子供は服がぬれるのもかまわず、川の中に入って遊んでいる。','ところかまわず、ごみを捨てる人がいて困る。']::text[],
   ARRAY['Em trai không nghĩ đến sự lo lắng của gia đình, định đi đến khu núi tuyết đầy nguy hiểm.','Trẻ con không bận tâm đến quần áo bị ướt, đang nhảy xuống sông chơi.','Đến khổ vì có người chả cần biết ở đâu, vứt rác bừa.']::text[]),

  ('8e54813b-653e-528d-ab40-34f6f73f3952'::uuid, '～をこめて',
   '気持ちをその中に入れて. Nghĩa: gửi gắm tâm tư, tình cảm vào ~.',
   '母は私のために心をこめて、セーターを編んでくれた。', 'Gửi gắm tất cả tình cảm của mình, mẹ đã đan cho tôi chiếc áo len.',
   ARRAY['怒りをこめて、核実験反対の署名をした。','病気回復の祈りをこめて、みんなで鶴を折った。']::text[],
   ARRAY['Mang sự phẫn nộ, tôi đã ký tên phản đối thử bom hạt nhân.','Mọi người gấp hạc giấy gửi vào đó sự cầu mong được lành bệnh.']::text[]),

  ('d83478d4-31e5-526e-b3ee-96446f360edc'::uuid, '～を通じて／～を通して',
   'A) その期間始めから終わりまでずっと: trong khoảng thời gian đó từ đầu đến cuối, liên tục. B) 直接ではなく、何かを間に入れて: không trực tiếp, thông qua trung gian nào đó.',
   'あの地方は、1年を通じて雨が多い。', 'Ở địa phương đó, trong suốt năm mưa nhiều.',
   ARRAY['彼は一生を通して日本との友好のために働いた。','社長を忙しいから、秘書を通じて頼んだほうがいい。','今はインターネットを通して世界中の情報が手に入る。']::text[],
   ARRAY['Ông ấy đã làm việc suốt đời vì tình hữu nghị với Nhật Bản.','Vì chủ tịch công ty bận, nên nhờ thông qua thư ký.','Bây giờ thông qua Internet mà có được thông tin của toàn thế giới.']::text[]),

  ('f0bbd3b6-0f36-5982-b720-7aa48a97637d'::uuid, '～をめぐって／～をめぐる',
   '～を中心にそれに関係あることについて. Nghĩa: nói về quan hệ liên quan đến trung tâm là ~, quanh ~.',
   'その法案の賛否をめぐって、活発な議論が交わされた。', 'Vì tán thành hay phủ quyết dự luật đó mà những thảo luận sôi nổi đã được trao đổi.',
   ARRAY['その事件をめぐって、様々なうわさが流れている。','この小説は、1人の女性をめぐって、5人の男性が戦う話です。']::text[],
   ARRAY['Có nhiều lời đồn đa dạng quanh sự kiện đó.','Cuốn tiểu thuyết này là câu chuyện nói về năm người đàn ông đã giao tranh vì một người phụ nữ.']::text[]),

  ('5fd772ab-852e-500c-a46f-69576c71637c'::uuid, '～あまり',
   '非常に～ので. Nghĩa: vì ~ bất thường nên…',
   '子供の将来を思うあまり、厳しすぎることを言ってしまった。', 'Chỉ vì nghĩ đến tương lai của con mà tôi đã lỡ nói lời quá nghiêm khắc.',
   ARRAY['彼は働きすぎたあまり、過労で倒れてしまった。','科学者である小林さんは実験に熱心なあまり、昼食をとるのを忘れることもしばしばある。','驚きのあまり、声も出なかった。']::text[],
   ARRAY['Làm việc quá nhiều nên anh ấy đã bất tỉnh vì quá sức.','Vì nhà khoa học Kobayashi đã rất nhiệt huyết trong thực nghiệm, nhiều lần ông ấy quên cả ăn trưa.','Vì quá ngạc nhiên mà tôi đã không thốt lên lời.']::text[]),

  ('7742ff4b-2662-54c3-bed4-d52e66214d01'::uuid, '～一方／～一方で（は）',
   '～のに対して（対比を表す。）Nghĩa: mặt khác, trái lại… (thể hiện sự so sánh).',
   '私の仕事は夏は非常に忙しい一方、冬は暇になる。', 'Công việc của tôi thì trái với mùa hè bận túi bụi, mùa đông lại nhàn hạ.',
   ARRAY['日本の工場製品の輸出国である一方、原材料や農産物の輸入国でもある。','彼女は女優として活躍する一方で、親善大使として貧しい子供たちのために世界中を回っている。','A国は天然資源が豊かな一方で、それを活用できるだけの技術がない。','地球上には豊かな人がいる一方では、明日の食べ物もない人がいる。']::text[],
   ARRAY['Nhật Bản là nước xuất khẩu các mặt hàng công nghệ, trái lại lại là nước nhập khẩu nguyên liệu và nông sản.','Hoạt động như một nữ diễn viên, nhưng mặt khác cô ấy cũng đi vòng quanh thế giới vì trẻ em nghèo trong vai trò là đại sứ thiện chí.','Nước A có tài nguyên thiên nhiên phong phú nhưng lại không có kỹ thuật để khai thác tận dụng chúng.','Trên thế giới có những người giàu, ngược lại cũng có những người không có cả thức ăn cho ngày mai.']::text[]),

  ('e4ca7e6a-87bb-5edd-97cb-4457b7320752'::uuid, '～上で（は）／～上の／～上でも／～上での',
   'A) ～してから: xong ~ rồi… B) （その時、その場面、その条件の範囲で～だ、と言いたい時に使う。）: dùng khi muốn nói trong phạm vi của thời điểm đó, hoàn cảnh đó, điều kiện đó ~.',
   'みんなの意見を聞いた上で決めました。', 'Nghe ý kiến của mọi người xong rồi quyết định.',
   ARRAY['内容をご確認の上で、サインをお願いいたします。','熟慮の上の結論です。','日本の会社で働く上で、注意しなければならないことは何でしょうか。','法律の上では、現実には不平等なことがある。','酒の上でも、言ってはいけないことがある。','立春は暦の上での春です。']::text[],
   ARRAY['Sau khi xác nhận nội dung, anh vui lòng ký tên ạ.','Đây là kết luận sau khi đã cân nhắc kỹ lưỡng.','Làm việc trong xã hội Nhật Bản, điều cần chú ý là gì ạ?','Trong pháp luật thì là bình đẳng, hiện thực thì vẫn có những điều bất công.','Ngay cả lúc uống rượu, cũng có những điều không được nói.','Lập xuân là mùa xuân trên lịch.']::text[]),

  ('3f93139c-7329-5354-a390-fa53ab2e2d0b'::uuid, '～限り（は）／～かぎりでは／～ないかぎり（は）',
   'A) ～する間は・～するうちは（dùng dạng ～かぎり（は））: giới hạn, hạn chế, trong phạm vi/khoảng thời gian ~ (chừng nào còn ~). B) 範囲を示す（dùng dạng ～かぎりでは）: chỉ phạm vi được biết/nghe. C) 限界まで（dùng dạng ～かぎり）: cho đến giới hạn, hết mức có thể. D) ～なければ（điều kiện, dùng dạng ～ないかぎり（は））: nếu không ~.',
   '日本にいるかぎり、丹さんは私に連絡してくれるはずだ。', 'Chừng nào còn ở Nhật, anh Đan chắc chắn sẽ liên lạc với tôi.',
   ARRAY['いくら批判されても、視聴率が高いかぎり、この番組は中止されないでしょう。','学生であるかぎり、勉強するのは当然だ。','父は元気なかぎりは、働きたいと言っている。','私が知っているかぎりでは、この本は今年一番よく売れたそうです。','電話で話したかぎりでは、彼はそんなに怒っていませんでしたよ。','時間の許すかぎり、話し合いを続けましょう。','遭難者を救うために、救助隊はできる限りのことをした。','力のかぎり頑張ろう。','雨や雪が降らないかぎり、毎日ジョギングを欠かさない。','来週、仕事が忙しくないかぎり、クラス会に参加したい。','魚は新鮮でないかぎり、刺身にはできない。','彼はよほど重病でないかぎりは、会社を休んだことがない。']::text[],
   ARRAY['Dù bị phê phán thế nào, chừng nào tỉ lệ người xem còn cao, chương trình này không thể dừng lại được.','Còn là học sinh thì đương nhiên phải học rồi.','Bố tôi nói là chừng nào còn khoẻ thì vẫn muốn làm việc.','Trong phạm vi tôi được biết thì cuốn sách này nghe nói là được bán chạy nhất trong năm nay.','Cứ như nói chuyện trên điện thoại thì anh ấy không giận thế đâu.','Trong giới hạn thời gian cho phép, chúng ta hãy tiếp tục trao đổi.','Để cứu giúp người bị nạn, đội cứu trợ đã làm hết sức có thể.','Hãy cố gắng hết sức!','Nếu mưa hay tuyết không rơi, tôi sẽ không bỏ chạy hàng ngày.','Tuần sau, nếu công việc không bận, em muốn tham gia lớp học.','Cá mà không tươi thì không làm món sashimi được.','Ông ấy mà không bị bệnh nặng thì không có chuyện nghỉ làm ở công ty.']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('6c34ada8-0c7f-5d88-ac0a-17741abe020b'::uuid, '～（か）と思うと／～（か）と思ったら',
   '～するとすぐ. Nghĩa: làm xong ~ ngay lập tức…, vừa thấy là ~ thì.',
   'リーさんは［さようなら］と言ったかと思うと教室を飛び出していった。', 'Vừa thấy cô Li nói [Sayounara] xong đã chạy biến ra khỏi phòng học.',
   ARRAY['空が暗くなったかと思ったら、大粒の雨が降ってきた。','ドンと音がしたと思ったら、トラックが壁にぶつかっていた。']::text[],
   ARRAY['Trời vừa tối đen cái là mưa như trút.','Vừa thấy có tiếng don một cái là xe tải đã húc vào tường.']::text[]),

  ('342be15f-8a32-5ec9-930c-6a459f9eb1a7'::uuid, '～か～ないかのうちに',
   '～とほぼ同時に（一つのことが終わったかどうかはっきりしないうちに、続いてすぐ次のことが起きる。）Nghĩa: việc này chưa qua, việc khác đã xảy ra.',
   'ヘビースモーカーの彼は、タバコを1本吸い終わったか終わらないかのうちに、また次のタバコに火をつけた。', 'Người nghiện thuốc nặng như anh ấy thì điếu này còn cháy dở đã châm điếu khác.',
   ARRAY['チャイムが鳴るか鳴らないかのうちに、先生が教室に入って来た。']::text[],
   ARRAY['Chưa biết chuông kêu hay chưa, thầy giáo đã đến vào lớp.']::text[]),

  ('c50ccc0f-9ed1-5553-85bb-723d459aea5d'::uuid, '～からいうと／～からいえば／～からいって',
   '～の点で見ると. Nghĩa: nhìn từ quan điểm ~.',
   '中国は人口からいうと世界一だが、人口密度は日本よりずっと低い。', 'Trung Quốc nói về dân số thì đứng đầu thế giới, nhưng mật độ dân số thấp hơn Nhật nhiều.',
   ARRAY['品質からいえば、これが一番いいけれど、値段がちょっと高い。','実力からいって、彼女が入賞することは間違いない。']::text[],
   ARRAY['Về chất lượng mà nói, cái này là tốt nhất rồi nhưng giá hơi đắt.','Xét về thực lực mà nói, việc cô ấy nhận giải thưởng không có gì phải bàn cãi cả.']::text[]),

  ('5dc620c8-15c8-59d7-920d-a68535c83c66'::uuid, '～からといって',
   '～だけの理由で. Nghĩa: chỉ vì lý do ~; tuy nhiên; tuy thế mà; không nhất thiết; với lý do là.',
   'お金があるからといって偉いわけではない。', 'Chỉ vì có tiền thì không có nghĩa là người giỏi giang.',
   ARRAY['一度や二度失敗したからといって、あきらめてはいけない。','安いからといって、そんなにたくさん買っても無駄だ。','便利だからといって、機械に頼りすぎないようにしたい。','子供だからといって、わがままを許すのは教育上よくない。']::text[],
   ARRAY['Chỉ vì một hai lần thất bại thì không được bỏ cuộc.','Rẻ thì rẻ nhưng mua nhiều đến thế này thì đúng là lãng phí.','Tuy tiện lợi nhưng tôi vẫn không muốn dựa quá nhiều vào máy móc.','Chỉ vì là trẻ con mà được phép ích kỷ thì xét về giáo dục là không tốt.']::text[]),

  ('d3204ecb-749b-5898-acd0-d8bb814f5bb2'::uuid, '～から見ると／～から見れば／～から見て（も）',
   '～から考えると. Nghĩa: nhìn từ ~, xét theo ~.',
   '子供の教育という点からみると、豊かすぎる生活は、必ずしもいいとは言えない。', 'Nhìn từ quan điểm giáo dục trẻ em, chưa hẳn cuộc sống quá sung túc là tốt.',
   ARRAY['昨日の首相の発言から見れば、彼はこの法案に否定的な考えを持っているようだ。','あの様子から見て、彼は、昨晩飲みすぎたようだ。','どこから見ても、あの人は紳士だ。']::text[],
   ARRAY['Xét theo phát ngôn của thủ tướng ngày hôm qua, có vẻ như ông ấy có ý phủ quyết dự luật này.','Nhìn cái bộ dạng kia kia, anh ta chắc là đêm qua quá chén rồi.','Dù theo khía cạnh nào, ông kia là người lịch thiệp.']::text[]),

  ('37845388-102d-5abb-a12e-8a60aa26ab74'::uuid, '～きり（だ）',
   'A) ～だけ: chỉ có ~. B) ～たままの状態が続いている: trạng thái ~ cứ thế tiếp diễn (trong văn nói dùng ～っきり).',
   '彼女は、何を聞いても笑っているきりで、答えない。', 'Cô ấy nghe gì cũng chỉ cười, chả đáp lại lời nào.',
   ARRAY['今朝コーヒーを飲んだきりで、何も食べていない。','子供たちが独立してから、夫婦二人きりの生活です。','寝たきり老人が増えている。','あの人は、アメリカへ行ったきりだ。']::text[],
   ARRAY['Sáng nay chỉ có uống café, chả ăn gì.','Con cái mà ra ở riêng, chỉ có hai vợ chồng sống với nhau.','Người già ốm nằm liệt giường đang tăng lên.','Người kia đi Mỹ vẫn chưa về.']::text[]),

  ('a42e83c5-1b8c-551a-9e00-65c1a3b54d23'::uuid, '～くせに',
   '～のに・～にもかかわらず（軽蔑・非難する気持ちを表す。）Nghĩa: dù; mặc dầu; lại còn; ngay cả ~ — diễn tả tâm trạng khinh miệt, quở trách. Ít dùng khi nói trang trọng.',
   'よく知らないくせに、あの人は何でも説明したがる。', 'Dù là chả biết mấy, ông kia cái gì cũng muốn giải thích.',
   ARRAY['彼は、若いくせにすぐ疲れたと言う。','父は下手なくせにカラオケが大好きなんです。','彼は学生のくせに高級車に乗っている。']::text[],
   ARRAY['Anh ấy dù là trẻ nhưng hơi tí là kêu mệt.','Bố tôi dù hát dở nhưng rất khoái karaoke.','Anh ta dù là sinh viên nhưng toàn lên xe xịn.']::text[]),

  ('d9c79c98-8177-5019-8af1-13df14f67502'::uuid, '～ことから',
   'ので（その理由を述べて後ろの文の根拠を示す。）Nghĩa: bởi vì ~ — nói lí do là căn cứ cho câu sau.',
   '道がぬれていることから、昨夜、雨が降ったことがわかった。', 'Vì là đường ướt nên biết là đêm qua trời mưa.',
   ARRAY['二人が一緒に仕事をしたことから、交際が始まった。','この鳥は目のまわりが白いことから、メジロと呼ばれている。','この村の老人が皆元気なことから、村の食習慣が体にいいと考えられている。']::text[],
   ARRAY['Hai người đã làm việc cùng nhau nên đã bắt đầu thiết lập quan hệ.','Con chim này quanh mắt màu trắng nên được gọi là chim mắt trắng (目白).','Những người già trong làng này đều khoẻ mạnh, có thể hiểu là tập quán ăn uống của làng này tốt cho cơ thể.']::text[]),

  ('67c058b5-f614-5748-8785-335198fc0a61'::uuid, '～ことに（は）',
   '（話者の気持ち・感情を先に述べて強調する時に使う。）Nghĩa: đặc biệt là; một cách đặc biệt — nhấn mạnh trước cảm tình, tâm trạng người nói.',
   '驚いたことに、私の祖父と恋人のおじいさんは小学校時代の友達だったそうだ。', 'Ngạc nhiên quá cơ, nghe nói ông tôi và ông của người yêu lại là bạn hồi tiểu học.',
   ARRAY['ありがたいことに、奨学金がもらえることになった。','火事になったが、幸いなことには火はすぐ消し止められた。']::text[],
   ARRAY['Vui thế chứ, thế là đã nhận được học bổng.','Đám cháy đã xảy ra nhưng may ơi là may, lửa bị dập tắt ngay.']::text[]),

  ('1c9fbc04-eceb-5c40-86a5-6ff11df13ed5'::uuid, '～上（は）／～上も／～上の',
   '～の視点から考えて. Nghĩa: xét từ quan điểm ~.',
   '京都には歴史上有名なお寺が数多くある。', 'Kyoto xét về mặt lịch sử thì có rất nhiều chùa nổi tiếng.',
   ARRAY['これは理論上は可能だが、実用化には時間がかかりそうだ。','男女差別は法律上も許されない。','健康上の理由で会社を辞めた。']::text[],
   ARRAY['Cái này về lý thuyết thì có thể đấy, nhưng làm thực tế thì có vẻ tốn thời gian.','Phân biệt nam nữ thì về mặt pháp luật cũng không được phép.','Vì lí do về mặt sức khoẻ nên đã nghỉ làm.']::text[]),

  ('0bdd119f-70b9-5011-8e5c-769cac70abee'::uuid, '～た末（に）／～た末の／～の末（に）',
   '長い間～をしたあとで. Nghĩa: rất lâu sau khi ~.',
   'いろいろ考えた末、会社を辞めることにした。', 'Sau khi đã suy nghĩ rất nhiều, tôi đã nghỉ việc.',
   ARRAY['苦労した末の成功は、何よりもうれしいものだ。','長期にわたる論議の末に、入試制度が改革されることになった。']::text[],
   ARRAY['Thành công sau rất nhiều gian khó thử thách thì hạnh phúc hơn bất cứ thứ gì.','Sau quá trình tranh luận lâu dài, chế độ thi tuyển đã được cải thiện.']::text[]),

  ('8f5a53ef-c933-5d66-9ede-2a00dec9377e'::uuid, '～たところ',
   '～たら（あることをしたら、その結果がどうなったかを表す表現。）Nghĩa: sau ~ (sau khi làm cái đó thì kết quả sẽ như thế nào đó).',
   '新しいワープロを使ってみたところ、とても使いやすかった。', 'Thử dùng cái máy tính mới xong mới biết là nó dễ sử dụng thế.',
   ARRAY['コンピューターが動かず、どうしていいか困っていたところ、山田さんが助けてくれた。']::text[],
   ARRAY['Máy tính trục trặc, khốn khổ không biết làm thế nào thì được bác Yamada giúp.']::text[]),

  ('da25d60c-c1c4-559b-a1c2-522b362cab91'::uuid, '～ついでに',
   '（あることをする時にその機会を利用してもう一つのこともすることを表す。）Nghĩa: nhân tiện; tiện thể — lúc làm việc gì đó, lợi dụng cơ hội đó làm một việc khác.',
   '銀行へ行くついでにこの手紙を出してくれませんか。', 'Tiện thể đến ngân hàng anh gửi cho em lá thư này được không ạ?',
   ARRAY['デパートへ買い物に行ったついでに、着物の展示会を見て来た。','買い物のついでに本屋に寄った。']::text[],
   ARRAY['Tiện thể đi siêu thị mua đồ, tôi đã đến xem triển lãm kimono.','Tiện thể đi mua sắm, tôi đã ghé vào hiệu sách.']::text[]),

  ('3040e16c-734e-5a29-ad1c-4d5490083ddb'::uuid, '～というと／～といえば',
   'A) （その話題に関係する代表的なものを取り上げる時に使う。）: lấy ví dụ tiêu biểu, đại diện liên quan đến chủ đề ~. B) （ある話題から思い出したこと、連想したことを取りあげる時に使う。）: từ một chủ đề nhớ ra, liên tưởng đến ~.',
   'スポーツの祭典というと、まずオリンピックですね。', 'Nói về ngày hội thể thao thì trước hết phải là Olympic nhỉ?',
   ARRAY['古典芸能といえば、何といっても歌舞伎でしょう。','昨日、ジョンさんに会いましたよ。そうですか。ジョンさんといえばA社に就職が決まったそうですね。','イタリアといえば、パスポートを落として困ったことを思い出した。','最近水道の水がまずいですね。水がまずいといえば、最近浄水器が出たそうですよ。']::text[],
   ARRAY['Về nghệ thuật cổ điển, nói gì thì nói phải là Kabuki.','Hôm qua, tớ gặp anh John đấy. Thế à, anh John à, hình như đã được nhận vào làm ở công ty A.','Nói về Italia, lại nhớ cái lần khốn khổ vì mất hộ chiếu.','Gần đây nước máy chán nhỉ. Nước chán à, gần đây mới có loại máy lọc hay lắm đấy.']::text[]),

  ('23d271c5-1079-5eba-9172-47540aa60bea'::uuid, '～といったら',
   '（感嘆・驚き・期待はずれの感情（プラス、マイナスの両方）を表す。）Nghĩa: nói về cảm xúc thán phục, ngạc nhiên, ngoài mong đợi (cả tiêu cực và tích cực).',
   '息子の部屋の汚いことといったら、ひどいものです。', 'Về độ bẩn của phòng con giai tôi thì rất kinh khủng.',
   ARRAY['その景色の美しさといったら、口で言い表せないほどです。']::text[],
   ARRAY['Nói về cái đẹp của cảnh sắc ở đấy thì chả lời nào tả được.']::text[]),

  ('7aba60a4-1e30-56cb-84b3-8ff2770dc4c8'::uuid, '～というより',
   '（～だが、それよりむしろ～と言ったほうが適切だと言い直す時に使う。）Nghĩa: là ~, nhưng cái nói đằng sau mới là thích đáng hơn.',
   '彼の言い方は勧めているというより、強制しているようだ。', 'Cách nói của anh ta có vẻ là đang thuyết phục nhưng thực ra là đang cưỡng ép mọi người.',
   ARRAY['冷房がききすぎて、涼しいというより寒い。','あの人はきれいというより上品だ。','あの人は学者というよりタレントだ。']::text[],
   ARRAY['Điều hoà bật mạnh quá, lạnh chứ không phải mát nữa.','Người kia nói là quý phái thì đúng hơn là đẹp.','Bảo ông kia là học giả, nhưng phải gọi là ngôi sao truyền hình mới đúng.']::text[]),

  ('f8efbc69-a93b-5167-aa1c-8eefb58ec8ba'::uuid, '～ば～ほど',
   '（一方の程度が高くなると、もう一方の程度も高くなる。）Nghĩa: càng ~ càng ~ — mặt này có mức độ cao lên, thêm một mặt khác cũng có mức độ cao lên.',
   '練習すればするほど上手になります。', 'Càng luyện tập thì càng giỏi.',
   ARRAY['給料は高ければ高いほどいいですね。','歯の治療は早ければ早いほどいい。','家庭の電気製品は操作が簡単なら簡単なほどいい。','有名人であればあるほどストレスも大きいのではないだろうか。']::text[],
   ARRAY['Lương càng cao càng tốt.','Chữa răng thì càng nhanh càng tốt.','Đồ điện trong gia đình thì sử dụng càng đơn giản càng tốt.','Chả phải càng nổi tiếng thì sức ép càng nhiều sao.']::text[]),

  ('51643c2b-e39f-569a-bf44-59fd6b1b2c98'::uuid, '～ほど',
   '（一方の程度が変わると、一緒に他方の程度も変化する。）Nghĩa: mặt này có mức độ thay đổi, cùng lúc một mặt khác cũng thay đổi mức độ.',
   '相撲では、太っているほど有利だ。', 'Sumo thì càng béo càng có lợi.',
   ARRAY['値段が高いほど品物がいいとは限らない。','推理小説は複雑なほど面白い。','頭がいい人ほど自慢しない。']::text[],
   ARRAY['Không hẳn cứ giá cao thì hàng tốt đâu.','Tiểu thuyết trinh thám thì càng phức tạp càng hấp dẫn.','Người càng thông minh càng không tự mãn.']::text[]),

  ('2048a890-2bd9-57ca-ba42-bccc0bd9072a'::uuid, '～かのようだ／～かのような／～かのように',
   '実際にはそうではないが、～のようだ. Nghĩa: thực tế thì không phải vậy nhưng có vẻ như là ~.',
   '激しい雨と風は、まるで台風が来たかのようだ。', 'Gió mưa dữ dội quá, như là bão về thật ấy.',
   ARRAY['彼はそのことについては、何も知らないかのような顔をしている。','不動産屋は、その土地が交通の便がいいかのように宣伝していた。','1か月ぶりに会った彼は、病気だったかのようにやつれていた。','彼は自分の考えが絶対であるかのように主張して譲らない。']::text[],
   ARRAY['Anh ta với vấn đề này thì ngoài mặt tỏ ra như là chả biết cái gì.','Văn phòng bất động sản thì tuyên truyền như là giao thông ở khu vực đó thì tiện lắm.','Sau một tháng không gặp mà anh ta tiều tuỵ như là vừa ốm dậy.','Anh ta thì chả nhường ai cả, khư khư với cách nghĩ của mình là tuyệt đối.']::text[]),

  ('43c4dc99-b104-5bb9-9b14-893e801c6329'::uuid, '～つつある',
   '（だんだん）＋ている. Nghĩa: dần dần đang ~. Chủ yếu dùng trong văn viết.',
   '景気は徐々に回復しつつある。', 'Tình hình đang từ từ được khôi phục.',
   ARRAY['問題は改善されつつあるが、時間がかかりそうだ。','事件の真相は明らかになりつつある。','失われつつある伝統文化を守ろうと努力している人もいる。']::text[],
   ARRAY['Vấn đề đang được cải thiện đấy, nhưng có vẻ còn mất thời gian.','Chân tướng của sự việc đang dần trở nên rõ ràng.','Vẫn có những người đang nỗ lực để bảo vệ văn hoá truyền thống đang dần mai một.']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('a6d6b6ca-b76e-5e42-8987-7e7c6bc3db60'::uuid, '～てたまらない／～てしようがない',
   '非常に～（前に感情・感覚を表す言葉がきて、それを押さえられない様子を表す。）Nghĩa: không thể kìm nén được (một cảm giác/cảm xúc). Chủ ngữ giới hạn ở ngôi thứ nhất.',
   '頭痛がしてたまらないので、近くの病院に行った。', 'Do đau đầu không chịu được tôi đã phải đi bệnh viện gần nhà.',
   ARRAY['家族からの手紙を読んでいたら、声が聞きたくてたまらなくなった。','大学に合格して、うれしくてたまらない。','買ったばかりの時計をなくしてしまって、残念でたまらない。','ビデオカメラが欲しくてしようがない。','窓を開けると、電車の声がうるさくてしようがない。']::text[],
   ARRAY['Lúc đang đọc thư nhà, thèm nghe tiếng nói ở nhà thế.','Đỗ đại học, không thể kìm được sung sướng.','Cái đồng hồ vừa mới mua lại bị mất, tiếc ơi là tiếc.','Thèm một cái máy quay phim quá cơ.','Khi mở cửa sổ ra, không thể chịu nổi tiếng ồn của tàu điện.']::text[]),

  ('84967df5-38fc-5e83-939f-18187cd3d726'::uuid, '～てならない',
   '非常に～（ある気持ちが自然に強くなってくる状態を表す。）Nghĩa: một cách phi thường — chỉ cảm xúc mạnh lên một cách tự nhiên.',
   '交通事故で両親を亡くした子供がかわいそうに思えてならない。', 'Không thể kìm lòng trước những đứa trẻ mất bố mẹ do tai nạn giao thông.',
   ARRAY['国の家族のことが思い出されてならない。','久しぶりに国の友達に会うのでうれしくてならない。','母の病気が心配でならない。']::text[],
   ARRAY['Không thể kìm được nỗi nhớ gia đình ở trong nước.','Tôi không thể kìm được sung sướng khi đã lâu mới gặp được người bạn trong nước.','Bệnh tình của mẹ không thể không lo lắng được.']::text[]),

  ('7e27e51b-904e-562a-a05d-528fe4e8ae69'::uuid, '～にきまっている',
   '必ず～だ・当然～だと思う. Nghĩa: nhất định là, đương nhiên là. Hay dùng trong văn nói.',
   'ぜんぜん練習していないんだから、今度の試合は負けるにきまっている。', 'Vì chả luyện tập tí nào, trận đấu năm nay nhất định là thua.',
   ARRAY['実力から見て、Aチームが勝つにきまっている。','注文服だから、高いにきまっている。','そんなうまい話はうそにきまっていますよ。']::text[],
   ARRAY['Nhìn vào thực lực thì đội A nhất định thắng.','Quần áo đặt mà, đắt là phải.','Nói dễ nghe thế này nhất định là điêu.']::text[]),

  ('18880439-52b8-543f-b677-bd88f1294a7c'::uuid, '～にすぎない',
   'ただ～だけだ・それ以上のものではない. Nghĩa: chỉ, không nhiều hơn ~.',
   '私は警官としてしなければならないことをしたにすぎません。', 'Tôi đã chỉ làm những việc cần làm với tư cách cảnh sát.',
   ARRAY['男女平等と言われているが、法律上平等であるにすぎない。','来年大地震があるというのは、うわさにすぎない。','これは少年犯罪の一例にすぎない。']::text[],
   ARRAY['Được nói là bình đẳng nam nữ đấy nhưng chỉ là bình đẳng trên luật pháp thôi.','Nói là sang năm có động đất lớn thì chỉ là tin đồn không hơn.','Đó chỉ là một ví dụ về tội phạm thiếu niên thôi.']::text[]),

  ('df73635e-28bf-55c6-83f8-0cbcee5270d6'::uuid, '～に相違ない',
   '確かに～だろう・間違いなく～だと思う. Nghĩa: chắc đúng là ~, nghĩ ~ là không sai được. Nếu dùng trong giấy tờ chứng nhận thì mang ý nghĩa "chắc chắn không sai, chắc chắn đúng".',
   'そんな非常識な要求は認められないに相違ない。', 'Yêu cầu thiếu tri thiếu biết thế này đúng là không thể chấp nhận được.',
   ARRAY['この地域の民族紛争を解決するのは難しいに相違ない。','今日の判決は、彼にとって不満に相違ない。','この土器は古い時代のものに相違ない。','ここに書かれていることは、事実に相違ありません。']::text[],
   ARRAY['Giải quyết xung đột sắc tộc ở khu vực này chắc là khó khăn.','Về phán quyết hôm nay, với anh ta khó mà thoả mãn.','Đồ gốm này ắt hẳn là thứ đồ cổ.','Những điều được viết ở đây không có gì là sai sự thật.']::text[]),

  ('f03c017f-002a-5d12-a087-db3a7ddcb1b2'::uuid, '～に違いない',
   '確かに～と思う. Nghĩa: nghĩ chính xác là ~.',
   'かぎがない。どこかに落としたに違いない。', 'Không có chìa khoá. Đúng là rơi đâu rồi.',
   ARRAY['山田さんが持って来てくれたワインは相当高かったに違いない。味も香りもすばらしかった。','老人の昔話は子供には退屈に違いない。','医者の話し方からすると、私は、癌に違いありません。']::text[],
   ARRAY['Chai vang bác Yamada mang cho khá đắt đây. Vị lẫn mùi thơm thật tuyệt.','Những câu chuyện ngày xưa của các cụ với trẻ con đúng là chán ngắt.','Theo cách nói của bác sỹ thì tôi đúng bị ung thư rồi.']::text[]),

  ('8fce49b4-8c4a-5e20-8cf0-2d0155ca3cec'::uuid, '～べき／～べきだ／～べきではない',
   'そうするのが人間として当然だ・～したほうがいい. Nghĩa: làm như thế là đương nhiên, nên làm ~.',
   '書く前に注意すべき点を説明します。', 'Trước khi viết thì tôi xin giải thích các điểm cần chú ý.',
   ARRAY['言うべきことは遠慮しないではっきり言ったほうがいい。','どんなに親しい仲でも、借りた物はきちんと返すべきだ。','若いうちに、外国語を勉強しておくべきだった。','先生のお宅に、こんな夜中に電話するべきではない。']::text[],
   ARRAY['Những điều nên nói thì nên không ngại ngần nói rõ ràng ra.','Dù là người thân mức nào đồ mượn thì nên trả lại cẩn thận.','Khi còn trẻ nên học ngoại ngữ trước.','Không nên điện thoại đến nhà thầy lúc nửa đêm thế này.']::text[]),

  ('abacbae4-1fed-5db4-b40e-0013e84c415d'::uuid, '～（より）ほか（は）ない／～ほかしかたがない',
   '～する以外に方法がない. Nghĩa: chả có cách nào khác là ~.',
   'だれにも頼めないから、自分でやるほかはない。', 'Không nhờ ai được, không có cách nào ngoài tự làm cả.',
   ARRAY['私の不注意で壊したのだから、弁償するほかない。','これだけ探しても見つからないのだから、あきらめるよりほかない。','この病気を治すためには、手術するほかしかたがないでしょう。']::text[],
   ARRAY['Vì tôi bất cẩn làm hỏng nên ắt phải đền thôi.','Tìm đến mức này mà không ra thì chả có cách gì hơn là bỏ cuộc.','Để chữa bệnh này thì ngoài phẫu thuật ra không có cách nào khác.']::text[]),

  ('e59ca8a9-1ffb-5053-a5ad-da17c1a4a679'::uuid, '～向きだ／～向きに／～向きの',
   '～にちょうどいい・～に適している. Nghĩa: vừa đẹp với ~, thích hợp với ~.',
   'このスキー場は初心者向きです。', 'Khu trượt tuyết này thích hợp với người mới tập.',
   ARRAY['この別荘は夏向きにできているので、冬は寒いです。','これは体力が必要なので、どちらかというと若い人向きの仕事です。']::text[],
   ARRAY['Khu biệt thự này được xây dành cho mùa hè nên mùa đông thì lạnh.','Vì đây cần có thể lực nên nói gì thì nói đây là công việc dành cho người trẻ.']::text[]),

  ('bd66dccb-10cc-5c13-9fe1-57d02a4e0dcd'::uuid, '～向けだ／～向けに／～向けの',
   '～に適するように特に作った. Nghĩa: để thích hợp với ~ mà đã đặc biệt tạo ra.',
   'ここにある軽量のクリスマスカードは、みんな海外向けだ。', 'Lượng nhỏ thiếp giáng sinh ở đây là hướng tới mọi người ở hải ngoại.',
   ARRAY['高齢者向けに、安全や住みやすさを考えた住宅が開発されている。','日本から1日2時間A国向けの番組が放送されている。','あちらに外国人向けのパンフレットが用意してある。']::text[],
   ARRAY['Hướng tới người cao tuổi, các nhà ở được xét về an toàn và dễ sinh sống đang được phát triển.','Chương trình dành cho nước A mỗi ngày 2h đang được phát đi từ Nhật Bản.','Các tờ rơi dành cho người nước ngoài được sắp ở đằng kia.']::text[]),

  ('c5a9b060-170e-5670-87ea-41b5e21278c7'::uuid, '～もの（です）か',
   '決して～ない（強い否定の意味を表す。）Nghĩa: quyết không ~ (ý phủ định mạnh). Nói chuyện hoặc giữa những người thân thì dùng dạng ～もんか／～もんですか.',
   'あの人が人の忠告なんか聞くものですか。', 'Người kia quyết không nghe lời khuyên của người khác.',
   ARRAY['歯医者に行くのがこわいんでしょう。こわいもんか。時間がないだけだよ。','ご迷惑じゃありませんか。迷惑なものですか。ぜひいらっしゃってください。','あの絵が名作なものか。ピカソの模倣にすぎない。']::text[],
   ARRAY['Đi nha sĩ thì sợ à. Sợ đâu. Không có thời gian thôi.','Không biết có phiền bác không? Phiền là phiền là thế nào. Nhất định đến đấy nhé.','Bức tranh kia nhất định không phải danh tác. Chỉ là mô phỏng bức của Picasso thôi.']::text[]),

  ('e78677cf-9b8c-5516-b202-da2a76b6b408'::uuid, '～ものだ／～ものではない',
   'A) （感嘆・嘆息・心に深く感ずることを表す。）: thể hiện cảm xúc mạnh, cảm thán, thở dài. B) （当然・常識と思えることを言う時の表現。）: nói về thứ được coi là tự nhiên, thường thức. C) （助言・軽い命令を表す。）: lời khuyên, mệnh lệnh nhẹ nhàng. D) （過去の状態やよく起こったことを思い出して言う時の表現。）: nhớ về việc đã xảy ra lâu trong quá khứ.',
   'あんな大事故にあって、よく助かったものだ。', 'Gặp tai nạn lớn thế mà được cứu sống hết.',
   ARRAY['いつか京都に行ってみたいものだ。','時間のたつのは早いものですね。','地震の時は、だれでも慌てるものだ。','年末は、だれでも忙しいものだ。','人の話はよく聞くものです。','人の陰口を言うものではありません。','子供のころ、いたずらをして、よく父に叱られたものだ。','この辺りは、昔は静かだったものだ。']::text[],
   ARRAY['Lúc nào đấy rất muốn đi Kyoto.','Thời gian trôi qua thật là nhanh nhỉ.','Lúc động đất thì ai cũng cuống cuồng.','Cuối năm thì ai cũng bận.','Cần phải nghe kỹ câu chuyện của người khác.','Không được nói xấu sau lưng người khác.','Hồi bé thường nghịch ngợm, hay bị bố mắng.','Khu này trước đây yên tĩnh lắm.']::text[]),

  ('5f22e3d0-6d15-5622-a084-cd95dde9c59f'::uuid, '～わけだ',
   'A) （理由があるから、そうなるのは当然だと言いたい時に使う。）: vì có lý do nên muốn nói như thế là đương nhiên. B) （成り行きから、そうなると言いたい時の表現。）: do quá trình, nên muốn nói sự việc trở nên thế — tức là ~, là thế.',
   '暗いわけだ。蛍光灯が1本切れている。', 'Tối là phải. Một bóng đèn huỳnh quang bị cháy.',
   ARRAY['ジョンさんは、お母さんが日本人ですから、日本語が上手なわけです。','5パーセントの値引きというと、1万円の物は9500円になるわけですね。','はじめは観光旅行のつもりで日本へ遊びに来たんですが、日本が好きになり、とうとう10年も日本に住んでしまったわけです。']::text[],
   ARRAY['Anh John có mẹ là người Nhật nên tiếng Nhật giỏi là phải.','Nói là giảm 5% giá, tức là hàng 1 man thì còn 9500Y nhỉ.','Ban đầu đến Nhật là định du lịch ngắm cảnh quan, đâm ra thích Nhật Bản, cuối cùng là sống đến 10 năm ở Nhật là như thế.']::text[]),

  ('e7e02dc7-2373-5e25-9d44-1243f2a01dd7'::uuid, '～わけではない／～わけでもない',
   '特に～ではない・必ずしも～ではない. Nghĩa: không nhất thiết là ~, không phải là ~.',
   '生活に困っているわけではないが、貯金する余裕はない。', 'Cuộc sống không phải là khó khăn nhưng cũng không có dư ra để dành.',
   ARRAY['彼の気持ちがわからないわけでもありませんが、やはり彼の意見には賛成できません。','甘い物が嫌いなわけではありませんが、ダイエットしているんです。']::text[],
   ARRAY['Không phải là tôi không hiểu tâm trạng anh ấy, nhưng mà rõ ràng tôi cũng không tán thành ý kiến anh ta.','Không phải tôi ghét đồ ngọt đâu nhưng mà đang ăn kiêng.']::text[]),

  ('c4463748-e964-5f16-9d62-7540e094f1a0'::uuid, '～っけ',
   '（思い出そうとした、思い出したことを確認する時に使う。）Nghĩa: đang nhớ ra, nhớ lại và muốn xác nhận lại. Dùng trong văn nói.',
   '彼にはまだパーティーの場所を知らせていなかったっけ。', 'Hình như tôi chưa báo cho anh ấy địa điểm liên hoan hay sao ấy.',
   ARRAY['学生時代は楽しかったね。そうそう、一緒によく卓球したっけね。','あのレストランで送別会しない。あそこ50人入れるほど広かったっけ。','そうだった。今日はお母さんの誕生日だっけ。']::text[],
   ARRAY['Lúc học sinh vui thật đấy nhỉ. Ừa ừa, mình cùng nhau hay chơi bóng bàn hay sao ấy nhỉ.','Không tổ chức tiệc chia tay ở nhà hàng đó. Đằng kia hình như chứa được tầm 50 người, rộng rãi lắm.','Ừ nhỉ, hôm nay là sinh nhật mẹ hay sao ấy.']::text[]),

  ('c8ec66a0-1068-5a52-96db-78a2cb83c363'::uuid, '～とか',
   '～そうだ・～ということだ（間接的情報を表す。）Nghĩa: nghe nói là ~ — chỉ thông tin mang tính gián tiếp.',
   '新聞によると、国内線の飛行機運賃が上がるとか。', 'Thấy báo nói giá cước vận chuyển hàng không tuyến nội địa tăng giá thì phải.',
   ARRAY['先生は来週、お忙しいとか。お宅に伺うのは、再来週にしませんか。','昨日はこの冬一番の寒さだったとか。','木村さんのお父さんも学校の先生だとか伺いました。','近々日本へいらっしゃるとか。ぜひお会いしたいものです。']::text[],
   ARRAY['Thầy giáo tuần sau bận thì phải ạ. Hay để tuần sau nữa em đến thăm nhà ạ.','Hôm qua thấy báo là lạnh nhất mùa đông năm nay.','Nghe nói bố của anh Kimura cũng là thầy giáo.','Nghe thấy gần đây bác vẫn đến Nhật. Nhất định em muốn được gặp.']::text[]),

  ('d894b666-2951-51db-8b94-2f53242c081a'::uuid, '～どころではない／～どころではなく',
   '事情があって、～できない. Nghĩa: có lý do, chịu không thể ~ (quá bận rộn hoặc lo lắng đến mức không thể nghĩ tới việc gì khác).',
   '人の仕事を手伝うどころではありません。自分の仕事も間に合わないんです。', 'Việc của người khác thì chịu không giúp được rồi. Việc của mình còn đang lỡ dở đây.',
   ARRAY['せっかく海へ行ったのに、寒くて泳ぐどころではなかった。','年末から母の入院で、お正月どころではありませんでした。','引っ越しの前の晩は、食事どころではなく、夜遅くまで荷作りが終わらなかった。']::text[],
   ARRAY['Khó khăn lắm mới đi được biển, thế mà lạnh quá không thể bơi được.','Từ cuối năm mẹ phải nhập viện, chả còn Tết nhất gì cả.','Đêm trước khi chuyển nhà thì chả có thời gian mà ăn uống, đóng đồ đến đêm muộn mà chả xong.']::text[]),

  ('86c19e26-a4d3-5bb3-9203-31c08e38a1af'::uuid, '～からして',
   'A) （一つの例をあげて、ほかももちろんだという気持ちを表す。）: đưa ra một ví dụ, nghĩ là những cái khác là đương nhiên — ngay cả ~. B) ～から判断して（推量の根拠を示す。）: từ ~ mà phán đoán — chỉ căn cứ của suy đoán.',
   '彼は礼儀を知らない。あいさつからして、きちんとしていない。', 'Anh ta chả biết lễ nghi gì cả. Đến chào hỏi còn chả thèm.',
   ARRAY['田舎は空気からして違う。','この映画はこわそうですね。題名からしてこわそうですね。','窓ガラスが破られていることからして、泥棒はここから行ったに違いない。','彼の健康状態からして、登山は無理だろう。']::text[],
   ARRAY['Ở quê thì ngay cả không khí cũng khác.','Bộ phim này có vẻ ghê nhỉ. Ngay cái tít thôi cũng sợ rồi.','Nhìn kính cửa sổ vỡ thế này, chắc hẳn kẻ trộm đã vào theo đường này.','Xem tình trạng sức khoẻ anh ta thế, leo núi làm sao được.']::text[]),

  ('e9359294-7fc5-5d5f-bb3c-1be7c173e325'::uuid, '～からすると／～からすれば',
   'A) ～の立場から見ると: nhìn từ lập trường của ~. B) ～から判断すると（推量の根拠を示す。）: phán đoán từ ~ — chỉ căn cứ cho suy luận.',
   '親からすると、子供はいくつになっても子供で、心配なものだ。', 'Với bố mẹ thì con cái có lớn thế nào thì vẫn lo lắng cho chúng.',
   ARRAY['日本人からすれば当たり前なことでも、外国人にとっては変だと思うこともある。','あの車は形からすると10年ぐらい前のものだと思う。','彼女の能力からすれば、A大学に十分合格できるだろう。']::text[],
   ARRAY['Theo cách nhìn của người Nhật, có những việc là đương nhiên nhưng đối với người nước ngoài lại nghĩ là lạ lắm.','Nhìn vào hình dáng của cái ô tô kia, tôi nghĩ nó là vật từ 10 năm trước.','Xét về năng lực của cô ấy, chắc là đủ sức đỗ đại học A.']::text[]),

  ('5373979f-3266-57de-8d7e-5e91c88e4b21'::uuid, '～からには／～からは',
   '～のだから当然. Nghĩa: as long as — chừng nào ~; vì là ~, đương nhiên. Đằng sau ～からには tiếp tục với câu nói về nghĩa vụ, quyết ý, suy luận, khuyên bảo, mệnh lệnh.',
   '試合に出るからには、勝ちたい。', 'Đã tham gia vào cuộc chơi, tất nhiên là muốn thắng.',
   ARRAY['約束したからには、守らなければいけない。','高価なものがこんなに安いからには、何か欠陥があるに違いない。','自分で選んだ道であるからには、最後までやりぬくつもりだ。','日本に来たからは、自分の専門の勉強だけでなく日本の文化も学ぼう。']::text[],
   ARRAY['Đã hứa rồi thì phải giữ lời.','Đồ đắt giá mà giá rẻ thế này hẳn là có khiếm khuyết gì đây.','Vì là con đường tự mình chọn, tôi định sẽ thực hiện đến cùng.','Vì đã đến Nhật rồi thì không chỉ học về chuyên môn của bản thân mà còn muốn học về văn hoá Nhật nữa.']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('e3bf3c4f-df54-5355-8d2e-d40a45643de8'::uuid, '～ことだから',
   '（皆が知っている理由を示す。後ろに推量の文がくる。）Nghĩa: trình bày lý do mà mọi người đều biết (về tính cách/thói quen của ai đó), theo sau là câu suy luận.',
   '子供のことだから、少しぐらいいたずらをしても仕方がないです。', 'Vì là trẻ con nên có nghịch một tí cũng không có cách nào.',
   ARRAY['あなたのことだからきっといい論文が書けると思います。','心の優しい林さんのことだから、喜んでボランティアに参加してくれるでしょう。']::text[],
   ARRAY['Anh thì em nghĩ chắc chắn sẽ viết được một luận văn tốt.','Vì là anh Hayashi người có trái tim nhân hậu nên anh ấy sẽ rất vui tham gia vào công việc tình nguyện.']::text[]),

  ('a67fbf7f-eff3-591d-8f87-3fc1d02d3ebc'::uuid, '～だけ／～だけあって／～だけに／～だけの',
   'A) ～にふさわしく: phù hợp với, quả đúng là, đúng là… có khác. B) ～だからいっそう（dùng dạng ～だけに）: chính vì là…nên càng… C) ～の限度まですべて: tất cả cho đến giới hạn…',
   'この仕事は努力しただけ成果が現れるので、やりがいがある。', 'Công việc này có thành quả thể hiện ra phù hợp với những nỗ lực bỏ ra nên tôi thấy rất có ý nghĩa.',
   ARRAY['この大学は歴史が長いだけあって伝統がある。','彼女はアメリカに留学しただけに英語がうまいね。','林さんはセールスマンだけに話が上手だ。','さすがに最高級と言われるワインだけのことはある。味も香りもすばらしい。','今日の試合は優勝がかかっているだけに大勢のファンが詰めかけ熱烈な応援をしていた。','昨年はみかんが不作で、値段が高かっただけに今年の豊作がうれしい。','考えるだけ考えたが結論は出なかった。','欲しいだけ本が買えたらどんなにいいだろう。','普段は忙しくて寝る時間も十分ないので、休みの日は好きなだけ寝ています。','目標を達成するためには、できるだけの努力をするつもりです。']::text[],
   ARRAY['Trường Đại học này có bề dày truyền thống tương xứng với chiều dài lịch sử.','Quả đúng là đã từng du học ở Mỹ, cô ấy rất giỏi tiếng Anh.','Quả đúng là Salesman, anh Hayashi nói chuyện rất hay.','Đúng là loại vang được mệnh danh là cao cấp nhất. Cả hương và vị đều rất tuyệt vời.','Trận đấu lần này chính vì là quyết định xem đội nào sẽ vô địch nên lượng người hâm mộ tập trung để cổ vũ càng đông đảo và cuồng nhiệt.','Chính vì năm ngoái mất mùa quýt, giá cao nên năm nay được mùa tôi lại càng vui.','Tôi đã nghĩ hết nước có thể nhưng cũng không ra được kết luận.','Giá mà tôi có thể mua tất cả sách mình mong muốn thì tốt biết mấy.','Ngày thường tôi rất bận rộn đến thời gian ngủ cũng không đủ, cho nên ngày nghỉ tôi ngủ bao nhiêu tùy thích.','Để đạt được mục tiêu, tôi sẽ nỗ lực hết khả năng có thể.']::text[]),

  ('407e941f-d553-5cdb-a59c-49c319bfa011'::uuid, '～にあたって／～に当たり',
   '～の時に（何かをすべき特別な機会や場合を示す。）Nghĩa: trong khi… (dùng trong trường hợp, cơ hội đặc biệt).',
   '開会にあたって、ひとことごあいさつ申し上げます。', 'Khai mạc hội nghị, tôi xin có một vài lời chào.',
   ARRAY['新製品を開発するにあたり、強力なプロジェクトチームが作られた。','新年にあたり、決心を新たにした。']::text[],
   ARRAY['Khi phát triển sản phẩm mới, một đội dự án mạnh đã được lập ra.','Vào thời điểm năm mới, tôi đã làm mới quyết tâm của bản thân.']::text[]),

  ('5e847563-7cc0-52e9-bf72-ac35f6cd709d'::uuid, '～にかけては／～にかけても',
   '～について言えば. Nghĩa: nếu nói về…',
   '数学にかけては、彼女はクラスでいつも一番だった。', 'Nếu nói về số học thì cô ấy là giỏi nhất lớp.',
   ARRAY['走ることにかけては、だれにも負けないつもりだ。','彼は優れた技術者だが、経営にかけても才能を発揮した。']::text[],
   ARRAY['Về môn chạy thì tôi quyết là sẽ không thua ai.','Anh ấy là một chuyên viên kỹ thuật xuất sắc nhưng về kinh doanh anh cũng phát huy tài năng của mình.']::text[]),

  ('101950ca-f9dc-5e0a-af92-d5a60e0501db'::uuid, '～に際して／～に際し／～に際しての',
   '～を始める時に・～をしている時に. Nghĩa: khi bắt đầu…, khi đang…',
   '留学に際して、先生や友人から励ましの言葉をもらった。', 'Khi đang du học, tôi đã nhận được nhiều lời động viên từ thầy cô và bè bạn.',
   ARRAY['帰国に際し、お世話になった人にあいさつの手紙を出した。','計画を変更するに際しての問題点を検討する。']::text[],
   ARRAY['Khi về nước, tôi đã viết thư chào hỏi những người đã giúp đỡ mình.','Chúng tôi đang xem xét những vấn đề khi thay đổi kế hoạch.']::text[]),

  ('4742bf49-01e0-5175-8ff8-301d815080a7'::uuid, '～に先立って／～に先立ち／～に先立つ',
   '～の前に・～より先に. Nghĩa: trước khi...',
   '映画の一般公開に先立って、主演女優のサイン会が開かれた。', 'Trước khi công chiếu bộ phim, lễ ký tặng của nữ diễn viên chính đã được tổ chức.',
   ARRAY['高層マンションの建設に先立って、住民と建設会社との話し合いが行われた。','入社試験に先立ち、会社説明会が行われた。','首脳会議に先立つ事務レベルの協議で、共同宣言の案が作られた。']::text[],
   ARRAY['Trước khi xây dựng các tòa nhà chung cư cao tầng, người ta tổ chức các cuộc thảo luận giữa dân chúng và công ty xây dựng.','Trước kì thi vào công ty, người ta tổ chức buổi giới thiệu về công ty ấy.','Ở hội nghị cấp thư ký trước hội nghị thượng đỉnh, người ta đã đưa ra dự thảo tuyên bố chung.']::text[]),

  ('96e95e99-7c98-58e3-92c5-623757f945c1'::uuid, '～にしたら／～にすれば／～にしても',
   '～の立場で言うと. Nghĩa: nếu nói trên lập trường…, nhìn từ suy nghĩ của…, đối với…',
   'あの人にしたら、私たちの親切はかえって迷惑かもしれません。', 'Nếu nhìn từ suy nghĩ của người đó, có thể sự tốt bụng của chúng ta ngược lại đem đến phiền phức.',
   ARRAY['学生にすれば、休みは長ければ長いほどいいだろう。','あなたにすれば、つまらないことかもしれませんが、私には大切なのです。','社会ルールを守ることは、小さな子供にしても同じです。']::text[],
   ARRAY['Đối với sinh viên có lẽ kì nghỉ càng dài càng tốt.','Đối với bạn có thể là một việc chán ngắt nhưng đối với tôi thì nó lại rất mực quan trọng.','Việc tôn trọng những quy tắc trong xã hội là giống nhau đối với cả những đứa trẻ.']::text[]),

  ('da9f9d45-7f3a-5776-aad7-9e45bf7f6f6e'::uuid, '～につき',
   '～なので. Nghĩa: vì… (cách nói khá cứng).',
   '雨天につき、試合は延期いたします。', 'Vì trời mưa nên trận đấu đã bị hoãn.',
   ARRAY['教授の海外出張につき休講。','店内改装につき、しばらく休業いたします。']::text[],
   ARRAY['Vì giảng viên đi công tác nước ngoài nên nghỉ học.','Vì sửa sang lại cửa hàng nên chúng tôi sẽ tạm nghỉ trong một thời gian.']::text[]),

  ('ba392bc6-f0bd-5d28-ad2e-b15b6552af4c'::uuid, '～につけ／～につけて（は）／～につけても',
   'A) ～するたびに: mỗi lần làm… (cuối câu thường có mẫu biểu hiện tình cảm như ～と思う／～という気持ちになる). B) ～の場合にも・～の場合も: trong trường hợp…cũng… (trước につけ có những từ đối xứng với nhau).',
   '家族の写真を見るにつけ、会いたくてたまらなくなる。', 'Mỗi lần nhìn ảnh gia đình tôi lại muốn gặp mọi người không chịu nổi.',
   ARRAY['戦争のニュースを聞くにつけ、心が痛む。','母は何かにつけて、小言を言う。','彼は何事につけても注意深い人だ。','アメリカに出張して帰って来たところです。そうですか。それにつけても、アメリカの大統領選挙の結果はどうなるんでしょうね。','先輩の活躍を見るにつけ聞くにつけ、心強くなる。','暑いにつけ寒いにつけ、うちのおばあさんは体の調子が悪いと言う。','雨につけ雪につけ、工事の遅れが心配された。']::text[],
   ARRAY['Mỗi lần nghe tin chiến tranh, lòng tôi lại đau thắt.','Mẹ thì lần nào cũng cằn nhằn.','Anh ta luôn là người rất cảnh giác với mọi việc.','Tôi vừa mới về từ chuyến công tác Hoa Kỳ. Vậy à? Liên quan đến đó, kết quả của cuộc bầu cử tổng thống Mỹ không biết sẽ thế nào nhỉ?','Mỗi lần nhìn, nghe các hoạt động của các anh chị khóa trên, tôi lại thấy thêm mạnh mẽ.','Lúc nóng, lúc lạnh, bà tôi đều nói là người không khỏe.','Lúc mưa, lúc có tuyết rơi tôi đều lo lắng bị muộn công trình.']::text[]),

  ('ed84433f-99f4-5276-a16a-d6dad066f4ae'::uuid, '～のもとで／～のもとに',
   '～のしたで（影響や条件の範囲内で、あることが行われることを表す。）Nghĩa: dưới… (trong phạm vi ảnh hưởng, trong điều kiện…mà một việc được tiến hành).',
   '鈴木教授のご指導のもとで、卒業論文を完成させた。', 'Dưới sự chỉ đạo của thầy Suzuki, tôi đã hoàn thành khóa luận tốt nghiệp.',
   ARRAY['国連から派遣された医師団のもとで救援活動が続けられた。','植民地の人々は独立と自由の名のもとに戦った。','子供の人権は法のもとに守られています。']::text[],
   ARRAY['Dưới sự hướng dẫn của đoàn bác sĩ được phái đến từ LHQ, các hoạt động viện trợ đã được tiếp tục.','Người dân các vùng thuộc địa đã chiến đấu dưới khẩu hiệu Độc lập và Tự do.','Quyền của trẻ em được bảo vệ dưới Pháp luật.']::text[]),

  ('1b600119-47d5-5f0d-8bdd-b2ac7818652b'::uuid, '～はともかく（として）',
   '～のことは考えないで・～は別にして. Nghĩa: tạm thời không nghĩ đến…, tạm thời gác chuyện…sang một bên.',
   'この洋服は、デザインはともかく、色がよくない。', 'Bộ quần áo này, tạm thời không nói đến thiết kế, màu sắc đã không đẹp rồi.',
   ARRAY['私は、話すことはともかく、書くことは苦手だ。','この店のラーメンは味はともかくとして、値段は安い。','買うかどうかはともかくとして、説明だけでも聞いてください。']::text[],
   ARRAY['Tôi thì không nói đến việc nói, viết đã kém rồi.','Mì của cửa hàng này, chưa nói đến vị, giá cả khá rẻ rồi.','Chưa tính đến việc có mua hay không nhưng xin hãy nghe lời giải thích của tôi đã.']::text[]),

  ('ae305f71-3dbf-58bf-8ca6-0e11a816b5e7'::uuid, '～をきっかけに（して）／～をきっかけとして',
   '（偶然のできごとから何かが始まったり変わったりすることを表す。）Nghĩa: biểu thị rằng từ một việc ngẫu nhiên mà có gì đó bắt đầu, thay đổi.',
   '留学をきっかけに、自分の国についていろいろ考えるようになった。', 'Từ việc đi du học mà tôi đã có nhiều suy nghĩ về đất nước của mình.',
   ARRAY['旅行をきっかけにして、木村さんと親しくなりました。','一主婦の投書をきっかけとして、町をきれいにする運動が起こった。']::text[],
   ARRAY['Từ việc du lịch mà tôi trở nên thân thiết với anh Kimura.','Từ bức thư của một bà nội trợ mà đã nổ ra cuộc vận động làm sạch thành phố.']::text[]),

  ('454ba874-b67b-5748-a136-62b0e7eef704'::uuid, '～を契機に（して）／～を契機として',
   '（あるできごとから、前の流れがはっきり表れてきたり大きく変わったりすることを表す。）Nghĩa: nhân cơ hội… (chỉ một việc mà dòng chảy từ trạng thái trước biểu hiện rõ ràng và thay đổi lớn từ một sự kiện nhất định).',
   'オイルショックを契機に新エネルギーの研究が進められた。', 'Nhân thời cơ của cuộc khủng hoảng dầu lửa, các nghiên cứu về năng lượng mới đã được đẩy mạnh.',
   ARRAY['明治維新を契機にして、日本は近代国家への道を歩みはじめた。','新製品の開発を契機として、大きく会社が発展した。']::text[],
   ARRAY['Nhân cuộc duy tân Meiji, Nhật Bản đã bắt đầu tiến trình theo con đường của các nước hiện đại.','Công ty đã phát triển mạnh mẽ với việc phát triển sản phẩm mới.']::text[]),

  ('e1ce5d7d-ca68-5f88-90d1-45fb8711be9f'::uuid, '～を～として／～を～とする／～を～とした',
   '～を～と決めて・～が～である. Nghĩa: lấy ~ làm ~ (trước として là các từ ngữ chỉ mục đích, lập trường, vai trò, chủng loại...).',
   '陳さんを先生として、中国語の勉強会を開いた。', 'Cử anh Trần làm thầy giáo và hội học tiếng Trung đã được mở.',
   ARRAY['同窓会は卒業生の交流を目的とする集まりです。','明治維新後、日本は欧米諸国を手本とした近代国家を作ろうとした。']::text[],
   ARRAY['Hội đồng học tập hợp lấy mục đích là giao lưu giữa các sinh viên đã tốt nghiệp.','Sau cuộc duy tân Meiji, Nhật Bản đã muốn lập nên nhà nước hiện đại lấy mô hình là các quốc gia Âu Mỹ.']::text[]),

  ('eaa03502-8b37-57df-a862-755d8293bb6b'::uuid, '～あげく（に）',
   '～したその結果とうとう・～したけれども、結局. Nghĩa: sau ~ rốt cuộc là...',
   'さんざん迷ったあげく、大学院には行かないことにした。', 'Sau khi cứ lúng túng gay go mãi, rốt cuộc là đã không học lên tiếp cao học được.',
   ARRAY['その男はお金に困ったあげく、銀行強盗を計画した。','長時間の議論のあげく、その開発計画は中止に決まった。','兄は父と口論のあげくに、家を飛び出して行った。']::text[],
   ARRAY['Người đàn ông đó khốn khổ vì không có tiền nên cuối cùng đã lên kế hoạch cướp ngân hàng.','Sau tranh luận dài, cuối cùng kế hoạch phát triển đó đã được quyết định tạm dừng.','Anh trai sau khi cãi nhau với bố đã chạy bay ra khỏi nhà.']::text[]),

  ('50f67271-14e8-5fbd-9dbe-87e9273a6c52'::uuid, '～以上（は）',
   '～からには. Nghĩa: chừng nào ~; đã là ~ thì.',
   '日本に住んでいる以上、日本の法律を守らなければならない。', 'Đã sống trên đất Nhật thì phải tuân thủ pháp luật Nhật Bản.',
   ARRAY['契約書に書かれている以上、期日までにこの仕事を完成させなければならない。','約束した以上、必ず守ってください。','相手のやり方が合理的である以上、文句はつけられない。','親子である以上、お互いの生活に無関心ではいられない。','給料がこんなに安い以上は、転職を考える人がいるのも当然だ。']::text[],
   ARRAY['Dựa trên các điều đã viết trong hợp đồng, đến kì hạn thì công việc này phải được hoàn thành xong.','Đã hứa rồi thì nhất quyết phải giữ lời đấy.','Chừng nào cách làm của đối phương là hợp lý thì chả phải kêu ca gì.','Đã là cha mẹ con cái thì không được thiếu quan tâm đến đời sống của nhau.','Chừng nào lương mà thấp cỡ này thì có người nghĩ đến chuyển chỗ làm là đương nhiên.']::text[]),

  ('7c0e4d39-7a24-50a6-84c4-7188abda0b4c'::uuid, '～上は',
   '～からには. Nghĩa: chừng nào ~; đã là ~ thì.',
   '契約を結ぶ上は、条件を慎重に検討すべきである。', 'Khi ký kết hợp đồng thì cần phải kiểm thảo thận trọng các điều kiện.',
   ARRAY['弁護士になると決めた上は、苦しくても頑張らなければならない。','友人が困っているのを知った上は、黙って見ていられない。','計画が中止になった。こうなった上は、プロジェクトチームは解散するしかない。']::text[],
   ARRAY['Đã quyết định thành luật sư thì dù là có gian khó cũng cần phải cố gắng.','Đã biết bạn bè khó khăn thì không thể đứng im nhìn được.','Kế hoạch tạm dừng rồi. Với tình hình này thì chỉ có nước giải tán đội dự án thôi.']::text[]),

  ('067c170e-f9d0-5751-877c-2255b4b26fe3'::uuid, '～ことなく',
   '～ないで. Nghĩa: không có ~.',
   'ロボットは24時間休むことなく働いている。', 'Robot làm việc 24h mà không nghỉ.',
   ARRAY['あの子はあきることなく、コンピューターゲームに熱中している。','彼は毎年忘れることなく、クリスマスカードをくれる。']::text[],
   ARRAY['Thằng nhỏ kia cứ chuyên tâm chơi điện tử mà không biết chán.','Anh ấy năm nào cũng không quên gửi thiếp giáng sinh cho tôi.']::text[]),

  ('a37a2314-3d3c-5d43-8d82-e29c4f5a96ec'::uuid, '～際（は）／～際に',
   '～時・～場合. Nghĩa: thời gian, trường hợp.',
   '帰国の際、保証人の家にあいさつに行った。', 'Lúc về nước đã đi chào gia đình người bảo lãnh.',
   ARRAY['カードを紛失した際はカード会社にすぐ知らせなければならない。','パスポートを申請する際に必要なものを教えてください。']::text[],
   ARRAY['Trong trường hợp đánh mất thẻ, cần phải thông báo với công ty cấp thẻ ngay.','Xin vui lòng chỉ dẫn các thứ cần thiết khi xin cấp hộ chiếu.']::text[]),

  ('53192181-3270-5531-b814-3838cb2dfd6e'::uuid, '～つつ／～つつも',
   'A) ながら: đang, trong khi ~ (không hay dùng trong hội thoại; với nghĩa này thì không dùng ～つつも). B) けれども・～のに: dù là ~.',
   '財布の中身を考えつつ、買い物をした。', 'Vừa nghĩ đến ví vừa đi mua hàng.',
   ARRAY['人は皆、お互いに助け合いつつ生きている。','喜ぶ母の顔を思いつつ、手紙を書いています。','悪いと知りつつ、うそをついてしまった。','今日こそ勉強しようと思いつつ、テレビを見てしまった。','早くご連絡しようと思いつつも、忙しくて遅くなってしまいました。申し訳ありません。']::text[],
   ARRAY['Mọi người vẫn đang sống tương trợ lẫn nhau.','Vừa nghĩ đến khuôn mặt mẹ hạnh phúc, vừa viết thư.','Dù biết là xấu nhưng lại nói dối mất rồi.','Chính hôm nay nghĩ là muốn học đây nhưng lại xem TV.','Muốn là nhanh chóng liên lạc nhưng mà do bận quá lại chậm mất. Xin được thứ lỗi.']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

insert into grammar_points (id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi, v.extra_examples_jp, v.extra_examples_vi,
       (select id from jlpt_levels where code = 'N2')
from (values
  ('249f3fb1-3af6-57e1-ae20-22f987f1327a'::uuid, '～てからでないと／～てからでなければ',
   '～た後でないと（前に言ったことが実現してからでなければ、後ろで言うことが実現しない。）Nghĩa: nếu không thực hiện cái nói đằng trước thì điều đằng sau cũng không thực hiện (câu sau mang ý phủ định).',
   'お金をいただいてからでないと、商品はお届けできません。', 'Nếu chưa nhận được tiền thì hàng cũng không giao được.',
   ARRAY['この仕事は訓練を受けてからでないと無理でしょう。','この地方では4月になってからでなければ、桜は咲かない。','契約書の内容を確認してからでなければ、判は押せません。']::text[],
   ARRAY['Công việc này mà không được huấn luyện thì không làm được đâu.','Địa phương này mà chưa đến tháng 4 thì hoa anh đào chưa nở.','Chưa xác nhận lại nội dung hợp đồng thì không đóng dấu được.']::text[]),

  ('add26f26-19b1-56f2-894a-da66ff930d1e'::uuid, '～といっても',
   '～（だ）が・しかし（実際はそれから考えられるものとは違う。）Nghĩa: dù là ~ nhưng ~ (thực tế so với điều được nghĩ từ đó khác nhau).',
   '庭があるといっても猫の額ほどです。', 'Nói là có vườn đấy nhưng mà bé tí (như cái đầu trán mèo).',
   ARRAY['朝ご飯を食べたといっても、パンとコーヒーだけの簡単なものです。','日本は物価が高いといっても、安いものもありますよ。','今日は暑かったといっても、クーラーをつけるほどではありませんでした。','日本料理が好きだといっても、天ぷらとすしだけです。','彼は社長といっても、社員が3人しかいない会社の社長です。']::text[],
   ARRAY['Dù là ăn sáng rồi nhưng cũng chỉ đơn giản là bánh mì và cafe thôi.','Nhật Bản thì đúng là giá cả cao thật nhưng đồ rẻ cũng có mà.','Hôm nay nói là nóng đấy nhưng cũng chưa đến mức cần bật máy lạnh.','Nói là tôi thích đồ ăn Nhật nhưng chỉ là tenpura và sushi thôi.','Anh ta là chủ tịch công ty đấy nhưng mà chỉ là chủ tịch của công ty có mỗi ba người thôi.']::text[]),

  ('297ff504-7e15-5d74-8ea9-f047632546c1'::uuid, '～どころか',
   '（前に言ったことはもちろん、それよりもっと程度が激しいという時や、実際はそうではなく、正反対であることを強調する時に使う。）Nghĩa: dùng nhấn mạnh một sự phản đối trực diện, điều nói trước là hiển nhiên; diễn đạt ý sau khác xa, thậm chí trái ngược hoàn toàn so với ý trước.',
   '彼は貯金するどころか借金だらけだ。', 'Anh ta mà có tiết kiệm à, nợ nần chồng chất kia kìa.',
   ARRAY['この部屋は涼しいどころか寒いくらいだ。','お宅の辺りは静かでしょう。いいえ、静かどころか最近は窓を開けていられないほど車の音がうるさいんです。','あの人は英語どころかアラビア語もスワヒリ語も話せる。']::text[],
   ARRAY['Phòng này mà mát á, lạnh thì có.','Gần nhà bác yên tĩnh nhỉ. Đâu, yên tĩnh gì, gần đây tiếng xe ô tô ồn ào đến mức không dám mở cửa sổ.','Ông kia đâu chỉ biết tiếng Anh, tiếng Arab rồi là Swahili nữa cũng nói được.']::text[]),

  ('91769b0a-2bd5-5e1a-90f7-906262c0ae56'::uuid, '～としたら／～とすれば',
   'A) ～なら（仮定の表現。）: nếu mà (giả định). B) ～なら・～から考えれば: nếu mà ~; nếu nghĩ từ ~ thì.',
   '留学するとしたら、日本に行きたいと思っていました。', 'Nếu mà đi du học, tôi đã định đi Nhật.',
   ARRAY['もし、もう一度生まれ変われるとしたら、男と女とどちらがいいですか。','予定どおりだとすれば、飛行機は9時に着くはずだ。','足の悪い人が地下鉄を利用するとしたら、どんな設備が必要だろうか。','この冷蔵庫はもう修理は無理ですね。修理が無理だとしたら、新しいのを買うしかありませんね。','電話を掛けても、出ないとすれば、彼はもう出かけたのでしょう。']::text[],
   ARRAY['Giả sử là, nếu được sinh ra lần nữa, bạn thích là con trai hay con gái?','Nếu mà như kế hoạch thì máy bay phải đến lúc 9h rồi.','Nếu người bị tật về chân sử dụng tàu điện ngầm thì cần loại thiết bị như thế nào nhỉ.','Cái tủ lạnh này đã không sửa được nữa nhỉ? Nếu mà không sửa được thì chỉ có cách mua cái mới nhỉ.','Dù gọi điện mà anh ta không ra thì chắc là đã ra ngoài rồi.']::text[]),

  ('56cca1e0-8a0f-55a3-9080-dad70be71c48'::uuid, '～ないことには',
   '～なければ. Nghĩa: nếu không ~ (đằng sau là câu mang ý phủ định).',
   '実際に読まないことには、この小説の面白さはわからないだろう。', 'Nếu mà chưa đọc thì không biết được độ hấp dẫn của tiểu thuyết này đâu.',
   ARRAY['部屋がもっと広くないことには、教室としては使えない。','体が丈夫でないことには、この仕事は無理だ。','担当者でないことには、詳しいことはわからないだろう。']::text[],
   ARRAY['Phòng này mà không rộng hơn tí nữa thì không dùng làm phòng học được.','Nếu mà không dai sức thì không thể làm việc này.','Nếu không phải người phụ trách thì chắc là không hiểu được những điều chi tiết.']::text[]),

  ('602d8323-dc2f-5905-8e85-ec6794de64c7'::uuid, '～ながら',
   'けれども. Nghĩa: ấy thế mà, tuy nhiên ~.',
   '一緒に暮らしていながら、母の病気に気づかなかった。', 'Sống cùng một nhà vậy mà không nhận ra bệnh của mẹ.',
   ARRAY['お礼を言おうと思いながら、言う機会がなかった。','日本語がわからないながら、テレビのドラマをけっこう楽しんでいます。','彼は仕事は遅いながら、確実で安心して任せられる。','残念ながら、その質問には答えられません。','この掃除機は、小型ながら性能がいい。']::text[],
   ARRAY['Muốn nói lời cảm ơn nhưng lại không có cơ hội nói.','Không hiểu tiếng Nhật nhưng mà vẫn thích thú thưởng thức kịch trên TV.','Anh ta làm việc thì hơi chậm nhưng được cái chắc chắn tôi đã yên tâm tin cậy giao phó.','Thật là tiếc nhưng câu hỏi đó tôi không trả lời được.','Cái máy hút bụi này tuy cỡ nhỏ nhưng tính năng tốt.']::text[]),

  ('7910fc87-19a7-5ad3-8c4e-29ac3139dfef'::uuid, '～にしては',
   'そのことから当然予想されることと違って. Nghĩa: so với điều được đương nhiên nghĩ đến từ đó thì khác.',
   '兄はアメリカに20年いたにしては英語が下手だ。', 'Dù anh trai sống ở Mỹ đến 20 năm nhưng tiếng Anh thì dở ẹc.',
   ARRAY['山田さんは忙しいにしては、よく手紙をくれます。','彼は歌手だったにしては歌が下手だ。','彼は力士にしては小柄だ。']::text[],
   ARRAY['Bác Yamada rất bận rộn nhưng vẫn hay viết thư cho tôi.','Anh ta là ca sĩ đấy nhưng hát dở tệ.','Anh ta là lực sĩ nhưng mà người nhỏ.']::text[]),

  ('10524dd0-6c9e-57bc-b02e-9bd1221dd8fc'::uuid, '～にしろ／～に（も）せよ／～にしても',
   'A) たとえ～ても・～でも: ngay cả nếu, tỉ như ~, vẫn ~. B) ～でも～でも、どちらでも: cái nào cũng ~.',
   'どんな人間にしろ長所はあるものだ。', 'Dù là người nào thì cũng có sở trường.',
   ARRAY['いくら忙しいにもせよ食事をしないのはよくない。','いくら体が丈夫であるにせよ、そんなに働いたら病気になりますよ。','中古の家を買うにしても借金しなければならない。','ビールにしろ、日本酒にしろ飲んだら運転できない。','好きにせよ嫌いにせよ、彼女が優れた歌手であることはみんなが認めている。','自分でやるにしても、人に頼むにしてもこれは時間がかかる。']::text[],
   ARRAY['Ngay cả là bận đến thế nào, bỏ ăn là không tốt.','Dù đai sức thế nào đi nữa, làm việc cỡ đó thì ốm mất đấy.','Dù là mua một cái nhà cũ nhưng vẫn phải vay tiền.','Bia cũng thế, rượu cũng thế, đã uống vào thì không lái xe được.','Dù thích hay không thích, mọi người đều công nhận cô ấy là một ca sĩ xuất sắc.','Tự làm hay nhờ người khác làm thì việc này đều tốn thời gian.']::text[]),

  ('a6a1abd1-0797-5c70-a166-5499f2e74125'::uuid, '～にかかわらず／～に（は）かかわりなく',
   '～に関係なく. Nghĩa: không liên quan đến~.',
   '参加するしないにかかわらず、必ず返事をください。', 'Không tính là có tham gia hay không, nhất định hãy trả lời nhé.',
   ARRAY['あの会社は外国語の能力にかかわらず、国際感覚を持った人を採用する。','経験の有無にかかわりなく、入社後の研修に参加していただきたい。','このゲームは、年齢や性別にかかわらず、だれでも楽しめる。']::text[],
   ARRAY['Công ty đó tuyển người không căn cứ vào trình độ ngoại ngữ mà là những người có khả năng về quốc tế.','Không quan tâm là đã có kinh nghiệm hay chưa, sau khi vào công ty chúng tôi muốn bạn tham gia tập huấn.','Trò chơi này không phân biệt tuổi tác, giới tính, ai cũng thích.']::text[]),

  ('b3c70803-1972-54b5-a4ac-e2efdf07c248'::uuid, '～にもかかわらず',
   '～のに. Nghĩa: dù cho, dẫu cho ~.',
   '彼は熱があるにもかかわらず、サッカーの試合に出場した。', 'Anh ta dù bị sốt nhưng vẫn ra sân thi đấu bóng đá.',
   ARRAY['問題が易しかったにもかかわらず、不注意でミスをしてしまった。','そのパソコンは操作が複雑であるにもかかわらず、よく売れている。','ご多忙にもかかわらず、ご出席くださいましてありがとうございます。']::text[],
   ARRAY['Dẫu cho câu hỏi dễ nhưng vì không chú ý tôi đã làm sai.','Cái máy tính này dù thao tác phức tạp nhưng vẫn bán chạy.','Xin cảm ơn vì dù rất bận rộn nhưng anh vẫn đến dự với chúng tôi.']::text[]),

  ('e0021672-ea01-51b0-b3f9-ef1d53c1810e'::uuid, '～ぬきで（は）／～ぬきに（は）／～ぬきの／～をぬきにして（は）／～はぬきにして',
   '～なしで・なしに（～がない状態で・～を省いて）Nghĩa: không có ~ (ở trạng thái không có ~ hoặc lược bớt ~).',
   '朝食ぬきで会社へ行くサラリーマンが多いらしい。', 'Có vẻ nhiều nhân viên công ty đi làm mà không ăn sáng.',
   ARRAY['社長ぬきでは、この件を決めることはできない。','彼女は世辞ぬきにすばらしい人だ。','子供用にわさびぬきのまぐろのすしを注文した。','アジアをぬきにしては、世界経済は語れない。','今日の会は難しい話はぬきにして楽しくやりましょう。']::text[],
   ARRAY['Không có chủ tịch thì việc này không thể quyết định được.','Không cần một lời khen, cô ấy là người tuyệt vời.','Tôi đã đặt món sushi cá ngừ không có mù tạt cho bọn trẻ.','Không thể nói đến kinh tế thế giới mà không có châu Á.','Buổi họp hôm nay chúng ta hãy thật thoải mái và không nói đến các vấn đề phức tạp.']::text[]),

  ('4ad455d8-684b-543a-9394-71099d4ede9b'::uuid, '～のみならず',
   '～だけでなく. Nghĩa: không chỉ, mà còn~.',
   'このコンピューターは性能が優れているのみならず、操作も簡単だ。', 'Máy tính này không chỉ vượt trội về tính năng mà sử dụng còn dễ dàng.',
   ARRAY['この会社は安定性が高いのみならず、将来性もある。','彼女は成績優秀であるのみならず、人柄も申し分ない。','学生のみならず、教師もスポーツ大会に参加することになっている。','この手術は費用が高額であるのみならず、危険も伴う。']::text[],
   ARRAY['Công ty này không chỉ có tính ổn định cao mà còn có tương lai nữa.','Cô ấy không những có thành tích ưu tú mà tính cách cũng không có gì phải bàn.','Không chỉ sinh viên mà các thầy cô giáo cũng tham gia vào đại hội thể thao.','Việc phẫu thuật này không những tốn chi phí cao mà còn kèm theo nguy hiểm.']::text[]),

  ('fb6b51c3-110a-5db8-9768-0d1ccbc52113'::uuid, '～反面／～半面',
   'ある面では～と考えられるが、別の面から見ると. Nghĩa: mặt khác, mặt trái.',
   'この薬はよくきく反面、副作用がある。', 'Thuốc này có tác dụng tốt nhưng mặt trái cũng gây tác dụng phụ.',
   ARRAY['母は優しい反面、厳しいところもある。','彼はわがままな反面リーダーシップがある。','あの映画はロマンチックな反面、考えさせるものがある。','彼は紳士である半面、子供っぽいところもある。']::text[],
   ARRAY['Mẹ thì một mặt dịu dàng nhưng cũng có cái nghiêm khắc.','Trái với tính cách ích kỷ, anh ta có khả năng lãnh đạo.','Bộ phim này bên cạnh tính lãng mạn còn có những điều cần suy nghĩ.','Anh ta một mặt là người lịch thiệp nhưng lại có tính trẻ con.']::text[]),

  ('19df5692-ae88-5c30-9c95-3adaad177f41'::uuid, '～ものなら',
   '～なら（実現が難しいことを希望する時、または、実現の可能性が少ないことを相手に冷たく言う時の言い方。）Nghĩa: nếu ~ (dùng khi hi vọng vào một điều khó thực hiện hoặc là ít khả năng thực hiện — cách nói lạnh lùng). Hay dùng với các động từ mang ý chỉ khả năng.',
   '父の病気が治るものなら、どんな高価な薬でも手に入れたい。', 'Nếu bệnh tình của bố chữa được thì thuốc có đắt đến mấy tôi cũng mua.',
   ARRAY['自分一人でやれるものならやってみなさい。','病気の子供を見ていると、代われるものなら代わってやりたいと思う。','退院できるものなら、すぐにでもうちへ帰りたい。']::text[],
   ARRAY['Nếu có thể thì hãy làm tự thân một mình.','Khi nhìn con ốm, nếu mà ốm thay được thì tôi cũng muốn thay.','Nếu mà ra viện được thì tôi muốn về nhà ngay.']::text[]),

  ('7ae0fa26-ebf6-5e9b-88ec-56ea03e7f993'::uuid, '～ものの',
   'けれども・～ということは本当だが、しかし. Nghĩa: dù là ~; nói ~ là đương nhiên nhưng mà ~. Hay dùng mẫu ～とはいうものの, đặc biệt với danh từ thì chỉ dùng mẫu [名]＋とはいうものの.',
   '免許はとったものの、車が買えない。', 'Dù là có bằng lái nhưng mà không mua được ô tô.',
   ARRAY['立秋とはいうものの、まだまだ残暑が厳しい。','給料は少ないものの、仕事はやりがいがあります。','冷凍食品は便利なものの、毎日続くといやになる。']::text[],
   ARRAY['Lập thu rồi đấy, nhưng cái nóng còn sót lại vẫn gay gắt.','Lương hơi ít nhưng công việc rất đáng làm.','Đồ ăn đông lạnh thì tiện đấy nhưng ngày nào cũng ăn thì phát ngán.']::text[]),

  ('c6d1a9c9-3f20-5767-bc69-842e946469ad'::uuid, '～わりに（は）',
   '～にふさわしくなく以外に. Nghĩa: không phù hợp, không xứng với ~ (so với tỉ lệ tương ứng).',
   '私はたくさん食べるわりに太らない。', 'Mặc dù tôi ăn rất nhiều, nhưng mà không bị tăng cân.',
   ARRAY['あのレストランの料理は、値段のわりにおいしい。','彼は勉強しないわりには成績がいい。','この品物は高いわりには品質がよくない。','兄は慎重なわりにはよく忘れ物をする。']::text[],
   ARRAY['Đồ ăn của nhà hàng đó, so với giá thì là ngon.','Dù nó chả học gì mà thành tích tốt ghê.','Mặt hàng này dù là đắt nhưng chất lượng không tốt.','Dù anh trai khá cẩn thận nhưng mà vẫn hay bỏ quên đồ.']::text[]),

  ('ed8b25e1-7f70-5d18-8bac-fb8f53a62cec'::uuid, '～（よ）うではないか／～（よ）うじゃないか',
   '～しましょう・～しませんか（強い呼びかけの表現。）Nghĩa: hãy ~ (kêu gọi mạnh mẽ).',
   '災害を受けた人々に救援物資を送ろうではないか。', 'Chúng ta hãy gửi đồ cứu viện đến cho những người bị thảm hoạ.',
   ARRAY['自然保護の運動を広めようではないか。','男女差別の問題について真剣に考えようではありませんか。','賃金を上げるように社長に交渉しようじゃありませんか。']::text[],
   ARRAY['Hãy mở rộng cuộc vận động bảo vệ tự nhiên.','Hãy suy nghĩ nghiêm túc về vấn đề phân biệt giới tính.','Chúng ta hãy đàm phán với chủ tịch công ty để được tăng tiền công.']::text[]),

  ('fde8ad60-9e2a-5f78-9cb4-6f0a5d9b5562'::uuid, '～得る／～得ない',
   '～することができる／できない・～の可能性がある／ない. Nghĩa: có thể/không thể ~. Nói về tính khả thi.',
   '考え得る限りの手は尽くしたが、問題の解決には至らなかった。', 'Đã hết sức trong giới hạn có thể suy nghĩ nhưng vẫn chưa đến được cách giải quyết vấn đề.',
   ARRAY['捜し得るかぎり捜したが、その書類はとうとう見つからなかった。','でき得るならば、独立して事業を始めたい。','あれは警報を早く出していれば、防ぎ得た災害かも知れない。','こんな低い山で遭難することはあり得ないと思う。']::text[],
   ARRAY['Đã tìm hết khả năng có thể tìm mà cuối cùng vẫn không thấy tài liệu đó.','Nếu mà có thể, tôi muốn bắt đầu sự nghiệp độc lập.','Đó có lẽ là thảm hoạ được phòng tránh nếu cảnh báo được đưa ra sớm.','Tôi nghĩ là không có khả năng bị nạn trên núi thấp thế này.']::text[]),

  ('42329718-c8ed-5087-b2b0-66905703ebed'::uuid, '～かねない',
   '～おそれがある・～かもしれない（悪い結果になる可能性がある時に使う。）Nghĩa: lo ngại là ~; có lẽ ~ (dùng khi có khả năng dẫn đến kết quả xấu).',
   'あんなにスピードを出したら、事故を起こしかねない。', 'Tăng tốc đến mức này, tai nạn chứ chẳng chơi.',
   ARRAY['あまり遊んでばかりいると、落第しかねない。','あの人ならそんな無責任なことも言いかねない。']::text[],
   ARRAY['Nếu cứ chỉ chơi thế này, thi trượt mất đấy.','Ông ấy thì có thể nói những lời vô trách nhiệm thế này.']::text[]),

  ('f61c519b-c740-52ae-90c7-e3b5b7113cce'::uuid, '～かねる',
   '～しようとしてもできない・～することが難しい. Nghĩa: muốn làm ~ nhưng không thể, ~ là khó.',
   'そんな多額な寄付には応じかねます。', 'Đóng góp nhiều tiền thế này thì chúng tôi khó lòng nhận lời được.',
   ARRAY['私の仕事がなかなか終わらなかったので、見かねて山田さんが手伝ってくれた。']::text[],
   ARRAY['Vì công việc của tôi vẫn chưa xong nên không đứng nhìn được, bác Yamada đã giúp.']::text[]),

  ('716ff311-2b10-54f4-85c8-59b26f813ca0'::uuid, '～ことか',
   'なんと～でしょう（感嘆・嘆息を表す。）Nghĩa: không biết thế nào đây ~ (cảm thán, thở dài).',
   '息子から半年も連絡がない。一体何をしていることか。', 'Con trai nửa năm rồi chả thấy liên lạc gì, không hiểu là đang làm cái gì đây.',
   ARRAY['あなたの返事をどんなに待っていたことか。','友達と別れて、どんなに寂しかったことか。','コンピューターは、なんと便利なことか。']::text[],
   ARRAY['Tôi đã đợi câu trả lời của anh bao lâu.','Chia biệt bạn, thật là cô đơn biết bao.','Máy tính thật là thứ thật tiện lợi.']::text[]),

  ('f32cca1e-be43-50a2-8941-09c45ba8d50b'::uuid, '～ことだ',
   '（そのことが大切であると勧める時に使う。）Nghĩa: dùng khi khuyên người khác rằng việc đó là quan trọng.',
   '大学に入りたければ、一生懸命勉強することだ。', 'Nếu muốn vào đại học thì nên chăm chỉ học hành.',
   ARRAY['風邪気味なら、早く寝ることだ。','言葉の意味がわからなければ、まず辞書で調べることだ。','人の悪口は言わないことです。']::text[],
   ARRAY['Nếu thấy có cảm giác bị cảm thì nên ngủ sớm.','Nếu không hiểu ý nghĩa của từ ngữ thì trước tiên nên tra từ điển.','Không nên nói xấu người khác.']::text[]),

  ('9367e74f-8b52-5a7b-bc6f-b240f2910605'::uuid, '～ざるを得ない',
   'どうしても～なければいけない・～ないわけにはいかない. Nghĩa: dù thế nào, cũng phải…; không thể không… ([する]は[せざるを得ない]となる。)',
   'みんなで決めた規則だから、守らざるを得ない。', 'Vì là nguyên tắc mọi người định ra nên không thể không tuân thủ.',
   ARRAY['原料がどんどん値上がりしているのですから、製品も値上げせざるを得ません。','彼は登山中に消息不明となり、すでに5年経っている。死んだと考えざるを得ないだろう。','こんなにひどい雨では運動会は中止せざるを得ない。']::text[],
   ARRAY['Giá nguyên liệu tăng vọt nên không thể không tăng giá hàng hóa.','Đã năm năm rồi kể từ khi anh ấy bị mất tích trong khi leo núi. Có lẽ không thể không nghĩ là anh ấy đã mất.','Mưa to thế này thì dù thế nào cũng phải hủy ngày hội thể thao thôi.']::text[]),

  ('394efb4b-62aa-5d4f-8363-61c0e8bbca98'::uuid, '～次第だ／～次第で（は）',
   'A) ～わけだ（経緯・理由を示して、～の結果になったと言いたい時の表現。）: chỉ nguồn căn, lý do; cách dùng khi muốn nói đã có kết quả là… B) ～によって決まる: dựa vào… mà quyết định.',
   'このたび日本政府の招きにより、親善大使として日本に来た次第です。', 'Lần này nhận lời mời của chính phủ Nhật Bản nên tôi đã đến Nhật với tư cách Đại sứ thiện chí.',
   ARRAY['英語が話せない私には無理な仕事と思い、お断りした次第です。','私の専門分野なのにこんなこともわからなくて、お恥ずかしい次第です。','以上のような次第で、退職することになりました。','この世の中はお金次第だと言う人もいる。','考え方次第で幸せにも不幸せにもなる。','実力次第では社長になることも可能だろう。','検査の結果次第では入院ということもあり得る。']::text[],
   ARRAY['Tôi nghĩ việc này là không thể với một người không thể dùng tiếng Anh như tôi nên tôi xin từ chối.','Là lĩnh vực chuyên môn của tôi mà việc này tôi lại không hiểu nên tôi thấy thật xấu hổ.','Với những lý do nêu trên, tôi đã có quyết định nghỉ việc.','Cũng có những người nói rằng cuộc đời này tất là do đồng tiền quyết định.','Dựa vào cách suy nghĩ mà cũng có thể trở thành hạnh phúc hay bất hạnh.','Dựa vào thực lực cũng có khả năng tôi sẽ trở thành giám đốc.','Dựa vào kết quả khám mà cũng có thể tôi sẽ nhập viện.']::text[]),

  ('63f04138-ef13-52b5-88bb-0fe3a93f67ee'::uuid, '～っこない',
   '決して～ない・絶対～ない（会話で使われる。）Nghĩa: nhất định không…, tuyệt đối không… — dùng trong hội thoại.',
   '宝くじなんて当たりっこないよ。', 'Tôi thì những thứ như xổ số là nhất định sẽ không bao giờ trúng.',
   ARRAY['どんなに急いだって、今からじゃ間に合いっこない。','いくら好きだって、一度にバナナを20本も食べられっこない。']::text[],
   ARRAY['Dù có khẩn trương thế nào thì giờ này nhất định cũng không thể kịp được.','Dù có thích thế nào, một lần cũng không thể ăn đến 20 quả chuối.']::text[]),

  ('4a725390-a19e-5c96-95d1-d52c1423e201'::uuid, '～というものだ',
   '（それが当たり前という話者の主張や感想を表す。）Nghĩa: biểu thị cách nghĩ và cảm giác của người nói rằng việc đó là đương nhiên.',
   '彼の作品がやっと世間から評価された。長年の苦労が認められたというものだ。', 'Tác phẩm của anh ấy cuối cùng cũng được dư luận đánh giá cao. Đó chính là sự công nhận công sức lao động trong thời gian dài.',
   ARRAY['言葉が通じない国へ一人で旅行するのは心細いというものだ。','若者が高価な車を買うのはぜいたくというものだ。','人の手紙を無断で開封するのは、プライバシーの侵害というものだ。']::text[],
   ARRAY['Việc đi du lịch một mình đến một đất nước có ngôn ngữ mình không biết thì thật đúng là cô đơn và bất an.','Người trẻ tuổi mà mua ô tô đắt tiền thì thật đúng là xa xỉ.','Việc mở phong bì thư người khác mà không được người đó cho phép thì đương nhiên là xâm hại đến sự riêng tư của người khác rồi.']::text[]),

  ('4308595c-2e98-51c3-99c5-1632f9bf593e'::uuid, '～というものではない／～というものでもない',
   '～とは言いきれない. Nghĩa: không thể nói hết là…',
   '性格は絶対に変えられないというものではない。', 'Không thể nói rằng là tính cách tuyệt đối sẽ không thay đổi.',
   ARRAY['お金さえあれば幸せに暮らせるというものではない。','かぎをかけたから安心というものでもない。','この仕事は英語ができなければだめだというものでもないが、できたほうがいい。']::text[],
   ARRAY['Không thể nói rằng là chỉ cần có tiền là có thể sống hạnh phúc.','Không thể nói rằng đã khóa rồi là có thể yên tâm.','Việc này cũng không thể nói là không biết tiếng Anh thì không làm được nhưng mà biết thì tốt hơn.']::text[]),

  ('4eba2dd2-1e66-5322-96d9-e909de572b72'::uuid, '～ないことはない／～ないこともない',
   '～の可能性もある. Nghĩa: cũng có khả năng là…, không phải là không thể…',
   '難しいが、やり方次第ではできないことはないだろう。', 'Dù khó nhưng mà tùy theo cách làm cũng không phải là không thể làm được.',
   ARRAY['どうしても話してくれと言われれば、話さないこともない。','ちょっと大きくないこともないが、この靴で大丈夫。','このセーター、ちょっと派手じゃありませんか。派手じゃないこともないけど、よく似合っているからいいんじゃないですか。']::text[],
   ARRAY['Đã được nhắc là dù thế nào cũng hãy nói chuyện nên không thể không nói.','Cũng không phải là không to một chút nhưng mà đôi giày này là ổn rồi.','Cái áo len này chẳng phải là hơi sặc sỡ hay sao? Cũng sặc sỡ, nhưng vì trông rất hợp nên chẳng được hay sao?']::text[]),

  ('b1ed521e-682a-50cb-a334-ed3b6873113c'::uuid, '～ないではいられない／～ずにはいられない',
   'どうしても～してしまう（どうしても我慢できず、自然にそうなってしまうと言いたい時の表現。主語は一人称に限る。主語が三人称の時は文末に[～ようだ][～らしい]などをつける。）Nghĩa: dù thế nào cũng đã làm… — dù thế nào cũng không thể chịu đựng, dùng khi muốn nói tự nhiên mà thành như thế. ([する]は[せずにはいられない]となる。)',
   '彼のもの真似を見るとおかしくて、笑わないではいられない。', 'Nhìn cách anh ấy bắt chước các sự vật buồn cười quá nên tôi không thể nhịn được.',
   ARRAY['あの映画のラストシーンは感動的で、涙を流さずにはいられなかった。','車の多い道路で遊んでいる子供を見て、注意せずにはいられなかった。']::text[],
   ARRAY['Cảnh cuối cùng của bộ phim đó quá cảm động nên tôi không thể kìm được nước mắt.','Nhìn bọn trẻ con đang chơi trên đường nhiều ô tô, tôi không thể không nhắc nhở.']::text[]),

  ('d9906b06-5055-58cf-a738-476167d8ae1e'::uuid, '～に限る／～に限り／～に限って',
   'A) ～だけ: giới hạn ở… B) ～だけは特に: riêng…là đặc biệt. C) 一番いい: là nhất…, nên… (A, B dùng [名]＋に限る／に限り／に限って; C dùng [動－辞書形／ない形－ない][名]＋に限る).',
   '参加者は女性に限る。', 'Người tham gia chỉ giới hạn ở nữ.',
   ARRAY['先着50名様に限り、受け付けます。','本日に限って、全商品2割引にさせていただきます。','あの人に限って、人をだますようなことはしない。','傘を持っていない日に限って、雨が降る。','あのレストランは年中無休なのに、行ってみたら今日に限って休みだった。','風を引いた時は、部屋を暖かくして寝るに限る。','危険な所には近寄らないに限る。','夏はビールに限る。']::text[],
   ARRAY['Chúng tôi chỉ tiếp nhận 50 người đến đầu tiên.','Chỉ hôm nay, chúng tôi giảm giá 20 phần trăm cho tất cả các mặt hàng.','Chỉ riêng với người đó, không bao giờ làm cái việc như là lừa người khác.','Vào đúng ngày tôi không mang ô thì lại mưa.','Nhà hàng đó hoạt động cả năm không nghỉ vậy mà đúng ngày hôm nay khi tôi thử đến thì lại nghỉ.','Khi bị cảm, nên giữ ấm phòng và ngủ là tốt nhất.','Tốt nhất không nên lại gần nơi nguy hiểm.','Mùa hè Bia là số 1.']::text[]),

  ('8f934117-524a-5223-8776-8bf055ff9e77'::uuid, '～に限らず',
   '～だけではなく～も. Nghĩa: không chỉ…mà cũng…, không những…mà còn…',
   'ディズニーランドは子供に限らず、大人にも人気がある。', 'Disneyland thì không những được trẻ con ưa thích mà cả người lớn nữa.',
   ARRAY['この講義は学生に限らず、社会人も聴講できる。']::text[],
   ARRAY['Buổi giảng này không chỉ sinh viên mà người đã đi làm cũng có thể tham gia nghe giảng.']::text[]),

  ('e68ad52b-82b1-5896-98a7-b5549d7262c9'::uuid, '～にほかならない',
   'まさに～だ・それ以外でない（強調。断定的に述べる時に使う。理由を表す[から]にもつく。）Nghĩa: chính là…, không gì khác là…',
   'この手紙は私の正直な気持ちを申し上げたにほかなりません。', 'Bức thư này không gì khác chính là nói lên tình cảm chân thành của tôi.',
   ARRAY['この仕事が成功したのは皆さんのご協力の結果にほかなりません。','熱帯雨林が消滅することは、地球の肺がなくなることにほかならない。','戦争というものは、大量殺人にほかならない。','親が子供を叱るのは子供を愛しているからにほかならない。']::text[],
   ARRAY['Sự thành công của công việc này chính là kết quả sự cộng tác của các bạn.','Việc rừng nhiệt đới bị hủy diệt chính là sẽ mất đi lá phổi của trái đất.','Chiến tranh không gì khác chính là giết người hàng loạt.','Việc cha mẹ mắng con không gì khác chính là yêu thương con.']::text[]),

  ('724bfcee-88a8-5b54-8a31-2cb977b7e868'::uuid, '～もの',
   '～から（理由の説明や言いわけの表現。話し言葉で女性や子供が使う。[～もん]は、よりくだけた言い方。）Nghĩa: bởi vì…',
   '一人で行ける。うん、大丈夫、地図を持っているもの。', 'Cậu có thể đi một mình chứ? Ừ, không sao đâu vì tớ có bản đồ mà.',
   ARRAY['電話はあしたにしたほうがいいんじゃない。もう遅いもの。','手伝ってあげようか。いいよ。一人でできるもん。','多少のいたずらはしかたありませんよ。子供ですもの。']::text[],
   ARRAY['Để đến mai gọi điện chẳng hơn sao. Vì muộn rồi mà.','Để tớ giúp cậu nhé. Thôi mà, được rồi, vì tớ làm một mình được mà.','Chúng có nghịch ngợm một chút thì cũng không có cách nào đâu. Vì là trẻ con mà.']::text[]),

  ('cd5a0c03-c1bc-5e27-b314-fcdf65116b92'::uuid, '～ものがある',
   '～という感じがある・～ように感じられる. Nghĩa: có cảm giác…, có thể cảm giác như là…',
   'この絵には人を引きつけるものがある。', 'Tôi có cảm giác bức tranh này rất lôi cuốn người xem.',
   ARRAY['彼の話にはどこか納得できないものがある。','仕事がなくて暇すぎるのもつらいものがある。','彼の話し方にはどこか強引なものがあった。']::text[],
   ARRAY['Trong câu chuyện của anh ấy tôi cảm thấy như có gì đó không thể thấu hiểu.','Tôi có cảm giác việc thất nghiệp và quá nhàn rỗi có gì đó cũng thật cay đắng.','Tôi có cảm giác cách nói chuyện của anh ta có gì đó miễn cưỡng.']::text[]),

  ('169c4ebe-35cd-5993-8974-ee4294c7c02c'::uuid, '～ようがない／～ようもない',
   '～する方法がない・手段がなくて～できない. Nghĩa: không còn phương pháp nào, không còn cách nào, không thể.',
   '木村さんは今どこにいるのかわからないので、連絡しようがない。', 'Tôi không biết anh Kimura giờ ở đâu nên không thể liên lạc được.',
   ARRAY['質問の意味がわからなくて、答えようがなかった。','ここまで壊れてしまった車は直しようがない。','この病気にかかると、今の医学ではどうしようもないらしい。']::text[],
   ARRAY['Tôi không hiểu ý nghĩa của câu hỏi nên không thể trả lời được.','Cái xe đã bị hỏng đến mức này rồi thì không có cách nào chữa nổi.','Nếu mắc bệnh này thì với y học hiện nay không có phương pháp cứu chữa.']::text[])
) as v(id, title, explanation, example_jp, example_vi, extra_examples_jp, extra_examples_vi)
on conflict (id) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Lessons — nhóm 3 điểm ngữ pháp liên tiếp theo đúng thứ tự trong file (đúng thứ tự PDF)
-- thành 1 "ngày": 173 điểm / 3 = 57 ngày đủ 3 điểm + ngày 58 còn 2 điểm.
-- id lesson: uuid5(NAMESPACE_URL, 'app-nihongo:n2:lesson:grammar:day:<NN>').
-- ─────────────────────────────────────────────────────────────

insert into lessons (id, title, level_id, order_index)
select v.id, v.title, (select id from jlpt_levels where code = 'N2'), v.order_index
from (values
  ('c909650c-3b90-55c8-9a22-a15291997044'::uuid, 'N2 - Ngữ pháp - Ngày 01', 1),
  ('89a982cf-4961-5acd-af1e-ccbde4ed804e'::uuid, 'N2 - Ngữ pháp - Ngày 02', 2),
  ('a6e2a14c-10e9-5207-a54d-396770af60c6'::uuid, 'N2 - Ngữ pháp - Ngày 03', 3),
  ('4b914119-b666-5568-b70f-25dd3f8fd6e1'::uuid, 'N2 - Ngữ pháp - Ngày 04', 4),
  ('1bd8cd3e-fd9f-54b1-85bc-eb41f364d5ed'::uuid, 'N2 - Ngữ pháp - Ngày 05', 5),
  ('3dac99ad-93ba-5db1-b971-528666c46331'::uuid, 'N2 - Ngữ pháp - Ngày 06', 6),
  ('8b8752df-9404-53d9-a723-a9c70c159cce'::uuid, 'N2 - Ngữ pháp - Ngày 07', 7),
  ('3c915a4f-66ab-5822-adf1-45881e43edfe'::uuid, 'N2 - Ngữ pháp - Ngày 08', 8),
  ('678a78be-236c-56d8-8ea0-876b0d496fad'::uuid, 'N2 - Ngữ pháp - Ngày 09', 9),
  ('4b4c4de7-bb96-5b20-84e3-e8df90fdad8b'::uuid, 'N2 - Ngữ pháp - Ngày 10', 10),
  ('0da3159e-7b1f-5de1-af3e-d822d30006c5'::uuid, 'N2 - Ngữ pháp - Ngày 11', 11),
  ('8ee9ddc6-54a6-55cc-80cb-5b993fdb64d1'::uuid, 'N2 - Ngữ pháp - Ngày 12', 12),
  ('5d155dbb-98c0-5c9d-a740-9f2bbb4b1478'::uuid, 'N2 - Ngữ pháp - Ngày 13', 13),
  ('9f06340f-cf1f-5b38-8f36-f4955fc93ce1'::uuid, 'N2 - Ngữ pháp - Ngày 14', 14),
  ('ef209aab-37b2-5d08-babb-b6342996f71d'::uuid, 'N2 - Ngữ pháp - Ngày 15', 15),
  ('10177dcf-fa23-5b61-abc4-b96dc4df106e'::uuid, 'N2 - Ngữ pháp - Ngày 16', 16),
  ('f9dd7892-7959-5ad7-9f3a-1ac9b280ebd2'::uuid, 'N2 - Ngữ pháp - Ngày 17', 17),
  ('5f203557-1ab8-5dd8-ad96-e80ca9089bae'::uuid, 'N2 - Ngữ pháp - Ngày 18', 18),
  ('40c9a96d-8bd7-5a75-942f-c3795c0d97c6'::uuid, 'N2 - Ngữ pháp - Ngày 19', 19),
  ('cfd2bf39-d233-5f1e-8915-586ddf1aa4e9'::uuid, 'N2 - Ngữ pháp - Ngày 20', 20),
  ('b050a8b5-83ac-55f4-900a-5616912cd949'::uuid, 'N2 - Ngữ pháp - Ngày 21', 21),
  ('bb5f1a0f-7397-5a4f-b8ad-a5ad6dbaa842'::uuid, 'N2 - Ngữ pháp - Ngày 22', 22),
  ('2c9879bf-19ba-5e07-b1f0-5e57aae31da2'::uuid, 'N2 - Ngữ pháp - Ngày 23', 23),
  ('dcadf733-f644-57a5-84d9-31d6c9578f7c'::uuid, 'N2 - Ngữ pháp - Ngày 24', 24),
  ('6a6eed5f-998a-5829-b49e-00392d74f013'::uuid, 'N2 - Ngữ pháp - Ngày 25', 25),
  ('80b63487-1d56-57ca-8d00-249746735b99'::uuid, 'N2 - Ngữ pháp - Ngày 26', 26),
  ('1c2f770a-1f7c-5001-8434-6276d99aab4d'::uuid, 'N2 - Ngữ pháp - Ngày 27', 27),
  ('4e5749cb-9ba9-57cd-8b2a-c9270f861415'::uuid, 'N2 - Ngữ pháp - Ngày 28', 28),
  ('4df91453-a333-5d16-94bd-8fc2ab1eeb12'::uuid, 'N2 - Ngữ pháp - Ngày 29', 29),
  ('9821fc71-69c8-59eb-a521-69bfbe254244'::uuid, 'N2 - Ngữ pháp - Ngày 30', 30),
  ('d0d2eff0-519d-5436-bfca-dfa0e1b9927f'::uuid, 'N2 - Ngữ pháp - Ngày 31', 31),
  ('d73139d5-fe30-50a7-aef2-906c6226d63b'::uuid, 'N2 - Ngữ pháp - Ngày 32', 32),
  ('e8a88724-ff7d-5e46-981b-9f41581606a6'::uuid, 'N2 - Ngữ pháp - Ngày 33', 33),
  ('bdb23f2d-1dea-5161-b1de-fef97ec09e22'::uuid, 'N2 - Ngữ pháp - Ngày 34', 34),
  ('99b7d57f-f4a7-5ffe-a08f-477e8bd116a7'::uuid, 'N2 - Ngữ pháp - Ngày 35', 35),
  ('9fd532b4-41ad-5db0-a4ec-dc94521c512f'::uuid, 'N2 - Ngữ pháp - Ngày 36', 36),
  ('50209e46-946e-5d9c-9215-f35cdb7690c7'::uuid, 'N2 - Ngữ pháp - Ngày 37', 37),
  ('ca5d0172-c25b-57d0-9095-21c407879cc4'::uuid, 'N2 - Ngữ pháp - Ngày 38', 38),
  ('6fde01c9-5e12-5724-a7c5-035ab6a874b7'::uuid, 'N2 - Ngữ pháp - Ngày 39', 39),
  ('2412c1d9-f9fd-54e4-9b77-1c41e43d811d'::uuid, 'N2 - Ngữ pháp - Ngày 40', 40),
  ('4f50a432-24af-509f-8c48-d10501e4d54c'::uuid, 'N2 - Ngữ pháp - Ngày 41', 41),
  ('568e0e59-cf86-5356-a6ca-3f3206ebf2e9'::uuid, 'N2 - Ngữ pháp - Ngày 42', 42),
  ('371298e7-4267-5782-b131-915d4eabae34'::uuid, 'N2 - Ngữ pháp - Ngày 43', 43),
  ('cbac3308-e9d5-5a31-b640-ab9ea89be1c2'::uuid, 'N2 - Ngữ pháp - Ngày 44', 44),
  ('50c151d1-751f-5909-8038-1cf100282d1c'::uuid, 'N2 - Ngữ pháp - Ngày 45', 45),
  ('726e6975-6aa1-5861-a2a2-5fa60eb9a49e'::uuid, 'N2 - Ngữ pháp - Ngày 46', 46),
  ('61bef0c3-468b-5864-a636-33c3e8adfc35'::uuid, 'N2 - Ngữ pháp - Ngày 47', 47),
  ('df51d00e-91df-534c-a5e3-c9cbda53de3f'::uuid, 'N2 - Ngữ pháp - Ngày 48', 48),
  ('155e11b5-409e-5bad-94a4-a7bca067f327'::uuid, 'N2 - Ngữ pháp - Ngày 49', 49),
  ('024ed555-f31a-55f9-a6a3-f2f3f1436fc3'::uuid, 'N2 - Ngữ pháp - Ngày 50', 50),
  ('4cba9574-3756-55d0-8517-f57c5738a008'::uuid, 'N2 - Ngữ pháp - Ngày 51', 51),
  ('187c4b2c-99ea-5b24-8c93-547a6289c4da'::uuid, 'N2 - Ngữ pháp - Ngày 52', 52),
  ('a10b032d-6548-5997-9ebe-fdda833aa8ae'::uuid, 'N2 - Ngữ pháp - Ngày 53', 53),
  ('02c2923a-bb0a-5e5c-8fec-f14b61528f7e'::uuid, 'N2 - Ngữ pháp - Ngày 54', 54),
  ('24762d09-62e4-5624-bc88-f3307f209427'::uuid, 'N2 - Ngữ pháp - Ngày 55', 55),
  ('d7627e39-b28b-5241-9bd1-e98e181d24dc'::uuid, 'N2 - Ngữ pháp - Ngày 56', 56),
  ('a99e77d1-3a49-561a-ab41-14eecfb0a78a'::uuid, 'N2 - Ngữ pháp - Ngày 57', 57),
  ('ccf06572-48c1-5500-959f-3381dd6f2a27'::uuid, 'N2 - Ngữ pháp - Ngày 58', 58)
) as v(id, title, order_index)
on conflict (id) do nothing;

insert into lesson_items (lesson_id, item_type, item_id, order_index)
select v.lesson_id, 'grammar', v.item_id, v.order_index
from (values
  ('c909650c-3b90-55c8-9a22-a15291997044'::uuid, '1921b09f-1fbf-5365-93a8-19df0f52dc2a'::uuid, 0),
  ('c909650c-3b90-55c8-9a22-a15291997044'::uuid, 'b52c5fac-a86e-557a-9a97-6e18a027bc8d'::uuid, 1),
  ('c909650c-3b90-55c8-9a22-a15291997044'::uuid, '9bb0d0f6-5878-51c2-a134-6e7efa2374b1'::uuid, 2),
  ('89a982cf-4961-5acd-af1e-ccbde4ed804e'::uuid, '983b21b1-3f11-5cdb-aaac-1449ab9892b2'::uuid, 0),
  ('89a982cf-4961-5acd-af1e-ccbde4ed804e'::uuid, '7a5bdce1-c437-59d1-9d9b-46ef8dc7916b'::uuid, 1),
  ('89a982cf-4961-5acd-af1e-ccbde4ed804e'::uuid, '960445c3-aa9b-57e2-9948-bb88b409af8f'::uuid, 2),
  ('a6e2a14c-10e9-5207-a54d-396770af60c6'::uuid, '491bbfa2-cf02-582f-94d1-d9b80014d682'::uuid, 0),
  ('a6e2a14c-10e9-5207-a54d-396770af60c6'::uuid, '2b817f7e-e626-547d-9bb6-4baae56d3dc5'::uuid, 1),
  ('a6e2a14c-10e9-5207-a54d-396770af60c6'::uuid, 'd77a1e12-f7d4-5ac2-8d62-de3e71d9312d'::uuid, 2),
  ('4b914119-b666-5568-b70f-25dd3f8fd6e1'::uuid, '2cf50cce-fb26-520c-a819-aed92216a848'::uuid, 0),
  ('4b914119-b666-5568-b70f-25dd3f8fd6e1'::uuid, '86cc8574-9590-5229-8ef0-1af4e4fc68a0'::uuid, 1),
  ('4b914119-b666-5568-b70f-25dd3f8fd6e1'::uuid, '7df4deaf-d5fc-5a27-8f02-26215b350a62'::uuid, 2),
  ('1bd8cd3e-fd9f-54b1-85bc-eb41f364d5ed'::uuid, '721e6341-58cf-51ef-97ef-80504a084229'::uuid, 0),
  ('1bd8cd3e-fd9f-54b1-85bc-eb41f364d5ed'::uuid, '8cfd8bee-b151-5705-a88a-1012faef7b87'::uuid, 1),
  ('1bd8cd3e-fd9f-54b1-85bc-eb41f364d5ed'::uuid, '5bdfa8a2-646b-5039-a65a-dd9f9a9853ee'::uuid, 2),
  ('3dac99ad-93ba-5db1-b971-528666c46331'::uuid, '76dd1cae-6d93-5532-b6ec-fb6962b5e348'::uuid, 0),
  ('3dac99ad-93ba-5db1-b971-528666c46331'::uuid, '1bf5b207-3099-59c4-bb34-0eb2c51a94f4'::uuid, 1),
  ('3dac99ad-93ba-5db1-b971-528666c46331'::uuid, 'be4d2740-8b3b-5dcf-962d-868b11600255'::uuid, 2),
  ('8b8752df-9404-53d9-a723-a9c70c159cce'::uuid, '04ad6c89-1aec-5959-bc3a-0f91f9ba351c'::uuid, 0),
  ('8b8752df-9404-53d9-a723-a9c70c159cce'::uuid, '0b4b8464-a058-5549-b080-6159eb9c051c'::uuid, 1),
  ('8b8752df-9404-53d9-a723-a9c70c159cce'::uuid, '6dcbe538-f87a-5430-840f-02ab7852f884'::uuid, 2),
  ('3c915a4f-66ab-5822-adf1-45881e43edfe'::uuid, 'adaa166d-4593-5550-89f4-c56c6a99588d'::uuid, 0),
  ('3c915a4f-66ab-5822-adf1-45881e43edfe'::uuid, '11d8b93c-d18f-5ebe-ba5f-8265ea914125'::uuid, 1),
  ('3c915a4f-66ab-5822-adf1-45881e43edfe'::uuid, 'adba2ced-32cf-54ce-9253-63a6d0c53582'::uuid, 2),
  ('678a78be-236c-56d8-8ea0-876b0d496fad'::uuid, 'b0de3c0d-9b20-52b2-926c-e509a4e2cdff'::uuid, 0),
  ('678a78be-236c-56d8-8ea0-876b0d496fad'::uuid, '83440e36-c0e8-5348-ae59-ac6c1b5fb8d9'::uuid, 1),
  ('678a78be-236c-56d8-8ea0-876b0d496fad'::uuid, 'de24af09-ce78-51e3-9cd9-12a84e2d15c3'::uuid, 2),
  ('4b4c4de7-bb96-5b20-84e3-e8df90fdad8b'::uuid, 'fecf43ad-1cd9-56c3-84b1-50d6991ed506'::uuid, 0),
  ('4b4c4de7-bb96-5b20-84e3-e8df90fdad8b'::uuid, '0f965e51-bdba-5f79-92b8-086e2979c5b8'::uuid, 1),
  ('4b4c4de7-bb96-5b20-84e3-e8df90fdad8b'::uuid, '422637ac-2be5-57e6-bf68-cb2483b22929'::uuid, 2),
  ('0da3159e-7b1f-5de1-af3e-d822d30006c5'::uuid, '02785054-b90e-57c4-823d-7c37ddb975b4'::uuid, 0),
  ('0da3159e-7b1f-5de1-af3e-d822d30006c5'::uuid, 'dcc89bc9-11ac-559d-9700-deb776657468'::uuid, 1),
  ('0da3159e-7b1f-5de1-af3e-d822d30006c5'::uuid, '074c29ad-b1a7-5397-a22c-e803f8bf57c9'::uuid, 2),
  ('8ee9ddc6-54a6-55cc-80cb-5b993fdb64d1'::uuid, 'd13193ab-9376-5d91-99eb-1d128c2ad1b8'::uuid, 0),
  ('8ee9ddc6-54a6-55cc-80cb-5b993fdb64d1'::uuid, 'ee7e301d-9344-507b-925b-95e909465bd7'::uuid, 1),
  ('8ee9ddc6-54a6-55cc-80cb-5b993fdb64d1'::uuid, '74403438-1728-5da6-aae7-216051b284ab'::uuid, 2),
  ('5d155dbb-98c0-5c9d-a740-9f2bbb4b1478'::uuid, '0dc53113-6a7c-5cce-b145-edae7f422710'::uuid, 0),
  ('5d155dbb-98c0-5c9d-a740-9f2bbb4b1478'::uuid, '917cc76e-220b-5483-bb52-d0c164e256cd'::uuid, 1),
  ('5d155dbb-98c0-5c9d-a740-9f2bbb4b1478'::uuid, '62735d76-82f7-5e51-a68d-b559c3b527b9'::uuid, 2),
  ('9f06340f-cf1f-5b38-8f36-f4955fc93ce1'::uuid, 'ed4c8c54-0f96-5d0c-8d1f-1c66a4904774'::uuid, 0),
  ('9f06340f-cf1f-5b38-8f36-f4955fc93ce1'::uuid, 'b5bf7b83-ce89-5b9e-a4bb-cff2490b208c'::uuid, 1),
  ('9f06340f-cf1f-5b38-8f36-f4955fc93ce1'::uuid, '9fad7ab0-1d4a-5af6-8365-914a013cad80'::uuid, 2),
  ('ef209aab-37b2-5d08-babb-b6342996f71d'::uuid, 'a639da1f-8b8f-5b2d-9751-786159697347'::uuid, 0),
  ('ef209aab-37b2-5d08-babb-b6342996f71d'::uuid, '256e8bf6-7e89-5cef-9b96-2ca27fcb4c93'::uuid, 1),
  ('ef209aab-37b2-5d08-babb-b6342996f71d'::uuid, '81b0db01-98ae-5b1d-80c7-e5191aff4639'::uuid, 2),
  ('10177dcf-fa23-5b61-abc4-b96dc4df106e'::uuid, '72fa61cf-d235-5ba7-9a95-783c9a4499a7'::uuid, 0),
  ('10177dcf-fa23-5b61-abc4-b96dc4df106e'::uuid, '4486b45f-2f83-5c4e-bf43-1b73db957c34'::uuid, 1),
  ('10177dcf-fa23-5b61-abc4-b96dc4df106e'::uuid, 'd3c375f5-c444-52a2-bdea-bc03fb182ab2'::uuid, 2),
  ('f9dd7892-7959-5ad7-9f3a-1ac9b280ebd2'::uuid, '792bbf45-d4ab-59a2-a63a-5e1830d763e1'::uuid, 0),
  ('f9dd7892-7959-5ad7-9f3a-1ac9b280ebd2'::uuid, '79dfd539-f264-59f6-b1c4-f0f3fd3bb1df'::uuid, 1),
  ('f9dd7892-7959-5ad7-9f3a-1ac9b280ebd2'::uuid, 'b18dba91-a707-501d-9c7c-11545cc0d4f2'::uuid, 2),
  ('5f203557-1ab8-5dd8-ad96-e80ca9089bae'::uuid, '87c3f6a3-91df-5663-92d5-4a49c80176ed'::uuid, 0),
  ('5f203557-1ab8-5dd8-ad96-e80ca9089bae'::uuid, '5f85e3b8-45e9-597a-a36e-c2e474a6655b'::uuid, 1),
  ('5f203557-1ab8-5dd8-ad96-e80ca9089bae'::uuid, '5fb295b1-250c-5589-9d92-113a71996c03'::uuid, 2),
  ('40c9a96d-8bd7-5a75-942f-c3795c0d97c6'::uuid, '3849c416-5eaa-53c3-85ef-3b00b31965ef'::uuid, 0),
  ('40c9a96d-8bd7-5a75-942f-c3795c0d97c6'::uuid, '140f881f-f9a7-5fc5-9e1d-d656a31326b3'::uuid, 1),
  ('40c9a96d-8bd7-5a75-942f-c3795c0d97c6'::uuid, '7789a2ae-6ab9-5f87-b72b-5804d8b8d670'::uuid, 2),
  ('cfd2bf39-d233-5f1e-8915-586ddf1aa4e9'::uuid, '52481372-d585-571e-b6eb-92a9bb273562'::uuid, 0),
  ('cfd2bf39-d233-5f1e-8915-586ddf1aa4e9'::uuid, '8461602d-154e-5ec3-b1b8-c5f5019c8e69'::uuid, 1),
  ('cfd2bf39-d233-5f1e-8915-586ddf1aa4e9'::uuid, '77b4f91c-ed61-5c6a-a0ba-4642619e4072'::uuid, 2),
  ('b050a8b5-83ac-55f4-900a-5616912cd949'::uuid, 'ca07e76b-c745-54a5-be8a-efc20cbd1279'::uuid, 0),
  ('b050a8b5-83ac-55f4-900a-5616912cd949'::uuid, '4ff96bde-949b-55f7-bde5-62010d6f9679'::uuid, 1),
  ('b050a8b5-83ac-55f4-900a-5616912cd949'::uuid, 'b3743175-3ba4-55f2-b20c-41584e7e80aa'::uuid, 2),
  ('bb5f1a0f-7397-5a4f-b8ad-a5ad6dbaa842'::uuid, 'b9855857-1ce7-53fa-80e1-e1b739a31536'::uuid, 0),
  ('bb5f1a0f-7397-5a4f-b8ad-a5ad6dbaa842'::uuid, 'dcc94866-8278-5fbc-9e5b-45d458fab014'::uuid, 1),
  ('bb5f1a0f-7397-5a4f-b8ad-a5ad6dbaa842'::uuid, '843e56f6-7498-5c28-91f3-e40bbd75e4f2'::uuid, 2),
  ('2c9879bf-19ba-5e07-b1f0-5e57aae31da2'::uuid, '5f8e77a7-de5a-5b71-9b66-64e268f9c313'::uuid, 0),
  ('2c9879bf-19ba-5e07-b1f0-5e57aae31da2'::uuid, '32b4a3e9-e90d-50f9-826f-4daff0de76f9'::uuid, 1),
  ('2c9879bf-19ba-5e07-b1f0-5e57aae31da2'::uuid, '3fe7a7f3-f3ee-5c6c-b3cf-0bdef57d61c3'::uuid, 2),
  ('dcadf733-f644-57a5-84d9-31d6c9578f7c'::uuid, 'ad6d170d-972c-5c40-94f0-c91dc1e343d9'::uuid, 0),
  ('dcadf733-f644-57a5-84d9-31d6c9578f7c'::uuid, '110dd542-cf98-5797-a447-02d58948b232'::uuid, 1),
  ('dcadf733-f644-57a5-84d9-31d6c9578f7c'::uuid, '8e54813b-653e-528d-ab40-34f6f73f3952'::uuid, 2),
  ('6a6eed5f-998a-5829-b49e-00392d74f013'::uuid, 'd83478d4-31e5-526e-b3ee-96446f360edc'::uuid, 0),
  ('6a6eed5f-998a-5829-b49e-00392d74f013'::uuid, 'f0bbd3b6-0f36-5982-b720-7aa48a97637d'::uuid, 1),
  ('6a6eed5f-998a-5829-b49e-00392d74f013'::uuid, '5fd772ab-852e-500c-a46f-69576c71637c'::uuid, 2),
  ('80b63487-1d56-57ca-8d00-249746735b99'::uuid, '7742ff4b-2662-54c3-bed4-d52e66214d01'::uuid, 0),
  ('80b63487-1d56-57ca-8d00-249746735b99'::uuid, 'e4ca7e6a-87bb-5edd-97cb-4457b7320752'::uuid, 1),
  ('80b63487-1d56-57ca-8d00-249746735b99'::uuid, '3f93139c-7329-5354-a390-fa53ab2e2d0b'::uuid, 2),
  ('1c2f770a-1f7c-5001-8434-6276d99aab4d'::uuid, '6c34ada8-0c7f-5d88-ac0a-17741abe020b'::uuid, 0),
  ('1c2f770a-1f7c-5001-8434-6276d99aab4d'::uuid, '342be15f-8a32-5ec9-930c-6a459f9eb1a7'::uuid, 1),
  ('1c2f770a-1f7c-5001-8434-6276d99aab4d'::uuid, 'c50ccc0f-9ed1-5553-85bb-723d459aea5d'::uuid, 2),
  ('4e5749cb-9ba9-57cd-8b2a-c9270f861415'::uuid, '5dc620c8-15c8-59d7-920d-a68535c83c66'::uuid, 0),
  ('4e5749cb-9ba9-57cd-8b2a-c9270f861415'::uuid, 'd3204ecb-749b-5898-acd0-d8bb814f5bb2'::uuid, 1),
  ('4e5749cb-9ba9-57cd-8b2a-c9270f861415'::uuid, '37845388-102d-5abb-a12e-8a60aa26ab74'::uuid, 2),
  ('4df91453-a333-5d16-94bd-8fc2ab1eeb12'::uuid, 'a42e83c5-1b8c-551a-9e00-65c1a3b54d23'::uuid, 0),
  ('4df91453-a333-5d16-94bd-8fc2ab1eeb12'::uuid, 'd9c79c98-8177-5019-8af1-13df14f67502'::uuid, 1),
  ('4df91453-a333-5d16-94bd-8fc2ab1eeb12'::uuid, '67c058b5-f614-5748-8785-335198fc0a61'::uuid, 2),
  ('9821fc71-69c8-59eb-a521-69bfbe254244'::uuid, '1c9fbc04-eceb-5c40-86a5-6ff11df13ed5'::uuid, 0),
  ('9821fc71-69c8-59eb-a521-69bfbe254244'::uuid, '0bdd119f-70b9-5011-8e5c-769cac70abee'::uuid, 1),
  ('9821fc71-69c8-59eb-a521-69bfbe254244'::uuid, '8f5a53ef-c933-5d66-9ede-2a00dec9377e'::uuid, 2),
  ('d0d2eff0-519d-5436-bfca-dfa0e1b9927f'::uuid, 'da25d60c-c1c4-559b-a1c2-522b362cab91'::uuid, 0),
  ('d0d2eff0-519d-5436-bfca-dfa0e1b9927f'::uuid, '3040e16c-734e-5a29-ad1c-4d5490083ddb'::uuid, 1),
  ('d0d2eff0-519d-5436-bfca-dfa0e1b9927f'::uuid, '23d271c5-1079-5eba-9172-47540aa60bea'::uuid, 2),
  ('d73139d5-fe30-50a7-aef2-906c6226d63b'::uuid, '7aba60a4-1e30-56cb-84b3-8ff2770dc4c8'::uuid, 0),
  ('d73139d5-fe30-50a7-aef2-906c6226d63b'::uuid, 'f8efbc69-a93b-5167-aa1c-8eefb58ec8ba'::uuid, 1),
  ('d73139d5-fe30-50a7-aef2-906c6226d63b'::uuid, '51643c2b-e39f-569a-bf44-59fd6b1b2c98'::uuid, 2),
  ('e8a88724-ff7d-5e46-981b-9f41581606a6'::uuid, '2048a890-2bd9-57ca-ba42-bccc0bd9072a'::uuid, 0),
  ('e8a88724-ff7d-5e46-981b-9f41581606a6'::uuid, '43c4dc99-b104-5bb9-9b14-893e801c6329'::uuid, 1),
  ('e8a88724-ff7d-5e46-981b-9f41581606a6'::uuid, 'a6d6b6ca-b76e-5e42-8987-7e7c6bc3db60'::uuid, 2),
  ('bdb23f2d-1dea-5161-b1de-fef97ec09e22'::uuid, '84967df5-38fc-5e83-939f-18187cd3d726'::uuid, 0),
  ('bdb23f2d-1dea-5161-b1de-fef97ec09e22'::uuid, '7e27e51b-904e-562a-a05d-528fe4e8ae69'::uuid, 1),
  ('bdb23f2d-1dea-5161-b1de-fef97ec09e22'::uuid, '18880439-52b8-543f-b677-bd88f1294a7c'::uuid, 2),
  ('99b7d57f-f4a7-5ffe-a08f-477e8bd116a7'::uuid, 'df73635e-28bf-55c6-83f8-0cbcee5270d6'::uuid, 0),
  ('99b7d57f-f4a7-5ffe-a08f-477e8bd116a7'::uuid, 'f03c017f-002a-5d12-a087-db3a7ddcb1b2'::uuid, 1),
  ('99b7d57f-f4a7-5ffe-a08f-477e8bd116a7'::uuid, '8fce49b4-8c4a-5e20-8cf0-2d0155ca3cec'::uuid, 2),
  ('9fd532b4-41ad-5db0-a4ec-dc94521c512f'::uuid, 'abacbae4-1fed-5db4-b40e-0013e84c415d'::uuid, 0),
  ('9fd532b4-41ad-5db0-a4ec-dc94521c512f'::uuid, 'e59ca8a9-1ffb-5053-a5ad-da17c1a4a679'::uuid, 1),
  ('9fd532b4-41ad-5db0-a4ec-dc94521c512f'::uuid, 'bd66dccb-10cc-5c13-9fe1-57d02a4e0dcd'::uuid, 2),
  ('50209e46-946e-5d9c-9215-f35cdb7690c7'::uuid, 'c5a9b060-170e-5670-87ea-41b5e21278c7'::uuid, 0),
  ('50209e46-946e-5d9c-9215-f35cdb7690c7'::uuid, 'e78677cf-9b8c-5516-b202-da2a76b6b408'::uuid, 1),
  ('50209e46-946e-5d9c-9215-f35cdb7690c7'::uuid, '5f22e3d0-6d15-5622-a084-cd95dde9c59f'::uuid, 2),
  ('ca5d0172-c25b-57d0-9095-21c407879cc4'::uuid, 'e7e02dc7-2373-5e25-9d44-1243f2a01dd7'::uuid, 0),
  ('ca5d0172-c25b-57d0-9095-21c407879cc4'::uuid, 'c4463748-e964-5f16-9d62-7540e094f1a0'::uuid, 1),
  ('ca5d0172-c25b-57d0-9095-21c407879cc4'::uuid, 'c8ec66a0-1068-5a52-96db-78a2cb83c363'::uuid, 2),
  ('6fde01c9-5e12-5724-a7c5-035ab6a874b7'::uuid, 'd894b666-2951-51db-8b94-2f53242c081a'::uuid, 0),
  ('6fde01c9-5e12-5724-a7c5-035ab6a874b7'::uuid, '86c19e26-a4d3-5bb3-9203-31c08e38a1af'::uuid, 1),
  ('6fde01c9-5e12-5724-a7c5-035ab6a874b7'::uuid, 'e9359294-7fc5-5d5f-bb3c-1be7c173e325'::uuid, 2),
  ('2412c1d9-f9fd-54e4-9b77-1c41e43d811d'::uuid, '5373979f-3266-57de-8d7e-5e91c88e4b21'::uuid, 0),
  ('2412c1d9-f9fd-54e4-9b77-1c41e43d811d'::uuid, 'e3bf3c4f-df54-5355-8d2e-d40a45643de8'::uuid, 1),
  ('2412c1d9-f9fd-54e4-9b77-1c41e43d811d'::uuid, 'a67fbf7f-eff3-591d-8f87-3fc1d02d3ebc'::uuid, 2),
  ('4f50a432-24af-509f-8c48-d10501e4d54c'::uuid, '407e941f-d553-5cdb-a59c-49c319bfa011'::uuid, 0),
  ('4f50a432-24af-509f-8c48-d10501e4d54c'::uuid, '5e847563-7cc0-52e9-bf72-ac35f6cd709d'::uuid, 1),
  ('4f50a432-24af-509f-8c48-d10501e4d54c'::uuid, '101950ca-f9dc-5e0a-af92-d5a60e0501db'::uuid, 2),
  ('568e0e59-cf86-5356-a6ca-3f3206ebf2e9'::uuid, '4742bf49-01e0-5175-8ff8-301d815080a7'::uuid, 0),
  ('568e0e59-cf86-5356-a6ca-3f3206ebf2e9'::uuid, '96e95e99-7c98-58e3-92c5-623757f945c1'::uuid, 1),
  ('568e0e59-cf86-5356-a6ca-3f3206ebf2e9'::uuid, 'da9f9d45-7f3a-5776-aad7-9e45bf7f6f6e'::uuid, 2),
  ('371298e7-4267-5782-b131-915d4eabae34'::uuid, 'ba392bc6-f0bd-5d28-ad2e-b15b6552af4c'::uuid, 0),
  ('371298e7-4267-5782-b131-915d4eabae34'::uuid, 'ed84433f-99f4-5276-a16a-d6dad066f4ae'::uuid, 1),
  ('371298e7-4267-5782-b131-915d4eabae34'::uuid, '1b600119-47d5-5f0d-8bdd-b2ac7818652b'::uuid, 2),
  ('cbac3308-e9d5-5a31-b640-ab9ea89be1c2'::uuid, 'ae305f71-3dbf-58bf-8ca6-0e11a816b5e7'::uuid, 0),
  ('cbac3308-e9d5-5a31-b640-ab9ea89be1c2'::uuid, '454ba874-b67b-5748-a136-62b0e7eef704'::uuid, 1),
  ('cbac3308-e9d5-5a31-b640-ab9ea89be1c2'::uuid, 'e1ce5d7d-ca68-5f88-90d1-45fb8711be9f'::uuid, 2),
  ('50c151d1-751f-5909-8038-1cf100282d1c'::uuid, 'eaa03502-8b37-57df-a862-755d8293bb6b'::uuid, 0),
  ('50c151d1-751f-5909-8038-1cf100282d1c'::uuid, '50f67271-14e8-5fbd-9dbe-87e9273a6c52'::uuid, 1),
  ('50c151d1-751f-5909-8038-1cf100282d1c'::uuid, '7c0e4d39-7a24-50a6-84c4-7188abda0b4c'::uuid, 2),
  ('726e6975-6aa1-5861-a2a2-5fa60eb9a49e'::uuid, '067c170e-f9d0-5751-877c-2255b4b26fe3'::uuid, 0),
  ('726e6975-6aa1-5861-a2a2-5fa60eb9a49e'::uuid, 'a37a2314-3d3c-5d43-8d82-e29c4f5a96ec'::uuid, 1),
  ('726e6975-6aa1-5861-a2a2-5fa60eb9a49e'::uuid, '53192181-3270-5531-b814-3838cb2dfd6e'::uuid, 2),
  ('61bef0c3-468b-5864-a636-33c3e8adfc35'::uuid, '249f3fb1-3af6-57e1-ae20-22f987f1327a'::uuid, 0),
  ('61bef0c3-468b-5864-a636-33c3e8adfc35'::uuid, 'add26f26-19b1-56f2-894a-da66ff930d1e'::uuid, 1),
  ('61bef0c3-468b-5864-a636-33c3e8adfc35'::uuid, '297ff504-7e15-5d74-8ea9-f047632546c1'::uuid, 2),
  ('df51d00e-91df-534c-a5e3-c9cbda53de3f'::uuid, '91769b0a-2bd5-5e1a-90f7-906262c0ae56'::uuid, 0),
  ('df51d00e-91df-534c-a5e3-c9cbda53de3f'::uuid, '56cca1e0-8a0f-55a3-9080-dad70be71c48'::uuid, 1),
  ('df51d00e-91df-534c-a5e3-c9cbda53de3f'::uuid, '602d8323-dc2f-5905-8e85-ec6794de64c7'::uuid, 2),
  ('155e11b5-409e-5bad-94a4-a7bca067f327'::uuid, '7910fc87-19a7-5ad3-8c4e-29ac3139dfef'::uuid, 0),
  ('155e11b5-409e-5bad-94a4-a7bca067f327'::uuid, '10524dd0-6c9e-57bc-b02e-9bd1221dd8fc'::uuid, 1),
  ('155e11b5-409e-5bad-94a4-a7bca067f327'::uuid, 'a6a1abd1-0797-5c70-a166-5499f2e74125'::uuid, 2),
  ('024ed555-f31a-55f9-a6a3-f2f3f1436fc3'::uuid, 'b3c70803-1972-54b5-a4ac-e2efdf07c248'::uuid, 0),
  ('024ed555-f31a-55f9-a6a3-f2f3f1436fc3'::uuid, 'e0021672-ea01-51b0-b3f9-ef1d53c1810e'::uuid, 1),
  ('024ed555-f31a-55f9-a6a3-f2f3f1436fc3'::uuid, '4ad455d8-684b-543a-9394-71099d4ede9b'::uuid, 2),
  ('4cba9574-3756-55d0-8517-f57c5738a008'::uuid, 'fb6b51c3-110a-5db8-9768-0d1ccbc52113'::uuid, 0),
  ('4cba9574-3756-55d0-8517-f57c5738a008'::uuid, '19df5692-ae88-5c30-9c95-3adaad177f41'::uuid, 1),
  ('4cba9574-3756-55d0-8517-f57c5738a008'::uuid, '7ae0fa26-ebf6-5e9b-88ec-56ea03e7f993'::uuid, 2),
  ('187c4b2c-99ea-5b24-8c93-547a6289c4da'::uuid, 'c6d1a9c9-3f20-5767-bc69-842e946469ad'::uuid, 0),
  ('187c4b2c-99ea-5b24-8c93-547a6289c4da'::uuid, 'ed8b25e1-7f70-5d18-8bac-fb8f53a62cec'::uuid, 1),
  ('187c4b2c-99ea-5b24-8c93-547a6289c4da'::uuid, 'fde8ad60-9e2a-5f78-9cb4-6f0a5d9b5562'::uuid, 2),
  ('a10b032d-6548-5997-9ebe-fdda833aa8ae'::uuid, '42329718-c8ed-5087-b2b0-66905703ebed'::uuid, 0),
  ('a10b032d-6548-5997-9ebe-fdda833aa8ae'::uuid, 'f61c519b-c740-52ae-90c7-e3b5b7113cce'::uuid, 1),
  ('a10b032d-6548-5997-9ebe-fdda833aa8ae'::uuid, '716ff311-2b10-54f4-85c8-59b26f813ca0'::uuid, 2),
  ('02c2923a-bb0a-5e5c-8fec-f14b61528f7e'::uuid, 'f32cca1e-be43-50a2-8941-09c45ba8d50b'::uuid, 0),
  ('02c2923a-bb0a-5e5c-8fec-f14b61528f7e'::uuid, '9367e74f-8b52-5a7b-bc6f-b240f2910605'::uuid, 1),
  ('02c2923a-bb0a-5e5c-8fec-f14b61528f7e'::uuid, '394efb4b-62aa-5d4f-8363-61c0e8bbca98'::uuid, 2),
  ('24762d09-62e4-5624-bc88-f3307f209427'::uuid, '63f04138-ef13-52b5-88bb-0fe3a93f67ee'::uuid, 0),
  ('24762d09-62e4-5624-bc88-f3307f209427'::uuid, '4a725390-a19e-5c96-95d1-d52c1423e201'::uuid, 1),
  ('24762d09-62e4-5624-bc88-f3307f209427'::uuid, '4308595c-2e98-51c3-99c5-1632f9bf593e'::uuid, 2),
  ('d7627e39-b28b-5241-9bd1-e98e181d24dc'::uuid, '4eba2dd2-1e66-5322-96d9-e909de572b72'::uuid, 0),
  ('d7627e39-b28b-5241-9bd1-e98e181d24dc'::uuid, 'b1ed521e-682a-50cb-a334-ed3b6873113c'::uuid, 1),
  ('d7627e39-b28b-5241-9bd1-e98e181d24dc'::uuid, 'd9906b06-5055-58cf-a738-476167d8ae1e'::uuid, 2),
  ('a99e77d1-3a49-561a-ab41-14eecfb0a78a'::uuid, '8f934117-524a-5223-8776-8bf055ff9e77'::uuid, 0),
  ('a99e77d1-3a49-561a-ab41-14eecfb0a78a'::uuid, 'e68ad52b-82b1-5896-98a7-b5549d7262c9'::uuid, 1),
  ('a99e77d1-3a49-561a-ab41-14eecfb0a78a'::uuid, '724bfcee-88a8-5b54-8a31-2cb977b7e868'::uuid, 2),
  ('ccf06572-48c1-5500-959f-3381dd6f2a27'::uuid, 'cd5a0c03-c1bc-5e27-b314-fcdf65116b92'::uuid, 0),
  ('ccf06572-48c1-5500-959f-3381dd6f2a27'::uuid, '169c4ebe-35cd-5993-8974-ee4294c7c02c'::uuid, 1)
) as v(lesson_id, item_id, order_index)
on conflict (lesson_id, item_type, item_id) do nothing;

