#===----------------------------------------------------------------------===#
# Dense path-sensitive list non-emptiness analysis tutorial
#===----------------------------------------------------------------------===#

add_mlir_library(ListNonEmptyPathAnalysis
  NonEmptyPathAnalysis.cpp
  NonEmptyPathAnalysisPass.cpp
  NonEmptyPathOptimizationPass.cpp

  LINK_LIBS PUBLIC
  MLIRAnalysis
  MLIRArithDialect
  MLIRControlFlowDialect
  MLIRIR
  MLIRPass
  MLIRTransforms
  ListDialect
)

target_include_directories(ListNonEmptyPathAnalysis PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/../..
  ${CMAKE_CURRENT_BINARY_DIR}/../..
)
