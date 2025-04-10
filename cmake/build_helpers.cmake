# Some libraries we use set the BUILD_SHARED_LIBS variable to ON, which causes CMake to
# display a warning about options being set using set() instead of option().
# Explicitly set the policy to NEW to suppress the warning.
set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

set(CMAKE_POLICY_DEFAULT_CMP0063 NEW)

if (POLICY CMP0177)
    set(CMAKE_POLICY_DEFAULT_CMP0177 OLD)
    cmake_policy(SET CMP0177 OLD)
endif()

function(getTarget target type)
    get_target_property(IMPORTED_TARGET ${target} IMPORTED)
    if (IMPORTED_TARGET)
        set(${type} INTERFACE PARENT_SCOPE)
    else()
        set(${type} PRIVATE PARENT_SCOPE)
    endif()
endfunction()

function(addCFlag)
    if (ARGC EQUAL 1)
        add_compile_options($<$<COMPILE_LANGUAGE:C>:${ARGV0}>)
    elseif (ARGC EQUAL 2)
        getTarget(${ARGV1} TYPE)
        target_compile_options(${ARGV1} ${TYPE} $<$<COMPILE_LANGUAGE:C>:${ARGV0}>)
    endif()
endfunction()

function(addCXXFlag)
    if (ARGC EQUAL 1)
        add_compile_options($<$<COMPILE_LANGUAGE:CXX>:${ARGV0}>)
    elseif (ARGC EQUAL 2)
        getTarget(${ARGV1} TYPE)
        target_compile_options(${ARGV1} ${TYPE} $<$<COMPILE_LANGUAGE:CXX>:${ARGV0}>)
    endif()
endfunction()

function(addObjCFlag)
    if (ARGC EQUAL 1)
        add_compile_options($<$<COMPILE_LANGUAGE:OBJC>:${ARGV0}>)
    elseif (ARGC EQUAL 2)
        getTarget(${ARGV1} TYPE)
        target_compile_options(${ARGV1} ${TYPE} $<$<COMPILE_LANGUAGE:OBJC>:${ARGV0}>)
    endif()
endfunction()

function(addLinkerFlag)
    if (ARGC EQUAL 1)
        add_link_options(${ARGV0})
    elseif (ARGC EQUAL 2)
        getTarget(${ARGV1} TYPE)
        target_link_options(${ARGV1} ${TYPE} ${ARGV0})
    endif()
endfunction()

function(addCCXXFlag)
    addCFlag(${ARGV0} ${ARGV1})
    addCXXFlag(${ARGV0} ${ARGV1})
endfunction()

function(addCommonFlag)
    addCFlag(${ARGV0} ${ARGV1})
    addCXXFlag(${ARGV0} ${ARGV1})
    addObjCFlag(${ARGV0} ${ARGV1})
endfunction()

set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "Disable deprecated warnings" FORCE)

include(FetchContent)

if(IMHEX_STRIP_RELEASE)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set(CPACK_STRIP_FILES TRUE)
    endif()
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_link_options($<$<CONFIG:RELEASE>:-s>)
    endif()
endif()

