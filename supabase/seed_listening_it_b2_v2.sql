-- Nghe hiểu "Tiếng Nhật IT" (ITの日本語 B2 会話編) — chỉnh chất lượng + bổ sung câu hỏi.
-- Chạy SAU seed_listening_it_b2.sql. Chạy lại nhiều lần an toàn (UPDATE có điều kiện, INSERT ... ON CONFLICT).
-- Lưu ý: seed_listening_it_b2.sql có `delete` toàn bộ hội thoại IT — nếu chạy lại file đó thì phải chạy tiếp file này.
--
-- A) Viết lại đáp án SAI của 28 câu cũ: trước đây đáp án đúng thường là lựa chọn dài nhất (36/45 câu) nên đoán được
--    mà không cần nghe. Câu hỏi và đáp án ĐÚNG giữ nguyên (đối chiếu sách); chỉ đổi 3 đáp án sai, độ dài/cấu trúc
--    gần đáp án đúng. Đáp án sai do Claude soạn (không có trong sách) — cần người biết tiếng Nhật rà.
-- B) Thêm 30 câu hỏi mới (2 câu/bài) trên CÙNG hội thoại của bài (nguyên văn モデル会話, dùng lại audio sẵn có).
--    Đáp án ĐÚNG lấy từ nội dung hội thoại/đối chiếu sách (script kiểm tra từng ý có trong hội thoại);
--    câu hỏi và 3 đáp án sai do Claude soạn thêm (AI), KHÔNG phải câu hỏi gốc của sách.
--    Không đổi schema (bảng chưa có cột nguồn) nên không gắn nhãn trong app; id xác định (uuid v5).

begin;

-- ===== A) Viết lại đáp án sai =====
update listening_dialogues set options = '["日本のお客様に新しい製品のデモを見せるためです。", "新しいシステムのテスト結果を確認するためです。", "ベトナムでプロジェクトのキックオフをするためです。", "要件定義の工程からオンサイトで作業するためです。"]'::jsonb
  where id = '0fd1db1c-fecc-5109-8496-746926e828c1'::uuid and options->>correct_index = 'ベトナムでプロジェクトのキックオフをするためです。';
update listening_dialogues set options = '["SESのIT部門で、IT関連のプロジェクトを管理している担当者です。", "日本のお客様向けのシステム開発プロジェクトを主に担当するPMです。", "日本企業向けのシステム開発部門全体を管理している責任者です。", "ゲーム開発プロジェクトのテストを主に担当しているエンジニアです。"]'::jsonb
  where id = '61177c59-f79b-574e-886b-0211e1277e96'::uuid and options->>correct_index = '日本のお客様向けのシステム開発プロジェクトを主に担当するPMです。';
update listening_dialogues set options = '["デジタル教科書のデスクトップアプリケーションを改良して、先生が採点しやすくすることです。", "既存のシステムを新しいシステムに入れ替えて、開発費用を大きく減らすことです。", "E-Learningのデスクトップアプリを開発して、海外の学校に販売することです。", "デジタル教科書のWebアプリケーションを開発し、生徒たちが楽しく学べるようにすることです。"]'::jsonb
  where id = '24b88d33-3803-5f2d-8852-6eb442e85174'::uuid and options->>correct_index = 'デジタル教科書のWebアプリケーションを開発し、生徒たちが楽しく学べるようにすることです。';
update listening_dialogues set options = '["プロジェクトの概要、体制、開発手法、スケジュール、コミュニケーションプラン、リスクと課題です。", "プロジェクトの目的、予算、契約の条件、納品日、サポート体制、リスクと課題です。", "概要、体制、要件定義、テスト計画、リリースノート、費用、リスクと課題です。", "プロジェクトの目的、開発手法、スケジュール、見積り、契約、品質保証の方針です。"]'::jsonb
  where id = '4e8a0898-4646-55e3-a5e9-5a04671a3031'::uuid and options->>correct_index = 'プロジェクトの概要、体制、開発手法、スケジュール、コミュニケーションプラン、リスクと課題です。';
update listening_dialogues set options = '["要件をもう一度すべて書き直して、お客様に確認します。", "3回のデモを実施して、修正すべき点を確認します。", "設計工程を増やして、詳しい設計書を作成します。", "毎週お客様の会社に行って、進捗を直接報告します。"]'::jsonb
  where id = '1e11d187-40f2-5228-8ad3-6bf613c3a61e'::uuid and options->>correct_index = '3回のデモを実施して、修正すべき点を確認します。';
