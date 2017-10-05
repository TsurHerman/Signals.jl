
abstract type PullType end

struct PullAction{pt <: PullType,ARGS <: Tuple,EXTRA <: Tuple} <: Function
    f::Function
    args::ARGS
    extra_args::EXTRA
end

create_pull_action(f,args,pt = StandardPull) = create_pull_action(f,args,pt,())
function create_pull_action(f,args::ARGS,pt::PT, extra::E) where ARGS where PT where E
    PullAction{pt,ARGS,E}(f,args,extra)
end

pull_args(sa::PullAction) = pull_args(sa.args)
pull_args(args) = map(args) do arg
    typeof(arg) != Signal ? arg : pull!(arg)
end
value_args(args) = map(args) do arg
    typeof(arg) != Signal ? arg : value(arg)
end
valid_args(args) = all(args) do arg
    typeof(arg) != Signal ? true : valid(arg)
end

(sa::PullAction)() = sa.f(pull_args(sa)...)

abstract type StandardPull <: PullType end
(sa::PullAction{StandardPull,A,E})(s) where A where E = begin
    pull_args(sa)
    if !valid(s)
        store!(s,sa())
    end
    value(s)
end

abstract type DropRepeats <: PullType end
droprepeats(s) = Signal(x->x,s;pull_type = DropRepeats)
export droprepeats

(sa::PullAction{DropRepeats,A,E})(s) where A where E = begin
    pull_args(sa)
    if !valid(s)
        old_val = value(s)
        res = sa()
        if old_val == res
            validate(s)
        end
        store!(s,res)
    end
    value(s)
end
