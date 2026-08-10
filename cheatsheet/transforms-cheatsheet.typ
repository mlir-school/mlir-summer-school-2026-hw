// MLIR Core Transformations Cheatsheet -- ACM Europe School on MLIR 2026,
// Day 2 Session 4.
// Build:  typst compile transforms-cheatsheet.typ

#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 3mm, y: 3mm),
  columns: 2,
)
#set columns(gutter: 4mm)

#set text(font: ("DejaVu Sans", "Liberation Sans"), size: 7.0pt, hyphenate: false)
#set par(justify: false, leading: 0.36em, spacing: 0.34em)
#set raw(syntaxes: ("tablegen.sublime-syntax", "mlir.sublime-syntax"))

#show raw: set text(font: ("DejaVu Sans Mono", "Liberation Mono"), size: 6.5pt)
#show raw.where(block: true): b => block(
  width: 100%, fill: luma(96%), inset: (x: 3pt, y: 2.4pt), radius: 1.5pt,
  above: 2.4pt, below: 2.4pt,
  { set par(leading: 0.30em); b },
)
#show raw.where(block: false): r => box(
  fill: luma(95%), inset: (x: 1.2pt, y: 0pt), outset: (y: 1.6pt), radius: 1pt, r,
)

#let accent = rgb("#1f4e79")

#let card(title, body) = block(
  breakable: false, width: 100%, above: 0pt, below: 2.6pt,
  stroke: 0.5pt + accent, radius: 2pt, clip: true, inset: 0pt,
)[
  #block(width: 100%, fill: accent, inset: (x: 4pt, y: 1.8pt))[
    #text(fill: white, weight: "bold", size: 8.8pt, title)
  ]
  #block(width: 100%, inset: (x: 4pt, y: 2.6pt), body)
]

// Tables get a hairline between every row so single rows stay easy to follow.
#let tbl(..args) = table(
  stroke: (x, y) => (top: if y == 0 { none } else { 0.3pt + luma(78%) }),
  inset: (x: 2.5pt, y: 2.2pt), align: left + top, row-gutter: 0pt, ..args,
)
#let hd(s) = text(weight: "bold", fill: accent, s)
#let key(s) = text(weight: "bold", s)

// ---------------------------------------------------------------- title -----
#place(top, float: true, scope: "parent", clearance: 3pt)[
  #block(width: 100%, inset: (x: 2pt, y: 0pt))[
    #text(size: 14pt, weight: "bold", fill: accent)[MLIR Core Transformations Cheatsheet]
    #h(5pt)
    #text(size: 8pt)[Canonicalization and folding · ACM Europe School on MLIR 2026 · `#include "mlir/IR/PatternMatch.h"`, `"mlir/IR/OpDefinition.h"`]
  ]
  #line(length: 100%, stroke: 0.9pt + accent)
]

// =============================================================== cards =======

#card[1 · Registering canonicalizations][
  ```tablegen
  def List_MapOp : List_Op<"map", [...]> {
    ...
    let hasCanonicalizer = 1;
    ...
  }
  ```
  ```cpp
  /// ListOps.cpp
  void MapOp::getCanonicalizationPatterns(RewritePatternSet &results,
                                          MLIRContext *context) {
    results.add<YourRewritePatternsHere, NextPattern>(context);
  }
  ```
  #tbl(columns: (auto, 1fr),
    hd[In ODS], hd[What you implement],
    [`hasCanonicalizer = 1`], [`static void getCanonicalizationPatterns(`
      `RewritePatternSet &, MLIRContext *)` -- any number of patterns rooted at
      this op],
    [`hasFolder = 1`], [`fold` -- no extra registration needed, the canonicalizer
      runs folders as well],
  )
]

#card[2 · Is my pattern a canonicalization?][
  #key[Canonical IR:] "all programs that compute the same thing should have the
  same IR". Which patterns get you there is a #key[design choice] -- these are
  guidelines, not rules.
  #tbl(columns: (auto, 1fr),
    hd[Yes], hd[],
    [constant folding], [`arith.addi 1, 0` #sym.arrow.r `1`],
    [fewer operations], [`addi(%x, muli(%y, -1))` #sym.arrow.r `subi(%x, %y)`],
    [it converges], [no ping-pong with another pattern],
  )
  #tbl(columns: (auto, 1fr),
    hd[No], hd[],
    [information is lost], [litmus test: *"can I no longer perform an
      optimization afterwards?"* Then it is a #key[lowering] -- put it in your
      own pass],
  )
  Things you do #emph[not] need to care about here: the performance of the
  generated code. Canonicalization is about form, not speed.
]

