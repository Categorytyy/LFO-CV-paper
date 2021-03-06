library(tidyverse)
colors <- unname(unlist(bayesplot::color_scheme_get()[c(6, 2)]))
# theme_set(bayesplot::theme_default(base_family = "sans"))
theme_set(theme_bw())

# data preparation
mlevels <- c(
  "constant", "linear", "quadratic",
  "AR2-only", "AR2-linear", "AR2-quadratic"
)
lfo_sims <- read_rds("results/lfo_sims.rds") %>%
  as_tibble() %>%
  mutate(
    model = factor(model, levels = mlevels),
    k_thres = paste0("k = ", k_thres),
    elpd_loo = map_dbl(res, ~ .$loo_cv$estimates["elpd_loo", 1]),
    elpd_exact_lfo = map_dbl(res, ~ .$lfo_exact_elpd[1]),
    elpd_approx_lfo = map_dbl(res, ~ .$lfo_approx_elpd[1]),
    elpd_diff_lfo = elpd_approx_lfo - elpd_exact_lfo,
    elpd_diff_loo = elpd_loo - elpd_exact_lfo,
    nrefits = lengths(map(res, ~ attr(.$lfo_approx_elpds, "refits"))),
    rel_nrefits = nrefits / (N - L)
  )


# LFO-1SAP plots ------------------------------------------------------------------
lfo_res <- lfo_sims %>% filter(is.na(B), M == 1)

lfo_res %>%
  group_by(model, k_thres) %>%
  summarise(
    mean_diff_lfo = mean(elpd_diff_lfo), 
    mean_diff_loo = mean(elpd_diff_loo),
    sd_diff_lfo = sd(elpd_diff_lfo), 
    sd_diff_loo = sd(elpd_diff_loo)
  )

# plot differences to exact LFO
lfo_res %>% 
  select(elpd_diff_lfo, elpd_diff_loo, model, k_thres) %>%
  gather("Type", "elpd_diff", elpd_diff_lfo, elpd_diff_loo) %>%
  ggplot(aes(x = elpd_diff, y = ..density.., fill = Type)) +
  facet_grid(model ~ k_thres, scales = "free_y") +
  geom_histogram(alpha = 0.7) +
  scale_fill_manual(
    values = colors,
    labels = c("Approximate LFO-CV", "Approximate LOO-CV")
  ) +
  labs(x = 'Difference to exact LFO-CV', y = "Density") +
  geom_vline(xintercept = 0, linetype = 2) +
  theme(legend.position = "bottom") +
  NULL

ggsave("plots/LFO_1SAP_AR_models_ELPD.jpeg", width = 7, height = 6)


# plot number of refits
lfo_res %>% 
  ggplot(aes(x = nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = nrefits),
    linetype = 2,
    data = lfo_res %>%
      group_by(model, k_thres) %>%
      summarise(nrefits = mean(nrefits))
  ) +
  geom_histogram(fill = colors[1]) +
  xlab("Number of refits based on N = 200 and L = 25") +
  ylab("Count") +
  theme_bw()

ggsave("plots/LFO_1SAP_AR_models_nrefits.jpeg", width = 6, height = 6)

# plot relative number of refits
lfo_res %>% 
  ggplot(aes(x = rel_nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = rel_nrefits),
    linetype = 2,
    data = lfo_res %>%
      group_by(model, k_thres) %>%
      summarise(rel_nrefits = mean(rel_nrefits))
  ) +
  geom_histogram(fill = colors[1]) +
  xlab("Relative number of refits based on N = 200 and L = 25") +
  ylab("Count") +
  theme_bw()

ggsave("plots/LFO_1SAP_AR_models_rel_refits.jpeg", width = 6, height = 6)



# block-LFO-1SAP plots ------------------------------------------------------------
block_lfo_res <- lfo_sims %>% 
  filter(!is.na(B), M == 1)

# plot differences to exact LFO
block_lfo_res %>% 
  select(elpd_diff_lfo, elpd_diff_loo, model, k_thres) %>%
  gather("Type", "elpd_diff", elpd_diff_lfo, elpd_diff_loo) %>%
  ggplot(aes(x = elpd_diff, y = ..density.., fill = Type)) +
  facet_grid(model ~ k_thres, scales = "free_y") +
  geom_histogram(alpha = 0.7) +
  scale_fill_manual(
    values = colors,
    labels = c("Approximate LFO-CV", "Approximate LOO-CV")
  ) +
  labs(x = 'Difference to exact block-LFO-CV', y = "Density") +
  geom_vline(xintercept = 0, linetype = 2) +
  theme(legend.position = "bottom") +
  NULL

ggsave("plots/block_LFO_1SAP_AR_models_ELPD.jpeg", width = 7, height = 6)


# plot number of refits
block_lfo_res %>% 
  ggplot(aes(x = nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = nrefits),
    linetype = 2,
    data = block_lfo_res %>%
      group_by(model, k_thres) %>%
      summarise(nrefits = mean(nrefits))
  ) +
  geom_histogram(fill = colors[1], bins = 10) +
  xlab("Number of refits based on N = 200, L = 25, and B = 10") +
  ylab("Count") +
  theme_bw()

