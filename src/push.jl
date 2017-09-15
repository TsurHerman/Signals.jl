const _async_mode = Ref(false)
async_mode() = _async_mode.x
async_mode(b::Bool)  = _async_mode.x = b

#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val , async::Bool = async_mode())
    if s.preserve_push
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
    if valis(s)
        push_signal!(a,val,async)
    else
        enqueue!(push_queue,(s,val))
        norify(eventloop_cond)
    end
end




#pull!
(s::Signal)() = pull!(s)

function pull!(s::Signal)
    if !valid(s)
        update_signal(s)
    end
    return value(s)
end
pull!(s) = s

update_signal(s::Signal) = s.update_signal()
nothing

#wizardry
