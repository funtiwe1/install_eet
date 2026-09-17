#!/usr/bin/env python3
"""Скачивает, распаковывает и запускает установщики модов из mods.csv."""

from __future__ import annotations

import argparse
import configparser
import csv
import logging
import shutil
import ssl
import subprocess
import sys
import tarfile
import zipfile
import os, stat
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import unquote, urlparse
from urllib.request import Request, urlopen

try:
    import certifi
except ImportError:
    certifi = None

SCRIPT_DIR = Path(__file__).resolve().parent
BG2_DISTR = None
INIPATH = SCRIPT_DIR / "funtik.ini"

EX_MOD_DIR = SCRIPT_DIR / "funtik"
ARCH_DIR = SCRIPT_DIR / "arch"
CSV_PATH = SCRIPT_DIR / "mods.csv"
LOG_PATH = SCRIPT_DIR / "install_mods.log"

# Столбцы в CSV считаются с 1, как в таблице.
COL_NAME = 1
COL_ORDER = 8
COL_FOLDER = 9
COL_URL = 10
COL_COMPONENTS = 11

BG2_FOLDER = {"characters", "data", "inline", "inlined-macro", "lang", "lua", "Manuals", "movies", "music","override", "portraits", "scripts","weidu_external","Worldmap"}
FILE_EXTENSIONS = {".zip", ".exe", ".7z", ".rar", ".tar", ".gz", ".tgz", ".bz2", ".xz"}
ARCHIVE_EXTENSIONS = {".zip", ".7z", ".rar", ".tar", ".gz", ".tgz", ".bz2", ".xz"}
SKIP_EXE_NAMES = {"unins000.exe", "uninstall.exe"}

log = logging.getLogger("install_mods")


def setup_logging() -> None:
    log.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")

    file_handler = logging.FileHandler(LOG_PATH, encoding="utf-8")
    file_handler.setFormatter(formatter)
    log.addHandler(file_handler)

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    log.addHandler(console_handler)


def cell(row: list[str], column_1based: int) -> str:
    index = column_1based - 1
    if index >= len(row):
        return ""
    return row[index].strip()


def set_cell(row: list[str], column_1based: int, value: str) -> None:
    index = column_1based - 1
    while len(row) <= index:
        row.append("")
    row[index] = value


def parse_order(value: str) -> tuple[int, int]:
    """Ключ сортировки: сначала строки с числом (по возрастанию), пустые — в конец."""
    if not value:
        return (1, 0)
    try:
        return (0, int(value))
    except ValueError:
        return (1, 0)


def load_csv(csv_path: Path) -> tuple[list[list[str]], list[dict]]:
    with csv_path.open(encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.reader(handle))

    mods = []
    for index, row in enumerate(rows):
        if not row or not any(item.strip() for item in row):
            continue
        mods.append(
            {
                "row_index": index,
                "line": index + 1,
                "name": cell(row, COL_NAME) or f"строка {index + 1}",
                "order": cell(row, COL_ORDER),
                "folder": cell(row, COL_FOLDER),
                "url": cell(row, COL_URL),
                "components": cell(row, COL_COMPONENTS),
            }
        )

    mods.sort(key=lambda item: (parse_order(item["order"]), item["line"]))
    return rows, mods


def save_csv(csv_path: Path, rows: list[list[str]]) -> None:
    with csv_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerows(rows)


def update_mod_folder_in_csv(
    rows: list[list[str]], mod: dict, folder_name: str, csv_path: Path
) -> None:
    row = rows[mod["row_index"]]
    set_cell(row, COL_FOLDER, folder_name)
    mod["folder"] = folder_name
    save_csv(csv_path, rows)
    log.info("В CSV (столбец 9) записано имя папки мода: %s", folder_name)


def filename_from_url(url: str) -> str:
    path = unquote(urlparse(url).path)
    name = Path(path).name
    return name or "download.bin"


def url_file_extension(url: str) -> str:
    name = filename_from_url(url).lower()
    if name.endswith(".tar.gz"):
        return ".tar.gz"
    return Path(name).suffix.lower()


def is_file_url(url: str) -> bool:
    if not url.lower().startswith(("http://", "https://")):
        return False
    return url_file_extension(url) in FILE_EXTENSIONS


def sanitize_mod_filename(name: str) -> str:
    """Имя мода, безопасное для имени файла Windows."""
    bad = '<>:"/\\|?*'
    cleaned = "".join("_" if (c in bad or ord(c) < 32) else c for c in name)
    cleaned = cleaned.strip(" .")
    return cleaned or "mod"


def parse_github_repo(url: str) -> tuple[str, str] | None:
    """Возвращает (owner, repo) для ссылки на GitHub-репозиторий."""
    if not url.lower().startswith(("http://", "https://")):
        return None
    if is_file_url(url):
        return None

    parsed = urlparse(url)
    host = parsed.netloc.lower()
    if host not in {"github.com", "www.github.com"}:
        return None

    parts = [part for part in parsed.path.strip("/").split("/") if part]
    if len(parts) < 2:
        return None

    owner, repo = parts[0], parts[1]
    if repo.endswith(".git"):
        repo = repo[:-4]

    # Страницы releases/issues и т.п. без прямого файла — всё равно корень репо
    return owner, repo


def is_repo_url(url: str) -> bool:
    return parse_github_repo(url) is not None


def github_branch_zip_url(owner: str, repo: str, branch: str) -> str:
    return f"https://github.com/{owner}/{repo}/archive/refs/heads/{branch}.zip"


def resolve_download(mod_name: str, url: str, folder_name: str = "") -> dict | None:
    """
    Определяет, что скачивать по столбцу 10.
    Возвращает dict: download_url, filename, kind ('file'|'repo'), owner, repo
    или None, если ссылка не подходит.
    """
    if is_file_url(url):
        return {
            "download_url": url,
            "filename": filename_from_url(url),
            "kind": "file",
            "owner": "",
            "repo": "",
        }

    parsed = parse_github_repo(url)
    if parsed is None:
        return None

    owner, repo = parsed
    # Имя архива в arch: [название мода]-master.zip
    filename = f"{sanitize_mod_filename(mod_name)}-master.zip"
    return {
        "download_url": github_branch_zip_url(owner, repo, "master"),
        "filename": filename,
        "kind": "repo",
        "owner": owner,
        "repo": repo,
        "folder": folder_name,
    }


