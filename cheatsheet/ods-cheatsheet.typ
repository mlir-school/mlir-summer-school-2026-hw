// MLIR ODS Cheatsheet -- ACM Europe School on MLIR 2026, Day 2 Session 1
// Build:  typst compile ods-cheatsheet.typ

#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 3mm, y: 3mm),
  columns: 3,
)
#set columns(gutter: 3.5mm)

#set text(font: ("DejaVu Sans", "Liberation Sans"), size: 5.0pt, hyphenate: false)
#set par(justify: false, leading: 0.36em, spacing: 0.34em)
#set raw(syntaxes: ("tablegen.sublime-syntax", "mlir.sublime-syntax"))

#show raw: set text(font: ("DejaVu Sans Mono", "Liberation Mono"), size: 4.65pt)
#show raw.where(block: true): b => block(
  width: 100%, fill: luma(96%), inset: (x: 2.5pt, y: 1.8pt), radius: 1.5pt,
  above: 1.8pt, below: 1.8pt,
  { set par(leading: 0.30em); b },
)
#show raw.where(block: false): r => box(
  fill: luma(95%), inset: (x: 1.2pt, y: 0pt), outset: (y: 1.6pt), radius: 1pt, r,
)

#let accent = rgb("#1f4e79")

#let card(title, body) = block(
  breakable: false, width: 100%, above: 0pt, below: 1.6pt,
  stroke: 0.5pt + accent, radius: 2pt, clip: true, inset: 0pt,
)[
  #block(width: 100%, fill: accent, inset: (x: 3pt, y: 1.2pt))[
    #text(fill: white, weight: "bold", size: 6.5pt, title)
  ]
  #block(width: 100%, inset: (x: 3pt, y: 1.8pt), body)
]

// Tables get a hairline between every row so single rows stay easy to follow.
#let tbl(..args) = table(
  stroke: (x, y) => (top: if y == 0 { none } else { 0.3pt + luma(78%) }),
  inset: (x: 2pt, y: 1.7pt), align: left + top, row-gutter: 0pt, ..args,
)
#let hd(s) = text(weight: "bold", fill: accent, s)
#let key(s) = text(weight: "bold", s)

// ---------------------------------------------------------------- title -----
#place(top, float: true, scope: "parent", clearance: 3pt)[
  #block(width: 100%, inset: (x: 2pt, y: 0pt))[
    #text(size: 11pt, weight: "bold", fill: accent)[MLIR ODS Cheatsheet]
    #h(5pt)
    #text(size: 6.4pt)[Defining Operations declaratively with TableGen · ACM Europe School on MLIR 2026 · `include "mlir/IR/OpBase.td"`, `"mlir/IR/Constraints.td"`, `"mlir/IR/CommonTypeConstraints.td"`]
  ]
  #line(length: 100%, stroke: 0.9pt + accent)
]

// =============================================================== cards =======

#card[1 · TableGen in 60 seconds][
  ```tablegen
  class ExampleClass<int parameter> {    // only code-reuse construct
    int field_ = !add(parameter, 1);
    string otherField = ?;               // ? == unset
  }
  def ExampleDef : ExampleClass<5> {     // generators emit code per def
    let otherField = "a value";          // let overrides a field
  }
  ```
  Generators (ODS) look for `def`s of a known `class` (e.g. `Op`); the fields you
  may `let` are documented in *that* class.
  #tbl(columns: (auto, auto, 1fr),
    hd[TableGen], hd[Literal syntax], hd[C++],
    [`int`], [`0` `-5` `0x5`], [`int64_t`],
    [`string`/`code`], [`"C string"`, `[{ raw }]`], [`std::string`],
    [`bit`], [`0` `1` `true` `false`], [`bool`],
    [`dag`], [`(op Value:$name, ...)`], [--],
    [`list<T>`], [`[a, b, c]`], [`std::vector`],
    [`ClassName`], [`ClassName<...>`, `DefName`], [`ClassName`],
  )
]

#card[2 · Skeleton of an Operation][
  ```tablegen
  class List_Op<string mnemonic, list<Trait> traits = []>
      : Op<List_Dialect, mnemonic, traits>;

  def List_RangeOp : List_Op<"range", [/* traits */]> {
    let summary = "list of a half-open integer range";
    let description = [{ Markdown docs, incl. a fenced mlir example. }];

    let arguments = (ins I32:$lower, I32:$upper);
    let results   = (outs List_ListType:$result);

    let assemblyFormat = [{
      $lower `to` $upper attr-dict `:` qualified(type($result))
    }];
  }
  ```
  #tbl(columns: (auto, 1fr),
    hd[Naming], hd[Convention],
    [`def` name], [PascalCase; text up to the first `_` is *dropped* from the
      C++ name #sym.arrow.r `mlir::list::RangeOp`],
    [mnemonic], [snake_case (sometimes camelCase) #sym.arrow.r `list.range`],
  )
]

