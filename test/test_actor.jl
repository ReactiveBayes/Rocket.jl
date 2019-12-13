module RxActorTest

using Test

import Rx
import Rx: UndefinedActorTrait, BaseActorTrait, NextActorTrait, ErrorActorTrait, CompletionActorTrait, ActorTrait
import Rx: Actor, NextActor, ErrorActor, CompletionActor
import Rx: next!, error!, complete!
import Rx: on_next!, on_error!, on_complete!
import Rx: as_actor

end
