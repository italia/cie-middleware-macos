# Install script for directory: /Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Library/Developer/CommandLineTools/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign/libcie_sign_sdk.a")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign" TYPE STATIC_LIBRARY FILES "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/libcie_sign_sdk.a")
  if(EXISTS "$ENV{DESTDIR}/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign/libcie_sign_sdk.a" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign/libcie_sign_sdk.a")
    execute_process(COMMAND "/Library/Developer/CommandLineTools/usr/bin/ranlib" "$ENV{DESTDIR}/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign/libcie_sign_sdk.a")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/CMakeFiles/cie_sign_sdk.dir/install-cxx-module-bmi-noconfig.cmake" OPTIONAL)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign/disigonsdk.h;/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign/CIEEngine.h")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/../cie-pkcs11/Sign" TYPE FILE FILES
    "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/include/disigonsdk.h"
    "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/include/CIEEngine.h"
    )
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "/Users/reikashi/Desktop/cie-middleware-macos_dev_recent/cie_sign_sdk/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