update listening_dialogues set options = '["はい。ロジックに合わせて直したほうがよいものがあれば、教えてもらうことになっています。", "いいえ。UIはお客様が準備したものなので、開発チームは一切修正できません。", "いいえ。UIを修正できるのは、3回のデモがすべて終わったあとだけです。", "はい。ただし、修正の作業はお客様が自分で行うことになっています。"]'::jsonb
  where id = 'fbd7fb57-4006-5b06-a900-12d81a9e08e1'::uuid and options->>correct_index = 'はい。ロジックに合わせて直したほうがよいものがあれば、教えてもらうことになっています。';
update listening_dialogues set options = '["メンバーがアンさんに直接報告し、アンさんがホアンさんに報告し、ホアンさんが小巻様に報告します。", "メンバーがチームリーダーに報告し、チームリーダーがアンさんに報告し、アンさんが小巻様に報告します。", "チームリーダーが小巻様に直接報告し、小巻様がアンさんに内容を伝えて、アンさんがメンバーに指示します。", "メンバーがリーさんに報告し、リーさんがアンさんに報告し、アンさんが黒田様に報告します。"]'::jsonb
  where id = '1bb27c44-6361-5d14-a9b4-9fb3f81a0ab5'::uuid and options->>correct_index = 'メンバーがチームリーダーに報告し、チームリーダーがアンさんに報告し、アンさんが小巻様に報告します。';
update listening_dialogues set options = '["技術的な課題はアンさんかリーさんが確認し、難しい課題は黒田様とホアンさんにエスカレーションします。", "課題はすべて小巻様とリンさんが確認し、難しい課題は黒田様にだけエスカレーションします。", "技術的な課題はリンさんが確認し、営業の課題はアンさんとリーさんがエスカレーションします。", "課題はすべてチームリーダーがホアンさんに報告し、小巻様とリンさんが最終的に決定します。"]'::jsonb
  where id = 'c838ac8e-11a3-5f0c-bb66-43b5a02acb1e'::uuid and options->>correct_index = '技術的な課題はアンさんかリーさんが確認し、難しい課題は黒田様とホアンさんにエスカレーションします。';
update listening_dialogues set options = '["ものを入れるときは日付を書いて、一週間たったものは全部処分します。", "冷蔵庫に入れたものは、毎日夕方に全部持って帰るようにします。", "ものを入れるときは自分の名前を書いて、賞味期限切れのものは処分します。", "ものを入れるときは名前を書かないで、みんなで自由に使えるようにします。"]'::jsonb
  where id = 'ff23f89a-c94b-5711-9a61-d3c43b6f2393'::uuid and options->>correct_index = 'ものを入れるときは自分の名前を書いて、賞味期限切れのものは処分します。';
update listening_dialogues set options = '["デジタル教科書のWebアプリケーションを開発しました。", "デジタル教科書の学習データを保存するサイトを開発しました。", "iPad専用のデジタル教科書アプリケーションを開発しました。", "デジタル教科書のデスクトップアプリケーションを開発しました。"]'::jsonb
  where id = '30120612-74f0-56be-9285-67285429326c'::uuid and options->>correct_index = 'デジタル教科書のデスクトップアプリケーションを開発しました。';
update listening_dialogues set options = '["このアプリをベースに、WebGLを使用してアプリをWeb化し、一部機能の追加・修正を行います。", "昨年のアプリをベースに、iPad専用のアプリに変えて、全機能の追加・修正を行います。", "このアプリをベースに、WebGLを使わずに、画面のデザインだけを新しく作り直します。", "昨年のアプリを使わず、新しいWebアプリを一から作り、全画面を新規に開発します。"]'::jsonb
  where id = 'b02fd1da-3b12-5370-a2c6-ab5beb9c95ea'::uuid and options->>correct_index = 'このアプリをベースに、WebGLを使用してアプリをWeb化し、一部機能の追加・修正を行います。';
