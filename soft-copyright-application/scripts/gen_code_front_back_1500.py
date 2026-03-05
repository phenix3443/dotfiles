#!/usr/bin/env python3
"""
通用版：根据配置生成《前1500行》《后1500行》源码文件（仅非空行）。
用法：python gen_code_front_back_1500.py --config <config.json>
或：  python gen_code_front_back_1500.py --source <项目根> --output <输出目录> --file-order <逗号分隔路径> --back-end-file <文件> --back-end-line <行号>

config.json 示例：
{
  "source_dir": "/path/to/project",
  "output_dir": "/path/to/output",
  "file_order": ["src/__init__.py", "src/client.py", "tests/test_a.py"],
  "back_end_at": {"file": "src/client.py", "line": 478}
}
"""
import argparse
import json
import os


def load_config(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def collect_non_empty_lines(source_dir, file_order):
    lines = []
    for rel in file_order:
        path = os.path.join(source_dir, rel)
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                s = line.rstrip("\n\r")
                if s.strip():
                    lines.append(s)
    return lines


def collect_back_lines(source_dir, file_order, back_end_file, back_end_line):
    back_file_order = [r for r in file_order if r != back_end_file] + [back_end_file]
    lines = []
    for rel in back_file_order:
        path = os.path.join(source_dir, rel)
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            file_lines = f.readlines()
        if rel == back_end_file:
            for line in file_lines[:back_end_line]:
                s = line.rstrip("\n\r")
                if s.strip():
                    lines.append(s)
        else:
            for line in file_lines:
                s = line.rstrip("\n\r")
                if s.strip():
                    lines.append(s)
    return lines


def main():
    parser = argparse.ArgumentParser(
        description="Generate 代码_前1500行.txt and 代码_后1500行.txt from project source (non-empty lines only)."
    )
    parser.add_argument("--config", help="Path to JSON config (source_dir, output_dir, file_order, back_end_at)")
    parser.add_argument("--source", help="Project root (overrides config)")
    parser.add_argument("--output", help="Output directory (overrides config)")
    parser.add_argument("--file-order", help="Comma-separated relative paths (overrides config)")
    parser.add_argument("--back-end-file", help="File path for back end (overrides config)")
    parser.add_argument("--back-end-line", type=int, help="Line number for back end (overrides config)")
    args = parser.parse_args()

    if args.config:
        cfg = load_config(args.config)
        source_dir = os.path.normpath(args.source or cfg["source_dir"])
        out_dir = os.path.normpath(args.output or cfg["output_dir"])
        file_order = args.file_order.split(",") if args.file_order else cfg["file_order"]
        be = cfg.get("back_end_at", {})
        back_end_file = args.back_end_file or be.get("file")
        back_end_line = args.back_end_line if args.back_end_line is not None else be.get("line")
    else:
        source_dir = os.path.normpath(args.source)
        out_dir = os.path.normpath(args.output)
        file_order = [s.strip() for s in args.file_order.split(",") if s.strip()]
        back_end_file = args.back_end_file
        back_end_line = args.back_end_line
    if not source_dir or not out_dir or not file_order or not back_end_file or back_end_line is None:
        raise SystemExit("Missing required: --config, or (--source, --output, --file-order, --back-end-file, --back-end-line)")

    if not os.path.isdir(source_dir):
        raise SystemExit(f"Source directory not found: {source_dir}")

    lines = collect_non_empty_lines(source_dir, file_order)
    total = len(lines)
    if total < 1500:
        raise SystemExit(f"Not enough non-empty lines: {total} < 1500")

    back_lines = collect_back_lines(source_dir, file_order, back_end_file, back_end_line)
    back_total = len(back_lines)
    if back_total < 1500:
        raise SystemExit(
            f"Not enough lines for back file (ends at {back_end_file}:{back_end_line}): {back_total} < 1500"
        )

    os.makedirs(out_dir, exist_ok=True)
    front_path = os.path.join(out_dir, "代码_前1500行.txt")
    with open(front_path, "w", encoding="utf-8") as fp:
        fp.write("\n".join(lines[:1500]))
        fp.write("\n")
    print(f"Wrote {front_path} (lines 1-1500)")

    back_path = os.path.join(out_dir, "代码_后1500行.txt")
    with open(back_path, "w", encoding="utf-8") as fp:
        fp.write("\n".join(back_lines[-1500:]))
        fp.write("\n")
    print(f"Wrote {back_path} (last 1500 lines, ends at {back_end_file}:{back_end_line})")
    print(f"Non-empty lines: total {total}, back segment {back_total}")


if __name__ == "__main__":
    main()
