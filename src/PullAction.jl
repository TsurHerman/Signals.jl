
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

pull_args(pa::PullAction) = pull_args(pa.args)
pull_args(args) = map(args) do arg
    typeof(arg) != Signal ? arg : pull!(arg)
end
value_args(args) = map(args) do arg
    typeof(arg) != Signal ? arg : value(arg)
end
valid_args(args) = all(args) do arg
    typeof(arg) != Signal ? true : valid(arg)
end
valid(pa::PullAction) = valid_args(pa.args)

(pa::PullAction)() = pa.f(pull_args(pa)...)

abstract type StandardPull <: PullType end
(pa::PullAction{StandardPull,A,E})(s) where A where E = begin
    pull_args(pa)
    if !valid(s)
        store!(s,pa())
    end
    value(s)
end
