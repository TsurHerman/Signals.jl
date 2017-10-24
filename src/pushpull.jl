
#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val)
    try
        if s.strict_push
            strict_push!(s,val)
        else
            soft_push!(s,val)
        end
    catch e
        handle_err(e,catch_stacktrace())
    end
end

function strict_push!(s,val)
    if !async_mode() || isempty(pull_queue)
        soft_push!(s,val)
    else
        enqueue!(push_queue,(s,val))
        notify(eventloop_cond)
    end
    val
end
export strict_push!

function soft_push!(s,val)
    set_value!(s,val)
    propogate!(s)
    async_mode() && notify(eventloop_cond)
    val
end

function propogate!(s::Signal)
    if isempty(s.children)
        pull_enqueue(s)
    else
        foreach(propogate!,s.children)
    end
end

function pull_enqueue(s)
    if async_mode()
        enqueue!(pull_queue,s)
    else
        pull!(s)
    end
end

#pull!
(s::Signal)() = pull!(s)

function pull!(s::Signal)
    if !valid(s)
        action(s)
    end
    return value(s)
end

abstract type StandardPull <: PullType end
(pa::PullAction{StandardPull,ARGS})(s::Signal) where ARGS = begin
    args = pull_args(pa)
    if !valid(s)
        store!(s,pa.f(args...))
    end
    value(s)
end

nothing
