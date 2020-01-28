using Documenter, Rx

makedocs(
    modules  = [ Rx ],
    clean    = true,
    sitename = "Rx.jl",
    pages    = [
        "Home"            => "index.md",
        "Getting started" => "getting-started.md",
        "Manual"     => [
            "Observable"   => "observables/about.md",
            "Actor"        => "actors/about.md",
            "Subscription" => "teardown/about.md",
            "Operator"     => "operators/about.md",
            "Subject"      => "subjects/about.md",
        ],
        "Library" => [
            "Observables" => [
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
                "Connectable"       => "observables/types/connectable.md",
            ],
            "Actors" => [
                "Lambda"        => "actors/types/lambda.md",
                "Logger"        => "actors/types/logger.md",
                "Async"         => "actors/types/async.md",
                "Sync"          => "actors/types/sync.md",
                "Keep"          => "actors/types/keep.md",
                "Void"          => "actors/types/void.md",
            ],
            "Subscriptions" => [
                "Void"  => "teardown/types/void.md",
                "Chain" => "teardown/types/chain.md",
            ],
            "Operators" => [
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
                "Error handling" => [
                    "About error handling operators" => "operators/errors/about.md",
                    "catch_error"                    => "operators/errors/catch_error.md",
                    "rerun"                          => "operators/errors/rerun.md"
                ],
                "Utility" => [
                    "About utility operators" => "operators/utility/about.md",
                    "tap"                     => "operators/utility/tap.md",
                    "delay"                   => "operators/utility/delay.md",
                    "safe"                    => "operators/utility/safe.md",
                ]
            ],
            "Subjects" => [
                "Behavior" => "subjects/types/behavior.md",
                "Replay"   => "subjects/types/replay.md",
            ]
        ],
        "API"          => [
            "Observables"  => "api/observables.md",
            "Actors"       => "api/actors.md",
            "Teardown"     => "api/teardown.md",
            "Operators"    => "api/operators.md",
            "Subjects"     => "api/subjects.md"
        ],
        "TODO"         => "todo.md",
        "Contributing" => "contributing.md",
        "Utils"        => "utils.md"
    ],
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    )
)
