using Test
using NeXLCore

@testset "X-ray" begin

        e1, e2, e3 = element(20), element(84), element(92)

        @testset "Elements" begin

                @test z(e1) == 20
                @test z(e2) == 84
                @test z(e3) == 92

                @test isapprox(a(e1), 40.08, atol = 0.01)
                @test isapprox(a(e2), 209.00, atol = 0.01)
                @test isapprox(a(e3), 238.03, atol = 0.01)

                @test symbol(e1) == "Ca"
                @test symbol(e2) == "Po"
                @test symbol(e3) == "U"

                @test name(e1) == "Calcium"
                @test name(e2) == "Polonium"
                @test name(e3) == "Uranium"

                @test e1 ≠ e2
                @test e1 == element(20)
                @test e2 == element(84)
                @test e3 == element(92)

                @test e1 < e2
                @test e1 < e3
                @test e2 < e3

                @test e2 >= e1
                @test e2 >= e2
                @test e3 >= e2
                @test e3 >= e1

                @test e2 > e1
                @test e3 > e2
                @test e3 > e1
        end

        @testset "Shells" begin
                @test length(ksubshells) == 1
                @test length(lsubshells) == 3
                @test length(msubshells) == 5
                @test length(nsubshells) == 7
                @test length(osubshells) == 9

                @test ksubshells == map(SubShell, ("K",))
                @test lsubshells == map(SubShell, ("L1", "L2", "L3"))
                @test msubshells == map(SubShell, ("M1", "M2", "M3", "M4", "M5"))
                @test nsubshells == map(SubShell, ("N1", "N2", "N3", "N4", "N5", "N6", "N7"))
                @test osubshells == map(SubShell, ("O1", "O2", "O3", "O4", "O5", "O6", "O7", "O8", "O9"))

                @test shell(SubShell("K")) == Shell(1)
                @test shell(SubShell("L2")) == Shell(2)
                @test shell(SubShell("M4")) == Shell(3)
                @test shell(SubShell("N7")) == Shell(4)
                @test shell(SubShell("O1")) == Shell(5)

                @test capacity(n"K1") == 2
                @test capacity(n"L2") == 2
                @test capacity(n"M5") == 6
                @test capacity(n"N6") == 6
                @test capacity(n"O9") == 10

                as1, as2, as3 = AtomicSubShell(e1.number, subshell("L3")),
                        AtomicSubShell(e2.number, subshell("M5")),
                        AtomicSubShell(e3.number, subshell("K"))

                @test repr(as1) == "Ca L3"
                @test repr(as2) == "Po M5"
                @test repr(as3) == "U K"

                @test as1 == n"Ca L3"
                @test as2 == n"Po M5"
                @test as3 == n"U K"

                @test shell(as1) == Shell(2)
                @test shell(as2) == Shell(3)
                @test shell(as3) == Shell(1)

                @test n"Ca K" > n"Ca L1"
                @test n"Ca K" < n"Ti K"
                @test as1 < as2
                @test !(as2 < as1)
                @test !(as1 < as1)

                @test n"Ca K" == n"Ca K"
                @test !(n"Ca K" == n"Ca L1")

                @test isless(Shell(3), Shell(1))  # Binding energy order (not N)
                @test !isless(Shell(3),Shell(3))
                @test !isless(n"Ca K",n"Ca L1") # Binding energy order (not N)
                @test isless(n"Ca L3",n"Ca L1")
                @test isless(n"Ca K",n"Fe K")
                @test !isless(n"Fe K",n"Fe K")
                @test isless(n"Fe K-L3", n"Fe K-L2")
                @test !isless(n"Fe K-L3", n"Fe K-L3")
                @test !isless(n"Fe K-L2", n"Fe K-L3")
        end

        @testset "Transitions" begin
                @test n"K-L3" in alltransitions
                @test n"L3-M5" in alltransitions
                #@test_throws ArgumentError n"M5-L3"
                #@test_throws ArgumentError n"K-N7"

                @test shell(n"K-L3") == Shell(1)
                @test shell(n"L3-M5") == Shell(2)
                @test shell(n"M5-N7") == Shell(3)

                @test all(tr -> shell(tr) == Shell(1), ktransitions)
                @test all(tr -> shell(tr) == Shell(2), ltransitions)
                @test all(tr -> shell(tr) == Shell(3), mtransitions)
                @test all(tr -> shell(tr) == Shell(4), ntransitions)

                @test length(alltransitions) == sum(
                        length.( ( ktransitions, ltransitions, mtransitions, ntransitions, otransitions) )
                )

                @test n"K-L3" == n"K-L3"
                @test n"K-L3" ≠ n"K-L2"

                @test transition(n"Fe L3-M5") == n"L3-M5"
                @test element(n"Fe L3-M5") == n"Fe"

                @test isapprox(energy(n"Fe", n"L3-M5"), 705.0, atol = 1.0)
                @test isapprox(energy(n"U", n"L3-M5"), 13614.6, atol = 1.0)
                @test energy(n"Fe", n"L3-M5") == energy(n"Fe L3-M5")
                @test isapprox(energy(n"C K-L2"), 277.4, atol = 1.0)

                # from https://www.physics.nist.gov/cgi-bin/XrayTrans/search.pl?element=Fe&trans=KL3&lower=&upper=&units=A
                @test isapprox(λ(n"Fe K-L3"), 1.936e-8, atol = 1e-10) #
                @test isapprox(λ(n"Cu L3-M5"), 13.336e-8, atol = 1e-10)

                x = n"Ba L3-M5"
                @test isapprox(NeXLCore.speedOfLight, λ(x) * ν(x), atol = 1.0e7) # C = λν
                @test isapprox(energy(x), NeXLCore.plancksConstant * ν(x), atol = 1.0) # E = hν
                @test isapprox(energy(x), NeXLCore.plancksConstant / (2π) * ω(x), atol = 1.0) # E = ħω

                x = n"U M5-N7"
                @test isapprox(NeXLCore.speedOfLight, λ(x) * ν(x), atol = 1.0e7) # C = λν
                @test isapprox(energy(x), NeXLCore.plancksConstant * ν(x), atol = 1.0) # E = hν
                @test isapprox(energy(x), NeXLCore.plancksConstant / (2π) * ω(x), atol = 1.0) # E = ħω

                @test isapprox(energy(n"Fe L3"), 708.0, atol = 1.0)
                @test energy(n"Fe L3") == energy(n"Fe", n"L3")

                @test has(n"C", n"K-L2")
                @test !has(n"Li", n"K-L3")
                @test !has(n"C", n"L3-M5")
                @test has(n"U", n"L3-M5")
                @test has(n"U", n"M5-N7")

                @test all(tr -> shell(tr) == Shell(2), characteristic(n"Fe", ltransitions))
                @test all(tr -> shell(tr) == Shell(1), characteristic(n"Fe", ktransitions))

                @test length(characteristic(n"Fe", ltransitions, 0.0)) == 12
                @test length(characteristic(n"Fe", ltransitions, 0.1)) == 6
                @test length(characteristic(n"Fe", ltransitions, 0.01)) == 7

                # @test_logs (:warn, "The sum mass fraction is 80.0 which is much larger than unity.")  mat"80*Fe+15*Ni+4*Cr"
        end
        @testset "Other" begin
            @test firstsubshell(Shell(3))==n"M1"
            @test lastsubshell(Shell(3))==n"M5"
            @test firstsubshell(Shell(1))==n"K1"
            @test lastsubshell(Shell(1))==n"K1"
            @test firstsubshell(Shell(2))==n"L1"
            @test lastsubshell(Shell(2))==n"L3"
            @test elementrange()==1:92
            @test NeXLCore.characteristicyield(20, 1, 4, 9, NeXL)==0.0
            @test isapprox(NeXLCore.characteristicyield(25, 1, 4, 9, NeXL), 0.0007828, atol=0.0000001)
            @test configuration(n"Fe")=="1s² 2s² 2p⁶ 3s² 3p⁶ 4s² 3d⁶"
            @test density(n"Au")==19.3
            @test density(pure(n"Au"))==density(n"Au")
            @test get(mat"Fe2O3",:Drip,"Drip")=="Drip"
            m=parse(Material,"Fe2O3",name="Hematite",properties=Dict{Symbol,Any}(:Density=>5.25,:Drizzle=>99))
            m[:Drop]="Drop"
            @test get(m, :Density, "Drip")==5.25
            @test get(m, :Drop, "Drip")=="Drop"
            @test m[:Drizzle]==99
            @test typeof(m[:Drizzle])==Int64
            lm = labeled(m)
            @test all(e->lm[MassFractionLabel("Hematite",e)]==m[e],keys(m))
            m = asnormalized(mat"0.8*Fe+0.15*Ni+0.04*Cr",1.0)
            @test isapprox(m[n"Fe"], 0.8081, atol=0.0001)
            @test isapprox(m[n"Ni"], 0.1515, atol=0.0001)
            @test isapprox(m[n"Cr"], 0.0404, atol=0.0001)
            @test analyticaltotal(m)==1.0
            lm = labeled(m)
            @test all(e->lm[MassFractionLabel("N[0.8×Fe+0.15×Ni+0.04×Cr,1.0]",e)]==m[e],keys(m))
            @test haskey(m,n"Fe")
            @test !haskey(m,n"Li")
            m = parsedtsa2comp("K411,(O:42.36),(Mg:8.85),(Si:25.38),(Ca:11.06),(Fe:11.21),4.0")
            @test name(m)=="K411"
            @test m[n"Fe"]==0.1121
            @test density(m)==4.0
            @test todtsa2comp(m)=="K411,(Fe:11.21),(Si:25.379999999999995),(O:42.36),(Mg:8.85),(Ca:11.06),4.0"
            cl = NeXLCore.compositionlibrary()
            @test cl["SRM93a"][n"Na"]==0.0295
            @test isapprox(cl["NIST K2789"][n"U"],0.2120,atol=0.0001)
        end
        @testset "Film" begin
            f = Film(pure(n"C"), 1.0e-6)
            @test repr(f)=="10.0 nm of Pure C"
            @test isapprox(0.981955, transmission(f,n"O K-L3",deg2rad(40.0)), atol=0.000001)
            @test material(f)[n"C"]==1.0
            @test thickness(f)==1.0e-6 # cm
        end
end
