default:
    just --list

build_pebbletool tag sdk_version="4.6-rc2" sdk_core="latest":
    #!/bin/fish
    # Set pipefail to ensure that the build fails if any of the commands fail
    set -x pipefail
    # Set the DEVCONTAINER_METADATA environment variable to the contents of the devcontainer_metadata.yaml file
    set -x DEVCONTAINER_METADATA (yq --output-format json --indent 0 e devcontainer_metadata.yaml)
    set -x CONTAINER_VERSION (yq e '.version' container_metadata.yaml)
    set -x SDK_URL (yq e '.pebble_sdk."{{ sdk_version }}"' download_urls.yaml)
    set -x SDK_VERSION {{ sdk_version }}
    set -x SDK_CORE {{ sdk_core }}
    echo "Building container with SDK version $SDK_VERSION and core $SDK_CORE"
    echo "Using SDK URL $SDK_URL"

    if test "$SDK_CORE" = "latest"
        if test "$SDK_VERSION" = "4.5"
            echo "Using latest core is not supported for SDK version 4.5"
            exit 1
        end
    end

    if test "$SDK_CORE" != "latest"
        set -x SDK_CORE (yq e '.pebble_core."{{ sdk_core }}"' download_urls.yaml)
    end
    
    
    buildah build -f Containerfile.pebbletool -t ghcr.io/flyinpancake/pebble-devcontainer:legacy-{{ sdk_version }}-{{ sdk_core }}-{{ tag }} \
        --build-arg DEVCONTAINER_METADATA=$DEVCONTAINER_METADATA \
        --build-arg CREATED_TIMESTAMP=(date -u +"%Y-%m-%dT%H:%M:%SZ") \
        --build-arg VCS_REF=(git rev-parse HEAD) \
        --build-arg CONTAINER_VERSION=$CONTAINER_VERSION \
        --build-arg SDK_URL=$SDK_URL \
        --build-arg SDK_VERSION=$SDK_VERSION \
        --build-arg SDK_CORE=$SDK_CORE \
        .
