# RMST

## Exploratory RMST Simulations App

This **R Shiny** app is designed to investigate the RMST (Restricted Mean Survival Time), allowing users to change populations and medians in two arms. The survival data pulls from a Weibull distribution (shape = 1 gives Exponential distribution).

### Inputs

* Seed (Any integer)
* Number of Patients in Arm 0 (An integer from 2 to 50,000)
* Number of Patients in Arm 1 (An integer from 2 to 50,000)
* Shape of Weibull in Arm 0 (A number from 0.2 to 10)
* Shape of Weibull in Arm 1 (A number from 0.2 to 10)
* Median of Arm 0 (A number from 1 to 5000)
* Median of Arm 1 (A number from 1 to 5000)
* Tau (A number from 0 to 100000)

### Outputs

* A table verifying the parameters entered by the user
* A Kaplan-Meier graph split by arm (0 vs 1) and showing tau
* A table showing RMSTs of Arm 1 and Arm 0, as well as the difference between these RMSTs (reference = Arm 0), with CIs (confidence intervals) presented with all of these. A column of the true medians of Arm 0 and Arm 1 as well as the difference between these is also given.

### Applications

This app has a variety of uses. Here are some I have used it for:

* Investigating how a difference of x in medians will correspond to a difference in RMSTs
  * I discovered with a Weibull shape of 1 in both arms, every difference of 10 in medians equates to roughly a difference of 14 in RMSTs
* Investigating how changing the Weibull shape changes how closely the RMST apporximates to the median
  * I discovered that using a Weibull shape of 3 will give an RMST very close to the median, rather than a shape of 1 where the RMST is consistently higher
