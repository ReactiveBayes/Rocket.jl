# [Observables](@id section_observables)

Observables are lazy Push collections of multiple values. They fill the missing spot in the following table:

 Type | Single   | Mutliple   |
 :--- | :------- | :--------- |
 Pull | Function | Iterator   |
 Push | Promise  | __Observable__ |

# Observable API

Any Observable should implements Subscribable logic.

```@docs
SubscribableTrait
```

```@docs
ValidSubscribable
```

```@docs
InvalidSubscribable
```

```@docs
Subscribable
```

```@docs
as_subscribable
```

```@docs
subscribe!
```

```@docs
on_subscribe!
```
