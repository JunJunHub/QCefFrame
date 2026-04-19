# Buildroot 集成说明

本目录包含 QCefView 与 Buildroot 集成所需的配置文件和脚本。

## 文件说明

| 文件 | 说明 |
|------|------|
| `setup-buildroot-env.sh` | 环境设置脚本，检测并配置 Buildroot 工具链 |
| `qceframe-config.in` | Buildroot 配置片段，用于启用 Qt6 和相关依赖 |
| `package/qceframe/` | QCefFrame 的 Buildroot 包定义 |

## 使用方式

### 方式一：作为 Buildroot 外部包

```bash
# 1. 设置环境变量
source tools/buildroot/setup-buildroot-env.sh /path/to/buildroot

# 2. 构建项目
./generate-linux-arm64.sh
```

### 方式二：集成到 Buildroot

将本目录内容复制到 Buildroot 项目中，然后：

```bash
# 在 Buildroot 根目录
make menuconfig
# 选择 Package -> Graphics -> qceframe
```

## 支持的目标平台

- Linux ARM64 (aarch64)
- 典型硬件: RK3568, RK3399, i.MX8 等
