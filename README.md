[中文](#Chinese)  [English](#English)

# <a id="Chinese" style="color: inherit">PKG.cmake</a>

简化项目安装过程中的大量代码，使用单个函数封装一些导出和安装操作，以方便构建安装单个项目或多组件项目。

*本模块目前属于测试阶段，不建议在正式项目中使用。*



## 使用方法

最简单的构建安装库示例：

```cmake
PKG(
  _NAME PKG_lib
  _INCLUDE_DIRS "include/"
)
```

接下来进行编译并安装：

```cmake
mkdir build
cd build
cmake ..
make -j8
make install
```

执行库安装后，可以通过 `find_package()` 在其他项目中查找 `PKG_lib` 库：

```cmake
find_package(PKG_lib REQUIRED)
```
怎么样，是不是很简单？

那么我们再来看看怎么构建安装可执行文件（即不要 `include` 和 `lib` ）↓

简单的构建安装可执行文件示例：

```cmake
PKG(
  _NAME PKG_exe
  _MODE Runtime
  _INSTALL_BIN_DIR "."    # Windows系统适用：默认可执行文件安装在安装目录的bin目录，该代码可以使可执行文件安装到安装目录根目录上
  _DISABLE_INTERFACE
  _DISABLE_CONFIG
  _DISABLE_VERSION
)
```

当然，自定义版本号也是一个关键字（如果未定义，函数将从 `_NAME` 的属性 `VERSION` 获取，如果获取失败，则忽略版本控制，即不生成 `*-config-version.cmake` 文件）。选项 `_DISABLE_VERSION` 表示在任何情况下都不生成  `*-config-version.cmake` 文件。

编译安装后，你就会神奇的发现，它安装到了 `C:\Program Files (x86)\PKG_exe` 目录中（Windows系统下），当然这个安装目录是可以修改的，以上例子只是简单的介绍基本功能。

一个较为完整的动态库封包示例：

```cmake
cmake_minimum_required(VERSION 3.20)
project(PKG_shared VERSION 1.2.3.4)

add_library(PKG_shared SHARED)
add_library(PKGNS::PKG_shared ALIAS PKG_shared)
set_target_properties(
  PKG_shared PROPERTIES
  VERSION 1.2.3.4
  #SOVERSION 1.2
  DEFINE_SYMBOL "${COMPONENT_NAME}_EXPORTS"
  MSVC_RUNTIME_LIBRARY "${MSVC_RUNTIME_LIB}"
)

include(cmake/PKG.cmake)
PKG(
  _NAME "PKG_shared"
  #_VERSION 1.2.3.4         # 因为PKG_shared已经定义了VERSION属性，这句就免了
  _DEBUG_POSTFIX "d"        # 相当于‘set_target_properties(PKG_shared PROPERTIES DEBUG_POSTFIX "d")’
  _NAMESPACE "PKGNS"
  _DEPENDENCIES "Soci" "Boost@1.71:python,thread,system"
  _EXPORT_EXT_DIRS_1 "resources" "."
  _INSTALL_EXT_DIRS_1 "doc/" "doc"
  _INCLUDE_DIRS "include/"
  _INCLUDE_EXCLUDE_REG ".*\\.(svn|h\\.in|hpp\\.in)$"
  _INCLUDE_DESTINATION "include/${PROJECT_NAME}-1.2.3.4"
  _EXPORT_HEADER "comm1_export.h"        # 相对于CMAKE_CURRENT_BINARY_DIR
  _INSTALL_PDB              # 仅MSVC有效
  #_ADD_LIB_SUFFIX          # 如果在64位计算机上，_BINARY_LIB_DIR和_INSTALL_LIB_DIR的值将添加后缀'64'
  _ADD_UNINSTALL
)

target_sources(
  PKG_shared PRIVATE "src/add.cpp"
)

target_include_directories(
  PKG_shared PRIVATE
  "include"
  "${PKG_PKG_shared_EXPORT_HEADER_DIR}"
)
```

如果要打包多组件项目，此脚本将为您提供极大的便利。该功能提供两个特殊选项： `_IS_COMPONENT` 和 `_IS_COMPONENTS`。`_IS_COMPONENT` 指定当前 `_NAME` 目标是项目的一个组件，则此组件将附属于 `_PROJECT` 项目，`_PROJECT` 在定义 `_IS_COMPONENT` 参数时就默认为 `PROJECT_NAME`。`_PROJECT` 可以定制。

###### 一个麻雀虽小五脏俱全的多组件项目封包示例

主项目部分：
```cmake
project(PKG VERSION 0.0.1)

# Its components also set this value to the default value of their _INSTALL_DIR, unless custom _INSTALL_DIR
set(PKG_PKG_INSTALL_DIR "/home/pkg/pkg_install")

add_subdirectory(component)

# Called after all child components
PKG(
  _IS_COMPONENTS
  _NAME ${PROJECT_NAME}
  _VERSION 0.0.1
  #_INCLUDE_DIRS "macro"             # 在这里，您可以将其他include目录添加到 _INCLUDE_DESTINATION 指定的路径中
  _INCLUDE_FILES "macro/global.h" "macro/macro.h"    #  结果同上，只是这里是针对文件而不是目录
  _INCLUDE_EXCLUDE_REG ".*\\.(svn|h\\.in|hpp\\.in)$"
  #_INCLUDE_DESTINATION "include"    # _INCLUDE_DESTINATION 的值默认为 _INSTALL_INCLUDE_DIR，也就是 "include"
  _SHARED_LIBS
  _ADD_UNINSTALL
)
```
组件部分：
```cmake
add_library(component SHARED)
PKG(
  _IS_COMPONENT
  _NAME component
  _PROJECT PKG
  _NAMESPACE "${PROJECT_NAME}"
  _DEBUG_POSTFIX "d"
  _INCLUDE_DIRS "include/"
  _INCLUDE_EXCLUDE_REG ".*\\.(svn|h\\.in|hpp\\.in)$"
  _INCLUDE_DESTINATION "include/${PROJECT_NAME}"
  _EXPORT_HEADER "include/component_export.h"    # 将定义 PKG_PKG_component_EXPORT_HEADER_DIR 变量
  _INSTALL_PDB
)
```
接下来，您可以在其他项目中使用`find_package()`来查询该组件：
```cmake
find_package(PKG COMPONENTS component REQUIRED)
...
target_link_libraries(... PRIVATE PKG::component)
...
```



## PKG() 的代码注释

以下的内容是 `PKG()` 的开头中文注释（英文说明中我删掉了这部分，为了简化）：
```cmake
#===============================================================================
#
# @brief 快速打包普通项目或多组件项目
#
# @par 可用关键字
# _IS_COMPONENT             opt，当前安装的是项目的小部件
# _IS_COMPONENTS            opt，当前安装的是组件集，组件集不能是运行时工件，
#                                也就是说`_NAME`不能是`add_library`或`add_executable`等命令生成的目标
# _NAME                     one，项目名称/组件名称（无默认）
# _PROJECT                  one，`_IS_COMPONENT`开启时可用，指定本组件所附属的项目名称（默认：${PROJECT_NAME}）
# _VERSION                  one，版本（默认：目标（_NAME）属性 VERSION 的值 | 未定义）
# _COMPATIBILITY            one，定义目标的版本兼容性，
#                                支持的值: `AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion`
#								（默认：AnyNewerVersion）
# _DEBUG_POSTFIX            one，在Debug的编译文件的文件名后面添加标识，例如："d"，对Release无效（无默认）
# _SHARED_LIBS              opt，指定函数作用域内的 BUILD_SHARED_LIBS 变量值，将会在PKG_components-config.cmake.in用到
# _DEPENDENCIES             mul, 目标的依赖，可以设置多个，将使用`CMakeFindDependencyMacro`模块的find_dependency函数进行查找。
#                                内容格式——依赖的库的文件“-config.cmake”或“Config.cmake”的前缀 + “@version”，
#								 一般这个前缀就是对应的项目的名称；
#                                对于多组件项目，则可以使用“project@version:component1,...”的格式填写，
#                                如果是当前`_PROJECT`的组件之间的依赖，则可以使用“:component1,component2...”的表示方法
#                                （注意：以上方式的@version均可省略，CMake3.19后version支持版本范围，详情请查阅find_package的使用方法）
# _BINARY_DIR               one，指定目标的二进制目录（默认：${CMAKE_BINARY_DIR}）
# _BINARY_BIN_DIR           one，指定目标的二进制目录的 runtime 目录，相对于`_BINARY_DIR`，也可定义绝对路径（默认：bin）
# _BINARY_LIB_DIR           one，指定目标的二进制目录的 library 目录，相对于`_BINARY_DIR`，也可定义绝对路径（默认：lib）
# _INSTALL_DIR              one，指定目标的安装目录（默认：${CMAKE_INSTALL_PREFIX}）
# _INSTALL_INCLUDE_DIR      one，指定目标的安装目录的 include 目录，相对于`_INSTALL_DIR`，也可定义绝对路径（默认：include）
# _INSTALL_BIN_DIR          one，指定目标的安装目录的 runtime 目录，相对于`_INSTALL_DIR`，也可定义绝对路径（默认：bin）
# _INSTALL_LIB_DIR          one，指定目标的安装目录的 library 目录，相对于`_INSTALL_DIR`，也可定义绝对路径（默认：lib）
# _ADD_LIB_SUFFIX           opt，在 library 目录名添加后缀"64"，仅64位系统有效
# _EXPORT_EXT_FILES_<N>     mul, 构建目标时导出自定义的附加文件，可以指定一个或多个文件，但要确保`_NAME`是运行时工件，
#                                可以是绝对或者相对于`CMAKE_CURRENT_SOURCE_DIR`的路径，
#                                指定的最后一个参数是导出的目标路径（指定的文件都导出到此处），可以是绝对或者相对于`_BINARY_DIR`的路径。
#                                注意：该关键字不允许在`_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>`和
#                                `_INSTALL_EXT_DIRS_<N>`以外的其他`mul`关键字之后
# _EXPORT_EXT_DIRS_<N>      mul, 构建目标时导出自定义的附加目录，可以指定一个或多个目录，但要确保`_NAME`是运行时工件，
#                                可以是绝对或者相对于`CMAKE_CURRENT_SOURCE_DIR`的路径，
#                                指定的最后一个参数是导出的目标路径（指定的目录都导出到此处），可以是绝对或者相对于`_BINARY_DIR`的路径。
#                                注意：该关键字不允许在`_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>`和
#                                `_INSTALL_EXT_DIRS_<N>`以外的其他`mul`关键字之后
# _INSTALL_EXT_FILES_<N>    mul, 安装自定义的附加文件，可以指定一个或多个文件，可以是绝对或者相对于`CMAKE_CURRENT_SOURCE_DIR`的路径，
#                                指定的最后一个参数是安装的目标路径（指定的文件都安装到此处），可以是绝对或者相对于`_INSTALL_DIR`的路径。
#                                注意：该关键字不允许在`_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>`和
#                                `_INSTALL_EXT_DIRS_<N>`以外的其他`mul`关键字之后
# _INSTALL_EXT_DIRS_<N>     mul, 安装自定义的附加目录，可指定多个目录，可以是绝对或者相对于`CMAKE_CURRENT_SOURCE_DIR`的路径，
#                                指定的最后一项是安装的目标路径（指定的文件都安装到此处），可以是绝对或者相对于`_INSTALL_DIR`的路径
#                                注意：该关键字不允许在`_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>`和
#                                `_INSTALL_EXT_DIRS_<N>`以外的其他`mul`关键字之后
# _INCLUDE_FILES            mul，目标公共标头的文件位置，可以是绝对或相对路径，
#								 相对路径相对于 `CMAKE_CURRENT_SOURCE_DIR`，支持生成器表达式（无默认）
# _INCLUDE_DIRS             mul，目标公共标头的目录位置，可以是绝对或相对路径，
#								 相对路径相对于 `CMAKE_CURRENT_SOURCE_DIR`，支持生成器表达式（无默认）
# _INCLUDE_EXCLUDE_REG      one，安装目标公共标头时忽略的文件或目录的完整路径相匹配的正则表达式（无默认）
# _INCLUDE_DESTINATION      one，关联目标的`INSTALL_INTERFACE`包含目录（默认：${_INSTALL_INCLUDE_DIR}）
# _DISABLE_INTERFACE        opt，禁止把`_INCLUDE_DESTINATION`指定的目录包含到`INSTALL_INTERFACE`中
# _MODE                     one，安装模式，支持的值: `Runtime | Development`（默认：Development）
# _NAMESPACE                one，使用命名空间安装您的目标，不要添加额外的'::'（无默认 | ${_PROJECT}）
# _EXPORT_HEADER            one，此处设置创建的导出标头的文件绝对或相对路径，相对路径相对于`CMAKE_CURRENT_BINARY_DIR`，
#                                其安装位置默认是`_INSTALL_INCLUDE_DIR`。
#                                注意，当`_MODE`的值为 Runtime 时，它将只会导出导出标头而不会进行安装导出表头（无默认）
# _EXPORT_MACRO             one，导出标头中的宏定义（默认：`${_NAME}_API|${_PROJECT}_${_NAME}_API`，将变为大写）
# _EXPORT_INSTALL_DIR       one，导出标头的安装路径，可以是绝对或相对路径，相对路径相对于`_INSTALL_DIR`（默认：${_INSTALL_INCLUDE_DIR}）
# _INSTALL_PDB              opt，安装PDB文件，仅MSVC有效
# _DISABLE_CONFIG           opt，禁用config文件生成
# _DISABLE_VERSION          opt，始终禁用`*-config-version.cmake`文件生成，
#								 如果没有基于`_VERSION`关键字值以及没有定义`_NAME`的属性VERSION，
#                                `*-config-version.cmake` 文件也不会生成
# _CONFIG_TEMPLATE          one, 用于生成`*-config.cmake`文件的 config 模板文件
#                               （默认：生成在内部文件缓存目录的 `PKG_normal-config.cmake.in`或`PKG_components-config.cmake.in`）
# _APPEND_CONFIG            one, 指定一个文件，用于附加在`_CONFIG_TEMPLATE`指定的模板文件后面。
#                                可指定绝对路径或相对于`CMAKE_CURRENT_SOURCE_DIR`路径的路径（无默认）
# _ADD_UNINSTALL            opt，`_IS_COMPONENT`关闭时可用，添加卸载命令，如果定义了`_IS_COMPONENT`，
#								 则始终强制`_ADD_UNINSTALL`定义为 FALSE
# _UNINSTALL_TEMPLATE       one，`_ADD_UNINSTALL`开启时可用，卸载操作的模板文件
#								（默认：生成在内部文件缓存目录的`PKG_cmake_uninstall.cmake.in`）
# _UNINSTALL_ADDITIONAL     mul，`_ADD_UNINSTALL`开启时可用，附加卸载的文件或目录，被附加的文件或目录将在卸载操作进行时一同进行卸载（无默认）
#
# @par 全局变量
# PKG_FILE_CACHE_DIR        PKG的内部文件缓存目录，如为空，则函数会取默认值：${CMAKE_CURRENT_BINARY_DIR}/_PKG_cache。
#                           该路径可以是绝对路径，也可以是相对`CMAKE_CURRENT_SOURCE_DIR`路径的路径。修改此值会影响 PKG 生成的仅供内部使用的文件的位置
# PKG_<PROJECT>_BINARY_DIR  如果未自定义 _BINARY_DIR 关键字，则会使用该变量值作为其关键字值。该值会影响附属于`_PROJECT`的组件
# PKG_<PROJECT>_INSTALL_DIR 如果未自定义 _INSTALL_DIR 关键字，则会使用该变量值作为其关键字值。该值会影响附属于`_PROJECT`的组件
#
# @par 函数导出的变量
# PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR  _IS_COMPONENT 开启时有效，值为导出标头的所在目录（确保 _EXPORT_HEADER 关键字已定义）
# PKG_<_NAME>_EXPORT_HEADER_DIR             _IS_COMPONENT 与_IS_COMPONENTS 均关闭时有效，值为导出标头的所在目录（确保 _EXPORT_HEADER 关键字已定义）
```



## 关键字说明

- #### \_IS\_COMPONENT

  - **类型:** 选项
  - **描述:** 目前正在安装 `_PROJECT` 项目的组件，意味着 `_NAME` 是一个组件而不是一个独立项目。

- #### \_IS\_COMPONENTS

  - **类型:** 选项
  - **描述:** 当前目标 `_NAME` 是一个多组件项目
  - **注意:** 多组件项目不能是运行时项目，也就是说 `_NAME` 不能是 `add_library()`、`add_executable()` 指定的目标。

- #### \_NAME

  - **类型:** 单值
  - **描述:** 项目名称 / 多组件项目名称 / 组件名称

- #### \_PROJECT

  - **类型:** 单值
  - **默认:** "${PROJECT_NAME}" \| Undefined
  - **描述:** `_IS_COMPONENT` 定义时可用，其作用是指定组件所属项目的名称，如果 `_IS_COMPONENT` 未被定义，改关键字失效。

- #### \_VERSION

  - **类型:** 单值
  - **默认:** property VERSION \| Undefined
  - **描述:** 版本控制。如果未给出 `_VERSION` 关键字，则查找 `_NAME` 的 `VERSION` 属性的值；如果未定义属性值，将不会定义 `_VERSION`。

- #### \_COMPATIBILITY

  - **类型:** 单值
  - **默认:** "AnyNewerVersion"
  - **描述:** 定义目标 `_NAME` 的版本兼容性。 支持的值: `AnyNewerVersion` \| `SameMajorVersion` \| `SameMinorVersion` \| `ExactVersion`. 参考 [CMakePackageConfigHelpers](https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html)。

- #### \_DEBUG\_POSTFIX

  - **类型:** 单值

  - **描述:** 在Debug配置中，在已编译的目标文件后添加后缀，例如:"d"。

- #### \_SHARED\_LIBS

  - **类型:** 选项
  - **描述:** 指定函数作用域的 `BUILD_SHARED_LIBS` 变量的值，将用于 `PKG_components-config.cmake.in`文件中。

- #### **_DEPENDENCIES**

  - **类型:** 多值

  - **描述:** 目标的依赖，可以设置多个，将使用 [CMakeFindDependencyMacro](https://cmake.org/cmake/help/latest/module/CMakeFindDependencyMacro.html) 模块的 `find_dependency()` 函数来查找。

  - **规范:** 

    1. 依赖的库的文件**"-config.cmake"**或**"Config.cmake"**的前缀 + **"@version"**，一般这个前缀就是对应的项目的名称。例如："boost\_python@1.72"; "boost\_python"; "Soci"。
    2. 对于多组件项目，则可以使用**"project@version:component1,..."**的格式填写。例如：Example: "Boost@1.72:python"; "Boost:system,thread"。
    3. 如果是当前 `_PROJECT` 的组件之间的依赖，则可以使用**":component1,component2..."**的表示方法。例如：":component2,component3", ~~"@1.0:component1"~~。

    - **注意:** 以上方式的@version均可省略，CMake3.19后version支持版本范围，详情请查阅 [`find_package()`](https://cmake.org/cmake/help/latest/command/find_package.html) 的使用方法。

    ```cmake
    PKG(
      ...
      _DEPENDENCIES ":component1" "Boost@1.72:python,system,thread" "Soci"
      ...
    )
    ```

- #### \_BINARY\_DIR

  - **类型:** 单值
  - **默认:** "${CMAKE_BINARY_DIR}"
  - **描述:** 指定目标的二进制文件目录。

- #### \_BINARY\_BIN\_DIR

  - **类型:** 单值
  - **默认:** "bin"
  - **描述:** 指定目标的二进制目录的 runtime 目录，相对于 `_BINARY_DIR`，也可定义绝对路径。

- #### \_BINARY\_LIB\_DIR

  - **类型:** 单值
  - **默认:** "lib"
  - **描述:** 指定目标的二进制目录的 library 目录，相对于 `_BINARY_DIR`，也可定义绝对路径。

- #### \_INSTALL\_DIR

  - **类型:** 单值
  - **默认:** "${CMAKE_INSTALL_PREFIX}"
  - **描述:** 指定目标的安装目录

- #### \_INSTALL\_INCLUDE\_DIR

  - **类型:** 单值
  - **默认:** "include"
  - **描述:** 指定目标的安装目录的 include 目录，相对于 `_INSTALL_DIR`，也可定义绝对路径

- #### \_INSTALL\_BIN\_DIR

  - **Type:** 单值
  - **Default:** "bin"
  - **Description:** 指定目标的安装目录的 runtime 目录，相对于 `_INSTALL_DIR`，也可定义绝对路径

- #### \_INSTALL\_LIB\_DIR

  - **类型:** 单值
  - **默认:** "lib"
  - **描述:** 指定目标的安装目录的 library 目录，相对于 `_INSTALL_DIR`，也可定义绝对路径。

- #### \_ADD\_LIB\_SUFFIX

  - **类型:** 选项
  - **描述:** 在 library 目录名添加后缀"64"，仅64位系统有效

- #### \_EXPORT\_EXT\_FILES\_\<N\>

  - **类型:** 多值

  - **描述:** 构建目标时导出自定义的附加文件，可以指定一个或多个文件，但要确保 `_NAME` 是运行时工件，可以是绝对或者相对于 `CMAKE_CURRENT_SOURCE_DIR` 的路径，指定的最后一个参数是导出的目标路径（指定的文件都导出到此处），可以是绝对或者相对于 `_BINARY_DIR` 的路径。

  - **注意:** 该关键字不允许在 `_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>` 和 `_INSTALL_EXT_DIRS_<N>` 以外的其他 `多值` 类型的关键字之后。

  - **示例:**

    ```cmake
    PKG(
      ...
      # _BINARY_DIR "${CMAKE_BINARY_DIR}"    # 默认值，不需要显式指定
      _EXPORT_EXT_FILES_1 "doc/helper.doc" "doc/documents.doxygen" "doc"
      _EXPORT_EXT_FILES_2 "resource/img1.jpg" "resource/img2.jpg" "resource"
      _EXPORT_EXT_FILES_n ...
      ...
    )
    ```

- #### \_EXPORT\_EXT\_DIRS\_\<N\>

  - **类型:** 多值

  - **描述:** 构建目标时导出自定义的附加目录，可以指定一个或多个目录，但要确保 `_NAME` 是运行时工件，可以是绝对或者相对于 `CMAKE_CURRENT_SOURCE_DIR` 的路径，指定的最后一个参数是导出的目标路径（指定的目录都导出到此处），可以是绝对或者相对于 `_BINARY_DIR` 的路径。

  - **注意:** 该关键字不允许在 `_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>` 和 `_INSTALL_EXT_DIRS_<N>` 以外的其他 `多值` 类型的关键字之后。

  - **示例:**

    ```cmake
    PKG(
      ...
      # _BINARY_DIR "${CMAKE_BINARY_DIR}"    # 默认值，不需要显式指定
      _EXPORT_EXT_DIRS_1 "doc" "resources" "."
      _EXPORT_EXT_DIRS_2 "/home/my/images/" "resources/imgs"
      _EXPORT_EXT_DIRS_n ...
      ...
    )
    ```


- #### \_INSTALL\_EXT\_FILES\_\<N\>

  - **类型:** 多值

  - **描述:** 安装自定义的附加文件，可以指定一个或多个文件，可以是绝对或者相对于 `CMAKE_CURRENT_SOURCE_DIR` 的路径，指定的最后一个参数是安装的目标路径（指定的文件都安装到此处），可以是绝对或者相对于 `_INSTALL_DIR` 的路径。

  - **注意:** 该关键字不允许在 `_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>` 和 `_INSTALL_EXT_DIRS_<N>` 以外的其他 `多值` 类型的关键字之后。

  - **示例:**

    ```cmake
    PKG(
      ...
      # _INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"    # 默认值，不需要显式指定
      _INSTALL_EXT_FILES_1 "doc/helper.doc" "doc/documents.doxygen" "doc"
      _INSTALL_EXT_FILES_2 "include/pkg.h.in" "include/tmp"
      _INSTALL_EXT_FILES_n ...
      ...
    )
    ```

  #### \_INSTALL\_EXT\_DIRS\_\<N\>

  - **类型:** 多值

  - **描述:** 安装自定义的附加目录，可指定多个目录，可以是绝对或者相对于 `CMAKE_CURRENT_SOURCE_DIR` 的路径，指定的最后一项是安装的目标路径（指定的文件都安装到此处），可以是绝对或者相对于 `_INSTALL_DIR` 的路径。

  - **注意:** 该关键字不允许在 `_EXPORT_EXT_FILES_<N>`、`_EXPORT_EXT_DIRS_<N>`、`_INSTALL_EXT_FILES_<N>` 和 `_INSTALL_EXT_DIRS_<N>` 以外的其他 `多值` 类型的关键字之后。

  - **示例:**

    ```cmake
    PKG(
      ...
      # _INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"    # 默认值，不需要显式指定
      _INSTALL_EXT_DIRS_1 "doc/" "document" "doc"
      _INSTALL_EXT_DIRS_2 "imgs" "."
      _INSTALL_EXT_DIRS_3 "include/tmp/" "include/tmp"    # eq: _INSTALL_EXT_DIRS_2 "include/tmp" "include"
      _INSTALL_EXT_DIRS_n ...
      ...
    )
    ```

- #### \_INCLUDE\_FILES

  - **类型:** 多值
  - **描述:** 目标公共标头的文件位置，可以是绝对或相对路径，相对路径相对于 `CMAKE_CURRENT_SOURCE_DIR`，支持[生成器表达式](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html)。

- #### \_INCLUDE\_DIRS

  - **类型:** 多值
  - **描述:** 目标公共标头的目录位置，可以是绝对或相对路径，相对路径相对于 `CMAKE_CURRENT_SOURCE_DIR`，支持[生成器表达式](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html)。

- #### \_INCLUDE\_EXCLUDE\_REG

  - **类型:** 单值
  - **描述:** 安装目标公共标头时忽略的文件或目录的完整路径相匹配的正则表达式。

- #### \_INCLUDE\_DESTINATION

  - **类型:** 单值
  - **默认:** "\<_INSTALL_INCLUDE_DIR\>"
  - **描述:** 匹配目标的 `INSTALL_INTERFACE` 包含目录，如果定义了 `_DISABLE_INTERFACE` 关键字，则该值将不会出现在 `install()` 指令中。

- #### \_DISABLE\_INTERFACE

  - **类型:** 选项
  - **描述:** 禁止把 `_INCLUDE_DESTINATION` 指定的目录包含到 `INSTALL_INTERFACE` 中。

- #### \_MODE

  - **类型:** 单值
  - **默认:** "Development"
  - **描述:** 安装模式，"Runtime" 意味着 `_INSTALL_INCLUDE_DIR` 中的头文件和 `_INSTALL_LIB_DIR` 中的库文件不被打包安装。支持的值: `Runtime` \| `Development`。

- #### \_NAMESPACE

  - **类型:** 单值
  - **默认:** "\<\_PROJECT\>"(仅当 `_IS_COMPONENT` 被定义时) \| Undefined
  - **描述:** 使用命名空间来安装目标，不要添加额外的'::'。

- #### \_EXPORT\_HEADER

  - **类型:** 单值
  - **描述:** 此处设置创建的导出标头的文件绝对或相对路径，相对路径相对于 `CMAKE_CURRENT_BINARY_DIR`，其安装位置默认是 `_INSTALL_INCLUDE_DIR`。
  - **注意:** 当 `_MODE` 的值为 Runtime 时，它将只会导出导出标头而不会进行安装导出表头。

- #### \_EXPORT\_MACRO

  - **类型:** 单值
  - **默认:** "\<\_NAME\>\_API" \| "\<\_PROJECT\>\_\<_NAME\>\_API"
  - **描述:** 导出标头中的宏（默认宏名称将转换为大写，自定义宏名称不会转换为大小写）。

- #### \_EXPORT\_INSTALL\_DIR

  - **类型:** 单值
  - **默认:** "\<\_INSTALL\_INCLUDE\_DIR\>"
  - **描述:** 导出标头的安装路径，可以是绝对或相对路径，相对路径相对于 `_INSTALL_DIR`。

- #### \_INSTALL\_PDB

  - **类型:** 选项
  - **描述:** 安装PDB文件，仅MSVC有效。

- #### \_DISABLE\_CONFIG

  - **类型:** 选项
  - **描述:** 禁用 `*-config.cmake` 文件生成。

- #### \_DISABLE\_VERSION

  - **类型:** 选项
  - **描述:** 始终禁用 `*-config-version.cmake` 文件生成，如果没有基于 `_VERSION` 关键字值以及没有定义 `_NAME` 的属性 `VERSION`，`*-config-version.cmake` 文件也不会生成。

- #### \_CONFIG\_TEMPLATE

  - **类型:** 单值
  - **默认:** 生成在内部文件缓存目录的 `PKG_normal-config.cmake.in` 或 `PKG_components-config.cmake.in`。
  - **描述:** 用于生成 `*-config.cmake` 文件的 config 模板文件。

- #### \_APPEND\_CONFIG

  - **类型:** 单值
  - **描述:** 指定一个文件，用于附加在 `_CONFIG_TEMPLATE` 指定的模板文件后面。可指定绝对路径或相对于 `CMAKE_CURRENT_SOURCE_DIR` 路径的路径。

- #### \_ADD\_UNINSTALL

  - **类型:** 选项
  - **描述:** `_IS_COMPONENT` 未定义时可用。添加卸载命令，如果定义了 `_IS_COMPONENT`，则始终强制 `_ADD_UNINSTALL` 定义为 FALSE。

- #### \_UNINSTALL\_TEMPLATE

  - **类型:** 单值
  - **默认:** 生成在内部文件缓存目录的 `PKG_cmake_uninstall.cmake.in`
  - **描述:** `_ADD_UNINSTALL` 已定义时可用，卸载操作的模板文件。

- #### \_UNINSTALL\_ADDITIONAL

  - **类型:** 多值
  - **描述:** `_ADD_UNINSTALL` 开启时可用，附加卸载的文件或目录，被附加的文件或目录将在卸载操作进行时一同进行卸载。



## 全局变量

- **`PKG_FILE_CACHE_DIR`** PKG 内部文件缓存目录，如果为空，则该函数采用默认值：**'${CMAKE\_CURRENT\_BINARY\_DIR}/\_PKG\_cache'**。 修改此值会影响 PKG 生成的文件的位置，但仅供内部使用。通常不建议修改此变量。

- **`PKG_<PROJECT>_BINARY_DIR`** 如果未自定义 `_BINARY_DIR` 关键字，则会使用该变量值作为其关键字值。该值会影响附属于 `_PROJECT ` 的组件。在组件以外的目标上，`<PROJECT>` 引用关键字的值 `_NAME`；如果目标是组件，则 `<PROJECT>` 引用关键字的值 `_PROJECT`。

- **`PKG_<PROJECT>_INSTALL_DIR`** 如果未自定义 `_INSTALL_DIR` 关键字，则会使用该变量值作为其关键字值。该值会影响附属于 `_PROJECT` 的组件。在组件以外的目标上，`<PROJECT>` 引用关键字的值 `_NAME`；如果目标是组件，则 `<PROJECT>` 引用关键字的值 `_PROJECT`。

**NOTE:** 如果关键字 `_BINARY_DIR` \| `_INSTALL_DIR` 没有定义，全局变量的值将会作用于项目 `_NAME` 的值为 `<PROJECT>` 的 `_BINARY_DIR` \| `_INSTALL_DIR` 的值中，且如果该项目是多组件项目，全局变量的值将会作用域项目组件的 `_BINARY_DIR` \| `_INSTALL_DIR` 中（组件的 `_PROJECT` 的值为 `<PROJECT>`）。



## 导出变量

调用 `PKG(... _EXPORT_HEADER "..." ...)` 后自动定义的变量。

导出标头所在的目录。如果关键字 `_EXPORT_HEADER` 的值为 "a/b/export. h"，那么变量的值将会是 "a/b"。

- **`PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR`** 定义了 `_IS_COMPONENT` 时该变量才会被导出。
- **`PKG_<_NAME>_EXPORT_HEADER_DIR`**在未定义 `_IS_COMPONENT` 和 `_IS_COMPONENTS` 时该变量才会被导出。





------

# <a id="English" style="color: inherit">PKG.cmake</a>

Simplify a large amount of code during project installation, using a single function to encapsulate some of the export and installation operations to facilitate the installation of a single project or a multi-component project.

*This module is currently in beta and is not recommended for use in a formal project.*



## Usage

The most concise configuration method for library installation is as follows:

```cmake
PKG(
  _NAME PKG_lib
  _INCLUDE_DIRS "include/"
)
```

Then compile and install:

```shell
mkdir build
cd build
cmake ..
make -j8
make install
```

After performing the library installation, you can then look for `PKG_lib` library in other projects through `find_package()`:

```cmake
find_package(PKG_lib REQUIRED)
```

The most concise configuration method for executable installation is as follows:

```cmake
PKG(
  _NAME PKG
  _MODE Runtime
  #_INSTALL_BIN_DIR "."    # You'll probably need this line of code badly on a Windows machine
  _DISABLE_INTERFACE
  _DISABLE_CONFIG
  _DISABLE_VERSION
)
```

Of course, a custom version number is also an keyword (if not defined, the function will get from the property `VERSION` of the `_NAME`, if the acquisition fails, versioning is ignored, i.e. the `*-config-version.cmake` file is not generated). The option `_DISABLE_VERSION` enforces that the `*-config-version.cmake` file is not generated under any circumstances.

A slightly more complete example of a dynamic library installation:

```cmake
cmake_minimum_required(VERSION 3.20)
project(PKG_shared VERSION 1.2.3.4)

add_library(PKG_shared SHARED)
add_library(PKGNS::PKG_shared ALIAS PKG_shared)
set_target_properties(
  PKG_shared PROPERTIES
  VERSION 1.2.3.4
  #SOVERSION 1.2
  DEFINE_SYMBOL "${COMPONENT_NAME}_EXPORTS"
  MSVC_RUNTIME_LIBRARY "${MSVC_RUNTIME_LIB}"
)

include(cmake/PKG.cmake)
PKG(
  _NAME "PKG_shared"
  #_VERSION 1.2.3.4         # Automatically gets the PKG_shared property VERSION
  _DEBUG_POSTFIX "d"        # Equivalent to `set_target_properties(PKG_shared PROPERTIES DEBUG_POSTFIX "d")`
  _NAMESPACE "PKGNS"
  _DEPENDENCIES "Boost@1.72:thread,system" "Soci"
  _EXPORT_EXT_DIRS_1 "resources" "."
  _INSTALL_EXT_DIRS_1 "docs/" "docs"
  _INCLUDE_DIRS "include/"
  _INCLUDE_EXCLUDE_REG ".*\\.(svn|h\\.in|hpp\\.in)$"
  _INCLUDE_DESTINATION "include/${PROJECT_NAME}-1.2.3.4"
  _EXPORT_HEADER "comm1_export.h"        # Relative to the CMAKE_CURRENT_BINARY_DIR, and defined PKG_PKG_shared_EXPORT_HEADER_DIR
  _INSTALL_PDB              # MSVC only effective
  #_ADD_LIB_SUFFIX          # If on a 64-bit machine, _BINARY_LIB_DIR and _INSTALL_LIB_DIR will be suffixed with '64'
  _ADD_UNINSTALL
)

target_sources(
  PKG_shared PRIVATE "src/add.cpp"
)

target_include_directories(
  PKG_shared PRIVATE
  "include"
  "${PKG_PKG_shared_EXPORT_HEADER_DIR}"
)
```

If you want to package a multi-component project, this script will give you great convenience. The function provides two special options, `_IS_COMPONENT` and `_IS_COMPONENTS`. `_IS_COMPONENT` means that the current `_NAME` target is a component of the project, this component is attached to the `_PROJECT` project, `_PROJECT` defaults to `PROJECT_NAME` when `_IS_COMPONENT` is defined. `_PROJECT` can be customized.

A simple component installation example:

```cmake
add_library(component SHARED)
PKG(
  _IS_COMPONENT
  _NAME component
  _PROJECT PKG
  _NAMESPACE "${PROJECT_NAME}"
  _DEBUG_POSTFIX "d"
  _INCLUDE_DIRS "include/"
  _INCLUDE_EXCLUDE_REG ".*\\.(svn|h\\.in|hpp\\.in)$"
  _INCLUDE_DESTINATION "include/${PROJECT_NAME}"
  _EXPORT_HEADER "include/component_export.h"        # The PKG_PKG_component_EXPORT_HEADER_DIR variable will be defined
  _INSTALL_PDB
)
```

Corresponding project installation example:

```cmake
project(PKG VERSION 0.0.1)

# Its components also set this value to the default value of their _INSTALL_DIR, unless custom _INSTALL_DIR
set(PKG_PKG_INSTALL_DIR "/home/pkg/pkg_install")

add_subdirectory(component)

# Called after all child components
PKG(
  _IS_COMPONENTS
  _NAME ${PROJECT_NAME}
  _VERSION 0.0.1
  #_INCLUDE_DIRS "macro"             # Here you can add additional include files to the path specified by _INCLUDE_DESTINATION
  _INCLUDE_FILES "macro/global.h" "macro/macro.h"
  _INCLUDE_EXCLUDE_REG ".*\\.(svn|h\\.in|hpp\\.in)$"
  #_INCLUDE_DESTINATION "include"    # The value of the _INCLUDE_DESTINATION defaults to the value of _INSTALL_INCLUDE_DIR
  _SHARED_LIBS
  _ADD_UNINSTALL
)
```

Next, you can use `find_package()` in other projects to query the component:

```cmake
find_package(PKG COMPONENTS component REQUIRED)
...
target_link_libraries(... PRIVATE PKG::component)
...
```



## Keyword Descriptions

- #### \_IS\_COMPONENT

	- **Type:** option
	- **Description:** The component of the `_PROJECT` project is currently being installed.

- #### \_IS\_COMPONENTS

  - **Type:** option
  - **Description:** Current target `_NAME` is a multi-component project and is being installed
  - **Note:** Multi-component Project cannot be a runtime artifact.

- #### \_NAME

	- **Type:** one value
	- **Description:** Project Name / Multi-component Project Name / Component Name

- #### \_PROJECT

	- **Type:** one value
	- **Default:** "${PROJECT_NAME}" \| Undefined
	- **Description:** Available when defined `_IS_COMPONENT`, its purpose is to specify the name of the project to which the component belongs.
	
- #### \_VERSION

  - **Type:** one value
  - **Default:** property VERSION \| Undefined
  - **Description:** Version control. If the `_VERSION` keyword is not given, the value of the `VERSION` property of the `_NAME` is looked up, and if the property value is not defined, the `_VERSION` will not be defined.

- #### \_COMPATIBILITY

  - **Type:** one value
  - **Default:** "AnyNewerVersion"
  - **Description:** Defines the version compatibility of the `_NAME` target. Supported values: `AnyNewerVersion` \| `SameMajorVersion` \| `SameMinorVersion` \| `ExactVersion`. See [CMakePackageConfigHelpers](https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html).

- #### \_DEBUG\_POSTFIX

  - **Type:** one value

  - **Description:** In the Debug configuration, add a postfix after the compiled target file, for example: "d".

- #### \_SHARED\_LIBS

  - **Type:** option
  - **Description:** The value of the `BUILD_SHARED_LIBS` variable that specifies the scope of the function will be used in `PKG_components-config.cmake.in`.

- #### **_DEPENDENCIES**

  - **Type:** multi value

  - **Description:** The dependencies of the target, you can set multiple, will use the ` find_dependency()` function of the [CMakeFindDependencyMacro](https://cmake.org/cmake/help/latest/module/CMakeFindDependencyMacro.html) module to find.

  - **Format:** 

      1. The file of the dependent library's **"-config.cmake"** or **"Config.cmake"** prefix + **"@version"**, usually this prefix is the name of the corresponding project. Example:  "boost\_python@1.72"; "boost\_python"; "Soci".
      2. For multi-component projects, you can use the format **"project@version:component1,component2..."**. Example: "Boost@1.72:python"; "Boost:system,thread".
      3. If it is a dependency between the components of the current `_PROJECT`, it can be expressed in the format of **":component1,component2..."**. Example: ":component2,component3", ~~"@1.0:component1"~~.

    - **Note:** The above "@version" can be omitted, CMake 3.19 after the version support version range. For details, please refer to the use of [`find_package()`](https://cmake.org/cmake/help/latest/command/find_package.html) function.

    ```cmake
    PKG(
      ...
      _DEPENDENCIES ":component1" "Boost@1.72:python,system,thread" "Soci"
      ...
    )
    ```

- #### \_BINARY\_DIR

  - **Type:** one value
  - **Default:** "${CMAKE_BINARY_DIR}"
  - **Description:** Specifies the binary directory of the target.

- #### \_BINARY\_BIN\_DIR

  - **Type:** one value
  - **Default:** "bin"
  - **Description:** Specifies the runtime directory of the target's binary directory, relative to `_BINARY_DIR`, and can also define an absolute path.

- #### \_BINARY\_LIB\_DIR

  - **Type:** one value
  - **Default:** "lib"
  - **Description:** Specifies the library directory of the target's binary directory, relative to `_BINARY_DIR`, and can also define an absolute path.

- #### \_INSTALL\_DIR

  - **Type:** one value
  - **Default:** "${CMAKE_INSTALL_PREFIX}"
  - **Description:** Specifies the installation directory for the target.

- #### \_INSTALL\_INCLUDE\_DIR

  - **Type:** one value
  - **Default:** "include"
  - **Description:** Specifies the include directory of the target's installation directory, relative to `_INSTALL_DIR`, or to define an absolute path.

- #### \_INSTALL\_BIN\_DIR

  - **Type:** one value
  - **Default:** "bin"
  - **Description:** Specifies the runtime directory of the target's installation directory, relative to `_INSTALL_DIR`, and can also define an absolute path.

- #### \_INSTALL\_LIB\_DIR

  - **Type:** one value
  - **Default:** "lib"
  - **Description:** Specifies the library directory of the target's installation directory, relative to `_INSTALL_DIR`, or to define an absolute path.

- #### \_ADD\_LIB\_SUFFIX

  - **Type:** option
  - **Description:** Add the suffix "64" to the library directory name, which is valid only for 64-bit systems.

- #### \_EXPORT\_EXT\_FILES\_\<N\>

  - **Type:** multi value

  - **Description:** Export custom additional files when building the target. You can specify one or more files, but make sure `_NAME` is a runtime artifact, which can be an absolute or relative path to `CMAKE_CURRENT_SOURCE_DIR`. The last parameter specified is The destination path of the export (the specified files are exported here), which can be absolute or relative to `_BINARY_DIR`.

  - **Note:** This keyword is not allowed after keywords of other `multi` types other than `_EXPORT_EXT_FILES_<N>`, `_EXPORT_EXT_DIRS_<N>`, `_INSTALL_EXT_FILES_<N>` and `_INSTALL_EXT_DIRS_<N>`.

  - **Example:**

    ```cmake
    PKG(
      ...
      # _BINARY_DIR "${CMAKE_BINARY_DIR}"    # default value, it does not need to be specified explicitly
      _EXPORT_EXT_FILES_1 "doc/helper.doc" "doc/documents.doxygen" "doc"
      _EXPORT_EXT_FILES_2 "resource/img1.jpg" "resource/img2.jpg" "resource"
      _EXPORT_EXT_FILES_n ...
      ...
    )
    ```

- #### \_EXPORT\_EXT\_DIRS\_\<N\>

  - **Type:** multi value

  - **Description:** Export custom additional directories when building the target. You can specify one or more directories, but make sure `_NAME` is a runtime artifact, which can be an absolute or relative path to `CMAKE_CURRENT_SOURCE_DIR`. The last parameter specified is the destination path of the export (the specified directories are exported here), which can be absolute or relative to `_BINARY_DIR`.

  - **Note:** This keyword is not allowed after keywords of other `multi` types other than `_EXPORT_EXT_FILES_<N>`, `_EXPORT_EXT_DIRS_<N>`, `_INSTALL_EXT_FILES_<N>` and `_INSTALL_EXT_DIRS_<N>`.

  - **Example:**

    ```cmake
    PKG(
      ...
      # _BINARY_DIR "${CMAKE_BINARY_DIR}"
      _EXPORT_EXT_DIRS_1 "doc" "resources" "."
      _EXPORT_EXT_DIRS_2 "/home/my/images/" "resources/imgs"
      _EXPORT_EXT_DIRS_n ...
      ...
    )
    ```


- #### \_INSTALL\_EXT\_FILES\_\<N\>

  - **Type:** multi value

  - **Description:** Install custom additional files, the keyword can specify one or more files, either absolute or relative to the path of the `CMAKE_CURRENT_SOURCE_DIR`, and the last parameter specified is the target path of the installation (the specified files will be installed here), which can be absolute or relative to the path of the `_INSTALL_DIR`.

  - **Note:** This keyword is not allowed after keywords of other `multi` types other than `_EXPORT_EXT_FILES_<N>`, `_EXPORT_EXT_DIRS_<N>`, `_INSTALL_EXT_FILES_<N>` and `_INSTALL_EXT_DIRS_<N>`.

  - **Example:**
    
    ```cmake
    PKG(
      ...
      # _INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"    # default value, it does not need to be specified explicitly
      _INSTALL_EXT_FILES_1 "doc/helper.doc" "doc/documents.doxygen" "doc"
      _INSTALL_EXT_FILES_2 "include/pkg.h.in" "include/tmp"
      _INSTALL_EXT_FILES_n ...
      ...
    )
    ```

  #### \_INSTALL\_EXT\_DIRS\_\<N\>

  - **Type:** multi value

  - **Description:** Install custom additional directories, the keyword can specify one or more directories, either absolute or relative to the path of the `CMAKE_CURRENT_SOURCE_DIR`, and the last parameter specified is the target path of the installation (the specified directories will be installed here), which can be absolute or relative to the path of the `_INSTALL_DIR`.

  - **Note:** This keyword is not allowed after keywords of other `multi` types other than `_EXPORT_EXT_FILES_<N>`, `_EXPORT_EXT_DIRS_<N>`, `_INSTALL_EXT_FILES_<N>` and `_INSTALL_EXT_DIRS_<N>`.

  - **Example:**

    ```cmake
    PKG(
      ...
      # _INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"
      _INSTALL_EXT_DIRS_1 "doc/" "document" "doc"
      _INSTALL_EXT_DIRS_2 "imgs" "."
      _INSTALL_EXT_DIRS_3 "include/tmp/" "include/tmp"    # eq: _INSTALL_EXT_DIRS_2 "include/tmp" "include"
      _INSTALL_EXT_DIRS_n ...
      ...
    )
    ```

- #### \_INCLUDE\_FILES

  - **Type:** multi value
  - **Description:** Files location of the target public headers, which can be an absolute or relative path, relative to `CMAKE_CURRENT_SOURCE_DIR`, supports [cmake-generator-expressions(7)](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html).

- #### \_INCLUDE\_DIRS

  - **Type:** multi value
  - **Description:** Directories location of the target public headers, which can be absolute or relative, relative to `CMAKE_CURRENT_SOURCE_DIR`, supports [cmake-generator-expressions(7)](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html).

- #### \_INCLUDE\_EXCLUDE\_REG

  - **Type:** one value
  - **Description:** The regular expression that matches the full path of the files or directoryies is ignored when the target public headers are installed.

- #### \_INCLUDE\_DESTINATION

  - **Type:** one value
  - **Default:** "\<_INSTALL_INCLUDE_DIR\>"
  - **Description:** `_INCLUDE_DIRS` installation path, which is also the `INSTALL_INTERFACE` that matches the target contains directory.

- #### \_DISABLE\_INTERFACE

  - **Type:** option
  - **Description:** It is forbidden to include the directory specified by the `_INCLUDE_DESTINATION` in the `INSTALL_INTERFACE`.

- #### \_MODE

  - **Type:** one value
  - **Default:** "Development"
  - **Description:** Installation mode, "Runtime" means that header files in `_INSTALL_INCLUDE_DIR` and library files in `_INSTALL_LIB_DIR` are not packaged. Supported values: `Runtime` \| `Development`.

- #### \_NAMESPACE

  - **Type:** one value
  - **Default:** "\<\_PROJECT\>"(only when `_IS_COMPONENT` is defined) \| Undefined
  - **Description:** Use the namespace to install your target, do not add extra '::'.

- #### \_EXPORT\_HEADER

  - **Type:** one value
  - **Description:** Here you set the absolute or relative path of the file that creates the export header, relative to the` CMAKE_CURRENT_BINARY_DIR`. It installs to the directory specified by `_INSTALL_INCLUDE_DIR`
  - **NOTE:** When the value of `_MODE` is "Runtime", it will only export the export header and not install the export header, which means that it will not be installed in the `_INSTALL_INCLUDE_DIR`

- #### \_EXPORT\_MACRO

  - **Type:** one value
  - **Default:** "\<\_NAME\>\_API" \| "\<\_PROJECT\>\_\<_NAME\>\_API"
  - **Description:** Macro in the export header(The default macro name will be converted to uppercase, and the custom macro name will not be converted to case).

- #### \_EXPORT\_INSTALL\_DIR

  - **Type:** one value
  - **Default:** "\<\_INSTALL\_INCLUDE\_DIR\>"
  - **Description:** The installation path for the export header, which can be absolute or relative, relative to the `_INSTALL_DIR`.

- #### \_INSTALL\_PDB

  - **Type:** option
  - **Description:** Install the PDB file, only MSVC is valid.

- #### \_DISABLE\_CONFIG

  - **Type:** option
  - **Description:** Disable `*-config.cmake` file generation.

- #### \_DISABLE\_VERSION

  - **Type:** option
  - **Description:** Always disable `*-config-version.cmake` file generation, and if there is no value based on `_VERSION` and property `VERSION` for `_NAME` is not defined, `*-config-version.cmake` file will not be generated.

- #### \_CONFIG\_TEMPLATE

  - **Type:** one value
  - **Default:** "PKG\_normal-config.cmake.in" or "PKG\_components-config.cmake.in" file that is generated in the internal file cache directory.
  - **Description:** The config template file used to generate the `*-config.cmake` file.

- #### \_APPEND\_CONFIG

    - **Type:** one value
    - **Description:** Specifies a file to append to the template file specified by `_CONFIG_TEMPLATE`. Either an absolute path or a path relative to the `CMAKE_CURRENT_SOURCE_DIR` path can be specified.

- #### \_ADD\_UNINSTALL

  - **Type:** option
  - **Description:** Available when `_IS_COMPONENT` is undefined, this keyword is used to add an uninstall command. If the `_IS_COMPONENT` is defined, `_ADD_UNINSTALL` is always mandatory to be defined as FALSE.

- #### \_UNINSTALL\_TEMPLATE

  - **Type:** one value
  - **Default:** "PKG\_cmake\_uninstall.cmake.in" file that is generated in the internal file cache directory.
  - **Description:** Available when `_ADD_UNINSTALL` is TRUE, a template file for unload operation.

- #### \_UNINSTALL\_ADDITIONAL

  - **Type:** multi value
  - **Description:** Available when `_ADD_UNINSTALL` is TRUE, it is used to attach the unloaded files or directories, which is unloaded together with the unload operation.



## Global Variables

- **`PKG_FILE_CACHE_DIR`** PKG's internal file cache directory, if empty, the function takes the default value: '${CMAKE\_CURRENT\_BINARY\_DIR}/\_PKG\_cache'. Modifying this value affects the location of files generated by `PKG` for internal use only. Modifying this variable is generally not recommended.

- **`PKG_<PROJECT>_BINARY_DIR`** If the `_BINARY_DIR` keyword is not customized, the altered amount value is used as its keyword value. This value affects components attached to `<PROJECT>`. On targets other than components, `<PROJECT>` refers to the value of the keyword `_NAME`; if the target is a component, `<PROJECT>` refers to the value of the keyword `_PROJECT`.

- **`PKG_<PROJECT>_INSTALL_DIR`** If the `_INSTALL_DIR` keyword is not customized, the altered amount value is used as its keyword value. This value affects components attached to `<PROJECT>`. On targets other than components, `<PROJECT>` refers to the value of the keyword `_NAME`; if the target is a component, `<PROJECT>` refers to the value of the keyword `_PROJECT`.

**NOTE:** If the `_BINARY_DIR` \| `_INSTALL_DIR` keyword is not customized, the altered amount value is used as `_BINARY_DIR` \| `_INSTALL_DIR` keyword value which the value of `_NAME` is `<PROJECT>`, which affects components attached to \<PROJECT\>(Use the `_PROJECT` keyword to specify the subordinate projects that are formed).




## Export Variables

Automatically defined variables after calling `PKG(... _EXPORT_HEADER "..." ...)`

Export header directory. If the value of `_EXPORT_HEADER` is "a/b/export. h", then the variable value will be "a/b".

- **`PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR`** Valid when `_IS_COMPONENT` is defined.
- **`PKG_<_NAME>_EXPORT_HEADER_DIR`** Valid when neither the `_IS_COMPONENT` nor the `_IS_COMPONENTS` is defined.
