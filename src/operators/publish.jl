export publish
export publish_sync
export publish_behavior
export publish_replay
export publish_pending

publish(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(subject_factory(mode = mode))

publish_behavior(default; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(behaviour_subject_factory(default, mode = mode))
publish_replay(count; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(replay_subject_factory(count, mode = mode))
publish_pending(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = multicast(pending_subject_factory(mode = mode))
