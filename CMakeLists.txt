cmake_minimum_required(VERSION 3.20)

# Options
# 将插件放在lib[..]/imhex/plugins中，而不是share/imhex/plugins中（仅限Linux）
option(IMHEX_PLUGINS_IN_SHARE           "Put the plugins in share/imhex/plugins instead of lib[..]/imhex/plugins (Linux only)"  OFF)
# 剥离发布版本
option(IMHEX_STRIP_RELEASE              "Strip the release builds"                                                              ON )
#启用离线构建
option(IMHEX_OFFLINE_BUILD              "Enable offline build"                                                                  OFF)
# 禁用坏克隆预防检查
option(IMHEX_IGNORE_BAD_CLONE           "Disable the bad clone prevention checks"                                               OFF)
option(IMHEX_PATTERNS_PULL_MASTER       "Download latest files from master branch of the ImHex-Patterns repo"                   OFF)
# 允许使用不受支持的编译器进行编译
option(IMHEX_IGNORE_BAD_COMPILER        "Allow compiling with an unsupported compiler"                                          OFF)
# 使用GTK文件选择器而不是xdg-desktop-portals（仅限Linux）
option(IMHEX_USE_GTK_FILE_PICKER        "Use GTK file picker instead of xdg-desktop-portals (Linux only)"                       OFF)
# 禁用打印堆栈跟踪的支持
option(IMHEX_DISABLE_STACKTRACE         "Disables support for printing stack traces"                                            OFF)
# 构建 .NET 运行时
option(IMHEX_BUNDLE_DOTNET              "Bundle .NET runtime"                                                                   ON )
# 启用链接时间优化
option(IMHEX_ENABLE_LTO                 "Enables Link Time Optimizations if possible"                                           OFF)
# 使用默认的构建设置
option(IMHEX_USE_DEFAULT_BUILD_SETTINGS "Use default build settings"                                                            OFF)
# 启用大多数可用的警告并将其视为错误
option(IMHEX_STRICT_WARNINGS            "Enable most available warnings and treat them as errors"                               ON )
# 静态链接所有插件到主可执行文件
option(IMHEX_STATIC_LINK_PLUGINS        "Statically link all plugins into the main executable"                                  OFF)
# 指定是否应构建本机包（仅限Windows和MacOS）
option(IMHEX_GENERATE_PACKAGE           "Specify if a native package should be built. (Windows and MacOS only)"                 OFF)
# 启用 构建 ImHex 作为一个单一的可执行文件
option(IMHEX_ENABLE_UNITY_BUILD         "Enables building ImHex as a unity build."                                              OFF)
# 启用再非调试构建中生成 PDB 文件（仅限Windows）
option(IMHEX_GENERATE_PDBS              "Enable generating PDB files in non-debug builds (Windows only)"                        OFF)
# 在生成 PDB 文件时删除 DWARF 信息（仅限Windows）
option(IMHEX_REPLACE_DWARF_WITH_PDB     "Remove DWARF information from binaries when generating PDBS (Windows only)"            OFF)
# 在c++标准库中启用调试断言（破坏插件ABI）
option(IMHEX_ENABLE_STD_ASSERTS         "Enable debug asserts in the C++ std library. (Breaks Plugin ABI!)"                     OFF)
# 启用构建单元测试
option(IMHEX_ENABLE_UNIT_TESTS          "Enable building unit tests"                                                            OFF)
# 启用预编译头文件
option(IMHEX_ENABLE_PRECOMPILED_HEADERS "Enable precompiled headers"                                                            OFF)
# 压缩调试信息
option(IMHEX_COMPRESS_DEBUG_INFO        "Compress debug information"                                                            ON )
# 启用C++20模块,仅用于测试
option(IMHEX_ENABLE_CXX_MODULES         "Enable C++20 Module compilation. Testing only!"                                        OFF)

# 设置CMakeLists.txt所在的目录路径
set(IMHEX_BASE_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}")
# 设置模块路径
set(CMAKE_MODULE_PATH "${IMHEX_BASE_FOLDER}/cmake/modules")

# Optional IDE support IDE支持
include("${IMHEX_BASE_FOLDER}/cmake/ide_helpers.cmake")

# Basic compiler and cmake configurations
# 使用 C++23 标准进行编译
set(CMAKE_CXX_STANDARD 23)
# CMake 将尝试在项目中启用 C++20 或 C++23 模块支持
set(CMAKE_CXX_SCAN_FOR_MODULES ${IMHEX_ENABLE_CXX_MODULES})
# CMake 在查找系统头文件之前，优先查找项目中的自定义包含目录
set(CMAKE_INCLUDE_DIRECTORIES_BEFORE ON)

# 其中包含所有编译命令的详细信息（例如，哪些源文件被编译、使用了哪些编译选项等）。这个文件通常用于 IDE、调试器或静态分析工具，帮助它们更好地理解编译过程和项目结构
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 导入构建帮助程序
include("${IMHEX_BASE_FOLDER}/cmake/build_helpers.cmake")

# Setup project
# 加载版本信息 放入这两个变量中
loadVersion(IMHEX_VERSION IMHEX_VERSION_PLAIN)
# 设置父级作用域中的变量
setVariableInParent(IMHEX_VERSION ${IMHEX_VERSION})

# CMAKE配置
configureCMake()
project(imhex
        LANGUAGES       C CXX
        VERSION         ${IMHEX_VERSION_PLAIN}
        DESCRIPTION     "The ImHex Hex Editor"
        HOMEPAGE_URL    "https://imhex.werwolv.net"
)
# 项目配置
configureProject()

# Add ImHex sources
# 添加没有输出的目标
add_custom_target(imhex_all ALL)

# Make sure project is configured correctly 翻译: 确保项目配置正确
setDefaultBuiltTypeIfUnset()
# 检测是否有第三方库没有克隆成功
detectBadClone()
# 检查是否有不支持的编译器
verifyCompiler()

# 检测捆绑插件
detectBundledPlugins()

# Add various defines 添加各种定义
detectOS()

# 添加定义
addDefines()

# Configure packaging and install targets  配置打包和安装目标
# 配置资源打包设置
configurePackingResources()
# 设置卸载目标
setUninstallTarget()
# 添加捆绑库
addBundledLibraries()

# 添加核心库
add_subdirectory(lib/libimhex)
# 主程序
add_subdirectory(main)
# 添加插件
addPluginDirectories()

# Add unit tests
if (IMHEX_ENABLE_UNIT_TESTS)
    if (NOT TARGET unit_tests)
        enable_testing()
        add_custom_target(unit_tests)
        add_subdirectory(tests EXCLUDE_FROM_ALL)
    endif ()
endif ()

# Configure more resources that will be added to the install package  配置更多资源，将添加到安装包中
generateSDKDirectory()

# Handle package generation 构建包
createPackage()

# Accommodate IDEs with FOLDER support
tweakTargetsForIDESupport()
