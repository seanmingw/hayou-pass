#!/bin/bash

# GitHub仓库设置和在线构建脚本
# 使用方法: ./setup_github.sh [repository-url]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info "🚀 GitHub仓库设置和在线构建配置"

# 检查Git是否安装
if ! command -v git &> /dev/null; then
    print_error "Git未安装，请先安装Git"
    print_info "安装命令: brew install git"
    exit 1
fi

# 检查是否在项目目录
if [[ ! -f "build.gradle" ]]; then
    print_error "请在BypassApp项目根目录运行此脚本"
    exit 1
fi

# 获取仓库URL
REPO_URL="$1"
if [[ -z "$REPO_URL" ]]; then
    echo
    print_info "请提供GitHub仓库URL，或按以下步骤创建："
    echo "1. 访问 https://github.com/new"
    echo "2. 创建新仓库（建议命名为 hayou-bypass）"
    echo "3. 不要初始化README、.gitignore或许可证"
    echo "4. 复制仓库URL（如：https://github.com/username/hayou-bypass.git）"
    echo
    read -p "请输入GitHub仓库URL: " REPO_URL
    
    if [[ -z "$REPO_URL" ]]; then
        print_error "仓库URL不能为空"
        exit 1
    fi
fi

print_info "使用仓库: $REPO_URL"

# 检查是否已经是Git仓库
if [[ -d ".git" ]]; then
    print_warning "已存在Git仓库，将重新配置远程仓库"
    git remote remove origin 2>/dev/null || true
else
    print_info "初始化Git仓库..."
    git init
fi

# 创建.gitignore文件
print_info "创建.gitignore文件..."
cat > .gitignore << 'EOF'
# Android
*.iml
.gradle
/local.properties
/.idea/
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
local.properties

# APK文件
*.apk
*.aab

# 签名文件
*.jks
*.keystore

# 日志文件
*.log

# 临时文件
*.tmp
*.temp

# 系统文件
.DS_Store
Thumbs.db

# IDE文件
.vscode/
*.swp
*.swo
*~

# 环境配置
.env
.env.local

# 构建输出
app/build/
build/
EOF

# 创建README.md
print_info "创建README.md文件..."
cat > README.md << 'EOF'
# 哈友工具箱绕过器

一个用于绕过哈友工具箱授权验证的Android应用。

## 🚀 快速开始

### 在线构建APK

1. **Fork此仓库**
2. **启用GitHub Actions**
3. **推送代码触发构建**
4. **下载构建的APK**

### 本地构建

```bash
# 克隆仓库
git clone https://github.com/yourusername/hayou-bypass.git
cd hayou-bypass

# 构建APK
./build_apk.sh debug
```

## 📱 使用说明

1. 确保Android设备已Root
2. 安装哈友工具箱应用
3. 安装本绕过器APK
4. 打开绕过器并授予Root权限
5. 点击"启动绕过"开始使用

## 🔧 功能特点

- ✅ 网络校验绕过
- ✅ 本地校验绕过
- ✅ 360加固绕过
- ✅ 后台持续监控
- ✅ 一键启动绕过

## ⚠️ 免责声明

本项目仅供学习研究使用，请遵守相关法律法规。使用者需自行承担使用风险和法律责任。

## 📄 许可证

本项目采用MIT许可证，详见LICENSE文件。
EOF

# 创建LICENSE文件
print_info "创建LICENSE文件..."
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Hayou Bypass

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# 配置Git用户信息（如果未配置）
if [[ -z "$(git config --global user.name)" ]]; then
    print_warning "Git用户信息未配置"
    read -p "请输入您的姓名: " GIT_NAME
    read -p "请输入您的邮箱: " GIT_EMAIL
    
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    print_success "Git用户信息已配置"
fi

# 添加远程仓库
print_info "配置远程仓库..."
git remote add origin "$REPO_URL"

# 添加所有文件
print_info "添加文件到Git..."
git add .

# 提交更改
print_info "提交更改..."
git commit -m "Initial commit: 哈友工具箱绕过器项目

- 添加Android应用源码
- 配置GitHub Actions自动构建
- 添加详细的使用文档
- 支持Debug和Release版本构建"

# 推送到GitHub
print_info "推送到GitHub..."
echo
print_warning "即将推送代码到GitHub，请确保："
echo "1. 您有该仓库的写入权限"
echo "2. 已正确配置GitHub认证（SSH密钥或Personal Access Token）"
echo "3. 仓库URL正确无误"
echo
read -p "确认推送? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 尝试推送
    if git push -u origin main 2>/dev/null; then
        print_success "推送成功！"
    elif git push -u origin master 2>/dev/null; then
        print_success "推送成功！"
    else
        print_error "推送失败，请检查："
        echo "1. 网络连接"
        echo "2. GitHub认证配置"
        echo "3. 仓库权限"
        echo "4. 仓库URL是否正确"
        echo
        print_info "手动推送命令："
        echo "git push -u origin main"
        exit 1
    fi
else
    print_info "跳过推送，您可以稍后手动推送："
    echo "git push -u origin main"
fi

print_success "🎉 GitHub仓库配置完成！"

echo
print_info "📋 下一步操作："
echo "1. 访问您的GitHub仓库页面"
echo "2. 点击 'Actions' 标签页"
echo "3. 启用GitHub Actions（如果需要）"
echo "4. 推送代码将自动触发APK构建"
echo "5. 在 'Actions' 页面查看构建进度"
echo "6. 构建完成后在 'Artifacts' 下载APK"

echo
print_info "🔗 有用的链接："
echo "- 仓库地址: $REPO_URL"
echo "- Actions页面: ${REPO_URL%.git}/actions"
echo "- Releases页面: ${REPO_URL%.git}/releases"

echo
print_warning "⚠️ 重要提醒："
echo "- 本项目仅供学习研究使用"
echo "- 请遵守GitHub服务条款"
echo "- 请遵守相关法律法规"
echo "- 不要上传敏感信息或密钥"

echo
print_info "🛠️ 故障排除："
echo "- 如果构建失败，检查 Actions 页面的错误日志"
echo "- 确保所有必要的文件都已提交"
echo "- 检查 build.gradle 配置是否正确"
echo "- 查看 快速构建指南.md 获取更多帮助"