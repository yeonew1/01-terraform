#!/bin/bash
echo "<h1>Hello, World"</h1>" > index.html
nohup busybox -f -p "${server_port}" &
