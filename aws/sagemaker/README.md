Detect spam in reviews    
Task:  
- Use any open dataset with training data to build spam detection classifier using SageMaker ML models  
- Set up batch transform job and generate predictions for reviews, based on concatenated title and text of review  
- Use CloudWatch event (new input in S3) to trigger Lambda function which should launch batch transform job  
- Collect average ratings for items, based on non-spam reviews, which contain not empty content. Publish results into DynamoDB  
----
To realize this task I used AWS in-built BlazingText algorithm  
The Amazon SageMaker BlazingText algorithm provides highly optimized implementations of the text classification algorithm  
In my case I have logs with user's reviews and I have to identify the text as SPAM or not SPAM  
The first step I chose algorithm, downloaded dataset for training (folder: aws/sagemaker/datasets_482_983_spam.csv) which contains  
features v1, v2 and v1 - is a label has pre-defined values: ham/spam  
AWS Jupyter notebooks:  
- capstone-bt.ipynb: contains code used for training and deploying model  
- etl-data.ipynb: supplementary notebook I used for data ETL  
After successfully deploying model I created endpoint and made predictions  
```
# Make test predictions with endpoint
import json
s = ["Free entry in 2 a wkly comp ... 08452810075over18's", "Bad book and useless content"]
ts = [' '.join(nltk.word_tokenize(s1)) for s1 in s]
payload = {"instances" : ts}
response = classifier.predict(json.dumps(payload))
predictions = json.loads(response)
print(json.dumps(predictions, indent=2))
```
Also for batch transform job I used next code:  
```
bucket = os.environ['BUCKET']
output_path = 's3://{}/{}/'.format(bucket, 'logs/predictions')
input_path = 's3://{}/{}'.format(bucket, 'logs/reviews/15062020095628.log')

transformer = sagemaker.transformer.Transformer(
    model_name='ykumarbekov-bt-capstone-model',
    ...
    accept='application/jsonlines')
# #####
transformer.transform(
    input_path, 
    ...
)
transformer.wait()
```
As result I received output file which contains predictions:  
```
{"ISBN":"0072294337","SageMakerOutput":{"label":["__label__ham"],"prob":[0.8249409198760986]},"device_id" ...
{"ISBN":"0735712360","SageMakerOutput":{"label":["__label__ham"],"prob":[0.6037992238998413]},"device_id" ...
...
```
For trigger I used code for Lambda function: s3_trigger.py  
And for final collecting average rating I used code from file: result2dynamo.py:  
```
python aws/sagemaker/result2dynamo.py --input-key=logs/predictions/15062020155302.log.out --bucket=$BUCKET --table=reviews-ykumarbekov
```