-- sales_01_2009.csv external table script
-- run bin/hive -f /opt/aws-gridu-project/aws/hadoop/hive_samples/sales_table.hql
use default;
create external table if not exists sales (
Transaction_date string,
Product string,
Price string,
Payment_Type string,
Name string,
City string,
State string,
Country string,
Account_Created string,
Last_Login string,
Latitude string,
Longitude string
)
comment 'Test Sales table'
row format delimited
fields terminated by '\044' lines terminated by '\n'
stored as textfile
location '/user/hive/sales'
tblproperties("skip.header.line.count"="1");