export share
export share_replay

"""
    share(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M

`share()` is a shortcut for `publish() + ref_count()`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`ref_count`](@ref)
"""
share(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = publish(mode = mode) + ref_count()

"""
    share_replay(count; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M

`share_replay(count)` is a shortcut for `publish_replay(count) + ref_count()`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`publish_replay`](@ref), [`ref_count`](@ref)
"""
share_replay(count; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = publish_replay(count, mode = mode) + ref_count()
