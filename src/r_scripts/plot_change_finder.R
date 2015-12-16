plot_change_finder <- function(urls_id) {
  file_name = paste("/Users/suiyujin/work/dse/pr_research/result/timepagerank/timepagerank_yahoo_from11to31_",urls_id,".txt", sep = "")
  eval(parse(text = paste("pr_",urls_id," = read.csv('",file_name,"', header = F, encoding = 'UTF-8', colClasses='double')", sep = "")))
  eval(parse(text = paste("a_",urls_id," = c(as.ts(pr_",urls_id,"))", sep = "")))
  
  eval(parse(text = paste("CF_test <- CF(a_",urls_id,", 2, 0.5, 7, 7)", sep = "")))
  eval(parse(text = paste("plot(a_",urls_id,", type = 'l', col = 1, xlab = 'date', ylab = 'PR')", sep = "")))
  par(new = TRUE)
  plot(CF_test, type = 'l', col = 4, axes = FALSE, ylab = '', xlab = '')
  axis(4)
}
