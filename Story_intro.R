# OECD STIP Survey Data Analysis in R
# データ分析に必要なライブラリのインストールと読み込み
# Install and load necessary R libraries

# 必要なパッケージのインストール（初回のみ実行）
install.packages(c("tidyverse", "ggplot2", "dplyr", "igraph", "network", "sna", "viridis", "RColorBrewer"))

# ライブラリの読み込み
library(tidyverse)
library(ggplot2)
library(dplyr)
library(igraph)
library(network)
library(sna)
library(viridis)
library(RColorBrewer)

# データセットの読み込み（OECD STIP Survey）
# Load the dataset from OECD STIP Survey with error handling
url <- "STIP_Survey.csv"

# エラーハンドリング付きでデータを読み込み
# Load data with error handling
tryCatch({
  stip_survey <- read.csv(url, sep = "|", stringsAsFactors = FALSE)
  print("Data loaded successfully!")
}, error = function(e) {
  print(paste("Error loading data:", e$message))
  print("Trying alternative approach...")
  
  # 代替アプローチ
  # Alternative approach
  tryCatch({
    stip_survey <<- read.csv(url, sep = "|", stringsAsFactors = FALSE, 
                            fileEncoding = "UTF-8", quote = "")
    print("Data loaded with error handling!")
  }, error = function(e2) {
    print(paste("Alternative approach also failed:", e2$message))
    stop(e2)
  })
})

# データセットの基本情報を表示
# Display basic information about the dataset
cat("\nNumber of rows in the dataset:", nrow(stip_survey), "\n")
cat("\nFirst 5 rows of the dataset:\n")
print(head(stip_survey, 5))

# コードブックの作成
# Create a separate 'Codebook' dataframe listing the column names and the detail given in the first row
# 1. 列名（Code）と最初の行（Meaning）を取得
# Get column names (Code) and the first row (Meaning) from the DataFrame
columns <- colnames(stip_survey)
meanings <- stip_survey[1, ]

# 2. 各列名とその説明をペアリングしたデータフレームを作成
# Create a DataFrame pairing each column name with its description
codebook <- data.frame(
  Code = columns,
  Meaning = as.character(meanings),
  stringsAsFactors = FALSE
)

# 3. "TH"または"TG"で始まる列のみをフィルタリング（政策テーマと直接受益者）
# Filter only columns whose names start with "TH" or "TG" (policy themes and direct beneficiaries)
codebook <- codebook %>%
  filter(grepl("^TH|^TG", Code)) %>%
  reset_index()

# 4. コードブックの最初の10行を表示
# Display the first 10 rows of the codebook
print(head(codebook, 10))

# データの前処理
# Data preprocessing
# 説明行を削除して観測データのみを保持
# Remove the description row to keep only observational data
stip_survey <- stip_survey[-1, ] %>% reset_index()

# テーマとターゲットグループ列を数値形式に変換
# Convert theme and target group columns to numeric format
th_tg_cols <- grep("^TH|^TG", colnames(stip_survey), value = TRUE)
stip_survey[th_tg_cols] <- lapply(stip_survey[th_tg_cols], function(x) {
  as.numeric(as.character(x))
})

# NAを0で置換
# Replace NA with 0
stip_survey[th_tg_cols][is.na(stip_survey[th_tg_cols])] <- 0

# ユニークなイニシアチブのみを含む別のデータフレームを作成
# Create a separate DataFrame with unique initiatives only
stip_survey_unique <- stip_survey %>%
  distinct(InitiativeID, .keep_all = TRUE)

cat("Data loaded and prepared.\n")
cat("Total policy instruments (rows):", nrow(stip_survey), "\n")
cat("Total unique policy initiatives:", nrow(stip_survey_unique), "\n")
print(head(stip_survey_unique, 5))

# TH31（ビジネスR&Dへの財政支援）の分析
# Analysis of TH31 (Financial support to business R&D)
th31_initiatives <- stip_survey_unique %>%
  filter(TH31 == 1)

# 国別のイニシアチブ数をカウントして上位10カ国を取得
# Count the number of initiatives per country and get the top 10
top_countries_th31 <- th31_initiatives %>%
  count(CountryLabel, sort = TRUE) %>%
  head(10)

