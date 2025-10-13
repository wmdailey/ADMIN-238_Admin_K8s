# Used in the K8s course as a backend for exercises
#

import time
import logging
import os.path
from flask import Flask

logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)


@app.route("/")
def hello():
    file_path = '/var/log/backend.log'
    if os.path.exists(file_path):
        with open(file_path) as data:
            return data.read()
    else:
        return f"File not found: {file_path}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
