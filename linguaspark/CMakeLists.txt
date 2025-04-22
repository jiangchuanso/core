cmake_minimum_required(VERSION 3.15...4.0)

project(linguaspark CXX C)

option(USE_MKL "Compile with MKL support" ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Newer versions of Cmake require this to compile
set(CMAKE_POLICY_VERSION_MINIMUM
    "3.5"
    CACHE STRING "Minimum CMake policy version" FORCE)

find_package(Threads REQUIRED)
if(NOT USE_MKL)
  message(STATUS "MKL support is disabled")
endif()

set(BERGAMOT_SUBMODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/3rd_party/bergamot-translator")

if(EXISTS "${BERGAMOT_SUBMODULE_PATH}/CMakeLists.txt")
  message(STATUS "Bergamot translator submodule found")
  add_subdirectory(${BERGAMOT_SUBMODULE_PATH} bergamot-translator)
else()
  message(STATUS "Bergamot translator submodule not found, using FetchContent")
  include(FetchContent)
  FetchContent_Declare(
    bergamot-translator
    GIT_REPOSITORY https://github.com/browsermt/bergamot-translator.git
    GIT_TAG main)
  FetchContent_MakeAvailable(bergamot-translator)
endif()

add_library(linguaspark SHARED linguaspark.cpp)
target_include_directories(
  linguaspark
  PUBLIC $<TARGET_PROPERTY:bergamot-translator,INTERFACE_INCLUDE_DIRECTORIES>)
target_link_libraries(linguaspark bergamot-translator Threads::Threads)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
  # Some versions of GCC will cause uninitialized errors during optimization
  if(CMAKE_COMPILER_IS_GNUCXX)
    add_compile_options(-Wno-error=maybe-uninitialized)
    add_compile_options(-Wno-error=uninitialized)
    add_compile_options(-Wno-maybe-uninitialized)
  endif()

  set(VERSION_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/export.map")
  if(EXISTS "${VERSION_SCRIPT}")
    target_link_options(linguaspark PRIVATE -Wl,--version-script=${VERSION_SCRIPT})
  endif()

  include(CheckIPOSupported)
  check_ipo_supported()
  set_property(TARGET linguaspark PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)

  target_link_options(linguaspark PRIVATE -Wl,--strip-all)
endif()
