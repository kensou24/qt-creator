#检测qtcreator.pri是否已经应用
!isEmpty(QTCREATOR_PRI_INCLUDED):error("qtcreator.pri already included")
QTCREATOR_PRI_INCLUDED = 1

#指定qtcreator版本名称，设置应用程序
include($$PWD/qtcreator_ide_branding.pri)
!isEmpty(IDE_BRANDING_PRI): include($$IDE_BRANDING_PRI)

PRODUCT_BUNDLE_IDENTIFIER=$${PRODUCT_BUNDLE_ORGANIZATION}.$${IDE_ID}
#这其实是 qmake 定义的变量，当template是app时，用于指定应用程序的版本号；
#当template是lib时，用于指定库的版本号。
#在 Windows 平台，如果没有指定RC_FILE和RES_FILE变量，则会自动生成一个 .rc 文件。
#该文件包含FILEVERSION和PRODUCTVERSION两个字段。
#VERSION应该由主版本号、次版本号、补丁号和构建版本号等组成。
#每一项都是 0 到 65535 之间的整型
VERSION = $$QTCREATOR_VERSION

#指定c++版本
CONFIG += c++14

#定义库名称，如果是debug模式下添加后缀，win下比如libtest在debug下为libtestd
defineReplace(qtLibraryTargetName) {
   unset(LIBRARY_NAME)
   LIBRARY_NAME = $$1
   #CONFIG是一个重要变量，用于指定编译参数
   #CONFIG的赋值顺序非常重要，在一组互斥的值之间（例如 debug 和 release），最后面的会被认为是激活的
   CONFIG(debug, debug|release) {
      #debug_and_release 意味着同时编译 debug 和 release 两个版本
      #build_pass 即构建过程
      !debug_and_release|build_pass {
          #member(variablename, position)是一个替换函数，返回variablename中第position个元素；
          #没有找到的话则返回空串。
          #variablename是必须的，position默认是 0，也就是会返回第一个元素
          mac:RET = $$member(LIBRARY_NAME, 0)_debug
              else:win32:RET = $$member(LIBRARY_NAME, 0)d
      }
   }
   isEmpty(RET):RET = $$LIBRARY_NAME
   return($$RET)
}

#定义库名称，带后缀版本号,win下libtestd，qt版本在4.11.0时则为，libtestd4
#在 Windows 平台，为了避免出现 dll hell，Qt 会自动为生成的 dll 增加版本号
defineReplace(qtLibraryName) {
   RET = $$qtLibraryTargetName($$1)
   win32 {
      VERSION_LIST = $$split(QTCREATOR_VERSION, .)
      RET = $$RET$$first(VERSION_LIST)
   }
   return($$RET)
}

#定义qt最低版本
defineTest(minQtVersion) {
    maj = $$1
    min = $$2
    patch = $$3
    isEqual(QT_MAJOR_VERSION, $$maj) {
        isEqual(QT_MINOR_VERSION, $$min) {
            isEqual(QT_PATCH_VERSION, $$patch) {
                return(true)
            }
            greaterThan(QT_PATCH_VERSION, $$patch) {
                return(true)
            }
        }
        greaterThan(QT_MINOR_VERSION, $$min) {
            return(true)
        }
    }
    greaterThan(QT_MAJOR_VERSION, $$maj) {
        return(true)
    }
    return(false)
}

# For use in custom compilers which just copy files
# OUT_PWD Specifies the full path leading to the directory where qmake places the generated Makefile.
# OUT_PWD也即makefile的路径
# _PRO_FILE_PWD_跟pwd一致
# PWD 使用该变量PWD的文件（.pro 文件或者 .pri 文件）所在目录。
# _PRO_FILE_PWD_	.pro 文件所在目录；即使该变量出现在 .pri 文件，也是指包含该 .pri 文件的 .pro 文件所在目录。
# _PRO_FILE_	.pro 文件完整路径。
# OUT_PWD	生成的 makefile 所在目录。
defineReplace(stripSrcDir) {
    return($$relative_path($$absolute_path($$1, $$OUT_PWD), $$_PRO_FILE_PWD_))
}

darwin:!minQtVersion(5, 7, 0) {
    # Qt 5.6 still sets deployment target 10.7, which does not work
    # with all C++11/14 features (e.g. std::future)
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.8
}

# 设置test
QTC_BUILD_TESTS = $$(QTC_BUILD_TESTS)
!isEmpty(QTC_BUILD_TESTS):TEST = $$QTC_BUILD_TESTS

!isEmpty(BUILD_TESTS):TEST = 1

isEmpty(TEST):CONFIG(debug, debug|release) {
    !debug_and_release|build_pass {
        TEST = 1
    }
}

