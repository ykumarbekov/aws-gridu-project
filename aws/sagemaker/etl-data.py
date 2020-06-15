#!/usr/bin/env python
# coding: utf-8

# In[2]:


get_ipython().run_line_magic('env', 'BUCKET=ykumarbekov-534348')


# In[3]:


import boto3
import os
import csv
import json
import nltk
import pandas as pd
from io import StringIO, BytesIO
from sagemaker import get_execution_role

bucket = os.environ['BUCKET']
prefix = 'sagemaker/datasets'

nltk.download('punkt')


# In[15]:


# #############################
# Preparing reviews.csv based on Datasets downloaded from Kaggle
# #############################
role = get_execution_role()
pd.set_option('display.max_colwidth', -1)
# ****
aws_reviews_loc = 's3://{}/{}'.format(bucket, 'sagemaker/datasets/input/amazon-reviews.csv')
prj_reviews_loc = 's3://{}/{}'.format(bucket, 'sagemaker/datasets/input/my_reviews.csv')
spam_sms_loc = 's3://{}/{}'.format(bucket, 'sagemaker/datasets/input/dataset_spam.csv')
spam_email_loc = 's3://{}/{}'.format(bucket,'sagemaker/datasets/input/spam_ham_dataset.csv')
target_ds_loc = 's3://{}/{}'.format(bucket,'sagemaker/datasets/input/reviews.csv')
# ****
awsr = pd.read_csv(aws_reviews_loc, sep='\t')
prr = pd.read_csv(prj_reviews_loc, sep='|')
spam_sms = pd.read_csv(spam_sms_loc, encoding='ISO-8859-1')
spam_email = pd.read_csv(spam_email_loc)
# #############################
awsr_1 = awsr.loc[awsr.review.str.contains('book', na=False) & awsr.review.str.contains('read', na=False)]
awsr_2 = awsr_1.loc[awsr_1.review.str.contains('baby|babies|son|mom|kid|daughter', case=False)==False] 
awsr_3 = awsr_2.loc[awsr_2.review.str.len()<1000]
awsr_4 = awsr_3[['review','rating']]
# ****
prr_1 = prr.rename(columns={'review_text': 'review','review_stars':'rating'})
# ****
spam_sms_1 = spam_sms.loc[spam_sms.v1 == 'spam']
spam_sms_2 = spam_sms_1.loc[spam_sms_1.v2.str.len()<1000][['v2']].head(50)
spam_sms_3 = spam_sms_2.rename(columns={'v2':'review'})
spam_sms_3['rating'] = 0
# ****
spam_email_1 = spam_email.loc[spam_email.label == 'spam']
spam_email_2 = spam_email_1.loc[spam_email_1.text.str.len()<1000][['text']].head(50)
spam_email_3 = spam_email_2.rename(columns={'text':'review'})
spam_email_3['rating'] = 0
# ****
awsr_5 = pd.concat([awsr_4, prr_1], sort=False)
awsr_6 = pd.concat([awsr_5, spam_sms_3], sort=False)
awsr_fin = pd.concat([awsr_6, spam_email_3], sort=False)


# In[16]:


import csv
csv_buffer = StringIO()
sv = awsr_fin.loc[(awsr_fin.review.str.contains('\n') == False)]
sv.to_csv(csv_buffer, sep='|', index=False, quoting=csv.QUOTE_MINIMAL)
s3 = boto3.resource('s3')
s3.Object(bucket, 'sagemaker/datasets/input/reviews.csv').put(Body=csv_buffer.getvalue())


# In[ ]:


# AWS example:
import boto3, re, sys, math, json, os, sagemaker, urllib.request
import numpy as np                                
import pandas as pd
from sagemaker import get_execution_role

role = get_execution_role()
try:
  urllib.request.urlretrieve ("https://d1.awsstatic.com/tmt/build-train-deploy-machine-learning-model-sagemaker/bank_clean.27f01fbbdf43271788427f3682996ae29ceca05d.csv", "bank_clean.csv")
  print('Success: downloaded bank_clean.csv.')
except Exception as e:
  print('Data load error: ',e)

try:
  model_data = pd.read_csv('./bank_clean.csv',index_col=0)
  print('Success: Data loaded into dataframe.')
except Exception as e:
    print('Data load error: ',e)
