#!/bin/sh
# ========================================
# narou.rb 初期化スクリプト
# ========================================

# 初回起動時のみ設定ファイルを作成
if [ ! -e /home/narou/novel/.narou ]; then
  mkdir .narou .narousetting
  
  # グローバル設定
  cat > .narousetting/global_setting.yaml <<EOF
---
aozoraepub3dir: "/opt/aozoraepub3"
over18: true
server-port: 33000
server-bind: 0.0.0.0
EOF

  # サーバー設定
  cat > .narousetting/server_setting.yaml <<EOF
---
already-server-boot: true
EOF

  # その他の設定
  narou s convert.no-open=true
fi

exec "$@"
