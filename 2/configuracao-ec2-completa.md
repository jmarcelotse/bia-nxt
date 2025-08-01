# Configuração Completa das Instâncias EC2

## Resumo das Instâncias Ativas

### 1. Instância bia-dev (i-0ebcff8cd132bec14)
- **Status**: Running
- **Tipo**: t3.micro
- **IP Público**: 34.229.224.0
- **IP Privado**: 172.31.36.238

### 2. Instância WordPress (i-04aff97b4207875d7)
- **Status**: Running
- **Tipo**: t3.micro
- **IP Público**: 3.86.183.162
- **IP Privado**: 172.31.93.216

---

## Instância 1: bia-dev (i-0ebcff8cd132bec14)

### Informações Básicas
- **Instance ID**: i-0ebcff8cd132bec14
- **Nome**: bia-dev
- **Tipo**: t3.micro
- **Arquitetura**: x86_64
- **Plataforma**: Linux/UNIX
- **AMI ID**: ami-08a6efd148b1f7504
- **Launch Time**: 2025-07-30T23:25:58+00:00
- **Estado**: running

### Configuração de Rede
- **VPC ID**: vpc-03c4e823f9cde5442
- **Subnet ID**: subnet-0e6f30f43f6727830
- **Availability Zone**: us-east-1c
- **IP Privado**: 172.31.36.238
- **IP Público**: 34.229.224.0
- **DNS Público**: ec2-34-229-224-0.compute-1.amazonaws.com
- **DNS Privado**: ip-172-31-36-238.ec2.internal

### Security Group
- **Group ID**: sg-0285d77448b0e2f50
- **Nome**: bia-dev
- **Descrição**: acesso do bia-dev

#### Regras de Entrada (Inbound)
- **Porta 3001**: TCP, 0.0.0.0/0 (liberado para o mundo)
- **Porta 3002**: TCP, 0.0.0.0/0 (liberado para o mundo)

#### Regras de Saída (Outbound)
- **Todas as portas**: Todos os protocolos, 0.0.0.0/0

### Armazenamento
- **Volume ID**: vol-03cdd4393d434b976
- **Tipo**: gp3
- **Tamanho**: 15 GB
- **IOPS**: 3000
- **Throughput**: 125 MB/s
- **Device**: /dev/xvda
- **Delete on Termination**: true
- **Encrypted**: false

### IAM Instance Profile
- **ARN**: arn:aws:iam::873976611862:instance-profile/role-acesso-ssm
- **ID**: AIPA4W7IQYQLF6RWTQ4RP

### Configurações Adicionais
- **EBS Optimized**: true
- **ENA Support**: true
- **Monitoring**: disabled
- **Source/Dest Check**: true
- **Tenancy**: default
- **Virtualization Type**: hvm
- **Boot Mode**: uefi
- **CPU Options**: 1 core, 2 threads per core

### Metadata Options
- **State**: applied
- **HTTP Tokens**: required
- **HTTP Put Response Hop Limit**: 2
- **HTTP Endpoint**: enabled
- **HTTP Protocol IPv6**: disabled
- **Instance Metadata Tags**: disabled

---

## Instância 2: WordPress (i-04aff97b4207875d7)

### Informações Básicas
- **Instance ID**: i-04aff97b4207875d7
- **Nome**: asg-cluster-lab-especial-wordpress
- **Tipo**: t3.micro
- **Arquitetura**: x86_64
- **Plataforma**: Linux/UNIX
- **AMI ID**: ami-0c58430228056d84e
- **Launch Time**: 2025-07-30T23:52:23+00:00
- **Estado**: running
- **Key Name**: nxt-linux

### Tags
- **Environment**: Sandbox
- **Project**: WordPress-Lab
- **AmazonECSManaged**: (vazio)
- **aws:autoscaling:groupName**: asg-cluster-lab-especial-wordpress
- **aws:ec2launchtemplate:id**: lt-0e040341212f1cc13
- **aws:ec2launchtemplate:version**: 1

