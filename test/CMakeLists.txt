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

add_lit_testsuite(check-tutorial "Checking the tutorial setup"
  ${CMAKE_CURRENT_BINARY_DIR}
  ARGS -v
  DEPENDS ${TUTORIAL_TEST_DEPENDS}
)
