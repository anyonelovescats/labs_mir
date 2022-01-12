# Ставим редис cli

sudo apt-get install redis-tools

# Поднимаем редис

docker-compose up -d

# Первое задание

Результат в файле 1.txt

Или вот тут

```
priv => WRONGTYPE Operation against a key holding the wrong kind of value
rasp:count => 2
users:msg => { name: Sergey, likes: [redis]} FTW !!111
urfu => WRONGTYPE Operation against a key holding the wrong kind of value
rasp:comments =>
  good
  nice
  not bad
mail =>
  rul
  https://mail.urfu.ru
rasp =>
  url
  http://urfu.ru/ru/students/study/shedule/
  count
  0
rtf =>
  url
  http://rtf.urfu.ru
scores => WRONGTYPE Operation against a key holding the wrong kind of value

```

## Второе Задание 1 миллион простых ключей

Я начал решать задачу влоб, и мой код выглядел вот так

```
function runOneMillion {
	echo "[ INFO ] Start script...."
	echo "[ INFO ] Write 1 million users"

	END=1000
	for ((z=1;z<=END;z++)); do
		redis-cli --raw set users:name${z} "value" > /dev/null
	done
}
```

На тысяче элементов это работало 2.7 секунды
На 10к уже 27 секунд, ставить 100к я даже не стал

Было принято решение копать глубже, и использовать batch upload потому что очевидно задание именно на него.

Была найдена [статья](https://redis.io/topics/mass-insert) и написана функция генератора тестовых данных

Показатели потребления оперативной памяти снимал исходя из

```
docker stats
```

Потребление пустого реддиса 47мб. Все что выше, считал чистым потреблением.

Удалял все записи перед каждым прогоном

### А теперь запуски

файл uploader_string.sh

| Count      | Time #1   | Time #2   | Time #3   | Ram    |
| ---------- | --------- | --------- | --------- | ------ |
| 1.000      | 0m0.007s  | 0m0.006s  | 0m0.007s  | 1 mb   |
| 10.000     | 0m0.025s  | 0m0.024s  | 0m0.023s  | 2 mb   |
| 100.000    | 0m0.204s  | 0m0.191s  | 0m0.203s  | 5 mb   |
| 1.000.000  | 0m2.006s  | 0m2.062s  | 0m2.321s  | 52 mb  |
| 10.000.000 | 0m20.729s | 0m21.563s | 0m27.274s | 930 mb |

## А теперь хеши

файл uploader_hash.sh

| Count      | Time #1   | Time #2   | Time #3   | Ram     |
| ---------- | --------- | --------- | --------- | ------- |
| 1.000      | 0m0.008s  | 0m0.008s  | 0m0.007s  | 1 mb    |
| 10.000     | 0m0.050s  | 0m0.052s  | 0m0.023s  | 2 mb    |
| 100.000    | 0m0.523s  | 0m0.468s  | 0m0.203s  | 12 mb   |
| 1.000.000  | 0m5.061s  | 0m5.231s  | 0m2.072s  | 150 mb  |
| 10.000.000 | 0m55.920s | 0m55.952s | 0m21.523s | 2.06 gb |

## Четвертое задание Картинки в Reddis

Учитывая количество строк, а именно так мы и будем хранить наши данные, (base64)

На предыдущих данных очень трудно основываться, там строчка очень маленькая, а base все же очень большой, попробуем...

файл uploader_image.sh

| Count   | Time #1  | Ram      |
| ------- | -------- | -------- |
| 1.000   | 0m0.609s | 28 mb    |
| 10.000  | 0m6.064s | 280 mb   |
| 100.000 | 1m1.262s | 2.78 gb  |
| 500.000 | 5m4.896s | 13.89 gb |

1 миллион в 16 гигов уже не влезет, да и генерироваться будет целую вечность
