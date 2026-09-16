"""Decode the production binary /info response with an independent plist reader.
Run: python3 tests/host/test_airplay_info.py
"""
import ctypes
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AirPlayInfoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        lib = Path(cls.tmp.name) / 'plist.so'
        subprocess.run(['cc', '-shared', '-fPIC', '-std=c11', '-Wall', '-Wextra',
                        '-Werror', '-I', str(ROOT / 'tests/host/stubs'),
                        '-I', str(ROOT / 'main/plist'),
                        '-I', str(ROOT / 'main/network'),
                        str(ROOT / 'main/plist/bplist_builder.c'), '-o', str(lib)],
                       check=True)
        cls.lib = ctypes.CDLL(str(lib))
        cls.build = cls.lib.bplist_build_info_response
        cls.build.restype = ctypes.c_size_t
        cls.build.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_char_p,
                             ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t,
                             ctypes.c_uint64, ctypes.c_int64]

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def build_info(self, name, capacity=1024):
        out = ctypes.create_string_buffer(b'\xa5' * 2048, 2048)
        key = ctypes.create_string_buffer(bytes(range(32)))
        size = self.build(out, capacity, b'28:84:85:BB:58:50', name, key, 32, 0, 2)
        self.assertEqual(out.raw[capacity:], b'\xa5' * (2048-capacity))
        return size, out.raw[:size]

    def test_sonos_speaker_model(self):
        size, data = self.build_info(b'Office')
        self.assertGreater(size, 0)
        self.assertEqual(plistlib.loads(data)['model'], 'One')

    def test_unicode_names(self):
        for name in ('Office', 'Büro', 'ÄÖÜ äöü ß', 'Küche 🎵', '客厅', 'ü'*32, ''):
            with self.subTest(name=name):
                size, data = self.build_info(name.encode())
                self.assertGreater(size, 0)
                self.assertEqual(plistlib.loads(data)['name'], name)

    def test_invalid_utf8(self):
        for name in (b'\xc3', b'\xc3x', b'\x80', b'\xc0\xaf',
                     b'\xed\xa0\x80', b'\xf4\x90\x80\x80'):
            with self.subTest(name=name):
                self.assertEqual(self.build_info(name)[0], 0)

    def test_capacity(self):
        size, _ = self.build_info('Büro 🎵'.encode())
        self.assertGreater(size, 0)
        for capacity in (0, 511, size-1):
            self.assertEqual(self.build_info('Büro 🎵'.encode(), capacity)[0], 0)
        self.assertEqual(self.build_info('Büro 🎵'.encode(), size)[0], size)


if __name__ == '__main__':
    unittest.main()
