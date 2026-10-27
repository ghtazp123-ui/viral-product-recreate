#Requires -Version 5.1
<#
  viral-product-recreate 一键安装器（各自账号版）
  用法：把整个 viral-product-recreate 文件夹发给同事，让同事在本文件夹内右键「用 PowerShell 运行」此脚本。
  脚本会：①装 creatok CLI ②装 ffmpeg ③把 skill 注册进 WorkBuddy ④写入每人自己的 CREATOK_API_KEY
#>
$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "viral-product-recreate 安装器"
Write-Host "== viral-product-recreate 安装器（各自账号版）==" -ForegroundColor Cyan

# 1) Node.js 检查（装 creatok 需要 npm）
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "错误：未检测到 Node.js。请先到 https://nodejs.org 安装 LTS 版本，再重新运行本脚本。" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}
Write-Host "Node: $(node -v)" -ForegroundColor Green

# 2) 安装 creatok CLI
if (Get-Command creatok -ErrorAction SilentlyContinue) {
    Write-Host "creatok 已安装：$(creatok --version 2>$null)" -ForegroundColor Green
} else {
    Write-Host "正在安装 creatok CLI (npm -g @creatok/cli)..." -ForegroundColor Yellow
    npm install -g @creatok/cli@latest
}

# 3) 安装 ffmpeg
if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    Write-Host "ffmpeg 已安装" -ForegroundColor Green
} else {
    Write-Host "尝试用 winget 安装 ffmpeg..." -ForegroundColor Yellow
    winget install --id Gyan.FFmpeg -e --silent | Out-Null
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "winget 安装失败。请手动安装 ffmpeg 并加入 PATH（如 scoop install ffmpeg / choco install ffmpeg）。" -ForegroundColor Red
    }
}

# 4) 把本 skill 注册进 WorkBuddy（用户级 skills 目录）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SkillsDir = Join-Path $env:USERPROFILE ".workbuddy\skills"
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
$Target = Join-Path $SkillsDir "viral-product-recreate"
if (Test-Path $Target) { Remove-Item $Target -Recurse -Force }
Copy-Item -Path $ScriptDir -Destination $Target -Recurse
Write-Host "已安装 skill 到 $Target" -ForegroundColor Green

# 5) 写入每人自己的 API Key（用户级环境变量，持久化）
$Key = Read-Host -Prompt "请输入你的 CREATOK_API_KEY（各自账号，从 CreatOK 后台获取）"
if ($Key.Trim().Length -gt 0) {
    [Environment]::SetEnvironmentVariable("CREATOK_API_KEY", $Key.Trim(), "User")
    $env:CREATOK_API_KEY = $Key.Trim()
    Write-Host "已写入用户环境变量 CREATOK_API_KEY（新开的终端/WorkBuddy 即生效）" -ForegroundColor Green
} else {
    Write-Host "未输入 key，跳过。稍后手动设置 CREATOK_API_KEY 环境变量即可。" -ForegroundColor Yellow
}

# 6) 验证
Write-Host "验证账户与余额：" -ForegroundColor Cyan
creatok account show
Write-Host ""
Write-Host "完成！在 WorkBuddy 中直接说：『换品复刻这个爆款 + 你的产品图』即可调用本 skill。" -ForegroundColor Green
Read-Host "按回车退出"

