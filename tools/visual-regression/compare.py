#!/usr/bin/env python3
import argparse
import json
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


@dataclass
class CompareResult:
    file: str
    status: str
    changed_pixels: int
    total_pixels: int
    diff_file: str | None


def load_masks(mask_dir: Path) -> dict[str, list[dict[str, int]]]:
    masks: dict[str, list[dict[str, int]]] = {}
    if not mask_dir.exists():
        return masks
    for json_file in mask_dir.glob("*.json"):
        data = json.loads(json_file.read_text(encoding="utf-8"))
        masks[json_file.stem] = data.get("ignore", [])
    return masks


def apply_mask(img: Image.Image, regions: list[dict[str, int]]) -> None:
    if not regions:
        return
    drawer = ImageDraw.Draw(img)
    for region in regions:
        x = int(region.get("x", 0))
        y = int(region.get("y", 0))
        w = int(region.get("width", 0))
        h = int(region.get("height", 0))
        drawer.rectangle((x, y, x + w, y + h), fill=(0, 0, 0, 0))


def changed_pixel_count(diff_img: Image.Image) -> int:
    rgba = diff_img.convert("RGBA")
    return sum(1 for px in rgba.getdata() if px[:3] != (0, 0, 0))


def compare_images(
    baseline_path: Path,
    snapshot_path: Path,
    diff_path: Path,
    masks: dict[str, list[dict[str, int]]],
    max_diff_ratio: float,
) -> CompareResult:
    baseline = Image.open(baseline_path).convert("RGBA")
    snapshot = Image.open(snapshot_path).convert("RGBA")
    if baseline.size != snapshot.size:
        return CompareResult(
            file=str(snapshot_path),
            status=f"size-mismatch {baseline.size} != {snapshot.size}",
            changed_pixels=-1,
            total_pixels=baseline.size[0] * baseline.size[1],
            diff_file=None,
        )

    relative_stem = snapshot_path.stem
    regions = masks.get("global", []) + masks.get(relative_stem, [])
    baseline_masked = baseline.copy()
    snapshot_masked = snapshot.copy()
    apply_mask(baseline_masked, regions)
    apply_mask(snapshot_masked, regions)

    diff = ImageChops.difference(baseline_masked, snapshot_masked)
    changed = changed_pixel_count(diff)
    total = baseline.size[0] * baseline.size[1]
    if changed <= int(total * max_diff_ratio):
        return CompareResult(
            file=str(snapshot_path),
            status="same",
            changed_pixels=changed,
            total_pixels=total,
            diff_file=None,
        )
    if changed > 0:
        diff_path.parent.mkdir(parents=True, exist_ok=True)
        diff.save(diff_path)
        return CompareResult(
            file=str(snapshot_path),
            status="different",
            changed_pixels=changed,
            total_pixels=total,
            diff_file=str(diff_path),
        )
    return CompareResult(
        file=str(snapshot_path),
        status="same",
        changed_pixels=0,
        total_pixels=total,
        diff_file=None,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--update-baseline", action="store_true")
    parser.add_argument("--max-diff-ratio", type=float, default=0.003)
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    baseline_root = root / "tests-artifacts" / "baselines" / "v1.2"
    snapshot_root = root / "tests-artifacts" / "snapshots"
    diff_root = root / "tests-artifacts" / "diff"
    mask_root = root / "tools" / "visual-regression" / "masks"

    if not snapshot_root.exists():
        print(f"快照目录不存在: {snapshot_root}")
        return 1

    snapshot_files = sorted(snapshot_root.rglob("*.png"))
    if not snapshot_files:
        print(f"快照目录没有 PNG 文件: {snapshot_root}")
        return 1

    masks = load_masks(mask_root)
    if args.update_baseline:
        for snapshot in snapshot_files:
            relative = snapshot.relative_to(snapshot_root)
            target = baseline_root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(snapshot, target)
        print(f"基线已更新，共 {len(snapshot_files)} 张")
        return 0

    if diff_root.exists():
        shutil.rmtree(diff_root)
    diff_root.mkdir(parents=True, exist_ok=True)

    results: list[CompareResult] = []
    for snapshot in snapshot_files:
        relative = snapshot.relative_to(snapshot_root)
        baseline = baseline_root / relative
        if not baseline.exists():
            results.append(
                CompareResult(
                    file=str(snapshot),
                    status="baseline-missing",
                    changed_pixels=-1,
                    total_pixels=0,
                    diff_file=None,
                )
            )
            continue
        diff_file = diff_root / relative.parent / f"{relative.stem}__diff.png"
        results.append(compare_images(baseline, snapshot, diff_file, masks, args.max_diff_ratio))

    failed = [r for r in results if r.status != "same"]
    if failed:
        print("视觉回归失败：")
        for item in failed:
            if item.status == "different":
                ratio = item.changed_pixels / item.total_pixels if item.total_pixels else 0
                print(f"- {item.file} changed={item.changed_pixels} ratio={ratio:.6f} diff={item.diff_file}")
            else:
                print(f"- {item.file} status={item.status}")
        return 1

    print(f"视觉回归通过，共 {len(results)} 张")
    return 0


if __name__ == "__main__":
    sys.exit(main())
