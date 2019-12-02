#############################################################################################
# Checks the distribution of the speaking time for the Serial Speaker corpus.
#
# Vincent Labatut 11/2019
#############################################################################################
library("poweRlaw")
source("src/logging.R")




#############################################################################################
# start logging
start.rec.log(text="PL_SpkTime")

				
				
				
#############################################################################################
# setup folders
in.folder <- file.path("in","speakers_spk_time")
out.folder <- "out"
prefixes <- c("bb","got","hoc")




#############################################################################################
# loop over all three datasets
for(prefix in prefixes)
{	tlog(0,"-------------------------------")
	in.file <- file.path(in.folder,paste0(prefix,"_speaking_time.csv"))
	
	# read the data
	tlog(0,"Loading file \"",in.file,"\"")
	data <- read.csv(in.file, header=TRUE, check.names=FALSE, stringsAsFactors=FALSE)
	
	tlog(2,"Handling power law")
	# create continuous power law distribution
	power.law <- conpl$new(data$total)
	# estimate parameters
	est <- estimate_xmin(power.law)
	power.law$setXmin(est)
#	print(est)
	# plot model
	plot(power.law, col="RED")
	lines(power.law, col="BLUE", lwd=2)
	# bootstrap test
	pl.bs <- bootstrap_p(power.law, no_of_sims=500, threads=4)
	tlog(4,"p-value for power law: ",pl.bs$p)
	
	tlog(2,"Handling log-normal law")
	# create continuous log-normal law
	log.normal <- conlnorm$new(data$total)
	# estimate parameters
	est <- estimate_xmin(log.normal)
	log.normal$setXmin(est)
#	print(est)
	# plot model
	lines(log.normal, col="GREEN", lwd=2)
	# bootstrap test
	ln.bs <- bootstrap_p(log.normal, no_of_sims=500, threads=4)
	tlog(4,"p-value for log-normal law: ",ln.bs$p)
	
	tlog(2,"Handling exponential law")
	# create  exponential law
	exp.law <- conexp$new(data$total)
	# estimate parameters
	est <- estimate_xmin(exp.law)
	exp.law$setXmin(est)
#	print(est)
	# plot model
	lines(exp.law, col="PURPLE", lwd=2)
	# bootstrap test
	el.bs <- bootstrap_p(exp.law, no_of_sims=500, threads=4)
	tlog(4,"p-value for exponential law: ",el.bs$p)
	
	# compare power and log-normal laws
	tlog(2,"Comparing power and log-normal laws")
	log.normal$setXmin(power.law$getXmin())
	est <- estimate_pars(log.normal)
	log.normal$setPars(est)
	comp.ln <- compare_distributions(power.law, log.normal)
#	print(comp.ln)
	tlog(4,"Test statistic: ",comp.ln$test_statistic)
	tlog(4,"p-values: ",comp.ln$p_one_sided,", ",comp.ln$p_two_sided)
	
	# compare power and exponential laws
	tlog(2,"Comparing power and exponential laws")
	exp.law$setXmin(power.law$getXmin())
	est <- estimate_pars(exp.law)
	exp.law$setPars(est)
	comp.el <- compare_distributions(power.law, exp.law)
#	print(comp.el)
	tlog(4,"Test statistic: ",comp.el$test_statistic)
	tlog(4,"p-values: ",comp.el$p_one_sided,", ",comp.el$p_two_sided)
}

tlog(0,"-------------------------------")
tlog(0,"Interpretation of the distribution test: statistically significant if large enough")
tlog(0,"-------------------------------")
tlog(0,"Interpretation of the comparison test:")
tlog(2,"- The test statistic indicates whether the power-law (positive) or the other distribution (negative) is preferred")
tlog(2,"- The p-value indicates whether this sign is significant (small p)")




#############################################################################################
# close the log file
tlog(0,"-------------------------------")
tlog(0,"Done")
end.rec.log()
