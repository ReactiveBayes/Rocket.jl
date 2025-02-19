# Rocket.jl

Welcome to Rocket.jl, a powerful reactive programming framework for Julia! 🚀

![Rocket.jl Logo](assets/logo-big.png)

Rocket.jl brings reactive programming paradigms to Julia, making it easy to work with asynchronous data streams, event-based programming, and reactive patterns. Whether you're building interactive applications, handling real-time data, or managing complex event-driven systems, Rocket.jl provides the tools you need.

## Why Rocket.jl?

- 🔄 **Reactive Programming**: Handle asynchronous data streams with ease
- 🛠️ **Rich Operator Library**: Transform, filter, and combine data streams using powerful operators
- 🎯 **Type-Safe**: Leverage Julia's type system for robust reactive applications
- 🚦 **Flow Control**: Manage complex event flows and data transformations
- ⚡ **High Performance**: Outperforms other reactive programming libraries in Julia

## Quick Example

Here's a fun example that creates a bouncing ball animation using Rocket.jl:

```julia
using Rocket, Compose, IJulia

# Function to draw the ball at a given time
function draw_ball(t)
    IJulia.clear_output(true)
    x = -exp(-0.01t) + 1                      # x coordinate
    y = -abs(exp(-0.04t)*(cos(0.1t))) + 0.83  # y coordinate
    display(compose(context(), circle(x, y, 0.01)))
end

# Create an observable that emits every 20ms, limited to 200 emissions
source = interval(20) |> take(200)

# Subscribe to animate the ball
subscription = subscribe!(source, draw_ball)

# Later, you can stop the animation with:
# unsubscribe!(subscription)
```

This example demonstrates how Rocket.jl can be used for reactive animations. The ball's position is updated based on time, creating a smooth bouncing effect.

## Getting Started

New to Rocket.jl? Our [Getting Started Guide](getting-started.md) will walk you through the essential concepts and show you how to build your first reactive applications!

## Documentation Structure

```@contents
Pages = [
    "getting-started.md",
    "observables/about.md",
    "actors/about.md",
    "teardown/about.md",
    "operators/about.md",
    "operators/piping.md",
    "operators/create-new-operator.md",
    "operators/high-order.md",
    "todo.md",
    "contributing.md",
    "utils.md"
]
Depth = 2
```

## API Reference

Looking for specific functionality? Browse our complete API documentation:

```@index
```

## Contributing

We welcome contributions! If you'd like to help improve Rocket.jl, please check out our [Contributing Guide](contributing.md).

## Acknowledgments

Rocket.jl is inspired by [RxJS](https://rxjs.dev) and brings its powerful reactive programming concepts to the Julia ecosystem.
