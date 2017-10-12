
abstract type Binder <: PullType end
"""
    bind!(dest::Signal, src::Signal, twoway=false)

for every update to `src` also update `dest` with the same value and, if
`twoway` is true, vice-versa.
"""
function bind!(dest::Signal, src::Signal, twoway=false)
    binder = Signal(src;state = false, pull_type = Binder) do s,state
        dest(s)
    end
    #move binder to the top of the food-chain
    unshift!(src.children,pop!(src.children))
    push!(dest.binders,binder)
    twoway && bind!(src,dest,false)
    dest
end
export bind!

(pa::PullAction{Binder,ARGS})(s) where ARGS = begin
    lock = s.state
    pull_args(pa)
    if !valid(s) && !lock.x
        lock.x = true
        pa()
        lock.x = false
    end
    nothing
end

import Base.detach
"""
    detach(s::Signal)

detach a signal `s` from the signal graph making it unreachable unless explicitly pushed.
"""
function detach(s::Signal)
    parents = filter(x->isa(x,Signal),s.action.args)
    foreach(parents) do p
        filter!(x->x!=s,p.children)
    end
    unbind!(s)
end

"""
    unbind!(dst::Signal,src::Signal,twoway = true)

remove bindings from `src` to `dst` that were previously created using `bind`

    unbind!(dst::Signal)

remove all bindings that were previously created using `bind` that will cause `dst` to update
"""
function unbind!(dst::Signal,src::Signal,twoway = true)
    detach(binder(dst,src))
    twoway && unbind!(src,dst,false)
end

binder(dst::Signal,src::Signal) = filter(dst.binders) do b
    b.action.args[1] == src
end

function unbind!(s::Signal)
    foreach(detach,s.binders)
end
export unbind!

"""
`bound_dests(src::Signal)` returns a vector of all signals that will update when
`src` updates, that were bound using `bind!(dest, src)`
"""
function bound_dests(s::Signal)
    related_binders = filter(s.children) do child
        typeof(child.action).parameters[1] == Binder
    end
    [binder.action.f.dest for binder in related_binders]
end
export bound_dests
"""
`bound_srcs(dest::Signal)` returns a vector of all signals that will cause
an update to `dest` when they update, that were bound using `bind!(dest, src)`
"""
function bound_srcs(s::Signal)
    map(s.binders) do binder
        binder.action.args[1]
    end
end
export bound_srcs
