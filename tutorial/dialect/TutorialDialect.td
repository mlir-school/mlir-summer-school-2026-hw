// A minimal dialect used to verify that the tutorial toolchain works.

#ifndef TUTORIAL_DIALECT
#define TUTORIAL_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

def Tutorial_Dialect : Dialect {
  let name = "tutorial";
  let cppNamespace = "::mlir::tutorial";
  let summary = "A minimal dialect for checking the tutorial setup";
}

class Tutorial_Op<string mnemonic, list<Trait> traits = []>
    : Op<Tutorial_Dialect, mnemonic, traits>;

def Tutorial_ConstantOp : Tutorial_Op<"constant", [Pure]> {
  let summary = "Produce a constant i32 value";
  let arguments = (ins I32Attr:$value);
  let results = (outs I32:$result);
  let assemblyFormat = "$value attr-dict `:` type($result)";
}

#endif // TUTORIAL_DIALECT
