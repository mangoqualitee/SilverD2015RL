### A Pluto.jl notebook ###
# v0.20.10

using Markdown
using InteractiveUtils

# ╔═╡ 016ec0a4-4db4-11f0-2157-0379144c786d
begin
	import Pkg
	Pkg.activate(Base.current_project())
end

# ╔═╡ 252cfc52-9459-4ae3-a7b5-82c05aeba1fa
let
	include("../src/RLExperimentsUtils.jl")
	include("../src/MCPrediction.jl")
end

# ╔═╡ a13bc2db-64c3-4a82-b685-05a0120be2ae
begin
	import .RLExperimentsUtils:@do_while,isconverged
	import .MCPrediction:Policy,createrandompolicy,mcpolicyevaluation,ActionValue,Policy
end

# ╔═╡ 9bfeca5d-2205-444b-9613-678983d8479e
MCPrediction.main()

# ╔═╡ 167f2b0a-e60b-4756-a485-0f88e8b5a830
policyevaluation = mcpolicyevaluation

# ╔═╡ f68e24d5-46bb-4d0d-bb25-0f1ae4903121
function policyimprovement(q::ActionValue)::Policy
	slen, alen = size(q)
	π̃ = zeros((size(q))...)
	ϵ = 0.7  # todo: take this from scheduler
	m = size(π̃)[2]
	aᵒ = [argmax(q[si, :]) for si in 1:slen]
	println(q)
	println(aᵒ)
	for si in 1:slen
		π̃[si, aᵒ[si]] += ϵ
	end
	π̃ .+= (1-ϵ)/m
	π̃
end

# ╔═╡ aa4a683c-97f0-4efe-8ff1-22805db02530
function gpi(π₁; k::UInt64)::Policy
	π̂ = π₁
	πᵒ = zeros((size(π₁))...)
	
	ispolicystable = false
	num_iter = 0
	q₁ = zeros((size(π₁))...)
	while ((~ispolicystable) && (num_iter<k))
		q_π̂ = policyevaluation(q₁, π̂; k=1000)
		q₁ = q_π̂
		πᵒ = policyimprovement(q_π̂)
		println("Old policy: ", π̂)
		println("New policy: ", πᵒ)
		
		ispolicystable = isconverged(πᵒ, π̂)
		π̂ = πᵒ
		num_iter += 1
	end

	πᵒ
end

# ╔═╡ 3e915b76-b08f-4e74-a585-133f006f80d9
begin
	π₁ = createrandompolicy()
	πᵒ = gpi(π₁; k=UInt(1))
end

# ╔═╡ Cell order:
# ╠═016ec0a4-4db4-11f0-2157-0379144c786d
# ╠═252cfc52-9459-4ae3-a7b5-82c05aeba1fa
# ╠═a13bc2db-64c3-4a82-b685-05a0120be2ae
# ╟─9bfeca5d-2205-444b-9613-678983d8479e
# ╠═167f2b0a-e60b-4756-a485-0f88e8b5a830
# ╠═f68e24d5-46bb-4d0d-bb25-0f1ae4903121
# ╠═aa4a683c-97f0-4efe-8ff1-22805db02530
# ╠═3e915b76-b08f-4e74-a585-133f006f80d9