update listening_dialogues set options = '["3.3「学習データ保存」は完了しましたが、3.4「学習の結果」は50%です。", "3.3「学習データ保存」は0%、3.4「学習の結果」は50%で、課題が発生しています。", "3.3「学習データ保存」は50%、3.4「学習の結果」は0%で、実装で課題が発生しています。", "3.3「学習データ保存」も3.4「学習の結果」も50%で、画面の実装に課題が発生しています。"]'::jsonb
  where id = '2465c023-fb6c-53e6-92e3-1e838e57de31'::uuid and options->>correct_index = '3.3「学習データ保存」は50%、3.4「学習の結果」は0%で、実装で課題が発生しています。';
update listening_dialogues set options = '["進捗の詳細をまとめたWBSと進捗報告書を送付しました。", "結合テスト仕様書と画面の設計書の最新版を送付しました。", "開発環境の調査結果とリスク・課題の一覧を送付しました。", "Q&Aファイルと今週分の週報を一緒に送付しました。"]'::jsonb
  where id = '87bbf544-83b8-5402-8777-ffb38333d36b'::uuid and options->>correct_index = '進捗の詳細をまとめたWBSと進捗報告書を送付しました。';
update listening_dialogues set options = '["影響します。遅れを取り戻すために、来週予定している結合テストを中止するからです。", "影響します。indexedDBの実装がまだ終わっていなくて、来週も遅れが続く見込みだからです。", "影響しません。遅れているタスクは、次のリリースで対応することになったからです。", "影響しません。結合テスト仕様書の作成を前倒しして、遅れは来週中に取り戻す予定だからです。"]'::jsonb
  where id = '12347803-0793-5da7-a720-17de5c5afa80'::uuid and options->>correct_index = '影響しません。結合テスト仕様書の作成を前倒しして、遅れは来週中に取り戻す予定だからです。';
update listening_dialogues set options = '["すべての画面が、まったく表示されなくなってしまいました。", "画面の表示は正しいですが、保存したデータが古いままです。", "一部の画面が、デスクトップアプリと同じように動作しません。", "アプリが起動するまでに、とても長い時間がかかってしまいます。"]'::jsonb
  where id = '8ac18980-8009-5e6f-915e-f6facdb0a8aa'::uuid and options->>correct_index = '一部の画面が、デスクトップアプリと同じように動作しません。';
update listening_dialogues set options = '["デスクトップアプリの画面が、Webで表示されなくなってしまったことです。", "Webの開発では、静的データをRAMに保存する方法だとメモリ不足になることです。", "indexedDBが使えなくて、必要なデータをブラウザに保存できないことです。", "結合テスト仕様書の作成が、予定より2人日も遅れてしまっていることです。"]'::jsonb
  where id = '96bc0334-bd0d-56aa-8007-749b8b8f9f9d'::uuid and options->>correct_index = 'Webの開発では、静的データをRAMに保存する方法だとメモリ不足になることです。';
update listening_dialogues set options = '["複数のタブやウィンドウで開くと、お客様のデータが他の利用者に見えてしまう可能性があるからです。", "ブラウザのバージョンが古いと、アプリの画面が正しく表示されない可能性があるからです。", "iPad Airでは、一つのブラウザで複数のウィンドウを開く機能が使えないからです。", "複数のタブやウィンドウで開くと、RAMをたくさん使い、パフォーマンスに影響を与える可能性があるからです。"]'::jsonb
  where id = 'affd4f18-81e2-5a8d-a48b-79645d81030e'::uuid and options->>correct_index = '複数のタブやウィンドウで開くと、RAMをたくさん使い、パフォーマンスに影響を与える可能性があるからです。';
update listening_dialogues set options = '["新しいデザインのボタンを、お客様に選んでもらうために見せることです。", "学習結果確認機能の見積りを作成して、お客様に承認してもらうことです。", "デスクトップ版とWeb版の画面の違いを、お客様に詳しく説明することです。", "学習結果確認機能の詳細画面のデモをして、お客様に確認してもらうことです。"]'::jsonb
  where id = '8fab0256-c351-556c-9262-602166dded8a'::uuid and options->>correct_index = '学習結果確認機能の詳細画面のデモをして、お客様に確認してもらうことです。';
