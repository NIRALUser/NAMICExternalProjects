####################################   USAGE   ##################################
# By default, all CLI modules listed in SlicerCLIModules are built
# If you do not want to compile all modules, define a variable BUILD_Module and set it to OFF
# before the resolution of external dependencies in your CMakeLists.txt
# eg: set(BUILD_CLI_MedianImageFilter OFF )
#     SlicerMacroCheckExternalProjectDependency(${proj})
##############################################################################
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
set(extProjName SlicerCLI) #The find_package known name
set(proj        SlicerCLI) #This local name
set(${extProjName}_REQUIRED_VERSION "")  #If a required version is necessary, then set this, else leave blank

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_DIR CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_DIR AND NOT EXISTS ${${extProjName}_DIR})
  message(FATAL_ERROR "${extProjName}_DIR variable is defined but corresponds to non-existing directory (${${extProjName}_DIR})")
endif()

# Set dependency list
set(${proj}_DEPENDENCIES ITKv4 VTK SlicerExecutionModel )
#if(${PROJECT_NAME}_BUILD_DICOM_SUPPORT)
#  list(APPEND ${proj}_DEPENDENCIES DCMTK)
#endif()

# Include dependent projects if any
SlicerMacroCheckExternalProjectDependency(${proj})

set( SlicerCLIModules
     MedianImageFilter
     N4ITKBiasFieldCorrection
     ResampleDTIVolume
     ResampleScalarVectorDWIVolume 
     AffineRegistration
     RigidRegistration
     ThresholdScalarVolume
     AddScalarVolumes
     BSplineDeformableRegistration
     BSplineToDeformationField
     CastScalarVolume
     CheckerBoardFilter
     ConnectedComponent
     DWIJointRicianLMMSEFilter
     DWIRicianLMMSEFilter
     #DWIToDTIEstimation->vtkITK+MRML
     #DWIUnbiasedNonLocalMeansFilter->vtkITK+MRML
     #DiffusionTensorScalarMeasurements->vtkITK+MRML
     #DiffusionWeightedVolumeMasking->vtkITK+MRML
     GaussianBlurImageFilter
     GradientAnisotropicDiffusion
     GrayscaleFillHoleImageFilter
     HistogramMatching
     ImageLabelCombine
     LabelMapSmoothing
     LinearRegistration
     MaskScalarVolume
     #MultiplyScalarVolumes->vtkITK
     OrientScalarVolume
     OtsuThresholdImageFilter
     OtsuThresholdSegmentation
     RobustStatisticsSegmenter
     SimpleRegionGrowingSegmentation
     SubtractScalarVolumes
     ThresholdScalarVolume
     VotingBinaryHoleFillingImageFilter
   )
unset( SLICER_CLI_TO_BUILD )
foreach( var ${SlicerCLIModules})
  if( DEFINED BUILD_CLI_${var} ) 
    list(APPEND SLICER_CLI_TO_BUILD -DBUILD_CLI_${var}:BOOL=${BUILD_CLI_${var}} )
  else()
    list(APPEND SLICER_CLI_TO_BUILD -DBUILD_CLI_${var}:BOOL=ON )
  endif()
  if( DEFINED StringModules )#Even if we don't want to build on module, we still download it's code, because another module might depend on it
    set(StringModules "${StringModules} ${var}" )
  else()
    set(StringModules "${var}")
  endif()
endforeach()

if(NOT ( DEFINED "USE_SYSTEM_${extProjName}" AND "${USE_SYSTEM_${extProjName}}" ) )
  #message(STATUS "${__indent}Adding project ${proj}")

  # Set CMake OSX variable to pass down the external project
  set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
  if(APPLE)
    list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET})
  endif()
  ### --- Project specific additions here
  set(${proj}_CMAKE_OPTIONS
    -DUSE_SYSTEM_ITK:BOOL=ON
    -DUSE_SYSTEM_VTK:BOOL=ON
    -DUSE_SYSTEM_SlicerExecutionModel:BOOL=ON
    -DITK_DIR:PATH=${ITK_DIR}
    -DDCMTK_DIR:PATH=${DCMTK_DIR}
    -DVTK_DIR:PATH=${VTK_DIR}
    -DSlicerExecutionModel_DIR:PATH=${SlicerExecutionModel_DIR}
    ${SLICER_CLI_TO_BUILD}
    -Dcli-modules_SUPERBUILD:BOOL=OFF
    )

  ### --- End Project specific additions
  set( ${proj}_REPOSITORY ${git_protocol}://github.com/fbudin69500/SlicerCLI.git )
  set( ${proj}_GIT_TAG 739793d164836c6fce3c4df4ff2a3e8d72574356 )
  if( NOT DEFINED Slicer_Revision )
    set( Slicer_Revision 0 ) 
  endif()
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
      -D${LOCAL_PROJECT_NAME}_SUPERBUILD:BOOL=OFF
      ## We really do want to install to remove uncertainty about where the tools are
      ## (on Windows, tools might be in subfolders, like "Release", "Debug",...)
      -DCMAKE_INSTALL_PREFIX:PATH=${EXTERNAL_BINARY_DIRECTORY}/${proj}-install
    PATCH_COMMAND ${CMAKE_COMMAND} -DSlicer_Revision:STRING=${Slicer_Revision} -DStringModules:STRING="${StringModules}" -DSubversion_SVN_EXECUTABLE:FILEPATH=${Subversion_SVN_EXECUTABLE} -DDOWNLOAD_DIR:PATH=${EXTERNAL_SOURCE_DIRECTORY}/${proj} -P ${EXTERNAL_SOURCE_DIRECTORY}/${proj}/SuperBuild/SlicerExecutionModelDownload.cmake
    DEPENDS
      ${${proj}_DEPENDENCIES}
  )
  set(${extProjName}_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build)
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