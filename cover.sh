#!/usr/bin/env bash

set -e # abort on error

go get github.com/wadey/gocovmerge
go install github.com/wadey/gocovmerge
go get github.com/axw/gocov/gocov
go install github.com/axw/gocov/gocov
go get github.com/AlekSi/gocov-xml
go install github.com/AlekSi/gocov-xml

export PKGS=$(glide novendor)

# We only cover packages with source code e.g. the integration tests folder only contains _test.go files
export PKGS_COV=$(go list -f '{{if (len .GoFiles)}}{{.ImportPath}}
{{end}}' $PKGS | paste -sd "," -)

# For each package that contains tests, run that package's' tests and capture coverage for all packages. Rinse repeat.
# Note: the Go coverage tool is geared towards measuring coverage of an individual package from its tests.
# Also ensure we don't get clashes from identically named packages
rm -f *.cov
go list -f '{{if or (len .TestGoFiles) (len .XTestGoFiles)}}go test -covermode set -coverprofile {{.Name}}_{{len .Imports}}_{{len .Deps}}.cov -coverpkg $PKGS_COV {{.ImportPath}}{{end}}' $PKGS | xargs -I {} bash -c {}

# Merge all the coverage files together
echo Merging `ls *.cov` into coverage.cov
gocovmerge `ls *.cov` > coverage.cov

# Transform the results to the Cobertura format
gocov convert coverage.cov | gocov-xml > coverage.cobertura
