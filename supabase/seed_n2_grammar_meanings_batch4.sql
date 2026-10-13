-- N2 grammar meanings + enrichment — batch 4 (bunpo_N2.pdf trang 61-80)
-- Nguồn: 完全マスター 日本語能力試験2級 文法 (mục 138–173).
-- Trang 76-80 là phần 索引 (mục lục tra cứu), không có nội dung giải thích mới.
-- Đối chiếu 36 mục (138-173) với n2_grammar_id_title.tsv: TẤT CẢ đều khớp chính xác,
-- không có mục nào ghi "KHÔNG KHỚP".

-- ============ grammar_meanings ============

-- 138 ～つつ／～つつも
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('53192181-3270-5531-b814-3838cb2dfd6e', 0, 'Diễn tả hai hành động xảy ra đồng thời (nghĩa gần với ながら), thường dùng trong văn viết trang trọng.', ARRAY['財布の中身を考えつつ、買い物をした。','人は皆、お互いに助け合いつつ生きている。']::text[], ARRAY['Vừa nghĩ đến ví vừa đi mua hàng.','Mọi người vẫn đang sống tương trợ lẫn nhau.']::text[]);
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('53192181-3270-5531-b814-3838cb2dfd6e', 1, 'Diễn tả sự nhượng bộ, nghĩa là "dù biết A nhưng vẫn làm B" (gần nghĩa けれども).', ARRAY['悪いと知りつつ、うそをついてしまった。','今日こそ勉強しようと思いつつ、テレビを見てしまった。']::text[], ARRAY['Dù biết là xấu nhưng lại nói dối mất rồi.','Chính hôm nay nghĩ là muốn học đây nhưng lại xem TV.']::text[]);

-- 139 ～てからでないと／～てからでなければ
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('249f3fb1-3af6-57e1-ae20-22f987f1327a', 0, 'Nếu chưa làm A trước thì B không thể xảy ra/thực hiện được (vế sau luôn là câu phủ định).', ARRAY['お金をいただいてからでないと、商品はお届けできません。','この仕事は訓練を受けてからでないと無理でしょう。']::text[], ARRAY['Nếu chưa nhận được tiền thì hàng cũng không giao được.','Công việc này mà không được huấn luyện thì không làm được đâu.']::text[]);

-- 140 ～といっても
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('add26f26-19b1-56f2-894a-da66ff930d1e', 0, 'Nói là ~ nhưng thực tế lại khác/kém hơn so với những gì câu trước gợi ý.', ARRAY['庭があるといっても猫の額ほどです。','日本は物価が高いといっても、安いものもありますよ。']::text[], ARRAY['Nói là có vườn đấy nhưng mà bé tí (như cái đầu trán mèo).','Nhật Bản thì đúng là giá cả cao thật nhưng cũng có đồ rẻ cũng có mà.']::text[]);

-- 141 ～どころか
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('297ff504-7e15-5d74-8ea9-f047632546c1', 0, 'Nhấn mạnh sự phủ định mạnh hoặc trái ngược hoàn toàn với điều vừa nêu, "nói gì đến... còn...".', ARRAY['彼は貯金するどころか借金だらけだ。','あの人は英語どころかアラビア語もスワヒリ語も話せる。']::text[], ARRAY['Anh ta mà có tiết kiệm à, nợ nần chồng chất kìa.','Ông kia đâu chỉ biết tiếng Anh, tiếng Arab rồi là Swahili nữa cũng nói được.']::text[]);

-- 142 ～としたら／～とすれば
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('91769b0a-2bd5-5e1a-90f7-906262c0ae56', 0, 'Đặt ra một giả định "nếu là..." rồi nêu mong muốn/kết quả kèm theo (biểu thị giả định).', ARRAY['留学するとしたら、日本に行きたいと思っていました。','予定どおりだとすれば、飛行機は9時に着くはずだ。']::text[], ARRAY['Nếu mà đi du học, tôi đã định đi Nhật.','Nếu mà như kế hoạch thì máy bay phải đến lúc 9h rồi.']::text[]);
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('91769b0a-2bd5-5e1a-90f7-906262c0ae56', 1, 'Đặt giả thiết rồi suy luận logic từ giả thiết đó, "nếu xét từ..., nếu nghĩ từ... thì".', ARRAY['足の悪い人が地下鉄を利用するとしたら、どんな設備が必要だろうか。','この冷蔵庫はもう修理は無理ですね。修理が無理だとしたら、新しいのを買うしかありませんね。']::text[], ARRAY['Nếu người bị tật về chân sử dụng tàu điện ngầm thì cần loại thiết bị như thế nào nhỉ.','Cái tủ lạnh này đã không sửa được nữa nhỉ? Nếu mà không sửa được thì chỉ có cách mua cái mới nhỉ.']::text[]);

-- 143 ～ないことには
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('56cca1e0-8a0f-55a3-9080-dad70be71c48', 0, 'Nếu không làm/không có A thì không thể có B (vế sau luôn mang nghĩa phủ định).', ARRAY['実際に読まないことには、この小説の面白さはわからないだろう。','体が丈夫でないことには、この仕事は無理だ。']::text[], ARRAY['Nếu mà chưa đọc thì không biết được độ hấp dẫn của tiểu thuyết này đâu.','Nếu mà không dai sức thì không thể làm việc này.']::text[]);

-- 144 ～ながら (nghĩa nhượng bộ)
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('602d8323-dc2f-5905-8e85-ec6794de64c7', 0, 'Mang nghĩa nhượng bộ "mặc dù... nhưng vẫn..." (khác nghĩa "vừa...vừa..." đã học ở N4).', ARRAY['一緒に暮らしていながら、母の病気に気づかなかった。','彼は仕事は遅いながら、確実で安心して任せられる。']::text[], ARRAY['Sống cùng một nhà vậy mà không nhận ra bệnh của mẹ.','Anh ta làm việc thì hơi chậm nhưng được cái chắc chắn tôi đã yên tâm tin cậy giao phó.']::text[]);

