set(VSMR_SOURCES
    AircraftTypeLookup.cpp
    CallsignLookup.cpp
    Config.cpp
    CPDLCSettingsDialog.cpp
    DataLinkDialog.cpp
    HttpHelper.cpp
    InsetWindow.cpp
    Rimcas.cpp
    SMRPlugin.cpp
    SMRRadar.cpp
    stdafx.cpp
    vSMR.cpp
)

set(VSMR_HEADERS
    AircraftTypeLookup.hpp
    CallsignLookup.hpp
    ColorManager.h
    Config.hpp
    Constant.hpp
    CPDLCSettingsDialog.hpp
    DataLinkDialog.hpp
    HttpHelper.hpp
    InsetWindow.h
    Logger.h
    resource.h
    Rimcas.hpp
    SMRPlugin.hpp
    SMRRadar.hpp
    stdafx.h
    targetver.h
    vSMR.hpp
)

add_library(vSMR SHARED
    ${VSMR_SOURCES}
    ${VSMR_HEADERS}
)

if(WIN32)
    target_sources(vSMR PRIVATE vSMR.rc)
endif()

target_compile_features(vSMR PRIVATE cxx_std_17)

target_compile_definitions(vSMR PRIVATE
    WIN32
    _WINDOWS
    _USRDLL
    CURL_STATICLIB
    CURL_STATIC
    ASIO_STANDALONE
    $<$<CONFIG:Debug>:_DEBUG>
    $<$<CONFIG:Release>:NDEBUG>
)

target_include_directories(vSMR PRIVATE
    ${CMAKE_SOURCE_DIR}/lib/include
)

target_precompile_headers(vSMR PRIVATE stdafx.h)

set_target_properties(vSMR PROPERTIES
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

if(WIN32)
    target_link_options(vSMR PRIVATE
        "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/vSMR.def"
        "/IGNORE:4099"
    )
endif()

target_link_libraries(vSMR PRIVATE
    ${CMAKE_SOURCE_DIR}/lib/EuroScopePlugInDll.lib
)

if(WIN32)
    target_link_libraries(vSMR PRIVATE winmm)
endif()

if(MSVC)
    target_compile_options(vSMR PRIVATE /W3 /utf-8 /Zc:wchar_t-)
    target_link_options(vSMR PRIVATE $<$<CONFIG:Release>:/NODEFAULTLIB:LIBCMTD>)
endif()
