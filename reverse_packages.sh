#!/bin/bash

find ./docker-images -type f -name "*.zip" -exec mv '{}' ./software/ \;