update listening_dialogues set options = '["表示領域は変えずに、デフォルトの画像サイズを小さくして、ボタンが画像に重ならないようにしてほしいと言っています。", "画像の表示領域を小さくしてでも、ボタンが画像に重ならないように対応してほしいと言っています。", "画像を大きくして、ボタンを画面の外に出し、画像だけがよく見えるようにしてほしいと言っています。", "ボタンを小さくして、画像に少し重なっても、画面全体の大きさは変えないでほしいと言っています。"]'::jsonb
  where id = 'e49c6adc-8b2a-56ac-87ff-8044d015c6df'::uuid and options->>correct_index = '表示領域は変えずに、デフォルトの画像サイズを小さくして、ボタンが画像に重ならないようにしてほしいと言っています。';
update listening_dialogues set options = '["はい。制限なしのバージョンを次回のリリースで納品することに、その場ですぐ合意しました。", "いいえ。制限を設けたバージョンを今回のリリースで納品することに、強く反対しました。", "いいえ、すぐには合意していません。受け入れテストの日程が近いので、担当者と相談すると言っています。", "はい。ただし、見積りの10人日よりも短い工数にしてほしいと条件を付けて合意しました。"]'::jsonb
  where id = '1765f917-93c1-5d9a-8478-12a8b7aac0ae'::uuid and options->>correct_index = 'いいえ、すぐには合意していません。受け入れテストの日程が近いので、担当者と相談すると言っています。';
update listening_dialogues set options = '["同じブラウザで複数ウィンドウを開くのに制限をかけない対応です。", "iPad版のお気に入りに登録できる画像を10枚に増やす対応です。", "テスト環境にChromeの最新バージョンを追加で用意する対応です。", "インストール手順書にアンインストールの手順を書き足す対応です。"]'::jsonb
  where id = '4185d624-dd24-5edb-9fb5-d0bea0358006'::uuid and options->>correct_index = '同じブラウザで複数ウィンドウを開くのに制限をかけない対応です。';
update listening_dialogues set options = '["ソースコードとテスト環境のサーバー、およびドキュメントのバックアップです。", "ソースコード、ソースコードからビルドしたアプリケーション、ドキュメントです。", "ビルドしたアプリケーションと学習データのバックアップ、操作説明の動画です。", "ソースコードとドキュメント、そしてテスト用のiPad端末一式です。"]'::jsonb
  where id = '16950d1d-f691-553e-a0fa-601cdbb81218'::uuid and options->>correct_index = 'ソースコード、ソースコードからビルドしたアプリケーション、ドキュメントです。';
update listening_dialogues set options = '["iPad版の学習データ保存機能で、お気に入り画面に画像が10枚以上あるとアプリが終了し、登録できる画像も最大2MBで3枚までです。", "デスクトップ版の学習データ保存機能で、お気に入り画面に画像が3枚以上あるとページが再読み込みされ、登録できる画像も最大10MBで2枚までです。", "iPad版の学習データ保存機能で、お気に入り画面に画像が3枚以上あるとページが再読み込みされ、登録できる画像も最大2MBで10枚までです。", "iPad版でもデスクトップ版でも、お気に入り画面に画像が3枚以上あると保存ができなくなり、登録できる画像も最大2MBで100枚までです。"]'::jsonb
  where id = '1b86c012-fa40-5ad9-ad6d-6d4e7e23acd9'::uuid and options->>correct_index = 'iPad版の学習データ保存機能で、お気に入り画面に画像が3枚以上あるとページが再読み込みされ、登録できる画像も最大2MBで10枚までです。';
update listening_dialogues set options = '["アプリの不具合によるものなので、次のリリースですぐに直すと説明しました。", "お客様の端末の設定が原因なので、設定を変更してほしいと説明しました。", "端末のハードウェアのスペックによるもので、RAMは2GBあれば十分だと説明しました。", "端末のハードウェアのスペックによるもので、RAMは4GB以上を推奨すると説明しました。"]'::jsonb
  where id = 'cce323ac-85a5-5fca-a7f3-663521b557f6'::uuid and options->>correct_index = '端末のハードウェアのスペックによるもので、RAMは4GB以上を推奨すると説明しました。';
update listening_dialogues set options = '["まず不具合管理システムに登録して、対応の優先順位をリーさんが決めます。", "すぐにオフショアチームに連絡して、原因の分析と修正をしてもらいます。", "まず原因を分析し、対応する担当を切り分け、再現手順も確認します。", "お客様に、どの不具合から先に直してほしいかを確認してから分析します。"]'::jsonb
  where id = '787ae3ed-b8d1-5597-97bb-c7e9b32169ca'::uuid and options->>correct_index = 'まず原因を分析し、対応する担当を切り分け、再現手順も確認します。';
