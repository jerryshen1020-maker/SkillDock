#!/usr/bin/env python3
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TRACEABILITY_FILE = ROOT / "tools" / "testing" / "prd_traceability.yml"
ID_PATTERN = re.compile(r'^\s*-\s+id:\s+"([^"]+)"\s*$')
TEST_PATTERN = re.compile(r'^\s*test:\s+"([^"]+)"\s*$')
FUNC_PATTERN_TEMPLATE = r"\bfunc\s+{}\b"


def parse_entries(content: str):
    entries = []
    pending_id = None
    for line in content.splitlines():
        id_match = ID_PATTERN.match(line)
        if id_match:
            pending_id = id_match.group(1)
            continue
        test_match = TEST_PATTERN.match(line)
        if test_match and pending_id:
            entries.append((pending_id, test_match.group(1)))
            pending_id = None
    return entries


def validate_entry(case_id: str, test_ref: str):
    if "::" not in test_ref:
        return f"{case_id}: test 引用格式错误 {test_ref}"
    file_part, func_name = test_ref.split("::", 1)
    target_file = ROOT / file_part
    if not target_file.exists():
        return f"{case_id}: 文件不存在 {file_part}"
    content = target_file.read_text(encoding="utf-8")
    func_pattern = re.compile(FUNC_PATTERN_TEMPLATE.format(re.escape(func_name)))
    if func_pattern.search(content) is None:
        return f"{case_id}: 方法不存在 {func_name} in {file_part}"
    return None


def main():
    if not TRACEABILITY_FILE.exists():
        print(f"未找到映射文件: {TRACEABILITY_FILE}")
        return 1
    entries = parse_entries(TRACEABILITY_FILE.read_text(encoding="utf-8"))
    if not entries:
        print("未解析到任何 PRD 映射条目")
        return 1
    errors = []
    seen_ids = set()
    for case_id, test_ref in entries:
        if case_id in seen_ids:
            errors.append(f"{case_id}: 重复 ID")
            continue
        seen_ids.add(case_id)
        error = validate_entry(case_id, test_ref)
        if error:
            errors.append(error)
    if errors:
        print("PRD 映射校验失败：")
        for item in errors:
            print(f"- {item}")
        return 1
    print(f"PRD 映射校验通过，共 {len(entries)} 条")
    return 0


if __name__ == "__main__":
    sys.exit(main())
