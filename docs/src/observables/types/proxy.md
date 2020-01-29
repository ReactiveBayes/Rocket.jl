# [Proxy Observable](@id observable_proxy)

`ProxyObservable` might help to create a custom operator.
It wraps either source and/or actor with their proxied versions providing additional custom logic for `on_subscribe!` and/or for
`on_next!`, `on_error!`, `on_complete!` methods.

```@docs
proxy
ProxyObservable
```

```@docs
ActorProxy
SourceProxy
ActorSourceProxy
```

```@docs
actor_proxy!
source_proxy!
```
