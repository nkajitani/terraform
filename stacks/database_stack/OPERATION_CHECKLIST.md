# 実務における Terraform 運用チェックリスト

## 📋 今回の構成概要
- **VPC**: 3層構成 (Public, Private, RDS)
- **Web層**: ALB + AutoScaling Group (EC2)
- **DB層**: Aurora MySQL Cluster (Multi-AZ)
- **運用層**: Bastion Server (Multi-AZ)

---

## 🔍 実務でチェックする観点

### 1. **変更前の事前確認** (Pre-deployment)
#### Infrastructure状態確認
- [ ] 現在のリソース稼働状況
- [ ] 既存のトラフィック状況
- [ ] メンテナンスウィンドウの確認
- [ ] 影響範囲の特定

#### Terraform実行前確認
- [ ] `terraform plan` の差分確認
- [ ] 想定外の削除・置き換えがないか
- [ ] State ファイルのバックアップ
- [ ] リソース依存関係の確認

#### コスト影響確認
- [ ] 新規リソースのコスト試算
- [ ] スケール変更によるコスト増減
- [ ] Reserved Instance / Savings Plans との整合性

---

### 2. **適用後の動作確認** (Post-deployment)

#### 🌐 VPC / Network層
**マネジメントコンソール確認手順:**
```
1. VPC Dashboard
   - VPC一覧から対象VPCを確認
   - CIDR範囲の確認
   
2. Subnets
   - Public/Private/RDS subnet の存在確認
   - AZ分散の確認 (ap-northeast-1a, 1c)
   - Route Table の関連付け確認
   
3. Internet Gateway
   - VPCへのアタッチ確認
   
4. NAT Gateway
   - 各AZに配置されているか
   - Elastic IP の関連付け確認
   - 状態が "Available" か
   
5. Route Tables
   - Public: 0.0.0.0/0 → IGW
   - Private: 0.0.0.0/0 → NAT GW
   - RDS: ルート設定なし（隔離）
```

**確認ポイント:**
- [ ] 各サブネットが適切なAZに配置されているか
- [ ] NAT Gatewayが正常に動作しているか（Privateサブネットからのインターネットアクセス）
- [ ] RDSサブネットが外部からアクセス不可能か

**AWS CLI確認コマンド:**
```bash
# VPC確認
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=study-terraform-vpc"

# Subnet確認
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"

# NAT Gateway状態確認
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-xxxxx"
```

---

#### 🖥️ EC2 / AutoScaling層

**マネジメントコンソール確認手順:**
```
1. EC2 Dashboard
   → Auto Scaling Groups
   
2. ASG詳細確認
   - Desired / Min / Max capacity の値
   - Current capacity（実際に起動しているインスタンス数）
   - Activity history（スケールイベント履歴）
   
3. Instances タブ
   - 起動中のインスタンス一覧
   - Health status が "Healthy" か
   - Lifecycle が "InService" か
   
4. Instance management
   - Launch Template の確認
   - Instance type, AMI の確認
   - User data の設定内容
   
5. 個別のEC2インスタンス確認
   - Instance state: running
   - Status checks: 2/2 passed
   - Security groups の設定
   - IAM role の関連付け
```

**確認ポイント:**
- [ ] ASGのDesired Capacityが想定値（3）になっているか
- [ ] 3台のインスタンスが正常起動しているか
- [ ] インスタンスが複数AZに分散配置されているか
- [ ] Security Group で必要なポートが開いているか
- [ ] IAM Roleが適切にアタッチされているか

**AWS CLI確認コマンド:**
```bash
# ASG詳細確認
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names study-web-asg

# ASG配下のインスタンス確認
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=study-web-asg" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,Placement.AvailabilityZone]'

# インスタンスのヘルスチェック
aws autoscaling describe-auto-scaling-instances \
  --query 'AutoScalingInstances[*].[InstanceId,HealthStatus,LifecycleState]'
```

---

#### ⚖️ Load Balancer (ALB)

**マネジメントコンソール確認手順:**
```
1. EC2 Dashboard
   → Load Balancers
   
2. ALB詳細確認
   - State: active
   - DNS name の確認（アクセステスト用）
   - Availability Zones の確認
   
3. Listeners タブ
   - Port 80 (HTTP) のリスナー設定
   - Default action: Forward to target group
   
4. Target Groups
   - Registered targets の数（3台になっているか）
   - Health status: healthy の数を確認
   - Health check settings
     * Path: /
     * Interval: 30s
     * Timeout: 5s
     * Healthy threshold: 2
     * Unhealthy threshold: 2
   
5. Monitoring タブ
   - Request count
   - Target response time
   - Healthy/Unhealthy host count
```

