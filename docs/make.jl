using Documenter, Rx

makedocs(
    modules  = [ Rx ],
    clean    = true,
    sitename = "Rx.jl",
    pages    = [
        "Home"            => "index.md",
        "Getting started" => "getting-started.md",
        "Observables"     => [
            "About observables" => "observables/about.md",
            "Types" => [
                "Function"          => "observables/types/function.md",
                "Single"            => "observables/types/single.md",
                "Array"             => "observables/types/array.md",
                "Error"             => "observables/types/error.md",
                "Never"             => "observables/types/never.md",
                "Completed"         => "observables/types/completed.md",
                "Timer"             => "observables/types/timer.md",
                "Interval"          => "observables/types/interval.md",
                "Proxy"             => "observables/types/proxy.md",
                "File"              => "observables/types/file.md",
                "Combined"          => "observables/types/combined.md",
            ],
            "API"               => "observables/api.md",
        ],
        "Subjects" => [
            "About subjects" => "subjects/about.md"
        ],
        "Actors"     => [
            "About actors"  => "actors/about.md",
            "Types"         => [
                "Lambda"        => "actors/types/lambda.md",
                "Logger"        => "actors/types/logger.md",
                "Async"         => "actors/types/async.md",
                "Void"          => "actors/types/void.md",
            ],
            "API"           => "actors/api.md",
        ],
        "Subscription"    => [
            "About subscriptions" => "teardown/about.md",
            "Types"               => [
                "Void"  => "teardown/types/void.md",
                "Chain" => "teardown/types/chain.md",
            ],
            "API"                 => "teardown/api.md",
        ],
        "Operators"       => [
            "About operators"         => "operators/about.md",
            "Piping"                  => "operators/piping.md",
            "Create a new operator"   => "operators/create-new-operator.md",
            "High-orders Observables" => "operators/high-order.md",
            "Categories"            => [
                "All"            => "operators/all.md",
                "Creation"       => "operators/creation/about.md",
                "Transformation" => [
                    "About transformation operators" => "operators/transformation/about.md",
                    "map"                            => "operators/transformation/map.md",
                    "scan"                           => "operators/transformation/scan.md",
                    "enumerate"                      => "operators/transformation/enumerate.md",
                    "uppercase"                      => "operators/transformation/uppercase.md",
                    "lowercase"                      => "operators/transformation/lowercase.md",
                    "to_array"                       => "operators/transformation/to_array.md",
                ],
                "Filtering" => [
                    "About filtering operators" => "operators/filtering/about.md",
                    "filter"                    => "operators/filtering/filter.md",
                    "some"                      => "operators/filtering/some.md",
                    "take"                      => "operators/filtering/take.md",
                    "first"                     => "operators/filtering/first.md",
                    "last"                      => "operators/filtering/last.md",
                ],
                "Mathematical and Aggregate" => [
                    "About mathematical operators" => "operators/mathematical/about.md",
                    "count"                        => "operators/mathematical/count.md",
                    "max"                          => "operators/mathematical/max.md",
                    "min"                          => "operators/mathematical/min.md",
                    "reduce"                       => "operators/mathematical/reduce.md",
                    "sum"                          => "operators/mathematical/sum.md",
                ],
                "Utility" => [
                    "About utility operators" => "operators/utility/about.md",
                    "tap"                     => "operators/utility/tap.md",
                    "delay"                   => "operators/utility/delay.md",
                ]
            ],
            "API"         => "operators/api.md",
        ],
        "TODO"         => "todo.md",
        "Contributing" => "contributing.md",
        "Utils"        => "utils.md"
    ],
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    )
)
