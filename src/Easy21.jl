module Easy21

# export step

import Base: step  # import to override

import Random

Card = Int  # [-10, ...-1, 1, ..., 10]
CardSum = Int  # 1 <= x <= 21
State = Tuple{Card,CardSum}

StartCard = Int  # [1, ..., 10]
StartState = Tuple{StartCard,StartCard}

@enum Action begin
    hit
    stick
end

Reward = Int

EnvResult = Tuple{State,Reward}

Episode = Vector{Tuple{State,Action,Reward}}

cards::Vector{Card} = vcat(-10:-1, 1:10)
cardsums::Vector{CardSum} = vcat(1:21)
firstcards::Vector{StartCard} = vcat(1:10)
states::Vector{State} = [(c, cs) for c in firstcards for cs in cardsums]
startstates::Vector{StartState} = [(c, cs) for c in firstcards for cs in firstcards]
# todo: how do you ensure (not verify) your types follow the above properties?
actions = collect(instances(Easy21.Action))
rewards = [-1, 0, +1]


# The game is played with an infinite deck of cards (i.e. cards are sampled with replacement)
# Each draw from the deck results in a value between 1 and 10 (uniformly distributed) with a colour of red (probability 1/3) or black (probability 2/3).
# There are no aces or picture (face) cards in this game
function draw()::Card
    number = rand(1:10)
    color = rand() < 2.0 / 3.0 ? 1 : -1

    card = color * number
    return card
end

isbust(mysum::CardSum)::Bool = ((mysum < 1) || (mysum > 21))

function step(s::State, a::Action)::EnvResult
    dealerfirstcard, playersum = s

    # logic
    # Each turn the player may either stick or hit
    if a == hit
        # If the player hits then she draws another card from the deck
        playercard = draw()

        # The values of the player’s cards are added (black cards) or subtracted (red cards)
        # oldplayersum = playersum  # for debugging ((9, 16), hit) going bust
        playersum += playercard

        # If the player’s sum exceeds 21, or becomes less than 1, then she “goes bust” and loses the game (reward -1)
        if isbust(playersum)
            # println("Player went bust $playersum = $oldplayersum + $playercard")
            # println("Player went bust")
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
            # println("Dealer went bust")
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

function initialstate()::Easy21.StartState
    rand(startstates)
end

function stateindex(s::State)
    i = findfirst(x -> x==s, states)
    isnothing(i) && error("State $s not found in 𝒮")
    i′ = findlast(x -> x==s, states)
    @assert i == i′ "Multiple occurrences of $s in 𝒮: at $i and $i′"
    i
end

function actionindex(a::Action)
    Int(a) + 1
end

function main()
    playerfirstcard = abs(draw())
    dealerfirstcard = abs(draw())

    playersum = playerfirstcard

    s₁, a₁ = ((dealerfirstcard, playersum), hit)
    s′, r = step(s₁, a₁)
    print(s′, ' ', r)
end


# PRETTY-PRINTING === {{{
function Base.show(io::IO, ::MIME"text/plain", action::Action)
    action_names = Dict(hit => "🟢 hit", stick => "🔴 stick")
    print(io, action_names[action])
end

function Base.show(io::IO, action::Action)
    action_names = Dict(hit => "🟢 hit", stick => "🔴 stick")
    print(io, action_names[action])
end

function Base.show(io::IO, ::MIME"text/plain", episode::Episode)
    print(io, "[\n")
    for res in episode
        (s, a, r) = res
        print(io, s, ' ', a, ' ', r)
        print(io, '\n')
    end
    print(io, "]\n")
end

function Base.show(io::IO, episode::Episode)
    print(io, "[\n")
    for res in episode
        (s, a, r) = res
        print(io, s, ' ', a, ' ', r, '\n')
    end
    print(io, "]\n")
end

function Base.show(io::IO, ::MIME"text/plain", episode::Episode)
    print(io, "[\n")
    for res in episode
        (s, a, r) = res
        print(io, s, ' ', a, ' ', r, '\n')
    end
    print(io, "]\n")
end
# }}} === PRETTY-PRINTING

end # module Easy21
