library("MASS")
data("OME")
?OME # background on the data
head(OME)

any(is.na(OME)) # check for missing values
dat <- subset(OME, OME != "N/A") # manually remove OME missing values identified with "N/A"
dat$OME <- factor(dat$OME)
str(dat)

plot(dat$Age, dat$Correct / dat$Trials )
plot(dat$OME, dat$Correct / dat$Trials )
plot(dat$Loud, dat$Correct / dat$Trials )
plot(dat$Noise, dat$Correct / dat$Trials )

mod_glm <- glm(Correct/Trials ~ Age + OME + Loud + Noise, data=dat, weights=Trials, family="binomial")
summary(mod_glm)


model.matrix(mod_glm)[, -1]

plot(residuals(mod_glm, type="deviance"))
plot(fitted(mod_glm), dat$Correct/dat$Trials)


X <- model.matrix(mod_glm)[,-1] # -1 removes the column of 1s for the intercept
head(X)


mod_string = " model {
	for (i in 1:length(y)) {
		y[i] ~ dbin(phi[i], n[i])
		logit(phi[i]) = b0 + b[1]*Age[i] + b[2]*OMElow[i] + b[3]*Loud[i] + b[4]*Noiseincoherent[i]
	}
	
	b0 ~ dnorm(0.0, 1.0/5.0^2)
	for (j in 1:4) {
		b[j] ~ dnorm(0.0, 1.0/4.0^2)
	}
	
} "

data_jags = as.list(as.data.frame(X))
data_jags$y = dat$Correct # this will not work if there are missing values in dat (because they would be ignored by model.matrix). Always make sure that the data are accurately pre-processed for JAGS.
data_jags$n = dat$Trials
str(data_jags) # make sure that all variables have the same number of observations (712).

library("rjags")
mod = jags.model(textConnection(mod_string), data=data_jags, n.chains=3)
update(mod, 1e3)

library("coda")
mod_sim = coda.samples(model=mod,
                       variable.names = 
                        n.iter=5e3)

mod_csim = as.mcmc(do.call(rbind, mod1_sim))


raftery.diag()
