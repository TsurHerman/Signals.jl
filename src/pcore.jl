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
    invoke_signal::Function
    children::Vector{Signal}
end

Signal(f::Function,args...) = begin
    sd = SignalData()

    invoke_signal() = store!(sd,f(map(pull!,args)...))

    s = Signal(sd,invoke_signal,Signal[])
    s()

    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
end

Signal(val) = begin
    Signal(()->val)
end

value(s::Signal) = s.data.x
value(s) = s

valid(s) = true
valid(s::Signal) = valid(s.data)
valid(sd::SignalData) = sd.valid

import Base.getindex
function getindex(s::Signal)
    value(s)
end

import Base.getindex
function getindex(s::Signal,val)
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
            pull!(child)
            propogate!(child)
        end
    end
end

#pull!
(s::Signal)() = pull!(s)

function pull!(s::Signal)
    if !valid(s)
        invoke_signal(s)
    end
    return value(s)
end
pull!(s) = s

invoke_signal(s::Signal) = s.invoke_signal()


nothing