def repo_archive_candidates(
    mod_name: str, folder_name: str, owner: str, repo: str
) -> list[str]:
    """Возможные имена уже скачанного архива репозитория в arch."""
    names: list[str] = []
    for base in (
        sanitize_mod_filename(mod_name),
        sanitize_mod_filename(folder_name) if folder_name else "",
        sanitize_mod_filename(repo),
    ):
        if not base:
            continue
        for suffix in ("-master.zip", "-main.zip"):
            name = f"{base}{suffix}"
            if name not in names:
                names.append(name)
    return names


def ssl_context() -> ssl.SSLContext:
    if certifi is not None:
        return ssl.create_default_context(cafile=certifi.where())
    return ssl.create_default_context()


def download_with_curl(url: str, destination: Path) -> None:
    curl = shutil.which("curl.exe") or shutil.which("curl")
    if not curl:
        raise RuntimeError("curl не найден")

    result = subprocess.run(
        [
            curl,
            "-fsSL",
            "--retry",
            "3",
            "--retry-delay",
            "2",
            "-A",
            "BgModInstaller/1.0",
            "-o",
            str(destination),
            url,
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "ошибка curl")


def download_file(url: str, destination: Path) -> None:
    request = Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 (compatible; BgModInstaller/1.0)",
            "Accept": "*/*",
        },
    )
    try:
        with urlopen(request, timeout=120, context=ssl_context()) as response, destination.open(
            "wb"
        ) as out:
            shutil.copyfileobj(response, out)
    except URLError as error:
        if "CERTIFICATE_VERIFY_FAILED" not in str(error) and not isinstance(
            error.reason, ssl.SSLCertVerificationError
        ):
            raise
        log.warning("SSL через urllib не прошёл, пробую curl: %s", error)
        download_with_curl(url, destination)


def archive_extract_dir(archive_path: Path) -> Path:
    name = archive_path.name.lower()
    if name.endswith(".tar.gz"):
        return SCRIPT_DIR / archive_path.name[: -len(".tar.gz")]
    return SCRIPT_DIR / archive_path.stem


def extract_zip(archive_path: Path, target_dir: Path) -> None:
    with zipfile.ZipFile(archive_path) as archive:
        archive.extractall(target_dir)


def extract_tar(archive_path: Path, target_dir: Path) -> None:
    with tarfile.open(archive_path) as archive:
        archive.extractall(target_dir)