# 結果の表示
# Print the resulting counts
cat("Top 10 countries by number of initiatives for 'Financial support to business R&D':\n")
print(top_countries_th31)

# 結果を棒グラフで可視化
# Visualize the results using a bar chart for better comparison
ggplot(top_countries_th31, aes(x = reorder(CountryLabel, n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Top 10 Countries by Number of Initiatives in 'Financial support to business R&D'",
       x = "Country",
       y = "Number of Unique Initiatives") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

# ガバナンステーマの共起分析
# Co-occurrence analysis of governance themes
# 1. 分析するガバナンステーマを定義
# Define the governance themes to analyze
governance_themes <- c(
  # 新しいテーマ
  # New themes
  'TH111',  # Strategic autonomy and promotion of critical technologies
  'TH110',  # Dynamic skills and capabilities for policymaking
  'TH112',  # Net zero transitions in steel
  
  # 関連テーマ（高い共起可能性）
  # Related themes with high co-occurrence potential
  'TH34',   # Dynamic and entrepreneurial capabilities and culture
  'TH13',   # STI plan or strategy
  'TH15',   # Evaluation and impact assessment
  'TH22',   # Structural change in the public research system
  
  # 新しいテーマと共起しそうな追加テーマ
  # Additional themes that likely co-occur with new themes
  'TH31',   # Financial support to business R&D and innovation
  'TH32',   # Non-financial support to business R&D and innovation
  'TH82',   # Digital transformation of firms
  'TH91',   # Mission-oriented innovation policies
  'TH92',   # Net zero transitions in energy
  'TH103',  # Net zero transitions in transport and mobility
  'TH104',  # Net zero transitions in food and agriculture
  'TH89',   # Ethics and governance of emerging technologies
  'TH106',  # Digital transformation of research-performing organisations
  'TH109'   # Research security
)

# 2. ヒートマップ用の英語ラベル
# English labels for the heatmap
label_mapping <- c(
  # 新しいテーマ
  # New themes
  'TH111' = 'Strategic Autonomy & Critical Technologies',
  'TH110' = 'Dynamic Skills for Policymaking',
  'TH112' = 'Net Zero Transitions in Steel',
  
  # 関連テーマ
  # Related themes
  'TH34' = 'Dynamic & Entrepreneurial Capabilities',
  'TH13' = 'STI Plan/Strategy',
  'TH15' = 'Evaluation & Impact Assessment',
  'TH22' = 'Structural Change in Public Research',
  
  # 追加の関連テーマ
  # Additional related themes
  'TH31' = 'Financial Support to Business R&D',
  'TH32' = 'Non-financial Support to Business R&D',
  'TH82' = 'Digital Transformation of Firms',
  'TH91' = 'Mission-oriented Innovation Policies',
  'TH92' = 'Net Zero Transitions in Energy',
  'TH103' = 'Net Zero Transitions in Transport',
  'TH104' = 'Net Zero Transitions in Food & Agriculture',
  'TH89' = 'Ethics & Governance of Emerging Tech',
  'TH106' = 'Digital Transformation of Research Org',
  'TH109' = 'Research Security'
)

# 3. データセットで利用可能なテーマをチェック
# Check which themes are available in the dataset
available_themes <- governance_themes[governance_themes %in% colnames(stip_survey_unique)]
cat("Available themes in dataset:", length(available_themes), "out of", length(governance_themes), "\n")
cat("Available themes:", paste(available_themes, collapse = ", "), "\n")

# 4. 利用可能なテーマ列のみを含むデータフレームを作成
# Create a DataFrame containing only available theme columns
governance_df <- stip_survey_unique[, available_themes, drop = FALSE]
colnames(governance_df) <- label_mapping[available_themes]

# 5. 共起行列を計算
# Calculate the co-occurrence matrix
co_occurrence_matrix <- t(governance_df) %*% as.matrix(governance_df)

# 6. ヒートマップを描画（反転したカラースキーム）
# Draw the heatmap with inverted color scheme
# データフレームに変換
co_occurrence_df <- as.data.frame(co_occurrence_matrix)
co_occurrence_df$theme1 <- rownames(co_occurrence_df)
co_occurrence_long <- co_occurrence_df %>%
  pivot_longer(-theme1, names_to = "theme2", values_to = "co_occurrence")

ggplot(co_occurrence_long, aes(x = theme2, y = theme1, fill = co_occurrence)) +
  geom_tile() +
  geom_text(aes(label = co_occurrence), size = 3) +
  scale_fill_viridis(option = "viridis", direction = -1) +
  labs(title = "Co-occurrence Heatmap: New Themes and Related Policy Areas\n(Lighter colors = Lower relationship strength)",
       x = "", y = "", fill = "Number of Co-occurrences") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 16, face = "bold"))

