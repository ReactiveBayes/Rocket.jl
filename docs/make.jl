using Documenter, Rx

makedocs(
    modules  = [ Rx ],
    clean    = true,
    sitename = "Rx.jl",
    pages    = [
        "Home"            => "index.md",
        "Getting started" => "getting-started.md",
        "Observables"     => [
            "About observables" => "observables/about.md"
        ],
        "Subscription"    => "teardown/about.md",
        "Operators"       => [
            "About operators"         => "operators/about.md",
            "Piping"                  => "operators/piping.md",
            "Create a new operator"   => "operators/create-new-operator.md",
            "High-orders Observables" => "operators/high-order.md",
            "Categories"            => [
                "All"            => "operators/all.md",
                "Transformation" => [
                    "About transformation operators" => "operators/transformation/about.md",
                    "map"                            => "operators/transformation/map.md",
                    "scan"                           => "operators/transformation/scan.md",
                    "enumerate"                      => "operators/transformation/enumerate.md",
                ],
                "Filtering" => [
                    "About filtering operators" => "operators/filtering/about.md",
                    "filter"                    => "operators/filtering/filter.md",
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
                    "tap"                     => "operators/utility/tap.md"
                ]
            ]
        ]
    ],
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    )
)
