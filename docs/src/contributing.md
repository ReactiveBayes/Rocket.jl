# Contribution guidelines

We welcome all possible contributors. This page details the some of the guidelines that should be followed when contributing to this package.

## Reporting bugs

We track bugs using [GitHub issues](https://github.com/reactivebayes/Rocket.jl/issues). We encourage you to write complete, specific, reproducible bug reports. Mention the versions of Julia and Rocket.jl for which you observe unexpected behavior. Please provide a concise description of the problem and complement it with code snippets, test cases, screenshots, tracebacks or any other information that you consider relevant. This will help us to replicate the problem and narrow the search space for solutions.

## Suggesting features

We welcome new feature proposals. However, before submitting a feature request, consider a few things:

- Does the feature require changes in the core Rocket.jl code? If it doesn't (for example, you would like to add a operator for a particular application), consider making a separate repository for your extensions.
- If you would like to add an implementation of a feature that changes a lot in the core Rocket.jl code, please open an issue on GitHub and describe your proposal first. This will allow us to discuss your proposal with you before you invest your time in implementing something that may be difficult to merge later on.

## Contributing code

### Installing Rocket

We suggest that you use the `dev` command from the new Julia package manager to
install Rocket.jl for development purposes. To work on your fork of Rocket.jl, use your fork's URL address in the `dev` command, for example:

```jl
] dev git@github.com:your_username/Rocket.jl.git
```

The `dev` command clones Rocket.jl to `~/.julia/dev/Rocket`. All local
changes to Rocket code will be reflected in imported code.

!!! note
    It is also might be useful to install [Revise.jl](https://github.com/timholy/Revise.jl) package as it allows you to modify code and use the changes without restarting Julia.

### Committing code

We use the standard [GitHub Flow](https://guides.github.com/introduction/flow/) workflow where all contributions are added through pull requests. In order to contribute, first [fork](https://guides.github.com/activities/forking/) the repository, then commit your contributions to your fork, and then create a pull request on the `master` branch of the Rocket.jl repository.

Before opening a pull request, please make sure that all tests pass without
failing! All demos (can be found in `/demo/` directory) have to run without errors as well.

### Style conventions

We use default [Julia style guide](https://docs.julialang.org/en/v1/manual/style-guide/index.html). We list here a few important points and our modifications to the Julia style guide:

- Use 4 spaces for indentation
- Type names use `UpperCamelCase`. For example: `ArrayObservable`, `MapOperator`, etc..
- Function names are `lowercase` with underscores, when necessary. For example: `next!`, `subscribe!`, `as_actor`, etc..
- Variable names and function arguments use `snake_case`
- The name of a method that modifies its argument(s) must end in `!`

### Unit tests

We use the test-driven development (TDD) methodology for Rocket.jl development. The test coverage should be as complete as possible. Please make sure that you write tests for each piece of code that you want to add.

All unit tests are located in the `/test/` directory. The `/test/` directory follows the structure of the `/src/` directory. Each test file should have following filename format: `test_*.jl`. Some tests are also present in `jldoctest` docs annotations directly in the source code.
See [Julia's documentation](https://docs.julialang.org/en/v1/manual/documentation/index.html) about doctests.

The tests can be evaluated by running following command in the Julia REPL:

```julia
] test Rocket
```
