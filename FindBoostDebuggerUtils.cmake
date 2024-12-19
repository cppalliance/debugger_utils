#
# Copyright (c) 2024 Dmitry Arkhipov (grisumbras@yandex.ru)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Official repository: https://github.com/cppalliance/debugger_utils
#

if(BoostDebuggerUtils_FIND_QUIETLY)
    set(quiet QUIET)
endif()
find_package(Python3 ${quiet} COMPONENTS Interpreter)

find_program(
    BoostDebuggerUtils_GDB_EXECUTABLE gdb DOC "GDB executable to use")
if(BoostDebuggerUtils_GDB_EXECUTABLE)
    set(BoostDebuggerUtils_GDB_FOUND TRUE)
else()
    set(BoostDebuggerUtils_GDB_FOUND ${BoostDebuggerUtils_GDB_EXECUTABLE})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(BoostDebuggerUtils
    REQUIRED_VARS Python3_Interpreter_FOUND
    HANDLE_COMPONENTS)

if(BoostDebuggerUtils_GDB_FOUND)
    add_executable(BoostDebuggerUtils::GDB IMPORTED)
    set_target_properties(BoostDebuggerUtils::GDB
        PROPERTIES IMPORTED_LOCATION "${BoostDebuggerUtils_GDB_EXECUTABLE}")
endif()

set(BoostDebuggerUtils_GDB_EMBED_SCRIPT
    "${CMAKE_CURRENT_LIST_DIR}/embed-gdb-extension.py")
set(BoostDebuggerUtils_GDB_TEST_SCRIPT
    "${CMAKE_CURRENT_LIST_DIR}/generate-gdb-test-runner.py")

function(boost_debugger_utils_embed_gdb_extension)
    set(options EXCLUDE_FROM_ALL)
    set(oneValueArgs TARGET INPUT OUTPUT)
    set(multiValueArgs FLAGS)
    cmake_parse_arguments(BOOST_DBG_UTILS_GDB_GEN
        "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    foreach(kw TARGET INPUT OUTPUT)
        if(NOT DEFINED "BOOST_DBG_UTILS_GDB_GEN_${kw}")
            message(FATAL_ERROR "Argument ${kw} is required for function \
                boost_debugger_utils_embed_gdb_extension.")
        endif()
    endforeach()

    add_custom_command(
        OUTPUT "${BOOST_DBG_UTILS_GDB_GEN_OUTPUT}"
        MAIN_DEPENDENCY "${BOOST_DBG_UTILS_GDB_GEN_INPUT}"
        DEPENDS "${BoostDebuggerUtils_GDB_EMBED_SCRIPT}"
        COMMAND
            "${Python3_EXECUTABLE}"
            "${BoostDebuggerUtils_GDB_EMBED_SCRIPT}"
            "${CMAKE_CURRENT_SOURCE_DIR}/${BOOST_DBG_UTILS_GDB_GEN_INPUT}"
            "${CMAKE_CURRENT_SOURCE_DIR}/${BOOST_DBG_UTILS_GDB_GEN_OUTPUT}"
            ${BOOST_DBG_UTILS_GDB_GEN_FLAGS}
        COMMENT "Generating ${BOOST_DBG_UTILS_GDB_GEN_OUTPUT}")

    if(NOT BOOST_DBG_UTILS_GDB_GEN_EXCLUDE_FROM_ALL)
        set(isInAll ALL)
    endif()
    add_custom_target(${BOOST_DBG_UTILS_GDB_GEN_TARGET}
        ${isInAll}
        DEPENDS "${BOOST_DBG_UTILS_GDB_GEN_OUTPUT}")
endfunction()


function(boost_debugger_utils_test_gdb_printers)
    set(options EXCLUDE_FROM_ALL)
    set(oneValueArgs TEST PROGRAM)
    set(multiValueArgs SOURCES)
    cmake_parse_arguments(BOOST_DBG_UTILS_TEST_GDB
        "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    foreach(kw TEST SOURCES)
        if(NOT DEFINED "BOOST_DBG_UTILS_TEST_GDB_${kw}")
            message(FATAL_ERROR "Argument ${kw} is required for function \
                boost_debugger_utils_test_gdb_printers.")
        endif()
    endforeach()

    if(NOT DEFINED BOOST_DBG_UTILS_TEST_GDB_PROGRAM)
        set(BOOST_DBG_UTILS_TEST_GDB_PROGRAM ${BOOST_DBG_UTILS_TEST_GDB_TEST})
    endif()
    if(BOOST_DBG_UTILS_TEST_GDB_EXCLUDE_FROM_ALL)
        set(excludeFromAll EXCLUDE_FROM_ALL)
    else()
        set(includeInAll ALL)
    endif()


    set(sources)
    foreach(src ${BOOST_DBG_UTILS_TEST_GDB_SOURCES})
        get_filename_component(
            real_src "${src}" ABSOLUTE ${CMAKE_CURRENT_SOURCE_DIR})
        LIST(APPEND sources "${real_src}")
    endforeach()

    add_custom_command(
        OUTPUT "${BOOST_DBG_UTILS_TEST_GDB_TEST}.py"
        DEPENDS ${sources}
        COMMAND
            "${Python3_EXECUTABLE}"
            "${BoostDebuggerUtils_GDB_TEST_SCRIPT}"
            ${sources}
            -o "${BOOST_DBG_UTILS_TEST_GDB_TEST}.py"
        COMMENT "Generating ${BOOST_DBG_UTILS_TEST_GDB_TEST}.py")

    add_custom_target(${BOOST_DBG_UTILS_TEST_GDB_TEST}_runner
        ${includeInAll}
        DEPENDS "${BOOST_DBG_UTILS_TEST_GDB_TEST}.py")

    add_executable(${BOOST_DBG_UTILS_TEST_GDB_PROGRAM}
        ${excludeFromAll}
        ${BOOST_DBG_UTILS_TEST_GDB_SOURCES})
    add_dependencies(
        ${BOOST_DBG_UTILS_TEST_GDB_PROGRAM}
        ${BOOST_DBG_UTILS_TEST_GDB_TEST}_runner)

    add_test(
        NAME ${BOOST_DBG_UTILS_TEST_GDB_TEST}
        COMMAND BoostDebuggerUtils::GDB
            --batch-silent
            -iex "add-auto-load-safe-path ${CMAKE_CURRENT_BINARY_DIR}"
            -x "${BOOST_DBG_UTILS_TEST_GDB_TEST}.py"
            $<TARGET_FILE:${BOOST_DBG_UTILS_TEST_GDB_PROGRAM}>)
endfunction()
