# 胰岛素APP — 新功能实施计划

> **目标：** 增加患者基本信息编辑/查看页面、血糖测量提醒、食物拍照识别三大功能

**架构：** 基于现有代码扩展，保持 MVVM 模式（Model 在 models.dart，DB 在 local_db.dart，AppState 做通知）。通知使用 flutter_local_notifications，拍照识别使用 image_picker + http 调用免费 OCR/识别API。

**Tech Stack:** Flutter + sqflite + flutter_local_notifications + image_picker

---

### Task 1: 扩展数据模型 — 添加患者信息字段

**Objective:** 在 UserConfig 模型中增加个人信息字段（姓名、年龄、糖尿病类型、诊断时间、HbA1c、用药方案）

**Files:**
- Modify: `lib/models/models.dart` — 添加字段和默认值
- Modify: `lib/database/local_db.dart` — 扩展 user_config 表 migration

**Step 1: 修改 UserConfig 模型**

在 `lib/models/models.dart` 中，给 `UserConfig` 增加字段：

```dart
class UserConfig {
  // 原有字段
  double targetGlucoseMin;
  double targetGlucoseMax;
  double isf;
  double icr;
  InsulinType insulinType;
  int iobDurationHours;
  double maxDosePerInjection;

  // 新增患者信息字段
  String patientName;
  int age;
  int diabetesType; // 1=1型, 2=2型
  DateTime? diagnosisDate;
  double? hba1c; // 糖化血红蛋白 (%)
  String medicationRegimen; // 用药方案描述

  UserConfig({
    // ...原有默认值...
    this.patientName = '',
    this.age = 30,
    this.diabetesType = 1,
    this.diagnosisDate,
    this.hba1c,
    this.medicationRegimen = '每日多次注射（MDI）',
  });
}
```

**Step 2: 数据库迁移**

创建 `local_db.dart` 的 migration 逻辑，检测旧表并增加新列。

---

### Task 2: 创建患者信息页面 (PatientProfilePage)

**Objective:** 一个表单页面，查看和编辑所有患者治疗相关信息

**Files:**
- Create: `lib/pages/patient_profile_page.dart`

**页面要素：**
- 头像占位 + 姓名 (TextField)
- 年龄 (数字输入)
- 糖尿病类型 (1型/2型 切换)
- 诊断日期 (日期选择器)
- 胰岛素敏感度 ISF (可编辑)
- 碳水系数 ICR (可编辑)
- 目标血糖范围 (下限/上限)
- 糖化血红蛋白 HbA1c (可编辑)
- 用药方案 (下拉或文本)
- 保存按钮

---

### Task 3: 添加本地通知提醒功能

**Objective:** 添加 flutter_local_notifications 依赖，实现定时血糖测量提醒

**Files:**
- Modify: `pubspec.yaml` — 添加 flutter_local_notifications
- Create: `lib/utils/notification_service.dart` — 通知服务封装
- Modify: `lib/pages/settings_page.dart` — 提醒时间段设置 UI
- Modify: `lib/main.dart` — 初始化通知

**提醒时间段：**
- 早餐前 (7:00)
- 午餐前 (11:30)
- 晚餐前 (17:30)
- 睡前 (21:00)
- 自定义

---

### Task 4: 食物拍照识别功能

**Objective:** 用 image_picker 拍照/选图，调用免费 API 识别食物并估算碳水

**Files:**
- Create: `lib/utils/food_recognizer.dart` — 食物识别服务
- Modify: `lib/pages/food_picker_page.dart` — 添加拍照按钮入口
- Or Create: `lib/pages/camera_food_page.dart` — 独立的拍照识别页面

**识别流程：**
1. 用户拍照或从相册选图
2. 调用免费识别API（如 Google Gemini API /或本地 base64 调用 OpenAI vision）
3. 解析返回的食物名称和估算份量
4. 从本地碳水库匹配或提示用户手动输入
5. 自动填入碳水值返回计算器

---

### Task 5: 集成到导航和主页面

**Objective:** 将患者信息页面接入导航，在首页显示患者概览入口

**Files:**
- Modify: `lib/pages/home_page.dart` — 在 AppBar 添加个人信息入口
- Modify: `lib/main.dart` — 注册路由

---

### Task 6: 编译测试

**Objective:** 确认所有代码无语法错误，可以正常编译

**Files:**
- CI: `.github/workflows/build-apk.yml` — 已在
