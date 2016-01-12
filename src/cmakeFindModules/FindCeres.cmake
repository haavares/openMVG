# - Find Ceres library
# Find the native Ceres includes and library
# This module defines
#  Ceres_INCLUDE_DIRS, where to find ceres.h, Set when
#                      Ceres_INCLUDE_DIR is found.
#  Ceres_LIBRARIES, libraries to link against to use Ceres.
#  Ceres_ROOT_DIR, The base directory to search for Ceres.
#                  This can also be an environment variable.
#  Ceres_FOUND, If false, do not try to use Ceres.
#
# also defined, but not for general use are
#  Ceres_LIBRARY, where to find the Ceres library.

# If Ceres_ROOT_DIR was defined in the environment, use it.
IF(NOT Ceres_ROOT_DIR AND NOT $ENV{Ceres_ROOT_DIR} STREQUAL "")
  SET(Ceres_ROOT_DIR $ENV{Ceres_ROOT_DIR})
ENDIF()
MESSAGE(STATUS "coucou : ${Ceres_ROOT_DIR}")
SET(_ceres_SEARCH_DIRS
  ${Ceres_ROOT_DIR}
  /usr/local
  /sw # Fink
  /opt/local # DarwinPorts
  /opt/csw # Blastwave
  /opt/lib/ceres
  /opt/local/ceres # addition for manual compile
)

FIND_PATH(Ceres_INCLUDE_DIR
  NAMES
    ceres/ceres.h
  HINTS
    ${_ceres_SEARCH_DIRS}
  PATH_SUFFIXES
    include
)

IF(Ceres_INCLUDE_DIR)
  MESSAGE( STATUS "Ceres include path found as ${Ceres_INCLUDE_DIR}" )
ELSE(Ceres_INCLUDE_DIR)
  MESSAGE( FATAL_ERROR "Ceres include path not found" )
ENDIF(Ceres_INCLUDE_DIR)

# TODO: Is Ceres_CONFIG_INCLUDE_DIR really needed? Or is it by default when the installation is correct?
FIND_PATH(Ceres_CONFIG_INCLUDE_DIR
  NAMES
    ceres/internal/config.h
  HINTS
    ${_ceres_SEARCH_DIRS}
  PATH_SUFFIXES
    config include
)
IF(Ceres_CONFIG_INCLUDE_DIR)
  MESSAGE( STATUS "Ceres config file found at ${Ceres_CONFIG_INCLUDE_DIR}")
  IF(NOT Ceres_INCLUDE_DIR STREQUAL Ceres_CONFIG_INCLUDE_DIR)
    SET(Ceres_INCLUDE_DIR ${Ceres_INCLUDE_DIR} ${Ceres_CONFIG_INCLUDE_DIR})
  ENDIF(NOT Ceres_INCLUDE_DIR STREQUAL Ceres_CONFIG_INCLUDE_DIR)
ELSE(Ceres_CONFIG_INCLUDE_DIR)
  MESSAGE( FATAL_ERROR "Ceres config file ceres/internal/config.h not found" )
ENDIF(Ceres_CONFIG_INCLUDE_DIR)


# message( WARNING "est-ce que tu m'entends he ho - dixit TRAGEDY ${Ceres_INCLUDE_DIR}")
FIND_LIBRARY(Ceres_LIBRARY
  NAMES
    ceres
  HINTS
    ${_ceres_SEARCH_DIRS}
  PATH_SUFFIXES
    lib64 lib
  )

