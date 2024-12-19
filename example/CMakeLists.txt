#
# Copyright (c) 2024 Dmitry Arkhipov (grisumbras@yandex.ru)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Official repository: https://github.com/boostorg/json
#

cmake_minimum_required(VERSION 3.8...3.16)

project(example_project VERSION 1.0 LANGUAGES CXX)


# the packacge is optional, because we check in the generated header, so that
# consumers aren't required to have Python 3 installed
find_package(BoostDebuggerUtils COMPONENTS GDB)

add_library(example src/example.cpp)
add_library(Example::example ALIAS example)
target_include_directories(example PUBLIC include)

# we avoid making the ability to regenerate GDB pretty printers a hard
# requirement of building the project
if(BoostDebuggerUtils_FOUND)
    boost_debugger_utils_embed_gdb_extension(
        TARGET regenerate_printers
        INPUT include/example/gdb_printers.py
        OUTPUT include/example/gdb_printers.hpp
        FLAGS
            # we set the header guard macro to something more project-specific
            --header-guard=EXAMPLE_GDB_PRINTERS_HPP
            # we don't put a disable macro into the generated header, instead
            # we wrap inclusions of that header with a disable macro (also
            # see include/example/all.hpp)
            --disable-macro=
        # we avoid making the ability to regenerate pretty printers a hard
        # requirement of building the project
        EXCLUDE_FROM_ALL)
    # if possible we make the library dependent on the embedded printers,
    # so that any change to the printers is reflected in the binary
    target_sources(example PUBLIC include/example/gdb_printers.hpp)
endif()

include(GNUInstallDirs)
install(TARGETS example DESTINATION "${CMAKE_INSTALL_LIBDIR}")
# install GDB pretty printers together with headers,
# so that users could load them manually
install(DIRECTORY include DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

include(CTest)
add_subdirectory(test)