**確認ポイント:**
- [ ] ALBのStateが "active" か
- [ ] Target Groupに3台のインスタンスが登録されているか
- [ ] 全てのターゲットが "healthy" になっているか（初期ヘルスチェック完了まで数分）
- [ ] ALBが複数AZに配置されているか
- [ ] Security Groupで80/443ポートが開いているか

**AWS CLI確認コマンド:**
```bash
# ALB詳細確認
aws elbv2 describe-load-balancers \
  --names study-alb

# Target Group確認
aws elbv2 describe-target-groups \
  --names study-alb-target-group

# ターゲットのヘルスステータス確認
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...
```

**動作確認:**
```bash
# ALBのDNS名にアクセス
curl http://study-alb-xxxxxxxxxx.ap-northeast-1.elb.amazonaws.com

# 複数回リクエストして負荷分散を確認
for i in {1..10}; do curl -s http://ALB_DNS_NAME | grep -i instance; done
```

---

#### 🗄️ RDS (Aurora MySQL)

**マネジメントコンソール確認手順:**
```
1. RDS Dashboard
   → Databases
   
2. Cluster確認
   - Status: Available
   - Multi-AZ: Yes
   - Engine version: 8.0.mysql_aurora.3.07.1
   
3. Writer/Reader インスタンス確認
   - Writer instance: 1台
   - Reader instance: 1台
   - 各インスタンスのStatus: Available
   - 配置AZの確認
   
4. Connectivity & security
   - Endpoint & port の確認
     * Writer endpoint (書き込み用)
     * Reader endpoint (読み取り用)
     * Cluster endpoint
   - Security groups の確認
   - Subnet group の確認（RDSサブネット使用）
   
5. Configuration
   - DB instance class: db.t4g.medium
   - Storage: Encrypted (KMS)
   - Backup retention period: 7 days
   - Preferred backup window
   - Preferred maintenance window
   
6. Monitoring
   - CPU utilization
   - Database connections
   - Free storage space
   - Read/Write latency
   
7. Logs & events
   - Recent events の確認
   - Error log, Slow query log の有効化確認
```

**確認ポイント:**
- [ ] Clusterの状態が "Available" か
- [ ] Writer/Readerインスタンスが正常動作しているか
- [ ] 異なるAZに配置されているか（Multi-AZ）
- [ ] 暗号化が有効か（KMS使用）
- [ ] バックアップ設定が適切か
- [ ] Enhanced Monitoring が有効か
- [ ] Parameter Group が適切に設定されているか

**AWS CLI確認コマンド:**
```bash
# Cluster情報確認
aws rds describe-db-clusters \
  --db-cluster-identifier study-terraform-aurora-cluster

# インスタンス情報確認
aws rds describe-db-instances \
  --filters "Name=db-cluster-id,Values=study-terraform-aurora-cluster"

# エンドポイント確認
aws rds describe-db-clusters \
  --db-cluster-identifier study-terraform-aurora-cluster \
  --query 'DBClusters[0].[Endpoint,ReaderEndpoint,Port]'
```

**接続テスト（Bastionから）:**
```bash
# Bastion経由でRDS接続テスト
mysql -h <writer-endpoint> -u admin -p -e "SELECT VERSION();"
mysql -h <reader-endpoint> -u admin -p -e "SELECT @@hostname;"
```

---

#### 🔐 Security Groups

**マネジメントコンソール確認手順:**
```
1. EC2 Dashboard
   → Security Groups
   
2. 各Security Groupの確認

   【ALB Security Group】
   Inbound:
   - HTTP (80) from 0.0.0.0/0
   - HTTPS (443) from 0.0.0.0/0
   Outbound:
   - All traffic
   
   【Web Security Group】
   Inbound:
   - HTTP (80) from ALB Security Group
   - SSH (22) from Bastion Security Group
   Outbound:
   - All traffic
   
   【RDS Security Group】
   Inbound:
   - MySQL (3306) from Web Security Group
   Outbound:
   - All traffic
   
   【Bastion Security Group】
   Inbound:
   - SSH (22) from My IP (管理者IP)
   Outbound:
   - All traffic
```

**確認ポイント:**
- [ ] 最小権限の原則に従っているか
- [ ] 不要なポートが開いていないか
- [ ] Source/Destinationが適切に制限されているか
- [ ] RDSへの直接アクセスがブロックされているか

**AWS CLI確認コマンド:**
```bash
# Security Group一覧
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-xxxxx"

# 特定のSGルール確認
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=sg-xxxxx"
```

---

#### 🔑 IAM / Keys / KMS