# 定义dll前缀
isEmpty(IDE_LIBRARY_BASENAME) {
    IDE_LIBRARY_BASENAME = lib
}

#定义单元测试相关
equals(TEST, 1) {
    QT +=testlib
    DEFINES += WITH_TESTS
}

##很有用的方式，获取源码目录以及编译的根目录
#IDE_SOURCE_TREE即源代码所在目录
IDE_SOURCE_TREE = $$PWD
isEmpty(IDE_BUILD_TREE) {
    sub_dir = $$_PRO_FILE_PWD_
    #re_escape Returns the string with every special regular expression character escaped with a backslash
    #转义字符串
    sub_dir ~= s,^$$re_escape($$PWD),,
    #OUT_PWD 目录清理
    #IDE_BUILD_TREE最终得到的是输出根目录
    IDE_BUILD_TREE = $$clean_path($$OUT_PWD)
    IDE_BUILD_TREE ~= s,$$re_escape($$sub_dir)$,,
}

#定义生成exe的(win)的路径
IDE_APP_PATH = $$IDE_BUILD_TREE/bin
osx {
    IDE_APP_TARGET   = "$$IDE_DISPLAY_NAME"

    # check if IDE_BUILD_TREE is actually an existing Qt Creator.app,
    # for building against a binary package
    exists($$IDE_BUILD_TREE/Contents/MacOS/$$IDE_APP_TARGET): IDE_APP_BUNDLE = $$IDE_BUILD_TREE
    else: IDE_APP_BUNDLE = $$IDE_APP_PATH/$${IDE_APP_TARGET}.app

    # set output path if not set manually
    isEmpty(IDE_OUTPUT_PATH): IDE_OUTPUT_PATH = $$IDE_APP_BUNDLE/Contents

    IDE_LIBRARY_PATH = $$IDE_OUTPUT_PATH/Frameworks
    IDE_PLUGIN_PATH  = $$IDE_OUTPUT_PATH/PlugIns
    IDE_LIBEXEC_PATH = $$IDE_OUTPUT_PATH/Resources
    IDE_DATA_PATH    = $$IDE_OUTPUT_PATH/Resources
    IDE_DOC_PATH     = $$IDE_DATA_PATH/doc
    IDE_BIN_PATH     = $$IDE_OUTPUT_PATH/MacOS
    copydata = 1

    LINK_LIBRARY_PATH = $$IDE_APP_BUNDLE/Contents/Frameworks
    LINK_PLUGIN_PATH  = $$IDE_APP_BUNDLE/Contents/PlugIns

    INSTALL_LIBRARY_PATH = $$QTC_PREFIX/$${IDE_APP_TARGET}.app/Contents/Frameworks
    INSTALL_PLUGIN_PATH  = $$QTC_PREFIX/$${IDE_APP_TARGET}.app/Contents/PlugIns
    INSTALL_LIBEXEC_PATH = $$QTC_PREFIX/$${IDE_APP_TARGET}.app/Contents/Resources
    INSTALL_DATA_PATH    = $$QTC_PREFIX/$${IDE_APP_TARGET}.app/Contents/Resources
    INSTALL_DOC_PATH     = $$INSTALL_DATA_PATH/doc
    INSTALL_BIN_PATH     = $$QTC_PREFIX/$${IDE_APP_TARGET}.app/Contents/MacOS
    INSTALL_APP_PATH     = $$QTC_PREFIX/
} else {
    contains(TEMPLATE, vc.*):vcproj = 1
    IDE_APP_TARGET   = $$IDE_ID

    # target output path if not set manually
    isEmpty(IDE_OUTPUT_PATH): IDE_OUTPUT_PATH = $$IDE_BUILD_TREE

    #定义生成lib的路径
    IDE_LIBRARY_PATH = $$IDE_OUTPUT_PATH/$$IDE_LIBRARY_BASENAME/qtcreator
    #定义生成插件plugin的路径
    IDE_PLUGIN_PATH  = $$IDE_LIBRARY_PATH/plugins
    #data目录
    IDE_DATA_PATH    = $$IDE_OUTPUT_PATH/share/qtcreator
    IDE_DOC_PATH     = $$IDE_OUTPUT_PATH/share/doc/qtcreator
    #bin目录
    IDE_BIN_PATH     = $$IDE_OUTPUT_PATH/bin
    win32: \
        IDE_LIBEXEC_PATH = $$IDE_OUTPUT_PATH/bin
    else: \
        IDE_LIBEXEC_PATH = $$IDE_OUTPUT_PATH/libexec/qtcreator
    !isEqual(IDE_SOURCE_TREE, $$IDE_OUTPUT_PATH):copydata = 1

    #qtcreator路径
    LINK_LIBRARY_PATH = $$IDE_BUILD_TREE/$$IDE_LIBRARY_BASENAME/qtcreator
    #plugin路径
    LINK_PLUGIN_PATH  = $$LINK_LIBRARY_PATH/plugins

    INSTALL_LIBRARY_PATH = $$QTC_PREFIX/$$IDE_LIBRARY_BASENAME/qtcreator
    INSTALL_PLUGIN_PATH  = $$INSTALL_LIBRARY_PATH/plugins
    win32: \
        INSTALL_LIBEXEC_PATH = $$QTC_PREFIX/bin
    else: \
        INSTALL_LIBEXEC_PATH = $$QTC_PREFIX/libexec/qtcreator
    INSTALL_DATA_PATH    = $$QTC_PREFIX/share/qtcreator
    INSTALL_DOC_PATH     = $$QTC_PREFIX/share/doc/qtcreator
    INSTALL_BIN_PATH     = $$QTC_PREFIX/bin
    INSTALL_APP_PATH     = $$QTC_PREFIX/bin
}

