#pragma once

#include <hex/api/event_manager.hpp>

/* Provider requests definitions */
namespace hex
{

    /**
     * @brief Creates a provider from its unlocalized name, and add it to the provider list 从其未本地化的名称创建提供程序，并将其添加到提供程序列表
     */
    EVENT_DEF(RequestCreateProvider, std::string, bool, bool, hex::prv::Provider **);

    /**
     * @brief Move the data from all PerProvider instances from one provider to another 将一个提供程序的所有 PerProvider 实例的数据移动到另一个提供程序
     *
     * The 'from' provider should not have any per provider data after this, and should be immediately deleted
     *
     * FIXME: rename with the "Request" prefix to apply standard naming convention.
     */
    EVENT_DEF(MovePerProviderData, prv::Provider *, prv::Provider *);

}
