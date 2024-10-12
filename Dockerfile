# This ARG is for the version of the Crystal image to use - the "latest" tag is overwritable via the .crystal-version file
ARG CRYSTAL_VERSION="latest"

FROM crystallang/crystal:${CRYSTAL_VERSION} AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y unzip wget

# install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# copy the crystal version file
COPY .crystal-version .crystal-version

# copy core scripts
COPY script/ script/

# copy all vendored dependencies
COPY vendor/shards/cache/ vendor/shards/cache/

# copy shard files
COPY shard.lock shard.lock
COPY shard.yml shard.yml

# bootstrap the project
RUN script/bootstrap --production

# copy all source files (ensure to use a .dockerignore file for efficient copying)
COPY . .

# build the project
RUN script/build --production

FROM crystallang/crystal:${CRYSTAL_VERSION}

# add curl for healthchecks
RUN apt-get update && apt-get install -y curl

# create a non-root user for security
RUN useradd -m nonroot
USER nonroot

WORKDIR /app

######### CUSTOM SECTION PER PROJECT #########

# copy the binary from the builder stage
COPY --from=builder --chown=nonroot:nonroot /app/bin/crystal-base-template .

# run the binary (adds two numbers together)
CMD ["./crystal-base-template", "234122314", "1234"]
