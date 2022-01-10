# PKG.cmake
Simplify a large amount of code during project installation, using a single function to encapsulate some of the export and installation operations to facilitate the installation of a single project or a multi-component project.



## Usage

The most concise configuration method for library installation is as follows:

```cmake
PKG(
  _NAME PKG
  _INCLUDE_DIRS "include/"
)
```

You can then look for `PKG` library in other projects through `find_package()`:

```cmake
find_package(PKG REQUIRED)
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

Of course, a custom version number is also an option (if not defined, the function will get from the property "VERSION" of the "\_NAME", if the acquisition fails, versioning is ignored, i.e. the "\*-config-version.cmake" file is not generated). The option \_DISABLE\_VERSION enforces that the "\*-config-version.cmake" file is not generated under any circumstances.

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
  #_VERSION 1.2.3.4         # Automatically gets the PKG_shared propertie VERSION
  _DEBUG_POSTFIX "d"        # Equivalent to `set_target_properties(PKG_shared PROPERTIES DEBUG_POSTFIX "d")`
  _NAMESPACE "PKGNS"
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

If you want to package a multi-component project, this script will give you great convenience. The function provides two special options, \_IS\_COMPONENT and \_IS\_COMPONENTS. \_IS\_COMPONENT specifies that the current \_NAME target is a component of the project, this component is attached to the \_PROJECT project, \_PROJECT defaults to PROJECT\_NAME when \_IS\_COMPONENT is turned on. \_PROJECT can be customized.

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

Next, you can use find\_package() in other projects to query the component:

```cmake
find_package(PKG COMPONENTS component REQUIRED)
...
target_link_libraries(... PRIVATE PKG::component)
...
```



## Functions Overview

The following is an overview of the function as a whole, including all available parameters and their corresponding default values (remember not to copy and use them directly):

```cmake
# Global variables, defined before PKG().
# If the _BINARY_DIR | _INSTALL_DIR parameter is not customized, 
# the altered amount value is used as its parameter value, which affects components 
# attached to <PROJECT>(Use the _PROJECT parameter to specify the subordinate projects that are formed)
set(PKG_<PROJECT>_BINARY_DIR "...")
set(PKG_<PROJECT>_INSTALL_DIR "...")

PKG(
  _IS_COMPONENT         FALSE
  _IS_COMPONENTS        FALSE
  _NAME                 ""
  _PROJECT              "${PROJECT_NAME}" | ""        # _IS_COMPONENT is undefined, the value is always empty
  _VERSION              propertie VERSION | ""
  _COMPATIBILITY        "AnyNewerVersion"
  _DEBUG_POSTFIX        ""
  _SHARED_LIBS          FALSE
  _BINARY_DIR           "${CMAKE_BINARY_DIR}"
  _BINARY_BIN_DIR       "bin"
  _BINARY_LIB_DIR       "lib"
  _INSTALL_DIR          "${CMAKE_INSTALL_PREFIX}"
  _INSTALL_INCLUDE_DIR  "include"
  _INSTALL_BIN_DIR      "bin"
  _INSTALL_LIB_DIR      "lib"
  _ADD_LIB_SUFFIX       FALSE
  _INCLUDE_FILES        ""
  _INCLUDE_DIRS         ""
  _INCLUDE_EXCLUDE_REG  ""
  _INCLUDE_DESTINATION  "<_INSTALL_INCLUDE_DIR>"
  _DISABLE_INTERFACE    FALSE
  _MODE                 "Development"
  _NAMESPACE            ""
  _EXPORT_HEADER        ""
  _EXPORT_MACRO         "<_NAME>_API"|"<_PROJECT>_<_NAME>_API"    # TO UPPER CASE
  _INSTALL_PDB          FALSE
  _DISABLE_CONFIG       FALSE
  _DISABLE_VERSION      FALSE
  _CONFIG_TEMPLATE      "${CMAKE_SOURCE_DIR}/cmake/PKG_normal-config.cmake.in" | "${CMAKE_SOURCE_DIR}/cmake/PKG_components-config.cmake.in"
  _ADD_UNINSTALL        FALSE
  _UNINSTALL_TEMPLATE   "${CMAKE_SOURCE_DIR}/cmake/PKG_cmake_uninstall.cmake.in"
  _UNINSTALL_ADDITIONAL ""
)

# Automatically defined variables after calling PKG(... _EXPORT_HEADER "..." ...).
# Export header directory. If the value of _EXPORT_HEADER is "a/b/exp. h", then the variable value will be "a/b".
message(${PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR})
message(PKG_<_NAME>_EXPORT_HEADER_DIR)

