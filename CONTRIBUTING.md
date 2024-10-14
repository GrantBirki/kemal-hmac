# Contributing

## Dependency Vendoring 📦

This project uses a highly opinionated dependency vendoring strategy. This strategy is designed to ensure that you own your availability and can always build your project. This strategy is as follows:

1. All dependencies are vendored into the project into the `vendor/shards/cache/` directory
2. The `vendor/shards/cache/` directory is committed to the repository to ensure that all dependencies are available to build the project forever. These shards are in `<name>-<version>.shard` format and take inspiration from a Ruby "Gem" when they are vendored.
3. The `script/bootstrap` command installs vendored dependencies with `SHARDS_CACHE_PATH="vendor/.cache/shards" shards install ...` to ensure that each project has its own cache and does not interfere with other crystal projects
4. The `script/update` command will re-vendor all dependencies and update the vendored dependencies in the repository. This will always result is changes to all dependencies, even if the version has not changed. This is to ensure that the vendored dependencies are always up to date and can be used to build the project.

## Testing 🧪

- All code must have unit tests
- 100% code coverage is enforced
- Acceptance tests are used to test the application as a whole

## Development Commands 💻

### Setup

Run the following command to bootstrap this repository and install all dependencies:

```bash
script/bootstrap
```

### Updating Dependencies

Run the following command to update all dependencies (shards):

```bash
script/update
```

### Testing

Run the following command to run all unit tests:

```bash
script/test
```

Run the following command to run all acceptance tests:

```bash
script/acceptance
```

### Linting and Formatting

Run the following command to lint the project:

```bash
script/lint

script/lint --fix # to fix any linting errors
```

Run the following command to format the project:

```bash
script/format

script/format --check # to check if any files need to be formatted without formatting them
```

This will lint and format the project, followed by running all unit tests.

## Contributing 🤝

To get started quickly with this project, you will need the following installed:

- [crystal](https://github.com/crystal-lang/crystal) ([crenv](https://github.com/crenv/crenv) is suggested)
- [docker compose](https://docs.docker.com/compose/)
- [bash](https://www.gnu.org/software/bash/)
- [jq](https://github.com/jqlang/jq)
- [yq](https://github.com/mikefarah/yq)
- [zip](https://formulae.brew.sh/formula/zip)

To get your repo setup for development do the following:

1. Clone the repo
2. Ensure your version of crystal matches the version in [`.crystal-version`](.crystal-version)
3. Run the following command:

  ```bash
  script/bootstrap
  ```

1. Congrats you're ready to start developing!
2. Write some code
3. Run `script/test` to run unit tests and ensure your changes work
4. Run `script/lint` to ensure your changes follow the style guide
5. Run `script/format` to ensure your changes are formatted correctly
6. Run `script/acceptance` to run the acceptance test suite
7. Open a pull request 🎉
