plot_csv_2data <- function(number, urls_id) {
  file_name1 = paste("/Users/suiyujin/work/dse/pr_research/result/timepagerank/timepagerank_yho_from81to101_",urls_id,".txt", sep = "")
  #file_name2 = paste("/Users/ippe/dse/master/pr_research/result/timeinlinks/ps_score_2times_5reduce/timeinlinks_yahoo_from11to31_",urls_id,".txt", sep = "")
  eval(parse(text = paste("pr_",urls_id," = read.csv('",file_name1,"', header = F, encoding = 'UTF-8', colClasses='double')", sep = "")))
  #eval(parse(text = paste("il_",urls_id," = read.csv('",file_name2,"', header = F, encoding = 'UTF-8', colClasses='double')", sep = "")))
  
  # all
  eval(parse(text = paste("a1_",urls_id," = c(as.ts(pr_",urls_id,"))", sep = "")))
  #eval(parse(text = paste("a2_",urls_id," = c(as.ts(il_",urls_id,"))", sep = "")))
  
  eval(parse(text = paste("plot(a1_",urls_id,", type = 'l', xlab = 'day', ylab = 'pagerank', main = 'No.",number," (id=",urls_id,")')", sep = "")))
  #par(new = TRUE)
  #eval(parse(text = paste("plot(a2_",urls_id,", type = 'l', xlab = '', ylab = '', axes = FALSE, col='blue')", sep = "")))
  #axis(4)
}