-- 145 ～にしては
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('7910fc87-19a7-5ad3-8c4e-29ac3139dfef', 0, 'So với tiêu chuẩn/kỳ vọng thông thường thì thực tế lại khác, thường mang sắc thái bất ngờ, thất vọng nhẹ.', ARRAY['兄はアメリカに20年いたにしては英語が下手だ。','彼は歌手だったにしては歌が下手だ。']::text[], ARRAY['Dù anh trai sống ở Mỹ đến 20 năm nhưng tiếng Anh thì dở ẹc.','Anh ta là ca sĩ đấy nhưng hát dở tệ.']::text[]);

-- 146 ～にしろ／～に（も）せよ／～にしても
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('10524dd0-6c9e-57bc-b02e-9bd1221dd8fc', 0, 'Dù là ~ đi nữa thì (kết quả/nhận định vẫn không đổi), mang nghĩa nhượng bộ.', ARRAY['どんな人間にしろ長所はあるものだ。','いくら体が丈夫であるにせよ、そんなに働いたら病気になりますよ。']::text[], ARRAY['Dù là người nào thì cũng có sở trường.','Dù đai sức thế nào đi nữa, làm việc cỡ đó thì ốm mất đấy.']::text[]);
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('10524dd0-6c9e-57bc-b02e-9bd1221dd8fc', 1, 'Liệt kê 2 trường hợp đối lập để nói "dù là cái nào cũng như nhau, đều...".', ARRAY['ビールにしろ、日本酒にしろ飲んだら運転できない。','自分でやるにしても、人に頼むにしてもこれは時間がかかる。']::text[], ARRAY['Bia cũng thế, rượu cũng thế, đã uống vào thì không lái xe được.','Tự làm hay nhờ người khác làm thì việc này đều tốn thời gian.']::text[]);

-- 147 ～にかかわらず／～に（は）かかわりなく
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('a6a1abd1-0797-5c70-a166-5499f2e74125', 0, 'Không liên quan/không phân biệt đến điều vừa nêu, thường đi sau cặp từ đối lập.', ARRAY['参加するしないにかかわらず、必ず返事をください。','このゲームは、年齢や性別にかかわらず、だれでも楽しめる。']::text[], ARRAY['Không tính là có tham gia hay không, nhất định hãy trả lời nhé.','Trò chơi này không phân biệt tuổi tác, giới tính, ai cũng thích.']::text[]);

-- 148 ～にもかかわらず
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('b3c70803-1972-54b5-a4ac-e2efdf07c248', 0, 'Mặc dù ~, dẫu cho ~ (mang sắc thái ngạc nhiên hoặc đáng tiếc so với kết quả).', ARRAY['彼は熱があるにもかかわらず、サッカーの試合に出場した。','そのパソコンは操作が複雑であるにもかかわらず、よく売れている。']::text[], ARRAY['Anh ta dù bị sốt nhưng vẫn ra sân thi đấu bóng đá.','Cái máy tính này dù thao tác phức tạp nhưng vẫn bán chạy.']::text[]);

-- 149 ～ぬきで（は）／～ぬきに（は）／～ぬきの／～をぬきにして（は）／～はぬきにして
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('e0021672-ea01-51b0-b3f9-ef1d53c1810e', 0, 'Không có ~, không kèm theo ~ (ở trạng thái thiếu/lược bỏ danh từ đó).', ARRAY['朝食ぬきで会社へ行くサラリーマンが多いらしい。','彼女は世辞ぬきにすばらしい人だ。']::text[], ARRAY['Có vẻ nhiều nhân viên công ty đi làm mà không ăn sáng.','Không cần một lời khen, cô ấy là người tuyệt vời.']::text[]);

-- 150 ～のみならず
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('4ad455d8-684b-543a-9394-71099d4ede9b', 0, 'Không chỉ ~ mà còn ~ (văn trang trọng, gần nghĩa だけでなく nhưng dùng trong văn viết).', ARRAY['このコンピューターは性能が優れているのみならず、操作も簡単だ。','学生のみならず、教師もスポーツ大会に参加することになっている。']::text[], ARRAY['Máy tính này không chỉ vượt trội về tính năng mà sử dụng còn dễ dàng.','Không chỉ sinh viên mà các thầy cô giáo cũng tham gia vào đại hội thể thao.']::text[]);

-- 151 ～反面／～半面
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('fb6b51c3-110a-5db8-9768-0d1ccbc52113', 0, 'Ở một mặt thì như vậy, nhưng nhìn ở mặt khác lại khác hẳn (2 mặt đối lập của cùng một sự vật).', ARRAY['この薬はよくきく反面、副作用がある。','彼はわがままな反面リーダーシップがある。']::text[], ARRAY['Thuốc này có tác dụng tốt nhưng mặt trái cũng gây tác dụng phụ.','Trái với tính cách ích kỷ, anh ta có khả năng lãnh đạo.']::text[]);

-- 152 ～ものなら
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('19df5692-ae88-5c30-9c95-3adaad177f41', 0, 'Nếu có thể ~ thì ~ (cách nói hi vọng vào điều khó thực hiện hoặc ít khả năng xảy ra).', ARRAY['父の病気が治るものなら、どんな高価な薬でも手に入れたい。','退院できるものなら、すぐにでもうちへ帰りたい。']::text[], ARRAY['Nếu bệnh tình của bố chữa được thì thuốc có đắt đến mấy tôi cũng mua.','Nếu có thể ra viện được thì tôi muốn về nhà ngay.']::text[]);

-- 153 ～ものの
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('7ae0fa26-ebf6-5e9b-88ec-56ea03e7f993', 0, 'Tuy đúng là ~ nhưng ~ (nhượng bộ trang trọng, gần nghĩa けれども nhưng nghiêng về văn viết).', ARRAY['免許はとったものの、車が買えない。','給料は少ないものの、仕事はやりがいがあります。']::text[], ARRAY['Dù là có bằng lái nhưng mà không mua được ô tô.','Lương hơi ít nhưng công việc rất đáng làm.']::text[]);

