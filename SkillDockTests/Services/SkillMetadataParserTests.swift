import XCTest
@testable import SkillDock

final class SkillMetadataParserTests: XCTestCase {
    func testParseReadsNameAndDescriptionFromFrontmatter() {
        let parser = SkillMetadataParser()
        let content = """
        ---
        name: brainstorming
        description: "Explore ideas before coding"
        ---
        body
        """

        let metadata = parser.parse(content: content, fallbackName: "fallback")

        XCTAssertEqual(metadata.name, "brainstorming")
        XCTAssertEqual(metadata.description, "Explore ideas before coding")
    }

    func testParseUsesFallbackAndDefaultDescription() {
        let parser = SkillMetadataParser()
        let content = """
        ---
        description:
        ---
        body
        """

        let metadata = parser.parse(content: content, fallbackName: "design-exploration")

        XCTAssertEqual(metadata.name, "design-exploration")
        XCTAssertEqual(metadata.description, "暂无描述")
    }

    func testParseWithoutFrontmatterReturnsFallbackValues() {
        let parser = SkillMetadataParser()
        let content = "plain markdown without frontmatter"

        let metadata = parser.parse(content: content, fallbackName: "project-map-builder")

        XCTAssertEqual(metadata.name, "project-map-builder")
        XCTAssertEqual(metadata.description, "暂无描述")
    }
}
