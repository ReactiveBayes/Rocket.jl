export AbstractMStorage, MAX_PREGENERATED_MSTORAGE_SIZE

abstract type AbstractMStorage end

const MAX_PREGENERATED_MSTORAGE_SIZE = 16

import Base: length

"""
    @MStorage(n::Int)

Helper function to generate tuple-like structure MStorageN, but with mutable fields and empty constructor.
It is possible then to take a `snapshot(::MStorage)` which returns a tuple with the same types and values from storage.
Some operators and observables use pregenerated `MStorage` to instatiate uninitialized
mutable storage in case when stream is allowed to not emit any values before completion.

# Generated structure layout

```
struct MStorageN{V1, V2, ..., VN}
    v1 :: V1
    v2 :: V2
    ...
    vn :: VN
end
```

See also: [`setstorage!`](@ref)
"""
macro MStorage(n::Int)
    name = Symbol(:MStorage, n)
    types = map(i -> Symbol(:V, i), 1:n) # types  = [ V1, V2, ..., V2 ]
    fields = map(i -> Symbol(:v, i), 1:n) # fields = [ v1, v2, ..., vn ]

    # Generates structure with the following layout:
    #
    # struct MStorageN{V1, V2, ..., VN} <: AbstractMStorage
    #     v1 :: V1
    #     v2 :: V2
    #     ...
    #     vn :: VN
    # end
    structure = Expr(
        :struct,
        true,                                   # <-- true stands for mutable
        Expr(:(<:), Expr(:curly, name, types...), :AbstractMStorage), # $name{types...} <: AbstractMStorage
        Expr(
            :block,                                                  # begin
            map(z -> Expr(:(::), z[1], z[2]), zip(fields, types))..., # v1::V1, v2::V2, ..., vn::VN
            Expr(
                :(=),                                                # constructor() = new()
                Expr(:where, Expr(:call, Expr(:curly, name, types...)), types...),
                Expr(:block, Expr(:call, :new)),
            ),
        ),
    )

    # Generates function `snapshot`
    #
    # snapshot(storage::$name) = (storage.v1, storage.v2, ..., storage.vn)
    snapshot = Expr(
        :(=),
        Expr(:call, :snapshot, Expr(:(::), :s, name)),
        Expr(:block, Expr(:tuple, map(f -> Expr(:(.), :s, QuoteNode(f)), fields)...)),
    )

    # Generates function `length`
    #
    # length(storage::$name) = $n
    length = Expr(:(=), Expr(:call, :length, Expr(:(::), :s, name)), Expr(:block, n))

    # Generates function `mstorage`
    #
    # `mstorage(::Val{$n}, ::Type{ <: Tuple{V1, V2, ..., VN} }) = $name{V1, V2, ..., VN}()`
    mstorage = Expr(
        :(=),
        Expr(
            :where,
            Expr(
                :call,
                :mstorage,
                Expr(:(::), Expr(:curly, :Type, Expr(:curly, :Tuple, types...))),
                Expr(:(::), Expr(:curly, :Val, n)),
            ),
            types...,
        ),
        Expr(:block, Expr(:call, Expr(:curly, name, types...))),
    )

    # Generates function `setstorage!`
    #
    # function setstorage!(s::$name, v, index::Int)
    #     if index === 1
    #         s.v1 = v
    #         return nothing 
    #     end 
    #     ...  
    # end
    setstorage = Expr(
        :function,
        Expr(:call, :setstorage!, Expr(:(::), :s, name), :v, Expr(:(::), :index, :Int)),
        Expr(
            :block,
            map(
                i -> Expr(
                    :if,
                    Expr(:call, :(===), :index, i),
                    Expr(
                        :block,
                        Expr(:(=), Expr(:(.), :s, QuoteNode(fields[i])), :v),
                        Expr(:return, :nothing),
                    ),
                ),
                1:n,
            )...,
        ),
    )

    output = quote
        $structure
        $snapshot
        $length
        $mstorage
        $setstorage
    end

    return esc(output)
end

"""
    setstorage!(s, v, ::Val{I}) where I

This function can be used to set a new value `v` for storage `s` with a given value `v` and index `I`.
Using parametrized `Val{I}` for indexing ensures for index to be resolved at compile-time and if-else branch optimization.

See also: [`@MStorage`](@ref)
"""
function setstorage!(s::S, v, ::Val{I}) where {S<:AbstractMStorage,I}
    if I === 1
        s.v1 = v
    elseif I === 2
        s.v2 = v
    elseif I === 3
        s.v3 = v
    elseif I === 4
        s.v4 = v
    elseif I === 5
        s.v5 = v
    elseif I === 6
        s.v6 = v
    elseif I === 7
        s.v7 = v
    elseif I === 8
        s.v8 = v
    elseif I === 9
        s.v9 = v
    elseif I === 10
        s.v10 = v
    elseif I === 11
        s.v11 = v
    elseif I === 12
        s.v12 = v
    elseif I === 13
        s.v13 = v
    elseif I === 14
        s.v14 = v
    elseif I === 15
        s.v15 = v
    elseif I === 16
        s.v16 = v
    end
end

mstorage(::Type{T}, ::Val{N}) where {N,T<:NTuple{N,Any}} = Vector{Any}(undef, N)
snapshot(s::S) where {S<:Vector} = tuple(s...)

setstorage!(s::S, v::T, ::Val{I}) where {T,S<:Vector{T},I} = s[I] = v
setstorage!(s::S, v::T, I::Int) where {T,S<:Vector{T}} = s[I] = v

macro GenerateMStorages()
    output = quote end
    for i = 1:MAX_PREGENERATED_MSTORAGE_SIZE
        output = quote
            $output
            @MStorage($i)
        end
    end
    return esc(output)
end

@GenerateMStorages()

_staticlength(::Type{T}) where {N,T<:NTuple{N,Any}} = Val{N}()

getmstorage(::Type{T}) where {T} = mstorage(T, _staticlength(T))
