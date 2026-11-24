cmake_minimum_required(VERSION 3.28)

set(MAIN_PROJECT "MyGame")

file(GLOB_RECURSE MAIN_SOURCES CONFIGURE_DEPENDS
    "src/*.cpp"
)

sdl3plus_add_game(${MAIN_PROJECT}
    SOURCES
        ${MAIN_SOURCES}
    
    ICON
        resources/example.png
    STUDIO
        lohksstudiosworks
)

sdl3plus_add_android_key_file(${MAIN_PROJECT} resources/release-key.jks)

target_include_directories(${MAIN_PROJECT} PUBLIC "include")