#card[3 · Fields of the Op class][
  #tbl(columns: (auto, 1fr),
    hd[Field], hd[Purpose],
    [`arguments`], [`(ins ...)` -- operands #sym.plus attributes],
    [`results`], [`(outs ...)` -- result types],
    [`regions`], [`(region ...)` -- attached regions],
    [`summary` / `description`], [docs (`description` is Markdown)],
    [`assemblyFormat`], [declarative custom syntax],
    [`hasVerifier`], [`= 1` #sym.arrow.r `LogicalResult verify()`],
    [`hasRegionVerifier`], [`= 1` #sym.arrow.r `verifyRegions()`],
    [`opDialect`, `opName`,\ `cppNamespace`], [already set for you by
      `Op<dialect, mnemonic, traits>`],
  )
]

#card[4 · TypeConstraints — ins / outs][
  A `TypeConstraint` allows one or more types as a result type or as the type of
  an operand.
  #tbl(columns: (auto, auto, 1fr),
    hd[TableGen], hd[MLIR], hd[C++ getter type],
    [`I1`, `I8` .. `I64`], [`i1`, `i32`], [`TypedValue<IntegerType>`],
    [`AnyInteger`], [any `iN`], [`TypedValue<IntegerType>`],
    [`AnyType`], [anything], [`Value`],
    [`AnyTypeOf<[I32, I64]>`], [--], [`Value`],
    [`List_ListType`], [`!list.list<i32>`], [`TypedValue<ListType>`],
    [`Optional<X>`], [0 or 1], [`Value` (null if absent)],
    [`Variadic<X>`], [0 .. n], [`OperandRange`],
  )
  Extendable via C++ predicates:
  `Type<CPred<"::llvm::isa<MyType>($_self)">, "my type">`.
]

#card[5 · Attributes are arguments too][
  ```tablegen
  let arguments = (ins List_ListType:$input,   // operand
                       I64Attr:$offset,        // attribute
                       UnitAttr:$nsw,          // presence == true
                       OptionalAttr<I32Attr>:$maybe,
                       DefaultValuedAttr<I32Attr, "0">:$init);
  ```
  `BoolAttr` `I32Attr` `I64Attr` `IndexAttr` `F32Attr` `StrAttr` `TypeAttr`
  `ArrayAttr` `DenseI64ArrayAttr` `SymbolRefAttr` `AnyAttr`. `getOffset()`
  returns the *unwrapped* value (`uint64_t`), `getOffsetAttr()` the
  `IntegerAttr`. In `assemblyFormat` reference it like an operand: `$offset`.
]

#card[6 · assemblyFormat directives][
  Describes the syntax #emph[after] the `list.range` prefix.
  #tbl(columns: (auto, 1fr),
    hd[Directive], hd[Meaning],
    [#raw("`kw`")], [literal keyword or punctuation: #raw("`,`") #raw("`:`")
      #raw("`->`") #raw("`(`")],
    [`$name`], [operand, attribute, region or successor],
    [`type($name)`], [the type of that value],
    [`qualified(type($x))`], [force the `!dialect.` prefix],
    [`attr-dict`], [#key[mandatory] -- discardable attributes],
    [`functional-type($in,$out)`], [prints `(i32, i32) -> i1`],
    [`custom<Foo>($a, type($b))`], [calls C++ `parseFoo` / `printFoo`],
    [#raw("($x^ `:` type($x))?")], [optional group, `^` = anchor],
    [`regions` / `successors`], [all of them at once],
  )
  #key[Rules:] every argument must appear; every type must appear via `type(...)`
  unless singleton or deducible; there is always an `attr-dict`.
]

#card[7 · Syntax conventions][
  Follow #raw("<arguments> attr-dict `:` <types>"); write types as
  `<arg-types> -> <result-types>`.
  ```mlir
  // DO
  %lo = list.push_back %li, %item : !list.list<i32>, i32 -> !list.list<i32>
  // DON'T -- types interleaved with the arguments
  %lo = list.push_back %li : !list.list<i32>, %item : i32 -> !list.list<i32>
  // DON'T -- result type inside the operand type list
  %lo = list.push_back %li, %item : !list.list<i32>, i32, !list.list<i32>
  ```
  Use the bare minimum of `type($x)` directives; drop `->` when one side is
  deducible or absent: `%r = list.reverse %0 : !list.list<i32>`.
]