macro(addDefines)
    # 检查版本
    if (NOT IMHEX_VERSION)
        message(FATAL_ERROR "IMHEX_VERSION is not defined")
    endif ()
    # 这行代码向 CMAKE_RC_FLAGS 变量添加了编译器标志，将项目的版本号的主版本号、次版本号和补丁号作为宏定义传递给编译器。
    set(CMAKE_RC_FLAGS "${CMAKE_RC_FLAGS} -DPROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR} -DPROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR} -DPROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH} ")

    set(IMHEX_VERSION_STRING ${IMHEX_VERSION})
    # 检查构建模式
    if (CMAKE_BUILD_TYPE STREQUAL "Release")
        set(IMHEX_VERSION_STRING ${IMHEX_VERSION_STRING})
        add_compile_definitions(NDEBUG)
    elseif (CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(IMHEX_VERSION_STRING ${IMHEX_VERSION_STRING}-Debug)
        add_compile_definitions(DEBUG)
    elseif (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        set(IMHEX_VERSION_STRING ${IMHEX_VERSION_STRING})
        add_compile_definitions(NDEBUG)
    elseif (CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
        set(IMHEX_VERSION_STRING ${IMHEX_VERSION_STRING}-MinSizeRel)
        add_compile_definitions(NDEBUG)
    endif ()
    # 启用调试断言
    if (IMHEX_ENABLE_STD_ASSERTS)
        add_compile_definitions(_GLIBCXX_DEBUG _GLIBCXX_VERBOSE)
    endif()
    # 静态链接所有插件到主可执行文件
    if (IMHEX_STATIC_LINK_PLUGINS)
        add_compile_definitions(IMHEX_STATIC_LINK_PLUGINS)
    endif ()
endmacro()

function(addDefineToSource SOURCE DEFINE)
    set_property(
            SOURCE ${SOURCE}
            APPEND
            PROPERTY COMPILE_DEFINITIONS "${DEFINE}"
    )

    # Disable precompiled headers for this file
    set_source_files_properties(${SOURCE} PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
endfunction()

# Detect current OS / System  检查当前编译的操作系统
macro(detectOS)
    # 如果是windows系统
    if (WIN32)
        # 定义编译标志
        add_compile_definitions(OS_WINDOWS)
        # 设置可执行文件的安装目录为当前目录
        set(CMAKE_INSTALL_BINDIR ".")
        # 设置库文件的安装目录为当前目录
        set(CMAKE_INSTALL_LIBDIR ".")
        # 设置插件的安装目录为 plugins
        set(PLUGINS_INSTALL_LOCATION "plugins")
        # WIN32_LEAN_AND_MEAN：减少 Windows 头文件的大小（不包含不常用的 Windows API）。
        # NOMINMAX：避免在 Windows API 中定义 min 和 max 宏。
        # UNICODE：启用 Unicode 支持。
        # _CRT_SECURE_NO_WARNINGS：禁用与安全相关的 CRT 警告（通常与不安全的字符串操作函数有关）。
        add_compile_definitions(WIN32_LEAN_AND_MEAN)
        add_compile_definitions(NOMINMAX)
        add_compile_definitions(UNICODE)
        add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    # 如果是苹果操作系统
    elseif (APPLE)
        # 定义编译标志
        add_compile_definitions(OS_MACOS)
        # 设置可执行文件的安装目录为当前目录
        set(CMAKE_INSTALL_BINDIR ".")
        # 设置库文件的安装目录为当前目录
        set(CMAKE_INSTALL_LIBDIR ".")
        # 设置插件的安装目录为 plugins
        set(PLUGINS_INSTALL_LOCATION "plugins")
        # 启用 Objective-C 和 C++ 语言
        enable_language(OBJC)
        enable_language(OBJCXX)
    # 如果是Emscripten是基于LLVM / Clang的编译器，用来将C和C++源代码编译为WebAssembly
    elseif (EMSCRIPTEN)
        add_compile_definitions(OS_WEB)
    # 如果为UNIX 且不是APPLE
    elseif (UNIX AND NOT APPLE)
        # 添加编译标志
        add_compile_definitions(OS_LINUX)
        # 检查操作系统是否是 FreeBSD
        if (BSD AND BSD STREQUAL "FreeBSD")
            # 添加编译标志
            add_compile_definitions(OS_FREEBSD)
        endif()
        # 引入linux标准安装路径
        include(GNUInstallDirs)

        # 插件放入share目录
        if(IMHEX_PLUGINS_IN_SHARE)
            set(PLUGINS_INSTALL_LOCATION "share/imhex/plugins")
        else()
            # /usr/local/lib这样的目录中
            set(PLUGINS_INSTALL_LOCATION "${CMAKE_INSTALL_LIBDIR}/imhex/plugins")

            # Add System plugin location for plugins to be loaded from
            # IMPORTANT: This does not work for Sandboxed or portable builds such as the Flatpak or AppImage release
            # 添加系统插件位置以加载插件
            add_compile_definitions(SYSTEM_PLUGINS_LOCATION="${CMAKE_INSTALL_FULL_LIBDIR}/imhex")
        endif()

    else ()
        # 不受支持的系统
        message(FATAL_ERROR "Unknown / unsupported system!")
    endif()

endmacro()

macro(configurePackingResources)
    set(LIBRARY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

    if (WIN32)
        if (NOT (CMAKE_BUILD_TYPE STREQUAL "Debug"))
            set(APPLICATION_TYPE WIN32)
        endif ()

        # 图标为当前目录下的资源文件
        set(IMHEX_ICON "${IMHEX_BASE_FOLDER}/resources/resource.rc")
        
        # 构建本机包（仅限Windows和MacOS）
        if (IMHEX_GENERATE_PACKAGE)
            # 设置构建工具
            set(CPACK_GENERATOR "WIX")
            # 构建名称
            set(CPACK_PACKAGE_NAME "ImHex")
            # 构建作者
            set(CPACK_PACKAGE_VENDOR "WerWolv")
            # 软件版本号GUI
            set(CPACK_WIX_UPGRADE_GUID "05000E99-9659-42FD-A1CF-05C554B39285")
            # 安装包使用的产品图标 
            set(CPACK_WIX_PRODUCT_ICON "${PROJECT_SOURCE_DIR}/resources/dist/windows/icon.ico")
            # 设置了安装包的 UI 横幅图像，通常是在安装程序的界面上展示的一个横幅。
            set(CPACK_WIX_UI_BANNER "${PROJECT_SOURCE_DIR}/resources/dist/windows/wix_banner.png")
            # 设置了安装包的对话框图像，通常用于安装过程中显示的对话框背景或图像
            set(CPACK_WIX_UI_DIALOG "${PROJECT_SOURCE_DIR}/resources/dist/windows/wix_dialog.png")
            # 设置了安装包支持的语言和地区文化。这里列出了多个语言区域，包括英语（美国）、德语、日语、意大利语、葡萄牙语、中文（简体和繁体）、俄语等
            set(CPACK_WIX_CULTURES "en-US;de-DE;ja-JP;it-IT;pt-BR;zh-CN;zh-TW;ru-RU")
            #  设置了安装时的默认安装目录。安装程序会将应用程序安装到 ImHex 目录中。
            set(CPACK_PACKAGE_INSTALL_DIRECTORY "ImHex")
            # 行设置了安装时的开始菜单快捷方式。$<TARGET_FILE_NAME:main> 会引用构建时的 main 可执行文件，并为它创建一个名为 ImHex 的开始菜单快捷方式
            set_property(INSTALL "$<TARGET_FILE_NAME:main>"
                    PROPERTY CPACK_START_MENU_SHORTCUTS "ImHex"
            )
            # 设置了安装包中的许可证文件，这里指定了一个 LICENSE.rtf 文件作为许可证文件。
            set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/resources/dist/windows/LICENSE.rtf")
        endif()
    
    # 如果是Mac 端 matches 匹配字符串
    elseif (APPLE OR ${CMAKE_HOST_SYSTEM_NAME} MATCHES "Darwin")
        # 设置了应用程序的图标文件路径。这个图标文件是一个 .icns 格式的图标文件，通常用于 macOS 应用程序的图标。
        set(IMHEX_ICON "${IMHEX_BASE_FOLDER}/resources/dist/macos/AppIcon.icns")
        # 设置了应用程序的名称
        set(BUNDLE_NAME "imhex.app")
        
        # 启用了构建本机包
        if (IMHEX_GENERATE_PACKAGE)
            
            # 设置程序类型为 MacOSX_BUNDLE
            set(APPLICATION_TYPE MACOSX_BUNDLE)
            # 设置了应用程序的图标文件路径 MAC端 将图标设置进入Resources 文件里面
            set_source_files_properties(${IMHEX_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
            # 设置应用程序包的图标
            set(MACOSX_BUNDLE_ICON_FILE "AppIcon.icns")
            # 设置构建信息
            set(MACOSX_BUNDLE_INFO_STRING "WerWolv")
            # 设置程序包名称
            set(MACOSX_BUNDLE_BUNDLE_NAME "ImHex")
            # 指定 macOS 应用程序的 Info.plist 文件的位置。Info.plist 是一个包含应用程序基本信息的文件
            set(MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/resources/dist/macos/Info.plist.in")
            # 设置版本信息字符串
            set(MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")
            # 设置GUI标识符
            set(MACOSX_BUNDLE_GUI_IDENTIFIER "net.WerWolv.ImHex")
            # 过截取 Git 提交哈希的前 7 位 
            string(SUBSTRING "${IMHEX_COMMIT_HASH_LONG}" 0 7 COMMIT_HASH_SHORT)
            # 生成版本号
            set(MACOSX_BUNDLE_LONG_VERSION_STRING "${PROJECT_VERSION}-${COMMIT_HASH_SHORT}")
            # 短版本号
            set(MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}")
            # 设置版权信息
            string(TIMESTAMP CURR_YEAR "%Y")
            set(MACOSX_BUNDLE_COPYRIGHT "Copyright © 2020 - ${CURR_YEAR} WerWolv. All rights reserved." )
            # 如果构建工具是Xcode
            if ("${CMAKE_GENERATOR}" STREQUAL "Xcode")
                # 设置了应用程序包的路径。这个路径是一个包含应用程序的目录，通常用于 macOS 应用程序的分发和安装。
                set (IMHEX_BUNDLE_PATH "${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/${BUNDLE_NAME}")
            else ()
                # 如果不是Xcode，则设置了应用程序包的路径。这个路径是一个包含应用程序的目录
                set (IMHEX_BUNDLE_PATH "${CMAKE_BINARY_DIR}/${BUNDLE_NAME}")
            endif()

            # 设置了插件的安装位置
            set(PLUGINS_INSTALL_LOCATION "${IMHEX_BUNDLE_PATH}/Contents/MacOS/plugins")
            # 设置了应用程序的安装目录
            set(CMAKE_INSTALL_LIBDIR "${IMHEX_BUNDLE_PATH}/Contents/Frameworks")
        endif()
    endif()
endmacro()

# 添加插件列表
macro(addPluginDirectories)
    # 当前构建目录创建一个子目录
    file(MAKE_DIRECTORY "plugins")
    # 遍历 plugins 目录下的所有子目录
    foreach (plugin IN LISTS PLUGINS)
        # 添加子模块列表
        add_subdirectory("plugins/${plugin}")
        # 检查是否定义了插件
        if (TARGET ${plugin})
            # 设置插件的输出目录
            set_target_properties(${plugin} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${IMHEX_MAIN_OUTPUT_DIRECTORY}/plugins")
            set_target_properties(${plugin} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${IMHEX_MAIN_OUTPUT_DIRECTORY}/plugins")
            # 如果是MacOS
            if (APPLE)
                # 如果构建本机包
                if (IMHEX_GENERATE_PACKAGE)
                    # 设置插件的输出目录
                    set_target_properties(${plugin} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${PLUGINS_INSTALL_LOCATION})
                endif ()
            else ()
                # 如果是window端
                if (WIN32)
                    # 获取插件的类型
                    get_target_property(target_type ${plugin} TYPE)
                    # 如果插件是动态链接库
                    if (target_type STREQUAL "SHARED_LIBRARY")
                        # 安装插件 运行时目标
                        install(TARGETS ${plugin} RUNTIME DESTINATION ${PLUGINS_INSTALL_LOCATION})
                    else ()
                        # 安装的是一个动态链接库
                        install(TARGETS ${plugin} LIBRARY DESTINATION ${PLUGINS_INSTALL_LOCATION})
                    endif()
                else()
                    # 如果是Linux端
                    install(TARGETS ${plugin} LIBRARY DESTINATION ${PLUGINS_INSTALL_LOCATION})
                endif()

            endif()

            add_dependencies(imhex_all ${plugin})
        endif ()
    endforeach()
endmacro()

# 构建包
macro(createPackage)
    # 如果是window平台    
    if (WIN32)
        # Install binaries directly in the prefix, usually C:\Program Files\ImHex. 将二进制文件直接安装到前缀中，通常是 C:\Program Files\ImHex
        set(CMAKE_INSTALL_BINDIR ".")
        # 设置插件的安装目录
        set(PLUGIN_TARGET_FILES "")
        # 遍历插件列表
        foreach (plugin IN LISTS PLUGINS) 
            # 将其添加到插件目标文件列表中
            list(APPEND PLUGIN_TARGET_FILES "$<TARGET_FILE:${plugin}>")
        endforeach ()

        # Grab all dynamically linked dependencies.
        # 将 PLUGIN_TARGET_FILES 变量（可能存储了一组目标文件的路径）传递到安装过程中。这样做的目的是确保在安装时，可以继续使用该变量中的文件路径
        install(CODE "set(CMAKE_INSTALL_BINDIR \"${CMAKE_INSTALL_BINDIR}\")")
        install(CODE "set(PLUGIN_TARGET_FILES \"${PLUGIN_TARGET_FILES}\")")
        # 检查运行时依赖项的文件，包括 PLUGIN_TARGET_FILES 中列出的文件路径，以及两个通过 TARGET_FILE 表达式获得的目标文件路径：libimhex 和 main。
        # 解析后的依赖关系将存储在 _r_deps 变量中
        # 解析的依赖关系（如果有的话）将存储在 _u_deps 变量中
        # 如果有冲突的依赖项，它们将以 _c_deps 为前缀进行分类
        # 依赖项的查找目录，这里包括了 DEP_FOLDERS 变量中的目录以及系统的 PATH 环境变量
        # 排除 system32 文件夹下的 .dll 文件
        # file(GET_RUNTIME_DEPENDENCIES
        install(CODE [[
        file(GET_RUNTIME_DEPENDENCIES
            EXECUTABLES ${PLUGIN_TARGET_FILES} $<TARGET_FILE:libimhex> $<TARGET_FILE:main>
            RESOLVED_DEPENDENCIES_VAR _r_deps
            UNRESOLVED_DEPENDENCIES_VAR _u_deps
            CONFLICTING_DEPENDENCIES_PREFIX _c_deps
            DIRECTORIES ${DEP_FOLDERS} $ENV{PATH}
            POST_EXCLUDE_REGEXES ".*system32/.*\\.dll"
        )
    
        if(_c_deps_FILENAMES)
            message(WARNING "Conflicting dependencies for library: \"${_c_deps}\"!")
        endif()

        foreach(_file ${_r_deps})
            file(INSTALL
                DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"
                TYPE SHARED_LIBRARY
                FOLLOW_SYMLINK_CHAIN
                FILES "${_file}"
                )
        endforeach()
        ]])

        downloadImHexPatternsFiles("./")
    elseif(UNIX AND NOT APPLE)
        # 设置libihex 的版本
        set_target_properties(libimhex PROPERTIES SOVERSION ${IMHEX_VERSION})

        # 将一个源文件复制到指定的目录
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/dist/DEBIAN/control.in ${CMAKE_BINARY_DIR}/DEBIAN/control)
         
        # 将许可证信息放入到指定的目录
        install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE DESTINATION ${CMAKE_INSTALL_PREFIX}/share/licenses/imhex)
        # 将desktop文件放入指定目录
        install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/dist/imhex.desktop DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications)
        # 将项目配置文件放入指定目录
        install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/dist/imhex.mime.xml DESTINATION ${CMAKE_INSTALL_PREFIX}/share/mime/packages RENAME imhex.xml)
        # 将图标文件放入指定目录
        install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/resources/icon.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/pixmaps RENAME imhex.svg)
        # 下载格式文件
        downloadImHexPatternsFiles("./share/imhex")

        # install AppStream file AppStream 是一个标准化的格式，用于描述 Linux 应用程序的元数据，如图标、描述、类别、版本等信息
        install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/dist/net.werwolv.imhex.metainfo.xml DESTINATION ${CMAKE_INSTALL_PREFIX}/share/metainfo)

        # install symlink for the old standard name
        # 创建一个符号链接
        file(CREATE_LINK net.werwolv.imhex.metainfo.xml ${CMAKE_CURRENT_BINARY_DIR}/net.werwolv.imhex.appdata.xml SYMBOLIC)
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/net.werwolv.imhex.appdata.xml DESTINATION ${CMAKE_INSTALL_PREFIX}/share/metainfo)

    endif()

    # 如果是苹果端
    if (APPLE)
        # 构建本机包
        if (IMHEX_GENERATE_PACKAGE)
            # 将IMHEX_SYSTEM_LIBRARY_PATH追加到EXTRA_BUNDLE_LIBRARY_PATHS中
            set(EXTRA_BUNDLE_LIBRARY_PATHS ${EXTRA_BUNDLE_LIBRARY_PATHS} "${IMHEX_SYSTEM_LIBRARY_PATH}")
            # 插件处理
            include(PostprocessBundle)
            # 设置程序版本
            set_target_properties(libimhex PROPERTIES SOVERSION ${IMHEX_VERSION})
            # 设置插件信息
            set_property(TARGET main PROPERTY MACOSX_BUNDLE_INFO_PLIST ${MACOSX_BUNDLE_INFO_PLIST})

            # Fix rpath
            install(CODE "execute_process(COMMAND ${CMAKE_INSTALL_NAME_TOOL} -add_rpath \"@executable_path/../Frameworks/\" $<TARGET_FILE:main>)")


            # build-time-make-plugins-directory 的自定义目标，并且每次构建时（由于 ALL 选项），都会执行一个命令来创建一个目录
            add_custom_target(build-time-make-plugins-directory ALL COMMAND ${CMAKE_COMMAND} -E make_directory "${IMHEX_BUNDLE_PATH}/Contents/MacOS/plugins")
            # 通过此命令，构建时会确保在应用程序的捆绑包中创建一个 Contents/Resources 目录，通常这个目录用来存放应用程序的资源文件
            add_custom_target(build-time-make-resources-directory ALL COMMAND ${CMAKE_COMMAND} -E make_directory "${IMHEX_BUNDLE_PATH}/Contents/Resources")
            # 下载mac端的模式文件
            downloadImHexPatternsFiles("${CMAKE_INSTALL_PREFIX}/${BUNDLE_NAME}/Contents/MacOS")
            # 将图标安装进入Resources 目录
            install(FILES ${IMHEX_ICON} DESTINATION "${CMAKE_INSTALL_PREFIX}/${BUNDLE_NAME}/Contents/Resources")
            # 将main 和updater 可执行文件安装到指定目录  
            install(TARGETS main BUNDLE DESTINATION ".")
            install(TARGETS updater BUNDLE DESTINATION ".")

            # Update library references to make the bundle portable
            postprocess_bundle(imhex_all main)

            # Enforce DragNDrop packaging. 设置打包类别
            set(CPACK_GENERATOR "DragNDrop")

            # 设置了应用程序图标
            set(CPACK_BUNDLE_ICON "${CMAKE_SOURCE_DIR}/resources/dist/macos/AppIcon.icns")
            # 设置macOS应用plist
            set(CPACK_BUNDLE_PLIST "${CMAKE_INSTALL_PREFIX}/${BUNDLE_NAME}/Contents/Info.plist")
            # 
            if (IMHEX_RESIGN_BUNDLE)
                find_program(CODESIGN_PATH codesign)
                if (CODESIGN_PATH)
                    install(CODE "message(STATUS \"Signing bundle '${CMAKE_INSTALL_PREFIX}/${BUNDLE_NAME}'...\")")
                    install(CODE "execute_process(COMMAND ${CODESIGN_PATH} --force --deep --entitlements ${CMAKE_SOURCE_DIR}/resources/macos/Entitlements.plist --sign - ${CMAKE_INSTALL_PREFIX}/${BUNDLE_NAME} COMMAND_ERROR_IS_FATAL ANY)")
                endif()
            endif()

            install(CODE [[ message(STATUS "MacOS Bundle finalized. DO NOT TOUCH IT ANYMORE! ANY MODIFICATIONS WILL BREAK IT FROM NOW ON!") ]])
        else()
            downloadImHexPatternsFiles("${IMHEX_MAIN_OUTPUT_DIRECTORY}")
        endif()
    else()
        install(TARGETS main RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
        if (TARGET updater)
            install(TARGETS updater RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
        endif()
        if (TARGET main-forwarder)
            install(TARGETS main-forwarder BUNDLE DESTINATION ${CMAKE_INSTALL_BINDIR})
        endif()
    endif()

    # 构建本地静态包
    if (IMHEX_GENERATE_PACKAGE)
        set(CPACK_BUNDLE_NAME "ImHex")

        include(CPack)
    endif()
endmacro()

function(JOIN OUTPUT GLUE)
    set(_TMP_RESULT "")
    set(_GLUE "") # effective glue is empty at the beginning
    foreach(arg ${ARGN})
        set(_TMP_RESULT "${_TMP_RESULT}${_GLUE}${arg}")
        set(_GLUE "${GLUE}")
    endforeach()
    set(${OUTPUT} "${_TMP_RESULT}" PARENT_SCOPE)
endfunction()

macro(configureCMake)
    message(STATUS "Configuring ImHex v${IMHEX_VERSION}")

    if (DEFINED CMAKE_TOOLCHAIN_FILE)
        message(STATUS "Using toolchain file: \"${CMAKE_TOOLCHAIN_FILE}\"")
    endif()

    set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "Enable position independent code for all targets" FORCE)

    # Configure use of recommended build tools 设置使用推荐的构建工具
    if (IMHEX_USE_DEFAULT_BUILD_SETTINGS)
        message(STATUS "Configuring CMake to use recommended build tools...")

        find_program(CCACHE_PATH ccache)
        find_program(NINJA_PATH ninja)
        find_program(LD_LLD_PATH ld.lld)
        find_program(AR_LLVMLIBS_PATH llvm-ar)
        find_program(RANLIB_LLVMLIBS_PATH llvm-ranlib)

        if (CCACHE_PATH)
            set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_PATH})
            set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PATH})
        else ()
            message(WARNING "ccache not found!")
        endif ()

        if (AR_LLVMLIBS_PATH)
            set(CMAKE_AR ${AR_LLVMLIBS_PATH})
        else ()
            message(WARNING "llvm-ar not found, using default ar!")
        endif ()

        if (RANLIB_LLVMLIBS_PATH)
            set(CMAKE_RANLIB ${RANLIB_LLVMLIBS_PATH})
        else ()
            message(WARNING "llvm-ranlib not found, using default ranlib!")
        endif ()

        if (LD_LLD_PATH)
            set(CMAKE_LINKER ${LD_LLD_PATH})

            if (NOT XCODE AND NOT MSVC)
                set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} -fuse-ld=lld)
                set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -fuse-ld=lld)
            endif()
        else ()
            message(WARNING "lld not found, using default linker!")
        endif ()

        if (NINJA_PATH)
            set(CMAKE_GENERATOR Ninja)
        else ()
            message(WARNING "ninja not found, using default generator!")
        endif ()
    endif()

    # Enable LTO if desired and supported 启用 LTO（链接时间优化）如果需要并且支持
    if (IMHEX_ENABLE_LTO)
        include(CheckIPOSupported)

        check_ipo_supported(RESULT result OUTPUT output_error)
        if (result)
            set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
            message(STATUS "LTO enabled!")
        else ()
            message(WARNING "LTO is not supported: ${output_error}")
        endif ()
    endif ()
