plot_apk <- function() {
  file_name = paste("/Users/ippe/dse/master/pr_research/result/check_apk/n2_2times_yahoo_from20140111to20140131_21_above_1reduce_2zettai_date2_95.csv", sep = "")
  eval(parse(text = paste("apk = read.csv('",file_name,"', header = F, encoding = 'UTF-8', colClasses='double')", sep = "")))
  
  # all
  eval(parse(text = paste("apk_ts = c(as.ts(apk))", sep = "")))
  
  eval(parse(text = paste("plot(apk_ts[1:100], type = 'l', xlab = 'N', ylab = 'AP@N', main = 'Average Precision')", sep = "")))
}