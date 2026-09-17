#!/usr/bin/env python3
"""Читает mods.csv и для каждого установленного мода выводит BEGIN-строки из .tp2."""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

DESIGNATED_RE = re.compile(r"\bDESIGNATED\s+(\S+)", re.IGNORECASE)
AT_REF_RE = re.compile(r"@(\d+)")
# Старт записи TRA: @123 = ~ или " или %
TRA_START_RE = re.compile(r"@(\d+)\s*=\s*([~\"%])")

LANG_DIR_NAMES = {"langs", "lang", "language", "languages", "translations", "tra","english"}
ENGLISH_DIR_NAMES = {"english", "en_us","./"}

SCRIPT_DIR = Path(__file__).resolve().parent
CSV_PATH = SCRIPT_DIR / "mods.csv"

# Столбцы в CSV считаются с 1, как в install_mods.py
COL_NAME = 1
COL_FOLDER = 9


def cell(row: list[str], col_1based: int) -> str:
    idx = col_1based - 1
    if idx >= len(row):
        return ""
    return (row[idx] or "").strip()


def load_mods(csv_path: Path) -> list[dict]:
    with csv_path.open(encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.reader(handle))

    mods: list[dict] = []
    for index, row in enumerate(rows):
        if index == 0:
            continue  # заголовок
        if not row or not any(item.strip() for item in row):
            continue
        name = cell(row, COL_NAME)
        folder = cell(row, COL_FOLDER)
        if not name:
            continue
        # Разделы CSV («Общие», «NPC» и т.п.) — без папки и без URL
        if not folder and not cell(row, 10):
            continue
        mods.append({"name": name, "folder": folder, "line": index + 1})
    return mods


def find_tp2(mod_folder: Path) -> list[Path]:
    """*.tp2 непосредственно в папке мода (не рекурсивно)."""
    if not mod_folder.is_dir():
        return []
    return sorted(
        path
        for path in mod_folder.iterdir()
        if path.is_file() and path.suffix.lower() == ".tp2"
    )


def find_english_tra_files(mod_folder: Path) -> list[Path]:
    """Ищет все *.tra в {langs|lang|language|languages|translations|tra}/{english|en_us}/."""
    found: list[Path] = []
    if not mod_folder.is_dir():
        return found
    for child in sorted(mod_folder.iterdir(), key=lambda p: p.name.lower()):
        if not child.is_dir() or child.name.lower() not in LANG_DIR_NAMES:
            continue
        for locale in sorted(child.iterdir(), key=lambda p: p.name.lower()):
            if not locale.is_dir() or locale.name.lower() not in ENGLISH_DIR_NAMES:
                continue
            found.extend(
                sorted(
                    (
                        path
                        for path in locale.iterdir()
                        if path.is_file() and path.suffix.lower() == ".tra"
                    ),
                    key=lambda p: p.name.lower(),
                )
            )
    return found


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def parse_tra(text: str) -> dict[int, str]:
    """Разбирает WeiDU .tra: @id = ~text~ / \"text\" / %text% (в т.ч. многострочные)."""
    result: dict[int, str] = {}
    pos = 0
    while True:
        match = TRA_START_RE.search(text, pos)
        if not match:
            break
        tra_id = int(match.group(1))
        delim = match.group(2)
        start = match.end()
        end = text.find(delim, start)
        if end < 0:
            value = text[start:]
            pos = len(text)
        else:
            value = text[start:end]
            pos = end + 1
        # Для вывода в одну строку схлопываем переносы
        value = re.sub(r"\s+", " ", value).strip()
        result[tra_id] = value
    return result


def load_tra_map(mod_folder: Path) -> dict[int, str]:
    """Собирает @id -> текст из всех .tra в english/en_us."""
    tra_map: dict[int, str] = {}
    for path in find_english_tra_files(mod_folder):
        tra_map.update(parse_tra(read_text(path)))
    return tra_map


def next_significant_line(lines: list[str], start: int, limit: int = 5) -> str | None:
    """Следующая непустая строка без //-комментария."""
    end = min(start + limit, len(lines))
    for j in range(start, end):
        nxt = lines[j].strip()
        if not nxt or nxt.startswith("//"):
            continue
        return nxt
    return None


def is_component_begin(lines: list[str], index: int) -> bool:
    """
    Компонент мода: BEGIN с именем на этой или следующей строке.
    Голый BEGIN у ACTION_FOR_EACH / DEFINE_* / ACTION_IF THEN — пропускаем.
    """
    line = lines[index]
    if not line.startswith("BEGIN"):
        return False
    rest = line[5:].lstrip()
    if rest:
        return True
    nxt = next_significant_line(lines, index + 1)
    if nxt is None:
        return False
    return nxt.startswith("@") or nxt.startswith("~") or nxt.startswith('"')


