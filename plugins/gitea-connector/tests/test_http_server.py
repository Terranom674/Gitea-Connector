import importlib.util
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
SPEC = importlib.util.spec_from_file_location("gitea_http_server", ROOT / "http_server.py")
http_server = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(http_server)


class HttpServerTests(unittest.TestCase):
    def test_http_token_is_optional(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertTrue(http_server._authorized(None))

    def test_http_token_uses_bearer_auth(self):
        with patch.dict(os.environ, {"MCP_HTTP_TOKEN": "secret"}, clear=True):
            self.assertFalse(http_server._authorized(None))
            self.assertFalse(http_server._authorized("Bearer wrong"))
            self.assertTrue(http_server._authorized("Bearer secret"))

    def test_allowed_origins_are_explicit(self):
        with patch.dict(os.environ, {"MCP_ALLOWED_ORIGINS": "https://example.com, https://chat.example"}, clear=True):
            self.assertEqual(
                http_server._allowed_origins(),
                {"https://example.com", "https://chat.example"},
            )


if __name__ == "__main__":
    unittest.main()