def extract_with_7z(archive_path: Path, target_dir: Path) -> None:
    seven_zip = shutil.which("7z") or shutil.which("7za")
    if not seven_zip:
        raise RuntimeError("Для .7z/.rar нужен установленный 7-Zip (команда 7z)")
    result = subprocess.run(
        [seven_zip, "x", str(archive_path), f"-o{target_dir}", "-y"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "ошибка 7z")


def extract_archive(archive_path: Path) -> Path:
    target_dir = archive_extract_dir(archive_path)
    target_dir.mkdir(parents=True, exist_ok=True)

    suffix = archive_path.suffix.lower()
    name = archive_path.name.lower()

    if suffix == ".zip" or zipfile.is_zipfile(archive_path):
        extract_zip(archive_path, target_dir)
    elif name.endswith(".tar.gz") or suffix in {".tar", ".tgz", ".gz", ".bz2"}:
        extract_tar(archive_path, target_dir)
    elif suffix in {".7z", ".rar"}:
        extract_with_7z(archive_path, target_dir)
    else:
        raise RuntimeError(f"неизвестный тип архива: {archive_path.name}")

    return target_dir


def tp2_files_in_dir(directory: Path) -> list[Path]:
    """Только *.tp2 непосредственно в directory (не рекурсивно). Предпочитает setup-*.tp2."""
    if not directory.is_dir():
        return []
    tp2_here = sorted(
        path
        for path in directory.iterdir()
        if path.is_file() and path.suffix.lower() == ".tp2"
    )
    if not tp2_here:
        return []
    setup = [path for path in tp2_here if path.name.lower().startswith("setup-")]
    return setup if setup else tp2_here


def content_root_for_archive(extract_root: Path, kind: str) -> Path:
    """
    Стартовый корень содержимого архива:
    - file (zip по ссылке): сам extract_root
    - repo: папка первого уровня внутри extract_root
    """
    if kind != "repo":
        return extract_root

    subdirs = sorted(path for path in extract_root.iterdir() if path.is_dir())
    if not subdirs:
        log.warning(
            "В архиве репозитория нет папки первого уровня, ищу в %s",
            extract_root.name,
        )
        return extract_root
    if len(subdirs) > 1:
        log.warning(
            "В архиве репозитория несколько папок верхнего уровня, беру: %s",
            subdirs[0].name,
        )
    return subdirs[0]


def find_mod_tp2_near_content_root(content_root: Path) -> list[Path]:
    """
    Папка мода — непосредственный потомок content_root, внутри неё лежит .tp2:
    content_root / <папка_мода> / *.tp2
    """
    found: list[Path] = []
    if not content_root.is_dir():
        return found

    for child in sorted(path for path in content_root.iterdir() if path.is_dir()):
        found.extend(tp2_files_in_dir(child))
    return found


def pick_installer_exe(search_root: Path, downloaded_path: Path | None) -> Path | None:
    """Ищет setup-*.exe / *.exe только непосредственно в search_root (рядом с папкой мода)."""
    candidates = []
    if search_root.is_dir():
        for path in sorted(search_root.iterdir()):
            if not path.is_file() or path.suffix.lower() != ".exe":
                continue
            if path.name.lower() in SKIP_EXE_NAMES:
                continue
            if downloaded_path and path.resolve() == downloaded_path.resolve():
                continue
            candidates.append(path)

    if not candidates:
        return None

    setup = [path for path in candidates if path.name.lower().startswith("setup-")]
    if setup:
        return setup[0]
    return candidates[0]


def locate_mod_and_exe(
    content_root: Path, downloaded_path: Path | None = None
) -> tuple[Path | None, Path | None, Path]:
    """
    Ищет пару: папка мода с .tp2 и exe на том же уровне, что и папка мода.

    content_root/
      setup-*.exe
      ModFolder/
        *.tp2

    Если полной пары нет — спускается на один уровень ниже только если там
    ровно одна подпапка. Если подпапок две и больше — ошибка, без спуска.
    Возвращает (tp2_path, exe_path, actual_content_root).
    """
    tp2_files = find_mod_tp2_near_content_root(content_root)
    exe_path = pick_installer_exe(content_root, downloaded_path)
    tp2_path = tp2_files[0] if tp2_files else None

    if tp2_path is not None and exe_path is not None:
        return tp2_path, exe_path, content_root

    log.info(
        "На уровне %s нет полной пары (exe рядом с папкой мода + .tp2)",
        content_root.name,
    )

    if not content_root.is_dir():
        return tp2_path, exe_path, content_root

    subdirs = sorted(path for path in content_root.iterdir() if path.is_dir())
    if len(subdirs) == 0:
        log.warning("Спуск ниже невозможен: в %s нет подпапок", content_root.name)
        return tp2_path, exe_path, content_root

    if len(subdirs) > 1:
        log.error(
            "Спуск на уровень ниже отменён: в %s несколько папок (%s), ожидалась одна. "
            "Имена: %s",
            content_root.name,
            len(subdirs),
            ", ".join(path.name for path in subdirs),
        )
        return tp2_path, exe_path, content_root

    deeper = subdirs[0]
    log.info("Спуск на уровень ниже в единственную папку: %s", deeper.name)

    deeper_tp2_files = find_mod_tp2_near_content_root(deeper)
    deeper_exe = pick_installer_exe(deeper, downloaded_path)
    deeper_tp2 = deeper_tp2_files[0] if deeper_tp2_files else None

    if deeper_tp2 is not None and deeper_exe is not None:
        log.info("exe и .tp2 найдены на уровень ниже: %s", deeper.name)
        return deeper_tp2, deeper_exe, deeper

    log.warning(
        "На уровне ниже (%s) тоже нет полной пары exe + папка мода с .tp2",
        deeper.name,
    )
    return deeper_tp2, deeper_exe, deeper


def locate_after_exe_run(
    folder_name: str,
) -> tuple[Path | None, Path | None, Path]:
    """
    После выполнения скачанного .exe:
    - .tp2 ищет в папке из CSV (столбец 9)
    - setup.exe ищет только в корне: setup-[имя папки из CSV].exe
    """
    tp2_path: Path | None = None

    if folder_name:
        mod_folder = SCRIPT_DIR / folder_name
        if mod_folder.is_dir():
            log.info("После .exe ищу .tp2 в папке из CSV: %s", folder_name)
            direct_tp2 = tp2_files_in_dir(mod_folder)
            if direct_tp2:
                tp2_path = direct_tp2[0]
            else:
                nested_tp2 = find_mod_tp2_near_content_root(mod_folder)
                if nested_tp2:
                    tp2_path = nested_tp2[0]
        else:
            log.warning("Папка %s из CSV не найдена после выполнения .exe", folder_name)
    else:
        log.warning("Папка в CSV не указана — .tp2 после .exe не ищется")

    exe_path: Path | None = None
    if folder_name:
        exe_path = setup_exe_path(folder_name)
        if exe_path is not None:
            log.info("Найден setup.exe в корне: %s", exe_path.name)
        else:
            log.warning("В корне не найден setup-%s.exe", folder_name)
    else:
        log.warning("Папка в CSV не указана — setup.exe не ищется")

    return tp2_path, exe_path, SCRIPT_DIR


def move_mod_folder_to_script_dir(tp2_path: Path) -> Path:
    """Перемещает папку с .tp2 в директорию скрипта, если она ещё не там."""
    mod_dir = tp2_path.parent.resolve()
    script_dir = SCRIPT_DIR.resolve()

    if mod_dir.parent == script_dir:
        log.info("Папка мода уже в текущей директории: %s", mod_dir.name)
        return mod_dir

    destination = script_dir / mod_dir.name
    if destination.exists():
        log.info("Папка уже существует в текущей директории: %s", destination.name)
        return destination

    log.info("Перемещение папки мода: %s -> %s", mod_dir, destination.name)
    shutil.move(str(mod_dir), str(destination))
    log.info("Папка мода перемещена: %s", destination.name)
    return destination


def resolve_path_after_move(extract_root: Path, relative: Path) -> Path | None:
    for base in (extract_root, SCRIPT_DIR):
        candidate = base / relative
        if candidate.exists():
            return candidate
    return None


def is_under_arch(path: Path) -> bool:
    try:
        path.resolve().relative_to(ARCH_DIR.resolve())
        return True
    except ValueError:
        return False


def move_exe_to_script_dir(exe_path: Path) -> Path:
    destination = SCRIPT_DIR / exe_path.name
    if exe_path.resolve() == destination.resolve():
        log.info("exe уже в текущей директории: %s", destination.name)
        return destination

    if is_under_arch(exe_path):
        log.info("Копирование exe из arch в корень: %s", exe_path.name)
        shutil.copy2(exe_path, destination)
        log.info("exe скопирован в корень (оригинал в arch сохранён): %s", destination.name)
        return destination

    if destination.exists():
        log.info("exe уже существует в текущей директории: %s", destination.name)
        return destination

    log.info("Перемещение exe: %s -> %s", exe_path.name, destination.name)
    shutil.move(str(exe_path), str(destination))
    log.info("exe перемещён в текущую директорию: %s", destination.name)
    return destination


def remove_root_exe_copy(exe_path: Path) -> None:
    """Удаляет временную копию exe из корня (оригинал в arch не трогает)."""
    exe_path = exe_path.resolve()
    if exe_path.parent != SCRIPT_DIR.resolve():
        return
    if is_under_arch(exe_path):
        return
    if not exe_path.is_file():
        return
    log.info("Удаление временной копии exe из корня: %s", exe_path.name)
    exe_path.unlink(missing_ok=True)


def parse_components(value: str) -> list[str]:
    """Номера компонентов из столбца 11 CSV (через пробел)."""
    return [part for part in value.split() if part]


def build_install_args(components: list[str]) -> list[str]:
    """Аргументы установщика: --language 0 и --yes всегда; --force-install-list — если есть компоненты."""
    args = ["--language", "0"]
    args.append("--no-exit-pause")
    if components:
        args.extend(["--force-install-list", *components])
    return args


def format_exe_command(exe_path: Path, extra_args: list[str] | None = None) -> str:
    parts = [exe_path.name]
    if extra_args:
        parts.extend(extra_args)
    return " ".join(parts)


def run_exe(exe_path: Path, extra_args: list[str] | None = None) -> int:
    cmd = [str(exe_path)]
    if extra_args:
        cmd.extend(extra_args)
    completed = subprocess.run(cmd, cwd=str(SCRIPT_DIR))
    return completed.returncode


def run_downloaded_self_extractor(arch_exe: Path) -> Path:
    """Скачанный .exe из arch: копия в корень, запуск копии. Оригинал в arch сохраняется."""
    runnable = move_exe_to_script_dir(arch_exe)
    log.info("Параметры запуска: %s", format_exe_command(runnable))
    log.info("Запуск копии .exe для распаковки: %s", runnable.name)
    code = run_exe(runnable)
    if code == 0:
        log.info("Скачанный .exe завершился успешно (код 0)")
    else:
        log.warning("Скачанный .exe завершился с кодом %s", code)
    return runnable


def remove_extract_dir(extract_dir: Path | None) -> None:
    if extract_dir is None:
        return
    extract_dir = extract_dir.resolve()
    if extract_dir == SCRIPT_DIR.resolve():
        return
    if not extract_dir.exists() or not extract_dir.is_dir():
        return
    log.info("Удаление временной папки распаковки: %s", extract_dir.name)
    shutil.rmtree(extract_dir, ignore_errors=False)
    log.info("Временная папка удалена: %s", extract_dir.name)


def ensure_local_file(url: str, local_path: Path, force: bool = False) -> bool:
    ARCH_DIR.mkdir(parents=True, exist_ok=True)

    if force and local_path.exists():
        log.info("Удаление повреждённого файла: %s", local_path.relative_to(SCRIPT_DIR))
        local_path.unlink()

    if not force and local_path.exists() and local_path.stat().st_size > 0:
        log.info("Найден уже скачанный файл: %s", local_path.relative_to(SCRIPT_DIR))
        return True

    # Старый архив мог лежать в корне — переносим в arch
    if not force:
        legacy = SCRIPT_DIR / local_path.name
        if (
            legacy.exists()
            and legacy.stat().st_size > 0
            and legacy.resolve() != local_path.resolve()
        ):
            log.info("Найден файл в корне, перенос в arch: %s", legacy.name)
            shutil.move(str(legacy), str(local_path))
            return True

    log.info("Архив/файл не найден в arch, скачивание: %s", url)
    try:
        download_file(url, local_path)
    except (HTTPError, URLError, TimeoutError, OSError, RuntimeError) as error:
        log.error("Не удалось скачать: %s", error)
        if local_path.exists():
            local_path.unlink(missing_ok=True)
        return False
    log.info("Скачано: %s (%s байт)", local_path.relative_to(SCRIPT_DIR), local_path.stat().st_size)
    return True


def find_existing_repo_archive(
    local_path: Path, mod_name: str, folder_name: str, owner: str, repo: str
) -> Path | None:
    """Ищет уже скачанный архив репозитория в arch (сначала каноническое имя)."""
    ARCH_DIR.mkdir(parents=True, exist_ok=True)

    candidates = [local_path.name] + [
        name
        for name in repo_archive_candidates(mod_name, folder_name, owner, repo)
        if name != local_path.name
    ]

    log.info("Проверка arch на наличие архива репозитория (ожидаемое имя: %s)", local_path.name)
    for name in candidates:
        path = ARCH_DIR / name
        if path.exists() and path.stat().st_size > 0:
            log.info("Найден уже скачанный архив в arch: %s", path.relative_to(SCRIPT_DIR))
            if path.resolve() != local_path.resolve():
                if local_path.exists():
                    log.info(
                        "Каноническое имя %s уже занято — использую найденный файл %s",
                        local_path.name,
                        path.name,
                    )
                    return path
                log.info("Переименовываю %s -> %s", path.name, local_path.name)
                path.rename(local_path)
                return local_path
            return path

    # Старый файл мог лежать в корне
    for name in candidates:
        legacy = SCRIPT_DIR / name
        if (
            legacy.exists()
            and legacy.stat().st_size > 0
            and not is_under_arch(legacy)
        ):
            target = ARCH_DIR / (local_path.name if name == local_path.name else name)
            if target.exists():
                return target if target.stat().st_size > 0 else None
            log.info("Найден файл в корне, перенос в arch: %s", legacy.name)
            shutil.move(str(legacy), str(target))
            if target.resolve() != local_path.resolve() and not local_path.exists():
                target.rename(local_path)
                return local_path
            return target if target.exists() else local_path

    log.info("В arch архив не найден: %s", local_path.name)
    return None


def ensure_repo_archive(
    owner: str,
    repo: str,
    local_path: Path,
    *,
    mod_name: str = "",
    folder_name: str = "",
    force: bool = False,
) -> tuple[str, Path] | None:
    """
    Скачивает master (или main) в local_path.
    Сначала проверяет наличие файла в arch.
    Возвращает (url, путь_к_архиву) или None.
    """
    ARCH_DIR.mkdir(parents=True, exist_ok=True)

    if force and local_path.exists():
        log.info("Удаление повреждённого файла: %s", local_path.relative_to(SCRIPT_DIR))
        local_path.unlink()

    if not force:
        existing = find_existing_repo_archive(
            local_path, mod_name or local_path.stem, folder_name, owner, repo
        )
        if existing is not None:
            return github_branch_zip_url(owner, repo, "master"), existing

    last_error: Exception | None = None
    for branch in ("master", "main"):
        url = github_branch_zip_url(owner, repo, branch)
        log.info("Скачивание ветки %s репозитория %s/%s: %s", branch, owner, repo, url)
        try:
            download_file(url, local_path)
            log.info(
                "Скачано: %s (%s байт)",
                local_path.relative_to(SCRIPT_DIR),
                local_path.stat().st_size,
            )
            return url, local_path
        except HTTPError as error:
            last_error = error
            if error.code == 404:
                log.warning("Ветка %s не найдена (404), пробую следующую", branch)
                if local_path.exists():
                    local_path.unlink(missing_ok=True)
                continue
            log.error("Не удалось скачать: %s", error)
            if local_path.exists():
                local_path.unlink(missing_ok=True)
            return None
        except (URLError, TimeoutError, OSError, RuntimeError) as error:
            last_error = error
            log.error("Не удалось скачать: %s", error)
            if local_path.exists():
                local_path.unlink(missing_ok=True)
            return None

    log.error("Не удалось скачать master/main для %s/%s: %s", owner, repo, last_error)
    return None


def extract_archive_with_redownload(
    download_url: str,
    local_path: Path,
    *,
    repo: tuple[str, str] | None = None,
    mod_name: str = "",
    folder_name: str = "",
) -> Path | None:
    """Распаковывает архив; при ошибке удаляет файл, скачивает заново и пробует ещё раз."""
    extract_dir = archive_extract_dir(local_path)

    for attempt in (1, 2):
        if extract_dir.exists() and any(extract_dir.iterdir()):
            log.info("Уже распаковано в папку: %s", extract_dir.name)
            return extract_dir

        log.info("Распаковка %s в %s", local_path.name, extract_dir.name)
        try:
            extract_dir = extract_archive(local_path)
            log.info("Распаковано в папку: %s", extract_dir.name)
            return extract_dir
        except Exception as error:
            log.error("Не удалось распаковать: %s", error)
            remove_extract_dir(extract_dir)
            if attempt == 1:
                log.warning("Повреждённый архив будет удалён и скачан заново")
                if repo is not None:
                    owner, repo_name = repo
                    result = ensure_repo_archive(
                        owner,
                        repo_name,
                        local_path,
                        mod_name=mod_name,
                        folder_name=folder_name,
                        force=True,
                    )
                    if result is None:
                        return None
                    local_path = result[1]
                elif not ensure_local_file(download_url, local_path, force=True):
                    return None
                continue
            log.error("Повторная распаковка после повторного скачивания тоже не удалась")
            return None

    return None


def has_tp2_in_mod_folder(mod_folder: Path) -> bool:
    if not mod_folder.is_dir():
        return False
    return any(
        path.is_file() and path.suffix.lower() == ".tp2" for path in mod_folder.iterdir()
    )


def setup_exe_path(folder_name: str) -> Path | None:
    """Ищет setup-[название модуля].exe в корне (без учёта регистра)."""
    expected = f"setup-{folder_name}.exe"
    direct = SCRIPT_DIR / expected
    if direct.is_file():
        return direct
    expected_lower = expected.lower()
    for path in SCRIPT_DIR.glob("setup-*.exe"):
        if path.name.lower() == expected_lower:
            return path
    return None


def check_installed_mod(folder_name: str) -> dict:
    """Проверяет уже установленный мод: папка, .tp2, setup-*.exe."""
    mod_folder = SCRIPT_DIR / folder_name
    has_folder = mod_folder.is_dir()
    has_tp2 = has_tp2_in_mod_folder(mod_folder) if has_folder else False
    exe = setup_exe_path(folder_name) if folder_name else None
    return {
        "folder": has_folder,
        "tp2": has_tp2,
        "exe": exe is not None,
        "exe_path": exe,
        "mod_folder": mod_folder,
    }


def log_installed_check(mod_name: str, folder_name: str, status: dict) -> None:
    log.info("Модуль уже установлен (папка %s есть в корне)", folder_name)
    if status["tp2"]:
        log.info("  .tp2 в папке мода: найден")
    else:
        log.warning("  .tp2 в папке мода: НЕ найден")
    expected_exe = f"setup-{folder_name}.exe"
    if status["exe"]:
        log.info("  %s в корне: найден (%s)", expected_exe, status["exe_path"].name)
    else:
        log.warning("  %s в корне: НЕ найден", expected_exe)


def build_status_report(mods: list[dict]) -> dict:
    installed = 0
    with_tp2 = 0
    with_exe = 0
    incomplete: list[str] = []

    for mod in mods:
        folder_name = mod.get("folder") or ""
        if not folder_name:
            continue
        status = check_installed_mod(folder_name)
        if not status["folder"]:
            continue
        installed += 1
        if status["tp2"]:
            with_tp2 += 1
        if status["exe"]:
            with_exe += 1
        if not status["tp2"] or not status["exe"]:
            incomplete.append(mod["name"])

    return {
        "installed": installed,
        "tp2": with_tp2,
        "exe": with_exe,
        "incomplete": incomplete,
    }


def log_status_report(report: dict) -> None:
    log.info("===== Отчёт =====")
    log.info("Установлено (папка мода в корне): %s", report["installed"])
    log.info("С файлом .tp2 в папке мода: %s", report["tp2"])
    log.info("С setup-[имя модуля].exe в корне: %s", report["exe"])
    if report["incomplete"]:
        log.warning(
            "Неполные установки (%s): отсутствует .tp2 и/или setup-*.exe",
            len(report["incomplete"]),
        )
        for name in report["incomplete"]:
            log.warning("  - %s", name)


def prepare_mod(mod: dict, rows: list[list[str]], csv_path: Path) -> Path | None:
    """Скачивает/распаковывает мод, готовит exe. Возвращает путь к exe или None."""
    name = mod["name"]
    order = mod["order"] or -1000
    url = mod["url"]
    folder_name = mod["folder"]
    log.info("=== Подготовка: %s (порядок %s) ===", name, order)

    if folder_name:
        status = check_installed_mod(folder_name)
        if status["folder"]:
            log_installed_check(name, folder_name, status)
            return None
        log.info("В CSV указана папка %s, но в корне её нет — продолжаем подготовку", folder_name)
    else:
        log.info("В столбце 9 имя папки мода пустое — нужно скачать/распаковать")

    source = resolve_download(name, url, folder_name)
    if source is None:
        log.info(
            "Пропуск: в столбце 10 нет ссылки на файл (.zip/.exe) или GitHub-репозиторий (%s)",
            url or "пусто",
        )
        return None

    local_path = ARCH_DIR / source["filename"]
    download_url = source["download_url"]
    repo_pair: tuple[str, str] | None = None

    if source["kind"] == "repo":
        repo_pair = (source["owner"], source["repo"])
        log.info(
            "Ссылка на репозиторий %s/%s — ожидаемый архив в arch: %s",
            source["owner"],
            source["repo"],
            source["filename"],
        )
        result = ensure_repo_archive(
            source["owner"],
            source["repo"],
            local_path,
            mod_name=name,
            folder_name=folder_name,
        )
        if result is None:
            return None
        download_url, local_path = result
        extension = ".zip"
    else:
        if not ensure_local_file(download_url, local_path):
            return None
        extension = url_file_extension(download_url)

    extract_root = SCRIPT_DIR
    extract_dir: Path | None = None
    downloaded_exe: Path | None = None
    self_extractor_copy: Path | None = None
    archive_kind = source["kind"]  # "file" | "repo"
    tp2_path: Path | None = None
    exe_path: Path | None = None
    content_root = SCRIPT_DIR
    search_location = SCRIPT_DIR

    if extension in ARCHIVE_EXTENSIONS or (
        local_path.exists() and zipfile.is_zipfile(local_path)
    ):
        extract_dir = extract_archive_with_redownload(
            download_url,
            local_path,
            repo=repo_pair,
            mod_name=name,
            folder_name=folder_name,
        )
        if extract_dir is None:
            return None
        extract_root = extract_dir
    elif extension == ".exe":
        log.info("Ссылка на .exe — скачиваю, выполняю копию для распаковки, затем ищу содержимое")
        archive_kind = "file"
        self_extractor_copy = run_downloaded_self_extractor(local_path)
        downloaded_exe = self_extractor_copy
        extract_root = SCRIPT_DIR
        search_location = SCRIPT_DIR / folder_name if folder_name else SCRIPT_DIR
        tp2_path, exe_path, content_root = locate_after_exe_run(folder_name)
    else:
        log.info("Файл не архив и не exe, пропуск распаковки")

    try:
        if extension != ".exe":
            # zip по ссылке: extract_root / exe + ModFolder/
            # репозиторий: extract_root / Wrapper / exe + ModFolder/
            start_root = content_root_for_archive(extract_root, archive_kind)
            search_location = start_root
            if archive_kind == "repo":
                log.info(
                    "Архив репозитория: сначала ищу в %s",
                    start_root.relative_to(SCRIPT_DIR)
                    if start_root != SCRIPT_DIR
                    else "корне",
                )
            else:
                log.info(
                    "Архив по ссылке: сначала ищу в %s",
                    start_root.relative_to(SCRIPT_DIR)
                    if start_root != SCRIPT_DIR
                    else "корне",
                )

            tp2_path, exe_path, content_root = locate_mod_and_exe(start_root, downloaded_exe)

            if tp2_path is None and extract_root == SCRIPT_DIR:
                root_tp2 = tp2_files_in_dir(SCRIPT_DIR)
                if root_tp2:
                    tp2_path = root_tp2[0]

        exe_relative = None
        if exe_path is not None:
            try:
                exe_relative = exe_path.relative_to(extract_root)
            except ValueError:
                exe_relative = Path(exe_path.name)

        if tp2_path is not None:
            discovered_folder = tp2_path.parent.name
            log.info(
                "Найден .tp2: %s (папка мода: %s)",
                tp2_path.relative_to(SCRIPT_DIR),
                discovered_folder,
            )
            log.info(
                "Уровень содержимого (exe рядом с папкой мода): %s",
                content_root.relative_to(SCRIPT_DIR)
                if content_root != SCRIPT_DIR
                else "корень",
            )

            if not folder_name:
                update_mod_folder_in_csv(rows, mod, discovered_folder, csv_path)
            elif folder_name != discovered_folder:
                log.warning(
                    "Имя папки в CSV (%s) отличается от найденного (%s), оставляю значение из CSV",
                    folder_name,
                    discovered_folder,
                )

            move_mod_folder_to_script_dir(tp2_path)
        else:
            log.warning(
                "Папка мода с .tp2 не найдена (искали в %s)",
                search_location.relative_to(SCRIPT_DIR)
                if search_location != SCRIPT_DIR
                else "корне",
            )
            if extension != ".exe":
                remove_extract_dir(extract_dir)
                return None

        if exe_path is None and downloaded_exe is not None:
            log.info(
                "После выполнения скачанного .exe отдельный setup.exe не найден — "
                "этап установки для этого мода не требуется"
            )
            return None

        if exe_path is not None and downloaded_exe is not None:
            if exe_path.resolve() == downloaded_exe.resolve():
                log.info(
                    "Найден только уже выполненный скачанный .exe — этап установки не требуется"
                )
                return None

        if exe_relative is not None:
            resolved = resolve_path_after_move(extract_root, exe_relative)
            if resolved is not None:
                exe_path = resolved

        if exe_path is None or not exe_path.exists():
            log.warning("exe-файл не найден")
            remove_extract_dir(extract_dir)
            return None

        log.info("Найден exe в распакованном содержимом: %s", exe_path.name)
        moved = move_exe_to_script_dir(exe_path)

        remove_extract_dir(extract_dir)

        log.info("Модуль подготовлен, exe готов к запуску: %s", moved.name)
        return moved
    finally:
        if self_extractor_copy is not None:
            remove_root_exe_copy(self_extractor_copy)


def install_mod(mod: dict, exe_path: Path) -> None:
    name = mod["name"]
    if int(mod["order"]) < 0 :
        log.error("Мод не устанавливаем: отрицательный приоритет: %s", exe_path)
        return
    order = mod["order"] or -1000
    components = parse_components(mod.get("components", ""))
    install_args = build_install_args(components)
    log.info("=== Установка: %s (порядок %s) ===", name, order)

    if not exe_path.exists():
        log.error("exe не найден для запуска: %s", exe_path)
        return

    log.info("Параметры запуска: %s", format_exe_command(exe_path, install_args))
    code = run_exe(exe_path, install_args)
    if code == 0:
        log.info("Установщик завершился успешно (код 0)")
    else:
        log.warning("Установщик завершился с кодом %s", code)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Подготовка к установке и установка EET"
    )
    parser.add_argument(
        "--install-fresh-bg2",
        help="Подготовить папку для чистой установки BG2EE",
    )
    parser.add_argument(
        "--full-install-fresh-bg2",
        help="Подготовить папку для полной автоматической чистой установки BG2EE",
    )
    parser.add_argument(
        "--install-bu-bg2",
        help="Подготовить папку для б/у установки BG2EE",
    )
    parser.add_argument(
        "--full-install-bu-bg2",
        help="Подготовить папку для полной автоматической б/у установки BG2EE",
    )
    parser.add_argument(
        "--download-only",
        "-d",
        help="Только проверить/скачать/распаковать модули, без запуска установщиков",
    )
    parser.add_argument(
        "--check-only",
        "-c",
        action="store_true",
        help="Только проверить моды, без запуска установщиков и скачивания",
    )
    parser.add_argument(
        "--report",
        help="Отчет",
    )
    parser.add_argument(
        "--install",
        "-i",
        nargs=2,
        type=int,
        metavar=("FROM", "TO"),
        help=(
            "После подготовки установить моды с приоритетом от FROM до TO включительно "
            "(столбец 8). Оба числа обязательны. На загрузку/проверку не влияет."
        ),
    )
    return parser.parse_args(argv)