IF(Ceres_LIBRARY)
  MESSAGE( STATUS "Ceres library found at ${Ceres_LIBRARY}" )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_amd
    NAMES amd
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_btf
    NAMES btf
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_camd
    NAMES camd
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_ccolamd
    NAMES ccolamd
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_cholmod
    NAMES cholmod
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_colamd
    NAMES colamd
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_csparse
    NAMES csparse
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_cxsparse
    NAMES cxsparse
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_klu
    NAMES klu
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_ldl
    NAMES ldl
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_rbio
    NAMES rbio
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_spqr
    NAMES spqr
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_umfpack
    NAMES umfpack
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )
  FIND_LIBRARY(SUITESPARSE_LIBRARY_suitesparseconfig
    NAMES suitesparseconfig
    HINTS ${_ceres_SEARCH_DIRS}
    PATH_SUFFIXES lib64 lib )

  IF(SUITESPARSE_LIBRARY_amd)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_amd})
  ENDIF(SUITESPARSE_LIBRARY_amd)
  IF(SUITESPARSE_LIBRARY_btf)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_btf})
  ENDIF(SUITESPARSE_LIBRARY_btf)
  IF(SUITESPARSE_LIBRARY_camd)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_camd})
  ENDIF(SUITESPARSE_LIBRARY_camd)
  IF(SUITESPARSE_LIBRARY_ccolamd)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_ccolamd})
  ENDIF(SUITESPARSE_LIBRARY_ccolamd)
  IF(SUITESPARSE_LIBRARY_cholmod)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_cholmod})
  ENDIF(SUITESPARSE_LIBRARY_cholmod)
  IF(SUITESPARSE_LIBRARY_colamd)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_colamd})
  ENDIF(SUITESPARSE_LIBRARY_colamd)
  IF(SUITESPARSE_LIBRARY_csparse)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_csparse})
  ENDIF(SUITESPARSE_LIBRARY_csparse)
  IF(SUITESPARSE_LIBRARY_cxsparse)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_cxsparse})
  ENDIF(SUITESPARSE_LIBRARY_cxsparse)
  IF(SUITESPARSE_LIBRARY_klu)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_klu})
  ENDIF(SUITESPARSE_LIBRARY_klu)
  IF(SUITESPARSE_LIBRARY_ldl)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_ldl})
  ENDIF(SUITESPARSE_LIBRARY_ldl)
  IF(SUITESPARSE_LIBRARY_rbio)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_rbio})
  ENDIF(SUITESPARSE_LIBRARY_rbio)
  IF(SUITESPARSE_LIBRARY_spqr)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_spqr})
  ENDIF(SUITESPARSE_LIBRARY_spqr)
  IF(SUITESPARSE_LIBRARY_umfpack)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_umfpack})
  ENDIF(SUITESPARSE_LIBRARY_umfpack)
  IF(SUITESPARSE_LIBRARY_suitesparseconfig)
    SET(SUITESPARSE_LIBRARIES ${SUITESPARSE_LIBRARIES} ${SUITESPARSE_LIBRARY_suitesparseconfig})
  ENDIF(SUITESPARSE_LIBRARY_suitesparseconfig)

  MESSAGE( STATUS "SuiteSparse libraries ${SUITESPARSE_LIBRARIES} found" )
  SET(Ceres_FOUND TRUE)
ELSE(Ceres_LIBRARY)
  MESSAGE( FATAL_ERROR "Ceres library not found" )
ENDIF(Ceres_LIBRARY)

# handle the QUIETLY and REQUIRED arguments and set Ceres_FOUND to TRUE if
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(ceres DEFAULT_MSG
    Ceres_LIBRARY Ceres_INCLUDE_DIR)

IF(Ceres_FOUND)
  SET(Ceres_LIBRARIES ${Ceres_LIBRARY} ${SUITESPARSE_LIBRARIES})
  SET(Ceres_INCLUDE_DIRS ${Ceres_INCLUDE_DIR})
  MESSAGE(STATUS "Ceres successfully configured")
ELSE(Ceres_FOUND)
  MESSAGE(FATAL_ERROR "Ceres it not completely configured")
ENDIF(Ceres_FOUND)

MARK_AS_ADVANCED(
  Ceres_INCLUDE_DIR
  Ceres_LIBRARY
)