### Configuração de Rede
- **VPC ID**: vpc-03c4e823f9cde5442
- **Subnet ID**: subnet-08efca2de6c4fa678
- **Availability Zone**: us-east-1a
- **IP Privado**: 172.31.93.216
- **IP Público**: 3.86.183.162
- **DNS Público**: ec2-3-86-183-162.compute-1.amazonaws.com
- **DNS Privado**: ip-172-31-93-216.ec2.internal

### Security Group
- **Group ID**: sg-0b7a0f40247751ffd
- **Nome**: wordpress-ec2
- **Descrição**: Security group for WordPress EC2 instances

#### Regras de Entrada (Inbound)
- **Todas as portas TCP (0-65535)**: Acesso apenas do Security Group sg-0dfa8423087a3d8e1

#### Regras de Saída (Outbound)
- **Todas as portas**: Todos os protocolos, 0.0.0.0/0

### Armazenamento
- **Volume ID**: vol-08e875d98684f1b18
- **Tipo**: gp2
- **Tamanho**: 30 GB
- **IOPS**: 100
- **Device**: /dev/xvda
- **Delete on Termination**: true
- **Encrypted**: false

### IAM Instance Profile
- **ARN**: arn:aws:iam::873976611862:instance-profile/ecs-wordpress-instance-role
- **ID**: AIPA4W7IQYQLPLUPUWJDG

### Configurações Adicionais
- **EBS Optimized**: false
- **ENA Support**: true
- **Monitoring**: disabled
- **Source/Dest Check**: true
- **Tenancy**: default
- **Virtualization Type**: hvm
- **Boot Mode**: legacy-bios
- **CPU Options**: 1 core, 2 threads per core

### Metadata Options
- **State**: applied
- **HTTP Tokens**: optional
- **HTTP Put Response Hop Limit**: 1
- **HTTP Endpoint**: enabled
- **HTTP Protocol IPv6**: disabled
- **Instance Metadata Tags**: disabled

---

## VPC (vpc-03c4e823f9cde5442)

### Informações da VPC
- **VPC ID**: vpc-03c4e823f9cde5442
- **CIDR Block**: 172.31.0.0/16
- **Estado**: available
- **Default VPC**: true
- **Instance Tenancy**: default
- **DHCP Options ID**: dopt-06a0b23b5e770f76d
- **Owner ID**: 873976611862

### Block Public Access States
- **Internet Gateway Block Mode**: off

---

## Subnets

### Subnet 1 (subnet-0e6f30f43f6727830) - bia-dev
- **Subnet ID**: subnet-0e6f30f43f6727830
- **VPC ID**: vpc-03c4e823f9cde5442
- **CIDR Block**: 172.31.32.0/20
- **Availability Zone**: us-east-1c
- **Availability Zone ID**: use1-az6
- **Estado**: available
- **Available IP Addresses**: 4090
- **Default for AZ**: true
- **Map Public IP on Launch**: true

### Subnet 2 (subnet-08efca2de6c4fa678) - WordPress
- **Subnet ID**: subnet-08efca2de6c4fa678
- **VPC ID**: vpc-03c4e823f9cde5442
- **CIDR Block**: 172.31.80.0/20
- **Availability Zone**: us-east-1a
- **Availability Zone ID**: use1-az2
- **Estado**: available
- **Available IP Addresses**: 4090
- **Default for AZ**: true
- **Map Public IP on Launch**: true

---

## Security Groups Detalhados

### Security Group 1: bia-dev (sg-0285d77448b0e2f50)
- **Group ID**: sg-0285d77448b0e2f50
- **Nome**: bia-dev
- **Descrição**: acesso do bia-dev
- **VPC ID**: vpc-03c4e823f9cde5442
- **Owner ID**: 873976611862
- **ARN**: arn:aws:ec2:us-east-1:873976611862:security-group/sg-0285d77448b0e2f50

