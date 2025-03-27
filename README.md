# playwright-sse-mcp-server

PlaywrightをMCP（Model Context Protocol）サーバーとして提供するためのサービスです。このサーバーを使用することで、MCPクライアントからPlaywrightの機能を利用することができます。

## 前提条件

- Dockerがインストールされていること
- docker-composeがインストールされていること
- mcp-networkという名前のDockerネットワークが作成されていること

mcp-networkが存在しない場合は、以下のコマンドで作成できます：

```bash
docker network create mcp-network
```

## セットアップと起動方法

1. リポジトリをクローンまたはダウンロードします
2. プロジェクトのルートディレクトリで以下のコマンドを実行します：

```bash
docker compose up --build
```

これにより、デフォルトの3002ポートでサーバーが起動します。起動が完了すると、以下のようなメッセージが表示されます：

```
playwright-sse-mcp-server  | Server is running on port 3002
```

### カスタムポートの設定

デフォルトポート（3002）以外のポートでサーバーを起動したい場合は、環境変数`PORT`を設定します：

```bash
PORT=4000 docker compose up --build
```

これにより、指定したポート（この例では4000）でサーバーが起動します：

```
playwright-sse-mcp-server  | Server is running on port 4000
```

## 使用方法

### 同じmcp-networkに参加しているコンテナからの接続

同じmcp-networkに参加している他のコンテナからは、以下のURLでサーバーに接続できます（`PORT`はサーバーの起動ポート）：

```
playwright-sse-mcp-server:${PORT}/sse
```

デフォルトポートを使用している場合：

```
playwright-sse-mcp-server:3002/sse
```

これにより、PlaywrightのMCP機能を利用することができます。

### ホスト側からの接続

ホストマシンからは、以下のURLでサーバーに接続できます（`PORT`はサーバーの起動ポート）：

```
localhost:${PORT}/sse
```

デフォルトポートを使用している場合：

```
localhost:3002/sse
```

### Roo Codeからの接続

MCP Servers -> MCP設定を編集 -> 以下を記入します（`PORT`はサーバーの起動ポート）：

```json
{
  "mcpServers": {
    "playwright-sse-mcp-server-local": {
      "url": "http://localhost:${PORT}/sse"
    }
  }
}
```

デフォルトポートを使用している場合：

```json
{
  "mcpServers": {
    "playwright-sse-mcp-server-local": {
      "url": "http://localhost:3002/sse"
    }
  }
}
```

※2025/03/27現在、ClineはSSEをサポートしていない為使えません。

## 便利な使用方法

毎回プロジェクトディレクトリに移動してdocker composeコマンドを実行するのは面倒です。以下の方法を使用すると、どこからでも簡単にサーバーを起動・停止できます。

### シェル関数を使用した方法

1. ホームディレクトリに`mcps`ディレクトリを作成し、そこにプロジェクトを配置します：

```bash
mkdir -p ~/mcps
# プロジェクトをmcpsディレクトリに移動またはクローン
git clone https://github.com/your-username/playwright-sse-mcp-server.git ~/mcps/playwright-sse-mcp-server
```

2. `.bashrc`（または`.zshrc`など使用しているシェルの設定ファイル）に以下のシェル関数を追加します：

```bash
vim ~/.bashrc
# Playwright MCP Server
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
  (cd ~/mcps/playwright-sse-mcp-server && PORT=$port RESTART_POLICY=$restart_policy docker compose up -d)
  echo "Playwright MCP Server started on port $port with restart policy: $restart_policy"
}

playwright-mcp-stop() {
  (cd ~/mcps/playwright-sse-mcp-server && docker compose down)
  echo "Playwright MCP Server stopped"
}

playwright-mcp-logs() {
  (cd ~/mcps/playwright-sse-mcp-server && docker compose logs -f)
}
```

3. シェルを再起動するか、設定ファイルを再読み込みします：

```bash
source ~/.bashrc
```

これで、どこからでも以下のコマンドを使用できるようになります：

#### 基本的な使用方法

- `playwright-mcp-start` - デフォルト設定（ポート3002、再起動なし）でサーバーを起動
- `playwright-mcp-stop` - サーバーを停止
- `playwright-mcp-logs` - サーバーのログを表示

#### 永続モードの使用

永続モードを使用すると、システム再起動時にサーバーが自動的に起動します：

```bash
playwright-mcp-start -p
# または
playwright-mcp-start --persistent
```

#### カスタムポートの使用

```bash
playwright-mcp-start -P 4000
# または
playwright-mcp-start --port 4000
```

#### 永続モードとカスタムポートの組み合わせ

```bash
playwright-mcp-start -P 4000 -p
# または
playwright-mcp-start --port 4000 --persistent
```

#### 特定の再起動ポリシーの指定

```bash
playwright-mcp-start -r always
# または
playwright-mcp-start --restart always
```

#### ヘルプの表示

```bash
playwright-mcp-start -h
# または
playwright-mcp-start --help
```

この方法では、フラグオプションを使用して柔軟に設定を変更できるため、より使いやすくなっています。

## 注意事項

- このサーバーはheadlessモードでPlaywrightを実行します
- サーバーはSSE（Server-Sent Events）を使用してMCPクライアントと通信します