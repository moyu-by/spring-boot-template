#!/bin/bash
# ====================================================
# 项目重命名脚本 — Linux / macOS / Git Bash
#
# 用法: ./rename.sh <新groupId> <新artifactId>
#
# 示例:
#   ./scripts/rename.sh com.mycompany my-app
#
# 脚本会替换包名、目录结构、pom.xml、主类名。
# 根目录改名需要脚本外手动执行（脚本无法重命名自身所在目录）。
# ====================================================

set -e

if [ "$#" -ne 2 ]; then
    echo "用法: ./rename.sh <新groupId> <新artifactId>"
    echo ""
    echo "示例:"
    echo "  ./scripts/rename.sh com.mycompany my-app"
    echo ""
    echo "执行后会提示你手动改根目录名。"
    exit 1
fi

NEW_GROUP="$1"
NEW_ARTIFACT="$2"

OLD_GROUP="com.example"
OLD_ARTIFACT="demo"
OLD_PACKAGE="${OLD_GROUP}.${OLD_ARTIFACT}"

NEW_ARTIFACT_SAFE="${NEW_ARTIFACT//-/.}"
NEW_PACKAGE="${NEW_GROUP}.${NEW_ARTIFACT_SAFE}"
NEW_DIR="${NEW_PACKAGE//./\/}"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

echo "========================================"
echo "  旧包名: ${OLD_PACKAGE}"
echo "  新包名: ${NEW_PACKAGE}"
echo "  artifactId: ${OLD_ARTIFACT} → ${NEW_ARTIFACT}"
echo "  当前目录: ${PROJECT_NAME}/"
echo "========================================"
echo ""

cd "$PROJECT_ROOT"

# ==================== 1. 替换文件内容 ====================
echo "[1/5] 替换文件中的包名引用..."
OLD_ESCAPED="${OLD_PACKAGE//\./\\.}"
find src -type f \( -name "*.java" -o -name "*.xml" -o -name "*.yml" -o -name "*.yaml" -o -name "*.properties" \) \
    -exec sed -i '' "s|${OLD_ESCAPED}|${NEW_PACKAGE}|g" {} + 2>/dev/null \
    || find src -type f \( -name "*.java" -o -name "*.xml" -o -name "*.yml" -o -name "*.yaml" -o -name "*.properties" \) \
       -exec sed -i "s|${OLD_ESCAPED}|${NEW_PACKAGE}|g" {} +

# ==================== 2. 替换 pom.xml ====================
echo "[2/5] 更新 pom.xml..."
sed -i '' "s|<groupId>${OLD_GROUP}</groupId>|<groupId>${NEW_GROUP}</groupId>|" pom.xml 2>/dev/null \
    || sed -i "s|<groupId>${OLD_GROUP}</groupId>|<groupId>${NEW_GROUP}</groupId>|" pom.xml
sed -i '' "s|<artifactId>${OLD_ARTIFACT}</artifactId>|<artifactId>${NEW_ARTIFACT}</artifactId>|" pom.xml 2>/dev/null \
    || sed -i "s|<artifactId>${OLD_ARTIFACT}</artifactId>|<artifactId>${NEW_ARTIFACT}</artifactId>|" pom.xml

# ==================== 3. 替换 application.yml ====================
echo "[3/5] 更新 application.yml..."
sed -i '' "s|name: ${OLD_ARTIFACT}|name: ${NEW_ARTIFACT}|" src/main/resources/application.yml 2>/dev/null \
    || sed -i "s|name: ${OLD_ARTIFACT}|name: ${NEW_ARTIFACT}|" src/main/resources/application.yml

# ==================== 4. 移动目录结构 ====================
echo "[4/5] 移动目录结构..."

OLD_DIR="src/main/java/${OLD_GROUP//./\/}/${OLD_ARTIFACT}"
NEW_DIR_FULL="src/main/java/${NEW_DIR}"

