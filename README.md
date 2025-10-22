# Terraform Study Project

TerraformでAWSリソースを構築する学習用プロジェクト

## ディレクトリ構成

```
terraform/
├── components/        # コンポーネント
│   ├── ec2/          # EC2インスタンス
│   ├── pub_subnet/   # パブリックサブネット
│   └── vpc/          # VPC
└── stacks/           # スタック（複数コンポーネント組み合わせ）
    └── pub_subnet_x_pri_subnet/  # パブリック・プライベートサブネット構成
```

## 使用方法

```bash
# 初期化
terraform init

# プラン確認
terraform plan

# 適用
terraform apply

# 削除
terraform destroy
```

## リージョン

ap-northeast-1 (東京)
