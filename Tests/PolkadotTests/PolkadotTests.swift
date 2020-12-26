import XCTest

#if !COCOAPODS
@testable import Polkadot
#else
@testable import Substrate
#endif

final class PolkadotTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Polkadot().text, "Hello, World!")
    }
}
