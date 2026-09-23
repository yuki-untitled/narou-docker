# 仕様: official-narou ブランチの方針

## Why（なぜ）

- narou-docker はこれまで Rumia-Channel 版 narou.rb（非公式フォーク、docker ブランチ）のみをビルド対象としていた
- Rumia 版は Linux 環境向けの改良（User-Agent 問題、ハーメルン 403 エラー対応など）を含む一方、非公式フォークであるためメンテナンス継続性に不確実性がある
- 公式 narou.rb（[whiteleaf7/narou](https://github.com/whiteleaf7/narou)）をベースにした構成も用意し、選択肢を持たせる
- 公式 narou.rb は rubygems.org への最終リリース（3.9.1）が古く、サイト構造の変化（小説家になろう・ハーメルン等のHTML変更）に追従できていない。追従用の [PR #446](https://github.com/whiteleaf7/narou/pull/446) は本家に未マージのまま更新が続いており、都度最新化する仕組みが必要
- 過去に本プロジェクトの前身（`original` ブランチ）で公式版のみでの運用を試みたが、Linux/Docker 環境で一部サイト（ハーメルン系）が 403 Forbidden になる問題を解決できず、Rumia 版採用の動機になっていた。原因を調査した結果、Rumia 版の対処方法（`wget` ベースの取得方式への置き換え）を移植すれば解決できると判断した

## What（何を）

- 本ブランチでは公式 narou.rb（whiteleaf7/narou, rubygems.org 配信版）を取得してビルドする
- 既存の2つの修正パッチ（`fix-websocket-port.patch` / `fix-ibooks-args.patch`）は Rumia 版 docker ブランチ向けに作られたものであり、そのまま公式版に適用してよいとは限らない。取り扱いは以下の通り
  - **`fix-websocket-port.patch`：適用しない**
    公式版の `create_ws_uri()` は元々ポート分離方式（`location.port + 1` を使う ws URI 組み立て）で実装されている。これは本プロジェクトが必要とする挙動そのものであり、Rumia 版 docker ブランチが独自に「nginx 経由の 443 ポート一本化」方式へ変更していたためにパッチが必要だった、という経緯である（ソース比較により確認済み）。
  - **`fix-ibooks-args.patch`：適用要否は保留**
    静的なコード比較では、公式版・Rumia 版のいずれも `hook_convert_txt_to_ebook_file` の呼び出し経路（`update.rb` 経由、引数なしの relay_proc）は同一であり、パッチが必要な根拠を静的解析だけでは特定できなかった。実機で iBooks 形式への変換を検証し、エラーが再現する場合のみ追加する。
- サイト構造変更への追従（PR446 相当）は、特定日付のパッチファイルを固定で持つのではなく、**ビルド時に本家 PR の最新差分を取得して適用する**方式とする。追従漏れ・パッチの陳腐化を防ぐため
- Linux/Docker 環境での 403 Forbidden 問題（ハーメルン系サイトなど）は、Rumia 版が実装した「`wget` コマンドベースの取得方式への置き換え」を移植して解決する。Ruby の OpenURI/Net::HTTP によるリクエストが一部サイトのボット対策に阻まれるためと考えられ、ブラウザに近いヘッダー構成での取得に切り替えることで回避する

## 検証結果（実装フェーズで確認済み）

- **`fix-websocket-port.patch` 不要の判断は実機でも確認済み**。パッチ無しの公式版で WebSocket ハンドシェイクが成立し（`101 Switching Protocols`）、ログのリアルタイム配信も正常に動作した
- ビルド時、公式 gemspec の依存指定（`tilt ~> 2.0`、上限なし）が原因で、最新の tilt では Web サーバー起動時に `LoadError` が発生することが判明した。回避策を導入済み（詳細は dockerfile のコメントを参照）。narou.gemspec 側の既知の不備であり、本プロジェクト固有の問題ではない
- `fix-ibooks-args.patch` の要否は未検証のまま（iBooks 形式への変換テストは今後実施）
- **PR446 の自動追従を実機で確認済み**。ビルド時に取得した最新差分が正しく適用され、`webnovel/h.syosetu.org.yaml`（新規ファイル）の追加、`ncode.syosetu.com.yaml` のバージョン更新（`2.2`）を確認した。実際に `narou download` で小説家になろうの作品情報取得・フォルダ作成（日本語タイトル）まで正常動作した
- **wget ベース取得方式への置き換えを実機で確認済み**。`Narou::Wget.open` で実サイト（ncode.syosetu.com）への到達・本文取得に成功した。なお、置き換えに伴い `wget` バイナリが実行時に必要になるため、最終イメージにも `wget` パッケージを追加した

## 対象外（Out of Scope）

- Rumia 版固有の依存関係削減（tilt 不要化など）を公式版に移植することは、今回のスコープ外
