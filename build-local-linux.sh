#!/usr/bin/env bash
#
# build-local-linux.sh — 基于官方 CI 逻辑的本地 Linux 二进制构建脚本
#
# 对应官方 CI 腿 (eng/pipelines/runtime.yml -> AllSubsets_CoreCLR_ReleaseRuntimeLibs,
# 平台 linux_arm/linux_arm64/linux_musl_x64/linux_musl_arm64) 的本地等价实现:
#
#   ./build.sh -ci -arch <arch> -os linux [-cross] \
#       -s clr+libs+host+packs -rc Release -lc Release -c <config>
#
# 参数映射 (与 eng/pipelines/common/global-build-job.yml 一致):
#   _osParameter   -> -os linux
#   _archParameter -> -arch <arch>
#   buildArgs      -> -s clr+libs+host+packs -rc Release -lc Release -c <config>
#   crossArg       -> -cross (仅交叉编译时; CI 中由 crossBuild 参数控制)
#   -ci            -> 启用 binary log (Build.binlog) + MSBuild node_reuse=false
#
# 产物输出:
#   artifacts/bin/dotnet/      完整 dotnet root (coreclr + host + shared framework)
#   artifacts/packages/        runtime/libraries packs (NuGet)
#   artifacts/log/<config>/    build 日志 (含 Build.binlog)

set -euo pipefail

# ---------------------------------------------------------------------------
# 默认值 —— 对齐 CI: rolling 构建 (debugOnPrReleaseOnRolling) 为 Release
# ---------------------------------------------------------------------------
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH="x64" ;;
  aarch64) ARCH="arm64" ;;
  armv7l)  ARCH="arm" ;;
  *) ;;
esac

CONFIGURATION="Release"      # -c, CI rolling 默认 Release
RUNTIME_CONFIG="Release"     # -rc (CI: -rc Release)
LIBS_CONFIG="Release"        # -lc (CI: -lc Release)
SUBSETS="clr+libs+host+packs" # -s (CI 主腿)
CI_MODE=false                # --ci 启用 CI 语义 (binlog + node_reuse=false)
CROSS=false                  # --cross 交叉编译 (需 ROOTFS_DIR)
BINARY_LOG=true              # 默认生成 Build.binlog (CI -ci 默认行为)
CLEAN=false                  # --clean 先清理 artifacts
TARGET_RID=""                # --targetrid (可选覆盖)
EXTRA_ARGS=()                # 透传给 build.sh 的额外参数

usage() {
  cat <<'EOF'
用法: ./build-local-linux.sh [选项]

基于官方 CI (eng/pipelines/runtime.yml) 逻辑在本地构建 Linux 版本二进制。

选项:
  -a, --arch <arch>       目标架构: x64, arm64, arm, x86
                          [默认: 本机架构]
  -c, --configuration <c> 总体配置: Debug, Release, Checked
                          [默认: Release (CI rolling 行为)]
  -rc, --runtime-config   运行时 (CLR) 配置: Debug, Release, Checked [默认: Release]
  -lc, --libraries-config 库配置: Debug, Release [默认: Release]
  -s, --subsets <s>       构建子集, 如 clr+libs+host+packs
                          [默认: clr+libs+host+packs (CI 主腿)]
      --cross             交叉编译 (设置 ROOTFS_DIR 后使用; 同架构本机构建无需)
      --targetrid <rid>   覆盖 target rid (如 linux-musl-x64)
      --ci                启用 CI 语义: Build.binlog + MSBuild node_reuse=false
                          [默认: 始终生成 binlog; --ci 额外禁用 node reuse]
      --clean             构建前清理 artifacts/
      --skip-binlog       不生成 Build.binlog
  -h, --help              显示本帮助

环境变量:
  ROOTFS_DIR              交叉编译时的 rootfs 路径
  SCCACHE_*               若已安装 sccache, 会自动启用 (CI 同款缓存)

示例:
  ./build-local-linux.sh                                  # 本机架构, Release, 全产物
  ./build-local-linux.sh -a arm64 -c Release              # 交叉编译 arm64
  ./build-local-linux.sh -s clr+libs -c Debug             # 仅 clr+libs, Debug
EOF
}

# ---------------------------------------------------------------------------
# 参数解析
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--arch)                ARCH="$2"; shift 2 ;;
    -c|--configuration)       CONFIGURATION="$2"; shift 2 ;;
    -rc|--runtime-config)     RUNTIME_CONFIG="$2"; shift 2 ;;
    -lc|--libraries-config)   LIBS_CONFIG="$2"; shift 2 ;;
    -s|--subsets)             SUBSETS="$2"; shift 2 ;;
    --cross)                  CROSS=true; shift ;;
    --targetrid)              TARGET_RID="$2"; shift 2 ;;
    --ci)                     CI_MODE=true; shift ;;
    --clean)                  CLEAN=true; shift ;;
    --skip-binlog)            BINARY_LOG=false; shift ;;
    -h|--help)                usage; exit 0 ;;
    *)                        EXTRA_ARGS+=("$1"); shift ;;
  esac