def mods_with_priority(mods: list[dict]) -> list[dict]:
    return [mod for mod in mods if mod["order"]]


def resolve_installer_exe(mod: dict, ready_by_line: dict[int, Path]) -> Path | None:
    exe = ready_by_line.get(mod["line"])
    if exe is not None and exe.exists():
        return exe
    folder_name = mod.get("folder") or ""
    if folder_name:
        return setup_exe_path(folder_name)
    return None


def run_install_stage(
    mods: list[dict],
    ready: list[tuple[dict, Path]],
    from_priority: int,
    to_priority: int,
) -> int:
    """Устанавливает моды с приоритетом FROM..TO включительно. Возвращает число запусков."""
    ready_by_line = {mod["line"]: exe_path for mod, exe_path in ready}
    to_install = mods_with_priority(mods)
    log.info("===== Этап 2: запуск установщиков по приоритету =====")
    log.info("Диапазон приоритета: %s .. %s (включительно)", from_priority, to_priority)
    log.info("Модов с приоритетом в CSV: %s", len(to_install))

    installed_count = 0
    skipped_before = 0
    for mod in to_install:
        try:
            priority = int(mod["order"])
        except ValueError:
            log.warning(
                "Пропуск «%s»: приоритет «%s» не число",
                mod["name"],
                mod["order"],
            )
            continue

        if priority < from_priority:
            skipped_before += 1
            continue

        if priority > to_priority:
            log.info(
                "Приоритет %s у «%s» больше верхней границы %s — этап установки остановлен",
                priority,
                mod["name"],
                to_priority,
            )
            break

        exe_path = resolve_installer_exe(mod, ready_by_line)
        if exe_path is None:
            log.warning(
                "Пропуск «%s» (приоритет %s): setup.exe не найден",
                mod["name"],
                mod["order"],
            )
            continue
        # if (mod["folder"] == "chloe") or  (mod["folder"] == "c#greythedog"):
        #     exe_path = Path("weidu.exe")
        try:
            install_mod(mod, exe_path)
            installed_count += 1
        except Exception as error:
            log.exception("Ошибка при установке «%s»: %s", mod["name"], error)

    if skipped_before:
        log.info("Пропущено модов с приоритетом ниже %s: %s", from_priority, skipped_before)
    log.info("Запущено установщиков на этапе 2: %s", installed_count)
    return installed_count


