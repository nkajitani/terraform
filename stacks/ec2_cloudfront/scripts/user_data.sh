#!/bin/bash
set -ex

sudo dnf install -y nginx

cat >/usr/share/nginx/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EC2 Instance</title>
</head>
<body>
    <h1>Welcome to EC2 Instance</h1>
</body>
</html>
EOF


cat >/etc/nginx/conf.d/cache.conf <<'EOF'
server {
    listen       80;
    server_name  _;

    location / {
        root /usr/share/nginx/html;
        index index.html;

        add_header Cache-Control "max-age=60, public";

        add_header X-Origin-Now $time_iso8601;
    }
}
EOF

systemctl enable nginx
systemctl restart nginx

# install CloudWatch Agent
sudo dnf install -y amazon-cloudwatch-agent

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/ec2/web/ec2-cloudfront-messages",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