mkdir -p "$(dirname "$NEW_DIR_FULL")"
if [ -d "$OLD_DIR" ]; then
    mv "$OLD_DIR"/* "$NEW_DIR_FULL/" 2>/dev/null && rm -rf "${OLD_DIR%/*}" || mv "$OLD_DIR" "$NEW_DIR_FULL"
    rmdir -p "src/main/java/${OLD_GROUP//./\/}" 2>/dev/null || true
fi

OLD_TEST_DIR="src/test/java/${OLD_GROUP//./\/}/${OLD_ARTIFACT}"
NEW_TEST_DIR="src/test/java/${NEW_DIR}"

if [ -d "$OLD_TEST_DIR" ]; then
    mkdir -p "$(dirname "$NEW_TEST_DIR")"
    mv "$OLD_TEST_DIR"/* "$NEW_TEST_DIR/" 2>/dev/null || mv "$OLD_TEST_DIR" "$NEW_TEST_DIR"
    rmdir -p "src/test/java/${OLD_GROUP//./\/}" 2>/dev/null || true
fi

# ==================== 5. 重命名主类 ====================
echo "[5/5] 重命名主类..."

NEW_MAIN_NAME="${NEW_ARTIFACT^}"
NEW_MAIN_NAME="${NEW_MAIN_NAME//-}"
NEW_MAIN_NAME="${NEW_MAIN_NAME}Application"

MAIN_FILE=$(grep -rl "@SpringBootApplication" "$NEW_DIR_FULL" 2>/dev/null | head -1)
if [ -n "$MAIN_FILE" ]; then
    OLD_MAIN_NAME=$(basename "$MAIN_FILE" .java)
    sed -i '' "s|class ${OLD_MAIN_NAME}|class ${NEW_MAIN_NAME}|" "$MAIN_FILE" 2>/dev/null \
        || sed -i "s|class ${OLD_MAIN_NAME}|class ${NEW_MAIN_NAME}|" "$MAIN_FILE"
    sed -i '' "s|${OLD_MAIN_NAME}\.class|${NEW_MAIN_NAME}.class|g" "$MAIN_FILE" 2>/dev/null \
        || sed -i "s|${OLD_MAIN_NAME}\.class|${NEW_MAIN_NAME}.class|g" "$MAIN_FILE"
    mv "$MAIN_FILE" "$(dirname "$MAIN_FILE")/${NEW_MAIN_NAME}.java"
    echo "   主类: ${OLD_MAIN_NAME} → ${NEW_MAIN_NAME}"
fi

TEST_MAIN_FILE=$(grep -rl "@SpringBootTest" "$NEW_TEST_DIR" 2>/dev/null | head -1)
if [ -n "$TEST_MAIN_FILE" ]; then
    OLD_TEST_NAME=$(basename "$TEST_MAIN_FILE" .java)
    NEW_TEST_NAME="${NEW_ARTIFACT^}"
    NEW_TEST_NAME="${NEW_TEST_NAME//-}"
    NEW_TEST_NAME="${NEW_TEST_NAME}ApplicationTests"
    sed -i '' "s|class ${OLD_TEST_NAME}|class ${NEW_TEST_NAME}|" "$TEST_MAIN_FILE" 2>/dev/null \
        || sed -i "s|class ${OLD_TEST_NAME}|class ${NEW_TEST_NAME}|" "$TEST_MAIN_FILE"
    mv "$TEST_MAIN_FILE" "$(dirname "$TEST_MAIN_FILE")/${NEW_TEST_NAME}.java"
    echo "   测试: ${OLD_TEST_NAME} → ${NEW_TEST_NAME}"
fi

echo ""
echo "========================================"
echo "  ✅ 项目内容重命名完成!"
echo "  包名:     ${OLD_PACKAGE} → ${NEW_PACKAGE}"
echo "  artifact: ${OLD_ARTIFACT} → ${NEW_ARTIFACT}"
echo "  主类:     ${OLD_MAIN_NAME:-DemoApplication} → ${NEW_MAIN_NAME}"
echo "========================================"
echo ""
echo "最后一步: 回到上级目录执行根目录改名"
echo ""
echo "  cd .. && mv '${PROJECT_NAME}' '${NEW_ARTIFACT}'"
echo ""
echo "以上命令可直接复制粘贴执行。"
echo ""
