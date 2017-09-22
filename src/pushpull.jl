using Unrolled

const _async_mode = Ref(false)
async_mode() = _async_mode.x
async_mode(b::Bool)  = _async_mode.x = b

#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val , async::Bool = async_mode())
    if s.strict_push
        push_preserve!(s,val,async)
    else
        push_signal!(s,val,async)
    end
end

function push_signal!(s,val,async::Bool = async_mode())
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

function push_preserve!(s,val,async)
    if valid(s)
        push_signal!(s,val,async)
    else
        enqueue!(push_queue,(s,val))
        notify(eventloop_cond)
    end
end


#pull!
(s::Signal)() = pull!(s)

@inline function pull!(s::Signal)
    if !valid(s)
        pull!(s,s.action)
    end
    return value(s)
end

pull!(s::Signal,sa::SignalAction) = begin
    _args = pull_args(sa)
    if !valid(s)
        old_val = value(s)
        res = sa.f(_args...)
        if s.drop_repeats && old_val  == res
            validate(s.data)
            foreach(validate,s.children)
        end
    else
        old_val = res = value(s)
        foreach(validate,s.children)
    end
    store!(sa,res)
end
pull!(x) = x

validate(s::Signal) = begin
    validate(s.action)
end


validate(sa::SignalAction{F,ARGS}) where F where ARGS = begin
    if valid(sa)
        validate(sa.sd)
    end
end
validate(sd::SignalData) = sd.valid = true


nothing

#wizardry
