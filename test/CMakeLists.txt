if(NOT BUILD_TESTING)
    return()
endif()

add_custom_target(tests)

add_test(
    NAME test-embed-gdb-extension.py
    COMMAND "${Python3_EXECUTABLE}"
    ${CMAKE_CURRENT_SOURCE_DIR}/test-embed-gdb-extension.py
    ${CMAKE_CURRENT_SOURCE_DIR}/../embed-gdb-extension.py
    ${CMAKE_CURRENT_SOURCE_DIR}/gdb.py)


boost_debugger_utils_embed_gdb_extension(
    TARGET generate-gdb-hpp
    INPUT gdb.py
    OUTPUT include/testlib/gdb.hpp
    EXCLUDE_FROM_ALL)

add_library(testlib lib/testlib.cpp)
target_include_directories(testlib PUBLIC include)
add_dependencies(testlib generate-gdb-hpp)

if(BoostDebuggerUtils_GDB_FOUND)
    FILE(GLOB gdb_test_srcs CONFIGURE_DEPENDS *.cpp)
    boost_debugger_utils_test_gdb_printers(
        TEST test_gdb
        SOURCES ${gdb_test_srcs})
    target_link_libraries(test_gdb PRIVATE testlib)
    add_dependencies(tests test_gdb)
endif()
