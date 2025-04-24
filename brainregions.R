# 加载必要的包
library(ggpubr)
library(dplyr)
library(rstatix)

# ---------- 数据输入（修正维度）----------
data <- data.frame(
  mousetype = factor(rep(c("rank1", "rank4"), each = 21)),
  BrainRegion = rep(rep(c("PL","ACA", 
                         "ACB","MEA","LHA",
                         "BLA","VTA"), each = 3), times = 2),
  CellCount = c(
    # rank1 数据
    30,147,75,102,197,227,42,46,85,10,6,3,0,1,4,53,120,92,0,0,2,
    # rank4 数据
    82,3214,1022,218,6681,3464,48,1250,893,10,215,95,3,59,4,64,1486,682,0,8,4
  )
) %>% 
  mutate(
    BrainRegion = factor(BrainRegion, levels = unique(BrainRegion)),
    CellCount = ifelse(CellCount == 0, 0.1, CellCount),
    MouseID = paste0("M", 1:n())  # 关键修正：动态生成与行数一致的ID
  )

# ---------- 统计分析（保持不变）----------
stat.test <- data %>% 
  group_by(BrainRegion) %>% 
  wilcox_test(CellCount ~ mousetype) %>% 
  ungroup() %>% 
  adjust_pvalue(method = "BH") %>% 
  add_significance() %>% 
  mutate(
    p.signif = case_when(
      p.adj < 0.001 ~ "***",
      p.adj < 0.01  ~ "**",
      p.adj < 0.05  ~ "*",
      TRUE          ~ "ns"
    )
  )

# ---------- 动态计算标注位置 ----------
max_counts <- data %>% 
  group_by(BrainRegion) %>% 
  summarise(max_count = max(CellCount))

stat.test <- stat.test %>% 
  left_join(max_counts, by = "BrainRegion") %>% 
  mutate(
    x_center = as.numeric(BrainRegion),
    xmin = x_center - 0.4,
    xmax = x_center + 0.4,
    y.position = 10^(log10(max_count) * 1.15)  # 微调高度系数
  )

# ---------- 可视化实现 ----------
p <- ggboxplot(
  data,
  x = "BrainRegion",
  y = "CellCount",
  color = "mousetype",
  palette = c("#3B9AB2", "#E7298A"),
  add = "jitter",
  width = 0.6
) + 
  scale_y_log10(
    breaks = 10^(0:4),  # 根据新数据范围调整
    labels = scales::trans_format("log10", scales::math_format(10^.x)),
    expand = expansion(mult = c(0.05, 0.2))
  ) +
  labs(x = "脑区", y = "细胞计数") +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    legend.position = "top"
  )

# ---------- 自动适配坐标范围 ----------
y_upper <- max(c(stat.test$y.position, data$CellCount)) * 2  # 增加倍数保证可见

final_plot <- p + 
  stat_pvalue_manual(
    stat.test,
    label = "p.signif",
    xmin = "xmin",
    xmax = "xmax",
    y.position = "y.position",
    tip.length = 0.005,
    inherit.aes = FALSE
  ) +
  coord_cartesian(ylim = c(0.1, y_upper))

print(final_plot)




