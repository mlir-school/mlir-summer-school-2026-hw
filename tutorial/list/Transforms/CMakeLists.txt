#===----------------------------------------------------------------------===#
# List dialect transformations
#===----------------------------------------------------------------------===#

set(LLVM_TARGET_DEFINITIONS ListPasses.td)
mlir_tablegen(ListPasses.h.inc -gen-pass-decls -name List)
add_public_tablegen_target(MLIRListTransformsIncGen)

add_mlir_library(ListTransforms
  Exercise_1_ListLowerFromElements.cpp
  Exercise_2_4_ListSimplify.cpp

  DEPENDS
  MLIRListTransformsIncGen
  MLIRListOpsIncGen

  LINK_LIBS PUBLIC
  ListDialect
  MLIRArithDialect
  MLIRIR
  MLIRPass
  MLIRSCFDialect
  MLIRSupport
  MLIRTransforms
  MLIRVectorDialect
)
