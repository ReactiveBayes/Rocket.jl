export publish
export publish_sync
export publish_behavior
export publish_replay

publish()                 = multicast(SubjectFactory())
publish_sync()            = multicast(SyncSubjectFactory())
publish_behavior(default) = multicast(BehaviorSubjectFactory(default))
publish_replay(count)     = multicast(ReplaySubjectFactory(count))