-- 154 ～わりに（は）
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('c6d1a9c9-3f20-5767-bc69-842e946469ad', 0, 'So với mức thông thường/kỳ vọng thì kết quả lại không tương xứng.', ARRAY['私はたくさん食べるわりに太らない。','この品物は高いわりには品質がよくない。']::text[], ARRAY['Mặc dù tôi ăn rất nhiều, nhưng mà không bị tăng cân.','Mặt hàng này dù là đắt nhưng chất lượng không tốt.']::text[]);

-- 155 ～（よ）うではないか／～（よ）うじゃないか
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('ed8b25e1-7f70-5d18-8bac-fb8f53a62cec', 0, 'Lời kêu gọi, hô hào mạnh mẽ "hãy cùng...!" thường dùng trước đám đông, diễn thuyết.', ARRAY['災害を受けた人々に救援物資を送ろうではないか。','男女差別の問題について真剣に考えようではありませんか。']::text[], ARRAY['Chúng ta hãy gửi đồ cứu viện đến cho những người bị thảm hoạ.','Hãy suy nghĩ nghiêm túc về vấn đề phân biệt giới tính.']::text[]);

-- 156 ～得る／～得ない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('fde8ad60-9e2a-5f78-9cb4-6f0a5d9b5562', 0, 'Có thể/không thể xảy ra, nói về tính khả thi hoặc xác suất của một sự việc.', ARRAY['考え得る限りの手は尽くしたが、問題の解決には至らなかった。','こんな低い山で遭難することはあり得ないと思う。']::text[], ARRAY['Đã hết sức trong giới hạn có thể suy nghĩ nhưng vẫn chưa đến được cách giải quyết vấn đề.','Tôi nghĩ là không có khả năng bị nạn trên núi thấp thế này.']::text[]);

-- 157 ～かねない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('42329718-c8ed-5087-b2b0-66905703ebed', 0, 'Có khả năng dẫn đến kết quả xấu, đáng lo ngại (chỉ dùng cho điều KHÔNG mong muốn).', ARRAY['あんなにスピードを出したら、事故を起こしかねない。','あの人ならそんな無責任なことも言いかねない。']::text[], ARRAY['Tăng tốc đến mức này, tai nạn chứ chẳng chơi.','Ông ấy thì có thể nói những lời vô trách nhiệm thế này.']::text[]);

-- 158 ～かねる
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('f61c519b-c740-52ae-90c7-e3b5b7113cce', 0, 'Muốn làm nhưng khó/không thể thực hiện được, cách nói lịch sự để từ chối.', ARRAY['そんな多額な寄付には応じかねます。','私の仕事がなかなか終わらなかったので、見かねて山田さんが手伝ってくれた。']::text[], ARRAY['Đóng góp nhiều tiền thế này thì chúng tôi khó lòng nhận lời được.','Vì công việc của tôi vẫn chưa xong nên không đứng nhìn được, bác Yamada đã giúp.']::text[]);

-- 159 ～ことか
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('716ff311-2b10-54f4-85c8-59b26f813ca0', 0, 'Câu cảm thán "biết bao nhiêu...!", thường đi cùng なんと/どんなに ở đầu câu.', ARRAY['息子から半年も連絡がない。一体何をしていることか。','コンピューターは、なんと便利なことか。']::text[], ARRAY['Con trai nửa năm rồi chả thấy liên lạc gì, không hiểu là đang làm cái gì đây.','Máy tính thật là thứ thật tiện lợi.']::text[]);

-- 160 ～ことだ
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('f32cca1e-be43-50a2-8941-09c45ba8d50b', 0, 'Lời khuyên nhẹ nhàng rằng nên/không nên làm gì đó vì điều đó quan trọng.', ARRAY['大学に入りたければ、一生懸命勉強することだ。','人の悪口は言わないことです。']::text[], ARRAY['Nếu muốn vào đại học thì nên chăm chỉ học hành.','Không nên nói xấu người khác.']::text[]);

-- 161 ～ざるを得ない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('9367e74f-8b52-5a7b-bc6f-b240f2910605', 0, 'Dù không muốn nhưng bị hoàn cảnh bắt buộc phải làm, không thể không làm.', ARRAY['みんなで決めた規則だから、守らざるを得ない。','彼は登山中に消息不明となり、すでに5年経っている。死んだと考えざるを得ないだろう。']::text[], ARRAY['Vì là nguyên tắc mọi người định ra nên không thể không tuân thủ.','Đã năm năm rồi kể từ khi anh ấy bị mất tích trong khi leo núi. Có lẽ không thể không nghĩ là anh ấy đã mất.']::text[]);

-- 162 ～次第だ／～次第で（は）
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('394efb4b-62aa-5d4f-8363-61c0e8bbca98', 0, 'Trình bày lý do/quá trình dẫn đến kết quả một cách khiêm tốn, trang trọng (gần nghĩa ～わけだ).', ARRAY['このたび日本政府の招きにより、親善大使として日本に来た次第です。','以上のような次第で、退職することになりました。']::text[], ARRAY['Lần này nhận lời mời của chính phủ Nhật Bản nên tôi đã đến Nhật với tư cách Đại sứ thiện chí.','Với những lý do nêu trên, tôi đã có quyết định nghỉ việc.']::text[]);
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('394efb4b-62aa-5d4f-8363-61c0e8bbca98', 1, 'Kết quả sẽ được quyết định tùy thuộc vào N (danh từ đứng trước).', ARRAY['この世の中はお金次第だと言う人もいる。','考え方次第で幸せにも不幸せにもなる。']::text[], ARRAY['Cũng có những người nói rằng cuộc đời này tất là do đồng tiền quyết định.','Dựa vào cách suy nghĩ mà cũng có thể trở thành hạnh phúc hay bất hạnh.']::text[]);

-- 163 ～っこない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('63f04138-ef13-52b5-88bb-0fe3a93f67ee', 0, 'Khẳng định mạnh "nhất định/tuyệt đối không...", chỉ dùng trong văn nói suồng sã.', ARRAY['宝くじなんて当たりっこないよ。','どんなに急いだって、今からじゃ間に合いっこない。']::text[], ARRAY['Tôi thì những thứ như xổ số là nhất định sẽ không bao giờ trúng.','Dù có khẩn trương thế nào thì giờ này nhất định cũng không thể kịp được.']::text[]);