```



## Parameter Introduction

| Parameter Name        | Type        | Default Value                                                | Illustrate                                                   |
| --------------------- | ----------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| _IS_COMPONENT         | option      |                                                              | The components of the `_PROJECT` project are currently being installed |
| _IS_COMPONENTS        | option      |                                                              | A component set project is currently being installed, and a component set project cannot be a buildable target |
| _NAME                 | one value   |                                                              | Project Name/Component Name                                  |
| _PROJECT              | one value   | "${PROJECT_NAME}"                                            | Available when `_IS_COMPONENT` definition, its purpose is to specify the name of the project to which the component belongs |
| _VERSION              | one value   | propertie VERSION \| Undefined                               | version                                                      |
| _COMPATIBILITY        | one value   | "AnyNewerVersion"                                            | Defines the version compatibility of the target.<br/>Supported values:`AnyNewerVersion` \| `SameMajorVersion` \| `SameMinorVersion` \| `ExactVersion` |
| _DEBUG_POSTFIX        | one value   |                                                              | Add a flag after the file name of the Debug compile file, for example: "D" |
| _SHARED_LIBS          | option      |                                                              | The value of the `BUILD_SHARED_LIBS` variable that specifies the scope of the function will be used in `PKG_components-config.cmake.in` |
| _BINARY_DIR           | one value   | "${CMAKE_BINARY_DIR}"                                        | Specifies the binary directory of the project                |
| _BINARY_BIN_DIR       | one value   | "bin"                                                        | Specifies the runtime directory of the project's binary directory, relative to `_BINARY_DIR`, and can also define an absolute path |
| _BINARY_LIB_DIR       | one value   | "lib"                                                        | Specifies the library directory of the project's binary directory, relative to `_BINARY_DIR`, and can also define an absolute path |
| _INSTALL_DIR          | one value   | "${CMAKE_INSTALL_PREFIX}"                                    | Specifies the installation directory for the project         |
| _INSTALL_INCLUDE_DIR  | one value   | "include"                                                    | Specifies the include directory of the project's installation directory, relative to `_INSTALL_DIR`, or to define an absolute path |
| _INSTALL_BIN_DIR      | one value   | "bin"                                                        | Specifies the runtime directory of the project's installation directory, relative to `_INSTALL_DIR`, and can also define an absolute path |
| _INSTALL_LIB_DIR      | one value   | "lib"                                                        | Specifies the library directory of the project's installation directory, relative to `_INSTALL_DIR`, or to define an absolute path |
| _ADD_LIB_SUFFIX       | option      |                                                              | Add the suffix "64" to the library directory name, which is valid only for 64-bit systems |
| _INCLUDE_FILES        | multi value |                                                              | The file location of the target public header, which can be an absolute or relative path, relative to `CMAKE_CURRENT_SOURCE_DIR`, supports generator expressions |
| _INCLUDE_DIRS         | multi value |                                                              | The directory location of the target public header, which can be absolute or relative, relative to `CMAKE_CURRENT_SOURCE_DIR`, supports generator expressions |
| _INCLUDE_EXCLUDE_REG  | one value   |                                                              | The regular expression that matches the full path of the file or directory is ignored when the target public header is installed |
| _INCLUDE_DESTINATION  | one value   | "<_INSTALL_INCLUDE_DIR>"                                     | The `INSTALL_INTERFACE` that matches the target contains directories |
| _DISABLE_INTERFACE    | option      |                                                              | It is forbidden to include the directory specified by the `_INCLUDE_DESTINATION` in the `INSTALL_INTERFACE` |
| _MODE                 | one value   | "Development"                                                | Installation mode, `Runtime` means that header files in `_INSTALL_INCLUDE_DIR` and library files in `_INSTALL_LIB_DIR` are not packaged.<br/>Supported values: `Runtime` \| `Development` |
| _NAMESPACE            | one value   |                                                              | Use the namespace to install your target, do not add extra '::' |
| _EXPORT_HEADER        | one value   |                                                              | Here you set the absolute or relative path of the file that creates the export header, relative to the` CMAKE_CURRENT_BINARY_DIR` |
| _EXPORT_MACRO         | one value   | "\<\_NAME\>\_API" \|<br/>"\<\_PROJECT\>_\<\_NAME\>\_API"     | Macro definitions in the export header                       |
| _INSTALL_PDB          | option      |                                                              | Install the PDB file, only MSVC is valid                     |
| _DISABLE_CONFIG       | option      |                                                              | Disable `*-config.cmake` file generation                     |
| _DISABLE_VERSION      | option      |                                                              | Always disable `*-config-version.cmake` file generation, and if there is no parameter value based on `_VERSION` and propertie `VERSION` for `_NAME` is not defined, `*-config-version.cmake` file will not be generated |
| _CONFIG_TEMPLATE      | one value   | "\${CMAKE\_SOURCE\_DIR}/<br/>cmake/PKG\_normal-config.cmake.in" \| "\${CMAKE\_SOURCE\_DIR}/<br/>cmake/PKG\_components-config.cmake.in" | The config template file used to generate the `*-config.cmake` file |
| _ADD_UNINSTALL        | option      |                                                              | Available when `_IS_COMPONENT` is undefined, this parameter is used to add an uninstall command |
| _UNINSTALL_TEMPLATE   | one value   | "\${CMAKE\_SOURCE\_DIR}/<br/>cmake/PKG_cmake\_uninstall.cmake.in" | Available when `_IS_COMPONENT` is undefined, a template file for unload operations |
| _UNINSTALL_ADDITIONAL | multi value |                                                              | Available when `_IS_COMPONENT` is undefined, it is used to attach the unloaded file or directory, which is unloaded together with the unload operation |



## Global Variables

If the `_BINARY_DIR` | `_INSTALL_DIR` parameter is not customized, the altered amount value is used as its parameter value, which affects components attached to \<PROJECT\>(Use the `_PROJECT` parameter to specify the subordinate projects that are formed).

- `PKG_<PROJECT>_BINARY_DIR`

- `PKG_<PROJECT>_INSTALL_DIR`

  

## Export Variables

Automatically defined variables after calling PKG(... _EXPORT_HEADER "..." ...)

Export header directory. If the value of _EXPORT_HEADER is "a/b/exp. h", then the variable value will be "a/b".

- `PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR` Valid when _IS_COMPONENT is TRUE
- `PKG_<_NAME>_EXPORT_HEADER_DIR`            Valid when neither the _IS_COMPONENT nor the _IS_COMPONENTS is defined
