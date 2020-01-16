export share
export share_replay

share()             = publish() + ref_count()
share_replay(count) = publish_replay(count) + ref_count() # TODO: WIP
