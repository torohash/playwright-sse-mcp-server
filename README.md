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

#### コンテナ環境でのRoo Codeからの接続

同じDocker Network内で実行されているRoo Codeコンテナからは、以下のようにMCP設定を行います：

```json
{
  "mcpServers": {
    "playwright-sse-mcp-server-local": {
      "url": "http://playwright-sse-mcp-server:3002/sse"
    }
  }
}
```

**docker-compose.yml設定例**：

```yaml
services:
  # Roo Code コンテナ
  roo-code:
    # 略

networks:
  mcp-network:
    external: true
```

この設定により、Roo Codeコンテナからplaywright-sse-mcp-serverコンテナに接続し、ブラウザ操作機能を利用できます。コンテナ名（`playwright-sse-mcp-server`）をホスト名として使用することで、Docker Network内での名前解決が可能になります。

## 便利な使用方法

毎回プロジェクトディレクトリに移動してdocker composeコマンドを実行するのは面倒です。以下の方法を使用すると、どこからでも簡単にサーバーを起動・停止できます。

### シェルスクリプトを使用した方法

このプロジェクトには、サーバーの起動・停止・ログ表示を簡単に行うためのシェルスクリプトが含まれています。

1. プロジェクトをクローンまたはダウンロードします：

```bash
# 任意のディレクトリにクローン
git clone https://github.com/torohash/playwright-sse-mcp-server.git /path/to/installation
```

2. `.bashrc`（または`.zshrc`など使用しているシェルの設定ファイル）に以下の行を追加して、シェルスクリプトを読み込みます：

```bash
# Playwright MCP Server
export PLAYWRIGHT_MCP_HOME="/path/to/installation"
source "$PLAYWRIGHT_MCP_HOME/scripts/playwright-mcp.sh"

# 具体例（絶対パス利用）
export PLAYWRIGHT_MCP_HOME="$HOME/mcps/playwright-sse-mcp-server"  # 実際のパスに置き換えてください
source "$PLAYWRIGHT_MCP_HOME/scripts/playwright-mcp.sh"
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

この方法では、フラグオプションを使用して柔軟に設定を変更できるため、より使いやすくなっています。また、シェルスクリプトを別ファイルに分離することで、.bashrcファイルがシンプルになり、管理が容易になります。

### シェルスクリプトのカスタマイズ

シェルスクリプトは`scripts/playwright-mcp.sh`にあります。必要に応じて、このファイルを編集してカスタマイズすることができます。

#### 環境変数

シェルスクリプトは以下の環境変数を使用します：

- `PLAYWRIGHT_MCP_HOME`: プロジェクトのインストールディレクトリ。設定されていない場合は、スクリプトの場所から自動的に検出されます。

例えば、以下のように環境変数を設定することで、カスタムパスを指定できます：

```bash
export PLAYWRIGHT_MCP_HOME="/path/to/custom/installation"
```

## 注意事項

- このサーバーはheadlessモードでPlaywrightを実行します
- サーバーはSSE（Server-Sent Events）を使用してMCPクライアントと通信します