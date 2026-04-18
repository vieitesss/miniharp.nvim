_default:
	just --list

release version:
	#!/usr/bin/env bash
	tag="{{version}}"
	if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		echo "Version must look like v0.1.0" >&2
		exit 1
	fi
	branch="$$(git branch --show-current)"
	if [[ "$branch" != "main" ]]; then
		echo "Release tags must be created from main. Current branch: $branch" >&2
		exit 1
	fi
	if git rev-parse "$tag" >/dev/null 2>&1; then
		echo "Tag already exists: $tag" >&2
		exit 1
	fi
	git tag "$tag"
	git push origin "$tag"
