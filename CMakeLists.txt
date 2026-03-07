cmake_minimum_required(VERSION 3.21)

project(vSMR LANGUAGES CXX RC)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

enable_testing()

find_package(asio REQUIRED)
find_package(CURL REQUIRED)
find_package(RapidJSON REQUIRED)

set(VSMR_SOURCES
  vSMR/AircraftTypeLookup.cpp
  vSMR/CallsignLookup.cpp
  vSMR/Config.cpp
  vSMR/CPDLCSettingsDialog.cpp
  vSMR/DataLinkDialog.cpp
  vSMR/HttpHelper.cpp
  vSMR/InsetWindow.cpp
  vSMR/Rimcas.cpp
  vSMR/SMRPlugin.cpp
  vSMR/SMRRadar.cpp
  vSMR/stdafx.cpp
  vSMR/vSMR.cpp
  vSMR/vSMR.rc
)

add_library(vSMR SHARED ${VSMR_SOURCES})

target_include_directories(vSMR PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/lib/include
  ${CMAKE_CURRENT_SOURCE_DIR}/vSMR
)

target_compile_definitions(vSMR PRIVATE
  WIN32
  _WINDOWS
  _USRDLL
  _MBCS
  CURL_STATICLIB
  CURL_STATIC
  ASIO_STANDALONE
  $<$<CONFIG:Debug>:_DEBUG>
  $<$<CONFIG:Release>:NDEBUG>
)

if(MSVC)
  target_compile_options(vSMR PRIVATE
    /W3
    /sdl
    /EHsc
    /Zc:wchar_t-
  )

  target_link_options(vSMR PRIVATE
    /DEF:${CMAKE_CURRENT_SOURCE_DIR}/vSMR/vSMR.def
    /IGNORE:4099
    $<$<CONFIG:Release>:/NODEFAULTLIB:LIBCMTD>
  )
endif()

target_link_libraries(vSMR PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/lib/EuroScopePlugInDll.lib
  winmm
  asio::asio
  CURL::libcurl
  rapidjson
)

set_target_properties(vSMR PROPERTIES
  OUTPUT_NAME vSMR
  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Release
  RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_CURRENT_SOURCE_DIR}/Release
  RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_CURRENT_SOURCE_DIR}/Debug
  ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Release
  ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${CMAKE_CURRENT_SOURCE_DIR}/Release
  ARCHIVE_OUTPUT_DIRECTORY_DEBUG ${CMAKE_CURRENT_SOURCE_DIR}/Debug
)

find_program(POWERSHELL_EXE NAMES pwsh powershell REQUIRED)
add_test(
  NAME smoke_checks
  COMMAND ${POWERSHELL_EXE} -ExecutionPolicy Bypass -File ${CMAKE_SOURCE_DIR}/scripts/ci-smoke.ps1
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)
