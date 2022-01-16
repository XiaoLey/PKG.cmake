# PKG.cmake - CMake scripts for encapsulating general or multi-component projects
# ----------------------------------------
# See https://github.com/XiaoLey/PKG.cmake for usage and update instructions.
#
# ----------------------------------------
# MIT License
#
# Copyright (c) 2022 XiaoLey
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------


cmake_minimum_required(VERSION 3.20 FATAL_ERROR)

# PKG.cmake version control
set(CURRENT_PKG_VERSION 0.9.1-release)
if (NOT "${CURRENT_PKG_VERSION}" MATCHES "-release$")
    message(WARNING "PKG: The current PKG.cmake is not a stable version, if you want to use stable functions, please download the release version.")
endif ()


#===============================================================================
#
# @brief Quickly package projects or multi-component projects
function(PKG)
    PKG_check_empty_and_change_relative(PKG_FILE_CACHE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_PKG_cache" "${CMAKE_CURRENT_SOURCE_DIR}")

    set(
      __options
      _IS_COMPONENT _IS_COMPONENTS _ADD_LIB_SUFFIX _DISABLE_INTERFACE _INSTALL_PDB
      _ADD_UNINSTALL _SHARED_LIBS _DISABLE_CONFIG _DISABLE_VERSION
    )
    set(
      __oneValueArgs
      _NAME _PROJECT _VERSION _COMPATIBILITY _DEBUG_POSTFIX _BINARY_DIR _BINARY_BIN_DIR
      _BINARY_LIB_DIR _NAMESPACE _EXPORT_HEADER _EXPORT_MACRO _EXPORT_INSTALL_DIR
      _CONFIG_TEMPLATE _INCLUDE_EXCLUDE_REG _MODE _INCLUDE_DESTINATION
      _INSTALL_DIR _INSTALL_INCLUDE_DIR _INSTALL_BIN_DIR _INSTALL_LIB_DIR
      _UNINSTALL_TEMPLATE
    )
    set(
      __multiValueArgs
      _DEPENDENCIES _INCLUDE_FILES _INCLUDE_DIRS _UNINSTALL_ADDITIONAL
    )
    cmake_parse_arguments(PARSE_ARGV 0 __cf "${__options}" "${__oneValueArgs}" "${__multiValueArgs}")
    PKG_unset(__options __oneValueArgs __multiValueArgs)


    # If _NAME is not specified, jump out of the function directly
    if (NOT __cf__NAME OR "${__cf__NAME}" STREQUAL "")
        message(FATAL_ERROR "PKG: `_NAME` keyword must be defined")
        return()
    endif ()

    if (__cf__IS_COMPONENT AND __cf__IS_COMPONENTS)
        message(FATAL_ERROR "PKG: `_IS_COMPONENT` and `_IS_COMPONENTS` keywords cannot be defined both at the same time")
        return()
    endif ()


    # Initialize all parameter values
    if (__cf__IS_COMPONENT)
        PKG_check_empty(__cf__PROJECT "${PROJECT_NAME}")
    else ()
        set(__cf__PROJECT "")
    endif ()

    if (NOT __cf__VERSION OR "${__cf__VERSION}" STREQUAL "")
        get_target_property(__version "${__cf__NAME}" VERSION)
        if (NOT "${__version}" STREQUAL "NOTFOUND")
            set(__cf__VERSION "${__version}")
        endif ()
        PKG_unset(__version)
    endif ()

    PKG_check_empty(__cf__COMPATIBILITY "AnyNewerVersion")

    if (DEFINED __cf__SHARED_LIBS AND __cf__SHARED_LIBS)
        set(BUILD_SHARED_LIBS "${__cf__SHARED_LIBS}")
    endif ()

    if (NOT __cf__BINARY_DIR OR "${__cf__BINARY_DIR}" STREQUAL "")
        if (__cf__IS_COMPONENT)
            if (NOT PKG_${__cf__PROJECT}_BINARY_DIR OR "${PKG_${__cf__PROJECT}_BINARY_DIR}" STREQUAL "")
                set(__cf__BINARY_DIR "${CMAKE_BINARY_DIR}")
            else ()
                set(__cf__BINARY_DIR "${PKG_${__cf__PROJECT}_BINARY_DIR}")
            endif ()
        else ()
            if (NOT PKG_${__cf__NAME}_BINARY_DIR OR "${PKG_${__cf__NAME}_BINARY_DIR}" STREQUAL "")
                set(__cf__BINARY_DIR "${CMAKE_BINARY_DIR}")
            else ()
                set(__cf__BINARY_DIR "${PKG_${__cf__NAME}_BINARY_DIR}")
            endif ()
        endif ()
    endif ()

    PKG_check_empty_and_change_relative(__cf__BINARY_BIN_DIR "${__cf__BINARY_DIR}/bin" "${__cf__BINARY_DIR}")

    if (NOT __cf__BINARY_LIB_DIR OR "${__cf__BINARY_LIB_DIR}" STREQUAL "")
        if (__cf__ADD_LIB_SUFFIX)
            PKG_get_COMPILER_BITS()
            PKG_set_LIB_SUFFIX()
            set(__cf__BINARY_LIB_DIR "${__cf__BINARY_DIR}/lib${LIB_SUFFIX}")
            PKG_unset(COMPILER_BITS LIB_SUFFIX)
        else ()
            set(__cf__BINARY_LIB_DIR "${__cf__BINARY_DIR}/lib")
        endif ()
    else ()
        PKG_change_relative(__cf__BINARY_LIB_DIR "${__cf__BINARY_DIR}")

        if (__cf__ADD_LIB_SUFFIX)
            PKG_get_COMPILER_BITS()
            PKG_set_LIB_SUFFIX()
            set(__cf__BINARY_LIB_DIR "${__cf__BINARY_LIB_DIR}${LIB_SUFFIX}")
            PKG_unset(COMPILER_BITS LIB_SUFFIX)
        endif ()
    endif ()

    if (NOT __cf__INSTALL_DIR OR "${__cf__INSTALL_DIR}" STREQUAL "")
        if (__cf__IS_COMPONENT)
            if (NOT PKG_${__cf__PROJECT}_INSTALL_DIR OR "${PKG_${__cf__PROJECT}_INSTALL_DIR}" STREQUAL "")
                set(__cf__INSTALL_DIR "${CMAKE_INSTALL_PREFIX}")
            else ()
                set(__cf__INSTALL_DIR "${PKG_${__cf__PROJECT}_INSTALL_DIR}")
            endif ()
        else ()
            if (NOT PKG_${__cf__NAME}_INSTALL_DIR OR "${PKG_${__cf__NAME}_INSTALL_DIR}" STREQUAL "")
                set(__cf__INSTALL_DIR "${CMAKE_INSTALL_PREFIX}")
            else ()
                set(__cf__INSTALL_DIR "${PKG_${__cf__NAME}_INSTALL_DIR}")
            endif ()
        endif ()
    endif ()

    PKG_check_empty_and_change_relative(__cf__INSTALL_INCLUDE_DIR "${__cf__INSTALL_DIR}/include" "${__cf__INSTALL_DIR}")

    PKG_check_empty_and_change_relative(__cf__INSTALL_BIN_DIR "${__cf__INSTALL_DIR}/bin" "${__cf__INSTALL_DIR}")

    if (NOT __cf__INSTALL_LIB_DIR OR "${__cf__INSTALL_LIB_DIR}" STREQUAL "")
        if (__cf__ADD_LIB_SUFFIX)
            PKG_get_COMPILER_BITS()
            PKG_set_LIB_SUFFIX()
            set(__cf__INSTALL_LIB_DIR "${__cf__INSTALL_DIR}/lib${LIB_SUFFIX}")
            PKG_unset(COMPILER_BITS LIB_SUFFIX)
        else ()
            set(__cf__INSTALL_LIB_DIR "${__cf__INSTALL_DIR}/lib")
        endif ()
    else ()
        PKG_change_relative(__cf__INSTALL_LIB_DIR "${__cf__INSTALL_DIR}")

        if (__cf__ADD_LIB_SUFFIX)
            PKG_get_COMPILER_BITS()
            PKG_set_LIB_SUFFIX()
            set(__cf__INSTALL_LIB_DIR "${__cf__INSTALL_LIB_DIR}${LIB_SUFFIX}")
            PKG_unset(COMPILER_BITS LIB_SUFFIX)
        endif ()
    endif ()

    PKG_check_empty(__cf__INCLUDE_DESTINATION "${__cf__INSTALL_INCLUDE_DIR}")

    PKG_check_empty(__cf__MODE "Development")

    if (__cf__IS_COMPONENT)
        PKG_check_empty(__cf__NAMESPACE "${__cf__PROJECT}")
    endif ()

    if (NOT __cf__EXPORT_MACRO OR "${__cf__EXPORT_MACRO}" STREQUAL "")
        if (NOT __cf__PROJECT OR "${__cf__PROJECT}" STREQUAL "")
            string(TOUPPER "${__cf__NAME}_API" __export_macro)
        else ()
            string(TOUPPER "${__cf__PROJECT}_${__cf__NAME}_API" __export_macro)
        endif ()
        set(__cf__EXPORT_MACRO "${__export_macro}")
        PKG_unset(__export_macro)
    endif ()

    PKG_check_empty_and_change_relative(__cf__EXPORT_INSTALL_DIR "${__cf__INSTALL_INCLUDE_DIR}" "${__cf__INSTALL_DIR}")

    if (NOT __cf__DISABLE_CONFIG)
        if (NOT __cf__CONFIG_TEMPLATE OR "${__cf__CONFIG_TEMPLATE}" STREQUAL "")
            if (__cf__IS_COMPONENTS)
                # Generate configuration file
                PKG_content_cmake_components_config_cmake_in(__file_content)
                file(WRITE "${PKG_FILE_CACHE_DIR}/PKG_components-config.cmake.in" "${__file_content}")
                set(__cf__CONFIG_TEMPLATE "${PKG_FILE_CACHE_DIR}/PKG_components-config.cmake.in")
                PKG_unset(__file_content)
            else ()
                # Generate configuration file
                PKG_content_cmake_normal_config_cmake_in(__file_content "${__cf__DEPENDENCIES}")
                file(WRITE "${PKG_FILE_CACHE_DIR}/PKG_normal-config.cmake.in" "${__file_content}")
                set(__cf__CONFIG_TEMPLATE "${PKG_FILE_CACHE_DIR}/PKG_normal-config.cmake.in")
                PKG_unset(__file_content)
            endif ()
        endif ()

        if (NOT EXISTS "${__cf__CONFIG_TEMPLATE}")
            message(FATAL_ERROR "PKG: \"${__cf__CONFIG_TEMPLATE}\" file does not exist")
        endif ()
    else ()
        # If the value has been customized, a prompt will pop up
        if (DEFINED __cf__CONFIG_TEMPLATE AND NOT "${__cf__CONFIG_TEMPLATE}" STREQUAL "")
            message("PKG: Keyword \"_CONFIG_TEMPLATE\" for \"${__cf__NAME}\" target will be ignored")
        endif ()
    endif ()

    if (__cf__IS_COMPONENT)
        set(__cf__ADD_UNINSTALL FALSE)
    endif ()

    if (__cf__ADD_UNINSTALL)
        if (NOT __cf__UNINSTALL_TEMPLATE OR "${__cf__UNINSTALL_TEMPLATE}" STREQUAL "")
            # Generate configuration file
            PKG_content_cmake_uninstall_cmake_in(__file_content)
            file(WRITE "${PKG_FILE_CACHE_DIR}/PKG_cmake_uninstall.cmake.in" "${__file_content}")
            set(__cf__UNINSTALL_TEMPLATE "${PKG_FILE_CACHE_DIR}/PKG_cmake_uninstall.cmake.in")
            PKG_unset(__file_content)
        endif ()

        if (NOT EXISTS "${__cf__UNINSTALL_TEMPLATE}")
            message(FATAL_ERROR "PKG: \"${__cf__UNINSTALL_TEMPLATE}\" file does not exist")
        endif ()
    else ()
        set(__cf__UNINSTALL_TEMPLATE "")
    endif ()


    # PKG-specific targets, some operations for PKG that override CMake's default actions
    if (__cf__IS_COMPONENT)
        if (NOT __PKG_${__cf__PROJECT}_${__cf__NAME}_SPECIFIC_TARGET OR "${__PKG_${__cf__PROJECT}_${__cf__NAME}_SPECIFIC_TARGET}" STREQUAL "")
            string(RANDOM LENGTH 12 ALPHABET "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" __PKG_specific_target)
            set(__PKG_${__cf__PROJECT}_${__cf__NAME}_SPECIFIC_TARGET "_PKG_${__PKG_specific_target}" CACHE INTERNAL "" FORCE)
        endif ()
        add_custom_target(${__PKG_${__cf__PROJECT}_${__cf__NAME}_SPECIFIC_TARGET} ALL)
        add_dependencies(${__cf__NAME} ${__PKG_${__cf__PROJECT}_${__cf__NAME}_SPECIFIC_TARGET})
    else ()
        if (NOT __PKG_${__cf__NAME}_SPECIFIC_TARGET OR "${__PKG_${__cf__NAME}_SPECIFIC_TARGET}" STREQUAL "")
            string(RANDOM LENGTH 12 ALPHABET "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" __PKG_specific_target)
            set(__PKG_${__cf__NAME}_SPECIFIC_TARGET "_PKG_${__PKG_specific_target}" CACHE INTERNAL "" FORCE)
        endif ()
        add_custom_target(${__PKG_${__cf__NAME}_SPECIFIC_TARGET} ALL)
        if (NOT __cf__IS_COMPONENTS)
            add_dependencies(${__cf__NAME} ${__PKG_${__cf__NAME}_SPECIFIC_TARGET})
        endif ()
    endif ()
    PKG_unset(__PKG_specific_target)

    # Modify the part that is automatically generated by the relevant CMake
    set(CMAKE_INSTALL_PREFIX "${__cf__INSTALL_DIR}")
    if (NOT __cf__IS_COMPONENTS)
        PKG_generate_cmake_install_PKG_cmake_file()
    endif ()


    # Export unapproved keywords
    set(__install_files_dirs "${__cf_UNPARSED_ARGUMENTS}")
    list(FILTER __install_files_dirs INCLUDE REGEX "^_INSTALL_EXT_(FILES|DIRS)_[0-9]+$")
    set(__export_files_dirs "${__cf_UNPARSED_ARGUMENTS}")
    list(FILTER __export_files_dirs INCLUDE REGEX "^_EXPORT_EXT_(FILES|DIRS)_[0-9]+$")
    list(APPEND __all_keywords ${__install_files_dirs} ${__export_files_dirs})
    cmake_parse_arguments(__exp_ins "" "" "${__all_keywords}" "${__cf_UNPARSED_ARGUMENTS}")

    # Load _INSTALL_EXT_FILES_<N> and _INSTALL_EXT_DIRS_<N>
    # Arguments of _INSTALL_EXT_FILES_<N> and _INSTALL_EXT_DIRS_<N> are not allowed to have only one
    foreach (__file_dir IN LISTS __install_files_dirs)
        # Make sure all __exp_ins__INSTALL_EXT_... have two or more arguments, otherwise ignore this keyword
        list(LENGTH __exp_ins_${__file_dir} __count)
        if (__count LESS_EQUAL 1)
            message(WARNING "PKG: Insufficient arguments to ${__file_dir} (two or more required), it will be ignored")
            # Delete the keyword and end the loop early
            list(REMOVE_ITEM __install_files_dirs "${__file_dir}")
            continue()
        endif ()

        # Get the value at the end of the list
        math(EXPR __last_index "${__count} - 1")
        list(GET __exp_ins_${__file_dir} ${__last_index} __last_value)
        # If it is not an absolute path, it becomes an absolute path
        PKG_change_relative(__last_value "${__cf__INSTALL_DIR}")
        # Make sure the last item of all __exp_ins__INSTALL_EXT_... is not an existing file
        # (because file cannot be used as installation directoriy)
        if (EXISTS "${__last_value}" AND NOT IS_DIRECTORY "${__last_value}")
            message(FATAL_ERROR "PKG: The last argument given by ${__file_dir} is an existing file, which is not allowed")
        endif ()

        # Remove the original last item and put the revised last element (ie "the installation directory of the file or project")
        list(POP_BACK __exp_ins_${__file_dir})
        list(APPEND __exp_ins_${__file_dir} "${__last_value}")
    endforeach ()
    PKG_unset(__file_dir __count __last_index __last_value)

    # Load _EXPORT_EXT_FILES_<N> and _EXPORT_EXT_DIRS_<N>
    # Arguments of _EXPORT_EXT_FILES_<N> and _EXPORT_EXT_DIRS_<N> are not allowed to have only one
    foreach (__file_dir IN LISTS __export_files_dirs)
        # Make sure all __exp_ins__EXPORT_EXT_... have two or more arguments, otherwise ignore this keyword
        list(LENGTH __exp_ins_${__file_dir} __count)
        if (__count LESS_EQUAL 1)
            message(WARNING "PKG: Insufficient arguments to ${__file_dir} (two or more required), it will be ignored")
            # Delete the keyword and end the loop early
            list(REMOVE_ITEM __export_files_dirs "${__file_dir}")
            continue()
        endif ()

        # Get the value at the end of the list
        math(EXPR __last_index "${__count} - 1")
        list(GET __exp_ins_${__file_dir} ${__last_index} __last_value)
        # If it is not an absolute path, it becomes an absolute path
        PKG_change_relative(__last_value "${__cf__BINARY_DIR}")
        # Make sure the last item of all __exp_ins__EXPORT_EXT_... is not an existing file
        # (because file cannot be used as installation directoriy)
        if (EXISTS "${__last_value}" AND NOT IS_DIRECTORY "${__last_value}")
            message(FATAL_ERROR "PKG: The last argument given by ${__file_dir} is an existing file, which is not allowed")
        endif ()

        # Remove the original last item and put the revised last element (ie "the installation directory of the file or project")
        list(POP_BACK __exp_ins_${__file_dir})
        list(APPEND __exp_ins_${__file_dir} "${__last_value}")
    endforeach ()
    PKG_unset(__file_dir __count __last_index __last_value)


    if (NOT __cf__IS_COMPONENTS)
        # Use the GenerateExportHeader module to create export headers
        if (DEFINED __cf__EXPORT_HEADER AND NOT "${__cf__EXPORT_HEADER}" STREQUAL "")
            # If no absolute path is specified, the relative path is relative to the
            # CMAKE_CURRENT_BINARY_DIR to synthesize the absolute path
            PKG_change_relative(__cf__EXPORT_HEADER "${CMAKE_CURRENT_BINARY_DIR}")

            PKG_generate_export_header("${__cf__NAME}")

            # Define PKG_<_PROJECT>_<_NAME>_EXPORT_HEADER_DIR or PKG_<_NAME>_EXPORT_HEADER_DIR
            get_filename_component(__export_header "${__cf__EXPORT_HEADER}" DIRECTORY)
            if (NOT __cf__IS_COMPONENTS AND NOT __cf__IS_COMPONENT)
                set(PKG_${__cf__NAME}_EXPORT_HEADER_DIR "${__export_header}" PARENT_SCOPE)
            elseif (__cf__IS_COMPONENT)
                set(PKG_${__cf__PROJECT}_${__cf__NAME}_EXPORT_HEADER_DIR "${__export_header}" PARENT_SCOPE)
            endif ()
            PKG_unset(__export_header)
        endif ()
        # set binary output
        PKG_project_export_properties("${__cf__NAME}")
        # install PDB
        PKG_project_install_pdb("${__cf__NAME}")
        # install target
        PKG_install_target("${__cf__NAME}")
        # Generates *-targets.cmake
        PKG_generate_target_targets("${__cf__NAME}")
    else ()
        if (DEFINED __cf__EXPORT_HEADER AND NOT "${__cf__EXPORT_HEADER}" STREQUAL "")
            message("PKG: Keyword \"_EXPORT_HEADER\" for \"${__cf__NAME}\" target will be ignored")
        endif ()
        if (DEFINED __cf__DEBUG_POSTFIX AND NOT "${__cf__DEBUG_POSTFIX}" STREQUAL "")
            message("PKG: Keyword \"_DEBUG_POSTFIX\" for \"${__cf__NAME}\" target will be ignored")
        endif ()
        if (DEFINED __cf__NAMESPACE AND NOT "${__cf__NAMESPACE}" STREQUAL "")
            message("PKG: Keyword \"_NAMESPACE\" for \"${__cf__NAME}\" target will be ignored")
        endif ()
    endif ()

    # Install includes
    PKG_install_includes("${__cf__NAME}")
    # Generate version config using CMakePackageConfigHelpers module
    if (NOT __cf__DISABLE_VERSION)
        PKG_generate_target_version_config("${__cf__NAME}")
    endif ()

    # Use the GenerateExportHeader module to set the config configuration file
    # (distinguish between normal libraries and component libraries)
    if (NOT __cf__DISABLE_CONFIG)
        PKG_generate_target_config(TARGET_NAME "${__cf__NAME}")
    endif ()


    # Install custom additional files and directories
    foreach (__file_dir IN LISTS __install_files_dirs)
        if ("${__file_dir}" MATCHES "_INSTALL_EXT_FILES_")
            PKG_install_files("${__exp_ins_${__file_dir}}")
        else ()
            PKG_install_dirs("${__exp_ins_${__file_dir}}")
        endif ()
    endforeach ()

    # Export custom additional files and directories
    foreach (__file_dir IN LISTS __export_files_dirs)
        if ("${__file_dir}" MATCHES "_EXPORT_EXT_FILES_")
            PKG_export_files("${__cf__NAME}" "${__exp_ins_${__file_dir}}")
        else ()
            PKG_export_dirs("${__cf__NAME}" "${__exp_ins_${__file_dir}}")
        endif ()
    endforeach ()

    if (NOT __cf__IS_COMPONENTS)
        PKG_set_rpath()
    endif ()


    # Add uninstall command
    if (__cf__ADD_UNINSTALL)
        if (NOT __cf__UNINSTALL_ADDITIONAL OR "${__cf__UNINSTALL_ADDITIONAL}" STREQUAL "")
            PKG_add_uninstall_command()
        else ()
            PKG_add_uninstall_command("${__cf__UNINSTALL_ADDITIONAL}")
        endif ()
    endif ()


    # Output information
    if (__cf__IS_COMPONENT)
        message(STATUS "PKG: [Project Component]: \"${__cf__PROJECT}-${__cf__NAME}\" build installation completed")
    elseif (__cf__IS_COMPONENTS)
        message(STATUS "PKG: [Multi-component Project]: \"${__cf__NAME}\" build installation completed")
    else ()
        message(STATUS "PKG: [Project]: \"${__cf__NAME}\" build installation completed")
    endif ()
endfunction()


# Determine whether the variable value is empty
# @parm path_variable   Path variable to process
# @parm default_value   Default value
# @param path_prefix    When the value is a relative path, this variable is the absolute path prefix
macro(PKG_check_empty path_variable default_value)
    if (NOT ${path_variable} OR "${${path_variable}}" STREQUAL "")
        set(${path_variable} "${default_value}")
    endif ()
endmacro()


# change the relative path to an absolute path
# @parm path_variable   Path variable to process
# @param path_prefix    When the value is a relative path, this variable is the absolute path prefix
macro(PKG_change_relative path_variable path_prefix)
    if (NOT "${${path_variable}}" MATCHES "^[a-zA-Z]:|^/")
        set(${path_variable} "${path_prefix}/${${path_variable}}")
    endif ()
endmacro()


# Determine whether the variable value is empty and change the relative path to an absolute path
# @parm path_variable   Path variable to process
# @parm default_value   Default value
# @param path_prefix    When the value is a relative path, this variable is the absolute path prefix
macro(PKG_check_empty_and_change_relative path_variable default_value path_prefix)
    if (NOT ${path_variable} OR "${${path_variable}}" STREQUAL "")
        set(${path_variable} "${default_value}")
    else ()
        if (NOT "${${path_variable}}" MATCHES "^[a-zA-Z]:|^/")
            set(${path_variable} "${path_prefix}/${${path_variable}}")
        endif ()
    endif ()
endmacro()


# Generate "cmake_install_PKG.cmake" file, and set to execute
function(PKG_generate_cmake_install_PKG_cmake_file)
    set(__cmake_install_pre_content [==========[
set(__install_file "${CMAKE_CURRENT_LIST_DIR}/cmake_install.cmake")

if (NOT EXISTS "${__install_file}")
  unset(__install_file)
  message(FATAL_ERROR "PKG: \"${__install_file}\" does not exist")
endif ()

message(STATUS "PKG: Executing: ${CMAKE_CURRENT_LIST_FILE}...")

file(READ "${__install_file}" __cmake_install_content)

string(REGEX MATCH "# PKG: Save the original CMAKE_INSTALL_PREFIX, then change it\n" __has_defined "${__cmake_install_content}")
if (NOT __has_defined OR "${__has_defined}" STREQUAL "")
  string(REPLACE "# Set the install prefix" [[
# PKG: Save the original CMAKE_INSTALL_PREFIX, then change it
set(__CMAKE_INSTALL_PREFIX_OLD "${CMAKE_INSTALL_PREFIX}")
set(CMAKE_INSTALL_PREFIX "@__INSTALL_DIR@")

# Set the install prefix]] __cmake_install_content "${__cmake_install_content}")
endif ()
unset(__has_defined)

string(REGEX MATCH "# PKG: Restore CMAKE_INSTALL_PREFIX\n" __has_defined "${__cmake_install_content}")
if (NOT __has_defined OR "${__has_defined}" STREQUAL "")
  string(APPEND __cmake_install_content [[
# PKG: Restore CMAKE_INSTALL_PREFIX
set(CMAKE_INSTALL_PREFIX "${__CMAKE_INSTALL_PREFIX_OLD}")
unset(__CMAKE_INSTALL_PREFIX_OLD)
]])
endif ()
unset(__has_defined)

# Get the *-targets.cmake file that will be installed, Modify the internal _IMPORT PREFIX variable
string(REGEX MATCHALL "[^\n]+" __content_list "${__cmake_install_content}")
foreach(__item IN LISTS __content_list)
  string(REGEX MATCH "file\\(INSTALL DESTINATION \"([a-zA-Z]:/|/).*@__TARGET@-targets\\.cmake\"\\)$" __aim "${__item}")

  if (DEFINED __aim AND NOT "${__aim}" STREQUAL "")
    string(REGEX MATCH "FILES \"([a-zA-Z]:/|/).*@__TARGET@-targets\\.cmake\"\\)$" __aim "${__aim}")
    string(REGEX REPLACE "^FILES \"|\"\\)$" "" __aim "${__aim}")

    if (DEFINED __aim AND NOT "${__aim}" STREQUAL "" AND EXISTS "${__aim}")
      file(READ "${__aim}" __aim_content)

      string(REGEX MATCH "# PKG: The installation prefix configured by this project\\.\n" __has_defined "${__aim_content}")
      if (NOT __has_defined OR "${__has_defined}" STREQUAL "")
        string(REGEX REPLACE "# Create imported target" [[
# PKG: The installation prefix configured by this project.
set(_IMPORT_PREFIX "@__INSTALL_DIR@")

# Create imported target]] __aim_content "${__aim_content}")

        file(WRITE "${__aim}" "${__aim_content}")
      endif ()
      unset(__has_defined)
      unset(__aim_content)
    endif()
    break()
  endif()
  unset(__aim)
endforeach()
unset(__item)
unset(__content_list)

file(WRITE "${__install_file}" "${__cmake_install_content}")

message(STATUS "PKG: Execution completed: ${CMAKE_CURRENT_LIST_FILE}")
unset(__install_file)
unset(__cmake_install_content)
]==========])
    string(REPLACE "@__INSTALL_DIR@" "${__cf__INSTALL_DIR}" __cmake_install_pre_content "${__cmake_install_pre_content}")
    string(REPLACE "@__TARGET@" "${__cf__NAME}" __cmake_install_pre_content "${__cmake_install_pre_content}")
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/cmake_install_PKG.cmake" "${__cmake_install_pre_content}")

    if (__cf__IS_COMPONENT)
        set(__specific_target "${__PKG_${__cf__PROJECT}_${__cf__NAME}_SPECIFIC_TARGET}")
    else ()
        set(__specific_target "${__PKG_${__cf__NAME}_SPECIFIC_TARGET}")
    endif ()
    add_custom_command(TARGET ${__specific_target} PRE_BUILD
                       COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_install_PKG.cmake"
                       VERBATIM)
    PKG_unset(__specific_target)
endfunction()


# Set the COMPILER_BITS variable to determine the compiler bits
# Example: get_COMPILER_BITS(32)
macro(PKG_get_COMPILER_BITS)
    # Violently judge 32 or 64 bits, and finally define the COMPILER_BITS variable with a value of 32 or 64
    # The -mx32 option sets int, long and pointer to 32 bits and generates code for AMD’s x86-64 architecture.
    set(COMPILER_BITS)
    if (CMAKE_SIZEOF_VOID_P STREQUAL "8"
        OR "${CMAKE_CXX_FLAGS}" MATCHES "-(m64|mx32)"
        OR "${CMAKE_C_FLAGS}" MATCHES "-(m64|mx32)"
        OR CMAKE_CL_64
        OR "${CMAKE_CXX_LIBRARY_ARCHITECTURE}" MATCHES "x86_64|x64|AMD_?64|amd_?64|IA64"
        OR "${CMAKE_C_LIBRARY_ARCHITECTURE}" MATCHES "x86_64|x64|AMD_?64|amd_?64|IA64"
        OR "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" MATCHES "64"
        OR "${CMAKE_C_COMPILER_ARCHITECTURE_ID}" MATCHES "64"
        OR "${CMAKE_GENERATOR}" MATCHES "W[iI][nN]64|IA64"
        OR "${CMAKE_ANDROID_ARCH}" MATCHES "64")
        set(COMPILER_BITS 64)
        set(CMAKE_SIZEOF_VOID_P 8)
    else ()
        set(COMPILER_BITS 32)
        set(CMAKE_SIZEOF_VOID_P 4)
    endif ()
endmacro()


# Set the LIB_SUFFIX variable according to the COMPILER_BITS variable (need to execute the get_COMPILER_BITS() macro first)
macro(PKG_set_LIB_SUFFIX)
    if (NOT DEFINED COMPILER_BITS)
        message(FATAL_ERROR "PKG: The `COMPILER_BITS` variable is not defined")
    endif ()

    if (COMPILER_BITS EQUAL 64)
        if (NOT DEFINED LIB_SUFFIX)
            set(LIB_SUFFIX "64")
        endif ()
    endif ()
endmacro()


# Export library properties
macro(PKG_project_export_properties target_name)
    # Add the suffix of the files generated by Debug
    if (DEFINED __cf__DEBUG_POSTFIX AND NOT "${__cf__DEBUG_POSTFIX}" STREQUAL "")
        set_target_properties("${target_name}" PROPERTIES DEBUG_POSTFIX "${__cf__DEBUG_POSTFIX}")
    endif ()

    get_property(__is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
    if (__is_multi_config)
        set_target_properties(
          ${target_name}
          PROPERTIES
          RUNTIME_OUTPUT_DIRECTORY_DEBUG "${__cf__BINARY_BIN_DIR}/Debug"
          RUNTIME_OUTPUT_DIRECTORY_RELEASE "${__cf__BINARY_BIN_DIR}/Release"
          RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${__cf__BINARY_BIN_DIR}/RelWithDebInfo"
          RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${__cf__BINARY_BIN_DIR}/MinSizeRel"
          LIBRARY_OUTPUT_DIRECTORY_DEBUG "${__cf__BINARY_LIB_DIR}/Debug"
          LIBRARY_OUTPUT_DIRECTORY_RELEASE "${__cf__BINARY_LIB_DIR}/Release"
          LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${__cf__BINARY_LIB_DIR}/RelWithDebInfo"
          LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL "${__cf__BINARY_LIB_DIR}/MinSizeRel"
          ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${__cf__BINARY_LIB_DIR}/Debug"
          ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${__cf__BINARY_LIB_DIR}/Release"
          ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${__cf__BINARY_LIB_DIR}/RelWithDebInfo"
          ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${__cf__BINARY_LIB_DIR}/MinSizeRel"
          PDB_OUTPUT_DIRECTORY_DEBUG "${__cf__BINARY_LIB_DIR}/Debug"
          PDB_OUTPUT_DIRECTORY_RELEASE "${__cf__BINARY_LIB_DIR}/Release"
          PDB_OUTPUT_DIRECTORY_RELWITHDEBINFO "${__cf__BINARY_LIB_DIR}/RelWithDebInfo"
          PDB_OUTPUT_DIRECTORY_MINSIZEREL "${__cf__BINARY_LIB_DIR}/MinSizeRel"
        )
    else ()
        set_target_properties(
          ${target_name}
          PROPERTIES
          RUNTIME_OUTPUT_DIRECTORY "${__cf__BINARY_BIN_DIR}"
          LIBRARY_OUTPUT_DIRECTORY "${__cf__BINARY_LIB_DIR}"
          ARCHIVE_OUTPUT_DIRECTORY "${__cf__BINARY_LIB_DIR}"
          PDB_OUTPUT_DIRECTORY "${__cf__BINARY_LIB_DIR}"
        )
    endif ()
    PKG_unset(__is_multi_config)
endmacro()


# Install PDB file (MSVC valid)
function(PKG_project_install_pdb target_name)
    if ("${__cf__MODE}" STREQUAL "Development" AND __cf__INSTALL_PDB)
        get_target_property(__type ${target_name} TYPE)
        if (MSVC AND NOT "${__type}" STREQUAL "STATIC_LIBRARY|EXECUTABLE")
            install(
              FILES "$<TARGET_PDB_FILE:${target_name}>"
              DESTINATION "${__cf__INSTALL_LIB_DIR}"
              COMPONENT Development
              OPTIONAL
              PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
            )
        else ()
            if (__cf__INSTALL_PDB)
                message("PKG: Option \"_INSTALL_PDB\" for \"${__cf__NAME}\" target is not valid")
            endif ()
        endif ()
        PKG_unset(__type)
    endif ()
endfunction()


# Install the include files
function(PKG_install_includes target_name)
    if ("${__cf__MODE}" STREQUAL "Development")
        if (DEFINED __cf__INCLUDE_DIRS AND NOT "${__cf__INCLUDE_DIRS}" STREQUAL "")
            if (DEFINED __cf__INCLUDE_EXCLUDE_REG AND NOT "${__cf__INCLUDE_EXCLUDE_REG}" STREQUAL "")
                # Install one by one to avoid spaces being used as separators
                foreach (__item IN LISTS __cf__INCLUDE_DIRS)
                    install(
                      DIRECTORY "${__item}"
                      DESTINATION "${__cf__INSTALL_INCLUDE_DIR}"
                      COMPONENT Development
                      FILE_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
                      DIRECTORY_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ
                      REGEX "${__cf__INCLUDE_EXCLUDE_REG}" EXCLUDE
                      PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
                    )
                endforeach ()
                PKG_unset(__item)
            else ()
                # Install one by one to avoid spaces being used as separators
                foreach (__item IN LISTS __cf__INCLUDE_DIRS)
                    install(
                      DIRECTORY "${__item}"
                      DESTINATION "${__cf__INSTALL_INCLUDE_DIR}"
                      COMPONENT Development
                      FILE_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
                      DIRECTORY_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ
                    )
                endforeach ()
                PKG_unset(__item)
            endif ()
        endif ()

        if (DEFINED __cf__INCLUDE_FILES AND NOT "${__cf__INCLUDE_FILES}" STREQUAL "")
            # Install one by one to avoid spaces being used as separators
            foreach (__item IN LISTS __cf__INCLUDE_FILES)
                install(
                  FILES "${__item}"
                  DESTINATION "${__cf__INSTALL_INCLUDE_DIR}"
                  COMPONENT Development
                  PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
                )
            endforeach ()
            PKG_unset(__item)
        endif ()
    endif ()
endfunction()


#  Install the given target
function(PKG_install_target target_name)
    if (NOT __cf__PROJECT OR "${__cf__PROJECT}" STREQUAL "")
        set(__target_export "${target_name}-targets")
    else ()
        set(__target_export "${__cf__PROJECT}-${target_name}-targets")
    endif ()
    if ("${__cf__MODE}" STREQUAL "Development")
        if (__cf__DISABLE_INTERFACE)
            install(
              TARGETS "${target_name}"
              EXPORT "${__target_export}"
              RUNTIME DESTINATION "${__cf__INSTALL_BIN_DIR}" COMPONENT Runtime
              LIBRARY DESTINATION "${__cf__INSTALL_LIB_DIR}" COMPONENT Development
              ARCHIVE DESTINATION "${__cf__INSTALL_LIB_DIR}" COMPONENT Development
            )
        else ()
            string(REPLACE "${CMAKE_INSTALL_PREFIX}/" "" __include_destination "${__cf__INCLUDE_DESTINATION}")
            # A successful replacement should have no "/" or drive letter at the beginning
            if ("${__include_destination}" MATCHES "^[a-zA-Z]:|^/")
                # Replacement failed, use original path
                set(__include_destination "${__cf__INCLUDE_DESTINATION}")
            endif ()

            install(
              TARGETS "${target_name}"
              EXPORT "${__target_export}"
              RUNTIME DESTINATION "${__cf__INSTALL_BIN_DIR}" COMPONENT Runtime
              LIBRARY DESTINATION "${__cf__INSTALL_LIB_DIR}" COMPONENT Development
              ARCHIVE DESTINATION "${__cf__INSTALL_LIB_DIR}" COMPONENT Development
              INCLUDES DESTINATION "${__include_destination}"
            )
            PKG_unset(__include_destination)
        endif ()
    else ()
        install(
          TARGETS "${target_name}"
          EXPORT "${__target_export}"
          RUNTIME DESTINATION "${__cf__INSTALL_BIN_DIR}" COMPONENT Runtime
        )
    endif ()
    PKG_unset(__target_export)
endfunction()


# Generates *-targets.cmake
function(PKG_generate_target_targets target_name)
    if ("${__cf__MODE}" STREQUAL "Development")
        if (NOT __cf__PROJECT OR "${__cf__PROJECT}" STREQUAL "")
            set(__final_name "${target_name}")
        else ()
            set(__final_name "${__cf__PROJECT}-${target_name}")
        endif ()

        if (NOT __cf__NAMESPACE OR "${__cf__NAMESPACE}" STREQUAL "")
            export(
              EXPORT "${__final_name}-targets"
              FILE "${__cf__BINARY_DIR}/cmake/${__final_name}-targets.cmake"
            )
            install(
              EXPORT "${__final_name}-targets"
              FILE "${__final_name}-targets.cmake"
              DESTINATION "${__cf__INSTALL_LIB_DIR}/cmake/${__final_name}"
              PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
            )
        else ()
            export(
              EXPORT "${__final_name}-targets"
              FILE "${__cf__BINARY_DIR}/cmake/${__final_name}-targets.cmake"
              NAMESPACE "${__cf__NAMESPACE}::"
            )
            install(
              EXPORT "${__final_name}-targets"
              FILE "${__final_name}-targets.cmake"
              NAMESPACE "${__cf__NAMESPACE}::"
              DESTINATION "${__cf__INSTALL_LIB_DIR}/cmake/${__final_name}"
              PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
            )
        endif ()
        PKG_unset(__final_name)
    endif ()
endfunction()


# Generate version config using CMakePackageConfigHelpers module
function(PKG_generate_target_version_config target_name)
    if (NOT __cf__VERSION OR "${__cf__VERSION}" STREQUAL "")
        return()
    endif ()

    if ("${__cf__MODE}" STREQUAL "Development")
        if (NOT __cf__PROJECT OR "${__cf__PROJECT}" STREQUAL "")
            set(__final_name "${target_name}")
        else ()
            set(__final_name "${__cf__PROJECT}-${target_name}")
        endif ()

        include(CMakePackageConfigHelpers)
        write_basic_package_version_file(
          "${__cf__BINARY_DIR}/cmake/${__final_name}-config-version.cmake"
          VERSION ${__cf__VERSION}
          COMPATIBILITY ${__cf__COMPATIBILITY}
        )
        install(
          FILES
          "${__cf__BINARY_DIR}/cmake/${__final_name}-config-version.cmake"
          DESTINATION "${__cf__INSTALL_LIB_DIR}/cmake/${__final_name}"
          COMPONENT Development
          PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
        )
        PKG_unset(__final_name)
    endif ()
endfunction()


#===============================================================================
#
# Generates *-config.cmake
# You can specify resource strings in arguments:
# TARGET_NAME           - one, the name of the target. (default: ${__cf__NAME})
# PATH_VARS             - mul, list of variables corresponding to PATH_VARS in configure_package_config_filea (no defaults)
function(PKG_generate_target_config)
    include(CMakeParseArguments)
    set(__options)
    set(__oneValueArgs
        TARGET_NAME)
    set(__multiValueArgs
        PATH_VARS)
    cmake_parse_arguments(__config "${__options}" "${__oneValueArgs}" "${__multiValueArgs}" "${ARGN}")
    PKG_unset(__options __oneValueArgs __multiValueArgs)

    PKG_check_empty(__config_TARGET_NAME "${__cf__NAME}")

    # If a namespace is declared, the namespace is used
    if (NOT __cf__PROJECT OR "${__cf__PROJECT}" STREQUAL "")
        set(__final_name "${__config_TARGET_NAME}")
    else ()
        set(__final_name "${__cf__PROJECT}-${__config_TARGET_NAME}")
    endif ()


    # Each component stores its own name so that the config file of its parent project can get a complete list of components
    set(__ENTIRE_LIBRARIES)
    if (__cf__IS_COMPONENT)
        if (DEFINED __cf__NAMESPACE AND NOT "${__cf__NAMESPACE}" STREQUAL "")
            set(__library_name "${__cf__NAMESPACE}::${__cf__NAME}")
        else ()
            set(__library_name "${__cf__NAME}")
        endif ()
        set(___ENTIRE_LIBRARIES_tmp "${__${__cf__PROJECT}_ENTIRE_LIBRARIES};${__library_name}")
        string(REGEX REPLACE "^;" "" ___ENTIRE_LIBRARIES_tmp "${___ENTIRE_LIBRARIES_tmp}")
        list(REMOVE_DUPLICATES ___ENTIRE_LIBRARIES_tmp)
        set(__${__cf__PROJECT}_ENTIRE_LIBRARIES "${___ENTIRE_LIBRARIES_tmp}" CACHE INTERNAL "" FORCE)
        PKG_unset(___ENTIRE_LIBRARIES_tmp)
    else ()
        set(__ENTIRE_LIBRARIES "${__${__cf__NAME}_ENTIRE_LIBRARIES}")
    endif ()


    string(RANDOM LENGTH 8 ALPHABET "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" __RAND)
    string(RANDOM LENGTH 6 ALPHABET "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" __RAND2)
    set(__FINAL_NAME "${__final_name}") # Used for variables in configuration files
    set(__FINAL_VERSION "${__cf__VERSION}") # Used for variables in configuration files
    set(__FINAL_INSTALL_DIR "${__cf__INSTALL_DIR}") # Used for _INSTALL_DIR in configuration files
    set(__FINAL_INSTALL_INCLUDE_DIR "${__cf__INSTALL_INCLUDE_DIR}") # Used for _INSTALL_INCLUDE_DIR in configuration files
    set(__FINAL_INSTALL_LIB_DIR "${__cf__INSTALL_LIB_DIR}") # Used for _INSTALL_LIB_DIR in configuration files
    set(__FINAL_INSTALL_BIN_DIR "${__cf__INSTALL_BIN_DIR}") # Used for _INSTALL_BIN_DIR in configuration files
    include(CMakePackageConfigHelpers)
    configure_package_config_file(
      "${__cf__CONFIG_TEMPLATE}"
      "${__cf__BINARY_DIR}/cmake/${__final_name}-config.cmake"
      INSTALL_DESTINATION "${__cf__INSTALL_LIB_DIR}/cmake/${__final_name}"
      PATH_VARS ${__config_PATH_VARS}
    )
    PKG_unset(__ENTIRE_LIBRARIES __RAND __RAND2 __FINAL_NAME __FINAL_VERSION __FINAL_INSTALL_DIR
              __FINAL_INSTALL_INCLUDE_DIR __FINAL_INSTALL_LIB_DIR __FINAL_INSTALL_BIN_DIR)

    install(
      FILES
      "${__cf__BINARY_DIR}/cmake/${__final_name}-config.cmake"
      DESTINATION "${__cf__INSTALL_LIB_DIR}/cmake/${__final_name}"
      COMPONENT Development
      PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
    )

    PKG_unset(__final_name)
endfunction()


# Generate library export header files (usually useful for dlls)
function(PKG_generate_export_header target_name)
    include(GenerateExportHeader)
    GENERATE_EXPORT_HEADER(${target_name}
                           EXPORT_MACRO_NAME "${__cf__EXPORT_MACRO}"
                           EXPORT_FILE_NAME "${__cf__EXPORT_HEADER}")

    if ("${__cf__MODE}" STREQUAL "Development")
        install(
          FILES "${__cf__EXPORT_HEADER}"
          DESTINATION "${__cf__EXPORT_INSTALL_DIR}"
          COMPONENT Development
          PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
        )
    endif ()
endfunction()


# Export extension files
function(PKG_export_files target_name files_list)
    # Remove the last element value in files_list (this value is the target directory)
    list(POP_BACK files_list __dir)
    # Install one by one to avoid spaces being used as separators
    foreach (__item IN LISTS files_list)
        # Make __item an absolute path
        PKG_change_relative(__item "${CMAKE_CURRENT_SOURCE_DIR}")
        # Get the parent path of the file
        get_filename_component(__file_parent_dir "${__item}" DIRECTORY)

        if (__cf__IS_COMPONENTS)
            add_custom_command(
              TARGET "${__PKG_${__cf__NAME}_SPECIFIC_TARGET}" POST_BUILD
              COMMAND "${CMAKE_COMMAND}" -E make_directory "${__dir}"   # Create parent directory
              COMMAND "${CMAKE_COMMAND}" -E copy "${__item}" "${__dir}"
              #COMMAND_EXPAND_LISTS     # Command expands the list, splits the list into commands
              VERBATIM
            )
        else ()
            add_custom_command(
              TARGET "${target_name}" PRE_LINK
              COMMAND "${CMAKE_COMMAND}" -E make_directory "${__dir}"   # Create parent directory
              COMMAND "${CMAKE_COMMAND}" -E copy "${__item}" "${__dir}"
              #COMMAND_EXPAND_LISTS     # Command expands the list, splits the list into commands
              VERBATIM
            )
        endif ()
    endforeach ()
    PKG_unset(__dir __item)
endfunction()


# Export extension dirs
function(PKG_export_dirs target_name files_list)
    # Remove the last element value in files_list (this value is the target directory)
    list(POP_BACK files_list __dir)
    # Install one by one to avoid spaces being used as separators
    foreach (__item IN LISTS files_list)
        # Make __item an absolute path
        PKG_change_relative(__item "${CMAKE_CURRENT_SOURCE_DIR}")

        # Determine the copy method according to whether there is a "/" at the end of __item
        # Define __dir_from and __dir_to
        string(REGEX REPLACE "([^\\])/$" "\\1" __dir_from "${__item}")
        if ("${__item}" MATCHES "[^\\]/$")
            set(__dir_to "${__dir}")
        else ()
            get_filename_component(__dir_to "${__dir_from}" NAME)
            set(__dir_to "${__dir}/${__dir_to}")
        endif ()

        if (__cf__IS_COMPONENTS)
            add_custom_command(
              TARGET "${__PKG_${__cf__NAME}_SPECIFIC_TARGET}" POST_BUILD
              COMMAND "${CMAKE_COMMAND}" -E copy_directory "${__dir_from}" "${__dir_to}"
              #COMMAND_EXPAND_LISTS     # Command expands the list, splits the list into commands
              VERBATIM
            )
        else ()
            add_custom_command(
              TARGET "${target_name}" PRE_LINK
              COMMAND "${CMAKE_COMMAND}" -E copy_directory "${__dir_from}" "${__dir_to}"
              #COMMAND_EXPAND_LISTS     # Command expands the list, splits the list into commands
              VERBATIM
            )
        endif ()
        PKG_unset(__dir_from __dir_to)
    endforeach ()
    PKG_unset(__dir __item)
endfunction()


# Install extension files
function(PKG_install_files files_list)
    # Remove the last element value in files_list (this value is the target directory)
    list(POP_BACK files_list __dir)
    # Install one by one to avoid spaces being used as separators
    foreach (__item IN LISTS files_list)
        install(
          FILES "${__item}"
          DESTINATION "${__dir}"
          # COMPONENT Development
          PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
          OPTIONAL
        )
    endforeach ()
    PKG_unset(__dir __item)
endfunction()


# Install extension dirs
function(PKG_install_dirs dirs_list)
    # Remove the last element value in dirs_list (this value is the target directory)
    list(POP_BACK dirs_list __dir)
    # Install one by one to avoid spaces being used as separators
    foreach (__item IN LISTS dirs_list)
        install(
          DIRECTORY "${__item}"
          DESTINATION "${__dir}"
          #COMPONENT Development
          FILE_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
          DIRECTORY_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ
          OPTIONAL
        )
    endforeach ()
    PKG_unset(__dir __item)
endfunction()


function(PKG_set_rpath)
    get_target_property(__install_rpaths ${__cf__NAME} INSTALL_RPATH)
    get_target_property(__build_rpaths ${__cf__NAME} BUILD_RPATH)
    list(APPEND __install_rpaths "${__cf__INSTALL_LIB_DIR}")
    list(APPEND __build_rpaths "${__cf__BINARY_LIB_DIR}")
    set_target_properties(
      ${__cf__NAME} PROPERTIES
      INSTALL_RPATH "${__install_rpaths}"
      BUILD_RPATH "${__build_rpaths}"
    )
endfunction()


# Add uninstall command
# INPUT:
#   ARGV     Other directories or files that need to be uninstalled together
# Example: PKG_add_uninstall_command(${CMAKE_INSTALL_PREFIX})
function(PKG_add_uninstall_command)
    foreach (arg ${ARGV})
        string(REGEX REPLACE "\;" "\\\\\\\\\\\\;" arg "${arg}")
        string(REGEX REPLACE "\"" "\\\\\"" arg "${arg}")
        string(REGEX REPLACE " " "\\\\ " arg "${arg}")
        string(REPLACE "(" "\\(" arg "${arg}")
        string(REPLACE ")" "\\)" arg "${arg}")
        string(REPLACE "{" "\\{" arg "${arg}")
        string(REPLACE "}" "\\}" arg "${arg}")
        list(APPEND CUSTOM_UNINSTALL_FILES "${arg}")
    endforeach ()

    configure_file(
      "${__cf__UNINSTALL_TEMPLATE}"
      "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
      IMMEDIATE @ONLY)

    # Add uninstall command
    add_custom_target(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
                      COMMENT "Uninstalling files installed by the project from the system..."
                      VERBATIM)
endfunction()


# batch release variables
# Example: PKG_unset(A B C)
macro(PKG_unset)
    foreach (__arg ${ARGN})
        unset(${__arg})
    endforeach ()
endmacro()


# "PKG_cmake_uninstall.cmake.in" files content
function(PKG_content_cmake_uninstall_cmake_in content)
    set(__content [===========================[
# If CUSTOM_UNINSTALL_FILES is defined, the files additionally specified
# in the CUSTOM_UNINSTALL_FILES list will be uninstalled together

if (NOT EXISTS "@CMAKE_CURRENT_BINARY_DIR@/install_manifest.txt")
    message(FATAL_ERROR "Cannot find install manifest: \"@CMAKE_CURRENT_BINARY_DIR@/install_manifest.txt\"")
endif ()

file(READ "@CMAKE_CURRENT_BINARY_DIR@/install_manifest.txt" files)
string(REGEX REPLACE "\;" "\\\;" files "${files}")  # Escape the original semicolon first
string(REGEX REPLACE "\n" ";" files "${files}")
list(REMOVE_DUPLICATES files)   # files deduplication
set(_CUSTOM_UNINSTALL_FILES @CUSTOM_UNINSTALL_FILES@)

foreach (file IN LISTS files _CUSTOM_UNINSTALL_FILES)
    message(STATUS "Uninstalling: \"$ENV{DESTDIR}${file}\"")
    if (EXISTS "$ENV{DESTDIR}${file}")
        #execute_process(
        #        COMMAND "@CMAKE_COMMAND@" -E remove \"$ENV{DESTDIR}${file}\"
        #        OUTPUT_VARIABLE rm_out
        #        RESULT_VARIABLE rm_resVal
        #)

        exec_program(
          "@CMAKE_COMMAND@" ARGS "-E rm -r \"$ENV{DESTDIR}${file}\""
          OUTPUT_VARIABLE rm_out
          RETURN_VALUE rm_resVal
        )

        if (NOT "${rm_resVal}" STREQUAL 0)
            message(FATAL_ERROR "Problem when removing \"$ENV{DESTDIR}${file}\" —— ${rm_resVal}")
        endif ()
    else ()
        message(STATUS "File \"$ENV{DESTDIR}${file}\" does not exist.")
    endif ()
endforeach ()
]===========================])
    string(REGEX REPLACE "^[\t\n\r ]+" "" __content "${__content}")
    set(${content} "${__content}" PARENT_SCOPE)
    PKG_unset(__content)
endfunction()


# "PKG_components-config.cmake.in" files content
function(PKG_content_cmake_components_config_cmake_in content)
    # BUILD_SHARED_LIBS
    # __FINAL_NAME
    # __FINAL_VERSION
    # __FINAL_INSTALL_INCLUDE_DIR
    # __FINAL_INSTALL_LIB_DIR
    # __FINAL_INSTALL_BIN_DIR
    set(__content [===========================[
####################################################################################
#
#    This file will define the following variables:
#      - @__FINAL_NAME@_INSTALL_PREFIX   : The @__FINAL_NAME@ installation directory.
#      - @__FINAL_NAME@_VERSION          : @__FINAL_NAME@ version number.
#      - @__FINAL_NAME@_ENTIRE_LIBS      : Full list of libraries in @__FINAL_NAME@.
#      - @__FINAL_NAME@_LIBS             : The list of libraries to link against.
#      - @__FINAL_NAME@_INCLUDE_DIRS     : The @__FINAL_NAME@ include directories.
#      - @__FINAL_NAME@_LIB_DIRS         : The @__FINAL_NAME@ library directories.
#      - @__FINAL_NAME@_BIN_DIRS         : The @__FINAL_NAME@ binary directories.
#      - @__FINAL_NAME@_SHARED           : If true, @__FINAL_NAME@ is a shared library.
#
####################################################################################

# Set the version number
set(@__FINAL_NAME@_VERSION "@__FINAL_VERSION@")

@PACKAGE_INIT@

# If true, it is a shared library
set(@__FINAL_NAME@_SHARED @BUILD_SHARED_LIBS@)
# binary directory location
if(EXISTS "@__FINAL_INSTALL_BIN_DIR@")
  list(APPEND @__FINAL_NAME@_BIN_DIRS "@__FINAL_INSTALL_BIN_DIR@")
endif()

set(__@__FINAL_NAME@_find_parts_required_@__RAND@)
if (@__FINAL_NAME@_FIND_REQUIRED)
  set(__@__FINAL_NAME@_find_parts_required_@__RAND@ REQUIRED)
endif ()
set(__@__FINAL_NAME@_find_parts_quiet_@__RAND@)
if (@__FINAL_NAME@_FIND_QUIETLY)
  set(__@__FINAL_NAME@_find_parts_quiet_@__RAND@ QUIET)
endif ()

get_filename_component(__@__FINAL_NAME@_install_prefix_@__RAND@ "${PACKAGE_PREFIX_DIR}" ABSOLUTE)

# Let components find each other, but don't overwrite CMAKE_PREFIX_PATH
set(__@__FINAL_NAME@_CMAKE_PREFIX_PATH_old_@__RAND@ "${CMAKE_PREFIX_PATH}")
set_and_check(CMAKE_PREFIX_PATH "${__@__FINAL_NAME@_install_prefix_@__RAND@}")


foreach (__@__FINAL_NAME@_module_@__RAND2@ ${@__FINAL_NAME@_FIND_COMPONENTS})
  if (@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_FOUND)
    continue()
  endif()

  find_package(@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}
               ${__@__FINAL_NAME@_find_parts_quiet_@__RAND@} ${__@__FINAL_NAME@_find_parts_required_@__RAND@}
               PATHS "${__@__FINAL_NAME@_install_prefix_@__RAND@}" NO_DEFAULT_PATH)
  set(@__FINAL_NAME@_FOUND "${@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_FOUND}")

  if (NOT @__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_FOUND)
    if (@__FINAL_NAME@_FIND_REQUIRED_${__@__FINAL_NAME@_module_@__RAND2@})
      set_and_check(@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@ "@__FINAL_INSTALL_LIB_DIR@/cmake/@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}/@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}-config.cmake")
      set(__@__FINAL_NAME@_notfound_message_@__RAND@ "${__@__FINAL_NAME@_notfound_message_@__RAND@}Failed to load @__FINAL_NAME@ component \"${__@__FINAL_NAME@_module_@__RAND2@}\", config file \"${@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@}\"\n")
      unset(@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@)
    elseif (NOT @__FINAL_NAME@_FIND_QUIETLY)
      set_and_check(@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@ "@__FINAL_INSTALL_LIB_DIR@/cmake/@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}/@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}-config.cmake")
      if (NOT EXISTS "${@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@}")
        message(WARNING "Failed to find @__FINAL_NAME@ component \"${__@__FINAL_NAME@_module_@__RAND2@}\" config file at \"${@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@}\"")
      else ()
        message(WARNING "Failed to load @__FINAL_NAME@ component \"${__@__FINAL_NAME@_module_@__RAND2@}\", config file \"${@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@}\"")
      endif ()
      unset(@__FINAL_NAME@-${__@__FINAL_NAME@_module_@__RAND2@}_CONFIG_PATH_@__RAND@)
    endif ()
  else ()
    # For backward compatibility set the LIBRARIES variable
    string(REGEX MATCH "[^;]+::${__@__FINAL_NAME@_module_@__RAND2@};|[^;]+::${__@__FINAL_NAME@_module_@__RAND2@}$" __@__FINAL_NAME@_target_@__RAND@ "@__ENTIRE_LIBRARIES@")
    if (NOT __@__FINAL_NAME@_target_@__RAND@ OR "${__@__FINAL_NAME@_target_@__RAND@}" STREQUAL "")
      string(REGEX MATCH ";${__@__FINAL_NAME@_module_@__RAND2@};|^${__@__FINAL_NAME@_module_@__RAND2@};|;${__@__FINAL_NAME@_module_@__RAND2@}$|^${__@__FINAL_NAME@_module_@__RAND2@}$" __@__FINAL_NAME@_target_@__RAND@ "@__ENTIRE_LIBRARIES@")
    endif ()
    if (NOT __@__FINAL_NAME@_target_@__RAND@ OR "${__@__FINAL_NAME@_target_@__RAND@}" STREQUAL "")
      message(FATAL_ERROR "@__FINAL_NAME@: Could not find the \"${__@__FINAL_NAME@_module_@__RAND2@}\" component")
    endif ()
    string(REGEX REPLACE "^;" "" __@__FINAL_NAME@_target_@__RAND@ "${__@__FINAL_NAME@_target_@__RAND@}")
    string(REGEX REPLACE ";$" "" __@__FINAL_NAME@_target_@__RAND@ "${__@__FINAL_NAME@_target_@__RAND@}")
    list(APPEND @__FINAL_NAME@_LIBS "${__@__FINAL_NAME@_target_@__RAND@}")

    # Add the include's directories of the component to @__FINAL_NAME@_INCLUDE_DIRS
    get_target_property(__${__@__FINAL_NAME@_module_@__RAND2@}_included_dirs_@__RAND@ "${__@__FINAL_NAME@_target_@__RAND@}" INTERFACE_INCLUDE_DIRECTORIES)
    # Append value in @__FINAL_NAME@_INCLUDE_DIRS
    list(APPEND @__FINAL_NAME@_INCLUDE_DIRS "${__${__@__FINAL_NAME@_module_@__RAND2@}_included_dirs_@__RAND@}")
    list(REMOVE_DUPLICATES @__FINAL_NAME@_INCLUDE_DIRS)

    unset(__@__FINAL_NAME@_target_@__RAND@)
    unset(__${__@__FINAL_NAME@_module_@__RAND2@}_included_dirs_@__RAND@)
  endif ()
endforeach ()
unset(__@__FINAL_NAME@_module_@__RAND2@)


# Define @__FINAL_NAME@_ENTIRE_LIBS
set(@__FINAL_NAME@_ENTIRE_LIBS "@__ENTIRE_LIBRARIES@")

# The default value, the directory is also included when no components are added
#set_and_check(__@__FINAL_NAME@_dir "@__FINAL_INSTALL_INCLUDE_DIR@")
if(EXISTS "@__FINAL_INSTALL_INCLUDE_DIR@")
  list(APPEND @__FINAL_NAME@_INCLUDE_DIRS "@__FINAL_INSTALL_INCLUDE_DIR@")
  list(REMOVE_DUPLICATES @__FINAL_NAME@_INCLUDE_DIRS)
endif()

# Define @PROJECT NAME@_LIBRARY_DIRS variable
#set_and_check(__@__FINAL_NAME@_dir "@__FINAL_INSTALL_LIB_DIR@")
if(EXISTS "@__FINAL_INSTALL_LIB_DIR@")
  list(APPEND @__FINAL_NAME@_LIB_DIRS "@__FINAL_INSTALL_LIB_DIR@")
  list(REMOVE_DUPLICATES @__FINAL_NAME@_LIB_DIRS)
endif()

# Restore the original CMAKE_PREFIX_PATH value
set(CMAKE_PREFIX_PATH "${__@__FINAL_NAME@_CMAKE_PREFIX_PATH_old_@__RAND@}")

if (DEFINED __@__FINAL_NAME@_notfound_message_@__RAND@ AND NOT "${__@__FINAL_NAME@_notfound_message_@__RAND@}" STREQUAL "")
  message(${__@__FINAL_NAME@_notfound_message_@__RAND@})
  set(@__FINAL_NAME@_FOUND FALSE)
endif ()

set_and_check(@__FINAL_NAME@_INSTALL_PREFIX "${__@__FINAL_NAME@_install_prefix_@__RAND@}")

check_required_components("")

# Show success message
if (NOT __@__FINAL_NAME@_notfound_message_@__RAND@ OR "${__@__FINAL_NAME@_notfound_message_@__RAND@}" STREQUAL "")
  message(STATUS "Found @__FINAL_NAME@: ${CMAKE_CURRENT_LIST_FILE} (found version \"${@__FINAL_NAME@_VERSION}\")")
endif ()

# Clear all temporary variables
unset(__@__FINAL_NAME@_find_parts_required_@__RAND@)
unset(__@__FINAL_NAME@_find_parts_quiet_@__RAND@)
unset(__@__FINAL_NAME@_install_prefix_@__RAND@)
unset(__@__FINAL_NAME@_CMAKE_PREFIX_PATH_old_@__RAND@)
unset(__@__FINAL_NAME@_notfound_message_@__RAND@)

if (NOT @__FINAL_NAME@_FOUND)
  unset(@__FINAL_NAME@_INSTALL_PREFIX)
  unset(@__FINAL_NAME@_VERSION)
  unset(@__FINAL_NAME@_ENTIRE_LIBS)
  unset(@__FINAL_NAME@_LIBS)
  unset(@__FINAL_NAME@_INCLUDE_DIRS)
  unset(@__FINAL_NAME@_LIB_DIRS)
  unset(@__FINAL_NAME@_BIN_DIRS)
  unset(@__FINAL_NAME@_SHARED)
endif ()
]===========================])
    string(REGEX REPLACE "^[\t\n\r ]+" "" __content "${__content}")
    set(${content} "${__content}" PARENT_SCOPE)
    PKG_unset(__content)
endfunction()


# "PKG_normal-config.cmake.in" files content
function(PKG_content_cmake_normal_config_cmake_in content dependencies)
    # Store strings generated by dependencies
    set(__find_dependency_str)
    # Break down dependencies
    foreach (__item IN LISTS dependencies)
        # Badly formatted strings are not allowed
        if (NOT "${__item}" MATCHES "^[^@:]+@[^@:]+:[^@:]+$" AND
            #NOT "${__item}" MATCHES "^@[^@:]+:[^@:]+$" AND
            NOT "${__item}" MATCHES "^[^@:]+:[^@:]+$" AND
            NOT "${__item}" MATCHES "^:[^@:]+$" AND
            NOT "${__item}" MATCHES "^[^@:]+$" AND
            NOT "${__item}" MATCHES "^[^@:]+@[^@:]+$")
            message(FATAL_ERROR "PKG: \"${__item}\" wrong format")
        endif ()

        string(REGEX MATCHALL "[@:]" __list_sign "${__item}")
        string(REGEX MATCHALL "[^@:]+" __list_data "${__item}")
        list(LENGTH __list_sign __count_sign)
        list(LENGTH __list_data __count_data)

        # Get the values of the following three variables
        set(__project_str "")
        set(__version_str "")
        set(__components_str "")
        list(FIND __list_sign "@" __index)
        if (NOT ${__index} EQUAL -1)
            if (${__count_sign} EQUAL 1 AND ${__count_data} EQUAL 2)    # project@version
                list(GET __list_data 0 __project_str)
                list(GET __list_data 1 __version_str)
            elseif (${__count_sign} EQUAL 2 AND ${__count_data} EQUAL 3)    # project@version:components
                list(GET __list_data 0 __project_str)
                list(GET __list_data 1 __version_str)
                list(GET __list_data 2 __components_str)
                #elseif (${__count_sign} EQUAL 2 AND ${__count_data} EQUAL 2)    # @version:components
                #    # Only components support this notation
                #    if (NOT __cf__IS_COMPONENT)
                #        message(FATAL_ERROR "PKG: The target is not a component，wrong expression of \"${__item}\"")
                #    endif ()
                #    set(__project_str "${__cf__PROJECT}")
                #    list(GET __list_data 0 __version_str)
                #    list(GET __list_data 1 __components_str)
            endif ()
        else ()
            PKG_unset(__index)
            list(FIND __list_sign ":" __index)
            if (NOT ${__index} EQUAL -1)
                if (${__count_data} EQUAL 2)        # project:components
                    list(GET __list_data 0 __project_str)
                    list(GET __list_data 1 __components_str)
                elseif (${__count_data} EQUAL 1)    # :components
                    # Only components support this notation
                    if (NOT __cf__IS_COMPONENT)
                        message(FATAL_ERROR "PKG: The target is not a component，wrong expression of \"${__item}\"")
                    endif ()

                    list(GET __list_data 0 __components_str_tmp)
                    set(__project_str "${__cf__PROJECT}-${__components_str_tmp}")
                    PKG_unset(__components_str_tmp)
                endif ()
            else ()     # project
                list(GET __list_data 0 __project_str)
            endif ()
        endif ()
        PKG_unset(__index)

        # Splicing `find_dependency()` function
        string(APPEND __find_dependency_str "find_dependency(${__project_str}")
        if (DEFINED __version_str AND NOT "${__version_str}" STREQUAL "")
            string(APPEND __find_dependency_str " ${__version_str}")
        endif ()
        if (DEFINED __components_str AND NOT "${__components_str}" STREQUAL "")
            string(REPLACE "," " " __components_str "${__components_str}")
            string(APPEND __find_dependency_str " COMPONENTS ${__components_str}")
        endif ()
        string(APPEND __find_dependency_str ")\n")

        PKG_unset(__project_str __version_str __components_str)
    endforeach ()
    PKG_unset(__item)

    # If not a component, add the version number
    if (NOT __cf__IS_COMPONENT)
        string(APPEND __content [===========================[
# Set the version number
set(@__FINAL_NAME@_VERSION "@__FINAL_VERSION@")
]===========================])
    endif ()

    string(APPEND __content "\@PACKAGE_INIT\@\n\n")

    # If there are dependencies, add dependencies
    if (DEFINED __find_dependency_str AND NOT "${__find_dependency_str}" STREQUAL "")
        string(APPEND __content "# add dependencies\ninclude(CMakeFindDependencyMacro)\n${__find_dependency_str}\n")
    endif ()
    PKG_unset(__find_dependency_str)

    string(APPEND __content [===========================[
include("${CMAKE_CURRENT_LIST_DIR}/@__FINAL_NAME@-targets.cmake")
]===========================])
    string(REGEX REPLACE "^[\t\n\r ]+" "" __content "${__content}")
    set(${content} "${__content}" PARENT_SCOPE)
    PKG_unset(__content)
endfunction()
