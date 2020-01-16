export share
export share_replay
export share_sync_replay

share()                  = publish() + ref_count()
share_replay(count)      = publish_replay(count) + ref_count() # TODO: WIP
share_sync_replay(count) = publish_sync_replay(count) + ref_count()
