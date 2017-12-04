@testset "bind" begin
    Signals.async_mode(false)
    A = Signal(1)
    B = Signal(1)
    C = Signal(1)

    bind!(A, B)
    bind!(A, C)

    A(10)
    B(100)

    @test A() == 100

    unbind!(A, B)

    A(10)
    B(100)

    @test A() == 10

    A(10)
    C(100)
    B(1000)

    @test A() == 100

    unbind!(A)

    A(10)
    C(100)
    B(1000)

    @test A() == 10

end
