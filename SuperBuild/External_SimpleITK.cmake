if( NOT EXTERNAL_SOURCE_DIRECTORY )
  set( EXTERNAL_SOURCE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/ExternalSources )
endif()
if( NOT EXTERNAL_BINARY_DIRECTORY )
  set( EXTERNAL_BINARY_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )
endif()

# Make sure this file is included only once by creating globally unique varibles
# based on the name of this included file.
get_filename_component(CMAKE_CURRENT_LIST_FILENAME ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
if(${CMAKE_CURRENT_LIST_FILENAME}_FILE_INCLUDED)
  return()
endif()
set(${CMAKE_CURRENT_LIST_FILENAME}_FILE_INCLUDED 1)

## External_${extProjName}.cmake files can be recurisvely included,
## and cmake variables are global, so when including sub projects it
## is important make the extProjName and proj variables
## appear to stay constant in one of these files.
## Store global variables before overwriting (then restore at end of this file.)
ProjectDependancyPush(CACHED_extProjName ${extProjName})
ProjectDependancyPush(CACHED_proj ${proj})

# Make sure that the ExtProjName/IntProjName variables are unique globally
# even if other External_${ExtProjName}.cmake files are sourced by
# SlicerMacroCheckExternalProjectDependency
set(extProjName SimpleITK) #The find_package known name
set(proj        SimpleITK) #This local name
set(${extProjName}_REQUIRED_VERSION "")  #If a required version is necessary, then set this, else leave blank

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_DIR CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_DIR AND NOT EXISTS ${${extProjName}_DIR})
  message(FATAL_ERROR "${extProjName}_DIR variable is defined but corresponds to non-existing directory (${${extProjName}_DIR})")
endif()

if(NOT ( DEFINED "USE_SYSTEM_${extProjName}" AND "${USE_SYSTEM_${extProjName}}") )
  #message(STATUS "${__indent}Adding project ${proj}")
  # Set dependency list
  set(${proj}_DEPENDENCIES ITKv4 PCRE Swig python)

  # Include dependent projects if any
  SlicerMacroCheckExternalProjectDependency(${proj})
  set( COMMON_EXTERNAL_PROJECT_ARGS_COPY ${COMMON_EXTERNAL_PROJECT_ARGS} )
  if( slicer_PYTHON_REAL_EXECUTABLE )
    list(REMOVE_ITEM COMMON_EXTERNAL_PROJECT_ARGS -DPYTHON_EXECUTABLE:FILEPATH=${PYTHON_EXECUTABLE})
    list(APPEND COMMON_EXTERNAL_PROJECT_ARGS -DPYTHON_EXECUTABLE:FILEPATH=${slicer_PYTHON_REAL_EXECUTABLE})
  endif()

  # Set CMake OSX variable to pass down the external project
  set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
  if(APPLE)
    list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET})
  endif()

  ### --- Project specific additions here

  find_package( PythonInterp REQUIRED )
  find_package ( PythonLibs REQUIRED )


#We cannot look for Python.h if we build python with Superbuild at the same time as we build SimpleITK
  #
  # On the Helium machine I ran into trouble with
  # SimpleITK not being able to find Python.h.
  # After sleuthing around I determined that
  # PYTHON_INCLUDE_DIR pointed to the parent of the
  # directory containing Python.h, So if that's
  # the case I search for it and amend the patch.
#  if(NOT EXISTS "${PYTHON_INCLUDE_DIR}/Python.h")
#    file(GLOB_RECURSE PYTHON_H "${PYTHON_INCLUDE_DIR}/Python.h")
#    get_filename_component(PYTHON_INCLUDE_DIR ${PYTHON_H} PATH )
#    set(PYTHON_INCLUDE_PATH ${PYTHON_INCLUDE_DIR})
  #  message("PYTHON_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}")
#  endif()
  configure_file(SuperBuild/External_SimpleITK_install_step.cmake.in
    ${EXTERNAL_BINARY_DIRECTORY}/External_SimpleITK_install_step.cmake
    @ONLY)

  set(SimpleITK_INSTALL_COMMAND ${CMAKE_COMMAND} -P ${EXTERNAL_BINARY_DIRECTORY}/External_SimpleITK_install_step.cmake)

  set(${proj}_CMAKE_OPTIONS
    -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
    -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
    -DCMAKE_CXX_FLAGS:STRING=${CMAKE_CXX_FLAGS}
    -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
    -DCMAKE_C_FLAGS:STRING=${CMAKE_C_FLAGS}
    # SimpleITK does not work with shared libs turned on
    -DBUILD_SHARED_LIBS:BOOL=OFF
    -DCMAKE_INSTALL_PREFIX:PATH=${EXTERNAL_BINARY_DIRECTORY}
    -DBUILD_TESTING:BOOL=OFF
    -DBUILD_DOXYGEN:BOOL=OFF
    -DSITK_INT64_PIXELIDS:BOOL=OFF
    -DWRAP_PYTHON:BOOL=ON
    -DWRAP_TCL:BOOL=OFF
    -DWRAP_JAVA:BOOL=OFF
    -DWRAP_RUBY:BOOL=OFF
    -DWRAP_LUA:BOOL=OFF
    -DWRAP_CSHARP:BOOL=OFF
    -DWRAP_R:BOOL=OFF
  )

  ### --- End Project specific additions
  set(${proj}_REPOSITORY https://github.com/SimpleITK/SimpleITK.git)
  set(${proj}_GIT_TAG eb16d9834f21c85530e2f38b8fa07962d91d5b93)
  ExternalProject_Add(${proj}
    GIT_REPOSITORY ${${proj}_REPOSITORY}
    GIT_TAG ${${proj}_GIT_TAG}
    SOURCE_DIR ${EXTERNAL_SOURCE_DIRECTORY}/${proj}
    BINARY_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build
    LOG_CONFIGURE 0  # Wrap configure in script to ignore log output from dashboards
    LOG_BUILD     0  # Wrap build in script to to ignore log output from dashboards
    LOG_TEST      0  # Wrap test in script to to ignore log output from dashboards
    LOG_INSTALL   0  # Wrap install in script to to ignore log output from dashboards
    ${cmakeversion_external_update} "${cmakeversion_external_update_value}"
    CMAKE_GENERATOR ${gen}
    CMAKE_ARGS
      ${CMAKE_OSX_EXTERNAL_PROJECT_ARGS}
      ${COMMON_EXTERNAL_PROJECT_ARGS}
      ${${proj}_CMAKE_OPTIONS}
    INSTALL_COMMAND ${SimpleITK_INSTALL_COMMAND}
    DEPENDS
      ${${proj}_DEPENDENCIES}
  )
  set(${extProjName}_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build)
  set( COMMON_EXTERNAL_PROJECT_ARGS ${COMMON_EXTERNAL_PROJECT_ARGS_COPY} )
else()
  if(${USE_SYSTEM_${extProjName}})
    find_package(${extProjName} ${${extProjName}_REQUIRED_VERSION} REQUIRED)
    message("USING the system ${extProjName}, set ${extProjName}_DIR=${${extProjName}_DIR}")
  endif()
  # The project is provided using ${extProjName}_DIR, nevertheless since other
  # project may depend on ${extProjName}, let's add an 'empty' one
  SlicerMacroEmptyExternalProject(${proj} "${${proj}_DEPENDENCIES}")
endif()

list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS ${extProjName}_DIR:PATH)

ProjectDependancyPop(CACHED_extProjName extProjName)
ProjectDependancyPop(CACHED_proj proj)
