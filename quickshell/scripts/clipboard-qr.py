#!/usr/bin/env python3
"""Código QR del texto que llega por la entrada estándar.

Uso: clipboard-qr.py SALIDA.png [MAX_BYTES]

Si el texto tiene algo más que ASCII (tildes, ñ, comillas…), se antepone un segmento ECI que declara UTF-8.
Sin él, los lectores adivinan la codificación y a veces leen "canci籀n" en vez de "canción".
`qrencode` no sabe escribir ECI, por eso se usa la librería `qrcode` de Python (python3-qrcode, con Pillow).

Códigos de salida: 0 = listo, 3 = el texto no cabe en un QR, 2 = uso incorrecto.
"""
import sys

import qrcode
from qrcode import exceptions, util
from qrcode.constants import ERROR_CORRECT_L

ECI_MODE = 0b0111  # indicador de modo ECI (ISO 18004)
ECI_UTF8 = 26


class EciSegment:
    """Segmento ECI: 4 bits de modo + 8 bits con el designador, sin campo de longitud."""

    mode = ECI_MODE

    def __len__(self):
        return 0

    def write(self, buffer):
        buffer.put(ECI_UTF8, 8)


# La librería no conoce el modo ECI: se le dice que no lleva campo de longitud
for _sizes in (util.MODE_SIZE_SMALL, util.MODE_SIZE_MEDIUM, util.MODE_SIZE_LARGE):
    _sizes[ECI_MODE] = 0
_length_in_bits = util.length_in_bits
util.length_in_bits = lambda mode, version: 0 if mode == ECI_MODE else _length_in_bits(mode, version)


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    out = sys.argv[1]
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    raw = sys.stdin.buffer.read()
    if limit and len(raw) > limit:
        return 3

    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_L, box_size=8, border=2)
    if raw.isascii():
        qr.add_data(raw)
    else:
        qr.data_list = [EciSegment(), util.QRData(raw, mode=util.MODE_8BIT_BYTE, check_data=False)]
        qr.data_cache = None
    try:
        qr.make(fit=True)
    except exceptions.DataOverflowError:
        return 3
    qr.make_image(fill_color="black", back_color="white").save(out)
    return 0


sys.exit(main())
