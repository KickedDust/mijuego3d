#!/usr/bin/env python3
"""Genera un PDF simple a partir del informe en Markdown."""
from __future__ import annotations

import textwrap
from pathlib import Path
from typing import List, Tuple

PAGE_WIDTH = 612  # 8.5 pulgadas
PAGE_HEIGHT = 792  # 11 pulgadas
LEFT_MARGIN = 72
RIGHT_MARGIN = 72
TOP_MARGIN = 72
BOTTOM_MARGIN = 72

LINE_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN


def pdf_escape(text: str) -> str:
    """Escapa caracteres especiales para usarlos dentro de un literal PDF."""
    return (
        text.replace("\\", "\\\\")
        .replace("(", "\\(")
        .replace(")", "\\)")
        .replace("\r", "")
        .replace("\n", "")
    )


def parse_markdown(path: Path) -> List[Tuple[str, object]]:
    """Interpreta un subconjunto de Markdown y devuelve elementos estructurados."""
    items: List[Tuple[str, object]] = []
    paragraph: List[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            items.append(("paragraph", " ".join(paragraph)))
            paragraph.clear()

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            flush_paragraph()
            items.append(("blank", None))
            continue

        if line.startswith("#"):
            flush_paragraph()
            level = len(line) - len(line.lstrip("#"))
            text = line[level:].strip()
            items.append(("heading", (level, text)))
        elif line.startswith("- "):
            flush_paragraph()
            items.append(("bullet", line[2:].strip()))
        else:
            paragraph.append(line.strip())

    flush_paragraph()
    return items


def layout_items(items: List[Tuple[str, object]]) -> List[List[Tuple[str, float, float, float, str]]]:
    """Convierte elementos estructurados en líneas distribuidas por páginas."""
    pages: List[List[Tuple[str, float, float, float, str]]] = [[]]
    current_y = PAGE_HEIGHT - TOP_MARGIN

    def new_page() -> None:
        nonlocal current_y
        pages.append([])
        current_y = PAGE_HEIGHT - TOP_MARGIN

    def ensure_space(amount: float) -> None:
        nonlocal current_y
        if current_y - amount < BOTTOM_MARGIN:
            new_page()

    def add_spacing(amount: float) -> None:
        nonlocal current_y
        if amount <= 0:
            return
        ensure_space(amount)
        current_y -= amount

    def add_line(font: str, size: float, text: str, indent: float = 0.0) -> None:
        nonlocal current_y
        leading = size + 4
        ensure_space(leading)
        current_y -= leading
        pages[-1].append((font, size, LEFT_MARGIN + indent, current_y, text))

    for item_type, payload in items:
        if item_type == "heading":
            level, text = payload  # type: ignore[misc]
            if level <= 1:
                font, size, after = "F2", 20.0, 10.0
            elif level == 2:
                font, size, after = "F2", 16.0, 8.0
            else:
                font, size, after = "F2", 13.0, 6.0
            add_line(font, size, text)
            add_spacing(after)
        elif item_type == "paragraph":
            paragraph_text = payload  # type: ignore[assignment]
            wrapped = textwrap.wrap(paragraph_text, width=90)
            for line in wrapped:
                add_line("F1", 11.0, line)
            add_spacing(8.0)
        elif item_type == "bullet":
            bullet_text = payload  # type: ignore[assignment]
            wrapped = textwrap.wrap(bullet_text, width=80)
            if wrapped:
                first, rest = wrapped[0], wrapped[1:]
                add_line("F1", 11.0, f"- {first}", indent=12.0)
                for cont in rest:
                    add_line("F1", 11.0, cont, indent=24.0)
            else:
                add_line("F1", 11.0, "-", indent=12.0)
            add_spacing(6.0)
        elif item_type == "blank":
            add_spacing(6.0)

    return pages


def build_pdf(pages: List[List[Tuple[str, float, float, float, str]]], output_path: Path) -> None:
    """Construye el archivo PDF utilizando objetos PDF básicos."""
    objects: List[bytes | None] = [None]  # Índice 0 sin usar

    def new_object(content: bytes | None = None) -> int:
        objects.append(content)
        return len(objects) - 1

    def set_object(obj_num: int, content: bytes) -> None:
        objects[obj_num] = content

    font_regular = new_object(
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
    )
    font_bold = new_object(
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>"
    )

    content_objects: List[int] = []
    for page in pages:
        content_lines = []
        for font, size, x, y, text in page:
            escaped = pdf_escape(text)
            content_lines.append(
                f"BT /{font} {size:.2f} Tf 1 0 0 1 {x:.2f} {y:.2f} Tm ({escaped}) Tj ET"
            )
        stream_data = "\n".join(content_lines).encode("latin-1")
        stream_object = new_object()
        set_object(
            stream_object,
            b"<< /Length "
            + str(len(stream_data)).encode("latin-1")
            + b" >>\nstream\n"
            + stream_data
            + b"\nendstream",
        )
        content_objects.append(stream_object)

    page_objects: List[int] = [new_object() for _ in pages]
    pages_object = new_object()
    catalog_object = new_object()

    for page_obj, content_obj in zip(page_objects, content_objects):
        page_dict = (
            f"<< /Type /Page /Parent {pages_object} 0 R /MediaBox [0 0 {PAGE_WIDTH} {PAGE_HEIGHT}] "
            f"/Contents {content_obj} 0 R /Resources << /Font << /F1 {font_regular} 0 R /F2 {font_bold} 0 R >> >> >>"
        ).encode("latin-1")
        set_object(page_obj, page_dict)

    kids = " ".join(f"{obj} 0 R" for obj in page_objects)
    set_object(
        pages_object,
        f"<< /Type /Pages /Kids [{kids}] /Count {len(page_objects)} >>".encode("latin-1"),
    )
    set_object(
        catalog_object,
        f"<< /Type /Catalog /Pages {pages_object} 0 R >>".encode("latin-1"),
    )

    with output_path.open("wb") as f:
        f.write(b"%PDF-1.4\n%\xFF\xFF\xFF\xFF\n")
        offsets: List[int] = []
        for index, obj in enumerate(objects[1:], start=1):
            if obj is None:
                raise ValueError(f"Objeto PDF {index} sin contenido")
            offsets.append(f.tell())
            f.write(f"{index} 0 obj\n".encode("latin-1"))
            f.write(obj)
            f.write(b"\nendobj\n")

        xref_pos = f.tell()
        f.write(f"xref\n0 {len(objects)}\n".encode("latin-1"))
        f.write(b"0000000000 65535 f \n")
        for offset in offsets:
            f.write(f"{offset:010} 00000 n \n".encode("latin-1"))
        f.write(b"trailer\n")
        f.write(
            f"<< /Size {len(objects)} /Root {catalog_object} 0 R >>\n".encode("latin-1")
        )
        f.write(b"startxref\n")
        f.write(f"{xref_pos}\n".encode("latin-1"))
        f.write(b"%%EOF")


def main() -> None:
    markdown_path = Path("docs/analisis_mijuego3d.md")
    output_path = Path("docs/analisis_mijuego3d.pdf")
    items = parse_markdown(markdown_path)
    pages = layout_items(items)
    build_pdf(pages, output_path)
    print(f"PDF generado en {output_path}")


if __name__ == "__main__":
    main()
