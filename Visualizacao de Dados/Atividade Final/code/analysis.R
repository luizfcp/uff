
library(readxl)
library(dplyr)
library(stringr)
library(magrittr)
library(purrr)
library(tidyr)
library(ggplot2)
library(janitor)

# base de dados -----------------------------------------------------------

# raw_data <- 
#   map(1:32,
#       ~ read_excel("../data/tabela_registro_civil.xlsx", skip = 4, n_max = 380, sheet = .x) %>% 
#         select(-c(1:3)) %>% 
#         rename_at(1:2, ~ c("idade_da_mae_na_ocasiao_do_parto", "ano")) %>% 
#         mutate(idade_da_mae_na_ocasiao_do_parto = rep(idade_da_mae_na_ocasiao_do_parto[seq(1,380,10)], each = 10)) %>% 
#         cbind(
#           "GR_UF" = read_excel("../data/tabela_registro_civil.xlsx", skip = 2, n_max = 2, sheet = .x) %>% 
#             select(1) %>% 
#             names() %>% 
#             str_sub(start = 49)
#         ) %>% 
#         as_tibble() %>% 
#         mutate(GR_UF = as.character(GR_UF))
#   )

base_gr <-
  map(1:5,
      ~ read_excel("../data/tabela_registro_civil.xlsx", skip = 4, n_max = 15, sheet = .x) %>%
        select(-c(1:4)) %>%
        rename_at(1, ~ c("ano")) %>%
        cbind(
          "GR" = read_excel("../data/tabela_registro_civil.xlsx", skip = 2, n_max = 2, sheet = .x) %>%
            select(1) %>%
            names() %>%
            str_sub(start = 49)
        ) %>%
        as_tibble() %>%
        mutate(GR = as.character(GR))
  )

base_uf <-
  map(6:32,
      ~ read_excel("../data/tabela_registro_civil.xlsx", skip = 4, n_max = 15, sheet = .x) %>%
        select(-c(1:4)) %>%
        rename_at(1, ~ c("ano")) %>%
        cbind(
          "UF" = read_excel("../data/tabela_registro_civil.xlsx", skip = 2, n_max = 2, sheet = .x) %>%
            select(1) %>%
            names() %>%
            str_sub(start = 49)
        ) %>%
        as_tibble() %>%
        mutate(UF = as.character(UF))
  )

# base_gr %>% bind_rows() %>% write.csv("../data/base por gr.csv", row.names = F)
# base_uf %>% bind_rows() %>% write.csv("../data/base por uf.csv", row.names = F)

base1 <- 
  read_excel("../data/tabela2612.xlsx", skip = 2, n_max = 64800) %>% 
  clean_names() %>% 
  select(-c(1,2,4)) 

gr <- base1 %>% select(1) %>% distinct() %>% remove_missing() %$% grande_regiao
idade_mae <- base1 %>% select(2) %>% distinct() %>% remove_missing() %$% idade_da_mae_na_ocasiao_do_parto


base1_mod <- 
  base1 %>% 
  mutate(grande_regiao = rep(gr, each = 12960),
         idade_da_mae_na_ocasiao_do_parto = rep(idade_mae, each = 360, times = 5),
         ano = rep(rep(2003:2017, each = 24, times = 36), each = 5),
         mes_do_nascimento = rep(meses_12$mes, each = 2, times = 2700))

write.csv(base1_mod, "../data/base por gr - idade da mae, sexo e local de nascimento.csv",
          row.names = F)

# rascunho ----------------------------------------------------------------

meses_12 <- base_gr %>% 
  bind_rows() %>% 
  gather(mes, value, -ano, -GR) %>% 
  distinct(mes)

# p1 <- 
  base_gr %>% 
  bind_rows() %>% 
  gather(mes, value, -ano, -GR) %>% 
  mutate(value = as.numeric(value)) %>% 
  group_by(mes) %>% 
  summarise(media = mean(value, na.rm = T)) %>% 
  ungroup() %>% 
  mutate(mes = factor(mes, levels = meses_12$mes)) %>% 
  ggplot(aes(mes, media)) +
  geom_bar(stat = 'identity', fill = "#800000") +
  theme_minimal() +
  geom_text(aes(label = media %>% round), nudge_y = -1000, color = "white") +
  labs(x = "", y = "Média", title = "Média de nascimento por mês (2003-2017)")


