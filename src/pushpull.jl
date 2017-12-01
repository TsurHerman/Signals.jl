
#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val,async = async_mode())
    try
        if s.strict_push
            strict_push!(s,val,async)
        else
            soft_push!(s,val,async)
        end
    catch e
        handle_err(e,catch_stacktrace())
    end
end

"""
    strict_push!(s::Signal,val,async = Signals.async_mode() )
sets `s` to `val` and propagate into derived signals, is `async` is `true`(default)
then updates to derived signals will occur asynchronically
"""
function strict_push!(s,val,async = async_mode())
    if !async || isempty(pull_queue)
        soft_push!(s,val,async)
    else
        enqueue!(push_queue,(s,val))
        notify(eventloop_cond)
    end
    val
end
export strict_push!

function soft_push!(s,val,async = async_mode())
    set_value!(s,val)
    propogate!(s,async)
    async && notify(eventloop_cond)
    val
end

function propogate!(s::Signal,async = async_mode())
    propogated(s) && return
    propogated(s,true)
    if isempty(s.children)
        pull_enqueue(s,async)
    else
        foreach(x->propogate!(x,async),s.children)
    end
end

function pull_enqueue(s,async = async_mode())
    if async
        enqueue!(pull_queue,s)
    else
        pull!(s)
    end
end

#pull!
(s::Signal)() = pull!(s)

function pull!(s::Signal)
    if !valid(s)
        propogated(s,false)
        action(s)
    end
    return value(s)
end
pull!(x) = x

action(s::Signal) =  s.action(s)

abstract type StandardPull <: PullType end
function (pa::PullAction{StandardPull,ARGS})(s::Signal) where ARGS
    args = pull_args(pa)
    if !valid(s)
        store!(s,pa())
    end
    value(s)
end



nothing