-- 164 ～というものだ
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('4a725390-a19e-5c96-95d1-d52c1423e201', 0, 'Thể hiện cách nghĩ, cảm nhận chủ quan của người nói rằng đó là điều đương nhiên, hợp lý.', ARRAY['彼の作品がやっと世間から評価された。長年の苦労が認められたというものだ。','若者が高価な車を買うのはぜいたくというものだ。']::text[], ARRAY['Tác phẩm của anh ấy cuối cùng cũng được dư luận đánh giá cao. Đó chính là sự công nhận công sức lao động trong thời gian dài.','Người trẻ tuổi mà mua ô tô đắt tiền thì thật đúng là xa xỉ.']::text[]);

-- 165 ～というものではない／～というものでもない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('4308595c-2e98-51c3-99c5-1632f9bf593e', 0, 'Phản bác một quan niệm/cách nghĩ tưởng chừng đúng nhưng thực ra không hoàn toàn đúng.', ARRAY['性格は絶対に変えられないというものではない。','お金さえあれば幸せに暮らせるというものではない。']::text[], ARRAY['Không thể nói rằng là tính cách tuyệt đối sẽ không thay đổi.','Không thể nói rằng là chỉ cần có tiền là có thể sống hạnh phúc.']::text[]);

-- 166 ～ないことはない／～ないこともない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('4eba2dd2-1e66-5322-96d9-e909de572b72', 0, 'Phủ định 2 lần để tạo khẳng định nhẹ: "cũng không phải là không thể", có nhưng hạn chế.', ARRAY['難しいが、やり方次第ではできないことはないだろう。','このセーター、ちょっと派手じゃありませんか。派手じゃないこともないけど、よく似合っているからいいんじゃないですか。']::text[], ARRAY['Dù khó nhưng mà tùy theo cách làm cũng không phải là không thể làm được.','Cái áo len này chẳng phải là hơi sặc sỡ hay sao? Cũng sặc sỡ, nhưng vì trông rất hợp nên chẳng được hay sao?']::text[]);

-- 167 ～ないではいられない／～ずにはいられない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('b1ed521e-682a-50cb-a334-ed3b6873113c', 0, 'Không thể kìm nén được, tự nhiên phải làm dù không cố ý (thường là phản ứng cảm xúc).', ARRAY['彼のもの真似を見るとおかしくて、笑わないではいられない。','あの映画のラストシーンは感動的で、涙を流さずにはいられなかった。']::text[], ARRAY['Nhìn cách anh ấy bắt chước các sự vật buồn cười quá nên tôi không thể nhịn được.','Cảnh cuối cùng của bộ phim đó quá cảm động nên tôi không kìm được nước mắt.']::text[]);

-- 168 ～に限る／～に限り／～に限って
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('d9906b06-5055-58cf-a738-476167d8ae1e', 0, 'Chỉ giới hạn trong phạm vi N (nghĩa gần với だけ).', ARRAY['参加者は女性に限る。','本日に限って、全商品2割引にさせていただきます。']::text[], ARRAY['Người tham gia chỉ giới hạn ở nữ.','Chỉ hôm nay, chúng tôi giảm giá 20 phần trăm cho tất cả các mặt hàng.']::text[]);
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('d9906b06-5055-58cf-a738-476167d8ae1e', 1, 'Riêng N thì lại đặc biệt như vậy (thường mang sắc thái trớ trêu, bất ngờ).', ARRAY['あの人に限って、人をだますようなことはしない。','傘を持っていない日に限って、雨が降る。']::text[], ARRAY['Chỉ riêng với người đó, không bao giờ làm cái việc như là lừa người khác.','Vào đúng ngày tôi không mang ô thì lại mưa.']::text[]);
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('d9906b06-5055-58cf-a738-476167d8ae1e', 2, 'N/V là lựa chọn tốt nhất, nên chọn N/V đó (lời khuyên).', ARRAY['風を引いた時は、部屋を暖かくして寝るに限る。','夏はビールに限る。']::text[], ARRAY['Khi bị cảm, nên giữ ấm phòng và ngủ là tốt nhất.','Mùa hè Bia là số 1.']::text[]);

-- 169 ～に限らず
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('8f934117-524a-5223-8776-8bf055ff9e77', 0, 'Không chỉ riêng N mà còn ~ nữa (mở rộng phạm vi, ngược nghĩa với に限る).', ARRAY['ディズニーランドは子供に限らず、大人にも人気がある。','この講義は学生に限らず、社会人も聴講できる。']::text[], ARRAY['Disneyland thì không những được trẻ con ưa thích mà cả người lớn nữa.','Buổi giảng này không chỉ sinh viên mà người đã đi làm cũng có thể tham gia nghe giảng.']::text[]);

-- 170 ～にほかならない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('e68ad52b-82b1-5896-98a7-b5549d7262c9', 0, 'Khẳng định dứt khoát "chính là..., không gì khác ngoài...".', ARRAY['この手紙は私の正直な気持ちを申し上げたにほかなりません。','親が子供を叱るのは子供を愛しているからにほかならない。']::text[], ARRAY['Bức thư này không gì khác chính là nói lên tình cảm chân thành của tôi.','Việc cha mẹ mắng con không gì khác chính là yêu thương con.']::text[]);

-- 171 ～もの
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('724bfcee-88a8-5b54-8a31-2cb977b7e868', 0, 'Giải thích lý do một cách phân trần, thân mật (đặt cuối câu, hay dùng bởi phụ nữ và trẻ em).', ARRAY['一人で行ける。うん、大丈夫、地図を持っているもの。','多少のいたずらはしかたがありませんよ。子供ですもの。']::text[], ARRAY['Cậu có thể đi một mình chứ? Ừ, không sao đâu vì tớ có bản đồ mà.','Chúng có nghịch ngợm một chút thì cũng không có cách nào đâu. Vì là trẻ con mà.']::text[]);

