data("PlantGrowth")
# ?PlantGrowth
head(PlantGrowth)

boxplot(weight ~ group, data = PlantGrowth)

lmod <- lm(weight ~ group, data = PlantGrowth)
summary(lmod)

anova(lmod)

library(rjags)

mod_string <- "
model {
    for (i in 1:length(y)) {
        y[i] ~ dnorm(mu[grp[i]], prec)
    }
    for (j in 1:3) {
        mu[j] ~ dnorm(0.0, 1.0e-6)
    }
    prec ~ dgamma(2.5, 2.5)
    sig <- sqrt(1.0 / prec)
}
"

set.seed(82)
str(PlantGrowth)
data_jags <- list(
    y = PlantGrowth$weight,
    grp = as.numeric(PlantGrowth$group)
)

params <- c("mu", "sig")

inits <- function() {
    list(mu = rnorm(3, 0.0, 100.0))
}

mod <- jags.model(
    textConnection(mod_string),
    data = data_jags,
    n.chains = 3
    # , inits = inits
)
update(mod, 1000)

mod_sim <- coda.samples(
    model = mod,
    variable.names = params,
    n.iter = 5000
)
mod_csim <- as.mcmc(do.call(rbind, mod_sim)) # combined chains

plot(mod_sim)

gelman.diag(mod_sim)
autocorr.diag(mod_sim)
effectiveSize(mod_sim)

dic.samples(mod, n.iter = 1000)

pm_params <- colMeans(mod_csim)

library(coda)

HPDinterval(mod_csim[, 3] - mod_csim[, 1])

mod_cm <- lm(weight ~ -1 + group, data = PlantGrowth)
summary(mod_cm)
