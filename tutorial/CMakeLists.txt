#===----------------------------------------------------------------------===#
# Tutorial MLIR Tool
#===----------------------------------------------------------------------===#

# Both the TableGen `include` directives and the C++ `#include`s spell the
# dialect files out from here (`list/IR/...`), so this directory is the include
# root: the source tree for the hand-written files, the build tree for the
# generated `.inc` files. Subdirectories inherit both, and `mlir_tablegen` picks
# them up from this directory property.
include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})

# Add tutorial dialects.
add_subdirectory(list)

set(LLVM_LINK_COMPONENTS
  Support
)

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)
get_property(extension_libs GLOBAL PROPERTY MLIR_EXTENSION_LIBS)

add_llvm_executable(tutorial-opt
  tutorial-opt.cpp
)

llvm_update_compile_flags(tutorial-opt)

target_link_libraries(tutorial-opt
  PRIVATE
  ${dialect_libs}
  ${conversion_libs}
  ${extension_libs}
  MLIROptLib
  MLIRPass
  MLIRTransforms
  MLIRRegisterAllDialects
  MLIRRegisterAllPasses
  MLIRRegisterAllExtensions
  ListDialect
  ListTransforms
)
