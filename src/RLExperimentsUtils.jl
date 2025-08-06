module RLExperimentsUtils

import LinearAlgebra
import StatsBase

macro do_while(body, condition)
    quote
        while true
            $(esc(body))
            $(esc(condition)) || break
        end
    end
end

function sample(a, b)
    StatsBase.sample(a, StatsBase.Weights(b))
end

function isconverged(a, b)::Bool
    diff = a - b
    Δ = (LinearAlgebra.norm(abs.(diff), Inf))
    Δ < (global τ = 1e-6)
end

end # module RLExperimentsUtils
