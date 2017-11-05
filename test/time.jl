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

A = fps(10;duration = 2)
pA = previous(A)
C = Signal(-,A,pA)
nupdates = count(C)
sum_updates = foldp(+,0,C)
avg_delay = Signal(/,sum_updates,nupdates)
sleep(1)
abs(avg_delay() - 0.1) < 0.01

#every
A = every(1/20;duration = 2)
pA = previous(A)
C = Signal(-,A,pA)
nupdates = count(C)
sum_updates = foldp(+,0,C)
avg_delay = Signal(/,sum_updates,nupdates)
sleep(1)
abs(avg_delay() - 1/20) < 0.01

#throttle
A = fps(100;duration = 1)
C = throttle(A; maxfps = 10) do a
    a
end
nupdates = count(C)
sleep(1)
nupdates() <= 10

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


range = Signal(1:5)
A = Signal(2)
for_signal(A;range = range,fps = 30) do a,i
    println(a^i)
end
