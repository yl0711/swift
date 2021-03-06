// RUN: %target-build-swift -sanitize=thread %s -o %t_binary
// RUN: TSAN_OPTIONS=ignore_interceptors_accesses=1:halt_on_error=1 %t_binary
// REQUIRES: executable_test
// REQUIRES: CPU=x86_64
// REQUIRES: OS=macosx
// REQUIRES: tsan_runtime

// Check taht TSan does not report spurious races in witness table lookup.

func consume(_ x: Any) {}
protocol Q {
  associatedtype QA
  func deduceQA() -> QA
  static func foo()
}
extension Q {
  func deduceQA() -> Int { return 0 }
}
protocol Q2 {
  associatedtype Q2A
  func deduceQ2A() -> Q2A
}
extension Q2 {
  func deduceQ2A() -> Int { return 0 }
}
protocol P {
  associatedtype E : Q, Q2
}
struct B<T : Q> : Q, Q2 {
  static func foo() { consume(self.dynamicType) }
}
struct A<T : Q where T : Q2> : P {
  typealias E = B<T>
  let value: T
}
func foo<T : P>(_ t: T) {
  T.E.foo()
}
struct EasyType : Q, Q2 {
    static func foo() { consume(self.dynamicType) }
}
extension Int : Q, Q2 {
  static func foo() { consume(self.dynamicType) }
}

// Execute concurrently.
import StdlibUnittest
var RaceTestSuite = TestSuite("t")

RaceTestSuite.test("test_metadata") {
  runRaceTest(trials: 1) {
    foo(A<Int>(value: 5))
    foo(A<Int>(value: Int()))
    foo(A<EasyType>(value: EasyType()))
  }
}

runAllTests()
