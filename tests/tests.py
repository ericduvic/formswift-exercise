import os
from unittest import TestCase

import requests

ENDPOINT_URL = os.environ.get("ENDPOINT_URL")

class HelloWorldTest(TestCase):
    def test_endpoint(self):
        url = f"{ENDPOINT_URL}"
        response = requests.get(url)self.assertEqual(res.status_code, 200)
        self.assertEqual(res.text, "Hello World!")