#card[8 · Type deduction: fewer types in the syntax][
  #tbl(columns: (auto, 1fr),
    hd[Trait], hd[Effect],
    [`AllTypesMatch<["a", "b"]>`], [all named args share one type],
    [`SameOperandsAndResultType`], [everything one type],
    [`SameTypeOperands`], [operands only],
    [`TypesMatchWith<...>`], [arbitrary transform (below)],
  )
  ```tablegen
  def List_ReverseOp : List_Op<"reverse",
      [AllTypesMatch<["input", "result"]>]> {
    let arguments = (ins List_ListType:$input);
    let results   = (outs List_ListType:$result);
    // only ONE of input/result must appear in the syntax:
    let assemblyFormat = "$input attr-dict `:` qualified(type($input))";
  }
  ```
  `TypesMatchWith<summary, lhsArg, rhsArg, transform>` checks
  `transform(lhs.getType()) == rhs.getType()`; `$_self` is the #key[lhs] type.
  `#` concatenates strings in TableGen.
  ```tablegen
  class List_ItemTypeMatchesElementType<string listArg, string itemArg>
      : TypesMatchWith<"type of '" # itemArg # "' matches element type",
                       listArg, itemArg,
                       "::llvm::cast<::mlir::list::ListType>($_self)"
                       ".getElementType()">;
  ```
]

#card[9 · Regions][
  ```tablegen
  let regions = (region AnyRegion:$body);
  let regions = (region SizedRegion<1>:$then, SizedRegion<1>:$else);
  ```
  #tbl(columns: (auto, 1fr),
    hd[RegionConstraint], hd[Description],
    [`AnyRegion`], [unconstrained],
    [`SizedRegion<N>`], [exactly N blocks],
    [`MinSizedRegion<N>`], [at least N blocks],
  )
  `$body` in `assemblyFormat` prints/parses #emph[everything between the braces],
  block arguments included.
  ```tablegen
  let assemblyFormat = "$input `->` type($result) `with` $body attr-dict";
  ```
  ```mlir
  %mapped = list.map %list -> !list.list<i64> with {
  ^bb0(%elem: i32):
    %ext = arith.extsi %elem : i32 to i64
    list.yield %ext : i64
  }
  ```
]

#card[10 · Traits used with Regions][
  #tbl(columns: (auto, 1fr),
    hd[Trait], hd[Description],
    [`Terminator`], [marks this op as a terminator],
    [`SingleBlockImplicitTerminator<` `"CppOpClassName">`],
      [enforces (and auto-inserts) that terminator],
    [`HasParent<"CppOpClassName">`], [the op owning the enclosing region must be
      this one],
    [`ParentOneOf<[...]>`], [... one of these ops],
  )
  ```tablegen
  def SCF_YieldOp : SCF_Op<"yield", [
    Terminator, ParentOneOf<["ForOp", "IfOp", "WhileOp"]>,
  ]>;
  ```
]

#card[11 · Extra verification in C++][
  Not every invariant fits in TableGen (e.g. "the block argument type must equal
  the list's element type").
  ```tablegen
  let hasVerifier = 1;        // runs BEFORE the regions are verified
  let hasRegionVerifier = 1;  // runs AFTER  the regions are verified
  ```
  ```cpp
  /// ListOps.cpp
  LogicalResult MapOp::verify() {
    Block &body = getBody().front();
    if (body.getNumArguments() != 1)
      return emitOpError("expects the body to have exactly one argument");

    Type elemTy = getInput().getType().getElementType();
    if (body.getArgument(0).getType() != elemTy)
      return emitOpError("expects the body argument type (")
             << body.getArgument(0).getType()
             << ") to match the element type of the list (" << elemTy << ")";
    return success();
  }
  ```
  `emitOpError(msg)` prefixes `'list.map' op` and returns an `InFlightDiagnostic`
  you stream into with `<<`; success is `return success();`
]

#card[12 · The generated C++ API][
  #tbl(columns: (auto, 1fr),
    hd[ODS], hd[C++ (`ListOps.h.inc` / `.cpp.inc`)],
    [`def List_RangeOp`], [`mlir::list::RangeOp`],
    [`I32:$lower`], [`getLower()`, `getLowerMutable()`],
    [`outs List_ListType:$result`], [`TypedValue<ListType> getResult()`],
    [`I64Attr:$offset`], [`getOffset()`, `getOffsetAttr()`, `setOffset()`],
    [`region AnyRegion:$body`], [`Region &getBody()`],
  )
]

