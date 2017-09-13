mutable struct SignalData
    x
    valid::Bool
    SignalData(x) = new(x,true)
    SignalData() = new(nothing,false)
end
import Base.convert
convert(::T,x) where T = SignalData(x)
invalidate!(sd::SignalData) = sd.valid = false
store!(sd::SignalData,val) = begin sd.x = val;sd.valid = true;val;end

struct Signal
    data::SignalData
    update_signal::Function
    value::Function
    children::Vector{Signal}
end

@generated function call_on_pull!(f::Function,args::Tuple)
    exp = Vector{Expr}(length(args.parameters))
    for (i,arg) in  enumerate(args.parameters)
        if arg == Signal
            exp[i] = :(pull!(args[$i]))
        else
            exp[i] = :(args[$i])
        end
    end
    return Expr(:call,:f,exp...)
end

Signal(f::Function,args...) = begin
    sd = SignalData()
    @inline function val()
        sd.x;
    end
    update_signal() = store!(sd,call_on_pull!(f,args))

    s = Signal(sd,update_signal,val,Signal[])
    s()

    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
end

Signal(val) = begin
    Signal(()->val)
end

@inline value(s::Signal) = value(s.data)
@inline value(sd::SignalData) = sd.x
value(s) = s

valid(s) = true
valid(s::Signal) = valid(s.data)
valid(sd::SignalData) = sd.valid

import Base.getindex
function getindex(s::Signal)
    value(s)
end

import Base.setindex!
function setindex!(s::Signal,val)
    set_value!(s,val)
end

function set_value!(s::Signal,val)
    invalidate!(s)
    store!(s,val)
end
store!(s::Signal,val) = store!(s.data,val)

function invalidate!(s::Signal)
    if valid(s)
        invalidate!(s.data)
        foreach(invalidate!,s.children)
    end
end

#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val)
    set_value!(s,val)
    propogate!(s)
    val
end

function propogate!(s::Signal)
    foreach(s.children) do child
        if !valid(child)
            if isempty(child.children)
                enqueue!(pull_queue,child)
            else
                propogate!(child)
            end
        end
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
