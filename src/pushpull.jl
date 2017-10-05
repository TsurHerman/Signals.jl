
#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val , async::Bool = async_mode())
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

function soft_push!(s,val,async::Bool = async_mode())
    set_value!(s,val)
    propogate!(s,async)
    async && notify(eventloop_cond)
    val
end

function propogate!(s,async::Bool = async_mode())
    foreach(s.children) do child
        valid(child) && return nothing
        if isempty(child.children)
            if async
                enqueue!(pull_queue,child)
            else
                pull!(child)
            end
        else
            propogate!(child,async)
        end
    end
end

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

#pull!
(s::Signal)() = pull!(s)

function pull!(s::Signal)
    if !valid(s)
        s.action(s)
    end
    return value(s)
end

validate(s::Signal) = begin
    valid(s) && return
    if valid(s.action)
        validate(s.data)
        foreach(validate,s.children)
    end
end

validate(sd::SignalData) = sd.valid = true


nothing
