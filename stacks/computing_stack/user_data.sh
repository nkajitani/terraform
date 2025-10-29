#!/bin/bash

set -e

exec > >(tee -a /var/log/user_data.log)
exec 2>&1

echo "Starting user data script..."
echo "Date: $(date)"

echo "Updating packages..."
dnf update -y

echo "Installing Nginx web server..."
dnf install -y nginx

AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
PRIVATE_IP=$(ec2-metadata --local-ipv4 | cut -d " " -f 2)

echo "Creating custom HTML page..."
cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Study Web Server - Phase3</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            max-width: 700px;
            width: 90%;
        }
        h1 {
            color: #667eea;
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
            background: linear-gradient(to right, #f8f9fa, #e9ecef);
            border-left: 5px solid #667eea;
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
            color: #667eea;
            font-size: 1.1em;
        }
        .value {
            color: #333;
            font-family: 'Courier New', monospace;
            font-size: 1em;
            background: white;
            padding: 5px 15px;
            border-radius: 5px;
        }
        .badge {
            display: inline-block;
            padding: 8px 20px;
            background-color: #667eea;
            color: white;
            border-radius: 25px;
            font-size: 14px;
            margin-top: 20px;
            font-weight: bold;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #e9ecef;
            color: #999;
            font-size: 0.9em;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Terraform Study - Phase3!</h1>
        <div class="subtitle">Auto Scaling Group + Application Load Balancer</div>
        <span class="badge">Standalone Configuration</span>

        <div class="info">
            <div class="info-item">
                <span class="label">Instance ID:</span>
                <span class="value">${INSTANCE_ID}</span>
            </div>
            <div class="info-item">
                <span class="label">Availability Zone:</span>
                <span class="value">${AVAILABILITY_ZONE}</span>
            </div>
            <div class="info-item">
                <span class="label">Private IP:</span>
                <span class="value">${PRIVATE_IP}</span>
            </div>
            <div class="info-item">
                <span class="label">Web Server:</span>
                <span class="value">Nginx on Amazon Linux 2023</span>
            </div>
        </div>

        <p><strong>✅ このインスタンスはAuto Scaling Groupで管理されています</strong></p>
        <p>負荷に応じて自動的にスケーリングします（Min: 2, Max: 4）</p>

        <div class="footer">
            <p>Deployed with Terraform - Phase 3: Computing Resources</p>
            <p>Phase3単独構成 - VPC、Subnet、SG、ALB、ASGを全てこのスタックで管理</p>
        </div>
    </div>
</body>
</html>
EOF

echo "User data script completed."

echo "Starting Nginx service..."
systemctl enable --now nginx

echo "Checking Nginx status..."
systemctl status nginx

echo "User data script finished successfully."
echo "Date: $(date)"