# 7. 共起パターンの要約を印刷
# Print summary of co-occurrence patterns
cat("\nCo-occurrence Analysis Summary:\n")
cat("=" %R% 60, "\n")
cat("New Themes (TH111, TH110, TH112) co-occurrence patterns:\n")

# 新しいテーマに焦点
# Focus on new themes
new_themes <- c('TH111', 'TH110', 'TH112')
for (new_theme in new_themes) {
  if (new_theme %in% available_themes) {
    theme_label <- label_mapping[new_theme]
    cat("\n", theme_label, ":\n")
    
    # このテーマの共起値を取得
    # Get co-occurrence values for this theme
    theme_co_occurrences <- co_occurrence_matrix[label_mapping[new_theme], ]
    
    # 共起値でソート（降順）
    # Sort by co-occurrence value (descending)
    sorted_co_occurrences <- sort(theme_co_occurrences, decreasing = TRUE)
    
    # 上位5つの共起テーマを表示
    # Show top 5 co-occurring themes
    cat("Top 5 co-occurring themes:\n")
    for (i in 2:6) {
      if (i <= length(sorted_co_occurrences)) {
        theme_name <- names(sorted_co_occurrences)[i]
        value <- sorted_co_occurrences[i]
        cat("  ", i-1, ". ", theme_name, ": ", value, " initiatives\n")
      }
    }
  }
}

# ネットワーク分析：動的スキルと政策手段
# Network Analysis: Dynamic Skills and Policy Instruments
# 1. 対象テーマを持つイニシアチブに属する手段をフィルタリング
# Filter for instruments belonging to initiatives with the target theme
dynamic_skills_instruments <- stip_survey %>%
  filter(TH34 == 1)

# 2. 国と手段の関係（エッジ）のデータフレームを作成
# Create a DataFrame of the relationships (edges) between countries and instruments
edges <- dynamic_skills_instruments %>%
  select(CountryLabel, InstrumentTypeLabel) %>%
  drop_na() %>%
  reset_index()

# 3. networkxライブラリを使用してこのエッジリストからグラフオブジェクトを作成
# Create a graph object from this list of edges using the networkx library
# Rではigraphパッケージを使用
# Use igraph package in R
G <- graph_from_data_frame(edges, directed = FALSE)

# 4. プロット用のノードプロパティを定義
# Prepare for plotting by defining node properties
# ノードタイプ別に色分け（国 vs 手段）
# Differentiate nodes by type (country vs. instrument) for better visual interpretation
country_nodes <- unique(edges$CountryLabel)
node_colors <- ifelse(V(G)$name %in% country_nodes, "skyblue", "lightgreen")
node_sizes <- ifelse(V(G)$name %in% country_nodes, 20, 40)

# 5. ネットワークグラフを描画
# Draw the network graph
plot(G, 
     vertex.color = node_colors,
     vertex.size = node_sizes,
     vertex.label.cex = 0.8,
     vertex.label.font = 2,
     edge.color = "gray",
     edge.width = 0.5,
     layout = layout_with_fr,
     main = "Network of Countries and Policy Instruments for 'Dynamic Skills in Policymaking'")