-- 172 ～ものがある
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('cd5a0c03-c1bc-5e27-b314-fcdf65116b92', 0, 'Có cảm giác/ấn tượng như vậy, diễn tả nhận định trực giác, khó nói rõ ràng.', ARRAY['この絵には人を引きつけるものがある。','仕事がなくて暇すぎるのもつらいものがある。']::text[], ARRAY['Tôi có cảm giác bức tranh này rất lôi cuốn người xem.','Tôi có cảm giác việc thất nghiệp và quá nhàn rỗi có gì đó cũng thật cay đắng.']::text[]);

-- 173 ～ようがない／～ようもない
insert into grammar_meanings (grammar_point_id, order_index, meaning_vi, examples_jp, examples_vi) values ('169c4ebe-35cd-5993-8974-ee4294c7c02c', 0, 'Không có cách nào/phương pháp nào để làm, dù muốn cũng không thể thực hiện.', ARRAY['木村さんは今どこにいるのかわからないので、連絡しようがない。','この病気にかかると、今の医学ではどうしようもないらしい。']::text[], ARRAY['Tôi không biết anh Kimura giờ ở đâu nên không thể liên lạc được.','Nếu mắc bệnh này thì với y học hiện nay không có phương pháp cứu chữa.']::text[]);

-- ============ grammar_points enrichment (memory_tip / comparison_note / common_mistake) ============

update grammar_points set memory_tip = 'つつ nối vào thân ます của động từ, vừa mang nghĩa "đang làm A vừa làm B" vừa mang nghĩa "dù biết A nhưng vẫn B" — phải dựa vào ngữ cảnh để phân biệt.', comparison_note = 'Khác ながら (N4, chỉ 2 hành động đồng thời) — つつ mang sắc thái văn viết/trang trọng hơn, và có thêm nghĩa nhượng bộ "dù biết... nhưng vẫn..." mà ながら không có.', common_mistake = 'Dùng つつも trong văn nói thân mật hàng ngày — sách lưu ý つつも hầu như chỉ dùng ở nghĩa nhượng bộ và ít xuất hiện trong hội thoại.' where id = '53192181-3270-5531-b814-3838cb2dfd6e';

update grammar_points set memory_tip = 'Ghép động từ thể て + からでないと, luôn nhớ vế sau phải là câu phủ định hoặc mang ý không thể.', comparison_note = 'Khác てから (chỉ đơn thuần nêu thứ tự "làm xong A rồi làm B") — てからでないと nhấn mạnh A là điều kiện bắt buộc để B thực hiện được.', common_mistake = 'Dùng vế sau ở dạng khẳng định (sai) — phải luôn kết thúc câu bằng ý phủ định/không thể như できない、わからない.' where id = '249f3fb1-3af6-57e1-ae20-22f987f1327a';

update grammar_points set memory_tip = 'Đọc といっても như "nói là... nhưng", thực tế luôn kém/khác hơn những gì câu trước gợi ý.', comparison_note = 'Khác けれど/が (chỉ đơn thuần nối 2 vế tương phản) — といっても nhấn mạnh việc đính chính lại một ấn tượng/kỳ vọng vừa nêu ra.', common_mistake = 'Hiểu といっても là "mặc dù nói vậy" theo nghĩa nhượng bộ mạnh giống のに — thực ra nó nhẹ hơn, chỉ nhằm điều chỉnh mức độ.' where id = 'add26f26-19b1-56f2-894a-da66ff930d1e';

update grammar_points set memory_tip = 'Hình dung どころか như "nói gì đến... còn..." — vế sau luôn đi xa hơn, trái ngược hẳn với vế trước.', comparison_note = 'Khác ばかりでなく (chỉ đơn thuần thêm thông tin, không phủ định) — どころか mang tính bác bỏ mạnh, phủ nhận hoàn toàn điều vừa nêu.', common_mistake = 'Dùng どころか khi 2 vế chỉ đơn giản bổ sung cho nhau mà không có sự tương phản mạnh — trường hợp đó nên dùng のみならず/ばかりでなく.' where id = '297ff504-7e15-5d74-8ea9-f047632546c1';

update grammar_points set memory_tip = 'Nhớ mẫu là [thể thường]+としたら/とすれば, dùng để đặt giả thiết rồi suy luận kết quả.', comparison_note = 'Khác たら/ば (giả định thông thường) — としたら/とすれば thiên về suy luận logic từ một giả thiết, ít dùng cho điều kiện thời gian tự nhiên.', common_mistake = 'Dùng としたら cho sự việc chắc chắn xảy ra trong tương lai — mẫu này chỉ dùng cho giả thiết, không dùng cho kế hoạch có thật.' where id = '91769b0a-2bd5-5e1a-90f7-906262c0ae56';

update grammar_points set memory_tip = 'Nhớ quy tắc: vế sau luôn phủ định — "nếu không... thì không thể...".', comparison_note = 'Khác なければ (điều kiện phủ định thông thường, vế sau tự do) — ないことには bắt buộc vế sau phải mang nghĩa phủ định/bất khả.', common_mistake = 'Kết câu bằng vế sau khẳng định (sai ngữ pháp) — ví dụ không thể nói "～ないことには、できます".' where id = '56cca1e0-8a0f-55a3-9080-dad70be71c48';

update grammar_points set memory_tip = 'Đây là ながら nghĩa "nhưng, tuy" (khác nghĩa "vừa...vừa..." đã học ở N4) — ghi nhớ theo ví dụ 残念ながら (tiếc là...).', comparison_note = 'Khác ながら N4 (2 hành động cùng lúc, chủ ngữ chủ động làm cả hai) — ながら N2 mang nghĩa nhượng bộ "mặc dù... vẫn...", thường đi với tính từ/động từ trạng thái.', common_mistake = 'Nhầm lẫn 2 nghĩa của ながら — cần dựa vào ngữ cảnh: nếu 2 vế là hành động đồng thời thì là N4, nếu có sắc thái trái ngược thì là N2.' where id = '602d8323-dc2f-5905-8e85-ec6794de64c7';

