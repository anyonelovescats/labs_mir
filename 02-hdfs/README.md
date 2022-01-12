Автор Владимир Лила

Цель работы: знакомство с распределённой файловой системой HDFS.

Подготовим почву
================

Пойдем на облачный провайдер, и соберем себе немного инфраструктуры. 

Я выбрал hetzner потому что быстро, удобно, и дают белый ip

![](https://teamdumpprod.blob.core.windows.net/images/medium/Yb8kZx/image.png)

  

Создал 3 виртуальные машины на последней Ubuntu

На последней убунту уже установлены пакеты git и openssh а значит можно сразу начинать работать.

Создаем ssh ключи
-----------------

Я написал скрипт, который позволял мне как можно скорее дебагаться, при выполнении лабы. 

Поскольку мои машины создавались в облаке, я всегда стартавал с набором существующих ssh ключей внесенных в разрешенные для логина. 

Поэтому первым делом, на каждой машине создадим свой ssh ключ, а дальше с каждой машины перейдем на каждую, чтобы добавить машину в надежные, и у нас при коннекте больше бы не справшивало на это разрешение (это нужно для связанности хадупа)

  

Проще всего это сделать вот таким скриптом

```bash
#!/bin/bash

# 0. Loading Variables
source conf/config.sh

# 1. Installing & Configuring SSH
echo $HADOOP_USER_PASSWORD | sudo -S apt install openssh-server openssh-client -y

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'cat conf/hosts >> /etc/hosts'

ssh-keygen -t rsa -f ~/.ssh/id_rsa # generate ssh key for the node
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

```

Мы подгружаем переменные из файлика (см гитхаб) а потом на всякий случай проверяем что у нас стоит ssh-server + ssh-client 

Генерируем ssh ключ на 11 строке

И добавляем сами себя в доверенные. Теперь мы можем подключаться сами к себе, попробуем

![](https://teamdumpprod.blob.core.windows.net/images/medium/nvFOrd/image.png)

  

Все работает. 

Теперь выполним этот скрипт на каждой из машин

Позже возьмем в текстовый файл все 3 публичные части ssh ключа, и по очереди запишем их в файл ~/.ssh/

![](https://teamdumpprod.blob.core.windows.net/images/medium/aqzP3d/image.png)

  

Данный файл копируем на все 3 машины.

Рутина
------

А дальше следует самая нудная часть, с каждой машины залогиниться на каждую, но без этого ничего не получится, т.к хадуп не сможет обработать ssh вопрос о доверии к подключаемой ноде. (уверен что это можно полечить конфигой ssh но чет так лень ее искать было)

  

С логином на каждую новую машину, у нас будет добавляться по одной записи в файл ~/.ssh/know\_hosts

Очень важное замечание
======================

На выяснение этой детали, у меня ушло 3 часа времени. Поэтому стоит подчеркнуть. На убунте, очень вредный файл /etc/hosts

А все дело в том, что он вписывает hostname текущей машины, на адрес 127.0.1.1 

А это означает, что все что будет стартовать на интерфейсе именованном хостнеймом, будет стартовать на **127.0.1.1** я прошу заметить не на 127.0.0.1 что прямо таки удивило.

Поэтому, для корректной работы мастера, и его старте на белом ip а не на странном локальном адресе, необходимо **УДАЛИТЬ** эту запись из /etc/hosts (на всех нодах) иначе map-reduce задачи не смогут назначить сами себе ноды (т.к будут ходить на себя через 127.0.1.1)

  

Для остального, в файл /etc/hosts поместим информацию о нодах нашего кластера

```
65.21.180.115 master
95.216.158.73 node1
95.216.158.7 node2

```

Выглядеть это может так

![](https://teamdumpprod.blob.core.windows.net/images/medium/fsrd8O/image.png)

удалите строчку с монтированием master она оверрайдит нижнюю строчку с белым ip

Установка кластера
==================

Начнем с установки мастера в кластере

Я написал [небольшой скрипец](https://github.com/WeslyG/databases-labs/blob/master/02-hdfs/install-hadoop.sh) который помогает мне быстро устанавливать кластер, посмотрим на него:

В первую очередь подставим java8
--------------------------------

```
sudo -S add-apt-repository ppa:openjdk-r/ppa
sudo -S apt update
sudo -S apt install openjdk-8-jdk -y
sudo -S apt install openjdk-8-jdk-headless -y

```

Скачаем и распакуем hadoop
--------------------------

```
echo ">>>> 3. Installing Hadoop... <<<<"

wget $HADOOP_ORIGIN
echo $HADOOP_USER_PASSWORD | sudo -S tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C $HADOOP_PARENT_DIR && rm -rf hadoop-${HADOOP_VERSION}.tar.gz

printf "<<<< 3. done. \n\n"

```

Сконфигурируем Hadoop
---------------------

```
echo ">>>> 4. Configuring Hadoop... <<<<"

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'mkdir /opt/hadoop'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'mkdir /opt/hadoop/namenode'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'mkdir /opt/hadoop/datanode'

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export HDFS_DATANODE_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export HDFS_SECONDARYNAMENODE_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export YARN_RESOURCEMANAGER_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export YARN_NODEMANAGER_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export HDFS_NAMENODE_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'

echo $HADOOP_USER_PASSWORD | sudo -S cp conf/hadoop/* $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/
echo $HADOOP_USER_PASSWORD | sudo -S chown hadoop $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}

printf "<<<< 4. done. \n\n"

```

Тут я не стал создавать юзера Hadoop которого ожидает система, а решил запустить все из под рута (просто для любопытства)

Дополнительные переменные
-------------------------

```
echo ">>>> 5. Updating .bashrc... <<<<"

## Add and export Java
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "JAVA_HOME=$JAVA_HOME" >> ~/.bashrc'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export JAVA_HOME" >> ~/.bashrc'
## Set PSDSH type to ssh
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'echo "PDSH_RCMD_TYPE=ssh" >> ~/.bashrc'
## set Hadoop home directory
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "HADOOP_HOME=$HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}" >> ~/.bashrc'
## Update and export PATH
echo $HADOOP_USER_PASSWORD | sudo -S bash -c "source conf/config.sh && echo PATH='$'PATH:'$'HADOOP_HOME/bin:'$'HADOOP_HOME/sbin >> ~/.bashrc"
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export PATH" >> ~/.bashrc'
## Load bash profile changes into current terminal session
source ~/.bashrc
printf "<<<< 5. done. \n\n"

```

Hadoop чувствителен к переменной окружения JAVA\_HOME и к некоторым другим. А также добавим все скрипты Hadoop в path, чтобы они были доступны из любого места в консольке. 

На этом конфигурация заканчивается, скрипт отрабатывает шустро, за одну минуту устанавливая сервер. 

Не забудем перезагрузить bashrc для применения всех переменных окружения из консоли

```
source ~/.bashrc

```

Рассмотрим конфигурацию детальнее

Конфигурация
============

Все конфиги лежат в /usr/local/hadoop-3.1.1/etc

Самая основная конфигурация называется core-site.xml

```
<configuration>
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://master:9000</value>
	</property>
</configuration>

```

В ней мы указываем на каком интерфейсе стартует мастер, и если не убрать 127.0.1.1 то он стартанет именно там, и другие ноды к нему не подключатся, если же в /etc/hosts Будет белый Ip то все стартанет на нем. 

Следующая важная часть
----------------------

```
<configuration>
    <property>
      <name>dfs.replication</name>
      <value>1</value>
    </property>

    <property>
      <name>dfs.namenode.name.dir</name>
      <value>/opt/hadoop/namenode</value>
    </property>
    <property>
      <name>dfs.datanode.data.dir</name>
      <value>/opt/hadoop/datanode</value>
    </property>
</configuration>

```

hdfs-site.xml настройка расположения данных из hdfs (не забываем создать эти папки внутри скрипта по инсталляции кластера)

Также в конфиге есть самая важная опция — репликейшен фактор, т.е сколько раз хранить информацию. Установим ее в значение = 1 т.к нода у нас пока одна.

Файл workers
------------

все в этой же папке etc положим файл workers с очень простой записью

```
master

```

Позже он будет нам служить инвентаризацией всех наших нод.

Также сконфигурируем yarn — это фреймворк для map reduce. 

```
<configuration>
        <property>
            <name>yarn.acl.enable</name>
            <value>0</value>
    </property>

    <property>
            <name>yarn.resourcemanager.hostname</name>
            <value>master</value>
    </property>

    <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
    </property>
        <property>
                <name>yarn.resourcemanager.scheduler.address</name>
                <value>master:8030</value>
        </property>
        <property>
                <name>yarn.resourcemanager.address</name>
                <value>master:8032</value>
        </property>
        <property>
                <name>yarn.resourcemanager.webapp.address</name>
                <value>master:8088</value>
        </property>
        <property>
                <name>yarn.resourcemanager.resource-tracker.address</name>
                <value>master:8031</value>
        </property>
        <property>
                <name>yarn.resourcemanager.admin.address</name>
                <value>master:8033</value>
        </property>
</configuration>

```

yarn-site.xml — тут самое важное это порты, на которых будут висеть веб интерфейсы для мониторинга.

И последний файл конфигурации — mapred-site.xml

```
<configuration>
    <property>
            <name>mapreduce.framework.name</name>
            <value>yarn</value>
    </property>
    <property>
            <name>yarn.app.mapreduce.am.env</name>
            <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
    </property>
    <property>
            <name>mapreduce.map.env</name>
            <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
    </property>
    <property>
            <name>mapreduce.reduce.env</name>
            <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
    </property>
    <property>
            <name>yarn.app.mapreduce.am.resource.mb</name>
            <value>2048</value>
    </property>

    <property>
            <name>mapreduce.map.memory.mb</name>
            <value>1024</value>
    </property>

    <property>
            <name>mapreduce.reduce.memory.mb</name>
            <value>1024</value>
    </property>
</configuration>

```

Тут мы как раз включаем использование Yarn

Выводы
------

Вся конфигурация копируется на этапе установки кластера, и делать это дополнительно не нужно, я лишь пояснил важные моменты из конфигурации. 

Запустим же наш кластер.

Запуск кластера
===============

Перед запуском
--------------

Теперь нам нужно отформатировать нашу файловую систему, выполняется это командой

```
hdfs namenode –format

```

Поехали
-------

Мы заранее добавили все исполняемые файлы hadoop в PATH поэтому можем просто вызвать находясь в любой папке

```
start-dfs.sh

```

после запуска скрипта, мы можем посмотреть, что у нас есть

Для этого подойдут команды jps (java process manager)

Или простой netstat -nltp отображающий текущие открытые порты.

![](https://teamdumpprod.blob.core.windows.net/images/medium/dmhhhG/image.png)

  

Тут видно, что основной порт 9000 — у нас запущен на белом ip адресе, и значит другие ноды к нему смогут присоединиться. 

Мы можем посмотреть файлы логов в том же каталоге Hadoop 

![](https://teamdumpprod.blob.core.windows.net/images/medium/cpEUDo/image.png)

  

Если что то идет не так, то в логах об этом будут сообщения.

Теперь же запустим Yarn, это запустит еще процессы, resourcemanager nodemanager

![](https://teamdumpprod.blob.core.windows.net/images/medium/Qbl4y5/image.png)

  

И картина уже будет вот такая

Если нам понадобиться остановить систему, мы можем воспользоваться скриптом 

stop-all.sh

![](https://teamdumpprod.blob.core.windows.net/images/medium/OouO7g/image.png)

  

Он остановит все процессы в кластере. 

Проверяем 
----------

Проверим нашу файловую систему — А точнее количество узлов в кластере

```
hdfs dfsadmin -report

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/3SzM2e/image.png)

  

Видим что у нас одна нода в кластере

Загрузим в нее данные
---------------------

Для этого нужно создать директорию, и выбрать локальные файлы

![](https://teamdumpprod.blob.core.windows.net/images/medium/9kUQbh/image.png)

  

Вот так выглядит работающая hdfs на одном узле. 

Подключаем еще 2 ноды
=====================

Остановим все на мастере скриптом stop-all.sh

Запустим скрипт установки Hadoop на node1 и node2 машинах. 

Не забудем добавить идентичные /etc/hosts записи на все машины, чтобы видеть друг друга по коротким именам, с правильными Ip адресами.

Меняем файл workers на мастере

![](https://teamdumpprod.blob.core.windows.net/images/medium/Xx4l6J/image.png)

  

В файле hdfs-site.xml поставим репликацию = 3 (на всех серверах)

![](https://teamdumpprod.blob.core.windows.net/images/medium/0eFIz1/image.png)

  

Снова отформатируем файловую систему (т.к к нам добавились новые ноды) 

```
hdfs namenode -format

```

Теперь запускаем start-dfs.sh на мастер ноде

И смотрим что выдаст jps на воркерах

![](https://teamdumpprod.blob.core.windows.net/images/medium/UDmE0q/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/0JML9u/image.png)

  

На воркерах начали работать DataNode управляемые с мастер сервера. 

Запускаем yarn
--------------

```
start-yarn.sh

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/BzVNj1/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/9FUBW0/image.png)

  

и видим, что кроме dataNode запустился также NodeManager

Проверяем количество дата нод
-----------------------------

```
hdfs dfsadmin -report

```

![](https://teamdumpprod.blob.core.windows.net/images/medium/KPjPFp/image.png)

  

И теперь в нашем кластере 3 ноды

![](https://teamdumpprod.blob.core.windows.net/images/medium/58GWhA/image.png)

  

[http://65.21.180.115:9870/dfshealth.html#tab-datanode](http://65.21.180.115:9870/dfshealth.html#tab-datanode)

Можно также посмотреть через веб на наши ноды, и их нагрузку, и свободное место. 

Финал
=====

В лабораторной работе меня просят положить туда в папку файл с именем моей подкоманды. 

Я делал это один, поэтому положу файл с собой

![](https://teamdumpprod.blob.core.windows.net/images/medium/wms67G/image.png)

  

Код скрипта установки и настройки в проекте — [https://github.com/WeslyG/databases-labs/tree/master/02-hdfs](https://github.com/WeslyG/databases-labs/tree/master/02-hdfs)