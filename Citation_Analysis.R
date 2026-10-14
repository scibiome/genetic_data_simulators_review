library(dplyr)
library(readr)
library(ggplot2)
library(ggrepel)
library(scales)
library(patchwork)

################################################
# LOAD DATA
################################################

citation_data <- read_csv("./tool_citation_history.csv")


################################################
# FILTER
################################################

citation_data <- citation_data %>%
  filter(
    Year >= 2011,
    Year <= 2025, 
    Year >= Publication_Year)


################################################
# GROUP TOOL VERSIONS + AGGREGATE FIRST
################################################

citation_data <- citation_data %>%
  mutate(
    Tool = case_when(
      grepl("^SLiM", Tool) ~ "SLiM",
      grepl("^fastsimcoal", Tool) ~ "fastsimcoal",
      grepl("^AdmixSim", Tool) ~ "AdmixSim",
      grepl("^GPOPSIM", Tool) ~ "GPOPSIM",
      grepl("^MimicrEE", Tool) ~ "MimicrEE",
      grepl("^msprime", Tool) ~ "msprime",
      TRUE ~ Tool
    )
  ) %>%
  group_by(Tool, Strategy, Year) %>%
  summarise(Citations = sum(Citations), .groups = "drop")


################################################
# TOOL-LEVEL CUMULATIVE (CORRECT NOW)
################################################

tool_cum <- citation_data %>%
  arrange(Tool, Strategy, Year) %>%
  group_by(Tool, Strategy) %>%
  mutate(Citations = cumsum(Citations)) %>%
  ungroup()

################################################
# STRATEGY LEVEL (USED FOR PANEL A)
################################################

strategy_cum <- tool_cum %>%
  group_by(Strategy, Year) %>%
  summarise(Citations = sum(Citations), .groups = "drop") %>%
  ungroup()

################################################
# COLORS
################################################

strategy_colors <- c(
  Forward = "#56B4E9",
  Backward = "#D55E00",
  Resampling = "#E69F00"
)

################################################
# TOP 5 PER STRATEGY + OTHER
################################################
################################################
# TOP 5 PER STRATEGY + OTHER
################################################

collapse_top5 <- function(df){
  
  # Top 5, excluding simLD
  top5 <- df %>%
    filter(Tool != "simLD") %>%
    group_by(Tool) %>%
    summarise(total = max(Citations), .groups = "drop") %>%
    slice_max(total, n = 5) %>%
    pull(Tool)
  
  # Keep the top 5
  top_df <- df %>% 
    filter(Tool %in% top5)
  
  # Everything else goes into Other, including simLD
  other_raw <- df %>% 
    filter(!Tool %in% top5)
  
  if(nrow(other_raw) == 0){
    return(top_df)
  }
  
  start_year <- min(other_raw$Year, na.rm = TRUE)
  
  other_df <- other_raw %>%
    tidyr::complete(
      Tool,
      Strategy,
      Year = start_year:max(df$Year),
      fill = list(Citations = 0)
    ) %>%
    arrange(Tool, Year) %>%
    group_by(Tool, Strategy) %>%
    mutate(Citations = cummax(Citations)) %>%
    ungroup() %>%
    group_by(Strategy, Year) %>%
    summarise(Citations = sum(Citations), .groups = "drop") %>%
    mutate(Tool = "Other") %>%
    arrange(Year)
  
  bind_rows(top_df, other_df)
}


################################################
# SPLIT BY STRATEGY
################################################

data_f <- collapse_top5(
  tool_cum %>% filter(Strategy == "Forward")
)

data_b <- collapse_top5(
  tool_cum %>% filter(Strategy == "Backward")
)

data_r <- collapse_top5(
  tool_cum %>% filter(Strategy == "Resampling")
)

################################################
# SPLIT BY STRATEGY
################################################

data_f <- collapse_top5(tool_cum %>% filter(Strategy == "Forward"))
data_b <- collapse_top5(tool_cum %>% filter(Strategy == "Backward"))
data_r <- collapse_top5(tool_cum %>% filter(Strategy == "Resampling"))

