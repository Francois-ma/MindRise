#!/usr/bin/env bash
set -o errexit

exec gunicorn config.wsgi:application --config gunicorn.conf.py
