import XCTest
@testable import CLI

final class CLITests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CLI().text, "Hello, World!")
    }
}
