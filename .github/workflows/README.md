# GitHub Actions Workflows

本项目包含以下 GitHub Actions workflows：

## 📦 Build and Release (`build-and-release.yml`)

**触发条件：**
- 推送以 `v` 开头的 tag（例如：`v1.0.0`）
- 手动触发（workflow_dispatch）

**功能：**
- 自动构建 macOS 应用
- 创建 DMG 安装包
- 自动创建 GitHub Release
- 上传 DMG 文件到 Release

**使用方法：**

### 方式一：通过 Git Tag 发布

```bash
# 1. 更新版本号
git tag v2.1.0

# 2. 推送 tag
git push origin v2.1.0
```

推送 tag 后，GitHub Actions 会自动：
- 构建应用
- 创建 Release
- 上传 DMG 文件

### 方式二：手动触发

1. 前往 GitHub 仓库的 Actions 页面
2. 选择 "Build and Release" workflow
3. 点击 "Run workflow"
4. 输入版本号（例如：2.1.0）
5. 点击 "Run workflow"

## 🔨 Build (`build.yml`)

**触发条件：**
- 推送到 `main`、`master` 或 `develop` 分支
- 创建 Pull Request

**功能：**
- 自动构建应用
- 生成 DMG 文件
- 上传构建产物作为 artifact（保留 7 天）

**用途：**
- 验证代码可以正常构建
- 为 PR 提供测试用的构建版本

## 📝 注意事项

1. **版本号格式**：建议使用语义化版本号（Semantic Versioning），例如：`1.0.0`、`1.1.0`、`2.0.0`
2. **Tag 格式**：Release workflow 需要以 `v` 开头的 tag，例如：`v1.0.0`
3. **构建时间**：macOS runner 构建通常需要 5-10 分钟
4. **Artifact 保留**：
   - Release 构建：保留 30 天
   - 普通构建：保留 7 天

## 🔧 自定义配置

如果需要修改构建配置，可以编辑对应的 workflow 文件：
- `.github/workflows/build-and-release.yml` - Release 构建
- `.github/workflows/build.yml` - 普通构建
