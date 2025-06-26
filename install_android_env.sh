#!/bin/bash

# Android开发环境一键安装脚本
# 适用于 macOS 系统

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

print_info "🚀 开始安装Android开发环境..."

# 检查操作系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "此脚本仅支持macOS系统"
    exit 1
fi

# 检查Homebrew
print_info "📦 检查Homebrew..."
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew未安装，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # 添加Homebrew到PATH（适用于Apple Silicon Mac）
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    print_success "Homebrew已安装"
fi

# 更新Homebrew
print_info "🔄 更新Homebrew..."
brew update

# 检查Java
print_info "☕ 检查Java环境..."
if ! command -v java &> /dev/null; then
    print_warning "Java未安装，正在安装OpenJDK 11..."
    brew install openjdk@11
else
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1-2)
    print_success "Java已安装，版本: $JAVA_VERSION"
fi

# 安装Android Studio
print_info "📱 安装Android Studio..."
if [[ ! -d "/Applications/Android Studio.app" ]]; then
    print_warning "Android Studio未安装，正在安装..."
    brew install --cask android-studio
    print_success "Android Studio安装完成"
else
    print_success "Android Studio已安装"
fi

# 检查Android SDK
print_info "🔧 检查Android SDK..."
ANDROID_SDK_PATH="$HOME/Library/Android/sdk"
if [[ ! -d "$ANDROID_SDK_PATH" ]]; then
    print_warning "Android SDK未找到，需要手动配置"
    print_info "请按以下步骤操作："
    echo "1. 启动Android Studio"
    echo "2. 完成初始设置向导"
    echo "3. SDK会自动下载到: $ANDROID_SDK_PATH"
    echo "4. 重新运行此脚本"
    
    # 询问是否现在启动Android Studio
    read -p "是否现在启动Android Studio进行初始设置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "/Applications/Android Studio.app"
        print_info "请完成Android Studio的初始设置，然后重新运行此脚本"
        exit 0
    fi
else
    print_success "Android SDK已找到: $ANDROID_SDK_PATH"
fi

# 配置环境变量
print_info "⚙️ 配置环境变量..."

# 检测shell类型
if [[ $SHELL == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ $SHELL == *"bash"* ]]; then
    SHELL_RC="$HOME/.bash_profile"
else
    SHELL_RC="$HOME/.profile"
fi

print_info "使用shell配置文件: $SHELL_RC"

# 备份现有配置
if [[ -f "$SHELL_RC" ]]; then
    cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "已备份现有配置文件"
fi

# 检查是否已配置环境变量
if ! grep -q "ANDROID_HOME" "$SHELL_RC" 2>/dev/null; then
    print_info "添加Android环境变量..."
    
    cat >> "$SHELL_RC" << 'EOF'

# Android Development Environment
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

EOF
    print_success "环境变量已添加"
else
    print_success "环境变量已存在"
fi

# 检查Java环境变量
if ! grep -q "JAVA_HOME" "$SHELL_RC" 2>/dev/null; then
    print_info "添加Java环境变量..."
    
    # 检测Java安装路径
    if [[ -d "/opt/homebrew/opt/openjdk@11" ]]; then
        JAVA_PATH="/opt/homebrew/opt/openjdk@11"
    elif [[ -d "/usr/local/opt/openjdk@11" ]]; then
        JAVA_PATH="/usr/local/opt/openjdk@11"
    else
        JAVA_PATH=$(brew --prefix openjdk@11 2>/dev/null || echo "")
    fi
    
    if [[ -n "$JAVA_PATH" ]]; then
        cat >> "$SHELL_RC" << EOF

# Java Development Environment
export JAVA_HOME=$JAVA_PATH
export PATH=\$JAVA_HOME/bin:\$PATH

EOF
        print_success "Java环境变量已添加"
    else
        print_warning "无法自动检测Java路径，请手动配置"
    fi
else
    print_success "Java环境变量已存在"
fi

# 重新加载环境变量
print_info "🔄 重新加载环境变量..."
source "$SHELL_RC"

# 验证安装
print_info "✅ 验证安装..."

# 检查环境变量
if [[ -n "$ANDROID_HOME" ]]; then
    print_success "ANDROID_HOME: $ANDROID_HOME"
else
    print_warning "ANDROID_HOME未设置，请重启终端后重试"
fi

# 检查Java
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    print_success "Java: $JAVA_VERSION"
else
    print_warning "Java命令未找到"
fi

# 检查Android工具
if command -v adb &> /dev/null; then
    ADB_VERSION=$(adb version | head -n 1)
    print_success "ADB: $ADB_VERSION"
else
    print_warning "ADB未找到，可能需要重启终端"
fi

# 安装必要的SDK组件（如果SDK存在）
if [[ -d "$ANDROID_SDK_PATH" ]] && command -v sdkmanager &> /dev/null; then
    print_info "📦 安装必要的SDK组件..."
    
    # 接受许可证
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    
    # 安装必要组件
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null 2>&1 || true
    
    print_success "SDK组件安装完成"
fi

print_success "🎉 Android开发环境安装完成！"

echo
print_info "📋 下一步操作："
echo "1. 重启终端或运行: source $SHELL_RC"
echo "2. 验证环境: echo \$ANDROID_HOME"
echo "3. 构建APK: cd BypassApp && ./build_apk.sh debug"
echo

print_warning "⚠️ 重要提醒："
echo "- 如果是首次安装Android Studio，请先启动它完成初始设置"
echo "- 确保下载了Android SDK Platform 34和Build Tools 34.0.0"
echo "- 重启终端后环境变量才会生效"

echo
print_info "🔧 故障排除："
echo "- 如果构建失败，请检查ANDROID_HOME是否正确设置"
echo "- 如果权限问题，运行: chmod +x ./build_apk.sh"
echo "- 查看详细安装指南: cat 环境安装指南.md"