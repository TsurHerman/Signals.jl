
#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val , async::Bool = async_mode())
    if s.strict_push
        strict_push!(s,val,async)
    else
        soft_push!(s,val,async)
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
        if !valid(child)
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

@inline function pull!(s::Signal)
    if !valid(s)
        # store!(s,s.action())
        pull!(s,s.action)
    end
    return value(s)
end

pull!(s::Signal,sa::SignalAction) = begin
    _args = pull_args(sa)
    if !valid(s)
        old_val = value(s)
        res = sa()
        if s.drop_repeats && old_val == res
            validate(s.data)
            foreach(validate,s.children)
        end
    else
        old_val = res = value(s)
        foreach(validate,s.children)
    end
    store!(s,res)
end
pull!(x) = x

validate(s::Signal) = begin
    if valid(s.action)
        validate(s.data)
    end
end

validate(sd::SignalData) = sd.valid = true


nothing

#wizardry
