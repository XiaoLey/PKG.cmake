#===============================================================================
#
# @brief Quickly package projects or multi-component projects
function(PKG)
    include(CMakeParseArguments)
    set(
      __options
      _IS_COMPONENT _IS_COMPONENTS _ADD_LIB_SUFFIX _DISABLE_INTERFACE _INSTALL_PDB
      _ADD_UNINSTALL _SHARED_LIBS _DISABLE_CONFIG _DISABLE_VERSION
    )
    set(
      __oneValueArgs
      _NAME _PROJECT _VERSION _COMPATIBILITY _DEBUG_POSTFIX _BINARY_DIR _BINARY_BIN_DIR
      _BINARY_LIB_DIR _NAMESPACE _EXPORT_HEADER _EXPORT_MACRO _CONFIG_TEMPLATE
      _INCLUDE_EXCLUDE_REG _MODE _INCLUDE_DESTINATION
      _INSTALL_DIR _INSTALL_INCLUDE_DIR _INSTALL_BIN_DIR _INSTALL_LIB_DIR
      _UNINSTALL_TEMPLATE
    )
    set(
      __multiValueArgs
      _INCLUDE_FILES _INCLUDE_DIRS _UNINSTALL_ADDITIONAL
    )
    cmake_parse_arguments(__cf "${__options}" "${__oneValueArgs}" "${__multiValueArgs}" "${ARGN}")
    PKG_unset(__options __oneValueArgs __multiValueArgs)


    # If _NAME is not specified, jump out of the function directly
    if (NOT __cf__NAME OR "${__cf__NAME}" STREQUAL "")
        return()
    endif ()

    if (__cf__IS_COMPONENT AND __cf__IS_COMPONENTS)
        message(FATAL_ERROR "PKG: `_IS COMPONENT` and `_IS COMPONENTS` cannot be enabled at the same time")
    endif ()


    # Initialize all parameter values
    if (__cf__IS_COMPONENT)
        if (NOT __cf__PROJECT OR "${__cf__PROJECT}" STREQUAL "")
            set(__cf__PROJECT "${PROJECT_NAME}")
        endif ()
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

    if (NOT __cf__COMPATIBILITY OR "${__cf__COMPATIBILITY}" STREQUAL "")
        set(__cf__COMPATIBILITY "AnyNewerVersion")
    endif ()

    set(BUILD_SHARED_LIBS "${__cf__SHARED_LIBS}")

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

    if (NOT __cf__BINARY_BIN_DIR OR "${__cf__BINARY_BIN_DIR}" STREQUAL "")
        set(__cf__BINARY_BIN_DIR "${__cf__BINARY_DIR}/bin")
    else ()
        if (NOT "${__cf__BINARY_BIN_DIR}" MATCHES "^[a-zA-Z]:|^/")
            set(__cf__BINARY_BIN_DIR "${__cf__BINARY_DIR}/${__cf__BINARY_BIN_DIR}")
        endif ()
    endif ()

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
        if (NOT "${__cf__BINARY_LIB_DIR}" MATCHES "^[a-zA-Z]:|^/")
            set(__cf__BINARY_LIB_DIR "${__cf__BINARY_DIR}/${__cf__BINARY_LIB_DIR}")
        endif ()

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
    set(CMAKE_INSTALL_PREFIX "${__cf__INSTALL_DIR}")    # change only the current scope

    if (NOT __cf__INSTALL_INCLUDE_DIR OR "${__cf__INSTALL_INCLUDE_DIR}" STREQUAL "")
        set(__cf__INSTALL_INCLUDE_DIR "${__cf__INSTALL_DIR}/include")
    else ()
        if (NOT "${__cf__INSTALL_INCLUDE_DIR}" MATCHES "^[a-zA-Z]:|^/")
            set(__cf__INSTALL_INCLUDE_DIR "${__cf__INSTALL_DIR}/${__cf__INSTALL_INCLUDE_DIR}")
        endif ()
    endif ()

    if (NOT __cf__INSTALL_BIN_DIR OR "${__cf__INSTALL_BIN_DIR}" STREQUAL "")
        set(__cf__INSTALL_BIN_DIR "${__cf__INSTALL_DIR}/bin")
    else ()
        if (NOT "${__cf__INSTALL_BIN_DIR}" MATCHES "^[a-zA-Z]:|^/")
            set(__cf__INSTALL_BIN_DIR "${__cf__INSTALL_DIR}/${__cf__INSTALL_BIN_DIR}")
        endif ()
    endif ()

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
        if (NOT "${__cf__INSTALL_LIB_DIR}" MATCHES "^[a-zA-Z]:|^/")
            set(__cf__INSTALL_LIB_DIR "${__cf__INSTALL_DIR}/${__cf__INSTALL_LIB_DIR}")
        endif ()

        if (__cf__ADD_LIB_SUFFIX)
            PKG_get_COMPILER_BITS()
            PKG_set_LIB_SUFFIX()
            set(__cf__INSTALL_LIB_DIR "${__cf__INSTALL_LIB_DIR}${LIB_SUFFIX}")
            PKG_unset(COMPILER_BITS LIB_SUFFIX)
        endif ()
    endif ()

    if (NOT __cf__INCLUDE_DESTINATION OR "${__cf__INCLUDE_DESTINATION}" STREQUAL "")
        set(__cf__INCLUDE_DESTINATION "${__cf__INSTALL_INCLUDE_DIR}")
    endif ()

    if (NOT __cf__MODE OR "${__cf__MODE}" STREQUAL "")
        set(__cf__MODE "Development")
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

    if (NOT __cf__CONFIG_TEMPLATE OR "${__cf__CONFIG_TEMPLATE}" STREQUAL "")
        if (__cf__IS_COMPONENTS)
            set(__cf__CONFIG_TEMPLATE "${CMAKE_SOURCE_DIR}/cmake/PKG_components-config.cmake.in")
        else ()
            set(__cf__CONFIG_TEMPLATE "${CMAKE_SOURCE_DIR}/cmake/PKG_normal-config.cmake.in")
        endif ()
        if (NOT EXISTS "${__cf__CONFIG_TEMPLATE}")
            message(FATAL_ERROR "PKG: \"${__cf__CONFIG_TEMPLATE}\" file does not exist")
        endif ()
    endif ()

    if (__cf__IS_COMPONENT)
        set(__cf__ADD_UNINSTALL FALSE)
    endif ()

    if (__cf__ADD_UNINSTALL)
        if (NOT __cf__UNINSTALL_TEMPLATE OR "${__cf__UNINSTALL_TEMPLATE}" STREQUAL "")
            set(__cf__UNINSTALL_TEMPLATE "${CMAKE_SOURCE_DIR}/cmake/PKG_cmake_uninstall.cmake.in")
            if (NOT EXISTS "${__cf__UNINSTALL_TEMPLATE}")
                message(FATAL_ERROR "PKG: \"${__cf__UNINSTALL_TEMPLATE}\" file does not exist")
            endif ()
        endif ()
    else ()
        set(__cf__UNINSTALL_TEMPLATE "")
    endif ()


    if (NOT __cf__IS_COMPONENTS)
        # Use the GenerateExportHeader module to create export headers
        if (DEFINED __cf__EXPORT_HEADER AND NOT "${__cf__EXPORT_HEADER}" STREQUAL "")
            # If no absolute path is specified, the relative path is relative to the
            # CMAKE_CURRENT_BINARY_DIR to synthesize the absolute path
            if (NOT "${__cf__EXPORT_HEADER}" MATCHES "^[a-zA-Z]:|^/")
                set(__cf__EXPORT_HEADER "${CMAKE_CURRENT_BINARY_DIR}/${__cf__EXPORT_HEADER}")
            endif ()

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
            message("PKG: Parameter \"_EXPORT_HEADER\" for \"${__cf__NAME}\" target will be ignored")
        endif ()
        if (DEFINED __cf__DEBUG_POSTFIX AND NOT "${__cf__DEBUG_POSTFIX}" STREQUAL "")
            message("PKG: Parameter \"_DEBUG_POSTFIX\" for \"${__cf__NAME}\" target will be ignored")
        endif ()
        if (DEFINED __cf__NAMESPACE AND NOT "${__cf__NAMESPACE}" STREQUAL "")
            message("PKG: Parameter \"_NAMESPACE\" for \"${__cf__NAME}\" target will be ignored")
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
        if (__cf__IS_COMPONENT)
            PKG_generate_target_config(TARGET_NAME "${__cf__NAME}")
        else ()
            PKG_generate_target_config(TARGET_NAME "${__cf__NAME}" MAIN)
        endif ()
    endif ()


    # Add uninstall command
    if (NOT __cf__UNINSTALL_ADDITIONAL OR "${__cf__UNINSTALL_ADDITIONAL}" STREQUAL "")
        add_uninstall_command()
    else ()
        add_uninstall_command("${__cf__UNINSTALL_ADDITIONAL}")
    endif ()
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
                install(
                  DIRECTORY ${__cf__INCLUDE_DIRS}
                  DESTINATION "${__cf__INSTALL_INCLUDE_DIR}"
                  COMPONENT Development
                  FILE_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
                  DIRECTORY_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ
                  REGEX "${__cf__INCLUDE_EXCLUDE_REG}" EXCLUDE
                  PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
                )
            else ()
                install(
                  DIRECTORY ${__cf__INCLUDE_DIRS}
                  DESTINATION "${__cf__INSTALL_INCLUDE_DIR}"
                  COMPONENT Development
                  FILE_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
                  DIRECTORY_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ
                )
            endif ()
        endif ()

        if (DEFINED __cf__INCLUDE_FILES AND NOT "${__cf__INCLUDE_FILES}" STREQUAL "")
            install(
              FILES ${__cf__INCLUDE_FILES}
              DESTINATION "${__cf__INSTALL_INCLUDE_DIR}"
              COMPONENT Development
              PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
            )
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
# MAIN                  - opt, Marked as main, means the CMakeLists.txt calling the function is the root CMakeLists.txt
function(PKG_generate_target_config)
    include(CMakeParseArguments)
    set(__options
        MAIN)
    set(__oneValueArgs
        TARGET_NAME)
    set(__multiValueArgs
        PATH_VARS)
    cmake_parse_arguments(__config "${__options}" "${__oneValueArgs}" "${__multiValueArgs}" "${ARGN}")
    PKG_unset(__options __oneValueArgs __multiValueArgs)

    if (NOT __config_TARGET_NAME OR "${__config_TARGET_NAME}" STREQUAL "")
        set(__config_TARGET_NAME "${__cf__NAME}")
    endif ()

    # If a namespace is declared, the namespace is used
    if (NOT __cf__PROJECT OR "${__cf__PROJECT}" STREQUAL "")
        set(__final_name "${__config_TARGET_NAME}")
    else ()
        set(__final_name "${__cf__PROJECT}-${__config_TARGET_NAME}")
    endif ()

    # The complete list of libraries in the project (used by the config template)
    set(__ENTIRE_LIBRARIES)

    # The main config file, which will get a complete list of components
    # (please make sure that all components have generated targets configuration files before this)
    if (__config_MAIN)
        file(GLOB_RECURSE __targets_files FOLLOW_SYMLINKS
             RELATIVE "${__cf__BINARY_DIR}/cmake"
             LIST_DIRECTORIES false
             "*-targets.cmake")

        # Remove the path that returns to the previous level
        set(__pre_remove)
        foreach (__item ${__targets_files})
            if ("${__item}" MATCHES "^\\.\\./")
                list(APPEND __pre_remove "${__item}")
            endif ()
            PKG_unset(__item)
        endforeach ()
        PKG_unset(__item)

        list(REMOVE_ITEM __targets_files ${__pre_remove})

        set(__targets_file_paths)       # Absolute path to the "*-targets.cmake" file
        foreach (__file ${__targets_files})
            list(APPEND __targets_file_paths "${__cf__BINARY_DIR}/cmake/${__file}")
        endforeach ()
        PKG_unset(__file __targets_files __pre_remove)

        foreach (__file ${__targets_file_paths})
            file(READ "${__file}" __content)
            string(REGEX MATCHALL [[add_library\((.*) (STATIC|SHARED|MODULE|UNKNOWN|OBJECT|INTERFACE) IMPORTED\)]]
                   __content "${__content}")
            string(REGEX REPLACE "^[ \t\r\n]+|[ \t\r\n]+$" "" __content "${CMAKE_MATCH_1}")

            # After processing, add to the __ENTIRE_LIBRARIES variable
            list(APPEND __ENTIRE_LIBRARIES "${__content}")

            PKG_unset(__content)
        endforeach ()
        PKG_unset(__file __targets_file_paths)

        # Remove duplicates after the end
        list(REMOVE_DUPLICATES __ENTIRE_LIBRARIES)
    endif ()

    include(CMakePackageConfigHelpers)
    set(__FINAL_NAME "${__final_name}") # Used for variables in configuration files
    configure_package_config_file(
      "${__cf__CONFIG_TEMPLATE}"
      "${__cf__BINARY_DIR}/cmake/${__final_name}-config.cmake"
      INSTALL_DESTINATION "${__cf__INSTALL_LIB_DIR}/cmake/${__final_name}"
      PATH_VARS ${__config_PATH_VARS}
    )
    PKG_unset(__FINAL_NAME __ENTIRE_LIBRARIES)

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
          DESTINATION "${__cf__INSTALL_INCLUDE_DIR}"
          COMPONENT Development
          PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
        )
    endif ()
endfunction()


# Add uninstall command
# INPUT:
#   ARGV     Other directories or files that need to be uninstalled together
# Example: add_uninstall_command(${CMAKE_INSTALL_PREFIX})
function(add_uninstall_command)
    if (NOT __cf__ADD_UNINSTALL)
        return()
    endif ()

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