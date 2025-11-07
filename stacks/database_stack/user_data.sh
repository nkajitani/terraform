#!/bin/bash

set -e

exec > >(tee -a /var/log/user_data.log)
exec 2>&1

echo "Starting user data script..."
echo "Date: $(date)"

# Aurora MySQL接続情報（Terraform変数から渡される）
AURORA_WRITER="${aurora_writer_endpoint}"
AURORA_READER="${aurora_reader_endpoint}"
DB_NAME="${db_name}"
DB_USERNAME="${db_username}"

# パッケージ更新
echo "Updating packages..."
dnf update -y

# Nginx インストール
echo "Installing Nginx..."
dnf install -y nginx

# MySQL Client インストール
echo "Installing MySQL client..."
dnf install -y mariadb105

# Aurora接続テスト用スクリプト作成
cat > /usr/local/bin/test-aurora-connection.sh <<'DBTEST'
#!/bin/bash
echo "Testing Aurora MySQL Writer connection..."
mysql -h $AURORA_WRITER -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT VERSION();"

echo "Testing Aurora MySQL Reader connection..."
mysql -h $AURORA_READER -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT @@innodb_read_only;"
DBTEST

chmod +x /usr/local/bin/test-aurora-connection.sh

# インスタンス情報取得
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
PRIVATE_IP=$(ec2-metadata --local-ipv4 | cut -d " " -f 2)

# カスタムHTMLページ作成
cat > /usr/share/nginx/html/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Study Terraform - Aurora MySQL</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #FF9500 0%, #FF6B35 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .container {
            background-color: white;
            padding: 50px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 900px;
            width: 90%;
        }
        h1 {
            color: #FF6B35;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            color: #999;
            margin-bottom: 40px;
            font-size: 1.1em;
        }
        .info {
            margin: 30px 0;
            padding: 25px;
            background: linear-gradient(to right, #fff3e0, #ffe0b2);
            border-left: 5px solid #FF6B35;
            border-radius: 8px;
        }
        .info-item {
            margin: 15px 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .label {
            font-weight: bold;
            color: #FF6B35;
            font-size: 1.1em;
        }
        .value {
            color: #333;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            background: white;
            padding: 5px 15px;
            border-radius: 5px;
        }
        .badge {
            display: inline-block;
            padding: 8px 20px;
            background-color: #FF6B35;
            color: white;
            border-radius: 25px;
            font-size: 14px;
            margin: 5px;
            font-weight: bold;
        }
        .aurora-logo {
            color: #FF9900;
            font-weight: bold;
            font-size: 1.2em;
        }
        .features {
            margin-top: 30px;
            padding: 20px;
            background: #f5f5f5;
            border-radius: 10px;
        }
        .features h3 {
            color: #FF6B35;
            margin-bottom: 15px;
        }
        .status {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background-color: #4CAF50;
            margin-right: 5px;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 <span class="aurora-logo">Amazon Aurora</span> MySQL</h1>
        <div class="subtitle">高性能クラウドネイティブデータベース</div>
        <span class="badge">ALB</span>
        <span class="badge">Auto Scaling</span>
        <span class="badge">Aurora MySQL</span>
        <span class="badge">Multi-AZ</span>

        <div class="info">
            <div class="info-item">
                <span class="label">Instance ID:</span>
                <span class="value">INSTANCE_ID_PLACEHOLDER</span>
            </div>
            <div class="info-item">
                <span class="label">Availability Zone:</span>
                <span class="value">AZ_PLACEHOLDER</span>
            </div>
            <div class="info-item">
                <span class="label">Private IP:</span>
                <span class="value">IP_PLACEHOLDER</span>
            </div>
            <div class="info-item">
                <span class="label"><span class="status"></span>Writer Endpoint:</span>
                <span class="value">WRITER_ENDPOINT_PLACEHOLDER</span>
            </div>
            <div class="info-item">
                <span class="label"><span class="status"></span>Reader Endpoint:</span>
                <span class="value">READER_ENDPOINT_PLACEHOLDER</span>
            </div>
            <div class="info-item">
                <span class="label">Database Name:</span>
                <span class="value">DB_NAME_PLACEHOLDER</span>
            </div>
        </div>

        <div class="features">
            <h3>⚡ Aurora MySQL の特徴</h3>
            <ul style="list-style: none; padding-left: 0;">
                <li>✅ <strong>5倍高速:</strong> 標準MySQL比で最大5倍のパフォーマンス</li>
                <li>✅ <strong>自動スケーリング:</strong> ストレージが自動拡張（10GB→128TB）</li>
                <li>✅ <strong>高可用性:</strong> 3つのAZに6つのデータコピー</li>
                <li>✅ <strong>高速フェイルオーバー:</strong> 30秒未満で自動切替</li>
                <li>✅ <strong>最大15個のリードレプリカ:</strong> 読み取り性能向上</li>
                <li>✅ <strong>継続的バックアップ:</strong> S3への自動バックアップ</li>
                <li>✅ <strong>バックトラック:</strong> 24時間前まで遡れる</li>
                <li>✅ <strong>Performance Insights:</strong> 詳細なパフォーマンス分析</li>
            </ul>
        </div>

        <div style="margin-top: 30px; padding: 20px; background: #e3f2fd; border-radius: 10px;">
            <h3 style="color: #1976d2;">📐 インフラ構成</h3>
            <ul style="list-style: none; padding-left: 0;">
                <li>🌐 <strong>VPC:</strong> 10.0.0.0/16 (Multi-AZ)</li>
                <li>⚖️ <strong>ALB:</strong> Application Load Balancer</li>
                <li>📈 <strong>ASG:</strong> 1-6 instances (CPU 50% Auto Scaling)</li>
                <li>🗄️ <strong>Aurora MySQL:</strong> Writer + Reader (Multi-AZ)</li>
                <li>🔒 <strong>暗号化:</strong> KMS暗号化、転送時も暗号化</li>
                <li>📊 <strong>監視:</strong> CloudWatch + Performance Insights</li>
            </ul>
        </div>

        <p style="margin-top: 30px; text-align: center; color: #666;">
            <strong>🎯 Aurora MySQL 8.0</strong> - UTF-8, 日本時間, スロークエリログ有効<br>
            <strong>💾 バックアップ:</strong> 7日間保持 + 24時間バックトラック<br>
            <strong>⚡ 高性能:</strong> 標準MySQLの5倍速、レイテンシー1ms以下
        </p>
    </div>
</body>
</html>
HTMLEOF

# プレースホルダーを実際の値で置換
sed -i "s/INSTANCE_ID_PLACEHOLDER/$INSTANCE_ID/g" /usr/share/nginx/html/index.html
sed -i "s/AZ_PLACEHOLDER/$AVAILABILITY_ZONE/g" /usr/share/nginx/html/index.html
sed -i "s/IP_PLACEHOLDER/$PRIVATE_IP/g" /usr/share/nginx/html/index.html
sed -i "s/WRITER_ENDPOINT_PLACEHOLDER/$AURORA_WRITER/g" /usr/share/nginx/html/index.html
sed -i "s/READER_ENDPOINT_PLACEHOLDER/$AURORA_READER/g" /usr/share/nginx/html/index.html
sed -i "s/DB_NAME_PLACEHOLDER/$DB_NAME/g" /usr/share/nginx/html/index.html

# Nginx起動
echo "Starting Nginx..."
systemctl enable --now nginx

# ヘルスチェック用エンドポイント
echo "OK" > /usr/share/nginx/html/health.html

echo "User data script completed successfully."
echo "Date: $(date)"