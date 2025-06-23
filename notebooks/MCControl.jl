### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 016ec0a4-4db4-11f0-2157-0379144c786d
# ╠═╡ show_logs = false
begin
	import Pkg
    Pkg.activate(Base.current_project())

	import SimplePlutoInclude: @plutoinclude
end

# ╔═╡ 6e30f4a2-8edd-4eeb-9321-83f09b3e53fe
# ╠═╡ show_logs = false
begin
	@plutoinclude "../src/RLExperimentsUtils.jl"
	@plutoinclude "../src/MCPrediction.jl"
end

# ╔═╡ 9bfeca5d-2205-444b-9613-678983d8479e
MCPrediction.main()

# ╔═╡ 167f2b0a-e60b-4756-a485-0f88e8b5a830
policyevaluation = mcpolicyevaluation

# ╔═╡ f68e24d5-46bb-4d0d-bb25-0f1ae4903121
function policyimprovement(q::ActionValue, ϵₜ::Vector{Float64})::Policy
	slen, alen = size(q)
	π̃ = zeros((size(q))...)
	m = size(π̃)[2]
	aᵒ = [argmax(q[si, :]) for si in 1:slen]
	for si in 1:slen
		ϵ = ϵₜ[si]
		π̃[si, aᵒ[si]] += ϵ
		π̃[si, :] .+= (1-ϵ)/m
	end
	π̃
end

# ╔═╡ 44de241f-ce93-4234-ba69-c9585eb2ad0e
begin
	n₀ = 100
end

# ╔═╡ aa4a683c-97f0-4efe-8ff1-22805db02530
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
		ϵₜ = [1.0/ (1.0 + (num_iter/n₀)) for si in 1:slen]
		πᵒ = policyimprovement(q_π̂, ϵₜ)
		
		ispolicyunstable = ~(isconverged(πᵒ, π̂))

		π̂ = πᵒ
		num_iter += 1

		(ispolicyunstable) ? nothing : println("Policy Converged! num_iter = ", num_iter)
	end

	πᵒ
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
	πᵒ = gpi(π₁; k=UInt(500))

	q₁ = zeros((size(π₁))...)
	qᵒ = policyevaluation(q₁, πᵒ; k=UInt(1000000))  # todo: mcpe arg q₁ does not matter

	vᵒ = vec(maximum(qᵒ, dims=2))
end

# ╔═╡ 87ba1767-ef37-4df1-87be-e84cdd02899a
MCPrediction.plot(vᵒ)

# ╔═╡ Cell order:
# ╟─016ec0a4-4db4-11f0-2157-0379144c786d
# ╠═6e30f4a2-8edd-4eeb-9321-83f09b3e53fe
# ╟─9bfeca5d-2205-444b-9613-678983d8479e
# ╟─167f2b0a-e60b-4756-a485-0f88e8b5a830
# ╟─f68e24d5-46bb-4d0d-bb25-0f1ae4903121
# ╠═44de241f-ce93-4234-ba69-c9585eb2ad0e
# ╠═aa4a683c-97f0-4efe-8ff1-22805db02530
# ╟─3e915b76-b08f-4e74-a585-133f006f80d9
# ╠═7b9607bf-c6c0-4355-b97c-e3b8d7fbbb70
# ╟─87ba1767-ef37-4df1-87be-e84cdd02899a
