import XCTest
@testable import SkillDock

final class DesignContractTests: XCTestCase {
    func testSidebarWidthIs200() {
        XCTAssertEqual(UIStyleConstants.sidebarWidth, 200)
    }

    func testSkillCardMinWidthIs320() {
        XCTAssertEqual(UIStyleConstants.skillCardMinWidth, 320)
    }

    func testSkillCardCornerRadiusIs14() {
        XCTAssertEqual(UIStyleConstants.skillCardCornerRadius, 14)
    }

    func testPrimaryColorIs4C6EF5() {
        XCTAssertEqual(UIStyleConstants.primaryColorHex.lowercased(), "#4c6ef5")
    }
}
