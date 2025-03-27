#!/bin/bash

# スクリプト自身のパスを取得（sourceコマンドでも動作するように改善）
if [ -n "${BASH_SOURCE[0]}" ]; then
  # Bash
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "$ZSH_VERSION" ]; then
  # Zsh
  SCRIPT_PATH="${(%):-%x}"
else
  # その他のシェル（推測）
  SCRIPT_PATH="$0"
fi

# 絶対パスに変換
if [ -z "$SCRIPT_PATH" ]; then
  echo "警告: スクリプトのパスを特定できませんでした。環境変数PLAYWRIGHT_MCP_HOMEを設定してください。"
  # デフォルトのパスを使用
  SCRIPT_DIR="$HOME/mcps/playwright-sse-mcp-server/scripts"
else
  SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_PATH" )" && pwd )"
fi

# 環境変数が設定されていない場合は、スクリプトの場所から推測
PLAYWRIGHT_MCP_HOME=${PLAYWRIGHT_MCP_HOME:-"$( dirname "$SCRIPT_DIR" )"}

# パスが存在するか確認
if [ ! -d "$PLAYWRIGHT_MCP_HOME" ]; then
  echo "警告: ディレクトリ $PLAYWRIGHT_MCP_HOME が存在しません。"
  echo "環境変数PLAYWRIGHT_MCP_HOMEを正しいパスに設定してください。"
  echo "例: export PLAYWRIGHT_MCP_HOME=\"$HOME/mcps/playwright-sse-mcp-server\""
fi

# Playwright MCP Server シェル関数

# サーバーを起動する関数
playwright-mcp-start() {
  local port=3002
  local restart_policy="no"
  local help=false
  
  # オプションの解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--persistent)
        restart_policy="unless-stopped"
        shift
        ;;
      -r|--restart)
        if [[ -n "$2" && "$2" != -* ]]; then
          restart_policy="$2"
          shift 2
        else
          echo "Error: --restart requires an argument."
          return 1
        fi
        ;;
      -P|--port)
        if [[ -n "$2" && "$2" != -* ]]; then
          port="$2"
          shift 2
        else
          echo "Error: --port requires an argument."
          return 1
        fi
        ;;
      -h|--help)
        help=true
        shift
        ;;
      *)
        # 後方互換性のために、数字のみの引数はポート番号として扱う
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          port="$1"
          shift
        else
          echo "Unknown option: $1"
          help=true
          shift
        fi
        ;;
    esac
  done
  
  # ヘルプの表示
  if [[ "$help" = true ]]; then
    echo "Usage: playwright-mcp-start [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --persistent       永続的に実行（システム再起動時に自動起動）"
    echo "  -r, --restart POLICY   再起動ポリシーを指定（no, always, on-failure, unless-stopped）"
    echo "  -P, --port PORT        ポート番号を指定（デフォルト: 3002）"
    echo "  -h, --help             このヘルプメッセージを表示"
    echo ""
    echo "Examples:"
    echo "  playwright-mcp-start                   # デフォルト設定で起動（ポート3002、再起動なし）"
    echo "  playwright-mcp-start -p                # 永続モードで起動（システム再起動時に自動起動）"
    echo "  playwright-mcp-start -P 4000           # ポート4000で起動"
    echo "  playwright-mcp-start -P 4000 -p        # ポート4000で永続モードで起動"
    echo "  playwright-mcp-start -r always         # 常に再起動するモードで起動"
    return 0
  fi
  
  # サーバーの起動
  (cd "$PLAYWRIGHT_MCP_HOME" && PORT=$port RESTART_POLICY=$restart_policy docker compose up -d)
  echo "Playwright MCP Server started on port $port with restart policy: $restart_policy"
}

# サーバーを停止する関数
playwright-mcp-stop() {
  (cd "$PLAYWRIGHT_MCP_HOME" && docker compose down)
  echo "Playwright MCP Server stopped"
}

# サーバーのログを表示する関数
playwright-mcp-logs() {
  (cd "$PLAYWRIGHT_MCP_HOME" && docker compose logs -f)
}