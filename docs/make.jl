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
            "Array"             => "observables/types/array.md",
            "Error"             => "observables/types/error.md",
            "Never"             => "observables/types/never.md",
            "Timer"             => "observables/types/timer.md",
            "Interval"          => "observables/types/interval.md",
            "Proxy"             => "observables/types/proxy.md",
            "API"               => "observables/api.md",
        ],
        "Actors"     => [
            "About actors"  => "actors/about.md",
            "Lambda"        => "actors/types/lambda.md",
            "Logger"        => "actors/types/logger.md",
            "Async"         => "actors/types/async.md",
            "Void"          => "actors/types/void.md",
            "API"           => "actors/api.md",
        ],
        "Subscription"    => [
            "About subscriptions" => "teardown/about.md",
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
        "TODO" => "todo.md"
    ],
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    )
)