def remove_readonly(func, path, exc_info):
        "Clear the readonly bit and reattempt the removal"
        # ERROR_ACCESS_DENIED = 5
        if func not in (os.unlink, os.rmdir) or exc_info[1].winerror != 5:
            raise exc_info[1]
        os.chmod(path, stat.S_IWRITE)
        func(path)


def clean_folder(folder: Path, keep: set[str], dry_run: bool = False) -> None:
    """Удаляет всё содержимое folder, кроме имён из keep."""
    if not folder.is_dir():
        print(f"[SKIP] Не папка: {folder}")
        return

    for item in folder.iterdir():
        if item.name in keep:
            print(f"[KEEP] {item}")
            continue

        if dry_run:
            print(f"[DRY-RUN] Будет удалено: {item}")
            continue

        try:
            if item.is_dir():
                shutil.rmtree(item, onerror=remove_readonly)
            else:
                item.unlink()
            print(f"[OK] Удалено: {item}")
        except Exception as e:
            print(f"[ERROR] {item}: {e}", file=sys.stderr)

def download_mods() -> int:
    return 1

def check_mods() -> int:
    return 1

def install_fresh_bg2(settings) -> int :
    log.info("========================================")
    base_dir = Path.cwd()
    dont_delete = getparamsfromsettings(settings,["scripts","dont_delete","arch_folder","bg2_distr"])
    log.info("Папки НЕ к удалению:")
    log.info(dont_delete)

    # очистка папки
    log.info("")
    log.info("Удаление:")
    clean_folder(SCRIPT_DIR,dont_delete)

    # 2. установка (копирование) BG2EE
    log.info("")
    log.info("Копирование:")
    copybg2ee(getbg2dist(settings),base_dir)
    # 3. Скачивание/распаковка модов
    check_mods()

    return 0


