#!/bin/bash

find . -type f -name "*.zip" -exec mv '{}' ./software/ \;