update grammar_points set memory_tip = 'Hiểu にしては là "so với cái mác/tiêu chuẩn đó thì lại..." — luôn mang sắc thái bất ngờ, không như kỳ vọng.', comparison_note = 'Khác にしても (nhượng bộ "dù có... đi nữa") — にしては so sánh thực tế với tiêu chuẩn thông thường, không mang nghĩa nhượng bộ.', common_mistake = 'Dùng にしては để khen ngợi phù hợp kỳ vọng — mẫu này chỉ dùng khi có sự chênh lệch so với kỳ vọng (thường là thất vọng nhẹ).' where id = '7910fc87-19a7-5ad3-8c4e-29ac3139dfef';

update grammar_points set memory_tip = 'Ghi nhớ khung "AにしろBにしろ" = "dù là A hay B thì cũng...", dùng liệt kê 2 trường hợp đối lập.', comparison_note = 'Khác としても (chỉ 1 giả thiết đơn) — にしろ／にせよ thường đi theo cặp để liệt kê nhiều khả năng cùng dẫn đến 1 kết luận.', common_mistake = 'Chỉ dùng 1 vế にしろ mà quên vế thứ hai — cấu trúc điển hình cần lặp lại にしろ ở cả 2 vế để tạo hiệu ứng liệt kê.' where id = '10524dd0-6c9e-57bc-b02e-9bd1221dd8fc';

update grammar_points set memory_tip = 'Nhớ にかかわらず hay đi sau cặp đối lập (するしないにかかわらず, 晴雨にかかわらず) nghĩa là "bất kể có...hay không".', comparison_note = 'Khác にもかかわらず (nghĩa "mặc dù, dẫu vậy", mang ý ngạc nhiên) — にかかわらず chỉ đơn thuần nói "không liên quan, không phân biệt".', common_mistake = 'Nhầm にかかわらず với にもかかわらず vì hình thức gần giống nhau — にかかわらず không có "も" và không mang nghĩa nhượng bộ bất ngờ.' where id = 'a6a1abd1-0797-5c70-a166-5499f2e74125';

update grammar_points set memory_tip = 'Thêm chữ "も" để phân biệt với にかかわらず: にもかかわらず = "vậy mà, mặc dù" mang sắc thái ngạc nhiên/đáng tiếc.', comparison_note = 'Khác のに (cũng nghĩa "mặc dù" nhưng thân mật, dùng cả trong hội thoại) — にもかかわらず trang trọng hơn, thường dùng trong văn viết.', common_mistake = 'Nhầm lẫn với にかかわらず (nghĩa "không liên quan tới, bất kể") — hai mẫu khác nghĩa dù hình thức gần giống.' where id = 'b3c70803-1972-54b5-a4ac-e2efdf07c248';

update grammar_points set memory_tip = 'Hình dung ぬき = "rút bỏ ra" — Nぬきで nghĩa là làm việc gì đó mà thiếu/bỏ qua N đó.', comparison_note = 'Khác なしで (cũng nghĩa "không có N" nhưng trung tính hơn) — ぬきで thường ngụ ý N đó đáng lẽ phải có nhưng bị lược bỏ có chủ đích.', common_mistake = 'Dùng ぬきで cho động từ (sai) — ぬき chỉ ghép được sau danh từ, không ghép sau động từ.' where id = 'e0021672-ea01-51b0-b3f9-ef1d53c1810e';

update grammar_points set memory_tip = 'のみならず = だけでなく nhưng trang trọng, văn viết hơn — hay đi cặp với も ở vế sau (Aのみならず、Bも).', comparison_note = 'Khác ばかりでなく (cùng nghĩa nhưng dùng được cả văn nói) — のみならず chỉ xuất hiện trong văn viết/phát biểu trang trọng.', common_mistake = 'Dùng のみならず trong hội thoại thân mật hàng ngày — nghe rất cứng nhắc, nên dùng だけでなく/ばかりでなく thay thế.' where id = '4ad455d8-684b-543a-9394-71099d4ede9b';

update grammar_points set memory_tip = 'Hình dung 反面 như "mặt trái của đồng xu" — một sự vật có 2 mặt trái ngược nhau cùng tồn tại.', comparison_note = 'Khác 一方で (cũng nêu 2 mặt song song nhưng không nhất thiết trái ngược nhau) — 反面 bắt buộc 2 vế phải đối lập về tính chất tốt/xấu.', common_mistake = 'Dùng 反面 khi 2 vế không hề đối lập (chỉ là 2 sự việc song song) — trường hợp đó nên dùng 一方で.' where id = 'fb6b51c3-110a-5db8-9768-0d1ccbc52113';

update grammar_points set memory_tip = 'ものなら luôn đi với động từ ở dạng khả năng (できる, 見られる...) để nói "nếu có thể... thì..." với ý hi vọng khó thành hiện thực.', comparison_note = 'Khác なら (giả định trung tính) — ものなら mang thêm sắc thái "điều khó xảy ra, chỉ là ước ao".', common_mistake = 'Dùng ものなら với động từ không ở thể khả năng — mẫu này gần như luôn cần V thể có thể (可能形) đứng trước.' where id = '19df5692-ae88-5c30-9c95-3adaad177f41';

update grammar_points set memory_tip = 'ものの = けれども nhưng trang trọng hơn, thường dùng khi vế đầu là một sự thật đã đạt được nhưng vế sau lại chưa như ý.', comparison_note = 'Khác けれど/が (thân mật, dùng cả nói lẫn viết) — ものの nghiêng về văn viết, báo chí, văn bản trang trọng.', common_mistake = 'Dùng ものの trong hội thoại suồng sã hàng ngày — nghe lạc phong cách, nên dùng けど/が cho tự nhiên hơn.' where id = '7ae0fa26-ebf6-5e9b-88ec-56ea03e7f993';

update grammar_points set memory_tip = 'わりに = "so với mức thông thường thì lại..." — luôn có phần bất ngờ, không tương xứng với vế trước.', comparison_note = 'Khác にしては (cũng so sánh với kỳ vọng nhưng thiên về đánh giá 1 sự việc/thân phận cụ thể) — わりに thường so sánh 2 đại lượng có thể đo đếm được (ăn nhiều/ít, giá cao/thấp).', common_mistake = 'Dùng わりに khi 2 vế không có quan hệ tỉ lệ nào để so sánh — mẫu này cần có sự chênh lệch rõ giữa mức độ kỳ vọng và thực tế.' where id = 'c6d1a9c9-3f20-5767-bc69-842e946469ad';

