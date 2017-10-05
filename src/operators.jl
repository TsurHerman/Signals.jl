
abstract type DropRepeats <: PullType end
droprepeats(s) = Signal(x->x,s;pull_type = DropRepeats)
export droprepeats

(pa::PullAction{DropRepeats,A,E})(s) where A where E = begin
    pull_args(pa)
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
