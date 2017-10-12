
abstract type PullType end

struct PullAction{pt <: PullType,ARGS <: Tuple} <: Function
    f::Function
    args::ARGS
end

PullAction(f,args,pt = StandardPull) = PullAction{pt,typeof(args)}(f,args)

pull_args(pa::PullAction) = pull_args(pa.args)
pull_args(args) = map(args) do arg
    typeof(arg) != Signal ? arg : pull!(arg)
end

valid_args(args) = all(args) do arg
    typeof(arg) != Signal ? true : valid(arg)
end
valid(pa::PullAction) = valid_args(pa.args)

(pa::PullAction)() = pa.f(pull_args(pa)...)

abstract type StandardPull <: PullType end
(pa::PullAction{StandardPull,ARGS})(s) where ARGS = begin
    args = pull_args(pa)
    if !valid(s)
        store!(s,pa.f(args...))
    end
    value(s)
end
