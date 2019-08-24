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

#include <QObject>
#include <QtPlugin>

namespace ExtensionSystem {
namespace Internal {
class IPluginPrivate;
class PluginSpecPrivate;
}

class PluginManager;
class PluginSpec;

/**
 * @brief 插件对象父类
 * IPlugin类是所有插件的基类，每个插件都必须继承这个抽象类，
 * 并实现其中的纯虚函数
 * （这是一个不恰当的命名，原本类名的前缀I代表 interface，但随着版本的迭代，这个类已经变成一个抽象类而不是接口。
 * 像 C++ 这种语言，并不区分 class 与 interface，所以这样带有前缀的名字很容易被人弄混，这是我们自己应该避免的）。
 * Qt Creator 的插件包含两部分：一个描述文件（这个我们之前已经详细介绍过了）和一个至少包含了IPlugin实现的库文件。
 * 在这个库文件中，插件实现的IPlugin类需要与描述文件中的name属性相匹配。
 * 这个实现需要使用标准的 Qt 插件系统暴露给外界，使用Q_PLUGIN_METADATA宏，并且给定 IID
 *为org.qt-project.Qt.QtCreatorPlugin。
 */
class EXTENSIONSYSTEM_EXPORT IPlugin : public QObject {
  Q_OBJECT

public:

  enum ShutdownFlag {
    SynchronousShutdown,
    AsynchronousShutdown
  };

  IPlugin();
  ~IPlugin() override;

  /**
   * @brief 当插件描述文件读取、并且所有依赖都满足之后，插件将开始进行加载。
   * 这一步分为三个阶段：
      1.所有插件的库文件按照依赖树从根到叶子的顺序进行加载。
      2.按照依赖树从根到叶子的顺序依次调用每个插件的IPlugin::initialize()函数。
      3. 按照依赖树从叶子到根的顺序依次调用每个插件的IPlugin::extensionsInitialized()函数。
   * @param arguments
   * @param errorString
   * @return
   */
  virtual bool initialize(const QStringList& arguments,
                          QString           *errorString) = 0;
  virtual void extensionsInitialized()                    = 0;
  virtual bool delayedInitialize() {
    return false;
  }

  /**
   * @brief aboutToShutdown()函数会以插件初始化的相反顺序调用。
   * 该函数应该用于与其它插件断开连接、隐藏所有 UI、优化关闭操作。
   * 如果插件需要延迟真正的关闭，例如，需要等待外部进程执行完毕，以便自己完全关闭，
   * 则应该返回IPlugin::AsynchronousShutdown。
   * 这么做的话会进入主事件循环，等待所有返回了IPlugin::AsynchronousShutdown的插件都发出了asynchronousShutdownFinished()信号之后，
   * 再执行相关操作。
   * 该函数默认实现是不作任何操作，直接返回IPlugin::SynchronousShutdown，即不等待其它插件关闭。
   * @return
   */
  virtual ShutdownFlag aboutToShutdown() {
    return SynchronousShutdown;
  }

  virtual QObject* remoteCommand(const QStringList& /* options */,
                                 const QString& /* workingDirectory */,
                                 const QStringList& /* arguments */) {
    return nullptr;
  }

  virtual QVector<QObject *>createTestObjects() const;

  PluginSpec              * pluginSpec() const;

signals:

  void asynchronousShutdownFinished();

private:

  Internal::IPluginPrivate *d;

  friend class Internal::PluginSpecPrivate;
};
} // namespace ExtensionSystem
