# GluCare — 用药提醒 + 开药提醒 + 病情总结 + 推荐食谱 + 采购清单 + 发送医生

## Overview
在现有代码基础上增加三大功能模块：
1. **用药管理** — 用药方案配置、按时提醒、开药提醒
2. **病情总结与推荐** — 病情总结报告、用药方案调整建议、每周食谱推荐、采购清单
3. **发送给医生** — 生成报告并跳转微信/短信分享

## 阶段一：用药管理与提醒

### 新模型 (models.dart 新增)
- `Medication`: 药品信息（名称、剂量、单位、频率、服用时间列表）
- `MedicationLog`: 用药记录（medicationId, timestamp, status: taken/skipped/missed）

### 新数据库表 (local_db 新增 v5 migration)
- `medications` 表 — 用户配置的药品
- `medication_logs` 表 — 用药打卡记录

### 新文件
- `lib/pages/medication_page.dart` — 用药管理主页面
- `lib/pages/medication_form_page.dart` — 新增/编辑药品表单
- `lib/utils/medication_notifier.dart` — 用药提醒业务逻辑

### 通知扩展
- NotificationService 增加用药提醒通道 `medication_reminder`
- 按每个药品的服用时间点分别调度每日通知

### 开药提醒逻辑
- 检测血糖数据：空腹>7.0 或 餐后>10.0 连续3天 → 提醒联系医生调药
- 药品到期/库存提醒（后续迭代）

## 阶段二：病情总结 + 食谱推荐 + 采购清单

### 新文件
- `lib/pages/health_report_page.dart` — 病情总结页面
- `lib/utils/report_generator.dart` — 报告生成逻辑
- `lib/utils/meal_planner.dart` — 食谱推荐引擎
- `lib/pages/meal_plan_page.dart` — 每周食谱展示页面
- `lib/pages/shopping_list_page.dart` — 采购清单页面

### 病情总结
- 从近7/14/30天数据生成：血糖均值/TIR/低血糖次数/用药统计
- 自然语言描述趋势和建议
- 用药方案调整建议（基于血糖规律）

### 食谱推荐
- 基于近7天饮食记录 + 血糖趋势 + 用药方案
- 输出周一到周日每日三餐+加餐
- 每道菜标注碳水、热量、推荐时间段

### 采购清单
- 每周五自动汇总食谱中所需食材
- 按分类汇总（蔬菜、肉类、调味品、主食等）
- 提供"跳转App购买"入口（用户选平台）

## 阶段三：发送给医生

### 实现方式
- 生成图文报告（或纯文本/PDF）
- 使用 `share_plus` 分享到微信/短信/其他App
- 或通过 URL Scheme 跳转微信

## 导航调整
- 底部Tab从5个调整为6个（增加"用药"Tab）或作为二级页面从推荐/设置进入
- 建议：底部Tab改为：记录 | 计算器 | CGM | **用药** | 推荐 | 报告