################################################
# PALETTES
################################################

generate_palette <- function(df, base){
  
  ranking <- df %>%
    group_by(Tool) %>%
    summarise(v = max(Citations), .groups = "drop") %>%
    arrange(desc(v))
  
  n <- sum(ranking$Tool != "Other")
  cols <- alpha(base, seq(1, 0.5, length.out = n))
  
  setNames(cols, ranking$Tool[ranking$Tool != "Other"]) |> c(Other = "grey75")
}

pal_f <- generate_palette(data_f, "#56B4E9")
pal_b <- generate_palette(data_b, "#D55E00")
pal_r <- generate_palette(data_r, "#E69F00")

################################################
# LABEL POSITIONS
################################################

line_end <- function(df){
  df %>%
    group_by(Tool) %>%
    slice_max(Year, n = 1) %>%
    ungroup()
}

end_f <- line_end(data_f)
end_b <- line_end(data_b)
end_r <- line_end(data_r)

end_s <- strategy_cum %>%
  group_by(Strategy) %>%
  slice_max(Year, n = 1) %>%
  ungroup()

################################################
# THEME
################################################

nature_theme <- theme_classic(base_size = 16) +
  theme(
    legend.position = "none",
    axis.title = element_text(size = 13),
    axis.text = element_text(size = 11),
    axis.line = element_line(linewidth = 0.6),
    axis.ticks = element_line(linewidth = 0.6),
    plot.margin = margin(5.5, 90, 5.5, 5.5),
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1)
  )

################################################
# PLOT FUNCTION
################################################

plot_panel <- function(df, end_df, palette){
  
  ggplot(df, aes(Year, Citations, group = Tool)) +
    geom_line(aes(color = Tool), linewidth = 1.1) +
    
    geom_text_repel(
      data = end_df,
      aes(x = Year, y = Citations, label = Tool, color = Tool),
      nudge_x = 3,
      direction = "y",
      box.padding = 0.5,
      point.padding = 0.4,
      segment.size = 0.4,
      force = 4,
      max.overlaps = Inf,
      hjust = 0,
      show.legend = FALSE
    ) +
    
    scale_color_manual(values = palette) +
    coord_cartesian(xlim = c(2011, 2030.5)) +
    scale_x_continuous(breaks = seq(2011, 2025, 2)) +
    labs(x = "Year", y = "Cumulative Citations") +
    nature_theme
}

################################################
# PANELS
################################################

p_f <- plot_panel(data_f, end_f, pal_f)
p_b <- plot_panel(data_b, end_b, pal_b)
p_r <- plot_panel(data_r, end_r, pal_r)

p_s <- ggplot(strategy_cum, aes(Year, Citations, color = Strategy)) +
          geom_line(linewidth = 1.3) +
          geom_text_repel(
            data = end_s,
            aes(x = Year, y = Citations, label = Strategy, color = Strategy),
            nudge_x = 3,
            direction = "y",
            box.padding = 0.5,
            point.padding = 0.4,
            segment.size = 0.4,
            force = 4,
            hjust = 0,
            show.legend = FALSE
          ) +
          scale_color_manual(values = strategy_colors) +
          coord_cartesian(xlim = c(2011, 2030.5)) +
          scale_x_continuous(breaks = seq(2011, 2025, 2)) +
          scale_y_continuous(labels = comma) +
          labs(x = "Year", y = "Cumulative Citations") +
          nature_theme

################################################
# FINAL FIGURE
################################################

figure <- (p_s + p_f) / (p_b + p_r) +
  plot_annotation(tag_levels = "a") &
  theme(plot.tag = element_text(face = "bold", size = 16))

figure

################################################
# EXPORT
################################################

ggsave("figure_cumulative_citations.png", figure, width = 12, height = 10, dpi = 300)
ggsave("figure_cumulative_citations.pdf", figure, width = 12, height = 10)
