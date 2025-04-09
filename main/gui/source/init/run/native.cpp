#if !defined(OS_WEB)

#include <hex/api/events/requests_lifecycle.hpp>
#include <wolv/utils/guards.hpp>

#include <init/run.hpp>
#include <window.hpp>

#include <GLFW/glfw3.h>

namespace hex::init
{

    int runImHex()
    {

        bool shouldRestart = false;
        do
        {
            // Register an event handler that will make ImHex restart when requested 注册一个事件处理程序，当请求时使ImHex重新启动
            shouldRestart = false;
            RequestRestartImHex::subscribe([&]
                                           { shouldRestart = true; });

            // 打开程序默认启动窗口
            {
                /**
                 * hex::init::initializeImHex 是一个函数，返回类型为 std::unique_ptr<hex::init::WindowSplash>，使用默认删除器 * std::default_delete。该函数可能用于初始化与 ImHex 相关的窗口启动逻辑，并以智能指针形式管理其生命周期。
                 */
                auto splashWindow = initializeImHex();
                // Draw the splash window while tasks are running 绘制启动窗口，同时任务正在运行
                if (!splashWindow->loop())
                    ImHexApi::System::impl::addInitArgument("tasks-failed");

                // 处理文件打开请求的逻辑操作
                handleFileOpenRequest();
            }

            {
                // Initialize GLFW
                if (!glfwInit())
                {
                    log::fatal("Failed to initialize GLFW!");
                    std::abort();
                }
                ON_SCOPE_EXIT { glfwTerminate(); };

                // Main window
                {
                    Window window;
                    window.loop();
                }

                deinitializeImHex();
            }
        } while (shouldRestart);

        return EXIT_SUCCESS;
    }

}

#endif