### A Pluto.jl notebook ###
# v0.20.10

using Markdown
using InteractiveUtils

# ╔═╡ 016ec0a4-4db4-11f0-2157-0379144c786d
begin
	import Pkg
	Pkg.activate(Base.current_project())
	
	include("../src/MCPrediction.jl")
	import .MCPrediction
end

# ╔═╡ 9bfeca5d-2205-444b-9613-678983d8479e
MCPrediction.main()

# ╔═╡ Cell order:
# ╠═016ec0a4-4db4-11f0-2157-0379144c786d
# ╠═9bfeca5d-2205-444b-9613-678983d8479e
