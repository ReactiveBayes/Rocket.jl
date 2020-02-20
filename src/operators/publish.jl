export publish
export publish_behavior
export publish_replay
export publish_pending

"""
    publish(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M

`publish()` is a shortcut for `multicast(make_subject_factory())`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`make_subject`](@ref)
"""
publish(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(make_subject_factory(mode = mode))

"""
    publish_behavior(default; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M

`publish_behavior(default)` is a shortcut for `multicast(make_behavior_subject_factory(default))`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`make_behavior_subject`](@ref)
"""
publish_behavior(default; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(make_behavior_subject_factory(default, mode = mode))

"""
    publish_replay(count; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M

`publish_replay(count)` is a shortcut for `multicast(make_replay _subject_factory(count))`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`make_replay_subject`](@ref)
"""
publish_replay(count; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(make_replay_subject_factory(count, mode = mode))

# TODO: Untested and undocumented
publish_pending(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(make_pending_subject_factory(mode = mode))
