cmake_minimum_required(VERSION 3.28)

project(SDL3_Plus
    VERSION 1.0
    DESCRIPTION "Base for game dev with SDL3 + useful extras built in"
    LANGUAGES C CXX
)


# >> Options!

option(SDL3PLUS_ENABLE_GRAPHICS     "Enable image and ttf dependencies" ON)
option(SDL3PLUS_ENABLE_AUDIO        "Enable audio dependencies" ON)
option(SDL3PLUS_ENABLE_SOCKETS      "Enable net dependencies" ON)
option(SDL3PLUS_ENABLE_HTTP         "Enable http dependencies" ON)
option(SDL3PLUS_ENABLE_JSON         "Enable JSON dependencies" ON)
option(SDL3PLUS_ENABLE_ANDROID      "Enable Android stuff" ON)

option(SDL3PLUS_BUILD_EXAMPLE "Build SDL3_Plus example application" ${PROJECT_IS_TOP_LEVEL})


# >> Dependencies!

include(FetchContent)
include(cmake/projectFlags.cmake)
include(cmake/installBatteryEmbed.cmake)
include(cmake/installSDL3.cmake)
include(cmake/installJson.cmake)
include(cmake/installCppHttpLib.cmake)
include(cmake/tools.cmake)


# >> Library setup!

file(GLOB_RECURSE CORE_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
)

add_library(SDL3Plus STATIC ${CORE_SOURCES})
add_library(SDL3Plus::SDL3Plus ALIAS SDL3Plus)

target_include_directories(SDL3Plus
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>"
        "$<INSTALL_INTERFACE:include>"
)


# >> Dependency linking!

set(SDL3PLUS_LIBRARIES)

if(SDL3PLUS_ENABLE_GRAPHICS OR SDL3PLUS_ENABLE_AUDIO OR SDL3PLUS_ENABLE_SOCKETS)
    list(APPEND SDL3PLUS_LIBRARIES SDL3::SDL3)
    if(MSVC)
        set(_sdl3_no_opt_flag "/Od")
    else()
        set(_sdl3_no_opt_flag "-O0")
    endif()

    target_compile_options(SDL3-static PRIVATE
        $<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:C,CXX>>:${_sdl3_no_opt_flag}>
    )
endif()

if(SDL3PLUS_ENABLE_GRAPHICS)
    list(APPEND SDL3PLUS_LIBRARIES SDL3_image::SDL3_image SDL3_ttf::SDL3_ttf)
endif()

if(SDL3PLUS_ENABLE_AUDIO)
    list(APPEND SDL3PLUS_LIBRARIES SDL3_mixer::SDL3_mixer)
endif()

if(SDL3PLUS_ENABLE_SOCKETS)
    list(APPEND SDL3PLUS_LIBRARIES SDL3_net::SDL3_net)
endif()

if(SDL3PLUS_ENABLE_HTTP)
    list(APPEND SDL3PLUS_LIBRARIES httplib::httplib)

    file(RELATIVE_PATH SDL3PLUS_CERTIFICATE_RELATIVE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CERTIFICATE_FILE}"
    )

    b_embed(SDL3Plus "${SDL3PLUS_CERTIFICATE_RELATIVE}")
    message(STATUS "Integrated certificate: ${SDL3PLUS_CERTIFICATE_RELATIVE}")

    target_compile_definitions(SDL3Plus PRIVATE
        SDL3PLUS_CERTIFICATE_KEY="${SDL3PLUS_CERTIFICATE_RELATIVE}"
    )
endif()

if(SDL3PLUS_ENABLE_JSON)
    list(APPEND SDL3PLUS_LIBRARIES nlohmann_json::nlohmann_json)
endif()

target_link_libraries(SDL3Plus PUBLIC ${SDL3PLUS_LIBRARIES})


# >> Certificates, flags, and automation!

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/include/SDL3_plus/flags/flags.hpp.in"
    "${CMAKE_CURRENT_BINARY_DIR}/include/SDL3_plus/flags/flags.hpp"
)


# >> Testing example build!

if(SDL3PLUS_BUILD_EXAMPLE)
    add_subdirectory(main)
endif()