ggsave("plots/block_LFO_1SAP_AR_models_nrefits.jpeg", width = 6, height = 6)

# plot relative number of refits
block_lfo_res %>% 
  ggplot(aes(x = rel_nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = rel_nrefits),
    linetype = 2,
    data = block_lfo_res %>%
      group_by(model, k_thres) %>%
      summarise(rel_nrefits = mean(rel_nrefits))
  ) +
  geom_histogram(fill = colors[1], bins = 10) +
  xlab("Relative number of refits based on N = 200 and L = 25") +
  ylab("Count") +
  theme_bw()

ggsave("plots/block_LFO_1SAP_AR_models_rel_refits.jpeg", width = 6, height = 6)


# LFO-4SAP plots ------------------------------------------------------------------
lfo_res_4sap <- lfo_sims %>% 
  filter(is.na(B), M == 4)

# plot differences to exact LFO
lfo_res_4sap %>% 
  select(elpd_diff_lfo, model, k_thres) %>%
  ggplot(aes(x = elpd_diff_lfo, y = ..density..)) +
  facet_grid(model ~ k_thres, scales = "free_y") +
  geom_histogram(alpha = 0.7, fill = colors[1]) +
  labs(x = 'Difference to exact LFO-CV', y = "Density") +
  geom_vline(xintercept = 0, linetype = 2) +
  theme(legend.position = "bottom") +
  NULL

ggsave("plots/LFO_4SAP_AR_models_ELPD.jpeg", width = 7, height = 6)


# plot number of refits
lfo_res_4sap %>% 
  ggplot(aes(x = nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = nrefits),
    linetype = 2,
    data = lfo_res_4sap %>%
      group_by(model, k_thres) %>%
      summarise(nrefits = mean(nrefits))
  ) +
  geom_histogram(fill = colors[1], bins = 10) +
  xlab("Number of refits based on N = 200 and L = 25") +
  ylab("Count") +
  theme_bw()

ggsave("plots/LFO_4SAP_AR_models_nrefits.jpeg", width = 6, height = 6)

# plot relative number of refits
lfo_res_4sap %>% 
  ggplot(aes(x = rel_nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = rel_nrefits),
    linetype = 2,
    data = lfo_res_4sap %>%
      group_by(model, k_thres) %>%
      summarise(rel_nrefits = mean(rel_nrefits))
  ) +
  geom_histogram(fill = colors[1], bins = 10) +
  xlab("Relative number of refits based on N = 200 and L = 25") +
  ylab("Count") +
  theme_bw()

ggsave("plots/LFO_4SAP_AR_models_rel_refits.jpeg", width = 6, height = 6)


# block-LFO-4SAP plots ------------------------------------------------------------------
block_lfo_res_4sap <- lfo_sims %>% 
  filter(!is.na(B), M == 4)

# plot differences to exact LFO
block_lfo_res_4sap %>% 
  select(elpd_diff_lfo, model, k_thres) %>%
  ggplot(aes(x = elpd_diff_lfo, y = ..density..)) +
  facet_grid(model ~ k_thres, scales = "free_y") +
  geom_histogram(alpha = 0.7, fill = colors[1]) +
  labs(x = 'Difference to exact block-LFO-CV', y = "Density") +
  geom_vline(xintercept = 0, linetype = 2) +
  theme(legend.position = "bottom") +
  NULL

ggsave("plots/block_LFO_4SAP_AR_models_ELPD.jpeg", width = 7, height = 6)


# plot number of refits
block_lfo_res_4sap %>% 
  ggplot(aes(x = nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = nrefits),
    linetype = 2,
    data = block_lfo_res_4sap %>%
      group_by(model, k_thres) %>%
      summarise(nrefits = mean(nrefits))
  ) +
  geom_histogram(fill = colors[1], bins = 10) +
  xlab("Number of refits based on N = 200, L = 25, and B = 10") +
  ylab("Count") +
  theme_bw()

ggsave("plots/block_LFO_4SAP_AR_models_nrefits.jpeg", width = 6, height = 6)

# plot relative number of refits
block_lfo_res_4sap %>% 
  ggplot(aes(x = rel_nrefits, y = ..density..)) +
  facet_grid(model ~ k_thres) + 
  geom_vline(
    aes(xintercept = rel_nrefits),
    linetype = 2,
    data = block_lfo_res_4sap %>%
      group_by(model, k_thres) %>%
      summarise(rel_nrefits = mean(rel_nrefits))
  ) +
  geom_histogram(fill = colors[1], bins = 10) +
  xlab("Relative number of refits based on N = 200, L = 25, and B = 10") +
  ylab("Count") +
  theme_bw()

ggsave("plots/block_LFO_4SAP_AR_models_rel_refits.jpeg", width = 6, height = 6)

