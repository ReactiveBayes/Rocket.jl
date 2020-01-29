export ChainTeardown, chain

import Base: ==
import Base: show

"""
    ChainTeardown(teardown)

ChainTeardown object wraps another teardown and calls its teardown logic on unsubscription.

See also: [`Teardown`](@ref), [`UnsubscribableTeardownLogic`](@ref), [`chain`](@ref)
"""
struct ChainTeardown <: Teardown
    teardown
end

as_teardown(::Type{<:ChainTeardown}) = UnsubscribableTeardownLogic()

on_unsubscribe!(chained::ChainTeardown) = unsubscribe!(chained.teardown)

"""
    chain(t::T) where { T <: Teardown }

Creates a ChainTeardown object with a given teardown `t`

See also: [`Teardown`](@ref), [`ChainTeardown`](@ref)
"""
chain(t::T) where { T <: Teardown } = ChainTeardown(t)

Base.:(==)(c1::ChainTeardown, c2::ChainTeardown) = c1.teardown == c2.teardown
