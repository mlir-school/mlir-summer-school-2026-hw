#===----------------------------------------------------------------------===#
# List size range analysis tutorial
#===----------------------------------------------------------------------===#

add_mlir_library(ListSizeRangeAnalysis
  SizeRangeAnalysis.cpp
  SizeRangeAnalysisPass.cpp
  SizeRangeOptimizationPass.cpp

  LINK_LIBS PUBLIC
  MLIRAnalysis
  MLIRArithDialect
  MLIRIR
  MLIRPass
  ListDialect
)

target_include_directories(ListSizeRangeAnalysis PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/../..
  ${CMAKE_CURRENT_BINARY_DIR}/../..
)
