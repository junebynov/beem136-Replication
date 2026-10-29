library(readxl)

# load in data
data <- read_excel("data_figure_1.xlsx",sheet='data')

# initialize plot
# png(file = "figure_1.pdf", height = 500, width = 1000)

setEPS()
postscript("figure_1.eps", height = 6, width = 10)

par(mfrow = c(2,3), mar = c(5, 5, 2, 4))

# plot 6 countries

for (country in c("France", "Italy", "United_Kingdom", "Finland", "Japan", "Australia")) {
  
  plot(x = data$Year[(! is.na(data[,paste(country, "_old", sep = "")])) | (! is.na(data[,paste(country, "_new", sep = "")]))],
       
       y = c(data[,paste(country, "_old", sep = "")][! is.na(data[,paste(country, "_old", sep = "")])],
             
             data[,paste(country, "_new", sep = "")][! is.na(data[,paste(country, "_new", sep = "")])]), 
       
       main = gsub("_", " ", country), xlab = "Year", ylab = "Pct GDP", cex.main = 2, cex.lab = 2, cex.axis = 2,
       
       type = "l", col = "blue", lwd = 2, xlim = c(1960, 2013), ylim = c(0, max(data[, (2:15)], na.rm = TRUE))
      
       )
  
}

dev.off()
