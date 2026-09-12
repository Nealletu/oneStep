## OneStep Action 1.0.0

原生 macOS 菜单栏全局快捷键工具。

### 动作
- 锁定屏幕
- 打开 App
- 打开 URL
- Shell 命令

### 系统要求
- Apple Silicon（arm64）
- macOS 26.0+
- 首次使用需授予「辅助功能」权限

### 安装
1. 下载 `OneStep-Action-1.0.0.zip` 或 `.dmg`
2. 解压/挂载后将 `OneStep Action.app` 拖入「应用程序」
3. 首次打开：系统设置 → 隐私与安全性 → 辅助功能 → 勾选 OneStep Action

### 校验
```bash
lipo -info "/Applications/OneStep Action.app/Contents/MacOS/OneStep Action"
# Non-fat file: ... is architecture: arm64
```
