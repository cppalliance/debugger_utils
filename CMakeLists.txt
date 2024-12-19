#
# Copyright (c) 2024 Dmitry Arkhipov (grisumbras@yandex.ru)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#

cmake_minimum_required(VERSION 3.8...3.16)

project(BoostDebuggerUtils VERSION 1.0 LANGUAGES CXX)

find_package(BoostDebuggerUtils REQUIRED OPTIONAL_COMPONENTS GDB)

include(CTest)
add_subdirectory(test)
