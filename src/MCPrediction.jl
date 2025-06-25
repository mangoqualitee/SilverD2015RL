# todo: write modular components, and make places for those boxes to be fitted:
# gpi[pe,pi], pe[visit,on/ffline], pi[greedy/egreedy]
module MCPrediction

import Distributions
using GLMakie

include("./RLExperimentsUtils.jl")
include("./Easy21.jl")

import .RLExperimentsUtils: @do_while, sample, isconverged
import .Easy21

Policy = Matrix{Float64}
StateValue = Vector{Float64}
ActionValue = Matrix{Float64}

Steps = UInt64

function createrandompolicy()
    # π = rand(length(Easy21.states), length(Easy21.actions))
    # π ./= sum(π, dims=2)
    π = Matrix(
        (rand(Distributions.Dirichlet(length(Easy21.actions), 1), length(Easy21.states)))',
    )
    # samples from triangle rather than cube -> triangle projection
    # # verify random policy
    # begin
    # 	π = createrandompolicy()
    # 	isvalidpolicy = all(isapprox.(sum(π, dims=2), 1.0))
    # 	string("ispolicyvalid ?= ", isvalidpolicy)
    # end
    π
end

function createepisode(s₁::Easy21.StartState, π::Policy)::Easy21.Episode
    episode = []
    s = s₁
    r = 0
    while r == 0
        si = Easy21.stateindex(s)
        π_s = π[si, :]
        a = sample(Easy21.actions, π_s)
        (s′, r) = Easy21.step(s, a)
        push!(episode, (s, a, r))
        s = s′
    end

    episode
end

function mcpolicyevaluation(q₁::ActionValue, π::Policy; k::UInt64)::ActionValue
    γ = 1.0  # should I include this inside Env?

    q̂_π = q₁
    q_π = zeros((size(q₁))...)

    g = zeros((size(q₁))...)
    n = zeros((size(q₁))...)

    num_iter = 0
    @do_while begin
        num_iter += 1
        q_π = q̂_π

        s = Easy21.initialstate()
        episode = createepisode(s, π)  # todo: move this outside; create k episodes before hand

        gₜ = 0
        for t = length(episode):-1:1
            sₜ, aₜ, r = episode[t]
            gₜ = + r + γ * gₜ
            (si, ai) = (Easy21.stateindex(sₜ), Easy21.actionindex(aₜ))
            n[si, ai] += 1
            g[si, ai] += gₜ
        end
        q̂_π = g ./ n

        isactionvaluenotconverged = !(isconverged(q_π, q̂_π))
        (isactionvaluenotconverged) ? nothing :
        println("ActionValue Converged! num_iter = ", num_iter)
    end ((num_iter < k) && (isactionvaluenotconverged))

    q_π
end

mutable struct MCPE
    g::Matrix{Float64}
    n::Matrix{UInt64}
    q::ActionValue

    function MCPE(g::Matrix{Float64}, n::Matrix{UInt64}, q::ActionValue)::MCPE
        new(copy(g), copy(n), copy(q))
    end

    function MCPE(slen::UInt64, alen::UInt64)::MCPE
        new(
            zeros(Float64, slen, alen),
            zeros(UInt64, slen, alen),
            zeros(Float64, slen, alen),
        )
    end
end

function mcpolicyevaluation!(mcpe::MCPE, π::Policy; k::Steps)::Nothing
    γ = 1.0  # should I include this inside Env?

    num_iter = 0
    @do_while begin
        num_iter += 1
        mcpeold = MCPE(mcpe.g, mcpe.n, mcpe.q)

        s = Easy21.initialstate()
        episode = createepisode(s, π)

        gₜ = 0.0
        for t = length(episode):-1:1
            (sₜ, aₜ, rₜ) = episode[t]
            (si, ai) = (Easy21.stateindex(sₜ), Easy21.actionindex(aₜ))

            gₜ = rₜ + γ * gₜ

            mcpe.g[si, ai] += gₜ
            mcpe.n[si, ai] += 1
            mcpe.q[si, ai] = mcpe.g[si, ai] / mcpe.n[si, ai]
        end

        isavaluestable = false
        if num_iter % 1000 == 0
            isavaluestable = isconverged(mcpe.q, mcpeold.q)
            if isavaluestable
                println("ActionValue Converged! num_iter = ", num_iter)

                # nids = [(si,ai) for si in 1:size(mcpe.q)[1] for ai in 1:size(mcpe.q)[2] if mcpe.n[si, ai] != mcpeold.n[si, ai]]
                # println("previous n changed indexs ", nids)
                # println("previous g,n,q changed values ")
                # for (s, a) in nids
                # 	println(mcpe.g[s, a], ' ', mcpe.n[s, a], ' ', mcpe.q[s, a])
                # 	println(mcpeold.g[s, a], ' ', mcpeold.n[s, a], ' ', mcpeold.q[s, a])
                # end

            end
        end
    end ((num_iter < k) && (!isavaluestable))

end

function main()
    s₁ = Easy21.initialstate()
    π₁ = createrandompolicy()
    episode = createepisode(s₁, π₁)

    q₁ = zeros(length(Easy21.states), length(Easy21.actions))
    q_π₁ = mcpolicyevaluation(q₁, π₁; k = UInt(2000000))
    v_π₁ = vec(maximum(q_π₁, dims = 2))

    plot(v_π₁)
end

# PLOTTING-STATEVALUE === {{{
function plot(v_π₁::StateValue)
    xs = zeros(length(Easy21.states))
    ys = zeros(length(Easy21.states))
    zs = zeros(length(Easy21.states))

    for si = 1:length(Easy21.states)
        s = Easy21.states[si]
        (y, x) = (dealerfirstcard, playersum) = s
        z = v_π₁[si]

        xs[si] = x
        ys[si] = y
        zs[si] = z
    end

    fig = GLMakie.Figure()
    ax3 = GLMakie.Axis3(
        fig[1, 1],
        xlabel = "Player Sum",
        ylabel = "Dealer Showing",
        zlabel = "v_π₁(s)",
        title = "mcpolicyevaluaiton",
        aspect = :data,
    )
    # GLMakie.limits!(ax3, (1, 21), (1, 10), (-1, 1))
    GLMakie.surface!(ax3, xs, ys, zs)

    fig
end
# }}} === PLOTTING-STATEVALUE


# PRETTY-PRINTING === {{{

function Base.show(io::IO, ::MIME"text/plain", actionvalue::ActionValue)
    print(io, "[\n")
    for i = 1:size(actionvalue)[1]
        print(io, i, ' ', actionvalue[i, :], '\n')  # todo, format: right-align the state number column
    end
    print(io, "]\n")
end

function Base.show(io::IO, actionvalue::ActionValue)
    print(io, "[\n")
    for i = 1:size(actionvalue)[1]
        print(io, i, ' ', actionvalue[i, :], '\n')  # todo, format: right-align the state number column
    end
    print(io, "]\n")
end
# }}} === PRETTY-PRINTING

end # module MCPrediction
