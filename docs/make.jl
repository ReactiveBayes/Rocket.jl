using Documenter, Rocket

makedocs(
    modules  = [ Rocket ],
    clean    = true,
    sitename = "Rocket.jl",
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
                "Merged"            => "observables/types/merged.md",
                "Network"           => "observables/types/network.md",
            ],
            "Actors" => [
                "Lambda"        => "actors/types/lambda.md",
                "Logger"        => "actors/types/logger.md",
                "Sync"          => "actors/types/sync.md",
                "Keep"          => "actors/types/keep.md",
                "Void"          => "actors/types/void.md",
                "Function"      => "actors/types/function.md",
                "Server"        => "actors/types/server.md",
            ],
            "Subscriptions" => [
                "Void"  => "teardown/types/void.md",
            ],
            "Operators" => [
                "All"            => "operators/all.md",
                "Creation"       => "operators/creation/about.md",
                "Transformation" => [
                    "About transformation operators" => "operators/transformation/about.md",
                    "map"                            => "operators/transformation/map.md",
                    "map_to"                         => "operators/transformation/map_to.md",
                    "scan"                           => "operators/transformation/scan.md",
                    "enumerate"                      => "operators/transformation/enumerate.md",
                    "uppercase"                      => "operators/transformation/uppercase.md",
                    "lowercase"                      => "operators/transformation/lowercase.md",
                    "to_array"                       => "operators/transformation/to_array.md",
                    "switch_map"                     => "operators/transformation/switch_map.md",
                    "switch_map_to"                  => "operators/transformation/switch_map_to.md",
                ],
                "Filtering" => [
                    "About filtering operators" => "operators/filtering/about.md",
                    "filter"                    => "operators/filtering/filter.md",
                    "some"                      => "operators/filtering/some.md",
                    "take"                      => "operators/filtering/take.md",
                    "take_until"                => "operators/filtering/take_until.md",
                    "first"                     => "operators/filtering/first.md",
                    "last"                      => "operators/filtering/last.md",
                    "find"                      => "operators/filtering/find.md",
                    "find_index"                 => "operators/filtering/find_index.md",
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
                "Multicasting" => [
                    "About multicasting operators" => "operators/multicasting/about.md",
                    "multicast"                    => "operators/multicasting/multicast.md",
                    "publish"                      => "operators/multicasting/publish.md",
                    "publish_behavior"             => "operators/multicasting/publish.md",
                    "publish_replay"               => "operators/multicasting/publish.md",
                    "share"                        => "operators/multicasting/share.md",
                    "share_replay"                 => "operators/multicasting/share.md",
                ],
                "Utility" => [
                    "About utility operators" => "operators/utility/about.md",
                    "tap"                     => "operators/utility/tap.md",
                    "`tap_on_subscribe`"      => "operators/utility/tap_on_subscribe.md",
                    "`tap_on_complete`"       => "operators/utility/tap_on_complete.md",
                    "delay"                   => "operators/utility/delay.md",
                    "safe"                    => "operators/utility/safe.md",
                    "noop"                    => "operators/utility/noop.md",
                    "ref_count"               => "operators/utility/ref_count.md",
                    "async"                   => "operators/utility/async.md",
                    "`default_if_empty`"      => "operators/utility/default_if_empty.md",
                    "`error_if_empty`"        => "operators/utility/error_if_empty.md",
                    "skip_next"               => "operators/utility/skip_next.md",
                    "skip_error"              => "operators/utility/skip_error.md",
                    "skip_complete"           => "operators/utility/skip_complete.md",
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
