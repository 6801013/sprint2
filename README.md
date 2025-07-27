# スプリント2：AWS環境構築（Terraform）

このリポジトリは、スプリント2で作成したTerraformコードをまとめたものです。
AWS上にWebサーバ、APIサーバ及びdbサーバを構築するインフラ構成を定義しています。
また、IAMユーザとIAMグループも定義しました。

## 構成概要

- Terraformを使用して以下を構築：
- Amazon LinuxベースのWebサーバ
- Amazon LinuxベースのAPIサーバ
‐ RDSのdbサーバ
- 4つのIAMユーザと3つのIAMグループ
- サーバの構築後、Tera Termを用いてそれぞれにSSHログインし、セットアップを実施

## 使用技術

- Terraform
- AWS（EC2, VPC など）
- Tera Term（サーバ設定用のSSHクライアント）

## Webサーバ／APIサーバ／dbサーバの中身

各サーバ内のミドルウェアや設定は、Tera Term経由で個別に設定しています。
