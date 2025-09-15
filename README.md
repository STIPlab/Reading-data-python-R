

## 🚀 Getting Started

### Prerequisites

- Python 3.7 or higher
- VS Code with Jupyter extension
- Required Python packages (see Installation section)

### Installation

#### Method 1: Direct Download/Copy Files

1. **Get the Files**
   - Click "Code" → "Download ZIP" on this repository page to download the ZIP file
   - Or copy and save individual files (`Story_intro.ipynb`, `data.md`, etc.) as needed

2. **Run in VS Code (Recommended)**
   - Install VS Code (https://code.visualstudio.com/)
   - Install the "Jupyter" extension
   - Open the downloaded folder in VS Code
   - Open `Story_intro.ipynb`
   - Run all cells

#### Method 2: Run in Google Colab (Easy Alternative)

If installing and setting up VS Code is difficult, we recommend using Google Colab:

1. **Access Google Colab**
   - Go to https://colab.research.google.com/
   - Sign in with your Google account

2. **Upload the Notebook**
   - Click "File" → "Upload notebook"
   - Upload `Story_intro.ipynb`
   - Or create a new notebook and copy & paste the code

3. **Install Packages**
   - Run the following in the first cell:
     ```python
     !pip install pandas numpy matplotlib seaborn networkx
     ```

**Note**: Google Colab requires internet connection and some features may be limited.

#### Method 3: Run R Code

For users who prefer R over Python:

1. **Install R and RStudio**
   - Install R from https://www.r-project.org/
   - Install RStudio from https://www.rstudio.com/products/rstudio/download/

2. **Run the R Script**
   - Open `STIP_compass_intro.R` in RStudio
   - The script will automatically install required packages using `pacman`
   - Run the entire script or execute sections step by step

3. **Required R Packages**
   The script will automatically install these packages:
   - `data.table`, `dplyr`, `ggplot2`, `stringr`, `tidyr`, `DT`, `readr`

**Note**: The R version provides similar analysis to the Python Jupyter notebook but with R-specific data manipulation and visualization tools.

## 📈 Analysis Components

### 1. Data Loading and Preprocessing
```python
# Load data from OECD STIP Survey
url = "https://stip.oecd.org/assets/downloads/STIP_Survey.csv"
stip_survey = pd.read_csv(url, sep="|")

# Remove description row and prepare data
stip_survey = stip_survey.iloc[1:].reset_index(drop=True)
```

### 2. Governance Theme Analysis
- Co-occurrence heatmap of governance policy themes
- Strategic autonomy and dynamic capabilities analysis
- STI planning and evaluation assessment

### 3. Innovation Financing Analysis
- Financial support to business R&D and innovation
- Non-financial support instruments
- Foreign direct investment and access to finance

### 4. Cross-country Comparisons
- Policy initiative counts by country
- Top countries in specific policy areas
- Geographic distribution of instruments

### 5. Network Analysis
- Country-instrument relationship networks
- Dynamic skills and capabilities mapping
- Policy instrument clustering

## 📄 License

This project is for educational and research purposes. The OECD STIP data is publicly available through the OECD website.

