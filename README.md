# A Naive 2022 Senate Forecast

I do not study elections. I am not a forecaster. So take what follows
accordingly.

There are a number of people who have built sophisticated and probably
quite fine election forecasting models. I wanted to see something a
little different. How close can I get with a *very naive* forecasting
model?

So first, what am I trying to forecast? I’m gonna go for the Democratic
two party voteshare, or

$$
\delta \triangleq \dfrac{\text{Number of Democratic Votes}}{\text{Number of Democratic Votes} + \text{Number of Republican Votes}}.
$$

Now like I said, for kicks I’m going to try to forecast
*δ*<sub>*i*</sub> for each state *i* where there’s a Senate race in a
very unsophisticated way: Specifically, I’m only going to use
information voters have given me about whether they prefer to vote for
the Democrat or the Republican. This information comes in two flavors:
the information I had beforehand and what I’ve learned through the
campaign. This leads very naturally to a very simple Bayesian model,
where we place a Beta prior on *δ*<sub>*i*</sub>, whose parameters are
shaped by election returns from past Senate races in state *i*, and
update our belief about *δ*<sub>*i*</sub> using polls of the voters in
state *i* in the current election cycle. (Specifics about how the prior
parameters are calculated from past election returns are given for the
interested reader after the forecasting results are discussed).

### Appendix: Setting the Prior Parameters

A Beta distribution is defined by two parameters, *a* and *b*. The mean
and variance of a Beta distribution are given by

$$
\mu = \dfrac{a}{a + b}
$$

and

$$
\sigma^2 = \dfrac{ab}{(a + b)^2 (a + b + 1)}
$$

respectively.

So we can use *the method of moments* to set *a* and *b* for our Beta
prior over *δ*<sub>*i*</sub> by taking the election returns from the
last *N* (say 3) Senate elections in state *i* and setting *μ* equal to
their mean and *σ*<sup>2</sup> equal to their variance, then solving for
*a* and *b* using the equations above.
