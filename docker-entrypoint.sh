#!/bin/bash

. $VENV_PATH/bin/activate

poetry run jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root
