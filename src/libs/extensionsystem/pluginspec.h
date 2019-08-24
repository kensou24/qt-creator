/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of Qt Creator.
**
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 as published by the Free Software
** Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
****************************************************************************/

#pragma once

#include "extensionsystem_global.h"

#include <QString>
#include <QHash>
#include <QVector>

QT_BEGIN_NAMESPACE
class QStringList;
class QRegExp;
QT_END_NAMESPACE

namespace ExtensionSystem {
namespace Internal {
class OptionsParser;
class PluginSpecPrivate;
class PluginManagerPrivate;
} // Internal

class IPlugin;
class PluginView;

/**
 * @brief
 * 如果插件 A 必须在插件 B 加载成功之后才能够加载，那么我们就说，插件 A 依赖于插件 B，插件 B 是插件 A 的被依赖插件。
 * 按照这一的加载模式，最终 Qt Creator 会得到一棵插件树。
 * PluginDependency定义了有关被依赖插件的信息，包括被依赖插件的名字以及版本号等。
 * 我们使用PluginDependency定义所需要的依赖，Qt Creator 则根据我们的定义，利用 Qt 的反射机制，通过名字和版本号获取到插件对应的状态，
 * 从而获知被依赖插件是否加载之类的信息。
 * 值得注意的是，Qt Creator 在匹配版本号时，并不会直接按照这里给出的version值完全匹配，
 * 而是按照一定的算法，选择一段区间内兼容的版本。
 * 这样做的目的是，有些插件升级了版本号之后，另外的插件可以按照版本号兼容，不需要一同升级
 */
struct EXTENSIONSYSTEM_EXPORT PluginDependency
{
  enum Type {
    Required, // 必须
    Optional, // 可选
    Test
  };

  PluginDependency() : type(Required) {}

  QString name;
  QString version;
  Type    type;
  bool    operator==(const PluginDependency& other) const;
  QString toString() const;
};

/**
 * @brief 一个全局函数，用于计算PluginDependency类的散列值。
 * 该函数的作用是允许PluginDependency类作为QHash这样的集合类的键。
 * 按照QHash文档要求，QHash的键必须在其类型所在命名空间中同时提供operator==()以及qHash()函数。
 * @param value
 * @return
 */
uint qHash(const ExtensionSystem::PluginDependency& value);

/**
 * @brief PluginArgumentDescription是一个简单的数据类，用于描述插件参数。
 */
struct EXTENSIONSYSTEM_EXPORT PluginArgumentDescription
{
  QString name;
  QString parameter;
  QString description;
};

class EXTENSIONSYSTEM_EXPORT PluginSpec {
public:

  enum State {
    Invalid,     // 起始点：任何信息都没有读取，甚至连插件元数据都没有读到
    Read,        // 成功读取插件元数据，并且该元数据是合法的；此时，插件的相关信息已经可用
    Resolved,    // 插件描述文件中给出的各个依赖已经被成功找到，这些依赖可以通过dependencySpecs()函数获取
    Loaded,      // 插件的库已经加载，插件实例成功创建；此时插件实例可以通过plugin()函数获取
    Initialized, // 调用插件实例的IPlugin::initialize()函数，并且该函数返回成功
    Running,     // 插件的依赖成功初始化，并且调用了extensionsInitialized()函数；此时，加载过程完毕
    Stopped,     // 插件已经停止，插件的IPlugin::aboutToShutdown()函数被调用
    Deleted      // 插件实例被删除销毁
  };

  ~PluginSpec();

  // information from the xml file, valid after 'Read' state is reached

  /**
   * @brief 一致到url()都是插件的一些基础属性，当状态达到 PluginSpec::Read 时才可用
   * @return
   */
  QString                    name() const;
  QString                    version() const;
  QString                    compatVersion() const;
  QString                    vendor() const;
  QString                    copyright() const;
  QString                    license() const;
  QString                    description() const;
  QString                    url() const;

  /**
   * @brief 插件类别，用于在界面分组显示插件信息。如果插件不属于任何类别，直接返回空字符串。
   * @return
   */
  QString                    category() const;

  /**
   * @brief 插件兼容的平台版本的正则表达式。如果兼容所有平台，则返回空。
   * @return
   */
  QRegExp                    platformSpecification() const;

  /**
   * @brief 对于宿主平台是否可用。该函数用使用 platformSpecification() 的返回值对平台名字进行匹配。
   * @return
   */
  bool                       isAvailableForHostPlatform() const;
  bool                       isRequired() const;
  bool                       isHiddenByDefault() const;
  bool                       isExperimental() const;
  bool                       isEnabledByDefault() const;
  bool                       isEnabledBySettings() const;

  /**
   * @brief 是否在启动时已经加载。
   * @return
   */
  bool                       isEffectivelyEnabled() const;

  /**
   * @brief 因为用户取消或者因其依赖项被取消而导致该插件无法加载时，返回 true。
   * @return
   */
  bool                       isEnabledIndirectly() const;

  /**
   * @brief 是否通过命令行参数 -load 加载。
   * @return
   */
  bool                       isForceEnabled() const;
  bool                       isForceDisabled() const;

  /**
   * @brief 插件依赖列表。当状态达到 PluginSpec::Read 时才可用。
   * @return
   */
  QVector<PluginDependency>  dependencies() const;
  QJsonObject                metaData() const;

  using PluginArgumentDescriptions = QVector<PluginArgumentDescription>;
  PluginArgumentDescriptions argumentDescriptions() const;

  // other information, valid after 'Read' state is reached
  QString                    location() const;
  QString                    filePath() const;

  QStringList                arguments() const;
  void                       setArguments(const QStringList& arguments);
  void                       addArgument(const QString& argument);

  // 当一个依赖需要插件名为 pluginName、版本为 version 时，返回该插件是否满足。
  bool                       provides(const QString& pluginName,
                                      const QString& version) const;

  // dependency specs, valid after 'Resolved' state is reached
  // 插件的依赖。当状态达到 PluginSpec::Resolved 时才可用。
  QHash<PluginDependency, PluginSpec *>dependencySpecs() const;
  bool                                 requiresAny(
    const QSet<PluginSpec *>& plugins) const;

  // linked plugin instance, valid after 'Loaded' state is reached
  IPlugin* plugin() const;

  // state
  State    state() const;
  bool     hasError() const;
  QString  errorString() const;

  void     setEnabledBySettings(bool value);

private:

  /**
   * @brief PluginSpec的构造函数是私有的。
   * 这意味着我们不能创建其实例。
   * 这个类显然不是单例，并且明显没有提供static的工厂函数，那么，我们如何创建其实例呢？
   * 答案就是，我们不能：PluginSpec的实例只能通过 Qt Creator 自身创建，而能够创建的类，就是这里定义的友元类。
   * 这里其实使用了 C++ 语言特性，即友元类可以访问到私有函数。
   * 我们将Internal::PluginManagerPrivate设置为PluginSpec的友元，就可以通过这个类调用PluginSpec私有的构造函数，从而创建其实例。
   * 这一技巧依赖于 C++ 语言特性，不能推广到其它语言，不过如果你使用的正是 C++，那么不妨尝试使用这一技巧，实现一种只能通过系统本身才能实例化的类。
   */
  PluginSpec();

  Internal::PluginSpecPrivate *d;
  friend class PluginView;
  friend class Internal::OptionsParser;
  friend class Internal::PluginManagerPrivate;
  friend class Internal::PluginSpecPrivate;
};
} // namespace ExtensionSystem
