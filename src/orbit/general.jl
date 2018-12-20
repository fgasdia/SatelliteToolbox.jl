#== # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   Functions to compute general values related to the orbit.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ==#

export @check_orbit
export angvel, dArgPer, dRAAN, period

################################################################################
#                                  Overloads
################################################################################

copy(orb::Orbit) = Orbit(orb.t, orb.a, orb.e, orb.i, orb.Ω, orb.ω, orb.f)

function display(orb::Orbit)
    d2r = 180/π

    # Definition of colors that will be used for printing.
    b = "\x1b[1m"
    d = "\x1b[0m"
    g = "\x1b[1m\x1b[32m"
    y = "\x1b[1m\x1b[33m"

    # Print the TLE information.
    println()
    print("                 $(g)Orbit$(d)\n")
    print("$(y)  ======================================$(d)\n")
    print("$(b)                  t = $(d)"); @printf("%14.5f\n",    orb.t)
    print("$(b)    Semi-major axis = $(d)"); @printf("%13.4f km\n", orb.a/1000)
    print("$(b)       Eccentricity = $(d)"); @printf("%15.6f\n",    orb.e)
    print("$(b)        Inclination = $(d)"); @printf("%13.4f ˚\n",  orb.i*d2r)
    print("$(b)               RAAN = $(d)"); @printf("%13.4f ˚\n",  orb.Ω*d2r)
    print("$(b)    Arg. of Perigee = $(d)"); @printf("%13.4f ˚\n",  orb.ω*d2r)
    print("$(b)       True Anomaly = $(d)"); @printf("%13.4f ˚\n",  orb.f*d2r)
end

################################################################################
#                                    Macros
################################################################################

"""
    macro check_orbit(a, e)

Verify if the orbit with semi-major axis `a` [m] and eccentricity `e` is valid.
This macro throws an exception if the orbit is not valid.

Return `true` is the orbit is valid, and `false` otherwise.

"""
macro check_orbit(a, e)
    quote
        # Check if the arguments are valid.
        if $(esc(a)) < 0
            throw(ArgumentError("The semi-major axis must be greater than 0."))
        end

        if !( 0 <= $(esc(e)) < 1 )
            throw(ArgumentError("The eccentricity must be within the interval 0 <= e < 1."))
        end

        # Compute the orbit perigee and check if it is inside Earth.
        perigee = $(esc(a))*(1-$(esc(e)))

        if perigee < R0
            throw(ArgumentError("The orbit perigee ($perigee m) is inside Earth!"))
        end
    end
end


################################################################################
#                                  Functions
################################################################################

"""
    function Orbit(a::Number, e::Number, i::Number, Ω::Number, ω::Number, f::Number)

Create an orbit with semi-major axis `a` [m], eccentricity `e`, inclination `i`
[rad], right ascension of the ascending node `Ω` [rad], argument of perigee `ω`
[rad], and true anomaly `f` [rad].

# Returns

An object of type `Orbit` with the specified orbit. The orbit epoch is defined
as 0.0.

"""
Orbit(a::Number, e::Number, i::Number, Ω::Number, ω::Number, f::Number) =
    Orbit(0.0, a, e, i, Ω, ω, f)

################################################################################
#                                  Functions
################################################################################

"""
    function angvel(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    function angvel(orb::Orbit, pert::Symbol = :J2)

Compute the angular velocity [rad/s] of an object in an orbit with semi-major
axis `a` [m], eccentricity `e`, and inclination `i` [rad], using the
perturbation terms specified by the symbol `pert`. The orbit can also be
specified by `orb`, which is an instance of the structure `Orbit`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

If `pert` is omitted, then it defaults to `:J2`.

"""
function angvel(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    # Unperturbed orbit period.
    n0 = sqrt(m0/Float64(a)^3)

    # Perturbation computed using a Keplerian orbit.
    if pert == :J0
        return n0
    # Perturbation computed using perturbations terms up to J2.
    elseif pert == :J2
        # Semi-lactum rectum.
        p = a*(1-e^2)

        # Orbit period considering the perturbations (up to J2).
        return n0 + 3R0^2*J2/(4p^2)*n0*(sqrt(1-e^2)*(3cos(i)^2-1) + (5cos(i)^2-1))
    else
        throw(ArgumentError("The perturbation parameter $pert is not defined."))
    end

end

angvel(orb::Orbit, pert::Symbol = :J2) = angvel(orb.a, orb.e, orb.i, pert)

"""
    function dArgPer(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    function dArgPer(orb::Orbit, pert::Symbol = :J2)

Compute the time-derivative of the argument of perigee [rad/s] of an orbit with
semi-major axis `a` [m], eccentricity `e`, and inclination `i` [rad], using the
perturbation terms specified by the symbol `pert`. The orbit can also be
specified by `orb`, which is an instance of the structure `Orbit`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

If `pert` is omitted, then it defaults to `:J2`.

"""
function dArgPer(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    # Perturbation computed using a Keplerian orbit.
    if pert == :J0
        return 0.0
    # Perturbation computed using perturbations terms up to J2.
    elseif pert == :J2
        # Semi-lactum rectum.
        p = a*(1.0-e^2)

        # Unperturbed orbit period.
        n0 = angvel(a, e, i, :J0)

        # Perturbation of the argument of perigee.
        return 3R0^2*J2/(4p^2)*n0*(5cos(i)^2-1)
    else
        throw(ArgumentError("The perturbation parameter $pert is not defined."))
    end

end

dArgPer(orb::Orbit, pert::Symbol = :J2) = dArgPer(orb.a, orb.e, orb.i, pert)

"""
    function dRAAN(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    function dRAAN(orb::Orbit, pert::Symbol = :J2)

Compute the time-derivative of the right ascension of the ascending node [rad/s]
of an orbit with semi-major axis `a` [m], eccentricity `e`, and inclination `i`
[rad], using the perturbation terms specified by the symbol `pert`. The orbit
can also be specified by `orb`, which is an instance of the structure `Orbit`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

If `pert` is omitted, then it defaults to `:J2`.

"""
function dRAAN(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    # Perturbation computed using a Keplerian orbit.
    if pert == :J0
        return 0.0
    # Perturbation computed using perturbations terms up to J2.
    elseif pert == :J2
        # Semi-lactum rectum.
        p = a*(1-e^2)

        # Unperturbed orbit period.
        n0 = angvel(a, e, i, :J0)

        # Perturbation of the right ascension of the ascending node.
        return -3/2*R0^2/(p^2)*n0*J2*cos(i)
    else
        throw(ArgumentError("The perturbation parameter $pert is not defined."))
    end
end

dRAAN(orb::Orbit, pert::Symbol = :J2) = dRAAN(orb.a, orb.e, orb.i, pert)

"""
    function period(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    function period(orb::Orbit, pert::Symbol = :J2)

Compute the period [s] of an object in an orbit with semi-major axis `a` [m],
eccentricity `e`, and inclination `i` [rad], using the perturbation terms
specified by the symbol `pert`. The orbit can also be specified by `orb`, which
is an instance of the structure `Orbit`.

`pert` can be:

* `:J0`: Consider a Keplerian orbit.
* `:J2`: Consider the perturbation terms up to J2.

If `pert` is omitted, then it defaults to `:J2`.

"""
function period(a::Number, e::Number, i::Number, pert::Symbol = :J2)
    n = angvel(a, e, i, pert)
    2π/n
end

period(orb::Orbit, pert::Symbol = :J2) = period(orb.a, orb.e, orb.i, pert)