endmacro()

function(configureProject)
    # Enable C and C++ languages
    enable_language(C CXX)
    
    # 如果编译工具是XCODE
    if (XCODE)
        # Support Xcode's multi configuration paradigm by placing built artifacts into separate directories
        # CMAKE_BINARY_DIR 是执行cmake 命令时所在的目录
        # 在Mac端分配到不同的目录
        set(IMHEX_MAIN_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Configs/$<CONFIG>" PARENT_SCOPE)
    else()
        # 不是XCODE直接放到当前目录
        set(IMHEX_MAIN_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}" PARENT_SCOPE)
    endif()
endfunction()

# 设置
macro(setDefaultBuiltTypeIfUnset)
    if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        # 设置CMAKE_BUILD_TYPE为RelWithDebInfo 并且将其存储在 CMake 的缓存中。CACHE STRING 指定了这是一个字符串类型的缓存变量。FORCE 参数表示即使该变量之前有其他值，也会强制覆盖。
        # RelWithDebInfo 是一个CMake的构建类型，表示“Release with Debug Info”，即在发布版本中包含调试信息
        set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "Using RelWithDebInfo build type as it was left unset" FORCE)
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "RelWithDebInfo")
    endif()
endmacro()


function(loadVersion version plain_version)
    set(VERSION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${VERSION_FILE})
    file(READ "${VERSION_FILE}" read_version)
    string(STRIP ${read_version} read_version)
    string(REPLACE ".WIP" "" read_version_plain ${read_version})
    set(${version} ${read_version} PARENT_SCOPE)
    set(${plain_version} ${read_version_plain} PARENT_SCOPE)