#card[13 · Anatomy of a lit test][
  Tests live in `test/list/*.mlir`; every such file is one lit test.
  ```mlir
  // RUN: tutorial-opt --split-input-file %s | FileCheck %s

  func.func @push_back(%li: !list.list<i32>, %it: i32) -> !list.list<i32> {
    %l = list.push_back %li, %it : !list.list<i32>
    return %l : !list.list<i32>
  }

  // CHECK-LABEL: func.func @push_back
  // CHECK-SAME:  (%[[LI:.*]]: !list.list<i32>, %[[IT:.*]]: i32)
  // CHECK:       %[[L:.*]] = list.push_back %[[LI]], %[[IT]]
  // CHECK:       return %[[L]]
  ```
  #tbl(columns: (auto, 1fr),
    [`// RUN:`], [lit runs this as a shell command; the test passes iff it exits
      with 0. Several `RUN:` lines = several commands, all must pass.],
    [`%s`], [substituted by lit with the path of *this* file],
    [`tutorial-opt`], [parses the IR and prints it again -- a #key[roundtrip
      test] proves your `assemblyFormat` prints what it parses],
    [`| FileCheck %s`], [pipes that printed IR into FileCheck, which reads its
      `CHECK` directives out of the very same file],
    [`--split-input-file`], [cuts the file at every `// -----` line and runs
      `tutorial-opt` on each piece independently],
  )
  #key[Run:] `cmake --build build --target check-tutorial` (or
  `check-tutorial-list`); one file: `lit -v build/test/list/roundtrip.mlir`.
  By hand: `build/bin/tutorial-opt test/list/roundtrip.mlir`.
]

#card[14 · How FileCheck matches][
  FileCheck reads the piped-in text #key[once, top to bottom]. Each directive
  starts matching where the previous one stopped, so the directives must appear
  in the same order as their matches in the output.
  #tbl(columns: (auto, 1fr),
    hd[Directive], hd[Matches],
    [`CHECK:`], [at or after the previous match; unmatched lines in between are
      skipped],
    [`CHECK-NEXT:`], [on the line #key[immediately] after the previous match],
    [`CHECK-SAME:`], [on the #key[same] line as the previous match -- lets you
      check one long line with several directives],
    [`CHECK-LABEL:`], [block anchor: the input is split at these and no other
      directive may match across the boundary. One per function.],
    [`CHECK-NOT:`], [must #key[not] occur between the previous and the next
      matching directive],
    [`CHECK-DAG:`], [a run of `CHECK-DAG` may match in any order],
    [`CHECK-COUNT-3:`], [the pattern must match 3 times in a row; also
      `CHECK-EMPTY:` -- "the next line is empty"],
  )
  Leading and trailing whitespace is ignored and internal whitespace matches any
  run of blanks, so indent the directives however you like.
]

#card[15 · FileCheck patterns and captures][
  #tbl(columns: (auto, 1fr),
    hd[Pattern], hd[Meaning],
    [plain text], [matched literally, as a substring of the line],
    [`{{re}}`], [regular expression, e.g. `{{.*}}` for "don't care"],
    [`[[NAME:re]]`], [match `re` and #key[capture] it as variable `NAME`],
    [`[[NAME]]`], [must equal what `NAME` captured earlier],
  )
  SSA value names are renumbered by the printer, so never hard-code them --
  capture them instead:
  ```mlir
  // CHECK: %[[L:.*]] = list.push_back %{{.*}}, %{{.*}}
  // CHECK: return %[[L]]
  ```
  #key[Idioms:] `%{{.*}}` -- some value, don't care which · `%[[X:.*]]` -- bind
  it · `!list.list<{{.*}}>` -- any element type · `{{\[\[}}` -- a literal `[[`.

  Keep checks #emph[loose]: assert the structure you care about, not the whole
  line, otherwise every unrelated change breaks your test.
]

#card[16 · Testing that verifiers reject IR][
  ```mlir
  // RUN: tutorial-opt --split-input-file --verify-diagnostics %s

  func.func @two_block_args(%l: !list.list<i32>) {
    // expected-error @below {{expects the body to have exactly one argument}}
    %m = list.map %l -> !list.list<i32> with {
    ^bb0(%a: i32, %b: i32):
      list.yield %a : i32
    }
    return
  }
  ```
  With `--verify-diagnostics` the run passes #emph[iff] the emitted diagnostics
  match the markers exactly: an unexpected diagnostic fails, and so does an
  `expected-*` that never fires. No `FileCheck` in the pipeline. Put one bad case
  per `// -----` section -- the first error usually stops the rest of it.
  #tbl(columns: (auto, 1fr),
    [`expected-error`], [also `expected-warning`, `expected-note`,
      `expected-remark`],
    [`{{...}}`], [a #key[substring] of the message -- keep it short and stable],
    [`@below` / `@above`\ `@+2` / `@-1`], [where the diagnostic is: next /
      previous line, or a relative offset. No marker = same line;
      `@unknown` = no location.],
  )
]
