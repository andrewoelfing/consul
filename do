#!/usr/bin/env bash

source .plsdo.sh

banner="Consul - project tasks"
_plsdo_help_task_name_width=22


help[godoc]="Run godoc locally to read package documentation."
godoc() {
    local url; url="http://localhost:6060/pkg/$(go list)/${1-}"
    command -v xdg-open && xdg-open "$url" &
    command -v open && open "$url" &
    command godoc -http=:6060
}


help[lint-shellcheck]="Run 'shellcheck' on all files."
lint-shellcheck() {
    if ! command -v shellcheck > /dev/null; then
        _plsdo_error "Missing shellcheck."
        _plsdo_error "See https://github.com/koalaman/shellcheck#installing"
        return 3
    fi
    # TODO: add other files
    shellcheck --severity=style --external-sources ./do .dolib/*
}

help[go-mod-tidy]="Run 'go mod tidy' on all go modules."
go-mod-tidy() {
    echo "Running go mod tidy"
    go mod tidy
    (cd sdk && go mod tidy)
    (cd api && go mod tidy)
}

help[update-vendor]="Update ./vendor after making changing dependencies."
go-mod-vendor() {
    go-mod-tidy
    echo "Running go mod vendor"
    go mod vendor
    echo "Removing vendoring of our own nested modules"
    rm -rf vendor/github.com/hashicorp/consul
    grep -v "hashicorp/consul/" < vendor/modules.txt > vendor/modules.txt.new
    mv vendor/modules.txt.new vendor/modules.txt
}

help[lint]="Run 'golangci-lint' on all files.

Environment Variables:

  GOTAGS - used as Go build tags
"
lint() {
    ${GOTAGS=}
    echo "Running go golangci-lint"
    golangci-lint run --build-tags "${GOTAGS}"
    (cd api && golangci-lint run --build-tags "${GOTAGS}")
    (cd sdk && golangci-lint run --build-tags "${GOTAGS}")
}

help[binary]="Build the consul binary.

Defaults to building a binary for the local GOOS and GOARCH.

TODO: env vars
"
binary() {
    local target=bin/consul
    if [ -n "${GOOS-}" ]; then
        target="bin/consul-${GOOS}-${GOARCH}"
    fi
    go build -o "$target" -ldflags "$(_go_build_ldflags)" .
}

_go_build_ldflags() {
    local commit; commit=$(git rev-parse --short HEAD)
    local dirty;   [ -z "$(git status --porcelain)" ] || dirty="+CHANGES"
    local desc;   desc="$(git describe --tags --always --match 'v*')"
    local import=github.com/hashicorp/consul/version
    echo "-X ${import}.GitCommit=${commit}${dirty} -X ${import}.GitDescribe=${desc}"
}

help[binary-all]="Build the consul binary for all platforms."
binary-all() {
    # TODO: use parallel
    GOOS=linux  GOARCH=amd64 binary
    GOOS=darwin GOARCH=amd64 binary
}

source .dolib/ent.sh
source .dolib/protobuf.sh

_plsdo_run "$@"
