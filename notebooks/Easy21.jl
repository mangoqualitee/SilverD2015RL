### A Pluto.jl notebook ###
# v0.20.10

using Markdown
using InteractiveUtils

# ╔═╡ 79f07797-95ac-42c3-8b6c-e0085e80795e
@enum Action begin
	hit
	stick
end

# ╔═╡ cd93dacf-d4b0-4ca0-bd8f-dace419cb9a0
Card = Int

# ╔═╡ 495aee28-41de-4272-a115-bbc41719a752
Result = Tuple{Tuple{Int, Int}, Int}

# ╔═╡ 9bee9ddb-7f9b-4741-99df-9ad74dad587d
begin
	import Random
	# The game is played with an infinite deck of cards (i.e. cards are sampled with replacement)
	# Each draw from the deck results in a value between 1 and 10 (uniformly distributed) with a colour of red (probability 1/3) or black (probability 2/3).
	# There are no aces or picture (face) cards in this game
	function draw()::Card
		number = rand(1:10)
		color = rand() < 2.0/3.0 ? 1 : -1
	
		card = color * number
		return card
	end
end

# ╔═╡ 0760ebb9-5088-4275-8728-39b53058caa1
# verify
begin
	function counter(arr)
		counting = Dict{Any, Int}()
		for el in arr
			if haskey(counting, el)
				counting[el]+=1
			else
				counting[el]=1
			end
		end
		return counting
	end
	
	#sample
	N = 100000
	counts = counter([draw() for _ in 1:N])
	
	# count
	num_count = Dict{Any, Int}(tuple.(1:10, 0))
	col_count = Dict{Any, Int}([(-1, 0), (+1, 0)])

	for (k,v) in counts
		# println(k, ' ', v)
		col_count[-1] += (sign(k) == -1) ? v : 0
		col_count[+1] += (sign(k) == +1) ? v : 0
		num_count[(abs(k))] += v
	end

	# normalize
	col_count = Dict(k=>v/N for (k,v) in col_count)
	num_count = Dict(k=>v/N for (k,v) in num_count)

	# present
	println("Verifying distribution draw()")
	println(col_count)
	println(num_count)
end

# ╔═╡ 4aa4eb6f-2f6a-4963-92bc-4a116c866e52
function isbust(mysum)::Bool
	((mysum < 1) || (mysum > 21))
end

# ╔═╡ eda72542-7a37-4eb2-a989-a24b1f4a32ca
begin
	import Base: step  # import to override
	function step(s, a::Action)::Result
		dealerfirstcard, playersum = s
		
		# logic
		# Each turn the player may either stick or hit
		if a == hit
			# If the player hits then she draws another card from the deck
			playercard = draw()

			# The values of the player’s cards are added (black cards) or subtracted (red cards)
			playersum += playercard

			# If the player’s sum exceeds 21, or becomes less than 1, then she “goes bust” and loses the game (reward -1)
			if isbust(playersum)
				println("Player went bust")
				s′ = (dealerfirstcard, playersum)
				r = -1
				return (s′, r)
			end

			s′ = (dealerfirstcard, playersum)
			r = 0
			return (s′, r)
		elseif a == stick
			# If the player sticks she receives no further cards
			
			# If the player sticks then the dealer starts taking turns. The dealer always sticks on any sum of 17 or greater, and hits otherwise.
			dealersum = dealerfirstcard
			while dealersum < 17
				dealercard = draw()
				dealersum += dealercard
			end

			# If the dealer goes bust, then the player wins; 
			if isbust(dealersum)
				println("Dealer went bust")
				s′ = (dealerfirstcard, playersum)
				r = +1
				return (s′, r)
			end

			# otherwise, the outcome – win (reward +1), lose (reward -1), or draw (reward 0) – is the player with the largest sum.
			r = sign(playersum - dealersum)

			s′ = (dealerfirstcard, playersum)
			return s′, r
		end
	end
end

# ╔═╡ f2e2ace0-b616-4b63-b4c6-de6fe270ed06
begin
	# At the start of the game both the player and the dealer draw one black card (fully observed)
	playerfirstcard = abs(draw())
	dealerfirstcard = abs(draw())

	playersum = playerfirstcard

	s₁, a₁ = ((dealerfirstcard, playersum), hit)
	s′, r = step(s₁, a₁)
	print(s′, ' ', r)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "fa3e19418881bf344f5796e1504923a7c80ab1ed"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"
"""

# ╔═╡ Cell order:
# ╠═79f07797-95ac-42c3-8b6c-e0085e80795e
# ╠═cd93dacf-d4b0-4ca0-bd8f-dace419cb9a0
# ╠═495aee28-41de-4272-a115-bbc41719a752
# ╠═9bee9ddb-7f9b-4741-99df-9ad74dad587d
# ╟─0760ebb9-5088-4275-8728-39b53058caa1
# ╠═4aa4eb6f-2f6a-4963-92bc-4a116c866e52
# ╠═eda72542-7a37-4eb2-a989-a24b1f4a32ca
# ╠═f2e2ace0-b616-4b63-b4c6-de6fe270ed06
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