endfunction()

# 检测 lib/external/ 和 lib/third_party/ 目录中的外部依赖是否正确地被克隆
function(detectBadClone)
    if (IMHEX_IGNORE_BAD_CLONE)
        return()
    endif()
    # 搜索 lib/external/ 和 lib/third_party/ 目录下的所有文件和子目录，结果会存储在 EXTERNAL_DIRS 列表中。即，它获取了所有外部依赖的目录路径
    file (GLOB EXTERNAL_DIRS "lib/external/*" "lib/third_party/*")
    # 循环遍历 EXTERNAL_DIRS 列表中的每个目录。每个目录存储在变量 EXTERNAL_DIR 中    
    foreach (EXTERNAL_DIR ${EXTERNAL_DIRS})
        # 使用 file(GLOB_RECURSE ...) 命令递归地查找该目录下的所有文件和子目录
        file(GLOB_RECURSE RESULT "${EXTERNAL_DIR}/*")
        # 获取 RESULT 列表的长度
        list(LENGTH RESULT ENTRY_COUNT)
        # 如果 ENTRY_COUNT 小于等于 1，表示该目录为空或只包含一个文件（可能是 .git 或其他隐藏文件）
        if(ENTRY_COUNT LESS_EQUAL 1)
            message(FATAL_ERROR "External dependency ${EXTERNAL_DIR} is empty!\nMake sure to correctly clone ImHex using the --recurse-submodules git option or initialize the submodules manually.")
        endif()
    endforeach ()
