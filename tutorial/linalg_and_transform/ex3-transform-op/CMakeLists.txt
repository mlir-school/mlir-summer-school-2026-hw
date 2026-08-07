#===----------------------------------------------------------------------===#
# Exercise 3: a transform dialect extension
#===----------------------------------------------------------------------===#

set(LLVM_TARGET_DEFINITIONS TutorialTransformOps.td)
mlir_tablegen(TutorialTransformOps.h.inc -gen-op-decls)
mlir_tablegen(TutorialTransformOps.cpp.inc -gen-op-defs)
add_public_tablegen_target(TutorialTransformOpsIncGen)

add_mlir_library(TutorialTransformOps
  TutorialTransformExtension.cpp
  PrintHandleOp.cpp

  DEPENDS
  TutorialTransformOpsIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRSideEffectInterfaces
  MLIRTransformDialect
  MLIRTransformDialectInterfaces
)

target_include_directories(TutorialTransformOps PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/..
  ${CMAKE_CURRENT_BINARY_DIR}/..
)
