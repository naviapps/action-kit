SWIFT_FORMAT_PATHS := Sources Tests Package.swift
SWIFT_TEST_FLAGS := -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors

.DEFAULT_GOAL := help

.PHONY: help check format lint test

help:
	@awk -F: '/^[a-zA-Z0-9_-]+:/ { print $$1 }' $(MAKEFILE_LIST)

check: lint test

format:
	swift format format --recursive --in-place $(SWIFT_FORMAT_PATHS)

lint:
	swift format lint --recursive --strict $(SWIFT_FORMAT_PATHS)

test:
	swift test $(SWIFT_TEST_FLAGS)