# 包括的なネットワーク分析
# Comprehensive Network Analysis
# 設定
# Configuration
categories <- list(
  New = c('TH110', 'TH111', 'TH112'),
  Governance = c('TH11', 'TH13', 'TH9', 'TH14', 'TH15', 'TH63', 'TH91', 'TH89', 'TH65'),
  Research = c('TH16', 'TH18', 'TH19', 'TH20', 'TH27', 'TH22', 'TH106', 'TH107', 'TH108', 'TH24', 'TH25', 'TH26', 'TH23', 'TH21', 'TH109'),
  Innovation = c('TH28', 'TH30', 'TH31', 'TH32', 'TH38', 'TH34', 'TH33', 'TH82', 'TH36', 'TH35'),
  Knowledge = c('TH39', 'TH41', 'TH42', 'TH47', 'TH43', 'TH44', 'TH46'),
  HR = c('TH48', 'TH50', 'TH51', 'TH52', 'TH53', 'TH55', 'TH54'),
  Society = c('TH56', 'TH58', 'TH61', 'TH66'),
  `Net Zero` = c('TH102', 'TH92', 'TH103', 'TH104')
)

colors <- c('lightblue', 'red', 'green', 'blue', 'orange', 'purple', 'brown', 'darkgreen')

# 利用可能なテーマを取得
# Get available themes
themes <- unlist(categories)
themes <- themes[themes %in% colnames(stip_survey_unique)]
new_themes <- c('TH110', 'TH111', 'TH112')

cat("Available themes:", length(themes), "\n")
cat("New themes:", paste(themes[themes %in% new_themes], collapse = ", "), "\n")

# ネットワーク関係を作成
# Create network relationships
relationships <- list()
for (i in 1:nrow(stip_survey_unique)) {
  row <- stip_survey_unique[i, ]
  active <- themes[sapply(themes, function(t) row[[t]] == 1)]
  
  for (j in 1:(length(active)-1)) {
    for (k in (j+1):length(active)) {
      pair <- sort(c(active[j], active[k]))
      pair_key <- paste(pair[1], pair[2], sep = "_")
      if (is.null(relationships[[pair_key]])) {
        relationships[[pair_key]] <- 0
      }
      relationships[[pair_key]] <- relationships[[pair_key]] + 1
    }
  }
}

# 重み付きエッジを作成
# Create weighted edges
edges_list <- list()
for (pair_key in names(relationships)) {
  if (relationships[[pair_key]] >= 2) {
    nodes <- strsplit(pair_key, "_")[[1]]
    edges_list[[length(edges_list) + 1]] <- list(
      from = nodes[1],
      to = nodes[2],
      weight = relationships[[pair_key]]
    )
  }
}

# グラフを作成
# Create graph
if (length(edges_list) > 0) {
  edges_df <- do.call(rbind, lapply(edges_list, function(x) {
    data.frame(from = x$from, to = x$to, weight = x$weight, stringsAsFactors = FALSE)
  }))
  
  G <- graph_from_data_frame(edges_df, directed = FALSE, vertices = data.frame(name = themes))
  
  # 可視化設定
  # Visualization setup
  # ノードの色とラベル
  # Node colors and labels
  node_colors <- sapply(V(G)$name, function(node) {
    for (i in seq_along(categories)) {
      if (node %in% categories[[i]]) {
        return(colors[i])
      }
    }
    return("gray")
  })
  
  node_labels <- sapply(V(G)$name, function(node) {
    for (i in seq_along(categories)) {
      if (node %in% categories[[i]]) {
        cat_name <- names(categories)[i]
        return(paste(node, "\n(", ifelse(cat_name == "New", "NEW", cat_name), ")", sep = ""))
      }
    }
    return(node)
  })
  
  # グラフを描画
  # Draw graph
  edge_weights <- E(G)$weight
  max_w <- max(edge_weights)
  edge_widths <- edge_weights / max_w * 5
  node_sizes <- degree(G) * 20
  
  plot(G, 
       vertex.color = node_colors,
       vertex.size = node_sizes,
       vertex.label = node_labels,
       vertex.label.cex = 0.7,
       vertex.label.font = 2,
       edge.width = edge_widths,
       edge.color = "gray",
       layout = layout_with_fr,
       main = "Policy Theme Network Analysis\n(TH110,111,112 in Light Blue)\nNode size = Connections, Edge thickness = Co-occurrence strength")
  
  # 凡例
  # Legend
  legend("topright", 
         legend = names(categories),
         col = colors,
         pch = 19,
         cex = 0.8,
         title = "Categories")
}

