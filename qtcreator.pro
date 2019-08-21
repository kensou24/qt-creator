#pri文件
#pri 文件可以理解为 pro 文件片段，可以使用include操作符将其引入一个 pro 文件。
#qmake 会自动处理引用操作，类似于将 pri 文件的全部内容复制到include语句处。
#这与 C++ 的#include指令类似。
#这里的处理是线性的，也就是 qmake 会从上向下进行解析。
#因此，如果你在 pri 中定义了一个函数，那么必须在include语句之后才能正常使用该函数。
#tips:即便你的所有文件都在同一个目录下，你也可以使用 pri 文件创建出来多个虚拟目录节点。这样的项目结构看起来会清晰很多。
include(qtcreator.pri)

#version check qt
!minQtVersion(5, 11, 0) {
    #message()是 qmake 预定义的函数，类似于qDebug()，可以在控制台输出一段文本
    #字符串最后的$${QT_VERSION}是占位符，会使用QT_VERSION变量的内容进行替换。这一操作被称为变量展开（variable expansion）
    message("Cannot build $$IDE_DISPLAY_NAME with Qt version $${QT_VERSION}.")
    error("Use at least Qt 5.11.0.")
}

include(doc/doc.pri)

#subdirs：创建依次构建子目录中文件的 Makefile。子目录使用SUBDIRS变量指定。
#按照SUBDIRS书写顺序来编译
TEMPLATE  = subdirs
CONFIG   += ordered

SUBDIRS = src share
unix:!macx:!isEmpty(copydata):SUBDIRS += bin
!isEmpty(BUILD_TESTS):SUBDIRS += tests

