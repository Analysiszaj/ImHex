#include <hex.hpp>

#include <clocale>

#include <hex/helpers/logger.hpp>

#include <window.hpp>
#include <messaging.hpp>

#include "crash_handlers.hpp"

#include <hex/api/task_manager.hpp>
#include <hex/api/plugin_manager.hpp>

namespace hex::init
{

    int runImHex();
    void runCommandLine(int argc, char **argv);

}
/**
 * @brief Main entry point of ImHex
 * @param argc Argument count
 * @param argv Argument values
 * @return Exit code
 */
int main(int argc, char **argv)
{
    using namespace hex;

    std::setlocale(LC_ALL, "en_US.utf8");

    // Set the main thread's name to "Main"  设置主线程的名称为"Main"
    TaskManager::setCurrentThreadName("Main");

    // Setup crash handlers right away to catch crashes as early as possible   初始化崩溃处理程序，以尽早捕获崩溃
    crash::setupCrashHandlers();

    // Run platform-specific initialization code  运行平台特定的初始化代码
    Window::initNative();

    // Setup messaging system to allow sending commands to the main ImHex instance  设置消息系统以允许向主ImHex实例发送命令
    hex::messaging::setupMessaging();

    // Handle command line arguments if any have been passed  处理命令行参数（如果有传递）
    if (argc > 1)
    {
        init::runCommandLine(argc, argv);
    }

    // Log some system information to aid debugging when users share their logs  记录一些系统信息以帮助调试用户共享日志时
    log::info("Welcome to ImHex {}!", ImHexApi::System::getImHexVersion().get());
    log::info("Compiled using commit {}@{}", ImHexApi::System::getCommitBranch(), ImHexApi::System::getCommitHash());
    log::info("Running on {} {} ({})", ImHexApi::System::getOSName(), ImHexApi::System::getOSVersion(), ImHexApi::System::getArchitecture());

#if defined(OS_LINUX)
    if (auto distro = ImHexApi::System::getLinuxDistro(); distro.has_value())
    {
        log::info("Linux distribution: {}. Version: {}", distro->name, distro->version == "" ? "None" : distro->version);
    }
#endif

    // Run ImHex
    return init::runImHex();
}
