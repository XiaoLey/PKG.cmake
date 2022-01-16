# PKG.cmake
Simplify a large amount of code during project installation, using a single function to encapsulate some of the export and installation operations to facilitate the installation of a single project or a multi-component project.



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



## Functions Overview

The following is an overview of the function as a whole, including all available keywords and their corresponding default values (remember not to copy and use them directly):

```cmake
# Global variables, defined before PKG()
set(PKG_<PROJECT>_BINARY_DIR "...")
set(PKG_<PROJECT>_INSTALL_DIR "...")

PKG(
  _IS_COMPONENT          FALSE
  _IS_COMPONENTS         FALSE
  _NAME                  ""
  _PROJECT               "${PROJECT_NAME}" | ""        # _IS_COMPONENT is undefined, the value is always empty
  _VERSION               property VERSION | ""
  _COMPATIBILITY         "AnyNewerVersion"
  _DEBUG_POSTFIX         ""
  _SHARED_LIBS           FALSE
  _DEPENDENCIES          ""...
  _BINARY_DIR            "${CMAKE_BINARY_DIR}"
  _BINARY_BIN_DIR        "bin"
  _BINARY_LIB_DIR        "lib"
  _INSTALL_DIR           "${CMAKE_INSTALL_PREFIX}"
  _INSTALL_INCLUDE_DIR   "include"
  _INSTALL_BIN_DIR       "bin"
  _INSTALL_LIB_DIR       "lib"
  _ADD_LIB_SUFFIX        FALSE
  _EXPORT_EXT_FILES_<N>  ""...
  _EXPORT_EXT_DIRS_<N>   ""...
  _INSTALL_EXT_FILES_<N> ""...
  _INSTALL_EXT_DIRS_<N>  ""...
  _INCLUDE_FILES         ""...
  _INCLUDE_DIRS          ""...
  _INCLUDE_EXCLUDE_REG   ""
  _INCLUDE_DESTINATION   "<_INSTALL_INCLUDE_DIR>"
  _DISABLE_INTERFACE     FALSE
  _MODE                  "Development"
  _NAMESPACE             "<_PROJECT>" | ""
  _EXPORT_HEADER         ""
  _EXPORT_MACRO          "<_NAME>_API"|"<_PROJECT>_<_NAME>_API"    # UPPERCASE
  _EXPORT_INSTALL_DIR    "<_INSTALL_INCLUDE_DIR>"
  _INSTALL_PDB           FALSE
  _DISABLE_CONFIG        FALSE
  _DISABLE_VERSION       FALSE
  _CONFIG_TEMPLATE       "${CMAKE_SOURCE_DIR}/cmake/PKG_normal-config.cmake.in" | "${CMAKE_SOURCE_DIR}/cmake/PKG_components-config.cmake.in"
  _APPEND_CONFIG         ""
  _ADD_UNINSTALL         FALSE
  _UNINSTALL_TEMPLATE    "${CMAKE_SOURCE_DIR}/cmake/PKG_cmake_uninstall.cmake.in"
  _UNINSTALL_ADDITIONAL  ""...
)

# Automatically defined variables after calling PKG(... _EXPORT_HEADER "..." ...)
message(${PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR})
message(PKG_<_NAME>_EXPORT_HEADER_DIR)

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

**NOTE:** If the `_BINARY_DIR` \| `_INSTALL_DIR` keyword is not customized, the altered amount value is used as `_BINARY_DIR` keyword value which the value of `_NAME` is `<PROJECT>`, which affects components attached to \<PROJECT\>(Use the `_PROJECT` keyword to specify the subordinate projects that are formed).




## Export Variables

Automatically defined variables after calling `PKG(... _EXPORT_HEADER "..." ...)`

Export header directory. If the value of `_EXPORT_HEADER` is "a/b/export. h", then the variable value will be "a/b".

- **`PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR`** Valid when `_IS_COMPONENT` is defined
- **`PKG_<_NAME>_EXPORT_HEADER_DIR` ** Valid when neither the `_IS_COMPONENT` nor the `_IS_COMPONENTS` is defined