#DISTFILES知道需要在最终的目标包括的文件
# $$files(*) 按照正则进行文件名匹配
DISTFILES += dist/copyright_template.txt \
    README.md \
    $$files(dist/changes-*) \
    qtcreator.qbs \
    $$files(qbs/*, true) \
    $$files(scripts/*.py) \
    $$files(scripts/*.sh) \
    $$files(scripts/*.pl)

exists(src/shared/qbs/qbs.pro) {
    # Make sure the qbs dll ends up alongside the Creator executable.
    QBS_DLLDESTDIR = $${IDE_BUILD_TREE}/bin
    cache(QBS_DLLDESTDIR)
    QBS_DESTDIR = $${IDE_LIBRARY_PATH}
    cache(QBS_DESTDIR)
    QBSLIBDIR = $${IDE_LIBRARY_PATH}
    cache(QBSLIBDIR)
    QBS_INSTALL_PREFIX = $${QTC_PREFIX}
    cache(QBS_INSTALL_PREFIX)
    QBS_LIB_INSTALL_DIR = $$INSTALL_LIBRARY_PATH
    cache(QBS_LIB_INSTALL_DIR)
    QBS_RESOURCES_BUILD_DIR = $${IDE_DATA_PATH}/qbs
    cache(QBS_RESOURCES_BUILD_DIR)
    QBS_RESOURCES_INSTALL_DIR = $$INSTALL_DATA_PATH/qbs
    cache(QBS_RESOURCES_INSTALL_DIR)
    macx {
        QBS_PLUGINS_BUILD_DIR = $${IDE_PLUGIN_PATH}
        QBS_APPS_RPATH_DIR = @loader_path/../Frameworks
    } else {
        QBS_PLUGINS_BUILD_DIR = $$IDE_PLUGIN_PATH
        QBS_APPS_RPATH_DIR = \$\$ORIGIN/../$$IDE_LIBRARY_BASENAME/qtcreator
    }
    cache(QBS_PLUGINS_BUILD_DIR)
    cache(QBS_APPS_RPATH_DIR)
    QBS_PLUGINS_INSTALL_DIR = $$INSTALL_PLUGIN_PATH
    cache(QBS_PLUGINS_INSTALL_DIR)
    QBS_LIBRARY_DIRNAME = $${IDE_LIBRARY_BASENAME}
    cache(QBS_LIBRARY_DIRNAME)
    QBS_APPS_DESTDIR = $${IDE_BIN_PATH}
    cache(QBS_APPS_DESTDIR)
    QBS_APPS_INSTALL_DIR = $$INSTALL_BIN_PATH
    cache(QBS_APPS_INSTALL_DIR)
    QBS_LIBEXEC_DESTDIR = $${IDE_LIBEXEC_PATH}
    cache(QBS_LIBEXEC_DESTDIR)
    QBS_LIBEXEC_INSTALL_DIR = $$INSTALL_LIBEXEC_PATH
    cache(QBS_LIBEXEC_INSTALL_DIR)
    QBS_RELATIVE_LIBEXEC_PATH = $$relative_path($$QBS_LIBEXEC_DESTDIR, $$QBS_APPS_DESTDIR)
    isEmpty(QBS_RELATIVE_LIBEXEC_PATH):QBS_RELATIVE_LIBEXEC_PATH = .
    cache(QBS_RELATIVE_LIBEXEC_PATH)
    QBS_RELATIVE_PLUGINS_PATH = $$relative_path($$QBS_PLUGINS_BUILD_DIR, $$QBS_APPS_DESTDIR$$)
    cache(QBS_RELATIVE_PLUGINS_PATH)
    QBS_RELATIVE_SEARCH_PATH = $$relative_path($$QBS_RESOURCES_BUILD_DIR, $$QBS_APPS_DESTDIR)
    cache(QBS_RELATIVE_SEARCH_PATH)
    !qbs_no_dev_install {
        QBS_CONFIG_ADDITION = qbs_no_dev_install qbs_enable_project_file_updates
        cache(CONFIG, add, QBS_CONFIG_ADDITION)
    }

    # Create qbs documentation targets.
    DOC_FILES =
    DOC_TARGET_PREFIX = qbs_
    include(src/shared/qbs/doc/doc_shared.pri)
    include(src/shared/qbs/doc/doc_targets.pri)
    docs.depends += qbs_docs
    !build_online_docs {
        install_docs.depends += install_qbs_docs
    }
    unset(DOC_FILES)
    unset(DOC_TARGET_PREFIX)
}

#QT_ARCH并没有使用$$运算符。因为在使用该函数时，第一个参数是变量名，函数会自己取该变量名的实际值
contains(QT_ARCH, i386): ARCHITECTURE = x86
else: ARCHITECTURE = $$QT_ARCH
message($$QT_ARCH)

macx: PLATFORM = "mac"
else:win32: PLATFORM = "windows"
else:linux-*: PLATFORM = "linux-$${ARCHITECTURE}"
else: PLATFORM = "unknown"

#生成basename
BASENAME = $$(INSTALL_BASENAME)
isEmpty(BASENAME): BASENAME = qt-creator-$${PLATFORM}$(INSTALL_EDITION)-$${QTCREATOR_VERSION}$(INSTALL_POSTFIX)
message($$BASENAME)
linux {
    appstream.files = dist/org.qt-project.qtcreator.appdata.xml
    appstream.path = $$QTC_PREFIX/share/metainfo/

    desktop.files = dist/org.qt-project.qtcreator.desktop
    desktop.path = $$QTC_PREFIX/share/applications/

    INSTALLS += appstream desktop
}

macx {
    APPBUNDLE = "$$OUT_PWD/bin/$${IDE_APP_TARGET}.app"
    BINDIST_SOURCE.release = "$$OUT_PWD/bin/$${IDE_APP_TARGET}.app"
    BINDIST_SOURCE.debug = "$$OUT_PWD/bin"
    BINDIST_EXCLUDE_ARG.debug = "--exclude-toplevel"
    deployqt.commands = $$PWD/scripts/deployqtHelper_mac.sh \"$${APPBUNDLE}\" \"$$[QT_INSTALL_BINS]\" \"$$[QT_INSTALL_TRANSLATIONS]\" \"$$[QT_INSTALL_PLUGINS]\" \"$$[QT_INSTALL_IMPORTS]\" \"$$[QT_INSTALL_QML]\"
    codesign.commands = codesign --deep -s \"$(SIGNING_IDENTITY)\" $(SIGNING_FLAGS) \"$${APPBUNDLE}\"
    dmg.commands = python -u \"$$PWD/scripts/makedmg.py\" \"$${BASENAME}.dmg\" \"Qt Creator\" \"$$IDE_SOURCE_TREE\" \"$$OUT_PWD/bin\"
    #dmg.depends = deployqt
    QMAKE_EXTRA_TARGETS += codesign dmg
} else {
    #$$OUT_PWD是 qmake 生成的 Makefile 所在的文件夹。
    #$$[]。这是取 qmake 的属性,设置qmake -set PROPERTY VALUE，查询qmake -query PROPERTY
    BINDIST_SOURCE.release = "$(INSTALL_ROOT)$$QTC_PREFIX"
    BINDIST_EXCLUDE_ARG.release = "--exclude-toplevel"
    BINDIST_SOURCE.debug = $${BINDIST_SOURCE.release}
    BINDIST_EXCLUDE_ARG.debug = $${BINDIST_EXCLUDE_ARG.release}
    deployqt.commands = python -u $$PWD/scripts/deployqt.py -i \"$(INSTALL_ROOT)$$QTC_PREFIX/bin/$${IDE_APP_TARGET}\" \"$(QMAKE)\"
    deployqt.depends = install
    win32:!isEmpty(BINARY_ARTIFACTS_BRANCH) {
        deployartifacts.depends = install
        deployartifacts.commands = git clone --depth 1 -b $$BINARY_ARTIFACTS_BRANCH \
                "http://code.qt.io/qt-creator/binary-artifacts.git" \
            && xcopy /s /q /y /i "binary-artifacts\\win32" \"$(INSTALL_ROOT)$$QTC_PREFIX\" \
            && rmdir /s /q binary-artifacts
        QMAKE_EXTRA_TARGETS += deployartifacts
    }
}

INSTALLER_ARCHIVE_FROM_ENV = $$(INSTALLER_ARCHIVE)
isEmpty(INSTALLER_ARCHIVE_FROM_ENV) {
    INSTALLER_ARCHIVE = $$OUT_PWD/$${BASENAME}-installer-archive.7z
} else {
    INSTALLER_ARCHIVE = $$OUT_PWD/$$(INSTALLER_ARCHIVE)
}

INSTALLER_ARCHIVE_DEBUG = $$INSTALLER_ARCHIVE
INSTALLER_ARCHIVE_DEBUG ~= s/(.*)[.]7z/\1-debug.7z

bindist.commands = python -u $$PWD/scripts/createDistPackage.py $$OUT_PWD/$${BASENAME}.7z \"$${BINDIST_SOURCE.release}\"
bindist_installer.commands = python -u $$PWD/scripts/createDistPackage.py $${BINDIST_EXCLUDE_ARG.release} $${INSTALLER_ARCHIVE} \"$${BINDIST_SOURCE.release}\"
bindist_debug.commands = python -u $$PWD/scripts/createDistPackage.py --debug $${BINDIST_EXCLUDE_ARG.debug} $${INSTALLER_ARCHIVE_DEBUG} \"$${BINDIST_SOURCE.debug}\"

win32 {
    #将输入字符串中的 / 全部替换为 \。这是适配命令路径中，Unix 的 / 和 Windows 的 \
    deployqt.commands ~= s,/,\\\\,g
    bindist.commands ~= s,/,\\\\,g
    bindist_installer.commands ~= s,/,\\\\,g
}

deployqt.CONFIG += recursive
deployqt.recurse = src

#一个常见的任务是，在编译完成之后，将预置的配置文件复制到特定目录。
#这种目标可以通过类似的语法进行定义，然后将定义好的目标添加到QMAKE_EXTRA_TARGETS。
#当 qmake 运行完毕后，会接着执行这些目标，直到编译成功。
QMAKE_EXTRA_TARGETS += deployqt bindist bindist_installer bindist_debug
