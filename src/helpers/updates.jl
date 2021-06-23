export PushEach, PushEachBut, PushNew, PushNewBut, PushStrategy

"""
    PushEach

`PushEach` update strategy specifies the strategy to emit new value each time an inner observable emit a new value

See also: [`combineLatest`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
struct PushEach end

"""
    PushEachBut{I}

`PushEachBut` update strategy specifies the strategy to emit new value if and only if an inner observable with index `I` have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
struct PushEachBut{I} end

"""
    PushNew

`PushNew` update strategy specifies the strategy to emit new value if and only if all inner observables have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
struct PushNew end

"""
    PushNewBut{I}

`PushNewBut{I}` update strategy specifies the strategy to emit new value if and only if all inner observables except with index `I` have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushStrategy`](@ref)
"""
struct PushNewBut{I} end

"""
    PushStrategy(strategy::BitArray{1})

`PushStrategy` update strategy specifies the strategy to emit new value if and only if all inner observables with index such that `strategy[index] = false` have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`collectLatest`](@ref)
"""
struct PushStrategy
    strategy :: BitArray{1}
end

getustorage(::Type{T}) where T = getustorage(T, _staticlength(T))

## Generic updates structure 

struct GenericUpdatesStatus
    cstatus  :: BitArray{1} # Completion status
    vstatus  :: BitArray{1} # Values status
    ustatus  :: BitArray{1} # Updates status

    GenericUpdatesStatus(nsize::Int) = new(falses(nsize), falses(nsize), falses(nsize))
end

getustorage(::Type{T}, ::Val{N}) where { T, N } = GenericUpdatesStatus(N)

cstatus(updates::GenericUpdatesStatus, index) = @inbounds updates.cstatus[index]
vstatus(updates::GenericUpdatesStatus, index) = @inbounds updates.vstatus[index]
ustatus(updates::GenericUpdatesStatus, index) = @inbounds updates.ustatus[index]

cstatus!(updates::GenericUpdatesStatus, index, v) = @inbounds updates.cstatus[index] = v
vstatus!(updates::GenericUpdatesStatus, index, v) = @inbounds updates.vstatus[index] = v
ustatus!(updates::GenericUpdatesStatus, index, v) = @inbounds updates.ustatus[index] = v

all_cstatus(updates::GenericUpdatesStatus) = all(updates.cstatus)
all_vstatus(updates::GenericUpdatesStatus) = all(updates.vstatus)
all_ustatus(updates::GenericUpdatesStatus) = all(updates.ustatus)

fill_cstatus!(updates::GenericUpdatesStatus, v) = fill!(updates.cstatus, v)
fill_vstatus!(updates::GenericUpdatesStatus, v) = fill!(updates.vstatus, v)
fill_ustatus!(updates::GenericUpdatesStatus, v) = fill!(updates.ustatus, v)

function push_update!(::Int, ::GenericUpdatesStatus, ::PushEach)
    return nothing
end

function push_update!(::Int, updates::GenericUpdatesStatus, ::PushEachBut{I}) where I
    vstatus!(updates, I, false)
    return nothing
end

function push_update!(nsize::Int, updates::GenericUpdatesStatus, ::PushNew)
    unsafe_copyto!(updates.vstatus, 1, updates.cstatus, 1, nsize)
    return nothing
end

function push_update!(nsize::Int, updates::GenericUpdatesStatus, ::PushNewBut{I}) where I
    push_update!(nsize, updates, PushNew())
    vstatus!(updates, I, true)
    return nothing
end

function push_update!(nsize::Int, updates::GenericUpdatesStatus, strategy::PushStrategy)
    push_update!(nsize, updates, PushNew())
    map!(|, updates.vstatus, updates.vstatus, strategy.strategy)
    return nothing
end

## Int8 updates structure 

mutable struct UInt8UpdatesStatus
    mask     :: UInt8
    cstatus  :: UInt8 # Completion status
    vstatus  :: UInt8 # Values status
    ustatus  :: UInt8 # Updates status

    UInt8UpdatesStatus(mask) = new(mask, 0b00000000, 0b00000000, 0b00000000)
end

getustorage(::Type{T}, ::Val{1}) where { T } = UInt8UpdatesStatus(0b1)
getustorage(::Type{T}, ::Val{2}) where { T } = UInt8UpdatesStatus(0b11)
getustorage(::Type{T}, ::Val{3}) where { T } = UInt8UpdatesStatus(0b111)
getustorage(::Type{T}, ::Val{4}) where { T } = UInt8UpdatesStatus(0b1111)
getustorage(::Type{T}, ::Val{5}) where { T } = UInt8UpdatesStatus(0b11111)
getustorage(::Type{T}, ::Val{6}) where { T } = UInt8UpdatesStatus(0b111111)
getustorage(::Type{T}, ::Val{7}) where { T } = UInt8UpdatesStatus(0b1111111)
getustorage(::Type{T}, ::Val{8}) where { T } = UInt8UpdatesStatus(0b11111111)

@inline _testbit(x::UInt8, bit::UInt8)   = x & (1 << (7 & (bit - 1))) !== 0
@inline _testbit(x::UInt8, bit::Integer) = _testbit(x, bit % UInt8)

@inline _setbit(x::UInt8, bit::UInt8, v)   = v ? (x | (0b1 << (bit - 1))) : (x & (~(0b1 << (bit - 1))))
@inline _setbit(x::UInt8, bit::Integer, v) = _setbit(x, bit % UInt8, v)

cstatus(updates::UInt8UpdatesStatus, index) = _testbit(updates.cstatus, index)
vstatus(updates::UInt8UpdatesStatus, index) = _testbit(updates.vstatus, index)
ustatus(updates::UInt8UpdatesStatus, index) = _testbit(updates.ustatus, index)

cstatus!(updates::UInt8UpdatesStatus, index, v) = updates.cstatus = _setbit(updates.cstatus, index, v)
vstatus!(updates::UInt8UpdatesStatus, index, v) = updates.vstatus = _setbit(updates.vstatus, index, v)
ustatus!(updates::UInt8UpdatesStatus, index, v) = updates.ustatus = _setbit(updates.ustatus, index, v)

all_cstatus(updates::UInt8UpdatesStatus) = (updates.cstatus & updates.mask) === updates.mask
all_vstatus(updates::UInt8UpdatesStatus) = (updates.vstatus & updates.mask) === updates.mask
all_ustatus(updates::UInt8UpdatesStatus) = (updates.ustatus & updates.mask) === updates.mask

fill_cstatus!(updates::UInt8UpdatesStatus, v) = updates.cstatus = v ? updates.mask : ~(updates.mask)
fill_vstatus!(updates::UInt8UpdatesStatus, v) = updates.vstatus = v ? updates.mask : ~(updates.mask)
fill_ustatus!(updates::UInt8UpdatesStatus, v) = updates.ustatus = v ? updates.mask : ~(updates.mask)

function push_update!(::Int, ::UInt8UpdatesStatus, ::PushEach)
    return nothing
end

function push_update!(::Int, updates::UInt8UpdatesStatus, ::PushEachBut{I}) where I
    vstatus!(updates, I, false)
    return nothing
end

function push_update!(nsize::Int, updates::UInt8UpdatesStatus, ::PushNew)
    updates.vstatus = updates.cstatus
    return nothing
end

function push_update!(nsize::Int, updates::UInt8UpdatesStatus, ::PushNewBut{I}) where I
    push_update!(nsize, updates, PushNew())
    vstatus!(updates, I, true)
    return nothing
end

function push_update!(nsize::Int, updates::UInt8UpdatesStatus, strategy::PushStrategy)
    @assert length(strategy.strategy) <= 8
    push_update!(nsize, updates, PushNew())
    updates.vstatus = updates.vstatus | UInt8(first(strategy.strategy.chunks))
    return nothing
end