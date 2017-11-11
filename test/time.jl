using Proactive
#warmup
A = fps(10;duration = 2)
pA = previous(A)
C = Signal(-,A,pA)
nupdates = count(C)
sum_updates = foldp(+,0,C)
avg_delay = Signal(/,sum_updates,nupdates)
sleep(1)
# 1 == 1

#fps
A = fps(20;duration = 1)
pA = previous(A)
C = Signal(-,A,pA)
nupdates = count(C)
sum_updates = foldp(+,0,C)
avg_delay = Signal(/,sum_updates,nupdates)
sleep(1)
abs(avg_delay() - 1/20) < 0.01


#every
A = every(1/20;duration = 1)
pA = previous(A)
C = Signal(-,A,pA)
nupdates = count(C)
sum_updates = foldp(+,0,C)
avg_delay = Signal(/,sum_updates,nupdates)
sleep(1)
abs(avg_delay() - 1/20) < 0.01

#throttle
A = every(1/100;duration = 2)
C = throttle(x->x,A ; maxfps = 10)
nupdates = count(C)
sleep(1)
nupdates() <= 10
println(nupdates())

#fpswhen
switch = Signal(false)
A = fpswhen(switch,10;duration = 1)
C = count(A)
C() <= 1

switch(true)
sleep(1)
C() == 10

#debounce
A = Signal(time())
B = debounce(A;delay = 1 ) do a
    time() - a
end

A(time())
sleep(1.2)
abs(B() - 1) < 0.01
B()


#for_signal
range = Signal(1:5)
A = Signal(2)
B = for_signal(range,A;fps = 30) do i,a
    # println(a^i)
    i
end
D = count(B)
D() == 1

D(0);state(D,0)
A(1)
sleep(1)
D() == 5







# A=Signal(1)
# B = Signal(a->a+1,A)
# C = Signal((a,b)->a+b,A,B)
# D = Signal((b,c)->b+c,B,C)


A = Signal(1)
B = Signal(a->a+a,A)
C = Signal(-,A,B)