endfunction()

# 检查编译器
function(verifyCompiler)
    if (IMHEX_IGNORE_BAD_COMPILER)
        return()
    endif()
    # 检查GCC版本
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "12.0.0")
        message(FATAL_ERROR "ImHex requires GCC 12.0.0 or newer. Please use the latest GCC version.")
    # 检查CMAKE版本
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "17.0.0")
        message(FATAL_ERROR "ImHex requires Clang 17.0.0 or newer. Please use the latest Clang version.")
    # 检查MSVC版本
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # 如果编译器既不是 GCC 也不是 Clang，则会抛出错误，指出该项目仅支持 GCC 和 Clang 编译器，不支持其他编译器。    
    elseif (NOT (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang"))
        message(FATAL_ERROR "ImHex can only be compiled with GCC or Clang. ${CMAKE_CXX_COMPILER_ID} is not supported.")
    endif()
endfunction()

# 检测是否有捆绑插件
macro(detectBundledPlugins)
    # 遍历 plugins 目录下的所有子目录
    file(GLOB PLUGINS_DIRS "plugins/*")

    # 如果没有定义 IMHEX_INCLUDE_PLUGINS 变量，则默认包含所有插件
    if (NOT DEFINED IMHEX_INCLUDE_PLUGINS)

        #遍历 PLUGINS_DIRS 列表中的每个目录
        foreach(PLUGIN_DIR ${PLUGINS_DIRS})
            # 检查该目录下是否存在 CMakeLists.txt 文件
            if (EXISTS "${PLUGIN_DIR}/CMakeLists.txt")
                # 如果存在，则获取该目录的名称，并将其添加到 PLUGINS 列表中
                get_filename_component(PLUGIN_NAME ${PLUGIN_DIR} NAME)
                # 检查插件是否在 IMHEX_EXCLUDE_PLUGINS 列表中
                if (NOT (${PLUGIN_NAME} IN_LIST IMHEX_EXCLUDE_PLUGINS))
                    # 往列表中添加插件名称
                    list(APPEND PLUGINS ${PLUGIN_NAME})
                endif ()
            endif()
        endforeach()
    else()
        # 定义了 IMHEX_INCLUDE_PLUGINS 变量，则将其值转换为列表
        set(PLUGINS ${IMHEX_INCLUDE_PLUGINS})
    endif()

    # 遍历 PLUGINS 列表中的每个插件
    foreach(PLUGIN_NAME ${PLUGINS})
        message(STATUS "Enabled bundled plugin '${PLUGIN_NAME}'")
    endforeach()

    # 如果没有启用任何插件，则抛出错误
    if (NOT PLUGINS)
        message(FATAL_ERROR "No bundled plugins enabled")
    endif()

    # 检查是否包含了内置插件
    if (NOT ("builtin" IN_LIST PLUGINS))
        message(FATAL_ERROR "The 'builtin' plugin is required for ImHex to work!")
    endif ()
endmacro()

macro(setVariableInParent variable value)
    get_directory_property(hasParent PARENT_DIRECTORY)

    if (hasParent)
        set(${variable} "${value}" PARENT_SCOPE)
    else ()
        set(${variable} "${value}")
    endif ()
endmacro()

# 下载模式文件
function(downloadImHexPatternsFiles dest)
    if (NOT IMHEX_OFFLINE_BUILD)
        if (IMHEX_PATTERNS_PULL_MASTER)
            set(PATTERNS_BRANCH master)
        else ()
            set(PATTERNS_BRANCH ImHex-v${IMHEX_VERSION})
        endif ()

        FetchContent_Declare(
                imhex_patterns
                GIT_REPOSITORY https://github.com/WerWolv/ImHex-Patterns.git
                GIT_TAG origin/master
        )

        message(STATUS "Downloading ImHex-Patterns repo branch ${PATTERNS_BRANCH}...")
        FetchContent_MakeAvailable(imhex_patterns)
        message(STATUS "Finished downloading ImHex-Patterns")

    else ()
        set(imhex_patterns_SOURCE_DIR "")

        # Maybe patterns are cloned to a subdirectory
        if (NOT EXISTS ${imhex_patterns_SOURCE_DIR})
            set(imhex_patterns_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ImHex-Patterns")
        endif()

        # Or a sibling directory
        if (NOT EXISTS ${imhex_patterns_SOURCE_DIR})
            set(imhex_patterns_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../ImHex-Patterns")
        endif()
    endif ()

    if (NOT EXISTS ${imhex_patterns_SOURCE_DIR})
        message(WARNING "Failed to locate ImHex-Patterns repository, some resources will be missing during install!")
    elseif(XCODE)
        # The Xcode build has multiple configurations, which each need a copy of these files
        file(GLOB_RECURSE sourceFilePaths LIST_DIRECTORIES NO CONFIGURE_DEPENDS RELATIVE "${imhex_patterns_SOURCE_DIR}"
            "${imhex_patterns_SOURCE_DIR}/constants/*"
            "${imhex_patterns_SOURCE_DIR}/encodings/*"
            "${imhex_patterns_SOURCE_DIR}/includes/*"
            "${imhex_patterns_SOURCE_DIR}/patterns/*"
            "${imhex_patterns_SOURCE_DIR}/magic/*"
            "${imhex_patterns_SOURCE_DIR}/nodes/*"
        )
        list(FILTER sourceFilePaths EXCLUDE REGEX "_schema.json$")

        foreach(relativePath IN LISTS sourceFilePaths)
            file(GENERATE OUTPUT "${dest}/${relativePath}" INPUT "${imhex_patterns_SOURCE_DIR}/${relativePath}")
        endforeach()
    else()
        set(PATTERNS_FOLDERS_TO_INSTALL constants encodings includes patterns magic nodes)
        foreach (FOLDER ${PATTERNS_FOLDERS_TO_INSTALL})
            install(DIRECTORY "${imhex_patterns_SOURCE_DIR}/${FOLDER}" DESTINATION "${dest}" PATTERN "**/_schema.json" EXCLUDE)
        endforeach ()
    endif ()

endfunction()

# Compress debug info. See https://github.com/WerWolv/ImHex/issues/1714 for relevant problem
macro(setupDebugCompressionFlag)
    include(CheckCXXCompilerFlag)
    include(CheckLinkerFlag)

    check_cxx_compiler_flag(-gz=zstd ZSTD_AVAILABLE_COMPILER)
    check_linker_flag(CXX -gz=zstd ZSTD_AVAILABLE_LINKER)
    check_cxx_compiler_flag(-gz COMPRESS_AVAILABLE_COMPILER)
    check_linker_flag(CXX -gz COMPRESS_AVAILABLE_LINKER)

    if (NOT DEBUG_COMPRESSION_FLAG) # Cache variable
        if (ZSTD_AVAILABLE_COMPILER AND ZSTD_AVAILABLE_LINKER)
            message("Using Zstd compression for debug info because both compiler and linker support it")
            set(DEBUG_COMPRESSION_FLAG "-gz=zstd" CACHE STRING "Cache to use for debug info compression")
        elseif (COMPRESS_AVAILABLE_COMPILER AND COMPRESS_AVAILABLE_LINKER)
            message("Using default compression for debug info because both compiler and linker support it")
            set(DEBUG_COMPRESSION_FLAG "-gz" CACHE STRING "Cache to use for debug info compression")
        else()
            set(DEBUG_COMPRESSION_FLAG "" CACHE STRING "Cache to use for debug info compression")
        endif()
    endif()

    addCommonFlag(${DEBUG_COMPRESSION_FLAG})
endmacro()

macro(setupCompilerFlags target)
    if (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
        addCommonFlag("/W4" ${target})
        addCommonFlag("/wd4127" ${target}) # conditional expression is constant
        addCommonFlag("/wd4242" ${target}) # 'identifier': conversion from 'type1' to 'type2', possible loss of data
        addCommonFlag("/wd4244" ${target}) # 'conversion': conversion from 'type1' to 'type2', possible loss of data
        addCommonFlag("/wd4267" ${target}) # 'var': conversion from 'size_t' to 'type', possible loss of data
        addCommonFlag("/wd4305" ${target}) # truncation from 'double' to 'float'
        addCommonFlag("/wd4996" ${target}) # 'function': was declared deprecated
        addCommonFlag("/wd5244" ${target}) # 'include' in the purview of module 'module' appears erroneous

        if (IMHEX_STRICT_WARNINGS)
            addCommonFlag("/WX" ${target})
        endif()
    elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        addCommonFlag("-Wall" ${target})
        addCommonFlag("-Wextra" ${target})
        addCommonFlag("-Wpedantic" ${target})

        # Define strict compilation flags
        if (IMHEX_STRICT_WARNINGS)
             addCommonFlag("-Werror" ${target})
        endif()

        if (UNIX AND NOT APPLE AND CMAKE_CXX_COMPILER_ID MATCHES "GNU")
            addCommonFlag("-rdynamic" ${target})
        endif()

        addCXXFlag("-fexceptions" ${target})
        addCXXFlag("-frtti" ${target})

        # Disable some warnings
        addCCXXFlag("-Wno-array-bounds" ${target})
        addCCXXFlag("-Wno-deprecated-declarations" ${target})
        addCCXXFlag("-Wno-unknown-pragmas" ${target})
        addCXXFlag("-Wno-include-angled-in-module-purview" ${target})

        # Enable hardening flags
        if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
            addCommonFlag("-U_FORTIFY_SOURCE" ${target})
            addCommonFlag("-D_FORTIFY_SOURCE=3" ${target})

            if (NOT EMSCRIPTEN)
                addCommonFlag("-fstack-protector-strong" ${target})
            endif()
        endif()

    endif()

    if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        if (WIN32)
            addLinkerFlag("-Wa,mbig-obj" ${target})
        endif ()
    endif()

    if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND APPLE)
        execute_process(COMMAND brew --prefix llvm OUTPUT_VARIABLE LLVM_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -L${LLVM_PREFIX}/lib/c++")
        set(CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -L${LLVM_PREFIX}/lib/c++")
        addCCXXFlag("-Wno-unknown-warning-option" ${target})

        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            add_compile_definitions(_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG)
        else()
            add_compile_definitions(_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_EXTENSIVE)
        endif()
    endif()

    if (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
        addCommonFlag("/bigobj" ${target})
        addCFlag("/std:clatest" ${target})
        addCXXFlag("/std:c++latest" ${target})
    endif()

    # Disable some warnings for gcc
    if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        addCCXXFlag("-Wno-restrict" ${target})
        addCCXXFlag("-Wno-stringop-overread" ${target})
        addCCXXFlag("-Wno-stringop-overflow" ${target})
        addCCXXFlag("-Wno-dangling-reference" ${target})
    endif()

    # Define emscripten-specific disabled warnings
    if (EMSCRIPTEN)
        addCCXXFlag("-pthread" ${target})
        addCCXXFlag("-Wno-dollar-in-identifier-extension" ${target})
        addCCXXFlag("-Wno-pthreads-mem-growth" ${target})
    endif ()

    if (IMHEX_COMPRESS_DEBUG_INFO)
        setupDebugCompressionFlag()
    endif()

    # Only generate minimal debug information for stacktraces in RelWithDebInfo builds
    if (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
            addCCXXFlag("-g1" ${target})
        endif()

        if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            # Add flags for debug info in inline functions
            addCCXXFlag("-gstatement-frontiers" ${target})
            addCCXXFlag("-ginline-points" ${target})
        endif()
    endif()
endmacro()

# uninstall target  卸载目标
macro(setUninstallTarget)
    # 检查 uninstall 目标是否已经存在
    if(NOT TARGET uninstall)
    # IMMEDIATE：表示 configure_file 函数会在 CMake 配置阶段立即执行，而不是等到构建阶段。
    # @ONLY：表示只替换文件中的 @VAR@ 格式的变量，不会替换其他类型的占位符。

        configure_file(
                "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
                "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
                IMMEDIATE @ONLY)
        # 添加一个自定义目标 uninstall，用于卸载安装的文件
        add_custom_target(uninstall
                COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
    endif()
endmacro()

# 添加捆绑库
macro(addBundledLibraries)
    # 设置第三方库文件夹和外部库文件夹的路径
    set(EXTERNAL_LIBS_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/lib/external")
    set(THIRD_PARTY_LIBS_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/lib/third_party")

    # 默认构建静态库而不是共享库
    set(BUILD_SHARED_LIBS OFF)
    # 子模块
    add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/imgui)

    add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/microtar EXCLUDE_FROM_ALL)

    add_subdirectory(${EXTERNAL_LIBS_FOLDER}/libwolv EXCLUDE_FROM_ALL)

    set(XDGPP_INCLUDE_DIRS "${THIRD_PARTY_LIBS_FOLDER}/xdgpp")
    set(FPHSA_NAME_MISMATCHED ON CACHE BOOL "")

    # 如果不使用系统的 fmt 库
    if(NOT USE_SYSTEM_FMT)
        set(FMT_INSTALL OFF CACHE BOOL "Disable install targets for libfmt" FORCE)
        add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/fmt EXCLUDE_FROM_ALL)
        set(FMT_LIBRARIES fmt::fmt-header-only)
    else()
        find_package(fmt REQUIRED)
        set(FMT_LIBRARIES fmt::fmt)
    endif()
    # 如果不使用系统的 nfd 库
    if (IMHEX_USE_GTK_FILE_PICKER)
        set(NFD_PORTAL OFF CACHE BOOL "Use Portals for Linux file dialogs" FORCE)
    else ()
        set(NFD_PORTAL ON CACHE BOOL "Use GTK for Linux file dialogs" FORCE)
    endif ()

    #  如果没有使用 Emscripten 构建环境
    if (NOT EMSCRIPTEN)

        # curl
        find_package(CURL REQUIRED)

        # nfd 如果不使用系统的 nfd 库
        if (NOT USE_SYSTEM_NFD)
            add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/nativefiledialog EXCLUDE_FROM_ALL)
            set(NFD_LIBRARIES nfd)
        else()
            find_package(nfd)
            set(NFD_LIBRARIES nfd)
        endif()
    endif()

    # 如果不使用系统等nlomann_json 库
    if(NOT USE_SYSTEM_NLOHMANN_JSON)
        add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/nlohmann_json EXCLUDE_FROM_ALL)
        set(NLOHMANN_JSON_LIBRARIES nlohmann_json)
    else()
        find_package(nlohmann_json 3.10.2 REQUIRED)
        set(NLOHMANN_JSON_LIBRARIES nlohmann_json::nlohmann_json)
    endif()

    # 如果不使用系统等lunasvg 库
    if (NOT USE_SYSTEM_LUNASVG)
        add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/lunasvg EXCLUDE_FROM_ALL)
        set(LUNASVG_LIBRARIES lunasvg)
    else()
        find_package(lunasvg REQUIRED)
        set(LUNASVG_LIBRARIES lunasvg::lunasvg)
    endif()

    # 如果不使用系统等llvm 库
    if (NOT USE_SYSTEM_LLVM)
        add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/llvm-demangle EXCLUDE_FROM_ALL)
    else()
        find_package(LLVM REQUIRED Demangle)
    endif()

    # 如果不使用系统等jthread 库
    if (NOT USE_SYSTEM_JTHREAD)
        add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/jthread EXCLUDE_FROM_ALL)
        set(JTHREAD_LIBRARIES jthread)
    else()
        find_path(JOSUTTIS_JTHREAD_INCLUDE_DIRS "condition_variable_any2.hpp")
        include_directories(${JOSUTTIS_JTHREAD_INCLUDE_DIRS})

        add_library(jthread INTERFACE)
        target_include_directories(jthread INTERFACE ${JOSUTTIS_JTHREAD_INCLUDE_DIRS})
        set(JTHREAD_LIBRARIES jthread)
    endif()

    # 如果使用系统等boost 库
    if (USE_SYSTEM_BOOST)
        find_package(Boost REQUIRED CONFIG COMPONENTS regex)
        set(BOOST_LIBRARIES Boost::regex)
    else()
        add_subdirectory(${THIRD_PARTY_LIBS_FOLDER}/boost ${CMAKE_CURRENT_BINARY_DIR}/boost EXCLUDE_FROM_ALL)
        set(BOOST_LIBRARIES boost::regex)
    endif()

    # 设置变量EXECUTABLES 将其存入缓存中
    set(LIBPL_BUILD_CLI_AS_EXECUTABLE OFF CACHE BOOL "" FORCE)
    set(LIBPL_ENABLE_PRECOMPILED_HEADERS ${IMHEX_ENABLE_PRECOMPILED_HEADERS} CACHE BOOL "" FORCE)

    set(LIBPL_SHARED_LIBRARY OFF CACHE BOOL "" FORCE)

    # 指定不默认构建
    add_subdirectory(${EXTERNAL_LIBS_FOLDER}/pattern_language EXCLUDE_FROM_ALL)
    add_subdirectory(${EXTERNAL_LIBS_FOLDER}/disassembler EXCLUDE_FROM_ALL)

    # 当这个标志为 ON 时，表示在编译时会启用预编译头文件的支持
    if (LIBPL_SHARED_LIBRARY)
        # 设置安装目标 为libpl 
        # 指定安装目录为 ${CMAKE_INSTALL_LIBDIR}
        # PERMISSIONS 设置安装文件的权限  
        install(
            TARGETS
                libpl
            DESTINATION
                "${CMAKE_INSTALL_LIBDIR}"
            PERMISSIONS
                OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
        )
    endif()

    # 如果是在window平台
    if (WIN32)
        # 设置libpl 库 设置可执行文件的输出目录， 动态链接库输出目录
        set_target_properties(
                libpl
                PROPERTIES
                    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
                    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
        )
    endif()
    # 启用统一构建  
    enableUnityBuild(libpl)

    # 使用mbedTLS
    find_package(mbedTLS 3.4.0 REQUIRED)
    # 导入Magic库
    find_package(Magic 5.39 REQUIRED)

    # 如果没有禁用打印堆栈跟踪 
    if (NOT IMHEX_DISABLE_STACKTRACE)
        # 检测操作系统
        if (WIN32)
            message(STATUS "StackWalk enabled!")
            set(LIBBACKTRACE_LIBRARIES DbgHelp.lib)
        else ()
            find_package(Backtrace)
            if (${Backtrace_FOUND})
                message(STATUS "Backtrace enabled! Header: ${Backtrace_HEADER}")

                if (Backtrace_HEADER STREQUAL "backtrace.h")
                    set(LIBBACKTRACE_LIBRARIES ${Backtrace_LIBRARY})
                    set(LIBBACKTRACE_INCLUDE_DIRS ${Backtrace_INCLUDE_DIR})
                    add_compile_definitions(BACKTRACE_HEADER=<${Backtrace_HEADER}>)
                    add_compile_definitions(HEX_HAS_BACKTRACE)
                elseif (Backtrace_HEADER STREQUAL "execinfo.h")
                    set(LIBBACKTRACE_LIBRARIES ${Backtrace_LIBRARY})
                    set(LIBBACKTRACE_INCLUDE_DIRS ${Backtrace_INCLUDE_DIR})
                    add_compile_definitions(BACKTRACE_HEADER=<${Backtrace_HEADER}>)
                    add_compile_definitions(HEX_HAS_EXECINFO)
                endif()
            endif()
        endif()
    endif()
endmacro()

# 是否启用统一构建
# UNITY_BUILD ON：启用 Unity Build 模式。Unity Build 是一种将多个源文件合并成一个源文件进行编译的技术，以减少编译时的开销，从而加速构建过程。
# UNITY_BUILD_MODE BATCH：设置 Unity Build 的模式为批处理（batch）模式。在批处理模式下，CMake 会将多个源文件合并成一个文件进行编译，从而减少预处理器的调用次数，提高构建效率。
function(enableUnityBuild TARGET)
    if (IMHEX_ENABLE_UNITY_BUILD)
        set_target_properties(${TARGET} PROPERTIES UNITY_BUILD ON UNITY_BUILD_MODE BATCH)
    endif ()
endfunction()

# 设置SDK路径
function(setSDKPaths)
    if (WIN32)
        set(SDK_PATH "./sdk" PARENT_SCOPE)
    elseif (APPLE)
        set(SDK_PATH "${CMAKE_INSTALL_PREFIX}/${BUNDLE_NAME}/Contents/Resources/sdk" PARENT_SCOPE)
    else()
        set(SDK_PATH "share/imhex/sdk" PARENT_SCOPE)
    endif()

    set(SDK_BUILD_PATH "${CMAKE_BINARY_DIR}/sdk" PARENT_SCOPE)
endfunction()

function(generateSDKDirectory)
    setSDKPaths()
    # 安装目录到指定位置
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/lib/libimhex DESTINATION "${SDK_PATH}/lib" PATTERN "**/source/*" EXCLUDE)
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/lib/external DESTINATION "${SDK_PATH}/lib")
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/lib/third_party/imgui DESTINATION "${SDK_PATH}/lib/third_party" PATTERN "**/source/*" EXCLUDE)
    # 如果不使用系统的fmt 库
    if (NOT USE_SYSTEM_FMT)
        # 将fmt 库安装到指定位置
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/lib/third_party/fmt DESTINATION "${SDK_PATH}/lib/third_party")
    endif()
    # 不使用系统的nolohmann_json 库
    if (NOT USE_SYSTEM_NLOHMANN_JSON)
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/lib/third_party/nlohmann_json DESTINATION "${SDK_PATH}/lib/third_party")
    endif()
    # 不使用系统的boost
    if (NOT USE_SYSTEM_BOOST)
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/lib/third_party/boost DESTINATION "${SDK_PATH}/lib/third_party")
    endif()

    # 将cmake/moudles 和cmake/build_helpers.cmake 安装到指定位置
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/cmake/modules DESTINATION "${SDK_PATH}/cmake")
    install(FILES ${CMAKE_SOURCE_DIR}/cmake/build_helpers.cmake DESTINATION "${SDK_PATH}/cmake")
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/cmake/sdk/ DESTINATION "${SDK_PATH}")
    # 将libimhex 库安装到指定位置
    install(TARGETS libimhex ARCHIVE DESTINATION "${SDK_PATH}/lib")

    # 将UI的头文件安装到指定目录
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/plugins/ui/include DESTINATION "${SDK_PATH}/lib/ui/include")
    install(FILES ${CMAKE_SOURCE_DIR}/plugins/ui/CMakeLists.txt DESTINATION "${SDK_PATH}/lib/ui/")
    # 如果是window平台
    if (WIN32)
        install(TARGETS ui ARCHIVE DESTINATION "${SDK_PATH}/lib")
    endif()
    # 将文字的头文件安装到指定目录
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/plugins/fonts/include DESTINATION "${SDK_PATH}/lib/fonts/include")
    install(FILES ${CMAKE_SOURCE_DIR}/plugins/fonts/CMakeLists.txt DESTINATION "${SDK_PATH}/lib/fonts/")
    # 如果是window平台
    if (WIN32)
        install(TARGETS fonts ARCHIVE DESTINATION "${SDK_PATH}/lib")
    endif()