#card[3 · Enabling fold for your Operation][
  ```tablegen
  def List_LengthOp : List_Op<"length", [Pure]> {
    ...
    // Whether this op has a folder.
    let hasFolder = 1;
  }
  ```
  #hd[Single-result op]
  ```cpp
  OpFoldResult MyOp::fold(FoldAdaptor adaptor) {
    ...
    return nullptr;   // on failure
  }
  ```
  #hd[Otherwise]
  ```cpp
  LogicalResult MyOp::fold(FoldAdaptor adaptor,
                           SmallVectorImpl<OpFoldResult> &results) {
    ...
    return failure();   // on failure (duh)
  }
  ```
  A folder may #key[not] create or erase operations. It may inspect the
  surrounding IR.
]

#card[4 · What fold returns: OpFoldResult][
  ```cpp
  class OpFoldResult : public PointerUnion<Value, Attribute>
  ```
  #key[A `Value`] replaces the op with an already existing value:
  ```cpp
  OpFoldResult ReverseOp::fold(FoldAdaptor adaptor) {
    // list.reverse(list.reverse(%li)) -> %li
    if (auto producer = getInput().getDefiningOp<ReverseOp>())
      return producer.getInput();
    return nullptr;
  }
  ```
  #key[An `Attribute`] replaces the op with a constant:
  ```mlir
  %lb = arith.constant 1 : i32
  %ub = arith.constant 4 : i32
  %li = list.range %lb to %ub : !list.list<i32>
  // becomes
  %li = list.constant #list.list<[1, 2, 3]> : !list.list<i32>
  ```
  #key[`{}` / `nullptr`] means "did not fold".
]

#card[5 · The FoldAdaptor parameter][
  ODS generates it next to the op, as a mirror for folding: every operand getter
  returns that operand's #key[constant value] instead of its `Value`, and is null
  when the operand is not a constant.
  ```cpp
  class PushBackOp : mlir::Op<...> {   class PushBackOp::FoldAdaptor {
  public:                             public:
    Value getInput();                   Attribute getInput();  // null if not
    Value getItem();                    Attribute getItem();   // a constant
  };                                  };
  ```
  Combine it with `dyn_cast_if_present` -- plain `dyn_cast` asserts on null:
  ```cpp
  OpFoldResult PushBackOp::fold(FoldAdaptor adaptor) {
    auto constant = dyn_cast_if_present<ListAttr>(adaptor.getInput());
    auto item = dyn_cast_if_present<IntegerAttr>(adaptor.getItem());
    if (!constant || !item)
      return {};
    SmallVector<int64_t> elements(constant.getElements());
    elements.push_back(item.getValue().getSExtValue());
    return ListAttr::get(constant.getType(), elements);
  }
  ```
  Attributes of the op are always constant, so read them from `adaptor` too.
]

#card[6 · Constant-folding checklist][
  #key[1.] Have an attribute that can represent a constant of the result type.
  #tbl(columns: (auto, 1fr),
    hd[MLIR C++ type], hd[MLIR C++ attribute],
    [`IntegerType`], [`IntegerAttr`],
    [`IntegerType` (`i1`)], [`BoolAttr`],
    [`list::ListType`], [`list::ListAttr`],
  )
  #key[2.] Have a `ConstantLike` operation that holds it:
  ```tablegen
  def List_ConstantOp : List_Op<"constant",
      [ConstantLike, Pure, AllTypesMatch<["value", "result"]>]> {
    let arguments = (ins List_ListAttr:$value);
    let results   = (outs List_ListType:$result);
    let hasFolder = 1;   // fold() { return getValueAttr(); }
  }
  ```
  #key[3.] Let the dialect materialize constants (next card).
]

#card[7 · The dialect materializes constants][
  ```tablegen
  def List_Dialect : Dialect {
    ...
    let hasConstantMaterializer = 1;
    // materializeConstant builds arith ops, so that dialect must be loaded too
    let dependentDialects = ["::mlir::arith::ArithDialect"];
  }
  ```
  ```cpp
  Operation *ListDialect::materializeConstant(OpBuilder &builder,
                                              Attribute value, Type type,
                                              Location loc) {
    if (auto listValue = dyn_cast<ListAttr>(value)) {
      if (listValue.getType() != type)
        return nullptr;
      return ConstantOp::create(builder, loc, listValue.getType(), listValue);
    }
    // Some folders produce integers or booleans instead!
    return arith::ConstantOp::materialize(builder, value, type, loc);
  }
  ```
  A fold whose attribute cannot be materialized is #key[silently dropped] -- if
  your folder seems to do nothing, look here first.
]

#card[8 · fold or RewritePattern?][
  #tbl(columns: (1fr, 1fr),
    hd[Use `fold`], hd[Use a `RewritePattern`],
    [when you can -- rule of least power], [when you need to create operations],
    [constant folding; `FoldAdaptor` is your friend], [`PatternRewriter` is your
      friend],
    [local: only this op's result changes], [may rewrite anything, anywhere],
    [free in `canonicalize`, `createOrFold` and dataflow analyses], [also fine
      for lowerings and opinionated transformations],
    [canonicalization only], [canonicalization #key[or] your own pass],
  )
]
