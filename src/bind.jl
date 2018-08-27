"""
    bind!(dest::Signal, src::Signal)

For every update to `src` also update `dest` with the same value.
"""
function bind!(dest::Signal, src::Signal)
    push!(dest.binders, Signal(x -> dest(x), src))
end
export bind!

"""
    unbind!(dst::Signal,src::Signal)

Remove bindings from `src` to `dst` that were previously created using `bind`.

    unbind!(dst::Signal)

Remove all bindings that were previously created using `bind` that will cause `dst` to update.
"""
function unbind!(dst::Signal, src::Signal)
    b_idx = findfirst(b -> b.action.args[1] == src, dst.binders)
    b_idx === 0 && return
    binder = dst.binders[b_idx]
    detach(binder)
    filter!(dst.binders) do b
        b != binder
    end
end
export unbind!

function unbind!(dst::Signal)
    foreach(detach, dst.binders)
    empty!(dst.binders)
end


import Base.detach
"""
    detach(s::Signal)

Detach a signal `s` from the signal graph making it unreachable and ready for GC.
"""
function detach(s::Signal)
    parents = Iterators.filter(x -> isa(x, Signal), s.action.args)
    foreach(parents) do p
        Iterators.filter!(x -> x!=s, p.children)
    end
    unbind!(s)
    nothing
end