endfunction()

function(addIncludesFromLibrary target library)
    get_target_property(library_include_dirs ${library} INTERFACE_INCLUDE_DIRECTORIES)
    target_include_directories(${target} PRIVATE ${library_include_dirs})
endfunction()

function(precompileHeaders target includeFolder)
    if (NOT IMHEX_ENABLE_PRECOMPILED_HEADERS)
        return()
    endif()

    file(GLOB_RECURSE TARGET_INCLUDES "${includeFolder}/**/*.hpp")
    set(SYSTEM_INCLUDES "<algorithm>;<array>;<atomic>;<chrono>;<cmath>;<cstddef>;<cstdint>;<cstdio>;<cstdlib>;<cstring>;<exception>;<filesystem>;<functional>;<iterator>;<limits>;<list>;<map>;<memory>;<optional>;<ranges>;<set>;<stdexcept>;<string>;<string_view>;<thread>;<tuple>;<type_traits>;<unordered_map>;<unordered_set>;<utility>;<variant>;<vector>")
    set(INCLUDES "${SYSTEM_INCLUDES};${TARGET_INCLUDES}")
    string(REPLACE ">" "$<ANGLE-R>" INCLUDES "${INCLUDES}")
    target_precompile_headers(${target}
            PUBLIC
            "$<$<COMPILE_LANGUAGE:CXX>:${INCLUDES}>"
    )
endfunction()
