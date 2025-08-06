### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 016ec0a4-4db4-11f0-2157-0379144c786d
# ╠═╡ show_logs = false
begin
	import Pkg
    Pkg.activate(Base.current_project())
end

# ╔═╡ 23e17f77-012a-452e-9625-b1ec9e51b2b6
begin
	import SimplePlutoInclude: @plutoinclude
	import GLMakie
end

# ╔═╡ 6e30f4a2-8edd-4eeb-9321-83f09b3e53fe
# ╠═╡ show_logs = false
begin
	@plutoinclude "../src/RLExperimentsUtils.jl"
	@plutoinclude "../src/MCPrediction.jl"
end

# ╔═╡ 9bfeca5d-2205-444b-9613-678983d8479e
# MCPrediction.main()

# ╔═╡ 167f2b0a-e60b-4756-a485-0f88e8b5a830
begin
	policyevaluation! = mcpolicyevaluation!
	# policyevaluation = mcpolicyevaluation
end

# ╔═╡ f68e24d5-46bb-4d0d-bb25-0f1ae4903121
function policyimprovement(q::ActionValue, ϵₜ::Vector{Float64})::Policy
	slen, alen = size(q)
	π̃ = zeros((size(q))...)
	for si in 1:slen
		ϵ = ϵₜ[si]
		aᵒ = argmax(q[si, :])
		π̃[si, aᵒ] += (1-ϵ)
		π̃[si, :] .+= ϵ/alen
	end
	π̃
end

# ╔═╡ c9eb93e4-33f2-4099-9097-b6e5e3ecdd60
begin
	function plotpolicy(π::Policy)
		slen = length(Easy21.states)
		
		xs = zeros(slen)
		ys = zeros(slen)
		zs = zeros(slen)
		
		for si in 1:slen
			s = Easy21.states[si]
			(y, x) = (dealerfirstcard, playersum) = s
			z = (argmax(π[si, :]) == 1) ? maximum(π[si, :]) : -maximum(π[si, :])
		
			xs[si] = x
			ys[si] = y
			zs[si] = z
		end

		fig = GLMakie.Figure()
		ax = GLMakie.Axis(
			fig[1, 1],
			xlabel = "Player Sum",
			ylabel = "Dealer Showing",
			title = "Easy21::Policy",
			aspect=GLMakie.DataAspect()
		)
		hm = GLMakie.heatmap!(ax, xs, ys, zs, colormap=:redblue)
		
		# Add action text labels
		for si in 1:slen
			s = Easy21.states[si]
			(y, x) = (dealerfirstcard, playersum) = s
			action_text = (argmax(π[si, :]) == 1) ? "H" : "S"
			text_color = abs(zs[si]) > 0.9 ? :black : :white
			
			GLMakie.text!(ax, x, y, 
				text=action_text,
				color=text_color,
				fontsize=12,
				align=(:center, :center))
		end
		
		# Add colorbar with clear labels
	    cb = GLMakie.Colorbar(fig[1, 2], hm, 
	                         label = "Stick / Hit",
	                         labelsize = 12)
		fig
	end
end

# ╔═╡ aa4a683c-97f0-4efe-8ff1-22805db02530
# ╠═╡ disabled = true
#=╠═╡
function gpi(π₁; k::UInt64)::Policy
	slen, alen = size(π₁)
	π̂ = π₁
	πᵒ = zeros((size(π₁))...)
	
	ispolicyunstable = true
	num_iter = 0
	q₁ = zeros((size(π₁))...)
	while ((ispolicyunstable) && (num_iter<k))
		q_π̂ = policyevaluation(q₁, π̂; k=UInt(1))
		q₁ = q_π̂
		# ϵₜ = [(1.0/ (1.0 + sum(n[si, :])/n₀)) for si in 1:slen]
		ϵₜ = [1.0/ (1.0 + (num_iter/(global n₀ = 100))) for si in 1:slen]
		πᵒ = policyimprovement(q_π̂, ϵₜ)
		
		ispolicyunstable = ~(isconverged(πᵒ, π̂))

		π̂ = πᵒ
		num_iter += 1

		(ispolicyunstable) ? nothing : println("Policy Converged! num_iter = ", num_iter)
	end

	πᵒ
