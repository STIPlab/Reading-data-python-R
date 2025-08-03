
## 🚀 Getting Started

### Prerequisites

- Python 3.7 or higher
- VS Code with Jupyter extension
- Required Python packages (see Installation section)

### Installation

1. **Clone or download this repository**
   ```bash
   git clone https://github.com/STIPlab/Reading-data-python.git
   cd Reading-data-python
   ```

2. **Open in VS Code**
   - Open VS Code
   - Open the project folder
   - Install the "Jupyter" extension if not already installed
   - Open `Story_intro.ipynb`
   - pip install pandas numpy matplotlib seaborn networkx jupyter

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

## 🎯 Key Findings

The analysis reveals:
- **Portugal** leads with 360 policy initiatives
- **Germany** is most active in financial support to business R&D (98 initiatives)
- **Governance themes** show strong co-occurrence patterns
- **Non-financial support** instruments are diverse across countries


## 📄 License

This project is for educational and research purposes. The OECD STIP data is publicly available through the OECD website.

