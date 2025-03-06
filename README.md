# AR寻宝游戏 (AR Treasure Hunt Game)

## 项目介绍

这是一个基于Flutter和AR技术开发的移动应用，允许用户在增强现实环境中放置和寻找虚拟礼物。应用利用AR Flutter Plugin实现AR功能，为用户提供沉浸式的寻宝体验。

## 主要功能

### 1. 放置礼物
- 用户可以在现实环境中的平面上放置虚拟礼物
- 支持多种礼物模型（礼物盒、宝箱、寶劍）
- 可以添加、删除和切换不同的礼物模型

### 2. 寻找礼物
- 用户可以在AR环境中寻找预先放置的礼物
- 可以选择要寻找的礼物类型
- 找到礼物后可以标记为已收集

## 技术栈

- **Flutter**: 跨平台UI框架
- **AR Flutter Plugin**: 提供AR功能支持
- **Permission Handler**: 处理相机和位置权限
- **Camera**: 提供相机功能支持
- **Path Provider**: 文件路径管理

## 安装指南

### 前提条件
- Flutter SDK (^3.7.0)
- Dart SDK
- Android Studio / Xcode
- 支持ARCore的Android设备或支持ARKit的iOS设备

### 安装步骤

1. 克隆项目仓库
```bash
git clone <repository-url>
cd XunBaoDemo/xunbao_app
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 使用说明

### 放置礼物
1. 在主屏幕点击「放置礼物」按钮
2. 允许应用访问相机和位置权限
3. 将相机对准平面，等待AR系统识别平面
4. 点击屏幕上的平面位置放置礼物
5. 使用底部按钮添加更多礼物、删除礼物或切换礼物模型

### 寻找礼物
1. 在主屏幕点击「寻找礼物」按钮
2. 在底部选择要寻找的礼物类型
3. 点击右下角的开始按钮开始寻宝
4. 在AR环境中移动，寻找放置的礼物
5. 找到礼物后，可以标记为已收集

## 项目结构

```
lib/
├── main.dart              # 应用入口点
└── screens/
    ├── home_screen.dart    # 主屏幕
    ├── place_gift_screen.dart  # 放置礼物界面
    └── find_gift_screen.dart   # 寻找礼物界面
```

## 权限要求

应用需要以下权限：
- 相机权限：用于AR功能
- 位置权限：用于AR定位

## 注意事项

- 应用需要在光线充足的环境中使用，以便AR系统能够准确识别平面
- 首次使用时，AR系统可能需要一些时间来识别周围环境
- 应用性能可能受设备硬件规格影响

## 未来计划

- 添加多人模式，允许多个用户共同寻宝
- 增加礼物自定义功能
- 添加计分系统和排行榜
- 优化AR识别性能

## 贡献指南

欢迎贡献代码、报告问题或提出新功能建议。请遵循以下步骤：

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request