update grammar_points set memory_tip = 'Ghép động từ thể ý hướng (意向形) + ではないか để tạo lời kêu gọi mạnh mẽ, hùng hồn — hay dùng trong diễn thuyết.', comparison_note = 'Khác ましょう (rủ rê nhẹ nhàng, dùng hàng ngày) — （よ）うではないか mang tính hô hào, trang trọng, thường dùng trước đám đông.', common_mistake = 'Dùng （よ）うではないか với bạn bè thân trong giao tiếp hàng ngày — nghe quá đao to búa lớn, nên dùng ましょう/ようよ cho tự nhiên.' where id = 'ed8b25e1-7f70-5d18-8bac-fb8f53a62cec';

update grammar_points set memory_tip = 'Ghép động từ thể ます (bỏ ます) + 得る/得ない để nói về khả năng xảy ra hay không, chú ý đọc là "える/えない" hoặc "うる/えない" tùy từ.', comparison_note = 'Khác できる (năng lực làm được việc gì) — 得る thiên về khả năng/xác suất một sự việc có thể xảy ra, không phải năng lực cá nhân.', common_mistake = 'Đọc nhầm 得る thành "とくる" — từ này đọc là "える" (hoặc "うる" trong văn viết trang trọng).' where id = 'fde8ad60-9e2a-5f78-9cb4-6f0a5d9b5562';

update grammar_points set memory_tip = 'かねない luôn đi với việc xấu, nguy hiểm có thể xảy ra — nhớ theo mẫu câu 事故を起こしかねない (có thể gây tai nạn).', comparison_note = 'Khác かもしれない (khả năng trung tính, tốt xấu đều dùng được) — かねない chỉ dùng cho khả năng xảy ra điều không mong muốn.', common_mistake = 'Dùng かねない cho việc tốt đẹp (sai sắc thái) — ví dụ không nói "合格しかねない" vì đỗ đạt là điều tốt.' where id = '42329718-c8ed-5087-b2b0-66905703ebed';

update grammar_points set memory_tip = 'かねる là cách nói lịch sự để từ chối, thường dùng trong công việc, dịch vụ khách hàng (お答えしかねます).', comparison_note = 'Khác られない/できない (từ chối trực tiếp, thẳng thắn) — かねる là cách nói giảm nhẹ, lịch sự, thường dùng nơi công sở.', common_mistake = 'Dùng かねる trong văn nói thân mật với bạn bè — mẫu này chỉ hợp trong ngữ cảnh trang trọng, lịch sự.' where id = 'f61c519b-c740-52ae-90c7-e3b5b7113cce';

update grammar_points set memory_tip = 'ことか luôn đi sau なんと/どんなに để tạo câu cảm thán "biết bao nhiêu...!".', comparison_note = 'Khác でしょう (chỉ phỏng đoán) — ことか mang cảm xúc cảm thán mạnh, thường đi kèm どんなに/なんと.', common_mistake = 'Quên thêm どんなに/なんと ở đầu câu — thiếu từ nhấn mạnh này câu sẽ mất đi sắc thái cảm thán đặc trưng.' where id = '716ff311-2b10-54f4-85c8-59b26f813ca0';

update grammar_points set memory_tip = 'ことだ đứng sau động từ nguyên thể/ない để đưa ra lời khuyên nhẹ nhàng, kiểu "nên làm...".', comparison_note = 'Khác べきだ (khuyên mạnh mẽ, mang tính đạo đức/nghĩa vụ) — ことだ nhẹ nhàng hơn, thường dùng khi khuyên bảo cá nhân, gần gũi.', common_mistake = 'Dùng ことだ để ra lệnh cấp trên hay người lớn tuổi — nghe hơi trịch thượng, nên chọn cách nói khiêm nhường hơn với người trên.' where id = 'f32cca1e-be43-50a2-8941-09c45ba8d50b';

update grammar_points set memory_tip = 'Ghép động từ thể ない (bỏ ない) + ざるを得ない — riêng する biến thành せざるを得ない (ngoại lệ cần nhớ riêng).', comparison_note = 'Khác なければならない (nghĩa vụ chung chung) — ざるを得ない nhấn mạnh việc bị hoàn cảnh bắt buộc làm dù không muốn.', common_mistake = 'Chia する thành しざるを得ない (sai) — động từ する luôn biến thành せざるを得ない.' where id = '9367e74f-8b52-5a7b-bc6f-b240f2910605';

update grammar_points set memory_tip = 'Hai nghĩa khác hẳn nhau: [thể thường]+次第だ = trình bày lý do một cách khiêm tốn; [danh từ]+次第で(は) = "tùy vào...mà".', comparison_note = 'Khác 次第 đứng một mình sau động từ thể ます (nghĩa "ngay khi vừa...") — đây là mẫu 次第だ/次第で khác nghĩa hoàn toàn dù cùng chữ 次第.', common_mistake = 'Nhầm 次第だ (giải thích lý do, khiêm tốn) với 次第で (tùy thuộc vào) — cần phân biệt qua cấu trúc đi kèm (mệnh đề hay danh từ).' where id = '394efb4b-62aa-5d4f-8363-61c0e8bbca98';

update grammar_points set memory_tip = 'っこない gắn sau thân ます của động từ, chỉ dùng trong văn nói suồng sã để khẳng định "chắc chắn không bao giờ".', comparison_note = 'Khác わけがない (cũng phủ định mạnh nhưng dùng được cả văn viết) — っこない chỉ dùng trong hội thoại thân mật.', common_mistake = 'Dùng っこない trong văn viết trang trọng/báo cáo — mẫu này chỉ hợp với văn nói đời thường.' where id = '63f04138-ef13-52b5-88bb-0fe3a93f67ee';