# Net Zero Transitions Comparison Analysis
# Net Zero Transitions 比較分析
# TH102, TH92, TH103, TH104, TH112のタイムライン比較を作成
# Create timeline comparison for TH102, TH92, TH103, TH104, and TH112

# CSVリファレンスに基づくテーマコードとラベル
# Theme codes and labels based on the CSV reference
theme_codes <- c(
  'TH102' = 'Government Capabilities for Net Zero Transitions',
  'TH92' = 'Net Zero Transitions in Energy', 
  'TH103' = 'Net Zero Transitions in Transport and Mobility',
  'TH104' = 'Net Zero Transitions in Food and Agriculture',
  'TH112' = 'Net Zero Transitions in Steel'
)

# 各テーマのタイムラインデータを収集
# Collect timeline data for each theme
timeline_dict <- list()
available_themes <- c()

for (code in names(theme_codes)) {
  if (code %in% colnames(stip_survey_unique)) {
    available_themes <- c(available_themes, code)
    # このテーマのイニシアチブをフィルタリング
    # Filter initiatives for this theme
    initiatives <- stip_survey_unique %>%
      filter(!!sym(code) == 1)
    
    if (nrow(initiatives) > 0) {
      # StartDateYearを数値に変換
      # Convert StartDateYear to numeric
      initiatives$StartDateYear <- as.numeric(as.character(initiatives$StartDateYear))
      initiatives <- initiatives %>%
        filter(!is.na(StartDateYear), StartDateYear > 2000)
      
      if (nrow(initiatives) > 0) {
        timeline <- initiatives %>%
          count(StartDateYear, sort = FALSE) %>%
          arrange(StartDateYear)
        
        timeline_dict[[theme_codes[code]]] <- timeline
        cat(code, ":", nrow(initiatives), "initiatives found\n")
      } else {
        cat(code, ": No initiatives in specified time frame\n")
      }
    } else {
      cat(code, ": No initiatives found\n")
    }
  } else {
    cat(code, ": Theme not available in dataset\n")
  }
}

# 比較プロットを作成
# Create comparison plot
if (length(timeline_dict) > 1) {
  # データを結合
  # Combine data
  all_data <- bind_rows(lapply(names(timeline_dict), function(label) {
    timeline_dict[[label]] %>%
      mutate(Theme = label)
  }), .id = "id")
  
  # 色を定義
  # Define colors
  colors <- c('#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd')
  
  ggplot(all_data, aes(x = StartDateYear, y = n, color = Theme, group = Theme)) +
    geom_line(size = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = colors[1:length(timeline_dict)]) +
    labs(title = "Comparison of Net Zero Transition Initiatives Timeline",
         x = "Year of Introduction",
         y = "Number of New Initiatives",
         color = "Theme") +
    theme_minimal() +
    theme(plot.title = element_text(size = 16, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "right")
  
  # 要約統計を印刷
  # Print summary statistics
  cat("\nSummary of Net Zero Transition Initiatives:\n")
  cat("=" %R% 50, "\n")
  for (label in names(timeline_dict)) {
    timeline <- timeline_dict[[label]]
    total_initiatives <- sum(timeline$n)
    years_active <- nrow(timeline)
    peak_year <- timeline$StartDateYear[which.max(timeline$n)]
    peak_count <- max(timeline$n)
    
    cat(label, ":\n")
    cat("  Total initiatives:", total_initiatives, "\n")
    cat("  Years active:", years_active, "\n")
    cat("  Peak year:", peak_year, "(", peak_count, "initiatives)\n\n")
  }
} else {
  cat("Not enough themes available for comparison\n")
}

# 記述統計の生成
# Generate descriptive statistics
# 主要な年列の記述統計
# Descriptive statistics for key year columns
print(summary(stip_survey[, c('SurveyYear', 'StartDateYear', 'EndDateYear')]))

# 国別のユニークな政策イニシアチブ数をカウント
# Count the number of unique policy initiatives per country
# 'stip_survey_unique'データフレームを使用して重複カウントを避ける
# Use the 'stip_survey_unique' DataFrame to avoid overcounting
top_countries <- stip_survey_unique %>%
  count(CountryLabel, sort = TRUE)

# 上位10カ国を表示
# Display the top 10 countries
print(head(top_countries, 10))
