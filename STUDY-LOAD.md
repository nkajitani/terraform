   Phase 1: ネットワーク基礎の強化

     - VPC + Public/Private Subnet + NAT Gateway

   Phase 2: セキュリティとアクセス制御

     - Security Group の管理
     - Network ACL の設定
     - VPC Endpoints (S3, EC2など)

   Phase 3: コンピューティングリソース

     - EC2 + Security Group + Key Pair
     - ALB + Target Group + EC2
     - Auto Scaling Group

   Phase 4: データベース・ストレージ

     - RDS (Subnet Group + Security Group)
     - S3 + Bucket Policy
     - ElastiCache (Redis/Memcached)

   Phase 5: 実務的なパターン

     - 3-Tier Architecture (ALB + EC2 + RDS)
     - Bastion Host経由のプライベート接続
     - CloudWatch Logs + Monitoring

   Phase 6: 高度な構成

     - Module化（再利用可能なコンポーネント）
     - Multi-Environment (dev/stg/prod)
     - Remote State (S3 + DynamoDB)
