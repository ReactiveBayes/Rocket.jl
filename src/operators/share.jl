export share
export share_replay

share(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = publish(mode = mode) + ref_count()
share_replay(count; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = publish_replay(count, mode = mode) + ref_count()
