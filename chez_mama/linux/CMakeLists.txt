# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "food")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.example.food")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# --- Local libmpv (media_kit / video_player_media_kit) without system apt ---
# Workspace extract lives at FOOD/.local-libs (see chez_mama/run_linux.sh).
# Makes plain `flutter run -d linux` work when libmpv-dev is not installed.
set(FOOD_LOCAL_LIBS "${CMAKE_CURRENT_SOURCE_DIR}/../../.local-libs/usr")
set(FOOD_LOCAL_LIBDIR "${FOOD_LOCAL_LIBS}/lib/x86_64-linux-gnu")
set(FOOD_LOCAL_PCDIR "${FOOD_LOCAL_LIBDIR}/pkgconfig")
if(EXISTS "${FOOD_LOCAL_PCDIR}/mpv.pc" AND EXISTS "${FOOD_LOCAL_LIBS}/include/mpv/client.h")
  file(WRITE "${FOOD_LOCAL_PCDIR}/mpv.pc"
"prefix=${FOOD_LOCAL_LIBS}
exec_prefix=\${prefix}
libdir=\${prefix}/lib/x86_64-linux-gnu
includedir=\${prefix}/include

Name: mpv
Description: mpv media player client library
Version: 2.5.0
Libs: -L\${libdir} -lmpv
Cflags: -I\${includedir}
")
  set(ENV{PKG_CONFIG_PATH} "${FOOD_LOCAL_PCDIR}:$ENV{PKG_CONFIG_PATH}")
  include_directories(BEFORE SYSTEM "${FOOD_LOCAL_LIBS}/include")
  link_directories(BEFORE "${FOOD_LOCAL_LIBDIR}")
  # Absolute rpath only for the configure/compile machine; runtime uses $ORIGIN/lib.
  list(PREPEND CMAKE_BUILD_RPATH "${FOOD_LOCAL_LIBDIR}")
  message(STATUS "Using local libmpv from ${FOOD_LOCAL_LIBS}")
endif()

# Use classic DT_RPATH (not DT_RUNPATH) so transitive deps of libmpv
# (libmujs, liblua, …) are also resolved via the executable rpath.
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--disable-new-dtags")

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")
set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  # Clang 18+ / 21: flutter_secure_storage_linux's vendored json.hpp uses
  # deprecated "operator "" _json" spacing; keep as warning, not -Werror.
  target_compile_options(${TARGET} PRIVATE -Wall -Werror -Wno-error=deprecated-literal-operator)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Bundle local libmpv + its non-system deps so runtime needs no LD_LIBRARY_PATH.
if(EXISTS "${FOOD_LOCAL_LIBDIR}/libmpv.so.2")
  file(GLOB FOOD_LOCAL_RUNTIME_LIBS
    "${FOOD_LOCAL_LIBDIR}/libmpv.so*"
    "${FOOD_LOCAL_LIBDIR}/libmujs.so*"
    "${FOOD_LOCAL_LIBDIR}/liblua5.2.so*"
    "${FOOD_LOCAL_LIBDIR}/libsixel.so*"
    "${FOOD_LOCAL_LIBDIR}/libXpresent.so*"
    "${FOOD_LOCAL_LIBDIR}/libva-wayland.so*"
  )
  install(FILES ${FOOD_LOCAL_RUNTIME_LIBS}
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  # Prefer workspace patchelf (no sudo); fall back to PATH.
  set(_FOOD_PATCHELF "${FOOD_LOCAL_LIBS}/../bin/patchelf")
  if(NOT EXISTS "${_FOOD_PATCHELF}")
    set(_FOOD_PATCHELF "${CMAKE_CURRENT_SOURCE_DIR}/../../.local-libs/usr/bin/patchelf")
  endif()
  if(NOT EXISTS "${_FOOD_PATCHELF}")
    find_program(_FOOD_PATCHELF patchelf)
  endif()
  if(_FOOD_PATCHELF)
    # libmpv must resolve mujs/lua/… next to itself ($ORIGIN), not only via
    # the executable RUNPATH (which does not apply to transitive NEEDED).
    install(CODE "
      set(_pe \"${_FOOD_PATCHELF}\")
      set(_libdir \"${INSTALL_BUNDLE_LIB_DIR}\")
      set(_bin \"${CMAKE_INSTALL_PREFIX}/${BINARY_NAME}\")
      if(EXISTS \"\${_pe}\" AND EXISTS \"\${_libdir}/libmpv.so.2\")
        execute_process(COMMAND \"\${_pe}\" --force-rpath --set-rpath \"\$ORIGIN\"
          \"\${_libdir}/libmpv.so.2\" ERROR_QUIET)
        if(EXISTS \"\${_libdir}/libmpv.so.2.5.0\")
          execute_process(COMMAND \"\${_pe}\" --force-rpath --set-rpath \"\$ORIGIN\"
            \"\${_libdir}/libmpv.so.2.5.0\" ERROR_QUIET)
        endif()
        if(EXISTS \"\${_bin}\")
          execute_process(COMMAND \"\${_pe}\" --force-rpath --set-rpath \"\$ORIGIN/lib\"
            \"\${_bin}\" ERROR_QUIET)
        endif()
      endif()
    " COMPONENT Runtime)
  endif()
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