def full_install_fresh_bg2(settings) -> int:

    # подготовка
    install_fresh_bg2(settings)

    # установка
    log.info(getmodrange(settings))
    start_mod, end_mod = getmodrange(settings)
    install_mods(mods,start_mod,end_mod)

    return 0


def install_bu_bg2(settings) -> int:
    log.info("========================================")
    base_dir = Path.cwd()
    #folders_delete = create_list_folder_to_delete(settings)
    folders_delete = getparamsfromsettings(settings,["folder_to_remove","bg2_folders"])
    log.info("Папки к удалению:")
    log.info(folders_delete)
    if not folders_delete:
        print("Не указаны папки к удалению нив одной секции.")
        return -1

    print(f"Найдено папок для удаления: {len(folders_delete)}")
    for f in folders_delete:
        print(f"  - {f}")
    print()

    # 1. удаление папок
    log.info("")
    log.info("Удаление:")
    remove_folders(base_dir, folders_delete)

    # 2. установка (копирование) BG2EE
    log.info("")
    log.info("Копирование:")
    copybg2ee(getbg2dist(settings),base_dir)

    # 3. Скачивание/распаковка модов
    mods = check_mods()

    return mods


def full_install_bu_bg2(settings) -> int:

    # подготовка
    mods = install_bu_bg2(settings)

    # установка
    log.info(getmodrange(settings))
    start_mod, end_mod = getmodrange(settings)
    install_mods(mods,start_mod,end_mod)

    return 0

