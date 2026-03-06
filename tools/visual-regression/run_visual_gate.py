#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path


def run(command: list[str], cwd: Path, env: dict[str, str] | None = None) -> None:
    completed = subprocess.run(
        command,
        cwd=str(cwd),
        check=False,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    output = completed.stdout or ""
    if output:
        print(output, end="")
    if completed.returncode != 0:
        raise subprocess.CalledProcessError(
            completed.returncode,
            command,
            output=output,
        )


def run_without_raise(command: list[str], cwd: Path) -> bool:
    completed = subprocess.run(command, cwd=str(cwd), check=False)
    return completed.returncode == 0


def has_png_files(path: Path) -> bool:
    return any(path.rglob("*.png"))


def cleanup_test_processes() -> None:
    subprocess.run(["pkill", "-f", "SkillDockUITests-Runner"], check=False)
    subprocess.run(["pkill", "-9", "-f", "SkillDockUITests-Runner"], check=False)
    subprocess.run(["pkill", "-f", "com.mac.SkillDock.xctrunner"], check=False)
    subprocess.run(["pkill", "-9", "-f", "com.mac.SkillDock.xctrunner"], check=False)
    subprocess.run(["pkill", "-f", "com.mac.SkillDock"], check=False)
    subprocess.run(["pkill", "-9", "-f", "com.mac.SkillDock"], check=False)
    subprocess.run(["pkill", "-f", "xctest"], check=False)
    subprocess.run(["pkill", "-9", "-f", "xctest"], check=False)
    subprocess.run(["pkill", "-f", "xcodebuild test"], check=False)


def is_bootstrap_failure(error: subprocess.CalledProcessError) -> bool:
    output = str(error.output or "")
    return "before establishing connection" in output or "never finished bootstrapping" in output


def is_retryable_capture_error(error: subprocess.CalledProcessError) -> bool:
    return error.returncode == 65 and is_bootstrap_failure(error)


def retry_backoff_seconds(index: int, base: float, max_seconds: float) -> float:
    return min(max_seconds, base ** (index + 1))


def collect_from_xctest_tmp(snapshot_dir: Path) -> None:
    xctest_tmp = Path.home() / "Library/Containers/com.mac.SkillDock.xctrunner/Data/tmp/skilldock-visual-snapshots"
    if not xctest_tmp.exists():
        return
    if snapshot_dir.exists():
        shutil.rmtree(snapshot_dir)
    shutil.copytree(xctest_tmp, snapshot_dir)


def capture_visual_snapshots(
    root: Path,
    result_bundle_path: Path,
    snapshot_dir: Path,
    use_test_without_building: bool = False,
) -> None:
    cleanup_test_processes()
    time.sleep(0.4)
    result_bundle_path.parent.mkdir(parents=True, exist_ok=True)
    if result_bundle_path.exists():
        shutil.rmtree(result_bundle_path)
    if snapshot_dir.exists():
        shutil.rmtree(snapshot_dir)
    snapshot_dir.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["VISUAL_OUTPUT_DIR"] = str(snapshot_dir)
    test_command = "test-without-building" if use_test_without_building else "test"
    run(
        [
            "xcodebuild",
            test_command,
            "-project",
            "SkillDock.xcodeproj",
            "-scheme",
            "SkillDock",
            "-maximum-parallel-testing-workers",
            "1",
            "-destination",
            "platform=macOS,arch=x86_64",
            "-resultBundlePath",
            str(result_bundle_path),
            "-only-testing:SkillDockUITests/VisualSnapshotCaptureUITests/testCaptureV13StateSnapshots",
        ],
        cwd=root,
        env=env,
    )
    if not has_png_files(snapshot_dir):
        collect_from_xctest_tmp(snapshot_dir)


def prepare_test_runner(root: Path) -> None:
    run(
        [
            "xcodebuild",
            "build-for-testing",
            "-project",
            "SkillDock.xcodeproj",
            "-scheme",
            "SkillDock",
            "-maximum-parallel-testing-workers",
            "1",
            "-destination",
            "platform=macOS,arch=x86_64",
        ],
        cwd=root,
    )


def capture_with_prepared_runner(
    root: Path,
    result_bundle_path: Path,
    snapshot_dir: Path,
    retry_backoff_base: float,
    retry_backoff_max_seconds: float,
) -> None:
    for recovery_index in range(3):
        try:
            capture_visual_snapshots(
                root,
                result_bundle_path,
                snapshot_dir,
                use_test_without_building=True,
            )
            return
        except subprocess.CalledProcessError as recovery_error:
            if not is_retryable_capture_error(recovery_error) or recovery_index == 2:
                raise
            wait_seconds = retry_backoff_seconds(
                recovery_index,
                retry_backoff_base,
                retry_backoff_max_seconds,
            )
            print(f"预热后采集失败，准备重试 ({recovery_index + 1}/2)，等待 {wait_seconds:.1f}s")
            cleanup_test_processes()
            time.sleep(wait_seconds)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-capture", action="store_true")
    parser.add_argument("--result-bundle-path", default="tests-artifacts/xcresult/visual.xcresult")
    parser.add_argument("--snapshot-dir", default="tests-artifacts/snapshots")
    parser.add_argument("--update-baseline", action="store_true")
    parser.add_argument("--max-diff-ratio", type=float, default=0.003)
    parser.add_argument("--capture-retries", type=int, default=8)
    parser.add_argument("--retry-backoff-base", type=float, default=1.8)
    parser.add_argument("--retry-backoff-max-seconds", type=float, default=8.0)
    parser.add_argument("--startup-retry-cycles", type=int, default=5)
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    snapshot_dir = root / args.snapshot_dir
    result_bundle_path = root / args.result_bundle_path

    compare_command = ["python3", "tools/visual-regression/compare.py"]
    compare_command.extend(["--max-diff-ratio", str(args.max_diff_ratio)])
    if args.update_baseline:
        compare_command.append("--update-baseline")
    if args.skip_capture:
        run(compare_command, cwd=root)
        return 0

    attempts = max(1, args.capture_retries)
    last_capture_error: subprocess.CalledProcessError | None = None
    startup_retry_cycles = max(1, args.startup_retry_cycles)
    prepare_cycles = 0
    for index in range(attempts):
        try:
            capture_visual_snapshots(root, result_bundle_path, snapshot_dir)
        except subprocess.CalledProcessError as error:
            last_capture_error = error
            if is_retryable_capture_error(error) and index < attempts - 1:
                wait_seconds = retry_backoff_seconds(index, args.retry_backoff_base, args.retry_backoff_max_seconds)
                print(f"视觉采集失败，准备重试 ({index + 1}/{attempts - 1})，等待 {wait_seconds:.1f}s")
                cleanup_test_processes()
                time.sleep(wait_seconds)
                continue
            if is_retryable_capture_error(error) and prepare_cycles < startup_retry_cycles:
                print("视觉采集连续失败，执行 build-for-testing 预热后再试一次")
                cleanup_test_processes()
                prepare_test_runner(root)
                prepare_cycles += 1
                wait_seconds = args.retry_backoff_max_seconds
                time.sleep(wait_seconds)
                capture_with_prepared_runner(
                    root,
                    result_bundle_path,
                    snapshot_dir,
                    args.retry_backoff_base,
                    args.retry_backoff_max_seconds,
                )
            else:
                raise
        if run_without_raise(compare_command, cwd=root):
            return 0
        if index < attempts - 1:
            wait_seconds = retry_backoff_seconds(index, args.retry_backoff_base, args.retry_backoff_max_seconds)
            print(f"视觉回归未通过，准备重试 ({index + 1}/{attempts - 1})，等待 {wait_seconds:.1f}s")
            time.sleep(wait_seconds)
    if last_capture_error is not None and not snapshot_dir.exists():
        raise last_capture_error
    run(compare_command, cwd=root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
