using Distributions
using Plots

function metropolis_hastings(target_pdf, proposal_pdf, proposal_sampler, initial_state, n_samples)
    samples = Vector{typeof(initial_state)}(undef, n_samples)
    current_state = initial_state

    for i in 1:n_samples
        proposed_state = proposal_sampler(current_state)
        acceptance_ratio = target_pdf(proposed_state) * proposal_pdf(current_state, proposed_state) / 
                          (target_pdf(current_state) * proposal_pdf(proposed_state, current_state))

        if rand() < min(1.0, acceptance_ratio)  # Added min(1.0, ...) for safety
            current_state = proposed_state
        end

        samples[i] = current_state
    end

    return samples
end

# Define distributions and functions as above
target_pdf(x) = x ≥ 0 ? exp(-x) : 0.0  # Exponential(1) PDF
proposal_pdf(current, proposed) = pdf(Normal(current, 1), proposed)
proposal_sampler(current) = rand(Normal(current, 1))

# Run sampler
samples = metropolis_hastings(target_pdf, proposal_pdf, proposal_sampler, 0.0, 10_000)

# Plot results
histogram(samples, bins=50, normed=true, label="MCMC Samples")
plot!(0:0.1:10, x -> exp(-x), lw=2, label="True Exponential(1)")
title!("Metropolis-Hastings Sampling from Exponential Distribution")
xlabel!("Value")
ylabel!("Density")