def report() -> int:
    return 0


def getparamsfromsettings(settings,sec:list[str]) -> list[str]:
    out: list[str] = []
    for v in settings:
        if (v[0] in sec):
            t = v[1].split(",")
            for tv in t:
                if tv == "":
                    continue
                out.append(tv)
    return out


def remove_folders(base_dir: Path, folders: list[str], dry_run: bool = False) -> int:
    """Удаляет указанные папки внутри base_dir."""
    for folder in folders:
        target = base_dir / folder

        if not target.exists():
            print(f"[SKIP] Не существует: {target}")
            continue

        if not target.is_dir():
            print(f"[SKIP] Не папка: {target}")
            continue

        if dry_run:
            print(f"[DRY-RUN] Будет удалено: {target}")
            continue

        try:
            shutil.rmtree(target)
            print(f"[OK] Удалено: {target}")
        except Exception as e:
            print(f"[ERROR] Не удалось удалить {target}: {e}", file=sys.stderr)
    return 0


def copybg2ee(src: Path, dst: Path, overwrite: bool = True) -> None:
    """Копирует всё содержимое src в dst (рекурсивно)."""
    dst = Path(dst)
    src = Path(src)
    log.info("Копируем из " + str(src) + " в " + str(dst))

    if not src.is_dir():
        raise NotADirectoryError(f"Источник не папка: {src}")

    dst.mkdir(parents=True, exist_ok=True)

    for item in src.iterdir():
        target = dst / item.name

        try:
            if item.is_dir():
                # dirs_exist_ok=True позволяет копировать поверх существующей папки
                shutil.copytree(item, target, dirs_exist_ok=overwrite)
            else:
                if target.exists() and not overwrite:
                    print(f"[SKIP] Уже существует: {target}")
                    continue
                shutil.copy2(item, target)  # copy2 сохраняет метаданные
            print(f"[OK] {item} -> {target}")
        except Exception as e:
            print(f"[ERROR] {item}: {e}", file=sys.stderr)


def getbg2dist(settings):
    for value in settings:
        if value[0] == "bg2_distr":
            return value[1]
    return -1


def getarchfolder(settings):
    for value in settings:
        if value[0] == "arch_folder":
            return value[1]
    return -1


