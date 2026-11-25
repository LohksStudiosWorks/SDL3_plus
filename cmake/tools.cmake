function(sdl3plus_generate_android_icons ICON_PATH RESOURCE_DIR)
    find_program(SDL3PLUS_MAGICK magick)

    if(NOT SDL3PLUS_MAGICK)
        message(FATAL_ERROR
            "ImageMagick is required to generate Android icons. "
            "Install ImageMagick and make sure 'magick' is available in PATH."
        )
    endif()

    # Android launcher icon sizes.
    set(ICON_DENSITIES
        mdpi:48
        hdpi:72
        xhdpi:96
        xxhdpi:144
        xxxhdpi:192
    )

    foreach(DENSITY_SIZE IN LISTS ICON_DENSITIES)
        string(REPLACE ":" ";" DENSITY_SIZE "${DENSITY_SIZE}")

        list(GET DENSITY_SIZE 0 DENSITY)
        list(GET DENSITY_SIZE 1 SIZE)

        set(OUTPUT_DIR
            "${RESOURCE_DIR}/mipmap-${DENSITY}"
        )

        file(MAKE_DIRECTORY "${OUTPUT_DIR}")

        execute_process(
            COMMAND "${SDL3PLUS_MAGICK}"
                "${ICON_PATH}"
                -alpha on
                -background none
                -resize "${SIZE}x${SIZE}^"
                -gravity center
                -extent "${SIZE}x${SIZE}"
                "PNG32:${OUTPUT_DIR}/ic_launcher.png"
            RESULT_VARIABLE RESULT
            ERROR_VARIABLE ERROR
        )

        if(NOT RESULT EQUAL 0)
            message(FATAL_ERROR
                "Failed to generate Android icon for ${DENSITY}: ${ERROR}"
            )
        endif()

        message(STATUS "Generated Android icon: ${DENSITY} (${SIZE}px)")
    endforeach()
endfunction()


function(sdl3plus_setup_android TARGET_NAME)
    if(ANDROID)
        return()
    endif()

    cmake_parse_arguments(
        ANDROID
        ""
        "ICON;STUDIO"
        ""
        ${ARGN}
    )

    message(STATUS "Configuring SDL3plus Android project...")
     
    if(NOT ANDROID_STUDIO)
        set(ANDROID_STUDIO "template")
    endif()

    set(SDL3PLUS_ANDROID_DIR
        "${CMAKE_BINARY_DIR}/_sdl3plus/android/${TARGET_NAME}"
    )

    set(SDL3PLUS_ANDROID_TEMPLATE_DIR
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../android-project"
    )

    file(COPY
        "${SDL3PLUS_ANDROID_TEMPLATE_DIR}/"
        DESTINATION "${SDL3PLUS_ANDROID_DIR}"
    )

    set(SDL3PLUS_ANDROID_TARGET "${TARGET_NAME}")
    set(GAME_CMAKE_PROJECT "${CMAKE_SOURCE_DIR}/CMakeLists.txt")

    configure_file(
        "${SDL3PLUS_ANDROID_TEMPLATE_DIR}/app/build.gradle.in"
        "${SDL3PLUS_ANDROID_DIR}/app/build.gradle"
        @ONLY
    )

    if(ANDROID_ICON)
        sdl3plus_generate_android_icons(
            "${ANDROID_ICON}"
            "${SDL3PLUS_ANDROID_DIR}/app/src/main/res"
        )
    endif()

    if(WIN32)
        set(SDL3PLUS_GRADLE
            "${SDL3PLUS_ANDROID_DIR}/gradlew.bat"
        )
    else()
        set(SDL3PLUS_GRADLE
            "${SDL3PLUS_ANDROID_DIR}/gradlew"
        )

        file(CHMOD
            "${SDL3PLUS_GRADLE}"
            PERMISSIONS
                OWNER_READ OWNER_WRITE OWNER_EXECUTE
                GROUP_READ GROUP_EXECUTE
                WORLD_READ WORLD_EXECUTE
        )
    endif()

    set(_ver_major 1)
    set(_ver_minor 0)
    set(_ver_patch 0)

    if(CMAKE_PROJECT_VERSION MATCHES "^([0-9]+)(\\.([0-9]+))?(\\.([0-9]+))?")
        set(_ver_major "${CMAKE_MATCH_1}")
        if(CMAKE_MATCH_3)
            set(_ver_minor "${CMAKE_MATCH_3}")
        endif()
        if(CMAKE_MATCH_5)
            set(_ver_patch "${CMAKE_MATCH_5}")
        endif()
    endif()

    math(EXPR VERSION_CODE "${_ver_major} * 1000000 + ${_ver_minor} * 1000 + ${_ver_patch}")
    set(VERSION_NAME "${_ver_major}.${_ver_minor}.${_ver_patch}")

    message(STATUS "Configured SDL3plus Android project:")
    message(STATUS "- Game Name: ${TARGET_NAME}")
    message(STATUS "- Studio Name: ${ANDROID_STUDIO}")
    message(STATUS "- Output Dir: ${CMAKE_BINARY_DIR}/bin")
    message(STATUS "- Version code: ${VERSION_CODE}")
    message(STATUS "- Version name: ${VERSION_NAME}")

    add_custom_target(${TARGET_NAME}_android_release
        COMMAND "${SDL3PLUS_GRADLE}" 
            assembleRelease
            copyRelease
            "-PgameName=${TARGET_NAME}"
            "-PstudioName=${ANDROID_STUDIO}"
            "-PoutputDir=${CMAKE_BINARY_DIR}/bin"
            "-PversionCode=${VERSION_CODE}"
            "-PversionName=${VERSION_NAME}"
        WORKING_DIRECTORY "${SDL3PLUS_ANDROID_DIR}"
        USES_TERMINAL
        COMMENT "Building Android release APK..."
        VERBATIM
    )

    message(STATUS "Android project configured.")