#### Tags
- **Name**: bia-dev
- **aws**: ia

#### Regras de Entrada (Inbound Rules)
| Protocolo | Porta | Origem | Descrição |
|-----------|-------|--------|-----------|
| TCP | 3001 | 0.0.0.0/0 | liberado para o mundo |
| TCP | 3002 | 0.0.0.0/0 | liberado para o mundo |

#### Regras de Saída (Outbound Rules)
| Protocolo | Porta | Destino | Descrição |
|-----------|-------|---------|-----------|
| All | All | 0.0.0.0/0 | Todas as conexões de saída |

### Security Group 2: wordpress-ec2 (sg-0b7a0f40247751ffd)
- **Group ID**: sg-0b7a0f40247751ffd
- **Nome**: wordpress-ec2
- **Descrição**: Security group for WordPress EC2 instances
- **VPC ID**: vpc-03c4e823f9cde5442
- **Owner ID**: 873976611862
- **ARN**: arn:aws:ec2:us-east-1:873976611862:security-group/sg-0b7a0f40247751ffd

#### Tags
- **Name**: wordpress-ec2

#### Regras de Entrada (Inbound Rules)
| Protocolo | Porta | Origem | Descrição |
|-----------|-------|--------|-----------|
| TCP | 0-65535 | sg-0dfa8423087a3d8e1 | Acesso de outro Security Group |

#### Regras de Saída (Outbound Rules)
| Protocolo | Porta | Destino | Descrição |
|-----------|-------|---------|-----------|
| All | All | 0.0.0.0/0 | Todas as conexões de saída |

---

## Volumes EBS

### Volume 1 (vol-03cdd4393d434b976) - bia-dev
- **Volume ID**: vol-03cdd4393d434b976
- **Tipo**: gp3
- **Tamanho**: 15 GB
- **IOPS**: 3000
- **Throughput**: 125 MB/s
- **Availability Zone**: us-east-1c
- **Estado**: in-use
- **Create Time**: 2025-07-29T00:00:01.819000+00:00
- **Snapshot ID**: snap-02887d3e50cfa18aa
- **Encrypted**: false
- **Multi-Attach**: false
- **Attached to**: i-0ebcff8cd132bec14 (/dev/xvda)
- **Delete on Termination**: true

### Volume 2 (vol-08e875d98684f1b18) - WordPress
- **Volume ID**: vol-08e875d98684f1b18
- **Tipo**: gp2
- **Tamanho**: 30 GB
- **IOPS**: 100
- **Availability Zone**: us-east-1a
- **Estado**: in-use
- **Create Time**: 2025-07-30T23:52:24.105000+00:00
- **Snapshot ID**: snap-06f0b8746b3dd9599
- **Encrypted**: false
- **Multi-Attach**: false
- **Attached to**: i-04aff97b4207875d7 (/dev/xvda)
- **Delete on Termination**: true

---

## Resumo da Arquitetura

### Conectividade
- Ambas as instâncias estão na mesma VPC (vpc-03c4e823f9cde5442)
- Instância bia-dev está na subnet us-east-1c
- Instância WordPress está na subnet us-east-1a
- Ambas têm IPs públicos e podem acessar a internet

### Segurança
- bia-dev: Acesso público nas portas 3001 e 3002
- WordPress: Acesso restrito apenas de outro Security Group específico
- Ambas têm acesso de saída irrestrito

### Armazenamento
- bia-dev: Volume gp3 de 15GB com alta performance (3000 IOPS)
- WordPress: Volume gp2 de 30GB com performance padrão (100 IOPS)

### IAM
- bia-dev: Profile para acesso SSM
- WordPress: Profile específico para ECS WordPress

---

*Documento gerado em: 2025-07-31 00:00:00 UTC*
*Região: us-east-1*
*Account ID: 873976611862*
