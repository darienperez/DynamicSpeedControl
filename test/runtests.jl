using Test
using DynamicSpeedControl

@testset "DynamicSpeedControl basic API" begin
    # 1) It loads
    @test isdefined(Main, :DynamicSpeedControl)

    # 2) Exports a function called `initialize`
    @test haskey(names(DynamicSpeedControl, all = true), :initialize)

    # 3) That function at least exists and is callable
    @test typeof(DynamicSpeedControl.initialize) <: Function
end