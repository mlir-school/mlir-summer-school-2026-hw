#===----------------------------------------------------------------------===#
# List dialect tutorial
#===----------------------------------------------------------------------===#

set(LLVM_TARGET_DEFINITIONS ListOps.td)
mlir_tablegen(ListOps.h.inc -gen-op-decls)
mlir_tablegen(ListOps.cpp.inc -gen-op-defs)
mlir_tablegen(ListOpsTypes.h.inc -gen-typedef-decls -typedefs-dialect=list)
mlir_tablegen(ListOpsTypes.cpp.inc -gen-typedef-defs -typedefs-dialect=list)
mlir_tablegen(ListOpsDialect.h.inc -gen-dialect-decls -dialect=list)
mlir_tablegen(ListOpsDialect.cpp.inc -gen-dialect-defs -dialect=list)
mlir_tablegen(ListOps.md -gen-op-doc)
add_public_tablegen_target(MLIRListOpsIncGen)

add_mlir_library(ListDialect
  ListDialect.cpp
  ListOps.cpp

  DEPENDS
  MLIRListOpsIncGen

  LINK_LIBS PUBLIC
  MLIRDialect
  MLIRIR
  MLIRSupport
)
