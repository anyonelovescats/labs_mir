CREATE TABLE price2 (
  id STRING,
  price INT,
  datetime DATE,
  postcode STRING,
  property_type STRING, 
  new_build_flag STRING, 
  tenure_type STRING, 
  primary_addressable_object_name STRING, 
  secondary_addressable_object_name STRING,
  street STRING,
  locality STRING,
  town_city STRING,
  district STRING,
  county STRING
  )
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ("separatorChar" = ",", "quoteChar"="\"", "escapeChar"="\\")
STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH '/opt/pp-complete.csv' OVERWRITE INTO TABLE price;

-- Количество загруженных строк данных
SELECT count(*) FROM price;

-- Средняя цена за год
select date_format(datetime, 'yyyy'),cast(avg(price) as INT) 
  from price 
  group by date_format(datetime, 'yyyy');

-- Средняя цена за год в городе
select date_format(datetime, 'yyyy'),town_city,cast(avg(price) as INT) 
  from price 
  group by date_format(datetime, 'yyyy'),town_city 
  order by date_format(datetime, 'yyyy');

-- Топ самых дорогих районов
select district,cast(avg(price) as INT) 
  from price2
  group by district
  order by cast(avg(price) as INT);