update listening_dialogues set options = '["まずリーさんが原因を分析して、対応の優先順位を決めてからお客様に連絡します。", "不具合がすべて直ってから、まとめて不具合管理システムに登録して連絡します。", "まずオフショアチームが優先順位を決めて、その後にお客様へ連絡して登録します。", "まず不具合管理システムに登録します。その後、お客様側で対応の優先順位を決めて連絡します。"]'::jsonb
  where id = '7d511428-c899-5928-878f-5cd1dd4b3e7e'::uuid and options->>correct_index = 'まず不具合管理システムに登録します。その後、お客様側で対応の優先順位を決めて連絡します。';
update listening_dialogues set options = '["優先順位を変えたいものがあれば、お客様に相談に行きます。", "何も言わずに、リーさんが自分で優先順位を変えて対応を進めます。", "山本さんに、代わりに優先順位を決めて連絡してもらうようにします。", "次の定例会が開かれるまで待ってから、まとめて報告するようにします。"]'::jsonb
  where id = 'a0df3a64-2003-5161-ad01-4b857f293302'::uuid and options->>correct_index = '優先順位を変えたいものがあれば、お客様に相談に行きます。';
update listening_dialogues set options = '["良かった点と改善すべき点について相談し、まとめます。", "新しいプロジェクトの見積りを作成して、お客様に提出します。", "クラウドの人材を追加で探して、次のプロジェクトに配置します。", "受入テストの結果をまとめて、お客様に詳しく報告します。"]'::jsonb
  where id = 'd681485a-f165-52a4-a93e-ba58b3663f58'::uuid and options->>correct_index = '良かった点と改善すべき点について相談し、まとめます。';