update grammar_points set memory_tip = 'というものだ dùng khi người nói khẳng định "đó đúng là..." theo cảm nhận/đánh giá cá nhân về một lẽ đương nhiên.', comparison_note = 'Khác ものだ (nói về bản chất/thói quen chung chung) — というものだ thiên về nhận định, đánh giá của người nói về một sự việc cụ thể vừa nêu.', common_mistake = 'Dùng というものだ để nêu sự thật khách quan không mang tính đánh giá — mẫu này luôn gắn với cảm nhận chủ quan của người nói.' where id = '4a725390-a19e-5c96-95d1-d52c1423e201';

update grammar_points set memory_tip = 'というものではない = phủ định một quan niệm/nhận định tưởng chừng đúng nhưng thực ra không hoàn toàn đúng.', comparison_note = 'Khác わけではない (phủ định một phần, mang tính cá nhân) — というものではない phủ định một quan niệm chung được nhiều người tin.', common_mistake = 'Dùng mẫu này để phủ định sự thật hiển nhiên — mẫu này chỉ dùng để phản bác một cách nghĩ/quan niệm, không phải sự kiện khách quan.' where id = '4308595c-2e98-51c3-99c5-1632f9bf593e';

update grammar_points set memory_tip = 'Phủ định 2 lần = khẳng định nhẹ: ないことはない nghĩa là "cũng không phải là không thể", ý nói có nhưng ở mức hạn chế.', comparison_note = 'Khác できる (khẳng định trực tiếp, dứt khoát) — ないことはない mang sắc thái dè dặt, có điều kiện đi kèm.', common_mistake = 'Hiểu nhầm ないことはない là phủ định hoàn toàn — vì có 2 lần phủ định nên thực chất câu mang nghĩa khẳng định (nhẹ).' where id = '4eba2dd2-1e66-5322-96d9-e909de572b72';

update grammar_points set memory_tip = 'Nhớ theo cảm xúc "không kìm được" — 笑わないではいられない (không nhịn được cười), 泣かずにはいられない (không kìm được nước mắt).', comparison_note = 'Khác たくてたまらない (diễn tả mong muốn mãnh liệt) — ないではいられない diễn tả một phản ứng/hành động không kiểm soát được do cảm xúc.', common_mistake = 'Dùng chủ ngữ ngôi thứ 3 mà không thêm ようだ/らしい ở cuối câu — mẫu này vốn chỉ dùng cho cảm xúc của chính người nói (ngôi thứ nhất).' where id = 'b1ed521e-682a-50cb-a334-ed3b6873113c';

update grammar_points set memory_tip = '3 nghĩa khác nhau của cùng 1 mẫu: に限る (giới hạn phạm vi), に限って (đúng lúc đó lại...), に限る (lời khuyên "tốt nhất là").', comparison_note = 'Khác だけ (chỉ đơn thuần giới hạn số lượng/phạm vi) — に限って còn mang thêm sắc thái "trớ trêu thay, đúng lúc đó lại...".', common_mistake = 'Nhầm nghĩa に限って (mang tính trớ trêu) với nghĩa giới hạn phạm vi thông thường — cần dựa vào ngữ cảnh để phân biệt.' where id = 'd9906b06-5055-58cf-a738-476167d8ae1e';

update grammar_points set memory_tip = 'に限らず = "không chỉ riêng N mà còn..." — luôn đi kèm も ở vế sau để mở rộng phạm vi.', comparison_note = 'Khác のみならず (trang trọng hơn, dùng nhiều trong văn viết) — に限らず tự nhiên hơn, dùng được cả trong văn nói.', common_mistake = 'Nhầm に限らず với に限る (nghĩa hoàn toàn trái ngược: に限る = giới hạn ở, に限らず = không giới hạn ở) — cần chú ý chữ ず phủ định.' where id = '8f934117-524a-5223-8776-8bf055ff9e77';

update grammar_points set memory_tip = 'にほかならない = "chính là..., không gì khác ngoài..." — dùng để khẳng định dứt khoát bản chất của sự việc.', comparison_note = 'Khác なのだ (giải thích/khẳng định thông thường) — にほかならない mang giọng văn trang trọng, nhấn mạnh không có khả năng nào khác.', common_mistake = 'Dùng にほかならない trong câu nghi vấn hoặc phủ định — mẫu này chỉ dùng ở câu khẳng định để nhấn mạnh.' where id = 'e68ad52b-82b1-5896-98a7-b5549d7262c9';

update grammar_points set memory_tip = 'もの (hay もん trong khẩu ngữ) đặt cuối câu để giải thích lý do một cách nũng nịu, hay dùng bởi phụ nữ và trẻ em.', comparison_note = 'Khác から/ので (giải thích lý do trung tính) — もの mang sắc thái phân trần, hờn dỗi, thân mật hơn nhiều.', common_mistake = 'Dùng もの trong văn viết trang trọng hoặc khi nói với cấp trên — mẫu này chỉ hợp trong hội thoại thân mật, suồng sã.' where id = '724bfcee-88a8-5b54-8a31-2cb977b7e868';

update grammar_points set memory_tip = 'ものがある đặt sau tính từ/động từ thể hiện cảm nhận trực giác của người nói về một điều gì đó khó diễn tả trọn vẹn.', comparison_note = 'Khác と思う (nêu ý kiến rõ ràng, chủ động) — ものがある mang sắc thái cảm nhận mơ hồ, như tự nhiên cảm thấy vậy.', common_mistake = 'Dùng ものがある để phát biểu ý kiến logic, rõ ràng — mẫu này chỉ hợp khi diễn tả cảm giác, ấn tượng chủ quan.' where id = 'cd5a0c03-c1bc-5e27-b314-fcdf65116b92';

update grammar_points set memory_tip = 'Ghép động từ thể ます (bỏ ます) + ようがない để nói "không có cách nào để làm...".', comparison_note = 'Khác できない (không có khả năng làm) — ようがない nhấn mạnh việc không có phương tiện/cách thức để thực hiện, dù có muốn làm cũng bó tay.', common_mistake = 'Dùng ようがない khi chỉ đơn thuần thiếu năng lực cá nhân — mẫu này thiên về việc không tồn tại phương pháp nào khả thi, không phải về năng lực.' where id = '169c4ebe-35cd-5993-8974-ee4294c7c02c';
