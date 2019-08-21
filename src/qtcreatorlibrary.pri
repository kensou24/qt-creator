#用于lib生成的pri文件
# 例如，_PRO_FILE_PWD_的值是E:/Sources/qt-creator/src/libs/aggregation，
# 匹配[^/]+$的部分是aggregation，
# 使用()则将该字符串捕获到\1，
# 最后的\\1/\\1_dependencies.pri部分最终结果是aggregation/aggregation_dependencies.pri。
# $$replace()函数替换之后的结果是E:/Sources/qt-creator/src/libs/aggregation/aggregation_dependencies.pri。
include($$replace(_PRO_FILE_PWD_, ([^/]+$), \\1/\\1_dependencies.pri))

#QTC_LIB_NAME正是在 aggregation_dependencies.pri 中定义的
TARGET = $$QTC_LIB_NAME

include(../qtcreator.pri)

# use precompiled header for libraries by default
isEmpty(PRECOMPILED_HEADER):PRECOMPILED_HEADER = $$PWD/shared/qtcreator_pch.h

win32 {
    DLLDESTDIR = $$IDE_APP_PATH
}

DESTDIR = $$IDE_LIBRARY_PATH

osx {
    QMAKE_LFLAGS_SONAME = -Wl,-install_name,@rpath/Frameworks/
    QMAKE_LFLAGS += -compatibility_version $$QTCREATOR_COMPAT_VERSION
}
include(rpath.pri)

#添加后缀以及版本
TARGET = $$qtLibraryTargetName($$TARGET)

TEMPLATE = lib
CONFIG += shared dll

contains(QT_CONFIG, reduce_exports):CONFIG += hide_symbols

win32 {
    dlltarget.path = $$INSTALL_BIN_PATH
    INSTALLS += dlltarget
} else {
    target.path = $$INSTALL_LIBRARY_PATH
    INSTALLS += target
}
