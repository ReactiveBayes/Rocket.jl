using JuliaFormatter
using ArgParse

s = ArgParseSettings()

@add_arg_table s begin
    "--overwrite"
    help = "Overwrite the files with the formatted code"
    action = :store_true
    default = false
end

args = parse_args(ARGS, s)
overwrite = args["overwrite"]
projectroot = joinpath(@__DIR__, "..")

passed = format(projectroot, verbose = true, overwrite = overwrite)

if !passed && !overwrite
    @error "JuliaFormatter check has failed. Run `make format` from the main directory and commit your changes to fix code style."
    exit(1)
elseif !passed && overwrite
    @info "JuliaFormatter has overwritten files according to style guidelines"
elseif passed
    @info "Codestyle from JuliaFormatted checks have passed"
end