**マネジメントコンソール確認手順:**
```
1. IAM Dashboard
   → Roles
   
2. Web EC2 Role確認
   - Attached policies:
     * AmazonSSMManagedInstanceCore
     * CloudWatchAgentServerPolicy
   - Trust relationships: ec2.amazonaws.com
   
3. RDS Monitoring Role確認
   - Attached policy:
     * AmazonRDSEnhancedMonitoringRole
   - Trust relationships: monitoring.rds.amazonaws.com
   
4. EC2 Dashboard
   → Key Pairs
   - Bastion用のKey Pairが存在するか
   
5. KMS Dashboard
   → Customer managed keys
   - RDS暗号化用のKMSキー
   - Key state: Enabled
   - Key policy の確認
```

**確認ポイント:**
- [ ] EC2にIAM Roleが適切にアタッチされているか
- [ ] SSM Session Managerでアクセス可能か
- [ ] KMSキーが有効化されているか
- [ ] Key Pairが安全に管理されているか

---

#### 📊 CloudWatch Monitoring

**マネジメントコンソール確認手順:**
```
1. CloudWatch Dashboard
   → Metrics → All metrics
   
2. EC2メトリクス
   - CPUUtilization
   - NetworkIn/Out
   - StatusCheckFailed
   
3. RDSメトリクス
   - CPUUtilization
   - DatabaseConnections
   - ReadLatency / WriteLatency
   - FreeableMemory
   
4. ALBメトリクス
   - RequestCount
   - TargetResponseTime
   - HealthyHostCount / UnHealthyHostCount
   - HTTPCode_Target_2XX_Count
   
5. Alarms
   - 設定されているアラームの確認
   - アラーム状態: OK / ALARM / INSUFFICIENT_DATA
   
6. Logs
   - Log groups の確認
   - /aws/ec2/instance-id
   - /aws/rds/cluster-name
```

**確認ポイント:**
- [ ] 各リソースのメトリクスが正常に収集されているか
- [ ] 異常な値がないか（CPU高騰、接続数異常など）
- [ ] アラームが適切に設定されているか

---

#### 💰 Cost Explorer / Billing

**マネジメントコンソール確認手順:**
```
1. Billing Dashboard
   → Cost Explorer
   
2. 現在月の費用確認
   - Service別コスト
     * EC2 (インスタンス + EBS)
     * RDS (Aurora)
     * Data Transfer
     * NAT Gateway
     * ELB
   
3. 前月との比較
   - 今回の変更による増減確認
   
4. Cost Allocation Tags
   - Terraform管理リソースのタグ確認
```

**確認ポイント:**
- [ ] 想定コスト内に収まっているか
- [ ] 不要なリソースが残っていないか
- [ ] タグ付けが適切か（コスト配分用）

---

## 🎯 実務運用フロー例

### パターン1: スケールアウト（今回のケース）
```
1. 事前準備
   □ 変更申請書の作成
   □ 影響範囲の確認
   □ ロールバックプランの作成
   
2. 変更作業（メンテナンスウィンドウ内）
   □ terraform plan の実行・レビュー
   □ 承認者の確認
   □ terraform apply の実行
   □ リソース起動待ち（5-10分）
   
3. 動作確認
   □ ASGのDesired Capacity確認
   □ EC2インスタンス起動確認（3台）
   □ ALB Target Health確認（3台全てHealthy）
   □ 疎通確認（curl でアクセステスト）
   □ 負荷分散動作確認
   □ CloudWatchメトリクス確認
   
4. 事後確認
   □ 30分～1時間の監視
   □ エラーログの確認
   □ パフォーマンスメトリクス確認
   □ 作業報告書の作成
```

### パターン2: DB設定変更
```
1. 事前準備
   □ Parameter変更内容の確認
   □ 再起動の必要性確認（static/dynamic parameter）
   □ スナップショット取得
   
2. 変更作業
   □ terraform apply
   □ Parameter適用（動的パラメータは即時、静的パラメータは再起動必要）
   
3. 動作確認
   □ DB接続確認
   □ パラメータ値の確認
   □ スロークエリログ確認
   □ アプリケーション動作確認
```

---

## 🚨 トラブルシューティング観点

### EC2インスタンスが起動しない
```
確認箇所:
□ Auto Scaling Activity history
□ EC2 System log
□ User data スクリプトエラー
□ IAM Role のアタッチミス
□ Security Group のアウトバウンドルール
□ Subnet の IP枯渇
```

### ALB Target が Unhealthy
```
確認箇所:
□ Target Group のHealth check設定
□ EC2のWebサーバー起動状態
□ Security Group（ALB → EC2）
□ Health check path が正しいか
□ ネットワークACL設定
```

