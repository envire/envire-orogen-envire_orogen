PROJECT(envire_orogen)
cmake_minimum_required(VERSION 2.6)

install(FILES ${PROJECT_SOURCE_DIR}/rock/orogen_plugin.rb
        DESTINATION ${CMAKE_INSTALL_PREFIX}/share/orogen/plugins
        RENAME opaque_generation_plugin.rb)

file(GLOB TYPEKIT_TEMPLATES
    ${PROJECT_SOURCE_DIR}/rock/typekit/templates/*.hpp
    ${PROJECT_SOURCE_DIR}/rock/typekit/templates/*.cpp)
install(FILES ${TYPEKIT_TEMPLATES}
        DESTINATION ${CMAKE_INSTALL_PREFIX}/share/orogen/templates/)