# -------------------------------------------------------------------------


temp_sol <- 
  base_gr %>% 
  bind_rows() %>% 
  select(13,2,3, 8:10) %>% 
  gather(mes, value)
  # mutate(value = as.numeric(value)) %>% 
  # group_by(mes) %>% 
  # summarise(media = mean(value, na.rm = T)) %>% 
  # ungroup()

temp_sol %>% 
  mutate(tempo = if_else((mes=="Dezembro"|mes=="Janeiro"|mes=="Fevereiro"), "Calor", "Frio")) %>% 
  ggplot(aes(tempo, value)) +
  geom_boxplot()


# -------------------------------------------------------------------------

base_gr %>% 
  bind_rows() %>% 
  gather(mes, value, -ano, -GR) %>%
  group_by(GR, mes) %>% 
  summarise(media = mean(value, na.rm = T)) %>% 
  ungroup() %>% 
  mutate(mes = factor(mes, levels = meses_12$mes)) %>% 
  ggplot(aes(mes, media)) +
  geom_bar(stat = 'identity', fill = "#800000") +
  facet_grid(~ GR) +
  theme_minimal() +
  coord_flip() +
  geom_text(aes(label = media %>% round), nudge_y = 15000) +
  labs(x = "", y = "Média", title = "Média de nascimento por mês (2003-2017)")
  

# rascunho ----------------------------------------------------------------

base_completa %>% 
  select(idade_da_mae_na_ocasiao_do_parto, mes_do_nascimento, ano, hospital, domicilio) %>% 
  filter(mes_do_nascimento %in% c("Março", "Outubro")) %>% 
  group_by(idade_da_mae_na_ocasiao_do_parto, ano, mes_do_nascimento) %>% 
  summarise(hospital = sum(hospital, na.rm = T),
            domicilio = sum(domicilio, na.rm = T)) %>% 
  ungroup() %>% 
  mutate(total = hospital+domicilio,
         ano = as.character(ano)) %>% 
  ggplot() +
  facet_grid(~ ano, scales = "free_x")+
  geom_boxplot(aes(x = ano, y = total, fill = mes_do_nascimento)) +
  theme_linedraw() +
  theme(axis.text.x.bottom = element_blank(), axis.ticks.x.bottom = element_blank()) +
  scale_fill_manual(name = "Mês do Nascimento", values = c("lightblue", "purple")) +
  labs(x = "", 
       y = "Total de Nascimentos de acordo com a idade da mãe na ocasião do parto",
       title = "Número total de Nascimentos de acordo com a idade da mãe na \n ocasião do parto nos meses de Março e Outubro entre os anos de 2003 a 2017")

base_completa %>% select(grande_regiao) %>% distinct() %$% grande_regiao %>% 
  map(
    ~ base_completa %>% 
      select(grande_regiao, sexo, hospital, domicilio, mes_do_nascimento) %>% 
      group_by(grande_regiao, mes_do_nascimento, sexo) %>% 
      summarise(hospital = sum(hospital, na.rm = T),
                domicilio = sum(domicilio, na.rm = T)) %>% 
      ungroup() %>% 
      mutate(total = hospital+domicilio) %>%
      select(-hospital, -domicilio) %>% 
      filter(grande_regiao == .x) %>% 
      ggplot(aes(x = mes_do_nascimento, y = total, fill = sexo)) +
      geom_bar(stat = 'identity', position = "dodge") +
      ggtitle(.x)
  )

base_completa %>% 
  group_by(grande_regiao) %>% 
  summarise(hospital = sum(hospital, na.rm = T),
            domicilio = sum(domicilio, na.rm = T)) %>% 
  gather(local, value, -grande_regiao) %>% 
  ggplot(aes(x = grande_regiao, y = value, fill = local)) +
  geom_bar(stat = 'identity')



























