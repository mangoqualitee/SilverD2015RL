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

isconverged(a, b)::Bool = (LinearAlgebra.norm(abs.(a - b), Inf) < (global τ = 1e-1))

end # module RLExperimentsUtils
