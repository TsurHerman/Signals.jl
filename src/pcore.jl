
mutable struct Signal
    data
    action::Function
    poll_action::Function
    children::Vector{Signal}

    data_age::Int
end

create_action(f::Function,args::Tuple,trans::Function = x->x) = begin
    () -> try f(trans.(args)...) catch error("blah"); end
end

(s::Signal)()  = begin
    s.data
end

function value(s::Signal)
    s()
end

function value(s::T) where T
    s
end


function set_value!(s::Signal,val)
    s.data_age += 1
    s.data = val
end

function update!(s::Signal)
    set_value!(s,s.action())
    foreach(update!,s.children)
end

function poll!(s::Signal)
    s.data = s.poll_action()
end

function poll!(s::T) where T
    s
end

(s::Signal)(val)  = begin
    set_value!(s,val)
    foreach(update!,s.children)
end

#base_construc
Signal(data,action::Function,poll_action::Function) = begin
    s = Signal(data,action,poll_action,Signal[],0)
    finalizer(s,(s) -> @async println("finialized Signal"))
    s
end

Signal(val) = begin
    nop = ()->nothing
    s = Signal(val,nop,nop);
    data = create_action(()->s.data,())
    s.action = data
    s.poll_action = data
    s
end

Signal(f::Function,args...) = begin
    action = create_action(f,args,value)
    poll_action = () -> begin
        foreach(poll!,args);
        action()
    end
    s = Signal(action(),action,poll_action)
    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
end
