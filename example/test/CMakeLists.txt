#
# Copyright (c) 2024 Dmitry Arkhipov (grisumbras@yandex.ru)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Official repository: https://github.com/boostorg/json
#

if(NOT BUILD_TESTING)
    return()
endif()

# we avoid making presence of GDB a hard requirement for testing the project
if(BoostDebuggerUtils_GDB_FOUND)
    boost_debugger_utils_test_gdb_printers(
        TEST test_gdb_printers
        SOURCES printers.cpp)
    target_link_libraries(test_gdb_printers PRIVATE Example::example)
endif()