-- ===== B) Câu hỏi mới =====
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'ce7bb3ad-e299-57d9-9752-c395846c64a3'::uuid, d.level_id, d.lesson_id, d.turns, '小巻さんは何日間ベトナムに出張しますか。', '["2日間です。", "1日間です。", "3日間です。", "1週間です。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000001'::uuid and id <> 'ce7bb3ad-e299-57d9-9752-c395846c64a3'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '551096a6-2650-57a3-9b54-b293a4b1b41e'::uuid, d.level_id, d.lesson_id, d.turns, '帰国したあと、要件定義の工程からオンサイトするのは誰ですか。', '["DKH社のホアンさんです。", "SESのリーさんです。", "DKH社のPMのアンさんです。", "SESの小巻さんです。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000001'::uuid and id <> '551096a6-2650-57a3-9b54-b293a4b1b41e'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '86a15abc-fdf9-574a-baad-0153846e7840'::uuid, d.level_id, d.lesson_id, d.turns, '会議のアジェンダは、どの順番で進めますか。', '["キックオフ資料の説明、目的の説明、Q&Aと相談の順です。", "Q&Aと相談、目的の説明、キックオフ資料の説明の順です。", "目的の説明、キックオフ資料の説明、Q&Aと相談の順です。", "目的の説明、Q&Aと相談、キックオフ資料の説明の順です。"]'::jsonb, 2
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000002'::uuid and id <> '86a15abc-fdf9-574a-baad-0153846e7840'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '180fbe98-db10-5b74-b75c-6a5606b8d399'::uuid, d.level_id, d.lesson_id, d.turns, '今回のプロジェクトでは、既存システムをベースに何を取り入れますか。', '["クラウドのサービスを取り入れます。", "iPad専用の画面を取り入れます。", "ゲームのエンジンを取り入れます。", "WebGLを取り入れます。"]'::jsonb, 3
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000002'::uuid and id <> '180fbe98-db10-5b74-b75c-6a5606b8d399'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '36dfc5ae-9bf7-5c90-926e-a0af95f40db3'::uuid, d.level_id, d.lesson_id, d.turns, '今回のプロジェクトの開発手法は何ですか。', '["ウォーターフォールです。", "アジャイルです。", "スクラムです。", "プロトタイプ開発です。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000003'::uuid and id <> '36dfc5ae-9bf7-5c90-926e-a0af95f40db3'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '39a05538-b1d9-50b8-9fc1-cbcff2a19107'::uuid, d.level_id, d.lesson_id, d.turns, 'SRSについて、お客様は何と言っていますか。', '["すでに御社に送ったので、説明は必要ないと言っています。", "完成したので、明日説明すると言っています。", "UIと一緒に、開発が終わってから提供すると言っています。", "まだ書き始めていないので、来月から作ると言っています。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000003'::uuid and id <> '39a05538-b1d9-50b8-9fc1-cbcff2a19107'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '24b0d719-1237-5faf-ba48-45f5ab2daa82'::uuid, d.level_id, d.lesson_id, d.turns, 'オフショア側のプロジェクト統括管理者は誰ですか。', '["アンさんです。", "リーさんです。", "ホアンさんです。", "黒田様です。"]'::jsonb, 2
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000004'::uuid and id <> '24b0d719-1237-5faf-ba48-45f5ab2daa82'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'c4abd2c8-2474-5ca1-933b-29cdf82f16be'::uuid, d.level_id, d.lesson_id, d.turns, 'アンさんが管理するのは、どんなチームですか。', '["開発、設計、契約、品質保証の4つのチームと営業部門です。", "開発とテストの2つのチームに加えて、営業のチームです。", "営業、契約、開発、テスト、品質保証の5つのチームです。", "開発、テスト、コミュニケーション、品質保証の4つのチームです。"]'::jsonb, 3
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000004'::uuid and id <> 'c4abd2c8-2474-5ca1-933b-29cdf82f16be'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'b41d5337-239a-5203-9970-defa3b36ee5c'::uuid, d.level_id, d.lesson_id, d.turns, 'SESの社員は、だいたい何分前に出社していますか。', '["10分前です。", "30分前です。", "5分前です。", "1時間前です。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000005'::uuid and id <> 'b41d5337-239a-5203-9970-defa3b36ee5c'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'cf2c9bca-f2e8-502e-8c1c-e280fb1b94b5'::uuid, d.level_id, d.lesson_id, d.turns, 'お昼休みについて、正しいのはどれですか。', '["必ず12時から1時の間に取らなければならないことになっている。", "基本は12時から1時だが、1時間であれば時間をずらして取ってもよい。", "12時から1時が基本で、30分に短くして取ってもよいことになっている。", "基本は1時から2時で、混んでいるときだけ12時に取ってもよい。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000005'::uuid and id <> 'cf2c9bca-f2e8-502e-8c1c-e280fb1b94b5'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'eac1b18c-b647-568e-a5eb-45ad916df373'::uuid, d.level_id, d.lesson_id, d.turns, '会議室を使いたいときは、どうすればよいですか。', '["当日の朝にIT部門の人に頼みます。", "空いていれば、予約しないで自由に使います。", "事前に会議室予約システムから予約します。", "使う前に、総務部に紙の申込書を出します。"]'::jsonb, 2
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000006'::uuid and id <> 'eac1b18c-b647-568e-a5eb-45ad916df373'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'e68b9d92-aa32-536f-813a-b4bfab88a3b9'::uuid, d.level_id, d.lesson_id, d.turns, 'ごみはどのように捨てますか。', '["すべて給湯室の大きなごみ箱に一緒に捨てます。", "机の横のごみ箱に分別しないで捨てます。", "毎日退社するときに、自分で持ち帰ります。", "生ごみやペットボトルなどに分別して捨てます。"]'::jsonb, 3
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000006'::uuid and id <> 'e68b9d92-aa32-536f-813a-b4bfab88a3b9'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '96d22236-bd8b-530c-81c9-3845290e3c25'::uuid, d.level_id, d.lesson_id, d.turns, '画面に「新規」と追記されているのは、どんな画面ですか。', '["新しく作る画面です。", "以前のアプリと同じ画面です。", "Web版で実装しなくてよい画面です。", "機能の修正点がまとめられている画面です。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000007'::uuid and id <> '96d22236-bd8b-530c-81c9-3845290e3c25'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '66f1b157-60eb-597c-aa52-56b14a4ea347'::uuid, d.level_id, d.lesson_id, d.turns, '「Web化対象外」と追記されている画面は、どうしますか。', '["以前のアプリと同じ画面にします。", "Web版では実装しなくてよいです。", "新しいデザインで作り直します。", "ほかの画面より先に実装します。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000007'::uuid and id <> '66f1b157-60eb-597c-aa52-56b14a4ea347'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'afeaf466-3147-553e-af2e-bfa5304f504e'::uuid, d.level_id, d.lesson_id, d.turns, '4つの機能の実装タスクの状況は、どうなっていますか。', '["2つは完了、1つは実施中、1つは遅延しています。", "すべて実施中で、遅延しているものはありません。", "1つは完了、1つは実施中、2つは遅延しています。", "1つは完了、2つは実施中、1つは遅延しています。"]'::jsonb, 2
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000008'::uuid and id <> 'afeaf466-3147-553e-af2e-bfa5304f504e'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '5ca19d17-bb4a-5f75-8cd7-44c72ef7fab4'::uuid, d.level_id, d.lesson_id, d.turns, '画面の実装と結合テスト仕様書の作成の進捗は、それぞれ何%ですか。', '["画面の実装は30%、結合テスト仕様書の作成は50%です。", "画面の実装も結合テスト仕様書の作成も50%です。", "画面の実装は80%、結合テスト仕様書の作成は30%です。", "画面の実装は50%、結合テスト仕様書の作成は30%です。"]'::jsonb, 3
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000008'::uuid and id <> '5ca19d17-bb4a-5f75-8cd7-44c72ef7fab4'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '9619ee72-eaf5-5523-a0b9-120e76348594'::uuid, d.level_id, d.lesson_id, d.turns, 'メモリ不足の問題に対して、チームはどんな対策をしていますか。', '["静的データを使う代わりに、indexedDBにデータを保存します。", "お客様のパソコンに、もっと多くのRAMを追加してもらいます。", "一部の画面をWeb版から外して、デスクトップ版だけにします。", "静的データをもっと小さくして、RAMに保存し続けます。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000009'::uuid and id <> '9619ee72-eaf5-5523-a0b9-120e76348594'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '4dbf4d7c-eed5-5dab-a041-8bf1f537484a'::uuid, d.level_id, d.lesson_id, d.turns, 'タスクの遅れは何人日で、いつ取り戻す予定ですか。', '["2人日の遅れで、今月末に取り戻す予定です。", "2人日の遅れで、来週中に取り戻す予定です。", "5人日の遅れで、来週中に取り戻す予定です。", "10人日の遅れで、次のリリースで取り戻す予定です。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000009'::uuid and id <> '4dbf4d7c-eed5-5dab-a041-8bf1f537484a'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'cd4df66f-bc64-5c37-aad1-79f3f4b3450c'::uuid, d.level_id, d.lesson_id, d.turns, 'Q&Aファイルに追加した質問は、何件ですか。', '["1番から4番の4件です。", "5番から10番の6件です。", "5番から8番の4件です。", "5番だけの1件です。"]'::jsonb, 2
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000010'::uuid and id <> 'cd4df66f-bc64-5c37-aad1-79f3f4b3450c'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'b404f01e-f33f-5922-b42f-07f2e6a9a608'::uuid, d.level_id, d.lesson_id, d.turns, 'テストするブラウザとバージョンについて、お客様は何と言いましたか。', '["Safariだけで、最新のバージョンのみです。", "SafariとChromeで、一つ前のバージョンも必要です。", "Chromeだけで、最新のバージョンのみです。", "SafariとChromeで、最新のバージョンのみです。"]'::jsonb, 3
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000010'::uuid and id <> 'b404f01e-f33f-5922-b42f-07f2e6a9a608'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '3903e59b-264c-5bfe-aa62-61a6b5847b78'::uuid, d.level_id, d.lesson_id, d.turns, '詳細画面では、画像をどこに配置していますか。', '["上部に配置しています。", "下部に配置しています。", "右側に配置しています。", "画面の中央に配置しています。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000011'::uuid and id <> '3903e59b-264c-5bfe-aa62-61a6b5847b78'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '3cd0a3c7-9705-513f-9236-9287369cfac2'::uuid, d.level_id, d.lesson_id, d.turns, 'デフォルトの画像サイズを小さくする案は、なぜ難しいですか。', '["ボタンの数が多すぎて、画像を小さくする余裕がないからです。", "アプリの表示枠が画面の縦横の比率に固定されているからです。", "画像を小さくすると、ペンツールが使えなくなるからです。", "お客様が画像サイズの変更を認めていないからです。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000011'::uuid and id <> '3cd0a3c7-9705-513f-9236-9287369cfac2'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '8aa4d890-af02-5755-aad6-3752d6283b1e'::uuid, d.level_id, d.lesson_id, d.turns, 'チームは、今回のリリースでどのバージョンを納品したいと言っていますか。', '["制限をかけないバージョンです。", "機能を減らした簡易バージョンです。", "制限を設けたバージョンです。", "テスト用の試作バージョンです。"]'::jsonb, 2
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000012'::uuid and id <> '8aa4d890-af02-5755-aad6-3752d6283b1e'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '91d31747-0c2e-5269-93e4-3cdf62037fc1'::uuid, d.level_id, d.lesson_id, d.turns, 'チームは、お客様にいつまでに回答してほしいと言っていますか。', '["今日中です。", "今週の金曜日までです。", "来週中です。", "明日中です。"]'::jsonb, 3
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000012'::uuid and id <> '91d31747-0c2e-5269-93e4-3cdf62037fc1'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '7ca4d3b3-9507-580d-b82c-47a662d7fbec'::uuid, d.level_id, d.lesson_id, d.turns, 'お客様の要望で、インストール手順書に追加された内容は何ですか。', '["アンインストールの手順です。", "バックアップの手順です。", "端末の設定の手順です。", "トラブルのときの連絡先です。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000013'::uuid and id <> '7ca4d3b3-9507-580d-b82c-47a662d7fbec'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'e90c61a6-0fe8-5638-b171-c37b4640616e'::uuid, d.level_id, d.lesson_id, d.turns, '手順書について、お客様は何と言いましたか。', '["内容に問題がないので、このままの形で承認したいと言いました。", "わかりにくい記載があるので、後ほど確認させてほしいと言いました。", "手順書は読む人がいないので、すべて削除してほしいと言いました。", "日本語だけでなく英語の手順書も追加してほしいと言いました。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000013'::uuid and id <> 'e90c61a6-0fe8-5638-b171-c37b4640616e'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'dfd07c42-354c-5d53-988a-eeab1831b17d'::uuid, d.level_id, d.lesson_id, d.turns, '不具合が出たとき、最初に対応の優先順位を決めるのは誰ですか。', '["リーさんです。", "オフショアチームのPMです。", "お客様の会社です。", "ホアンさんです。"]'::jsonb, 2
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000014'::uuid and id <> 'dfd07c42-354c-5d53-988a-eeab1831b17d'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '9a5f1989-743d-579d-85c3-97efbf1f6c6f'::uuid, d.level_id, d.lesson_id, d.turns, '仕様変更についての相談は、いつ行いますか。', '["明日の朝に行います。", "次の定例会で行います。", "受入テストが終わったあとに行います。", "午後に行います。"]'::jsonb, 3
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000014'::uuid and id <> '9a5f1989-743d-579d-85c3-97efbf1f6c6f'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select '594777f7-16bb-52e6-89ea-7c4408955c94'::uuid, d.level_id, d.lesson_id, d.turns, 'リーさんは、オンサイトで約何か月働きましたか。', '["約4か月です。", "約2か月です。", "約6か月です。", "約1年です。"]'::jsonb, 0
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000015'::uuid and id <> '594777f7-16bb-52e6-89ea-7c4408955c94'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;
insert into listening_dialogues (id, level_id, lesson_id, turns, question_ja, options, correct_index)
select 'ca11bf88-3980-56e3-a231-f25df1a209f8'::uuid, d.level_id, d.lesson_id, d.turns, '次のプロジェクトについて、お客様は何と言っていますか。', '["すでに確定していて、来週から新しいプロジェクトが始まると言っています。", "まだ確定していませんが、もう少し規模の大きなプロジェクトを予定しています。", "前回と同じ規模のプロジェクトを、同じメンバーで行うと言っています。", "今のところ、次のプロジェクトを行う予定は何もないと言っています。"]'::jsonb, 1
from (select level_id, lesson_id, turns from listening_dialogues where lesson_id = '98000000-0000-0000-0000-000000000015'::uuid and id <> 'ca11bf88-3980-56e3-a231-f25df1a209f8'::uuid limit 1) d
on conflict (id) do update set question_ja = excluded.question_ja, options = excluded.options, correct_index = excluded.correct_index;

commit;