gcc:!clang: QMAKE_CXXFLAGS += -Wno-noexcept-type

#获取相对路径，传递给程序
RELATIVE_PLUGIN_PATH = $$relative_path($$IDE_PLUGIN_PATH, $$IDE_BIN_PATH)
RELATIVE_LIBEXEC_PATH = $$relative_path($$IDE_LIBEXEC_PATH, $$IDE_BIN_PATH)
RELATIVE_DATA_PATH = $$relative_path($$IDE_DATA_PATH, $$IDE_BIN_PATH)
RELATIVE_DOC_PATH = $$relative_path($$IDE_DOC_PATH, $$IDE_BIN_PATH)
DEFINES += $$shell_quote(RELATIVE_PLUGIN_PATH=\"$$RELATIVE_PLUGIN_PATH\")
DEFINES += $$shell_quote(RELATIVE_LIBEXEC_PATH=\"$$RELATIVE_LIBEXEC_PATH\")
DEFINES += $$shell_quote(RELATIVE_DATA_PATH=\"$$RELATIVE_DATA_PATH\")
DEFINES += $$shell_quote(RELATIVE_DOC_PATH=\"$$RELATIVE_DOC_PATH\")

INCLUDEPATH += \
    #Qt Creator 会在每次编译时自动生成一个 app_version.h，
    #包含 Qt Creator 的版本信息（每次自动更新构建版本号，具体生成过程会在后文详细介绍），
    #所有自动生成的代码文件都会出现在$$IDE_BUILD_TREE/src
    $$IDE_BUILD_TREE/src \ # for <app/app_version.h> in case of actual build directory
    $$IDE_SOURCE_TREE/src \ # for <app/app_version.h> in case of binary package with dev package
    $$IDE_SOURCE_TREE/src/libs \
    $$IDE_SOURCE_TREE/tools

#+=运算符，有的是*=运算符。前者是追加；后者是没有则追加，有则不作操作，也就是保持存在且唯一
win32:exists($$IDE_SOURCE_TREE/lib/qtcreator) {
    # for .lib in case of binary package with dev package
    LIBS *= -L$$IDE_SOURCE_TREE/lib/qtcreator
    LIBS *= -L$$IDE_SOURCE_TREE/lib/qtcreator/plugins
}

#从环境变量中获取qtcreator的plugins的目录
QTC_PLUGIN_DIRS_FROM_ENVIRONMENT = $$(QTC_PLUGIN_DIRS)
QTC_PLUGIN_DIRS += $$split(QTC_PLUGIN_DIRS_FROM_ENVIRONMENT, $$QMAKE_DIRLIST_SEP)
QTC_PLUGIN_DIRS += $$IDE_SOURCE_TREE/src/plugins
for(dir, QTC_PLUGIN_DIRS) {
    INCLUDEPATH += $$dir
}

QTC_LIB_DIRS_FROM_ENVIRONMENT = $$(QTC_LIB_DIRS)
QTC_LIB_DIRS += $$split(QTC_LIB_DIRS_FROM_ENVIRONMENT, $$QMAKE_DIRLIST_SEP)
QTC_LIB_DIRS += $$IDE_SOURCE_TREE/src/libs
QTC_LIB_DIRS += $$IDE_SOURCE_TREE/src/libs/3rdparty
for(dir, QTC_LIB_DIRS) {
    INCLUDEPATH += $$dir
}

CONFIG += \
    depend_includepath \  #Appending the value of INCLUDEPATH to DEPENDPATH is enabled. Set by default
    no_include_pwd

LIBS *= -L$$LINK_LIBRARY_PATH  # Qt Creator libraries
exists($$IDE_LIBRARY_PATH): LIBS *= -L$$IDE_LIBRARY_PATH  # library path from output path

!isEmpty(vcproj) {
    DEFINES += IDE_LIBRARY_BASENAME=\"$$IDE_LIBRARY_BASENAME\"
} else {
    DEFINES += IDE_LIBRARY_BASENAME=\\\"$$IDE_LIBRARY_BASENAME\\\"
}

DEFINES += \
    QT_CREATOR \
    QT_NO_JAVA_STYLE_ITERATORS \
    QT_NO_CAST_TO_ASCII \  #Disables automatic conversions from 8-bit strings (char *) to unicode QStrings
    QT_RESTRICTED_CAST_FROM_ASCII \
    QT_DISABLE_DEPRECATED_BEFORE=0x050900 \ #This macro can be defined in the project file to disable functions deprecated in a specified version of Qt or any earlier version
    QT_USE_FAST_OPERATOR_PLUS \
    QT_USE_FAST_CONCATENATION

unix {
    CONFIG(debug, debug|release):OBJECTS_DIR = $${OUT_PWD}/.obj/debug-shared
    CONFIG(release, debug|release):OBJECTS_DIR = $${OUT_PWD}/.obj/release-shared

    CONFIG(debug, debug|release):MOC_DIR = $${OUT_PWD}/.moc/debug-shared
    CONFIG(release, debug|release):MOC_DIR = $${OUT_PWD}/.moc/release-shared

    RCC_DIR = $${OUT_PWD}/.rcc
    UI_DIR = $${OUT_PWD}/.uic
}

msvc {
    #Don't warn about sprintf, fopen etc being 'unsafe'
    DEFINES += _CRT_SECURE_NO_WARNINGS
    QMAKE_CXXFLAGS_WARN_ON *= -w44996
    # Speed up startup time when debugging with cdb
    QMAKE_LFLAGS_DEBUG += /INCREMENTAL:NO
}

qt {
    contains(QT, core): QT += concurrent
    contains(QT, gui): QT += widgets
}

QBSFILE = $$replace(_PRO_FILE_, \\.pro$, .qbs)
exists($$QBSFILE):DISTFILES += $$QBSFILE

!isEmpty(QTC_PLUGIN_DEPENDS) {
    LIBS *= -L$$IDE_PLUGIN_PATH  # plugin path from output directory
    LIBS *= -L$$LINK_PLUGIN_PATH  # when output path is different from Qt Creator build directory
}

# recursively resolve plugin deps
#允许用户在编译时直接通过QTC_PLUGIN_DEPENDS指定插件依赖
done_plugins =
for(ever) {
    isEmpty(QTC_PLUGIN_DEPENDS): \
        break()
    done_plugins += $$QTC_PLUGIN_DEPENDS
    for(dep, QTC_PLUGIN_DEPENDS) {
        dependencies_file =
        for(dir, QTC_PLUGIN_DIRS) {
            exists($$dir/$$dep/$${dep}_dependencies.pri) {
                dependencies_file = $$dir/$$dep/$${dep}_dependencies.pri
                break()
            }
        }
        isEmpty(dependencies_file): \
            error("Plugin dependency $$dep not found")
        include($$dependencies_file)
        LIBS += -l$$qtLibraryName($$QTC_PLUGIN_NAME)
    }
    #使用-=运算符移除每次处理的依赖
    QTC_PLUGIN_DEPENDS = $$unique(QTC_PLUGIN_DEPENDS)
    QTC_PLUGIN_DEPENDS -= $$unique(done_plugins)
}

# recursively resolve library deps
done_libs =
for(ever) {
    isEmpty(QTC_LIB_DEPENDS): \
        break()
    done_libs += $$QTC_LIB_DEPENDS
    for(dep, QTC_LIB_DEPENDS) {
        dependencies_file =
        for(dir, QTC_LIB_DIRS) {
            exists($$dir/$$dep/$${dep}_dependencies.pri) {
                dependencies_file = $$dir/$$dep/$${dep}_dependencies.pri
                break()
            }
        }
        isEmpty(dependencies_file): \
            error("Library dependency $$dep not found")
        include($$dependencies_file)
        LIBS += -l$$qtLibraryName($$QTC_LIB_NAME)
    }
    QTC_LIB_DEPENDS = $$unique(QTC_LIB_DEPENDS)
    QTC_LIB_DEPENDS -= $$unique(done_libs)
}
