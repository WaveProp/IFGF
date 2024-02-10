using Test
using IFGF
using LinearAlgebra
using StaticArrays

include("simple_geometries.jl")

n = 10000
X = Y   = sphere_uniform(n,1)
Xf = Yf = IFGF.Point3Df.(X)
p = 8

@testset "Laplace3d" begin
    pde = IFGF.Laplace(;dim=3)

    @testset "single layer (double precision)" begin
        K = IFGF.SingleLayerKernel(pde)
        @test IFGF.wavenumber(K) == 0
        L = IFGF.assemble_ifgf(K, X, Y; p)
        x = rand(n)
        y = L*x
        I = rand(1:n, 100)
        exa = [sum(K(X[i], Y[j]) * x[j] for j in 1:n) for i in I]
        @test norm(exa - y[I]) / norm(exa) < 1e-4
        # test forward_map!
        L = IFGF.plan_forward_map(pde, X, Y; tol=1e-4, charges=x)
        y = IFGF.forward_map(L; charges=x)
        @test norm(exa - y[I]) / norm(exa) < 1e-4
    end

    @testset "single layer (single precision)" begin
        K = IFGF.SingleLayerKernel(pde)
        @test IFGF.wavenumber(K) == 0
        L = IFGF.assemble_ifgf(K, Xf, Yf; p)
        x = rand(Float32,n)
        y = L*x
        @test eltype(y) == Float32
        I = rand(1:n, 100)
        exa = [sum(K(X[i], Y[j]) * x[j] for j in 1:n) for i in I]
        @test norm(exa - y[I]) / norm(exa) < 1e-4
        # test forward_map!
        L = IFGF.plan_forward_map(pde, Xf, Yf; tol=1e-4, charges=x)
        y = IFGF.forward_map(L; charges=x)
        @test eltype(y) == Float32
        @test norm(exa - y[I]) / norm(exa) < 1e-4
    end

    @testset "double layer (double precision)" begin
        K = IFGF.GradSingleLayerKernel(pde)
        @test IFGF.wavenumber(K) == 0
        L = IFGF.assemble_ifgf(K, X, Y; p)
        x = rand(SVector{3,Float64},n)
        y = L*x
        I = rand(1:n, 100)
        exa = [sum(K(X[i], Y[j]) * x[j] for j in 1:n) for i in I]
        @test norm(exa - y[I]) / norm(exa) < 1e-4
        # test forward_map!
        L = IFGF.plan_forward_map(pde, X, Y; tol=1e-4, dipvecs=x)
        y = IFGF.forward_map(L; dipvecs=x)
        @test norm(exa - y[I]) / norm(exa) < 1e-4
    end

    @testset "double layer (single precision)" begin
        K = IFGF.GradSingleLayerKernel(pde)
        @test IFGF.wavenumber(K) == 0
        L = IFGF.assemble_ifgf(K, Xf, Yf; p)
        x = rand(SVector{3,Float32},n)
        y = L*x
        @test eltype(y) == Float32
        I = rand(1:n, 100)
        exa = [sum(K(X[i], Y[j]) * x[j] for j in 1:n) for i in I]
        @test norm(exa - y[I]) / norm(exa) < 1e-4
        # test forward_map!
        L = IFGF.plan_forward_map(pde, Xf, Yf; tol=1e-4, dipvecs=x)
        y = IFGF.forward_map(L; dipvecs=x)
        @test eltype(y) == Float32
        @test norm(exa - y[I]) / norm(exa) < 1e-4
    end

    @testset "combined field (double precision)" begin
        K = IFGF.CombinedFieldKernel(pde)
        @test IFGF.wavenumber(K) == 0
        L = IFGF.assemble_ifgf(K, X, Y; p)
        c = rand(n)
        v = rand(SVector{3,Float64},n)
        x = [vcat(c[i],v[i]) for i in 1:n]
        y = L*x
        I = rand(1:n, 100)
        exa = [sum(K(X[i], Y[j]) * x[j] for j in 1:n) for i in I]
        @test norm(exa - y[I]) / norm(exa) < 1e-4
        # test forward_map!
        @test_throws AssertionError IFGF.forward_map!(y, L; dipvecs=x)
        L = IFGF.plan_forward_map(pde, X, Y; tol=1e-4, charges=x, dipvecs=v)
        y = IFGF.forward_map(L; dipvecs=v, charges=c)
        @test norm(exa - y[I]) / norm(exa) < 1e-4
    end

    @testset "combined field (single precision)" begin
        K = IFGF.CombinedFieldKernel(pde)
        @test IFGF.wavenumber(K) == 0
        L = IFGF.assemble_ifgf(K, Xf, Xf; p)
        c = rand(Float32, n)
        v = rand(SVector{3,Float32},n)
        x = [vcat(c[i],v[i]) for i in 1:n]
        y = L*x
        I = rand(1:n, 100)
        exa = [sum(K(X[i], Y[j]) * x[j] for j in 1:n) for i in I]
        @test norm(exa - y[I]) / norm(exa) < 1e-4
        # test forward_map!
        @test_throws AssertionError IFGF.forward_map!(y, L; dipvecs=x)
        L = IFGF.plan_forward_map(pde, Xf, Yf; tol=1e-4, charges=x, dipvecs=v)
        y = IFGF.forward_map(L; dipvecs=v, charges=c)
        @test eltype(y) == Float32
        @test norm(exa - y[I]) / norm(exa) < 1e-4
    end
end
