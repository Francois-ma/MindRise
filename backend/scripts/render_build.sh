#!/usr/bin/env bash
set -o errexit

python -m pip install --upgrade pip
pip install -r requirements.txt
python manage.py migrate --noinput
python manage.py bootstrap_admin --noinput
python manage.py collectstatic --noinput
