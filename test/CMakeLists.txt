configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
  MAIN_CONFIG
  ${CMAKE_SOURCE_DIR}/lit.cfg.py
)

set(TUTORIAL_TEST_DEPENDS
  tutorial-opt
  FileCheck
)

# `add_lit_testsuite` knows where lit lives, the per-tutorial targets below
# invoke it directly and have to be told.
set(TUTORIAL_LIT_COMMAND ${LLVM_EXTERNAL_LIT})
if(NOT TUTORIAL_LIT_COMMAND)
  set(TUTORIAL_LIT_COMMAND ${LLVM_DEFAULT_EXTERNAL_LIT})
endif()
if(NOT TUTORIAL_LIT_COMMAND)
  set(TUTORIAL_LIT_COMMAND lit)
endif()

# All tests - run lit on build directory
add_lit_testsuite(check-tutorial "Running all tutorial tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  ARGS -v
  DEPENDS ${TUTORIAL_TEST_DEPENDS}
)

# Per-tutorial test targets using --filter
add_custom_target(check-tutorial-list
  COMMAND ${TUTORIAL_LIT_COMMAND} ${CMAKE_CURRENT_BINARY_DIR} --filter=list -v
  DEPENDS ${TUTORIAL_TEST_DEPENDS}
  COMMENT "Running list tutorial tests"
)

add_custom_target(check-tutorial-analysis
  COMMAND ${LLVM_EXTERNAL_LIT} ${CMAKE_CURRENT_BINARY_DIR} --filter=analysis -v
  DEPENDS ${TUTORIAL_TEST_DEPENDS}
  COMMENT "Running analysis tutorial tests"
)