def component_header(lines: list[str], index: int) -> str:
    """Текст заголовка BEGIN (для Sandrah: BEGIN + @id со следующей строки)."""
    line = lines[index]
    rest = line[5:].lstrip()
    if rest:
        return line
    nxt = next_significant_line(lines, index + 1)
    if nxt is None:
        return line
    return f"BEGIN {nxt}"


def begin_components(tp2_path: Path) -> list[tuple[str, str | None]]:
    """Компоненты BEGIN и DESIGNATED из блока до следующего компонента BEGIN."""
    lines = read_text(tp2_path).splitlines()
    begin_indices = [i for i in range(len(lines)) if is_component_begin(lines, i)]
    result: list[tuple[str, str | None]] = []
    for idx, start in enumerate(begin_indices):
        end = begin_indices[idx + 1] if idx + 1 < len(begin_indices) else len(lines)
        block = "\n".join(lines[start:end])
        match = DESIGNATED_RE.search(block)
        designated = match.group(1) if match else None
        result.append((component_header(lines, start), designated))
    return result


def extract_component_name(header: str) -> str:
    """Имя компонента сразу после BEGIN (@id, ~текст~, \"текст\" или токен)."""
    rest = header[5:].lstrip() if header.startswith("BEGIN") else header.lstrip()
    if not rest:
        return ""

    at = re.match(r"@(\d+)", rest)
    if at:
        return f"@{at.group(1)}"

    if rest.startswith("~"):
        end = rest.find("~", 1)
        return rest[1:end] if end > 0 else rest[1:]

    if rest.startswith('"'):
        end = rest.find('"', 1)
        return rest[1:end] if end > 0 else rest[1:]

    # Обрезать служебные ключевые слова WeiDU
    cut = re.split(
        r"\s+(?:DESIGNATED|GROUP|SUBCOMPONENT|LABEL|REQUIRE_|FORBID_|DEPRECATED|/\*)",
        rest,
        maxsplit=1,
        flags=re.IGNORECASE,
    )[0]
    return cut.strip()


def resolve_name(name: str, tra_map: dict[int, str]) -> str:
    """Подставляет текст TRA для @id; иначе возвращает имя как есть."""
    at = re.fullmatch(r"@(\d+)", name.strip())
    if at:
        tra_id = int(at.group(1))
        if tra_id in tra_map:
            return tra_map[tra_id]
    return substitute_refs(name, tra_map)


def substitute_refs(line: str, tra_map: dict[int, str]) -> str:
    """Подставляет текст из TRA вместо @NNNN."""

    def repl(match: re.Match[str]) -> str:
        tra_id = int(match.group(1))
        if tra_id in tra_map:
            return tra_map[tra_id]
        return match.group(0)

    return AT_REF_RE.sub(repl, line)


def format_begin_line(name: str, designated: str | None) -> str:
    """Только: BEGIN <имя> (DESIGNATED N)."""
    if designated is None:
        return f"BEGIN {name}"
    return f"BEGIN {name} (DESIGNATED {designated})"


def process_mod(mod: dict) -> None:
    name = mod["name"]
    folder = mod["folder"]

    print(f"\n=== {name} ===")

    if not folder:
        print("не установлен (в CSV нет имени папки)")
        return

    mod_dir = SCRIPT_DIR / folder
    if not mod_dir.is_dir():
        print("не установлен")
        return

    tp2_files = find_tp2(mod_dir)
    if not tp2_files:
        print(f"установлен, но .tp2 не найден в папке {folder}")
        return
    if len(tp2_files) > 1:
        names = ", ".join(p.name for p in tp2_files)
        print(f"предупреждение: в папке {folder} найдено несколько .tp2 ({names}) — пропуск")
        return

    tp2 = tp2_files[0]
    print(f"файл: {folder}/{tp2.name}")

    tra_files = find_english_tra_files(mod_dir)
    if not tra_files:
        print(
            "предупреждение: .tra в lang(s)/language(s)/translations/tra/"
            "{english|en_us} не найдены — @ссылки без подстановки"
        )
        tra_map: dict[int, str] = {}
    else:
        tra_map = load_tra_map(mod_dir)

    components = begin_components(tp2)
    if not components:
        print("(строк BEGIN нет)")
        return
    for line, designated in components:
        name = resolve_name(extract_component_name(line), tra_map)
        print(format_begin_line(name, designated))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Для каждого мода из mods.csv: статус установки и BEGIN-строки из .tp2."
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=CSV_PATH,
        help=f"Путь к mods.csv (по умолчанию: {CSV_PATH.name})",
    )
    args = parser.parse_args()

    if not args.csv.is_file():
        print(f"Файл не найден: {args.csv}", file=sys.stderr)
        return 1

    mods = load_mods(args.csv)
    if not mods:
        print("В CSV нет модов", file=sys.stderr)
        return 1

    for mod in mods:
        process_mod(mod)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
