Detect spam in reviews    
Task:  
- Use any open dataset with training data to build spam detection classifier using SageMaker ML models  
- Set up batch transform job and generate predictions for reviews, based on concatenated title and text of review  
- Use CloudWatch event (new input in S3) to trigger Lambda function which should launch batch transform job  
- Collect average ratings for items, based on non-spam reviews, which contain not empty content. Publish results into DynamoDB  
----

