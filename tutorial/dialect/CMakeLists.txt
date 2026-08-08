set(LLVM_TARGET_DEFINITIONS TutorialDialect.td)
mlir_tablegen(TutorialOps.h.inc -gen-op-decls)
mlir_tablegen(TutorialOps.cpp.inc -gen-op-defs)
mlir_tablegen(TutorialOpsDialect.h.inc -gen-dialect-decls -dialect=tutorial)
mlir_tablegen(TutorialOpsDialect.cpp.inc -gen-dialect-defs -dialect=tutorial)
add_public_tablegen_target(TutorialOpsIncGen)

add_mlir_library(TutorialDialect
  TutorialDialect.cpp

  DEPENDS
  TutorialOpsIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRSideEffectInterfaces
)

target_include_directories(TutorialDialect PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/..
  ${CMAKE_CURRENT_BINARY_DIR}/..
)
