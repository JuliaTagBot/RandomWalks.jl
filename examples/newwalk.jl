using RandomWalks

# using all of the following just so Revise knows about them
using RandomWalks.Actors
using RandomWalks.Lattices
using RandomWalks.LatticeVars
using RandomWalks.LatticeWalks
using RandomWalks.Points
using RandomWalks.WalksBase
using RandomWalks.Walks

using Distributions, BenchmarkTools
using EmpiricalCDFs
using DataFrames

struct WalkParams
    dimension::Int
    ntrials::Int
    nsteps::Int
    lambda::Float64
    alpha::Float64
end

WalkParams() = WalkParams(0,0,0,0.0,0.0)

function Base.print(io::IO, wp::WalkParams)
    println(io, "dimension = ", wp.dimension)
    println(io, "ntrials = ", wp.ntrials)
    println(io, "lambda = ", wp.lambda)
    print(io, "alpha = ", wp.alpha)
#    println(io, "nsteps = ", wp.nsteps)
end

function getcdfs(; dimension = 2, ntrials = 10^3, nsteps = 10^3, lambda = 1e2)
    alpha = 1/2
    wparams = WalkParams(
        dimension,
        ntrials,
        nsteps,
        lambda,
        alpha
        )

    lattice_rates = LatticeVar{dimension}(Exponential(lambda))
    waiting_times = LatticeVarParam{dimension}(Pareto(alpha))
    quenched_lattice = Lattice(waiting_times, lattice_rates)

    walk = MortalWalk(WalkB{dimension}())
    lattice_walk = LatticeWalk(quenched_lattice, walk)

    log_store_range = 1:0.5:12.0

    storing_actor = storing_nsteps_num_sites_visited_actor(logrange(log_store_range))
#    storing_actor = storing_num_sites_visited_actor(logrange(log_store_range))
#    storing_actor2 = storing_num_sites_visited_actor(logrange(log_store_range))

    step_limit_actor = StepLimitActor(nsteps)
    theactors = ActorSet(step_limit_actor, storing_actor)
    walk_plan = WalkPlan(lattice_walk, theactors)
    ecdfs_actor = ECDFsActor(storing_actor);
    max_step_counter = CountActor(step_limit_actor)
    trial_actors = ActorSet(max_step_counter, ecdfs_actor)
    @time trial!(walk_plan, SampleLoopActor(ProgressIter(ntrials), trial_actors));
    check_counter(max_step_counter, "Hit step limit")
    tcdfs = get_ecdf_times(ecdfs_actor);
    ptcdfs = prune(tcdfs)
    return (ptcdfs, ntrials, trial_actors, wparams)
end

function cdfrep(ptcdfs, ntrials)
    cdfs = get_cdfs(ptcdfs)
    times = get_times(ptcdfs)
    nsites = cdfs[:,2]
    nsteps = cdfs[:,1]
    DataFrame([times, length.(nsteps), length.(nsteps) ./ ntrials,  median.(nsteps), extrema.(nsites),
               median.(nsites), mean.(nsites), std.(nsites)],
              [:time, :ncounts, :survp, :median_steps, :minmax_sites, :median_nsites, :mean_nsites, :std_nsites])
end

function vstrials(; dimension = 2, nsteps = 10^2, lambda = 1e3)
    for nexp in 1:7
        for fac in (1, 3, 6)
            (tcdfs, ntrials, trial_actors, wparams) = getcdfs(;ntrials = fac * 10^nexp,
                               nsteps=nsteps, lambda=lambda, dimension = dimension)
            df = cdfrep(tcdfs, ntrials)
            println(wparams)
            println(df)
            println()
        end
    end
end

nothing
