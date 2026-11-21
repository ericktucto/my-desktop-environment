"""Pruebas de scripts/theme.py (paleta, combinaciones y colores de la shell): python3 -m unittest tests/theme/test_theme.py"""
import importlib.util
import os
import tempfile
import unittest

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("theme", os.path.join(HERE, "..", "..", "scripts", "theme.py"))
T = importlib.util.module_from_spec(spec)
spec.loader.exec_module(T)

# Los colores de un wallpaper del EVA-01 y cuánto ocupa cada uno
EVA = [
    ("#241436", 30), ("#1a1025", 16), ("#0d0d12", 14), ("#14141a", 10), ("#5b2c83", 8), ("#6d3b9e", 5),
    ("#78d64b", 2), ("#64dd17", 4), ("#f39c12", 3), ("#e67e22", 3), ("#e6e1ec", 3), ("#b8b2c4", 2),
]


def make_image(colors, name):
    """Una imagen de 100×100 con franjas verticales de esos colores, en esas proporciones."""
    im = Image.new("RGB", (100, 100))
    x = 0
    total = sum(w for _, w in colors)
    for hx, w in colors:
        n = max(1, round(100 * w / total))
        im.paste(rgb_tuple(hx), (x, 0, min(100, x + n), 100))
        x += n
    path = os.path.join(tempfile.gettempdir(), name)
    im.save(path)
    return path


def rgb_tuple(h):
    return tuple(int(h[i : i + 2], 16) for i in (1, 3, 5))


def palette_and_combos(colors, name):
    path = make_image(colors, name)
    pal = T.extract_palette(path)
    return pal, T.combos_of(pal)


class Eva(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pal, cls.combos = palette_and_combos(EVA, "stixshell-test-eva.png")

    def test_palette_has_the_real_colors(self):
        hexes = {p["hex"] for p in self.pal}
        self.assertLessEqual(len(self.pal), 12)
        for c in ("#241436", "#5b2c83", "#64dd17", "#f39c12"):
            self.assertIn(c, hexes)

    def test_first_is_purple_and_green(self):
        c = self.combos[0]
        self.assertEqual(c["name"], "Lila + verde")
        self.assertEqual(c["accent"], "#64dd17")

    def test_there_are_color_and_neutral_combos(self):
        self.assertLessEqual(len(self.combos), 6)
        self.assertTrue(any(c["bg"] == "none" for c in self.combos))
        self.assertTrue(any(c["name"].startswith("Verde") for c in self.combos))
        self.assertEqual(len({c["id"] for c in self.combos}), len(self.combos))

    def test_intense_uses_the_dark_of_the_image(self):
        c = self.combos[0]
        self.assertEqual(T.shell_colors(c["fam"], c["accent"], "vivid")["island"], "#241436")

    def test_contrasts(self):
        for c in self.combos:
            for tint in T.TINTS:
                s = T.shell_colors(c["fam"], c["accent"], tint)
                island = s.get("island", T.SYS_ISLAND)
                if "text" in s:
                    self.assertGreaterEqual(T.contrast(s["text"], island), 7.0, (c["name"], tint))
                self.assertGreaterEqual(T.contrast(s["primary"], island), 3.0 - 0.05, (c["name"], tint))

    def test_dark_green_background_lightens_the_purple_accent(self):
        c = next(c for c in self.combos if c["name"].startswith("Verde + lila"))
        s = T.shell_colors(c["fam"], c["accent"], "vivid")
        self.assertGreaterEqual(T.contrast(s["primary"], s["island"]), 2.95)

    def test_black_is_readable_on_the_green(self):
        s = T.shell_colors(self.combos[0]["fam"], self.combos[0]["accent"], "vivid")
        self.assertGreaterEqual(T.contrast(s["black"], s["primary"]), 7.0)
        self.assertLess(T.contrast("#ffffff", s["primary"]), 3.0)

    def test_sutil_is_darker_and_less_tinted(self):
        c = self.combos[0]
        a, b = (T.oklch(T.shell_colors(c["fam"], c["accent"], t)["island"]) for t in ("tinted", "vivid"))
        self.assertLess(a[0], b[0])
        self.assertLess(a[1], b[1])

    def test_pick_combo(self):
        self.assertEqual(T.pick_combo(self.combos, "")["id"], self.combos[0]["id"])
        self.assertEqual(T.pick_combo(self.combos, "neutral")["bg"], "none")
        self.assertEqual(T.pick_combo(self.combos, self.combos[2]["id"])["id"], self.combos[2]["id"])
        # un id que ya no existe: el más parecido
        near = self.combos[1]["bg"].lstrip("#") + "|" + "64dd18"
        self.assertEqual(T.pick_combo(self.combos, near)["bg"], self.combos[1]["bg"])
        self.assertEqual(T.pick_combo(self.combos, "basura")["id"], self.combos[0]["id"])


class Rare(unittest.TestCase):
    def test_gray_image_only_neutral_with_blue(self):
        _, combos = palette_and_combos([("#202020", 5), ("#808080", 3), ("#e0e0e0", 2)], "stixshell-test-gray.png")
        self.assertTrue(combos)
        self.assertTrue(all(c["bg"] == "none" for c in combos))
        self.assertEqual(combos[0]["name"], "Neutro + azul")

    def test_single_hue_image(self):
        _, combos = palette_and_combos([("#081825", 40), ("#132636", 30), ("#1d3a4b", 20), ("#608273", 10)], "stixshell-test-mono.png")
        self.assertNotEqual(combos[0]["bg"], "none")
        s = T.shell_colors(combos[0]["fam"], combos[0]["accent"], "vivid")
        self.assertGreaterEqual(T.contrast(s["primary"], s["island"]), 2.95)
        self.assertTrue(any(c["bg"] == "none" for c in combos))


class Color(unittest.TestCase):
    def test_oklch_roundtrip(self):
        for h in ("#241436", "#64dd17", "#2979ff", "#808080"):
            L, C, H = T.oklch(h)
            back = T.from_oklch(L, C, H)
            self.assertLess(sum(abs(a - b) for a, b in zip(T.rgb(h), T.rgb(back))), 4, h)

    def test_gamut_clip_keeps_lightness(self):
        out = T.from_oklch(0.24, 0.3, 138)
        self.assertAlmostEqual(T.oklch(out)[0], 0.24, delta=0.02)


if __name__ == "__main__":
    unittest.main()
