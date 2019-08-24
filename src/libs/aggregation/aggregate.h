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

#include "aggregation_global.h"

#include <QObject>
#include <QList>
#include <QHash>
#include <QReadWriteLock>
#include <QReadLocker>

namespace Aggregation {
// Aggregation ::Aggregate将多个相关组件定义为一个聚合体，从而使外界可以将这些组件视为一个整体
class AGGREGATION_EXPORT Aggregate : public QObject {
  Q_OBJECT

public:

  Aggregate(QObject *parent = nullptr);
  ~Aggregate() override;

  void                   add(QObject *component);
  void                   remove(QObject *component);

  // 转换成内部对象数据
  template<typename T>T* component() {
    QReadLocker locker(&lock());

    foreach(QObject * component, m_components) {
      if (T *result = qobject_cast<T *>(component)) return result;
    }
    return nullptr;
  }

  // 转换成内部对象列表数据
  template<typename T>QList<T *>components() {
    QReadLocker locker(&lock());
    QList<T *>  results;

    foreach(QObject * component, m_components) {
      if (T *result = qobject_cast<T *>(component)) {
        results << result;
      }
    }
    return results;
  }

  static Aggregate     * parentAggregate(QObject *obj);
  static QReadWriteLock& lock();

signals:

  void changed();

private:

  void deleteSelf(QObject *obj);

  // 所有Aggregate共享一个散列，起到统一注册管理的作用，无需引入第三个管理类来管理这些Aggregate
  // 记录了各个object对象多属于的Aggregate类
  static QHash<QObject *, Aggregate *>& aggregateMap();

  // 记录当前Aggregate对象中关联的数据项
  QList<QObject *>m_components;
};

// get a component via global template function
template<typename T>T* query(Aggregate *obj)
{
  if (!obj) return nullptr;

  // 调用 Aggregate返回数据
  return obj->template component<T>();
}

// query()用于将obj对象转换成所需要的类型。
// 首先，它会尝试使用qobject_cast进行转换，如果转换成功则直接返回，
// 否则会查询其是否存在于某个Aggregate对象，如果是，则从该对象继续尝试查询
template<typename T>T* query(QObject *obj)
{
  if (!obj) return nullptr;

  T *result = qobject_cast<T *>(obj);

  // 直接转换失败时，查找所属Aggregate对象进行转换，也即只要对象注册到Aggregate对象了
  // 就可以进行对象的转换，而不需要实际继承于待转换的对象
  if (!result) {
    QReadLocker locker(&Aggregate::lock());
    Aggregate  *parentAggregation = Aggregate::parentAggregate(obj);
    result = (parentAggregation ? query<T>(parentAggregation) : nullptr);
  }
  return result;
}

// get all components of a specific type via template function
template<typename T>QList<T *>query_all(Aggregate *obj)
{
  if (!obj) return QList<T *>();

  return obj->template components<T>();
}

template<typename T>QList<T *>query_all(QObject *obj)
{
  if (!obj) return QList<T *>();

  QReadLocker locker(&Aggregate::lock());
  Aggregate  *parentAggregation = Aggregate::parentAggregate(obj);
  QList<T *>  results;

  if (parentAggregation) results = query_all<T>(parentAggregation);
  else if (T *result = qobject_cast<T *>(obj)) results.append(result);
  return results;
}
} // namespace Aggregation
