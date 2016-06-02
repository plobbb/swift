; This is not really a Swift source file: -*- Text -*-
; TODO: se-0081 - apply tail style where clause to swift-demangle, edit Inputs/manglings.txt

%t.input: "A ---> B" ==> "A"
RUN: sed -ne '/--->/s/ *--->.*$//p' < %S/Inputs/manglings.txt > %t.input

%t.check: "A ---> B" ==> "B"
RUN: sed -ne '/--->/s/^.*---> *//p' < %S/Inputs/manglings.txt > %t.check

RUN: swift-demangle < %t.input > %t.output
RUN: diff %t.check %t.output

; RUN: swift-demangle __TtSi | FileCheck %s -check-prefix=DOUBLE
; DOUBLE: _TtSi ---> Swift.Int

