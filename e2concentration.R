# 加载包
library(tidyverse)
library(rstatix)
library(ggpubr)

# ---------------------- 数据准备 ----------------------
data <- data.frame(
  Rank = factor(rep(c("rank1", "rank2", "rank3", "rank4"), each = 3)),
  Estradiol = c(
    34.23,22.39,40.44,   # rank1
    25.94,28.90,28.61,   # rank2
    34.52,33.04,28.01,   # rank3
    28.01,28.61,32.75    # rank4
  )
)

# ---------------------- 统计检验 ----------------------
# 正态性检验
norm_test <- data %>% 
  group_by(Rank) %>% 
  shapiro_test(Estradiol)

# 方差齐性检验
var_test <- levene_test(data, Estradiol ~ Rank)

# 自动选择检验方法
if (all(norm_test$p > 0.05) && var_test$p > 0.05) {
  res.aov <- aov(Estradiol ~ Rank, data = data)
  posthoc <- tukey_hsd(res.aov)
  method_text <- "ANOVA with Tukey HSD"
} else {
  res.kruskal <- kruskal_test(data, Estradiol ~ Rank)
  posthoc <- dunn_test(data, Estradiol ~ Rank)
  method_text <- "Kruskal-Wallis with Dunn test"
}

# ---------------------- 显著性标记处理 ----------------------
sig_results <- data.frame()  # 初始化空数据框

if (exists("posthoc") && nrow(posthoc) > 0) {
  sig_temp <- posthoc %>% 
    filter(p.adj < 0.05)
  
  if (nrow(sig_temp) > 0) {
    sig_results <- sig_temp %>% 
      add_xy_position(
        x = "Rank",
        data = data,
        formula = Estradiol ~ Rank,
        dodge = 0.8
      )
  }
}

# ---------------------- 绘图 ----------------------
p <- ggplot(data, aes(x = Rank, y = Estradiol)) +
  geom_boxplot(aes(fill = Rank), width = 0.6, alpha = 0.7, outlier.shape = NA) +
  geom_jitter(aes(color = Rank), width = 0.1, size = 3, alpha = 0.8) +
  scale_fill_brewer(palette = "Pastel1") +
  scale_color_brewer(palette = "Set1") +
  labs(
    x = "社会等级", 
    y = "雌二醇浓度 (pg/mL)",
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

if (nrow(sig_results) > 0) {
  p <- p + 
    stat_pvalue_manual(
      sig_results,
      label = "p.adj.signif",
      tip.length = 0.01,
      bracket.nudge.y = 0.2,
      step.increase = 0.1
    ) +
    coord_cartesian(ylim = c(NA, max(data$Estradiol) * 1.3))
}

print(p)
# 在统计检验部分后添加
cat("\n=== 正态性检验结果 ===\n")
print(norm_test)
cat("\n=== 方差齐性检验结果 ===\n")
print(var_test)
cat("\n=== 事后检验结果 ===\n")
print(posthoc)