<#
.SYNOPSIS
    项目重命名脚本 — Windows PowerShell / PowerShell Core (跨平台)
.DESCRIPTION
    将模板项目 (com.example.demo) 重命名为你的新项目。
    脚本会替换包名、目录结构、pom.xml、主类名。
    根目录改名需要脚本外手动执行（脚本无法重命名自身所在目录）。
.PARAMETER GroupId
    新 groupId，如 com.mycompany
.PARAMETER ArtifactId
    新 artifactId，如 my-app
.EXAMPLE
    .\scripts\rename.ps1 com.mycompany my-app
.EXAMPLE
    .\scripts\rename.ps1 com.blog blog-server
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$GroupId,
    [Parameter(Mandatory = $true)]
    [string]$ArtifactId
)

$ErrorActionPreference = "Stop"

# 旧项目信息
$OldGroup = "com.example"
$OldArtifact = "demo"
$OldPackage = "${OldGroup}.${OldArtifact}"

# 新包名（artifactId 的连字符替换为点）
$ArtifactSafe = $ArtifactId -replace "-", "."
$NewPackage = "${GroupId}.${ArtifactSafe}"
$NewDir = $NewPackage -replace "\.", "/"

# 获取当前项目根目录名
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir/.."
$ProjectName = Split-Path -Leaf $ProjectRoot

Write-Host "========================================"
Write-Host "  旧包名: $OldPackage"
Write-Host "  新包名: $NewPackage"
Write-Host "  artifactId: $OldArtifact → $ArtifactId"
Write-Host "  当前目录: $ProjectName/"
Write-Host "========================================"
Write-Host ""

Set-Location $ProjectRoot

Write-Host "[1/5] 替换文件中的包名引用..."

# 替换所有文本文件中的包名
Get-ChildItem -Recurse -File -Path "src" -Include "*.java", "*.xml", "*.yml", "*.yaml", "*.properties" | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    if ($content -match [regex]::Escape($OldPackage)) {
        $content = $content -replace [regex]::Escape($OldPackage), $NewPackage
        Set-Content -Path $_.FullName -Value $content -NoNewline
    }
}

Write-Host "[2/5] 更新 pom.xml..."

$pomContent = Get-Content -Path "pom.xml" -Raw
$pomContent = $pomContent -replace "<groupId>$OldGroup</groupId>", "<groupId>$GroupId</groupId>"
$pomContent = $pomContent -replace "<artifactId>$OldArtifact</artifactId>", "<artifactId>$ArtifactId</artifactId>"
Set-Content -Path "pom.xml" -Value $pomContent -NoNewline

Write-Host "[3/5] 更新 application.yml..."

$ymlContent = Get-Content -Path "src/main/resources/application.yml" -Raw
$ymlContent = $ymlContent -replace "name: $OldArtifact", "name: $ArtifactId"
Set-Content -Path "src/main/resources/application.yml" -Value $ymlContent -NoNewline

Write-Host "[4/5] 移动目录结构..."

# 移动 src/main/java 下的目录
$OldMainDir = "src/main/java/$($OldGroup -replace '\.', '/')/$OldArtifact"
$NewMainDir = "src/main/java/$NewDir"

if (Test-Path $OldMainDir) {
    $parent = Split-Path -Parent $NewMainDir
    if (-not (Test-Path $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $NewMainDir)) {
        Move-Item -Path $OldMainDir -Destination $NewMainDir
    } else {
        Get-ChildItem -Path "$OldMainDir/*" | Move-Item -Destination $NewMainDir
    }
    # 清理空目录
    $cleanup = "src/main/java/$($OldGroup -replace '\.', '/')"
    while ($cleanup -ne "src/main/java") {
        if (Test-Path $cleanup) {
            $isEmpty = (Get-ChildItem -Path $cleanup).Count -eq 0
            if ($isEmpty) { Remove-Item -Path $cleanup -Recurse -Force } else { break }
        }
        $cleanup = Split-Path -Parent $cleanup
    }
}

