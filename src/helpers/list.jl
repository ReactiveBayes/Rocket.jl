

mutable struct ListNode{T}
    data :: T
    prev :: ListNode{T}
    next :: ListNode{T}

    function ListNode(::Type{T}) where T 
        return new{T}()
    end

    function ListNode(data::T) where T 
        return new{T}(data)
    end
end

Base.show(io::IO, node::ListNode) = print(io, string("ListNode(", node.data, ")"))

struct List{T}
    first :: ListNode{T} # First and last do not represent any real nodes, but used as placeholders to have a reference for beginning and ending of the list
    last  :: ListNode{T}

    function List(::Type{T}) where T
        first = ListNode(T)
        last  = ListNode(T)

        first.next = last
        last.prev  = first

        return new{T}(first, last)
    end
end

Base.show(io::IO, list::List) = print(io, string("List(", eltype(list), ")"))

Base.isempty(list::List)                  = list.first.next === list.last
Base.eltype(::Type{ <: List{T} }) where T = T

function Base.push!(list::List{T}, data::T) where T
    node = ListNode(T)

    node.data = data
    node.prev = list.last.prev
    node.next = list.last

    list.last.prev.next = node
    list.last.prev      = node

    return list
end

function pushnode!(list::List{T}, data::T) where T
    node = ListNode(T)

    node.data = data
    node.prev = list.last.prev
    node.next = list.last

    list.last.prev.next = node
    list.last.prev      = node

    return node
end

function Base.empty!(list::List)
    list.first.next = list.last
    list.last.prev  = list.first
    return list
end

function remove(node::ListNode)
    next = node.next
    prev = node.prev

    next.prev = prev
    prev.next = next

    return node
end

Base.IteratorSize(::Type{ <: List })   = Base.SizeUnknown()
Base.IteratorEltype(::Type{ <: List }) = Base.HasEltype()

Base.iterate(list::List)                  = isempty(list) ? nothing : (list.first.next.data, list.first.next.next)
Base.iterate(list::List, state::ListNode) = list.last === state ? nothing : (state.data, state.next)