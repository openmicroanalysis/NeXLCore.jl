using Pkg
# Base system
Pkg.activate()
#Pkg.gc()
Pkg.add(PackageSpec(url="https://github.com/usnistgov/BoteSalvatICX.jl.git"))
Pkg.add(PackageSpec(url="https://github.com/usnistgov/FFAST.jl.git"))
Pkg.add(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLUncertainties.jl.git"))
Pkg.add(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLCore.jl.git"))
Pkg.add(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLSpectrum.jl.git"))
Pkg.add(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLMatrixCorrection.jl.git"))
Pkg.add(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLParticle.jl.git"))
Pkg.add(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLDatabase.jl.git"))
Pkg.instantiate()
Pkg.update()
Pkg.develop(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLUncertainties.jl.git"))
Pkg.develop(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLCore.jl.git"))
Pkg.develop(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLSpectrum.jl.git"))
Pkg.develop(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLMatrixCorrection.jl.git"))
Pkg.develop(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLParticle.jl.git"))
Pkg.develop(PackageSpec(url="https://github.com/NicholasWMRitchie/NeXLDatabase.jl.git"))
#Pkg.build()
Pkg.precompile()
Pkg.activate()
