#!/usr/bin/env python
# coding: utf-8

# In[1]:


get_ipython().run_line_magic('env', 'BUCKET=ykumarbekov-534348')


# In[11]:


# #############################
# Loading and training data
# Algorithm: BlazingText classification
# #############################
import boto3
import os
import pandas as pd
import sagemaker
from sagemaker import get_execution_role
from sagemaker.amazon.amazon_estimator import get_image_uri
import numpy as np
from random import shuffle
import multiprocessing
from multiprocessing import Pool
import csv
import nltk
import json

nltk.download('punkt')
bucket = os.environ['BUCKET']
role = get_execution_role()
prefix = 'sagemaker/datasets'

session = sagemaker.Session()

index_to_label = {1:'spam',2:'ham'} 


# In[3]:


def transform_instance(row):
    cur_row = []
    label = "__label__" + row[0]  #Prefix the index-ed label with __label__
    cur_row.append(label)
    cur_row.extend(nltk.word_tokenize(row[1].lower()))
    return cur_row


# In[4]:


def preprocess(input_file, output_file, keep=1):
    all_rows = []
    with open(input_file, 'r') as csvinfile:
        csv_reader = csv.reader(csvinfile, delimiter=',')
        for row in csv_reader:
            all_rows.append(row)
            # print('{}-{}-{}'.format(row[0],row[1],row[2]))
    shuffle(all_rows)
    all_rows = all_rows[:int(keep*len(all_rows))] 
    
    pool = Pool(processes=multiprocessing.cpu_count())
    transformed_rows = pool.map(transform_instance, all_rows)
    # print(transformed_rows)
    pool.close() 
    pool.join()
    
    with open(output_file, 'w') as csvoutfile:
        csv_writer = csv.writer(csvoutfile, delimiter=' ', lineterminator='\n')
        csv_writer.writerows(transformed_rows)


# In[ ]:


get_ipython().system(' cat ./datasets_483_982_spam-3.csv|head -3')


# In[52]:


# Preparing input dataset
train_key = '{}/{}/{}'.format(prefix, 'input/blazingtext','datasets_483_982_spam-2.csv')
md = pd.read_csv('s3://{}/{}'.format(bucket, train_key), index_col=0)
md1 = md.loc[md.v2.str.contains('"') == False]
train_data, test_data = np.split(md1.sample(frac=1, random_state=1729), [int(0.7 * len(md1))])
train_data.to_csv('spam_input_train.csv', header=False, index=False)
test_data.to_csv('spam_input_test.csv', header=False, index=False)


# In[9]:


# ! cat ./spam-input-train.csv|head -3
# ! head -10 ./spam-input-train.csv > ./spam-input-train.csv.sample
# ! cat ./spam_output_train.csv|grep spam|head -3
get_ipython().system(' head -3 ./spam_output_test.csv')


# In[5]:


preprocess('spam_input_train.csv', 'spam_output_train.csv')
preprocess('spam_input_test.csv', 'spam_output_test.csv')


# In[20]:


train_channel = prefix + '/train/blazingtext'
validation_channel = prefix + '/validation/blazingtext'

session.upload_data(path='spam_output_train.csv', bucket=bucket, key_prefix=train_channel)
session.upload_data(path='spam_output_test.csv', bucket=bucket, key_prefix=validation_channel)

s3_train_data = 's3://{}/{}'.format(bucket, train_channel)
s3_validation_data = 's3://{}/{}'.format(bucket, validation_channel)
s3_output_location = 's3://{}/{}/model'.format(bucket, 'sagemaker')

print(s3_output_location)
print(s3_train_data)
print(s3_validation_data)


# In[15]:


region_name = boto3.Session().region_name
container = sagemaker.amazon.amazon_estimator.get_image_uri(region_name, "blazingtext", "latest")
print('Using SageMaker BlazingText container: {} ({})'.format(container, region_name))


# In[16]:


bt_model = sagemaker.estimator.Estimator(container,
                                         role, 
                                         train_instance_count=1, 
                                         train_instance_type='ml.c4.4xlarge',
                                         train_volume_size = 30,
                                         train_max_run = 360000,
                                         input_mode= 'File',
                                         output_path=s3_output_location,
                                         sagemaker_session=session)

bt_model.set_hyperparameters(mode="supervised",
                            epochs=10,
                            min_count=2,
                            learning_rate=0.05,
                            vector_dim=10,
                            early_stopping=True,
                            patience=4,
                            min_epochs=5,
                            word_ngrams=1)


# In[21]:


train_data = sagemaker.session.s3_input(s3_train_data, distribution='FullyReplicated', 
                        content_type='text/plain', s3_data_type='S3Prefix')
validation_data = sagemaker.session.s3_input(s3_validation_data, distribution='FullyReplicated', 
                             content_type='text/plain', s3_data_type='S3Prefix')
data_channels = {'train': train_data, 'validation': validation_data}


# In[ ]:


# Start training
bt_model.fit(inputs=data_channels, logs=True)


# In[23]:


# Deploying model
classifier = bt_model.deploy(
    endpoint_name='ykumarbekov-bt-endpoint',
    model_name='ykumarbekov-bt-capstone-model',
    initial_instance_count = 1,
    instance_type = 'ml.m4.xlarge')


# In[ ]:


# Make test predictions with endpoint
import json
s = ["Free entry in 2 a wkly comp to win FA Cup final tkts 21st May 2005. Text FA to 87121 to receive entry question(std txt rate)T&C's apply 08452810075over18's",
     "Bad book and useless content"]
ts = [' '.join(nltk.word_tokenize(s1)) for s1 in s]
payload = {"instances" : ts}
response = classifier.predict(json.dumps(payload))
predictions = json.loads(response)
print(json.dumps(predictions, indent=2))


# In[ ]:


# Create batch transform job
import os
import sagemaker

bucket = os.environ['BUCKET']
output_path = 's3://{}/{}/'.format(bucket, 'logs/predictions')
input_path = 's3://{}/{}'.format(bucket, 'logs/reviews/15062020095628.log')

transformer = sagemaker.transformer.Transformer(
    model_name='ykumarbekov-bt-capstone-model',
    strategy='MultiRecord',
    instance_count=1,
    instance_type='ml.m4.xlarge',
    assemble_with='Line',
    output_path=output_path,
    accept='application/jsonlines')
# #####
transformer.transform(
    input_path, 
    content_type="application/jsonlines",
    input_filter="$.review",
    output_filter="$",
    join_source="Input",
    split_type="Line"
)
# #####
transformer.wait()


# In[ ]:




