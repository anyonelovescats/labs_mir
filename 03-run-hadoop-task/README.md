Автор Владимир Лила

После второй лабы, у нас уже есть готовый hadoop кластер, настало время запустить на нем задачи.

Подготовка
----------

Веб интерфейс hadoop запускается на 8088

![](https://teamdumpprod.blob.core.windows.net/images/medium/Rtx6Io/image.png)

  

для упрощения общения с веб интерфейсом, на своем компьютере я также установил в файл hosts ноды с их белыми ip адресами.

Тестируем задачи
----------------

Файл с examples лежит в папке share/hadoop/mapreduce 

![](https://teamdumpprod.blob.core.windows.net/images/medium/a0a8i3/image.png)

  

Повторим задачу из презентации с подсчетом числа pi до 100

![](https://teamdumpprod.blob.core.windows.net/images/medium/AlXpcf/image.png)

  

Запустили

![](https://teamdumpprod.blob.core.windows.net/images/medium/3RNy48/image.png)

  

Получили ответ

Можем сходить в веб интерфейс и посмотреть там на нашу задачу

![](https://teamdumpprod.blob.core.windows.net/images/medium/C0cN9d/image.png)

  

Во время выполнения работы, можно смотреть за ходом выполнения задач

![](https://teamdumpprod.blob.core.windows.net/images/medium/BpRred/image.png)

  

внутри можно проваливаться и смотреть на логи каждой конкретной таски. 

Выяснять, почему например задача ушла в статус Failed 

Запустим ту же задачу на 1м
---------------------------

![](https://teamdumpprod.blob.core.windows.net/images/medium/26VsbI/image.png)

  

Получим вот такой результат

![](https://teamdumpprod.blob.core.windows.net/images/medium/2AA6vF/image.png)

  

WordCount
---------

Я создал файл pushkin.txt файл, и положил в него Евгения Онегина. 

Создадим папку, и загрузим этот файл в систему в /input

![](https://teamdumpprod.blob.core.windows.net/images/medium/JGwzVY/image.png)

  

Дальше повторяем гайд по компиляции исходника java с джобой, в jar формат

Создаем файл WordCount.java

```java
import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCount {

  public static class TokenizerMapper
       extends Mapper<Object, Text, Text, IntWritable>{

    private final static IntWritable one = new IntWritable(1);
    private Text word = new Text();

    public void map(Object key, Text value, Context context
                    ) throws IOException, InterruptedException {
      StringTokenizer itr = new StringTokenizer(value.toString());
      while (itr.hasMoreTokens()) {
        word.set(itr.nextToken());
        context.write(word, one);
      }
    }
  }

  public static class IntSumReducer
       extends Reducer<Text,IntWritable,Text,IntWritable> {
    private IntWritable result = new IntWritable();

    public void reduce(Text key, Iterable<IntWritable> values,
                       Context context
                       ) throws IOException, InterruptedException {
      int sum = 0;
      for (IntWritable val : values) {
        sum += val.get();
      }
      result.set(sum);
      context.write(key, result);
    }
  }

  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    Job job = Job.getInstance(conf, "word count");
    job.setJarByClass(WordCount.class);
    job.setMapperClass(TokenizerMapper.class);
    job.setCombinerClass(IntSumReducer.class);
    job.setReducerClass(IntSumReducer.class);
    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(IntWritable.class);
    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));
    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}

```

Далее проверяем что у нас в PATH есть все необходимые утилиты

![](https://teamdumpprod.blob.core.windows.net/images/medium/aXCBai/image.png)

  

Вот так выглядят мои переменные окружения в PATH

незабываем каждый раз при изменении .bashrc перезагружать изменения в текущей консольке

```
source ~/.bashrc

```

Теперь можно скомпилировать наш файл в JAR

```
hadoop com.sun.tools.javac.Main WordCount.java
jar cf wc.jar WordCount*.class

```

Первая команда билдит классы, вторая из них билдит готовый jar (читай архив)

Наша задача готова к исполнению. 

Запускаем
---------

Команда для запуска принимает на вход jar файл, и папки с Input/output

```
hadoop jar wc.jar WordCount /user/joe/wordcount/input /user/joe/wordcount/output

```

Важно, если папка с output существует, то Hadoop у меня ругался, пришлось ее удалить

```
hdfs dfs -rm -r /user/hadoop/wordcount/output

```

Запускаем команду обработки. (можно наблюдать за ней в вебе кстати)

![](https://teamdumpprod.blob.core.windows.net/images/medium/IyGiHz/image.png)

  

![](https://teamdumpprod.blob.core.windows.net/images/medium/GThPwu/image.png)

  

И вот наш результат, джоба отработала хорошо. 

Посмотрим что у нас внутри папки Output

![](https://teamdumpprod.blob.core.windows.net/images/medium/02b1HT/image.png)

  

Немного повыпендриваюсь знаниями баша, отсортируем по второму столбцу, и выведем топ 10 совпадений. И разумеется это же не полнотекстовый поиск, тут одни местоимения и предлоги. 

Но результат показательный. 

![](https://teamdumpprod.blob.core.windows.net/images/medium/CxbRIh/image.png)

  

Все работает ожидаемо. Даже с Русским языком