done

# ---------------------------------------------------------------------------
# 前置检查
# ---------------------------------------------------------------------------
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_ROOT"

if [[ ! -f "./build.sh" ]]; then
  echo "错误: 未找到 ./build.sh, 请在 dotnet/runtime 仓库根目录运行此脚本。" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "警告: 当前目录不是 git 仓库, 继续构建。" >&2
fi

if [[ "$CROSS" == true && -z "${ROOTFS_DIR:-}" ]]; then
  echo "错误: --cross 需要设置 ROOTFS_DIR 环境变量 (指向目标平台的 rootfs)。" >&2
  echo "      同架构本机构建不需要 --cross。" >&2
  exit 1
fi

# 磁盘空间提示 (完整构建约需 15-30 GB)
AVAIL_GB="$(df -Pk . | awk 'NR==2 {print int($4/1024/1024)}')"
if [[ -n "$AVAIL_GB" && "$AVAIL_GB" -lt 20 ]]; then
  echo "警告: 可用磁盘空间仅 ${AVAIL_GB}GB, 完整构建可能需要 15-30GB。" >&2
fi

# ---------------------------------------------------------------------------
# 可选: 启用 sccache (CI 使用 setup-sccache.yml; 本地若安装了则自动复用)
# ---------------------------------------------------------------------------
if command -v sccache >/dev/null 2>&1; then
  export SCCACHE_CACHE_SIZE="${SCCACHE_CACHE_SIZE:-10G}"
  echo "检测到 sccache, 启用缓存 (SCCACHE_CACHE_SIZE=${SCCACHE_CACHE_SIZE})。"
fi

# ---------------------------------------------------------------------------
# 组装构建命令 (复刻 CI: build.sh -ci -arch X -os linux [-cross] -s ... )
# ---------------------------------------------------------------------------
BUILD_ARGS=(
  -arch "$ARCH"
  -os linux
)

[[ "$CROSS" == true ]] && BUILD_ARGS+=(-cross)
[[ -n "$TARGET_RID" ]] && BUILD_ARGS+=(--targetrid "$TARGET_RID")
[[ "$BINARY_LOG" == true ]] && BUILD_ARGS+=(-bl)

# CI 语义: node_reuse=false (仅 --ci 时, 与 eng/common/build.sh 一致)
if [[ "$CI_MODE" == true ]]; then
  export MSBUILD_NODEREUSE_ENABLED=0
  echo "CI 模式: 禁用 MSBuild node reuse。"
fi

# --clean: 清理 artifacts (等价于 CI 全新 agent 环境)
if [[ "$CLEAN" == true ]]; then
  echo "=== [1/2] 清理 artifacts/ ==="
  rm -rf artifacts
fi

echo "=== [1/2] 开始构建: Linux ${ARCH} ${CONFIGURATION} ==="
echo "      子集:  ${SUBSETS}"
echo "      运行时: ${RUNTIME_CONFIG}  库: ${LIBS_CONFIG}"
echo "      命令:  ./build.sh ${BUILD_ARGS[*]} -s ${SUBSETS} -rc ${RUNTIME_CONFIG} -lc ${LIBS_CONFIG} -c ${CONFIGURATION} ${EXTRA_ARGS[*]}"
echo ""

# ---------------------------------------------------------------------------
# 执行构建 (与 CI global-build-step.yml 的调用等价)
# ---------------------------------------------------------------------------
# shellcheck disable=SC2086
./build.sh \
  "${BUILD_ARGS[@]}" \
  -s "$SUBSETS" \
  -rc "$RUNTIME_CONFIG" \
  -lc "$LIBS_CONFIG" \
  -c "$CONFIGURATION" \
  "${EXTRA_ARGS[@]}"

BUILD_RC=$?

# ---------------------------------------------------------------------------
# 汇总产物
# ---------------------------------------------------------------------------
echo ""
echo "=== [2/2] 构建完成 (exit=$BUILD_RC) ==="
echo "产物目录:"
if [[ -d "artifacts/bin/dotnet" ]]; then
  echo "  完整 dotnet root: artifacts/bin/dotnet/"
  echo "    - host/muxer:    artifacts/bin/dotnet/dotnet"
  echo "    - runtime:       artifacts/bin/dotnet/shared/Microsoft.NETCore.App/*/"
  echo "    - hostfxr:       artifacts/bin/dotnet/host/fxr/*/"
fi
if [[ -d "artifacts/packages" ]]; then
  echo "  NuGet packs:      artifacts/packages/"
fi
if [[ -d "artifacts/log" ]]; then
  echo "  build 日志:      artifacts/log/ (含 Build.binlog)"
fi
echo ""
echo "快速验证:"
echo "  artifacts/bin/dotnet/dotnet --info"
exit "$BUILD_RC"