### RDSに接続できない
```
確認箇所:
□ Security Group（Web → RDS）
□ Subnet Group の設定
□ RDS の Public Access設定（無効であるべき）
□ Endpoint の正誤
□ 認証情報の確認
□ DB起動状態
```

### NAT Gatewayが動作しない
```
確認箇所:
□ NAT GW の状態（Available）
□ Elastic IP の関連付け
□ Route Table の設定（Private → NAT GW）
□ Network ACL
```

---

## 📝 実践的な確認手順（初心者向け）

### ステップ1: マネジメントコンソール全体確認
```
1. AWSマネジメントコンソールにログイン
2. リージョンが "Tokyo (ap-northeast-1)" になっているか確認
3. 画面右上のリージョン選択をチェック！
```

### ステップ2: VPCの確認（基盤確認）
```
サービス検索 → "VPC" と入力

1. 左メニュー "Your VPCs" をクリック
   → "study-terraform-vpc" が存在するか
   
2. 左メニュー "Subnets" をクリック
   → 6つのサブネットが存在するか確認
   → Name tag で判別: public-a, public-c, private-a, private-c, rds-a, rds-c
   
3. 左メニュー "Route Tables" をクリック
   → Public route: 0.0.0.0/0 → igw-xxxxx
   → Private route: 0.0.0.0/0 → nat-xxxxx
   
4. 左メニュー "NAT Gateways" をクリック
   → 2つのNAT Gateway の State が "Available"
```

### ステップ3: EC2/ASGの確認（アプリケーション層）
```
サービス検索 → "EC2" と入力

1. 左メニュー "Instances" をクリック
   → "study-terraform-bastion-a/c" (2台)
   → ASG配下のインスタンス (3台) ← 今回の変更で増えた
   → 合計5台が "running" 状態か
   
2. 左メニュー "Auto Scaling Groups" をクリック
   → "study-web-asg..." をクリック
   → 画面下部の詳細を確認:
     * Desired capacity: 3
     * Current capacity: 3
     * Min: 1, Max: 6
   
3. "Activity" タブをクリック
   → スケールアウトのActivity履歴を確認
   → "Launching a new EC2 instance" が2件あるはず
   
4. "Instance management" タブをクリック
   → 3台のインスタンスが一覧表示
   → Lifecycle: InService
   → Health status: Healthy
```

### ステップ4: ALBの確認（負荷分散確認）
```
EC2画面のまま

1. 左メニュー "Load Balancers" をクリック
   → "study-alb" をクリック
   → State: active を確認
   → DNS name をコピー
   
2. "Listeners" タブをクリック
   → HTTP:80 が設定されているか
   
3. "Target groups" リンクをクリック
   → "study-alb-target-group" をクリック
   → "Targets" タブを確認
   → Registered targets: 3
   → Health status: 3 healthy (緑色) ← 重要！
   
   ※ unhealthy の場合は、ヘルスチェック完了まで待つ（2-3分）
```

### ステップ5: RDSの確認（データベース層）
```
サービス検索 → "RDS" と入力

1. 左メニュー "Databases" をクリック
   → "study-terraform-aurora-cluster" をクリック
   
2. Cluster情報確認
   → Status: Available
   → Region & AZ: Multi-AZ (青いバッジ)
   → Engine: Aurora MySQL 8.0
   
3. スクロールして "Connectivity & security" セクション
   → Writer endpoint をメモ
   → Reader endpoint をメモ
   → ポート: 3306
   
4. "Configuration" タブをクリック
   → DB instance class: db.t4g.medium
   → Storage encrypted: Yes
   
5. "Monitoring" タブをクリック
   → CPU, Connections, Latency のグラフを確認
```

### ステップ6: セキュリティの確認
```
EC2画面に戻る

1. 左メニュー "Security Groups" をクリック

2. "study-terraform-alb-sg" を検索
   → Inbound rules: 80, 443 from 0.0.0.0/0
   
3. "study-terraform-web-sg" を検索
   → Inbound rules: 
     * 80 from ALB-SG
     * 22 from Bastion-SG
   
4. "study-terraform-rds-sg" を検索
   → Inbound rules: 3306 from Web-SG
   → ソースに "0.0.0.0/0" が無いことを確認！
```

### ステップ7: 動作確認（実際にアクセス）
```
ターミナルで実行:

# ALBのDNS名にアクセス（ステップ4でコピーしたもの）
curl http://study-alb-xxxxxxxxxx.ap-northeast-1.elb.amazonaws.com

# 正常ならHTMLが返る
# エラーの場合は Target Health を再確認

# 負荷分散確認（10回アクセスしてインスタンスIDが変わるか確認）
for i in {1..10}; do 
  curl -s http://study-alb-xxxxxxxxxx.ap-northeast-1.elb.amazonaws.com | grep -o "instance-id-[^<]*"
  sleep 1
done
```

