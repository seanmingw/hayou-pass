#!/bin/bash

# 哈友工具箱绕过器 APK 构建脚本
# 使用方法: ./build_apk.sh [debug|release]

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

# 检查构建类型
BUILD_TYPE=${1:-debug}
if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    print_error "无效的构建类型: $BUILD_TYPE"
    print_info "使用方法: $0 [debug|release]"
    exit 1
fi

print_info "开始构建 $BUILD_TYPE 版本的APK..."

# 检查环境
print_info "检查构建环境..."

# 检查Java
if ! command -v java &> /dev/null; then
    print_error "Java未安装，请先安装Java JDK 8+"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1-2)
print_info "Java版本: $JAVA_VERSION"

# 检查Android SDK
if [[ -z "$ANDROID_HOME" ]]; then
    print_warning "ANDROID_HOME环境变量未设置"
    print_info "尝试自动检测Android SDK..."
    
    # 常见的Android SDK路径
    POSSIBLE_PATHS=(
        "$HOME/Android/Sdk"
        "$HOME/Library/Android/sdk"
        "/usr/local/android-sdk"
        "/opt/android-sdk"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            export ANDROID_HOME="$path"
            print_info "找到Android SDK: $ANDROID_HOME"
            break
        fi
    done
    
    if [[ -z "$ANDROID_HOME" ]]; then
        print_error "无法找到Android SDK，请设置ANDROID_HOME环境变量"
        exit 1
    fi
fi

# 添加Android工具到PATH
export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"

# 检查Gradle Wrapper
if [[ ! -f "./gradlew" ]]; then
    print_error "gradlew文件不存在，请确保在项目根目录运行此脚本"
    exit 1
fi

# 给gradlew执行权限
chmod +x ./gradlew

# 清理之前的构建
print_info "清理之前的构建..."
./gradlew clean

# 同步依赖
print_info "同步项目依赖..."
./gradlew --refresh-dependencies

# 构建APK
print_info "构建 $BUILD_TYPE APK..."
if [[ "$BUILD_TYPE" == "debug" ]]; then
    ./gradlew assembleDebug
    APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
else
    ./gradlew assembleRelease
    APK_PATH="app/build/outputs/apk/release/app-release.apk"
fi

# 检查构建结果
if [[ -f "$APK_PATH" ]]; then
    print_success "APK构建成功!"
    print_info "APK位置: $APK_PATH"
    
    # 显示APK信息
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    print_info "APK大小: $APK_SIZE"
    
    # 如果有aapt工具，显示更多信息
    if command -v aapt &> /dev/null; then
        print_info "APK详细信息:"
        aapt dump badging "$APK_PATH" | grep -E "package|application-label|uses-permission"
    fi
    
    # 询问是否安装到设备
    if command -v adb &> /dev/null; then
        DEVICES=$(adb devices | grep -v "List of devices" | grep "device$" | wc -l)
        if [[ $DEVICES -gt 0 ]]; then
            echo
            read -p "检测到Android设备，是否立即安装APK? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "安装APK到设备..."
                adb install -r "$APK_PATH"
                if [[ $? -eq 0 ]]; then
                    print_success "APK安装成功!"
                else
                    print_error "APK安装失败"
                fi
            fi
        fi
    fi
    
else
    print_error "APK构建失败，请检查错误信息"
    exit 1
fi

# 构建完成
print_success "构建完成!"
print_info "你可以将APK文件传输到Android设备进行安装"
print_warning "注意: 设备需要Root权限才能正常使用绕过功能"

echo
print_info "使用说明:"
echo "1. 将APK安装到已Root的Android设备"
echo "2. 确保哈友工具箱已安装"
echo "3. 打开绕过器应用并授予Root权限"
echo "4. 点击'启动绕过'开始使用"
echo
print_warning "免责声明: 本工具仅供学习研究使用，请遵守相关法律法规"