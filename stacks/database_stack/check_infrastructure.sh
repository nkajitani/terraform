#!/bin/bash

# Infrastructure Check Script
# 実務でよく使う確認コマンド集

set -e

echo "=========================================="
echo "  AWS Infrastructure Check"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Auto Scaling Group
echo -e "${BLUE}[1] Auto Scaling Group Status${NC}"
aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `study-web-asg`)].{Name:AutoScalingGroupName,Desired:DesiredCapacity,Current:Instances|length(@),Min:MinSize,Max:MaxSize}' \
  --output table
echo ""

# 2. EC2 Instances
echo -e "${BLUE}[2] EC2 Instances (ASG)${NC}"
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=study-web-asg*" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,Placement.AvailabilityZone]' \
  --output table
echo ""

# 3. Load Balancer
echo -e "${BLUE}[3] Application Load Balancer${NC}"
aws elbv2 describe-load-balancers \
  --names study-alb \
  --query 'LoadBalancers[0].{Name:LoadBalancerName,State:State.Code,DNS:DNSName}' \
  --output table
echo ""

# 4. Target Health
echo -e "${BLUE}[4] Target Group Health Status${NC}"
TG_ARN=$(aws elbv2 describe-target-groups --names study-alb-target-group --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,Target.AvailabilityZone]' \
  --output table
echo ""

# 5. RDS Aurora Cluster
echo -e "${BLUE}[5] RDS Aurora Cluster${NC}"
aws rds describe-db-clusters \
  --db-cluster-identifier study-terraform-aurora-cluster \
  --query 'DBClusters[0].{Status:Status,MultiAZ:MultiAZ,Engine:Engine,Endpoint:Endpoint,ReaderEndpoint:ReaderEndpoint}' \
  --output table
echo ""

# 6. RDS Instances
echo -e "${BLUE}[6] RDS Aurora Instances${NC}"
aws rds describe-db-instances \
  --filters "Name=db-cluster-id,Values=study-terraform-aurora-cluster" \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,AvailabilityZone,DBInstanceStatus]' \
  --output table
echo ""

# 7. NAT Gateways
echo -e "${BLUE}[7] NAT Gateways${NC}"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=study-terraform-vpc" --query 'Vpcs[0].VpcId' --output text)
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table
echo ""

# 8. ALB DNS Name
echo -e "${BLUE}[8] ALB Access URL${NC}"
ALB_DNS=$(aws elbv2 describe-load-balancers --names study-alb --query 'LoadBalancers[0].DNSName' --output text)
echo -e "${GREEN}http://${ALB_DNS}${NC}"
echo ""

# 9. Quick Health Check
echo -e "${BLUE}[9] Quick Health Check${NC}"
echo "Testing ALB endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${ALB_DNS})
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ ALB is responding (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${YELLOW}⚠ ALB returned HTTP $HTTP_CODE${NC}"
fi
echo ""

echo -e "${GREEN}=========================================="
echo "  Check Complete!"
echo "==========================================${NC}"
