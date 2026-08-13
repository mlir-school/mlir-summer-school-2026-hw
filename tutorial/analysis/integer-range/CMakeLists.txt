#===----------------------------------------------------------------------===#
# MLIR integer range analysis tutorial
#===----------------------------------------------------------------------===#

add_mlir_library(ListIntegerRangeAnalysis
  IntegerRangeAnalysisPass.cpp
  IntegerRangeOptimizationPass.cpp
  ListIntegerRangeAnalysis.cpp

  LINK_LIBS PUBLIC
  MLIRAnalysis
  MLIRArithDialect
  MLIRIR
  MLIRPass
  MLIRTransforms
  ListDialect
  ListSizeRangeAnalysis
)

target_include_directories(ListIntegerRangeAnalysis PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/../..
  ${CMAKE_CURRENT_BINARY_DIR}/../..
)
