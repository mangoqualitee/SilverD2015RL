# todo: write modular components, and make places for those boxes to be fitted:
# gpi[pe,pi], pe[visit,on/ffline], pi[greedy/egreedy]
module MCPrediction

import Distributions
import GLMakie

include("./RLExperimentsUtils.jl")
include("./Easy21.jl")

import .RLExperimentsUtils:@do_while,sample,isconverged
import .Easy21

Policy = Matrix{Float64}
StateValue = Vector{Float64}
ActionValue = Matrix{Float64}

function createrandompolicy()
	# π = rand(length(Easy21.states), length(Easy21.actions))
	# π ./= sum(π, dims=2)
	π = Matrix((rand(Distributions.Dirichlet(length(Easy21.actions), 1), length(Easy21.states)))')
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

function mcpolicyevaluation(q₁::ActionValue, π::Policy; k=UInt64)::ActionValue
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
		episode = createepisode(s, π)
		
		gₜ = 0
		for t in length(episode):-1:1
			sₜ, aₜ, r = episode[t]
			gₜ = + r + γ * gₜ
			(si, ai) = (Easy21.stateindex(sₜ), Easy21.actionindex(aₜ))
			n[si, ai] += 1
			g[si, ai] += gₜ
		end
		q̂_π = g ./ n

		isactionvaluenotconverged = !(isconverged(q_π, q̂_π))
		(isactionvaluenotconverged) ? nothing : println("ActionValue Converged! num_iter = ", num_iter)
	end ((num_iter < k) && (isactionvaluenotconverged))

	q_π
end

function main()
	s₁ = Easy21.initialstate()
	π₁ = createrandompolicy()
	episode = createepisode(s₁, π₁)

	q₁ = zeros(length(Easy21.states), length(Easy21.actions))
	q_π₁ = mcpolicyevaluation(q₁, π₁; k=2000000)
	v_π₁ = vec(maximum(q_π₁, dims=2))

	plot(v_π₁)
end

# PLOTTING-STATEVALUE === {{{
function plot(v_π₁::StateValue)
	xs = zeros(length(Easy21.states))
	ys = zeros(length(Easy21.states))
	zs = zeros(length(Easy21.states))
	
	for si in 1:length(Easy21.states)
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
		xlabel = "Dealer Showing", 
		ylabel = "Player Sum", 
		zlabel = "v_π₁(s)",
		title = "mcpolicyevaluaiton"
	)
	# GLMakie.limits!(ax3, (1, 21), (1, 10), (-1, 1))
	GLMakie.surface!(ax3, xs, ys, zs)

	fig
end
# }}} === PLOTTING-STATEVALUE


# PRETTY-PRINTING === {{{

function Base.show(io::IO, ::MIME"text/plain", actionvalue::ActionValue)
	print(io, "[\n")
	for i in 1:size(actionvalue)[1]
	    print(io, i, ' ', actionvalue[i, :], '\n')  # todo, format: right-align the state number column
    end
	print(io, "]\n")
end

function Base.show(io::IO, actionvalue::ActionValue)
	print(io, "[\n")
	for i in 1:size(actionvalue)[1]
	    print(io, i, ' ', actionvalue[i, :], '\n')  # todo, format: right-align the state number column
    end
	print(io, "]\n")
end
# }}} === PRETTY-PRINTING

end # module MCPrediction
