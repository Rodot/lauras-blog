#!/bin/bash

# Kill any process running on port 54321
fuser -k 54321/tcp 2>/dev/null || true

npm install
npm run dev -- --port 54321
