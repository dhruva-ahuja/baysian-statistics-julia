using Distributions

struct Init
    mu_0;
    sigma2_0;
    nu_0;
    beta_0;
end

function update_mu(n, y_bar, mu_0, sigma2_0, sigma2)
    sig2_1 = 1 / (n/sigma2 + 1/sigma2_0)
    mu_1 = (n*y_bar/sigma2 + mu_0/sigma2_0) * sig2_1

    rand(Normal(mu_1, sig2_1 ^ 0.5))
end


function update_sigma2(n, nu_0, beta_0, y, mu)
    nu_1 = nu_0 + n/2
    beta_1 = beta_0 + sum((y .- mu) .^ 2) / 2

    rand(InverseGamma(nu_1, beta_1))
end


function gibbs(y, init; n_iter = 5000)
    n = length(y)
    y_bar = mean(y)

    mu_now = init.mu_0
    result = []

    for _ in 1:n_iter
        sigma2_now = update_sigma2(n, init.nu_0, init.beta_0, y, mu_now)
        mu_now = update_mu(n, y_bar, init.mu_0, init.sigma2_0, sigma2_now)
        push!(result, (mu_now, sigma2_now))
    end
    result
end

y = [-0.2, -1.5, -5.3, 0.3, -0.8, -2.2]
init = Init(1.0, 1.0, 1.0, 1.0)

result = gibbs(y, init)

mean(map(x->x[1], result[1001:5000]))
