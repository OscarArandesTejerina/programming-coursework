#!/usr/bin/env python
# coding: utf-8

# In[188]:


import numpy as np
import pandas as pd


# Create a dictionary mapping the feature with its data type (specific for the dataset we are analysing)

# In[211]:


attribute_types = {
    "age": "numeric",
    "sex": "categorical",
    "chest-pain": "categorical",
    "resting-blood-pressure": "numeric",
    "serum-cholestoral": "numeric",
    "fasting-blood-sugar": "categorical",
    "rest-ecg": "categorical",
    "max-heart-rate": "numeric",
    "exercise-angina": "categorical",
    "oldpeak-ecg": "numeric",
    "slope-ecg": "categorical",
    "major-vessels": "numeric",
    "thal": "categorical"
}


# Preprocess the dataset to assign a numerical values to categorical features 

# In[243]:


def preprocess_dataset(df, attribute_types):
    df = df.copy()    
    df = df.replace("?", pd.NA) # Replace "?" with NaN 
    
    for col, typ in attribute_types.items():
        if typ == "numeric":
            df[col] = df[col].astype("Float64")
        if typ == "categorical":
            df[col] = df[col].astype("category")                           # Convert categorial features into "category" data type.
            df[col] = df[col].cat.codes.replace(-1, pd.NA).astype("Int64") # Assign integer codes for each category and keep missing values as NA
    
    return df


# Read the dataset

# In[256]:


df = pd.read_csv("disease.csv", sep="\t")
processed_df = preprocess_dataset(df, attribute_types)
print(processed_df.shape)


# Split preprocessed dataset intro training (80%) and testing (20%) datasets in a random way

# In[245]:


train_df = processed_df.sample(frac=0.8, random_state=42)
test_df = processed_df.drop(train_df.index)

print(train_df.shape)
print(test_df.shape)


# Identify the features and target 

# In[246]:


target_cols = ['H','S1','S2','S3','S4']            # Specific for our dataset
feature_cols = df.columns.difference(target_cols)


# In[247]:


train_df_x = train_df[feature_cols]
train_df_y = train_df[target_cols]

test_df_x  = test_df[feature_cols]
test_df_y  = test_df[target_cols]

test_df_y


# In[248]:


# If the target is multi-column (one-hot), convert to single-label
if train_df_y.shape[1] > 1 or test_df_y.shape[1] > 1:
    train_df_y = train_df_y.idxmax(axis=1)    # picks the active column as label
    test_df_y  = test_df_y.idxmax(axis=1)

test_df_y


# ## Naive Bayes Classifier

# In[249]:


# Here, we define our own Naive Bayesian model 
class MyNaiveBayes():
    def __init__(self, alpha):
        self.alpha = alpha                         # initialize smoothing parameter
        self.P_y = {}                              # initialize P(y) 
        self.n_y = {}                              # initialize n_y
        self.attribute_types = attribute_types 
        self.gaussian_params = {}
        self.discrete_params = {}
        self.categories = {}
        pass
    
    def fit(self, data_x, data_y):
        n_tot = len(data_y)                        # total number of class instances
        classes = np.unique(data_y)                # different classes of the dataset (in our dataset corresponds H, S1, S2, S3, S4)
        
        for clss in classes:
            data_ix = data_x[data_y == clss]       # data_x([TRUE, FALSE, FALSE,...]) = instances that belong to class "clss"
            self.n_y[clss] = len(data_ix)          # number of occurrences in the dataset of each class    
            self.P_y[clss] = (self.n_y[clss] + self.alpha)/(n_tot + len(classes)*self.alpha)  # Estimate P(y) 
            
            self.gaussian_params[clss] = {}
            self.discrete_params[clss] = {}
            
            for col, typ in self.attribute_types.items():
                if typ == "numeric":
                    vals = data_ix[col].dropna()
                    mean = vals.mean()
                    var = vals.var()                                  
                    self.gaussian_params[clss][col] = (mean, var)
                    
                elif typ == "categorical":
                    vals = data_ix[col].dropna()
                    counts = vals.value_counts()
                    categories = data_x[col].dropna().unique()
                    self.categories[col] = categories
                    probs = {}
                    for cat in categories:
                        probs[cat] = (counts.get(cat,0) + self.alpha) / (len(vals) + len(categories)*self.alpha)
                    self.discrete_params[clss][col] = probs
            pass
    
    def predict(self, data_x):
        y_pred = []
        for idx, row in data_x.iterrows():
            log_probs = {}
            for clss in self.P_y:
                log_prob = np.log(self.P_y[clss])
                
                for col, typ in self.attribute_types.items():
                    val = row[col]
                    if pd.isna(val):
                        continue  # skip missing                    
                    if typ == "numeric":
                        mean, var = self.gaussian_params[clss][col]
                        log_prob += -0.5*np.log(2*np.pi*var) - ((val-mean)**2)/(2*var)
                    elif typ == "categorical":
                        log_prob += np.log(self.discrete_params[clss][col].get(val, self.alpha/(self.alpha*len(self.categories[col]))))
                log_probs[clss] = log_prob
            y_pred.append(max(log_probs, key=log_probs.get))
            
        return y_pred


# ## Performance

# In[301]:


model = MyNaiveBayes(1)
model.fit(train_df_x, train_df_y)


# In[302]:


# Performance on training data
sum(model.predict(train_df_x) == train_df_y)/len(train_df_x)*100


# In[303]:


# Performance on test data
sum(model.predict(test_df_x) == test_df_y)/len(test_df_x)*100


# In[ ]:




