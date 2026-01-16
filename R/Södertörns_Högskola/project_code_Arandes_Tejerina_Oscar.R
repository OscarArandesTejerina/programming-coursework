###############################################################
#####---Statistical analyses and visualization in R (I)---#####
##########-----------------Project Work---------------#########      
##########-----------Oscar Arandes Tejerina----------########## 
###############################################################

#install.packages("tidyverse")
#install.packages("corrplot")
#install.packages("showtext")
#install.packages("psych")
#install.packages("PMCMRplus")
#install.packages("car")
library(tidyverse)
library(corrplot)
library(showtext)
library(psych)
library(PMCMRplus)
library(car)

# Add LM Roman font
font_path <- "K:/STOCKHOLM/Courses/Södetorns Högskola/Statistical analyses and visualization in R (I)/latin-modern-roman.mroman10-regular.otf"
font_add("LM Roman", font_path) 
showtext_auto()

###############################################################################
##########----------------------------PART 1---------------------------########
###############################################################################
# Read the data 
data_bank <- read.csv("bank_dataset.csv")
summary(data_bank)

# Preprocessing
data_bank <- data_bank |>
  mutate(
    Id = as.character(Id),
    age = as.numeric(age),
    job = as.factor(job),
    marital = as.factor(marital),
    education = as.factor(education),
    default = as.factor(default),
    housing = as.factor(housing),
    loan = as.factor(loan),
    contact = as.factor(contact),
    month = as.factor(month),
    poutcome = as.factor(poutcome),
    y = as.factor(y)
  ) |>          
  rename(
    deposit = y                   # rename y" to "deposit"
  ) |>
  filter(!(age %in% c(999, -1))   # remove nonsense age values
  )

data_bank_clean <- na.omit(data_bank)

summary(data_bank_clean)

####################
### Question 1.1 ###
####################
# Is there a correlation between a customer’s age and their bank balance?

# Statistics of the features (using "describe" function from "psych" library)
describe(data_bank_clean[, c("age", "balance")])

# Scatter Plot
data_bank_clean |> 
  ggplot(mapping = aes(x = age, y =balance)) + 
  geom_point(color = "darkgreen", size = 2) +
  labs(
    x = "Age",
    y = "Balance"
  ) +
  theme_bw() +
  theme(
    panel.grid = element_blank(),
    aspect.ratio = 0.4,
    text = element_text(size = 20, family = "LM Roman") 
  ) 

# Perform a Spearman’s Rank Correlation (non-parametric) test
cor.test(data_bank_clean$age, 
         data_bank_clean$balance, 
         method = "spearman")


####################
### Question 1.2 ###
####################
# Is there an association between client marital status and term deposit 
# subscription?

# Perform a chi-2 test
cont_table <- table(data_bank_clean$marital, data_bank_clean$deposit)
result_chi2 <- chisq.test(cont_table, correct = FALSE) # Remove Yates’ 
                                                       # continuity correction

# Is the chi-2 test valid? Let's examine the Expected Frequencies
result_chi2$expected

# Explore the Individual Contributions to the chi-2test
round(result_chi2$residuals,4)
round(result_chi2$residuals^2,4)

# Visualization data
cont_table |> 
  as.data.frame() |>
  setNames(c("Row", "Column", "Freq")) |>
  ggplot(aes(x = Column, y = Freq, fill = Row)) +
  geom_bar(stat = "identity", position = "dodge",color = "black") +
  labs(
    title = NULL,
    x = NULL,
    y = "Counts",
    fill = NULL
  ) +
  theme_bw() +
  theme(
    legend.position = c(0.85, 0.8),
    panel.grid = element_blank(),
    aspect.ratio = 0.6,
    text = element_text(size = 20, family = "LM Roman")  
  ) 

# Visualization Individual Contributions to the chi-2test
contrib1 <- (result_chi2$residuals^2/result_chi2$statistic)*100
par(family = "LM Roman")
contrib1 |> 
  corrplot(is.cor = FALSE, 
           cl.align.text = "l", 
           tl.col = "black")  



###############################################################################
##########----------------------------PART 2---------------------------########
###############################################################################
# Read the data 
data_sleep <- read.csv("sleep_dataset.csv")
summary(data_sleep)

# Merge 'Normal' and 'Normal Weight' into one level
data_sleep <- data_sleep |>
  mutate(BMI.Category = ifelse(
    BMI.Category == "Normal Weight", "Normal", BMI.Category)
  )

data_sleep_clean <- data_sleep |>
  mutate(Person.ID = as.character(Person.ID),
         Gender = as.factor(Gender),
         Occupation = as.factor(Occupation),
         BMI.Category = as.factor(BMI.Category),
         Sleep.Disorder = as.factor (Sleep.Disorder),
         )

summary(data_sleep_clean)

####################
### Question 2.1 ###
####################
# Is there a significant difference in Sleep Duration between Male and 
# Female participants?

# Two-samples t-test (independent samples t-test)?
# Check if the dependent variable (response variable) is normally distributed
data_sleep_clean |>
  ggplot(aes(x = Sleep.Duration)) +
  geom_histogram(bins = 10, fill = "skyblue", color = "darkblue") +
  labs(
    x = "Sleep Duration",
    y = "Frequency") +
  theme_bw() +
  theme(
    aspect.ratio = 0.6,
    legend.position = "none",  
    text = element_text(size = 20, family = "LM Roman")  
  ) 

# They are not so we better perform a Wilcoxon rank-sum test 
# (also called the Mann-Whitney U test)
test_sleep <- wilcox.test(data_sleep_clean$Sleep.Duration ~ data_sleep_clean$Gender, alternative = "two.sided")

# Visualize difference means 
summary_sleep <- data_sleep_clean |>
  group_by(Gender) |>
  summarise(
    mean_sleep = mean(Sleep.Duration),          # Mean
    se_sleep = sd(Sleep.Duration) / sqrt(n())  # Standard error of the mean
  )

summary_sleep |>
  ggplot(aes(x = Gender, y = mean_sleep)) +
  geom_point(size = 4) +                                                                         # Mean points
  geom_errorbar(aes(ymin = mean_sleep - se_sleep, ymax = mean_sleep + se_sleep), width = 0.2) +  # Error bars
  labs(
    x = "Gender",   
    y = "Sleep Duration"
    ) +
  theme_bw() +
  theme(
    aspect.ratio = 0.6,
    legend.position = "none",  
    text = element_text(size = 20, family = "LM Roman")  
  ) 

####################
### Question 2.2 ###
####################
# Does the quality of sleep differ between individuals with different BMI 
# categories or those with different sleep disorders? 

table(data_sleep_clean$BMI.Category, data_sleep_clean$Sleep.Disorder)

model_sleep <- data_sleep_clean |>
  lm(formula = Quality.of.Sleep ~ BMI.Category)

model_sleep_2 <- data_sleep_clean |>
  aov(formula = Quality.of.Sleep ~ BMI.Category)

summary(model_sleep)
summary(model_sleep_2)

# Is the model valid?
par(mfrow=c(2,2))
plot(model_sleep)                    # Graphical inspection
shapiro.test(residuals(model_sleep)) # Shapiro-Wilk test on the residuals

# Note that quality of sleep is already not normally distributed!
shapiro.test(data_sleep_clean$Quality.of.Sleep)

# It seems that normality is not satisfied. We perform the non-parametric
# version, i.e., the Kruskal-Wallis test for both variables separately
kruskal.test(Quality.of.Sleep ~ BMI.Category, data=data_sleep_clean)
kruskal.test(Quality.of.Sleep ~ Sleep.Disorder, data=data_sleep_clean)

# Perform a post hoc test (pairwise comparison) with "pairwise.wilcox.test" function
pairwise.wilcox.test(data_sleep_clean$Quality.of.Sleep, data_sleep_clean$BMI.Category, p.adjust.method = "holm")
pairwise.wilcox.test(data_sleep_clean$Quality.of.Sleep, data_sleep_clean$Sleep.Disorder, p.adjust.method = "holm")

# Perform a post hoc test (pairwise comparison) with "PMCMRplus" package
kruskal_posthoc_bmi <- kwAllPairsNemenyiTest(data_sleep_clean$Quality.of.Sleep ~ data_sleep_clean$BMI.Category, 
                                         dist="Tukey", 
                                         data=data_sleep_clean)
summary(kruskal_posthoc_bmi)

kruskal_posthoc_disorder <- kwAllPairsNemenyiTest(data_sleep_clean$Quality.of.Sleep ~ data_sleep_clean$Sleep.Disorder, 
                                             dist="Tukey", 
                                             data=data_sleep_clean)
summary(kruskal_posthoc_disorder)

# Summarize the data by BMI.Category to calculate mean and standard error of the mean (SE)
summary_bmi <- data_sleep_clean |>
  group_by(BMI.Category) |>
  summarise(
    mean_sleep = mean(Quality.of.Sleep),          # Mean of Quality of Sleep
    se_sleep = sd(Quality.of.Sleep) / sqrt(n())  # Standard error of the mean
  )

# Visualize difference in means 
summary_bmi |>
  ggplot(aes(x = BMI.Category, y = mean_sleep)) +
  geom_point(size = 4) +                                                                        # Mean points
  geom_errorbar(aes(ymin = mean_sleep - se_sleep, ymax = mean_sleep + se_sleep), width = 0.2) +  # Error bars
  labs(
    x = "BMI Categoryr", 
    y = "Quality of Sleep"
  ) +
  theme_bw() +
  theme(
    aspect.ratio = 0.6,
    legend.position = "none",  
    text = element_text(size = 20, family = "LM Roman")  
  )

# Visualize difference in medians
ggplot(data_sleep_clean, aes(x = BMI.Category, y = Quality.of.Sleep)) +
  geom_boxplot(aes(fill = BMI.Category), width = 0.7) +  
  labs(
    x = "BMI Category", 
    y = "Quality of Sleep"
  ) +
  theme_bw() +
  theme(
    aspect.ratio = 0.6,
    legend.position = "none",  
    text = element_text(size = 20, family = "LM Roman")  
  )

# Summarize the data by Sleep.Disorder to calculate mean and standard error of the mean (SE)
summary_disorder <- data_sleep_clean |>
  group_by(Sleep.Disorder) |>
  summarise(
    mean_sleep = mean(Quality.of.Sleep),          # Mean of Quality of Sleep
    se_sleep = sd(Quality.of.Sleep) / sqrt(n())  # Standard error of the mean
  )

# Visualize difference in means 
summary_disorder |>
  ggplot(aes(x = Sleep.Disorder, y = mean_sleep)) +
  geom_point(size = 4) +                                                                        # Mean points
  geom_errorbar(aes(ymin = mean_sleep - se_sleep, ymax = mean_sleep + se_sleep), width = 0.2) +  # Error bars
  labs(
    x = "Sleep Disorder", 
    y = "Quality of Sleep"
  ) +
  theme_bw() +
  theme(
    aspect.ratio = 0.6,
    legend.position = "none",  
    text = element_text(size = 20, family = "LM Roman")  
  )

# Visualize difference in medians
ggplot(data_sleep_clean, aes(x = Sleep.Disorder, y = Quality.of.Sleep)) +
  geom_boxplot(aes(fill = Sleep.Disorder), width = 0.7) +  
  labs(
    x = "Sleep Disorder", 
    y = "Quality of Sleep"
  ) +
  theme_bw() +
  theme(
    aspect.ratio = 0.6,
    legend.position = "none",  
    text = element_text(size = 20, family = "LM Roman")  
  )



