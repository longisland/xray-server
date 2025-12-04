#!/bin/sh
nginx &
exec xray run -config /etc/xray/config.json