endfunction()


function(sdl3plus_add_game TARGET_NAME)
    cmake_parse_arguments(
        GAME
        ""
        "ICON;STUDIO"
        "SOURCES"
        ${ARGN}
    )

    if(NOT GAME_SOURCES)
        message(FATAL_ERROR
            "sdl3plus_add_game(${TARGET_NAME}): SOURCES is required."
        )
    endif()

    if(GAME_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "sdl3plus_add_game(${TARGET_NAME}): Unknown arguments: "
            "${GAME_UNPARSED_ARGUMENTS}"
        )
    endif()

    message(STATUS "Adding game ${TARGET_NAME}...")

    if(GAME_ICON)
        get_filename_component(
            GAME_ICON
            "${GAME_ICON}"
            ABSOLUTE
            BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
        )

        if(NOT EXISTS "${GAME_ICON}")
            message(FATAL_ERROR
                "Game icon does not exist: ${GAME_ICON}"
            )
        endif()
    endif()

    if(ANDROID)
        add_library(${TARGET_NAME} SHARED ${GAME_SOURCES})

        set_target_properties(${TARGET_NAME} PROPERTIES
            OUTPUT_NAME main
        )
    else()
        add_executable(${TARGET_NAME} WIN32 ${GAME_SOURCES})

        set_target_properties(${TARGET_NAME} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
        )
    endif()

    target_link_libraries(${TARGET_NAME} PRIVATE
        SDL3Plus::SDL3Plus
    )

    target_compile_definitions(${TARGET_NAME} PRIVATE
        IS_ANDROID=$<BOOL:${ANDROID}>
    )

    if(SDL3PLUS_ENABLE_ANDROID AND NOT ANDROID)
        message(STATUS "Preparing Android version for ${TARGET_NAME}...")

        sdl3plus_setup_android(
            ${TARGET_NAME}
            ICON "${GAME_ICON}"
            STUDIO "${GAME_STUDIO}"
        )
    endif()
endfunction()

function(sdl3plus_add_android_key_file TARGET_NAME KEY_FILE)
    if(NOT SDL3PLUS_ENABLE_ANDROID)
        return()
    endif()

    get_filename_component(KEY_FILE
        "${KEY_FILE}"
        ABSOLUTE
        BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
    )

    if(NOT EXISTS "${KEY_FILE}")
        message(FATAL_ERROR "Release key not found: ${KEY_FILE}")
    endif()

    set(ANDROID_PROJECT_DIR
        "${CMAKE_BINARY_DIR}/_sdl3plus/android/${TARGET_NAME}"
    )

    file(MAKE_DIRECTORY "${ANDROID_PROJECT_DIR}")

    configure_file(
        "${KEY_FILE}"
        "${ANDROID_PROJECT_DIR}/release-key.jks"
        COPYONLY
    )

    message(STATUS
        "Android release key copied to ${ANDROID_PROJECT_DIR}/release-key.jks"
    )
endfunction()