# 移动 src/test/java 下的目录
$OldTestDir = "src/test/java/$($OldGroup -replace '\.', '/')/$OldArtifact"
$NewTestDir = "src/test/java/$NewDir"

if (Test-Path $OldTestDir) {
    $parent = Split-Path -Parent $NewTestDir
    if (-not (Test-Path $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $NewTestDir)) {
        Move-Item -Path $OldTestDir -Destination $NewTestDir
    } else {
        Get-ChildItem -Path "$OldTestDir/*" | Move-Item -Destination $NewTestDir
    }
    $cleanup = "src/test/java/$($OldGroup -replace '\.', '/')"
    while ($cleanup -ne "src/test/java") {
        if (Test-Path $cleanup) {
            $isEmpty = (Get-ChildItem -Path $cleanup).Count -eq 0
            if ($isEmpty) { Remove-Item -Path $cleanup -Recurse -Force } else { break }
        }
        $cleanup = Split-Path -Parent $cleanup
    }
}

Write-Host "[5/5] 重命名主类..."

# 新主类名: my-app → MyAppApplication
$NewMainName = (Get-Culture).TextInfo.ToTitleCase(($ArtifactId -replace '-', ' ')) -replace ' ', ''
$NewMainName = "${NewMainName}Application"

# 查找并重命名主类
$MainFile = Get-ChildItem -Path $NewMainDir -Recurse -Filter "*.java" `
    | Select-String -List "@SpringBootApplication" | Select-Object -First 1

if ($MainFile) {
    $OldMainName = [System.IO.Path]::GetFileNameWithoutExtension($MainFile.Path)
    $content = Get-Content -Path $MainFile.Path -Raw
    $content = $content -replace "class $OldMainName", "class $NewMainName"
    # 同时修改 SpringApplication.run(DemoApplication.class, args) → RagApplication.class
    $content = $content -replace "${OldMainName}\.class", "${NewMainName}.class"
    Set-Content -Path $MainFile.Path -Value $content -NoNewline
    $NewMainPath = Join-Path (Split-Path $MainFile.Path) "${NewMainName}.java"
    if ($MainFile.Path -ne $NewMainPath) {
        Remove-Item -Path $MainFile.Path -Force
        # content already written to old path, need to write to new
        Set-Content -Path $NewMainPath -Value $content -NoNewline
    }
    Write-Host "   主类: $OldMainName → $NewMainName"
}

# 查找并重命名测试主类
$TestFile = Get-ChildItem -Path $NewTestDir -Recurse -Filter "*.java" `
    | Select-String -List "@SpringBootTest" | Select-Object -First 1

if ($TestFile) {
    $OldTestName = [System.IO.Path]::GetFileNameWithoutExtension($TestFile.Path)
    $NewTestName = "${NewMainName}Tests"
    $content = Get-Content -Path $TestFile.Path -Raw
    $content = $content -replace "class $OldTestName", "class $NewTestName"
    $NewTestPath = Join-Path (Split-Path $TestFile.Path) "${NewTestName}.java"
    Set-Content -Path $NewTestPath -Value $content -NoNewline
    if ($TestFile.Path -ne $NewTestPath) {
        Remove-Item -Path $TestFile.Path -Force
    }
    Write-Host "   测试: $OldTestName → $NewTestName"
}

Write-Host ""
Write-Host "========================================"
Write-Host "  ✅ 项目内容重命名完成!"
Write-Host "  包名:     $OldPackage → $NewPackage"
Write-Host "  artifact: $OldArtifact → $ArtifactId"
Write-Host "  主类:     DemoApplication → $NewMainName"
Write-Host "========================================"
Write-Host ""
Write-Host "最后一步: 回到上级目录执行根目录改名"
Write-Host ""
Write-Host '  cd .. && Rename-Item -Path "' + $ProjectName + '" -NewName "' + $ArtifactId + '"'
Write-Host ""
Write-Host "以上命令可直接复制粘贴执行。"