end
  ╠═╡ =#

# ╔═╡ c3c40a1b-dd7c-491a-b8cb-db881e26b3a9
function gpi(π₁; k::UInt64)::Policy
	mcpe = MCPE((UInt.(size(π₁)))...)
	mcpeold = MCPE((UInt.(size(π₁)))...)
	n₀ = 3500
	
	slen, alen = size(π₁)
	π̂ = copy(π₁)

	ispolicyunstable = true
	num_iter = 0
	@do_while begin
		num_iter += 1
		πold = π̂

		# todo: should this function store n[si, ai] (that happen in pe)?
		policyevaluation!(mcpe, π̂; k=UInt(4))
		ϵₜ = [(n₀/ (n₀ + sum(mcpe.n[si, :]))) for si in 1:slen]
		π̂ = policyimprovement(mcpe.q, ϵₜ)  # ϵ = f(s) and not an array ?

		ispolicyunstable = true
		if (num_iter % 500 == 0)
			ispolicyunstable = !(isconverged(π̂, πold))
			(ispolicyunstable) ? nothing : println("Policy Converged! num_iter = ", num_iter)

			# mcpenew = MCPE(mcpe.g, mcpe.n, mcpe.q)
			# mcpe = MCPE(mcpeold.g, mcpeold.n, mcpeold.q)
			# mcpeold = mcpenew
			# bad idea: too slow
			# maybe to get rid of baggage of history we have α
			# so todo: make this function accept different types of pe
			# not just "policyevaluation!", think, first implement mcpe with α
		end
	end ((num_iter < k) && (ispolicyunstable))

	π̂
end

# ╔═╡ 3e915b76-b08f-4e74-a585-133f006f80d9
# ╠═╡ show_logs = false
# ╠═╡ disabled = true
#=╠═╡
begin
	π₁ = createrandompolicy()
	# πᵒ = gpi(π₁; k=UInt(1))
	q₁ = zeros((size(π₁))...)
	q_π₁ = policyevaluation(q₁, π₁; k=100000)

	π₂ = policyimprovement(q_π₁)
	q_π₂ = policyevaluation(q_π₁, π₂; k=100000)

	π₃ = policyimprovement(q_π₂)
	q_π₃ = policyevaluation(q_π₂, π₃; k=100000)
end
  ╠═╡ =#

# ╔═╡ 7b9607bf-c6c0-4355-b97c-e3b8d7fbbb70
begin
	π₁ = createrandompolicy()
	πᵒ = gpi(π₁; k=UInt(100000))
	mcpe = MCPE((UInt.(size(πᵒ)))...)
end

# ╔═╡ 9a10a464-0476-427c-81d1-a5eca5f74af9
plotpolicy(πᵒ)

# ╔═╡ e144ffee-e353-42ed-b431-fd4b6d68c398
begin
	# π₁ = createrandompolicy()
	policyevaluation!(mcpe, πᵒ; k=UInt(20000))
	qᵒ = mcpe.q
	vᵒ = vec(maximum(qᵒ, dims=2))
	MCPrediction.plot(vᵒ)
end

# ╔═╡ Cell order:
# ╠═016ec0a4-4db4-11f0-2157-0379144c786d
# ╠═23e17f77-012a-452e-9625-b1ec9e51b2b6
# ╠═6e30f4a2-8edd-4eeb-9321-83f09b3e53fe
# ╟─9bfeca5d-2205-444b-9613-678983d8479e
# ╟─167f2b0a-e60b-4756-a485-0f88e8b5a830
# ╠═f68e24d5-46bb-4d0d-bb25-0f1ae4903121
# ╟─c9eb93e4-33f2-4099-9097-b6e5e3ecdd60
# ╟─aa4a683c-97f0-4efe-8ff1-22805db02530
# ╠═c3c40a1b-dd7c-491a-b8cb-db881e26b3a9
# ╟─3e915b76-b08f-4e74-a585-133f006f80d9
# ╠═7b9607bf-c6c0-4355-b97c-e3b8d7fbbb70
# ╟─9a10a464-0476-427c-81d1-a5eca5f74af9
# ╠═e144ffee-e353-42ed-b431-fd4b6d68c398
