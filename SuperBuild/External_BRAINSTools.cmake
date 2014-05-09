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
set(extProjName BRAINSTools) #The find_package known name
set(proj        BRAINSTools) #This local name
set(${extProjName}_REQUIRED_VERSION "")  #If a required version is necessary, then set this, else leave blank

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_DIR CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_DIR AND NOT EXISTS ${${extProjName}_DIR})
  message(FATAL_ERROR "${extProjName}_DIR variable is defined but corresponds to non-existing directory (${${extProjName}_DIR})")
endif()

if(NOT ( DEFINED "${extProjName}_SOURCE_DIR" OR ( DEFINED "USE_SYSTEM_${extProjName}" AND "${USE_SYSTEM_${extProjName}}" ) ) )
# Set dependency list
  set(${extProjName}_DEPENDENCIES ITKv4 SlicerExecutionModel VTK DCMTK teem OpenCV zlib )

  #message(STATUS "${__indent}Adding project ${proj}")
  if(USE_ANTs)
    list(APPEND ${extProjName}_DEPENDENCIES ANTs Boost)
  endif()

  if( ${PRIMARY_PROJECT_NAME}_BUILD_TIFF_SUPPORT )
    list(APPEND ${proj}_DEPENDENCIES TIFF)
  endif()
  if( ${PRIMARY_PROJECT_NAME}_BUILD_JPEG_SUPPORT )
    list(APPEND ${proj}_DEPENDENCIES JPEG)
  endif()
  # Include dependent projects if any
  SlicerMacroCheckExternalProjectDependency(${proj})

  # Set CMake OSX variable to pass down the external project
  set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
  if(APPLE)
    list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET})
  endif()

  set(BRAINS_ANTS_PARAMS
    -DUSE_ANTS:BOOL=${USE_ANTs}
    )
  if(USE_ANTs)
    list(APPEND BRAINS_ANTS_PARAMS
      -DUSE_SYSTEM_ANTS:BOOL=ON
      -DANTs_SOURCE_DIR:PATH=${ANTs_SOURCE_DIR}
      -DANTs_LIBRARY_DIR:PATH=${ANTs_LIBRARY_DIR}
      -DUSE_SYSTEM_Boost:BOOL=ON
      -DBoost_NO_BOOST_CMAKE:BOOL=ON #Set Boost_NO_BOOST_CMAKE to ON to disable the search for boost-cmake
      -DBoost_DIR:PATH=${BOOST_ROOT}
      -DBOOST_DIR:PATH=${BOOST_ROOT}
      -DBOOST_ROOT:PATH=${BOOST_ROOT}
      -DBOOST_INCLUDE_DIR:PATH=${BOOST_INCLUDE_DIR}
      )
  endif()
  ### --- Project specific additions here
  # message("VTK_DIR: ${VTK_DIR}")
  # message("ITK_DIR: ${ITK_DIR}")
  # message("SlicerExecutionModel_DIR: ${SlicerExecutionModel_DIR}")
  # message("BOOST_INCLUDE_DIR:PATH=${BOOST_INCLUDE_DIR}")

  if( ${PRIMARY_PROJECT_NAME}_BUILD_TIFF_SUPPORT )
    set(${proj}_TIFF_ARGS
      -DUSE_SYSTEM_TIFF:BOOL=ON
       )
  endif()
  if( ${PRIMARY_PROJECT_NAME}_BUILD_JPEG_SUPPORT )
    set(${proj}_JPEG_ARGS
      -DUSE_SYSTEM_JPEG:BOOL=ON
      )
  endif()

  set(${proj}_CMAKE_OPTIONS
      -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/${proj}-install
      -DBUILD_EXAMPLES:BOOL=OFF
      -DBUILD_TESTING:BOOL=OFF
      -DUSE_SYSTEM_ITK:BOOL=ON
      -DUSE_SYSTEM_VTK:BOOL=ON
      -DUSE_SYSTEM_DCMTK:BOOL=ON
      -DUSE_SYSTEM_Teem:BOOL=ON
      -DUSE_SYSTEM_OpenCV:BOOL=ON
      -DUSE_SYSTEM_ReferenceAtlas:BOOL=ON
      -DPYTHON_LIBRARY:FILEPATH=${PYTHON_LIBRARY}
      -DPYTHON_INCLUDE_DIR:PATH=${PYTHON_INCLUDE_DIR}
      -DUSE_SYSTEM_SlicerExecutionModel:BOOL=ON
      -DDCMTK_config_INCLUDE_DIR:PATH=${DCMTK_DIR}/include
      -DSlicerExecutionModel_DIR:PATH=${SlicerExecutionModel_DIR}
      -DSuperBuild_BRAINSTools_USE_GIT_PROTOCOL=${${CMAKE_PROJECT_NAME}_USE_GIT_PROTOCOL}
      -DBRAINSTools_SUPERBUILD:BOOL=OFF
      -D${proj}_USE_QT:BOOL=${LOCAL_PROJECT_NAME}_USE_QT
      -DUSE_SYSTEM_ZLIB:BOOL=ON
      -DZLIB_ROOT:PATH=${zlib_DIR}
      -DZLIB_INCLUDE_DIR:PATH=${zlib}_DIR}/include
      -DZLIB_LIBRARY:FILEPATH=${ZLIB_LIBRARY}
      -DUSE_BRAINSABC:BOOL=OFF
      -DUSE_BRAINSConstellationDetector:BOOL=OFF
      -DUSE_BRAINSContinuousClass:BOOL=OFF
      -DUSE_BRAINSCut:BOOL=OFF
      -DUSE_BRAINSDemonWarp:BOOL=OFF
      -DUSE_BRAINSFit:BOOL=OFF
      -DUSE_BRAINSFitEZ:BOOL=OFF
      -DUSE_BRAINSTalairach:BOOL=OFF
      -DUSE_BRAINSImageConvert:BOOL=OFF
      -DUSE_BRAINSInitializedControlPoints:BOOL=OFF
      -DUSE_BRAINSLandmarkInitializer:BOOL=OFF
      -DUSE_BRAINSMultiModeSegment:BOOL=OFF
      -DUSE_BRAINSMush:BOOL=OFF
      -DUSE_BRAINSImageConvert:BOOL=OFF
      -DUSE_BRAINSInitializedControlPoints:BOOL=OFF
      -DUSE_BRAINSLandmarkInitializer:BOOL=OFF
      -DUSE_BRAINSMultiModeSegment:BOOL=OFF
      -DUSE_BRAINSMush:BOOL=OFF
      -DUSE_BRAINSROIAuto:BOOL=OFF
      -DUSE_BRAINSResample:BOOL=OFF
      -DUSE_BRAINSSnapShotWriter:BOOL=OFF
      -DUSE_BRAINSSurfaceTools:BOOL=OFF
      -DUSE_BRAINSTransformConvert:BOOL=OFF
      -DUSE_BRAINSPosteriorToContinuousClass:BOOL=OFF
      -DUSE_BRAINSCreateLabelMapFromProbabilityMaps:BOOL=OFF
      -DUSE_DebugImageViewer:BOOL=OFF
      -DUSE_GTRACT:BOOL=OFF
      -DUSE_ICCDEF:BOOL=OFF
      -DUSE_ConvertBetweenFileFormats:BOOL=OFF
      -DUSE_ImageCalculator:BOOL=OFF
      -DUSE_AutoWorkup:BOOL=OFF
      ${BRAINS_ANTS_PARAMS}
    )

  ### --- End Project specific additions
  set(${proj}_REPOSITORY "${git_protocol}://github.com/BRAINSia/BRAINSTools.git")
  set(${proj}_GIT_TAG "33b739e7e6a414be41d44aca028b1304a2c0a440")
  ExternalProject_Add(${proj}
    GIT_REPOSITORY ${${proj}_REPOSITORY}
    GIT_TAG ${${proj}_GIT_TAG}
    SOURCE_DIR ${EXTERNAL_SOURCE_DIRECTORY}/${proj}
    BINARY_DIR ${proj}-build
    LOG_CONFIGURE 0  # Wrap configure in script to ignore log output from dashboards
    LOG_BUILD     0  # Wrap build in script to to ignore log output from dashboards
    LOG_TEST      0  # Wrap test in script to to ignore log output from dashboards
    LOG_INSTALL   0  # Wrap install in script to to ignore log output from dashboards
    ${cmakeversion_external_update} "${cmakeversion_external_update_value}"
    CMAKE_GENERATOR ${gen}
    CMAKE_ARGS
      -Wno-dev
      --no-warn-unused-cli
      ${CMAKE_OSX_EXTERNAL_PROJECT_ARGS}
      ${COMMON_EXTERNAL_PROJECT_ARGS}
      ${${proj}_CMAKE_OPTIONS}
    INSTALL_COMMAND ""
    DEPENDS
      ${${extProjName}_DEPENDENCIES}
    )
  set(${extProjName}_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build)
  set(${extProjName}_SOURCE_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj})
  set(BRAINSCommonLib_DIR    ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build/BRAINSCommonLib)
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
_expand_external_project_vars()
set(COMMON_EXTERNAL_PROJECT_ARGS ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS})

ProjectDependancyPop(CACHED_extProjName extProjName)
ProjectDependancyPop(CACHED_proj proj)
