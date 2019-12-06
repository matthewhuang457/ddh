## THIS CODE GENERATES master_top AND master_bottom TABLES

#load libraries
library(tidyverse)
library(here)
library(corrr)

#rm(list=ls()) 

#set params
release <- "19Q3"
start_time <- Sys.time()

#LOAD data 
load(file = here::here("data", "gene_summary.RData"))
load(file = here::here("data", paste0(release, "_achilles_cor.Rdata")))
achilles_lower <- readRDS(file = here::here("data", "achilles_lower.rds"))
achilles_upper <- readRDS(file = here::here("data", "achilles_upper.rds"))

#convert cor
class(achilles_cor) <- c("cor_df", "tbl_df", "tbl", "data.frame")

#setup containers
master_top_table <- tibble(
  fav_gene = character(), 
  data = list()
)
master_bottom_table <- tibble(
  fav_gene = character(), 
  data = list()
)

#define list
sample <- sample(names(achilles_cor), size = 10) #comment this out
r <- "rowname" #need to drop "rowname"
full <- (names(achilles_cor))[!(names(achilles_cor)) %in% r] #f[!f %in% r]

gene_group <- full #(~60' on a laptop); change to sample for testing

#master_table_top
for (fav_gene in gene_group) {
  message(" Top dep tables for ", fav_gene)
    dep_top <- achilles_cor %>% 
      focus(fav_gene) %>% 
      arrange(desc(.[[2]])) %>% #use column index
      filter(.[[2]] > achilles_upper) %>% #formerly top_n(20), but changed to mean +/- 3sd
      rename(approved_symbol = rowname) %>% 
      left_join(gene_summary, by = "approved_symbol") %>% 
      select(approved_symbol, approved_name, fav_gene) %>% 
      rename(gene = approved_symbol, name = approved_name, r2 = fav_gene)
    
    top_table <- dep_top %>% 
      mutate(fav_gene = fav_gene) %>% 
      group_by(fav_gene) %>% 
      nest()
    
    master_top_table <- master_top_table %>% 
      bind_rows(top_table)
}

#master_bottom_table
for (fav_gene in gene_group) {
  message(" Bottom dep tables for ", fav_gene)
  dep_bottom <- achilles_cor %>% 
    focus(fav_gene) %>% 
    arrange(.[[2]]) %>% #use column index
    filter(.[[2]] < achilles_lower) %>% #formerly top_n(20), but changed to mean +/- 3sd
    rename(approved_symbol = rowname) %>% 
    left_join(gene_summary, by = "approved_symbol") %>% 
    select(approved_symbol, approved_name, fav_gene) %>% 
    rename(gene = approved_symbol, name = approved_name, r2 = fav_gene)
  
  bottom_table <- dep_bottom %>% 
    mutate(fav_gene = fav_gene) %>% 
    group_by(fav_gene) %>% 
    nest()
  
  master_bottom_table <- master_bottom_table %>% 
    bind_rows(bottom_table)
}

#save
save(master_top_table, file=here::here("data", "master_top_table.RData"))
save(master_bottom_table, file=here::here("data", "master_bottom_table.RData"))

#how long
end_time <- Sys.time()