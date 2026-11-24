[![Build](https://github.com/LohksStudiosWorks/SDL3_plus/actions/workflows/build.yaml/badge.svg)](https://github.com/LohksStudiosWorks/SDL3_plus/actions/workflows/build.yaml)

# SDL3_plus

A modular C++ base that simplifies the development of cross-platform games and applications by providing an integrated CMake build system and a rich collection of statically configured libraries.

## What the project is? / Why?

This is a library that wraps:

- [SDL3](https://github.com/libsdl-org/SDL) - main cross-platform library for multimedia software development.
- [SDL3 Image](https://github.com/libsdl-org/SDL_image) - library to enable loading many image formats to SDL3 surfaces.
- [SDL3 TTF](https://github.com/libsdl-org/SDL_ttf) - library that allows for TrueType fonts to be used with SDL3.
- [SDL3 Mixer](https://github.com/libsdl-org/SDL_mixer) - library to handle audio files and devices.
- [SDL3 Net](https://github.com/libsdl-org/SDL_net) - library that enables UDP/TCP socket communication with SDL3 easily.
- [Battery Embed](https://github.com/batterycenter/embed) - CMake tool to embed files with your applications.
- [Cpp-HttpLib](https://github.com/yhirose/cpp-httplib) - Modern C++ library that does the HTTP handling, with support for HTTPS/TLS and so on.
- [JSON](https://github.com/nlohmann/json) - Classic Nlohmann's JSON library for JSON parsing and building.
- [MbedTLS](https://github.com/Mbed-TLS/mbedtls) - Library to enable Cpp-HttpLib to have the security part (HTTPS/TLS) on all platforms.

The project combines these libraries into one called `SDL3_plus::SDL3_plus`, which is pre-configured to compile for `Windows`, `Linux`, `macOS`, and `Android`.

You can also find smaller combined ones like these:

- `SDL3Plus::Base`: The SDL3 itself, enabled by default with any of the options `SDL3PLUS_ENABLE_GRAPHICS`, `SDL3PLUS_ENABLE_AUDIO`, or `SDL3PLUS_ENABLE_SOCKETS`.
- `SDL3Plus::Graphics`: The SDL Image and SDL TTF, enabled by default with the option `SDL3PLUS_ENABLE_GRAPHICS`.
- `SDL3Plus::Audio`: The SDL3 Mixer, enabled by default with the option `SDL3PLUS_ENABLE_AUDIO`.
- `SDL3Plus::Sockets`: The SDL3 Net, enabled by default with the option `SDL3PLUS_ENABLE_SOCKETS`.
- `SDL3Plus::HTTP`: The CppHttpLib and MbedTLS integrated with it, enabled by default with the option `SDL3PLUS_ENABLE_HTTP`.
- `SDL3Plus::JSON`: The Nlohmann's JSON, enabled by default with the option `SDL3PLUS_ENABLE_JSON`.

This was created for that: make it way easier for anyone to build cross-platform C++ SDL3 rich applications with no hurdle. No more messing around CMake to make it compile on each platform to then later break something. This makes the process way easier! Try it!

Also, this is configured for `monolith`/`static` builds. What that means is that there will be no `dll` or `so` lying around! Just copy the executable and share with your friends!

## How to use it?

Easy. This is a CMake project in the end. You just have to fetch it in your project and use it.

```cmake
cmake_minimum_required(VERSION 3.28)

project(YourProject # Rename if needed
    VERSION 1.0.0
    LANGUAGES CXX
    # ...
)

include(FetchContent)
FetchContent_Declare(
    sdl3_plus
    GIT_REPOSITORY  https://github.com/LohksStudiosWorks/SDL3_plus
    GIT_TAG         master # adjust to a tag as needed
)
FetchContent_MakeAvailable(sdl3_plus)

# This automatically change the project to executable or lib depending if compiling to Android or Desktop.
# Also, it integrates itself in here, no need to link the library manually.
sdl3plus_add_game(${PROJECT_NAME}
    SOURCES
        src/main.cpp
        # ...
    ICON
        resources/icon.png # Icon used for Android build. Not required for desktop applications
)

# Used for signing APK
sdl3plus_add_android_key_file(${PROJECT_NAME} resources/release-key.jks)

# ... target include directories and other flags as usual if you need those.
```

The Android part requires you to have a JKS (Java KeyStore) file to sign the APK, so you can actually install it in the end. To make your own, use this command in your terminal:

```bash
keytool -genkey -v -keystore FILENAME.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ALIAS_NAME_HERE
```
> [!NOTE]
> `ALIAS_NAME_HERE`: This is used in the pipeline later, if you integrate this with that. Save it somewhere.

> [!NOTE]
>  Other password things you should save too to use with the pipeline later, like the `keystore password` and `key password`.

To generate the `base64` version of the file, you can use this command:

```bash
base64 -w 0 YOUR_FILE_PATH.jks
```

This will print the `base64` version of the jks file. You can use it in the pipeline as a secret later!

### How to build it?

You can take a look at the [`fullBuild action`](https://github.com/LohksStudiosWorks/SDL3_plus/tree/master/actions/fullBuild) to check the libraries and other steps. Maybe not all of them are needed for your specific case, but surely this action makes it way easier to compile your project just like that:

```yaml
name: Build everything that easy!

on:
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    name: ${{ matrix.name }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest # NOTE: The Ubuntu one that builds for Android, if you configure it to build it!
            artifact: linux-x86_64
            name: Ubuntu Latest x64
          - os: macos-latest
            artifact: macos-arm64
            name: macOS Latest ARM64
          - os: windows-latest
            artifact: windows-x86_64
            name: Windows Latest x64

    runs-on: ${{ matrix.os }}

    steps:
      - name: Check out source
        uses: actions/checkout@v7

      - name: Bundle things up!
        uses: LohksStudiosWorks/SDL3_plus/actions/fullBuild@master
        with:
          target_name: YourProject # Rename this to the target you've set in sdl3plus_add_game() earlier
          # EXTRA ONES if you are building to Android:
          # keystore_base64: ${{ secrets.RELEASE_KEYSTORE_BASE64 }} # This is used for Android. You need a keystore thing to sign the APK. Store it as base64 in a secret and map it here.
          # keystore_password: ${{ secrets.KEYSTORE_PASSWORD }} # When creating your jks file, this will be requested and used. Save as a secret as well.
          # key_alias: ${{ secrets.KEY_ALIAS }} # There is an ALIAS argument to the generator. Save as a secret and put it here.
          # key_password: ${{ secrets.KEY_PASSWORD }} # Sometimes this is the same as keystore password. Save as a secret and use it here.
          # release_keys_file_path: resources/release-key.jks # This is the path you are using in CMake's script (sdl3plus_add_android_key_file). Use the same here and you're good. It'll extract the base64 value in this path so you don't have to worry about security risk.
```

> [!NOTE]
> The pipeline automatically uploads the final binary as artifacts. The `ubuntu` one is the only one that may output two artifacts, one for Linux, one for Android (if you configured it to do so).

## Examples of project using this (so far):

- [**FlappyBlock**](https://github.com/LohksStudiosWorks/FlappyBlock)
    - Also available on [GameJolt](https://gamejolt.com/games/FlappyBlock/1118179)!
    - Uses all platforms (`Windows`, `Linux`, `macOS`, `Android`)

## How to contribute?

Please fork the project and experiment on something new you may think is useful to add to this project. Then, open a pull request!

You can also talk about it in [this Discord server](https://discord.gg/eQfnXdTH6f)! Many projects under LohksStudiosWorks are linked there.