.PHONY: help docs docs-serve docs-clean test format check-format clean deps deps-docs deps-scripts

# Colors for terminal output
ifdef NO_COLOR
GREEN  :=
YELLOW :=
WHITE  :=
RESET  :=
else
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
endif

# Default target
.DEFAULT_GOAL := help

## Show help for each of the Makefile targets
help:
	@echo ''
	@echo 'PLACEHOLDERNAME_CHANGE_MAKEFILE_LINE_22.jl Makefile ${YELLOW}targets${RESET}:'
	@echo ''
	@echo '${GREEN}Documentation commands:${RESET}'
	@echo '  ${YELLOW}docs${RESET}                 Build the documentation'
	@echo '  ${YELLOW}docs-serve${RESET}           Serve documentation locally for preview in browser'
	@echo '  ${YELLOW}docs-clean${RESET}           Clean the documentation build directory'
	@echo ''
	@echo '${GREEN}Development commands:${RESET}'
	@echo '  ${YELLOW}deps${RESET}                 Install project dependencies'
	@echo '  ${YELLOW}deps-docs${RESET}            Install documentation dependencies'
	@echo '  ${YELLOW}deps-scripts${RESET}         Install script dependencies'
	@echo '  ${YELLOW}test${RESET}                 Run project tests'
	@echo '  ${YELLOW}format${RESET}               Format Julia code'
	@echo '  ${YELLOW}check-format${RESET}         Check Julia code formatting (does not modify files)'
	@echo '  ${YELLOW}clean${RESET}                Clean all generated files'
	@echo ''
	@echo '${GREEN}Help:${RESET}'
	@echo '  ${YELLOW}help${RESET}                 Show this help message'
	@echo ''
	@echo '${GREEN}Environment variables:${RESET}'
	@echo '  ${YELLOW}NO_COLOR${RESET}             Set this variable to any value to disable colored output'
	@echo ''

## Documentation commands:
docs: deps-docs ## Build the documentation
	julia --project=docs/ docs/make.jl

docs-serve: deps-docs ## Serve documentation locally for preview in browser
	julia --project=docs/ -e 'using LiveServer; LiveServer.servedocs(launch_browser=true, port=5678)'

docs-clean: ## Clean the documentation build directory
	rm -rf docs/build

## Development commands:
deps: ## Install project dependencies
	julia --project -e 'using Pkg; Pkg.instantiate()'

deps-docs: ## Install documentation dependencies
	julia --project=docs/ -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'

deps-scripts: ## Install script dependencies
	julia --project=scripts/ -e 'using Pkg; Pkg.instantiate()'

test: deps ## Run project tests
	julia --project -e 'using Pkg; Pkg.test()'

format: deps-scripts ## Format Julia code
	julia --project=scripts/ scripts/formatter.jl --overwrite

check-format: deps-scripts ## Check Julia code formatting (does not modify files)
	julia --project=scripts/ scripts/formatter.jl

clean: docs-clean ## Clean all generated files
	rm -rf .julia/compiled