# #####
train_data, test_data = np.split(model_data.sample(frac=1, random_state=1729), [int(0.7 * len(model_data))])
# print(train_data.shape, test_data.shape)
prefix = 'sagemaker/tests'
pd.concat([train_data['y_yes'], train_data.drop(['y_no', 'y_yes'], axis=1)], axis=1).to_csv('train.csv', index=False, header=False)
boto3.Session().resource('s3').Bucket(bucket).Object(os.path.join(prefix, 'train/train.csv')).upload_file('train.csv')
s3_input_train = sagemaker.s3_input(s3_data='s3://{}/{}/train'.format(bucket, prefix), content_type='csv')
print(s3_input_train)


# In[ ]:


train_loc = 's3://{}/{}'.format(bucket, 'sagemaker/tests/train/train.csv')
df = pd.read_csv(train_loc)
df.head(5)


# In[22]:


# #############################
# Preparing training dataset based on Dataset: datasets_483_982_spam downloaded from Kaggle
# Algorithm: XGBoost: binary logistic
# 1st column: Label [1,0], or 1 - spam; 0 - ham
# 2nd and other columns - features
# Steps:
# Remove all unnecessary columns 
# Clean data: remove excessed commas and quotes
# #############################
pd.set_option('display.max_colwidth', -1)
prefix = 'sagemaker/datasets'
train_key = '{}/{}/{}'.format(prefix, 'input','datasets_483_982_spam-2.csv')
# df = pd.read_csv('s3://{}/{}'.format(bucket, train_key), encoding='ISO-8859-1', usecols=['v1', 'v2'])
df = pd.read_csv('s3://{}/{}'.format(bucket, train_key), index_col=0)
df.loc[df['v1'] == 'spam', 'v1'] = 1
df.loc[(df['v1'] == 'ham'), 'v1'] = 0
df1 = df[['v1','v2']]
# df['v1'].unique()
df1 = df.loc[df.v2.str.contains('\,', na=False) == False]
df2 = df1.loc[df1.v2.str.contains('"') == False]
# spam = df1.loc[df1.v1 == 'spam']; ham = df1.loc[df1.v1 == 'ham']
# print('{} {} {}'.format(df1.shape[0], spam.shape[0], ham.shape[0]))
# df2.shape
df2.to_csv('datasets_483_982_spam-3.csv', header=False, index=False)
boto3.Session().resource('s3').Bucket(bucket).Object('sagemaker/datasets/input/datasets_483_982_spam-3.csv').upload_file('datasets_483_982_spam-3.csv')


# In[ ]:


train_key = '{}/{}/{}'.format(prefix, 'input','datasets_483_982_spam-3.csv')
# model_data = pd.read_csv('s3://{}/{}'.format(bucket, train_key), 
#                         encoding='ISO-8859-1', index_col=0, usecols=['v1', 'v2'])
md = pd.read_csv('s3://{}/{}'.format(bucket, train_key))
md1 = md.loc[md.v2.str.contains('"', na=False)]
md1.head(5)


# In[ ]:


md0 = pd.read_csv('./train-capstone.csv', index_col=0)
md0.tail(25)


# In[ ]:


df1 = pd.read_json('s3://{}/{}'.format(bucket,'logs/reviews/08062020073912.log'), lines=True)
df2 = df1.loc[(df1.review.str.contains('\n') == False) & (df1.review.str.contains('"') == False)].head(10)
# df3 = df2[['review']]
# dt_lst = df2[['ISBN','ip','rating','review','timestamp']].to_dict('records')
dt_lst = df2.to_dict('records')
out_lst = []
for dt in dt_lst:
    dt['reviewcontent'] = {'source': dt['review']}
    del dt['review']
    out_lst.append(dt)
df3 = pd.DataFrame.from_dict(out_lst, orient='columns')    
df4 = df3.rename(columns={'reviewcontent':'review'})
# df4 = df3[['ISBN','ip','rating','review_json','timestamp']]
# df4 = df3[['source']]
# df4.head(3)

out_buffer = StringIO()
s3 = boto3.resource('s3')
df4.to_json(out_buffer, orient='records', lines=True)
s3.Object(bucket, 'logs/reviews/batch_job_test.log').put(Body=out_buffer.getvalue())
# #####


# In[18]:


reviews = 's3://{}/{}'.format(bucket, 'sagemaker/datasets/input/reviews.csv')
df = pd.read_csv(reviews, sep='|')
#df.shape
df1 = df.loc[(df.review.str.contains('\n') == False)]
df1.shape


# In[ ]:




