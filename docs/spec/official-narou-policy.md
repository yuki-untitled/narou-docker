# 仕様: official-narou ブランチの方針

## Why（なぜ）

- narou-docker はこれまで Rumia-Channel 版 narou.rb（非公式フォーク、docker ブランチ）のみをビルド対象としていた
- Rumia 版は Linux 環境向けの改良（User-Agent 問題、ハーメルン 403 エラー対応など）を含む一方、非公式フォークであるためメンテナンス継続性に不確実性がある
- 公式 narou.rb（[whiteleaf7/narou](https://github.com/whiteleaf7/narou)）をベースにした構成も用意し、選択肢を持たせる

## What（何を）

- 本ブランチでは公式 narou.rb（whiteleaf7/narou, master）を取得してビルドする
- 既存の2つの修正パッチ（`fix-websocket-port.patch` / `fix-ibooks-args.patch`）は Rumia 版 docker ブランチ向けに作られたものであり、そのまま公式版に適用してよいとは限らない。取り扱いは以下の通り
  - **`fix-websocket-port.patch`：適用しない**
    公式版の `create_ws_uri()` は元々ポート分離方式（`location.port + 1` を使う ws URI 組み立て）で実装されている。これは本プロジェクトが必要とする挙動そのものであり、Rumia 版 docker ブランチが独自に「nginx 経由の 443 ポート一本化」方式へ変更していたためにパッチが必要だった、という経緯である（ソース比較により確認済み）。
  - **`fix-ibooks-args.patch`：適用要否は保留**
    静的なコード比較では、公式版・Rumia 版のいずれも `hook_convert_txt_to_ebook_file` の呼び出し経路（`update.rb` 経由、引数なしの relay_proc）は同一であり、パッチが必要な根拠を静的解析だけでは特定できなかった。実機で iBooks 形式への変換を検証し、エラーが再現する場合のみ追加する。
- Rumia 版が解決していた既知の問題（Linux User-Agent 問題、ハーメルン 403 エラーなど）が公式版でも発生するかどうかは、本仕様の対象外とし、実装・検証時に別途確認する

## 検証結果（実装フェーズで確認済み）

- **`fix-websocket-port.patch` 不要の判断は実機でも確認済み**。パッチ無しの公式版で WebSocket ハンドシェイクが成立し（`101 Switching Protocols`）、ログのリアルタイム配信も正常に動作した
- ビルド時、公式 gemspec の依存指定（`tilt ~> 2.0`、上限なし）が原因で、最新の tilt では Web サーバー起動時に `LoadError` が発生することが判明した。回避策を導入済み（詳細は dockerfile のコメントを参照）。narou.gemspec 側の既知の不備であり、本プロジェクト固有の問題ではない
- `fix-ibooks-args.patch` の要否は未検証のまま（iBooks 形式への変換テストは今後実施）

## 対象外（Out of Scope）

- Rumia 版固有の依存関係削減（tilt 不要化など）を公式版に移植することは、今回のスコープ外
