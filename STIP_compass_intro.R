if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman") # pacman is a package for convenient installing and/or loading of packages and makes it easy for users of this tutorial to run the code from this tutorial on their own machine
}
pacman::p_load(data.table, dplyr, ggplot2, stringr, tidyr, DT, readr, readxl)

# Only download and read the remote Excel
remote_xlsx <- "https://stip.oecd.org/assets/downloads/STIP_Survey.xlsx"
tmp_xlsx <- tempfile(fileext = ".xlsx")
utils::download.file(remote_xlsx, tmp_xlsx, mode = "wb", quiet = TRUE)
stip_survey <- readxl::read_excel(tmp_xlsx)
head(stip_survey)
#To facilitate working with the dataset, we generate a separate 'Codebook' dataframe listing the column names and the detail given in the first row, for variables on themes and direct beneficiaries
codebook <- cbind(names(stip_survey), as.character(stip_survey[1,])) %>%
  as.data.frame() %>%
  filter(str_detect(V1, "TH|TG"))

names(codebook) <- c("Code","Meaning")

#Next, we clean up the dataset by removing the first row, so that all rows in the dataset now contain survey data.
stip_survey <- stip_survey[-1,]

#We also convert dummy columns on policy themes and direct beneficiaries to numeric format (given the first row of the dataset containing text information, columns had character formatting before).
stip_survey <- stip_survey %>%
    mutate(across(starts_with(c("TH","TG")), ~ suppressWarnings(as.numeric(.x))))

#A glimpse into the codebook:
print("First 5 rows of the codebook:")
print(head(codebook, 5))


stip_survey_Unique <- dplyr::distinct(stip_survey, InitiativeID, .keep_all = TRUE)
# Remove duplicates of policy initiatives
print(paste("Original data rows:", nrow(stip_survey)))
print(paste("Unique initiatives:", nrow(stip_survey_Unique)))
head(stip_survey_Unique)


financing_innovation <- stip_survey %>%
  dplyr::select(!starts_with("F")) %>% #just removing columns not needed for present analysis to make the dataset easier to handle
  dplyr::filter(rowSums(across(c(TH31, TH32, TH36, TH38), ~ replace_na(.x, 0))) > 0) %>% #filter to retain only the policy themes in question
  tidyr::pivot_longer(c(TH31, TH32, TH36, TH38), names_to = "Theme", values_to = "value") %>% #change the format of the dataframe to enable separate analysis of the four themes
  dplyr::filter(value == 1) %>%
  dplyr::group_by(InitiativeID, Theme) %>%
  dplyr::summarise(n_instruments = dplyr::n(), .groups = "drop") %>% #obtain the number of instruments by counting the number of rows per policy initiativer per theme
  dplyr::group_by(Theme) %>%
  dplyr::distinct(InitiativeID, .keep_all = TRUE) %>% # retain only unique policy initiatives
  dplyr::summarise(n_initiatives = dplyr::n(), n_instruments = sum(n_instruments), .groups = "drop") # count unique policy initiatives and sum the numbers of their instruments

# 7a) Plot: instruments vs initiatives by theme
p1 <- financing_innovation %>%
  tidyr::pivot_longer(c(n_initiatives, n_instruments), names_to = "Metric", values_to = "Count") %>%
  ggplot(aes(x = Theme, y = Count, fill = Metric)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("skyblue", "steelblue"), name = "") +
  labs(title = "Policy instruments vs initiatives by theme",
       x = "", y = "Count") +
  theme_minimal(base_size = 12) +
  coord_flip() +
  scale_x_discrete(labels = setNames(codebook$Meaning, codebook$Code))
print(p1)


TH32_instruments <- stip_survey %>%
  dplyr::select(!starts_with("F")) %>%
  dplyr::filter(!is.na(TH32) & TH32 > 0) %>%
  dplyr::group_by(InstrumentTypeLabel) %>%
  dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(n)) %>%
  dplyr::slice_head(n = 5)

# 8a) Plot: top 5 instrument types for TH32
p2 <- TH32_instruments %>%
  ggplot(aes(x = reorder(InstrumentTypeLabel, n), y = n)) +
  geom_col(fill = "skyblue") +
  coord_flip() +
  labs(title = "Top 5 instrument types (TH32: Non-financial support to business R&D and innovation)",
       x = "Instrument type", y = "Count") +
  theme_minimal(base_size = 10)
print(p2)




