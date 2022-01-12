Автор Владимир Лила

Установим hive 

Скачаем с оф сайта дистрибутив версии 3.1.2

```
wget https://dlcdn.apache.org/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz

```

После скачивания распакуем

```
tar -xzvf apache-hive-3.1.2-bin.tar.gz

```

И перенесем наш hive директорию рядом к Hadoop 

```
mv apache-hive-3.1.2-bin /usr/local/

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/v1sI8X/image.png)

  

Теперь нужно добавить недостающие переменные окружения, для этого в ~/.bashrc добавим

![](https://teamdumpprod.blob.core.windows.net/images/medium/vZGmgo/image.png)

  

Теперь можно запустить инициализацию схемы данных внутри hive

С помощью команды 

```
schematool -dbType derby --initSchema

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/9xB3MA/image.png)

  

Важный момент, тут может быть другая база данных (Mysql/postgres) для хранения мета информации, но для этого, необходимо будет установить данную бд на хост.

Использование derby позволяет нам не устанавливать дополнительно субд и использовать локальную файловую систему. 

Теперь можно запускать hiveserver2 когда dfs и yarn уже запущенны

![](https://teamdumpprod.blob.core.windows.net/images/medium/asR2Kb/image.png)

  

И после этого, можно запускать утилиту hive

![](https://teamdumpprod.blob.core.windows.net/images/medium/us3DGT/image.png)

  

Проверяем что version работает, а также что создаются таблички

Повторяем get started 
----------------------

![](https://teamdumpprod.blob.core.windows.net/images/medium/DGAdr9/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/30HuLh/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/gvRgDY/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/s5vogD/image.png)

  

На этом со стартедом закончено, переходим к нашим данным

Нарезаем данные
---------------

Посмотрим сверху и снизу на данные

![](https://teamdumpprod.blob.core.windows.net/images/medium/4GSfsn/image.png)

  

Отрежем кусочки по 100 1m 10m

![](https://teamdumpprod.blob.core.windows.net/images/medium/RHMloi/image.png)

  

Получим вот такую картину

![](https://teamdumpprod.blob.core.windows.net/images/medium/410tSL/image.png)

  

Начнем загружать данные
-----------------------

Для 100к

![](https://teamdumpprod.blob.core.windows.net/images/medium/54UWcl/image.png)

  

Для 1m

![](https://teamdumpprod.blob.core.windows.net/images/medium/CO64xm/image.png)

  

Для 10m

![](https://teamdumpprod.blob.core.windows.net/images/medium/FcwUQR/image.png)

  

Подготовка к финальному заданию
-------------------------------

Создадим таблицу куда будут загружены файлы

```sql
CREATE TABLE price (
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

```

Загрузим данные.
----------------

```
LOAD DATA LOCAL INPATH '/opt/pp-complete.csv' OVERWRITE INTO TABLE price;

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/FgNKx6/image.png)

  

Посчитаем Count загруженных строк
---------------------------------

```
SELECT count(*) FROM price;

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/b82lc5/image.png)

  

На моем кластере это заняло 5 минут! 

Но мы получили заветную цифру 

```
26 541 204

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/2MwlC7/image.png)

  

Поглядим на структуру базы данных

И через просмотр

![](https://teamdumpprod.blob.core.windows.net/images/medium/wyix5P/image.png)

  

Средняя цена за год
-------------------

```sql
select date_format(datetime, 'yyyy'),town_city,cast(avg(price) as INT) from price 
    group by date_format(datetime, 'yyyy'),town_city;

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/kxWc0o/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/kf9Aip/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/5ZlgvT/image.png)

  

```
1995    67931
1996    71506
1997    78532
1998    85436
1999    96037
2000    107483
2001    118885
2002    137942
2003    155888
2004    178886
2005    189352
2006    203528
2007    219378
2008    217056
2009    213419
2010    236109
2011    232804
2012    238366
2013    256923
2014    279938
2015    297266
2016    313222
2017    346095
2018    350275
2019    351488
2020    370677
2021    383662

```

Средняя цена за год в Городе
----------------------------

Возьмем все года, имя города, и ценник средний ценник приведеный к INT, и сгруппируем по году и по городу, отсортируем по году.

![](https://teamdumpprod.blob.core.windows.net/images/medium/IjzjtF/image.png)

  

```sql
select date_format(datetime, 'yyyy'),town_city,cast(avg(price) as INT) from price 
    group by date_format(datetime, 'yyyy'),town_city 
    order by date_format(datetime, 'yyyy');

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/LGExAs/image.png)

  

```
1995    WELLINGBOROUGH  45870
1995    WEYBRIDGE       157201
1995    WHITSTABLE      61647
1995    WIGTON  52778
1995    AMLWCH  37322
1995    ASHBOURNE       86230
1995    ASHFORD 74976
1995    PRENTON 53984
1995    PICKERING       71060
1995    PENARTH 74589
1995    BACUP   32905
1995    BARNSLEY        43275
1995    BATTLE  91825
1995    BEAMINSTER      73240
1995    BETWS-Y-COED    37049
1995    BEWDLEY 72812
1995    BINGLEY 63478
1995    BOGNOR REGIS    66521
1995    BOREHAMWOOD     85596
1995    BOSTON  43451
1995    BOURNE  57090
1995    BRACKNELL       88567
1995    BUCKHURST HILL  106542
1995    CALLINGTON      58493
1995    CARNFORTH       73515
1995    CASTLE CARY     62556
1995    CHALFONT ST. GILES      202174
1995    COLEFORD        53111
1995    CROWBOROUGH     103618
1995    DEREHAM 53028
1995    EBBW VALE       33386
1995    EXETER  64316
1995    FORDINGBRIDGE   96897
1995    GRANGE-OVER-SANDS       70638
1995    GRAVESEND       65451
1995    HARLECH 48011
1995    HEANOR  37178
1995    HENGOED 39401
1995    HORNSEA 54340
1995    HORSHAM 96833

```

Начало файла можно наблюдать тут

Самые дорогие районы
--------------------

Я решил вычислять дорогие районы по средней цене, мне кажется это справдливее чем смотреть на локальные максимумы (тем более за 20 лет). Поэтому просто берем все районы, и средний ценник, агрегируем по району, и сортируем по среднему ценнику.

```sql
select district,cast(avg(price) as INT) from price 
    group by district 
    order by cast(avg(price) as INT) DESC;

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/BaXJ42/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/vOledB/image.png)

  

Приведу топ 20 дорогих районов тут.

```
CITY OF LONDON  1995179
KENSINGTON AND CHELSEA  1039831
CITY OF WESTMINSTER     1028504
CAMDEN  719088
HAMMERSMITH AND FULHAM  565830
BUCKINGHAMSHIRE 564427
ELMBRIDGE       497489
ISLINGTON       494469
RICHMOND UPON THAMES    471790
SOUTH BUCKS     457049
WANDSWORTH      438007
SOUTHWARK       413146
WEST NORTHAMPTONSHIRE   398455
TOWER HAMLETS   396889
CHILTERN        394007
WEST SUFFOLK    391442
WINDSOR AND MAIDENHEAD  386591
BOURNEMOUTH, CHRISTCHURCH AND POOLE     383726
HACKNEY 381256
BARNET  375548

```