### ステップ8: CloudWatch確認（監視）
```
サービス検索 → "CloudWatch" と入力

1. 左メニュー "Metrics" → "All metrics" をクリック

2. "EC2" をクリック → "Per-Instance Metrics"
   → ASGの3つのインスタンスを選択
   → "CPUUtilization" にチェック
   → グラフ表示される
   
3. "ApplicationELB" をクリック → "Per AppELB Metrics"
   → "RequestCount" を選択
   → トラフィック状況を確認
   
4. 左メニュー "Logs" → "Log groups" をクリック
   → ログが出力されているか確認
```

---

## 📚 実務でよく使う AWS CLI コマンド集

```bash
# ========================================
# Auto Scaling Group
# ========================================

# ASG一覧
aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[*].[AutoScalingGroupName,DesiredCapacity,MinSize,MaxSize]' \
  --output table

# 特定ASGの詳細
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names study-web-asg \
  --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,Desired:DesiredCapacity,Min:MinSize,Max:MaxSize,Health:HealthCheckType}' \
  --output table

# ASG Activity履歴
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name study-web-asg \
  --max-records 10 \
  --query 'Activities[*].[StartTime,Description,StatusCode]' \
  --output table

# ========================================
# EC2 Instances
# ========================================

# 特定タグでフィルタ
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=study-terraform*" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# ASG配下のインスタンス
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=study-web-asg*" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Placement.AvailabilityZone]' \
  --output table

# ========================================
# Load Balancer
# ========================================

# ALB一覧
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code,DNSName]' \
  --output table

# Target Health確認
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups --names study-alb-target-group --query 'TargetGroups[0].TargetGroupArn' --output text) \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,Target.AvailabilityZone]' \
  --output table

# ========================================
# RDS Aurora
# ========================================

# Cluster情報
aws rds describe-db-clusters \
  --db-cluster-identifier study-terraform-aurora-cluster \
  --query 'DBClusters[0].{Endpoint:Endpoint,Reader:ReaderEndpoint,Status:Status,MultiAZ:MultiAZ,Engine:Engine}' \
  --output table

# Instance情報
aws rds describe-db-instances \
  --filters "Name=db-cluster-id,Values=study-terraform-aurora-cluster" \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,AvailabilityZone,DBInstanceStatus]' \
  --output table

# ========================================
# CloudWatch Metrics
# ========================================

# ASGのCPU使用率（過去1時間の平均）
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=study-web-asg \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --output table

# RDSのコネクション数
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBClusterIdentifier,Value=study-terraform-aurora-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --output table
```

---

## 🎓 学習のステップ

### Phase 1: マネジメントコンソールに慣れる（今ここ！）
1. 上記の「ステップ1〜8」を実際に操作
2. 各サービスの画面構成を把握
3. どこに何があるか覚える

### Phase 2: AWS CLI に慣れる
1. 上記のCLIコマンドを実行してみる
2. `--query` の使い方を学ぶ（JMESPath）
3. スクリプト化して自動化

### Phase 3: 運用タスクの実践
1. ASGのスケール変更
2. RDSのパラメータ変更
3. Security Groupのルール追加
4. CloudWatchアラームの設定

### Phase 4: トラブルシューティング
1. 意図的にエラーを起こしてみる
2. ログから原因を特定
3. 修正して復旧

---

## ✅ 今すぐできる確認アクション

```bash
# 1. マネジメントコンソールで以下を開く
# - EC2 > Auto Scaling Groups > study-web-asg
#   → Desired: 3, Current: 3 を確認
# - EC2 > Target Groups > study-alb-target-group
#   → Healthy targets: 3 を確認
# - RDS > Databases > study-terraform-aurora-cluster
#   → Status: Available を確認

# 2. ターミナルで動作確認
# ALBのDNS名を取得
aws elbv2 describe-load-balancers \
  --names study-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# 上記で得たDNS名にアクセス
curl http://<ALB-DNS-NAME>

# 3. CloudWatchでメトリクス確認
# マネジメントコンソール > CloudWatch > Metrics
# → EC2 > Auto Scaling Group Metrics
# → CPUUtilization を確認
```

---

この確認リストを使って、まずは**ステップ1〜8のマネジメントコンソール確認**を実際に操作してみてください！
画面を見ながら「あ、ここにこの情報があるんだ」という感覚を掴むのが最初のステップです 💪