def getmodrange(settings) -> list[str]:
    ret : list[str] = []
    v2 = 0
    for value in settings:
        if value[0] == "start_mod":
            ret.append(value[1])
        if value[0] == "end_mod":
            ret.append(value[1])
    if ret != []:
        # log.info(ret)
        # exit()
        return ret
    return -1


def parse_ini(ini_path: Path, section_param = "GLOBAL") -> list[str,str]:
    """Читает .ini"""
    log.info("===================================");
    log.info("Чтение конфигкрационного ini файла");
    if not ini_path.is_file():
        raise FileNotFoundError(f"Файл не найден: {ini_path}")

    # allow_no_value=False — все строки должны быть key = value
    parser = configparser.ConfigParser()

    try:
        parser.read(ini_path, encoding="utf-8")
    except configparser.Error as e:
        raise ValueError(f"Ошибка чтения INI: {e}")

    folders: list[str,str] = []
    for section in parser.sections():
        if (section != section_param) and (section != "GLOBAL"):
            continue

        log.info("Читаем секцию "+section)
        for value in parser.items(section):
            if value[0] == "bg2_distr":
                BG2_DISTR = SCRIPT_DIR / value[1]
            folders.append(value)
            log.info(value)
        # raw_value = parser.get(section, section)
        # # Разделяем по запятой, чистим пробелы и кавычки
        # for item in raw_value.split(","):
        #     name = item.strip().strip('"').strip("'")
        #     if name and name not in folders:
        #         folders.append(name)
    if folders == []:
        log.info("Нет секций ни GLOBAL, ни "+section_param)
        return 1
    log.info("Конфиг общий: ")
    log.info(folders)
    return folders


def check_mods():
    if not CSV_PATH.exists():
        log.error("Файл mods.csv не найден")
        return 1

    rows, mods = load_csv(CSV_PATH)
    log.info("Загружено модов: %s (сортировка по столбцу 8, по возрастанию)", len(mods))

    # Этап 1: проверить/скачать/распаковать все модули.
    log.info("===== Этап 1: подготовка всех модулей =====")
    ready: list[tuple[dict, Path]] = []
    for mod in mods:
        try:
            exe_path = prepare_mod(mod, rows, CSV_PATH)
            if exe_path is not None:
                ready.append((mod, exe_path))
        except Exception as error:
            log.exception("Ошибка при подготовке «%s»: %s", mod["name"], error)

    log.info("Подготовка завершена. К установке готово: %s", len(ready))

    report = build_status_report(mods)
    log_status_report(report)
    return mods


def before_install_mods():
    # copy stat.ini и function.tph и exe для chloe и dog
    copybg2ee(EX_MOD_DIR,Path.cwd(),1)
    return False

def install_mods(mods,from_priority, to_priority):
    if before_install_mods():
        return
    ready: list[tuple[dict, Path]] = []
    to_priority = int(to_priority)
    from_priority = int(from_priority)
    if from_priority > to_priority:
        log.error(
            "Неверный диапазон --install: начало %s больше конца %s",
            from_priority,
            to_priority,
        )
        return 1
    log.info(
        "Режим установки: приоритет %s .. %s включительно",
        from_priority,
        to_priority,
    )
    run_install_stage(mods, ready, from_priority, to_priority)

    report = build_status_report(mods)
    log_status_report(report)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    setup_logging()
    ARCH_DIR.mkdir(parents=True, exist_ok=True)

    log.info("========================================")
    log.info("Рабочая директория: %s", SCRIPT_DIR)
    log.info("Лог: %s", LOG_PATH)
    log.info("Папка архивов: %s", ARCH_DIR)
    log.info("CSV: %s", CSV_PATH)

    if args.install_fresh_bg2:
        log.info("Режим: свежая установка BG2EE (очистка от всего) и установка bg2ee (--install-fresh-bg2)")
        settings = parse_ini(INIPATH,"INSTALL_FRESH_BG2")
        install_fresh_bg2(settings)
    if args.full_install_fresh_bg2:
        log.info("Режим: полная, автоматическая свежая установка BG2EE (очистка от всего, от модов, установка bg2ee, копирование и установка модов) (--full-install-fresh-bg2)")
        settings = parse_ini(INIPATH,"FULL_INSTALL_FRESH_BG2")
        full_install_fresh_bg2(settings)
    if args.install_bu_bg2:
        log.info("Режим: б/у установка BG2EE (очистка, моды оставлем, устанавливаем BG2EE) (--install-bu-bg2)")
        settings = parse_ini(INIPATH,"INSTALL_BU_BG2")
        install_bu_bg2(settings)
    if args.full_install_bu_bg2:
        log.info("Режим: полная автоматичская установка б/у BG2EE (очистка, моды оставлем, устанавливаем bg2ee и моды)  (--full-install-bu-bg2)")
        settings = parse_ini(INIPATH,"FULL_INSTALL_BU_BG2")
        full_install_bu_bg2(settings)
    if args.download_only:
        log.info("Режим: только проверка/скачивание (--download-only)")
    if args.check_only:
        log.info("Режим: только проверка (--check-only)")
    if args.report:
        log.info("Режим: отчет (--report)")
        report()
    if args.install:
        from_priority, to_priority = args.install
        install_mods(from_priority,to_priority)

    # if not CSV_PATH.exists():
    #     log.error("Файл mods.csv не найден")
    #     return 1
    #
    # rows, mods = load_csv(CSV_PATH)
    # log.info("Загружено модов: %s (сортировка по столбцу 8, по возрастанию)", len(mods))
    #
    # # Этап 1: проверить/скачать/распаковать все модули.
    # log.info("===== Этап 1: подготовка всех модулей =====")
    # ready: list[tuple[dict, Path]] = []
    # for mod in mods:
    #     try:
    #         exe_path = prepare_mod(mod, rows, CSV_PATH)
    #         if exe_path is not None:
    #             ready.append((mod, exe_path))
    #     except Exception as error:
    #         log.exception("Ошибка при подготовке «%s»: %s", mod["name"], error)
    #
    # log.info("Подготовка завершена. К установке готово: %s", len(ready))
    #
    # report = build_status_report(mods)
    # log_status_report(report)

    # if args.download_only or not args.install:
    #     if not args.install:
    #         log.info(
    #             "Этап 2 пропущен (по умолчанию выключен; "
    #             "для запуска: --install FROM TO)"
    #         )
    #     else:
    #         log.info("Этап 2 пропущен (--download-only)")
    #     log.info("Готово")
    #     return 0
    #
    # from_priority, to_priority = args.install
    # run_install_stage(mods, ready, from_priority, to_priority)
    #
    # report = build_status_report(mods)
    # log_status_report(report)

    log.info("Готово")
    return 0


if __name__ == "__main__":
    sys.exit(main())
