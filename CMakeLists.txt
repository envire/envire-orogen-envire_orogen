PROJECT(envire_orogen)
cmake_minimum_required(VERSION 2.6)

install(
    DIRECTORY
        ${PROJECT_SOURCE_DIR}/orogen
    DESTINATION
        ${CMAKE_INSTALL_PREFIX}/share
)

