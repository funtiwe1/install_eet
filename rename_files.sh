#!/bin/bash

# Укажи каталог, где лежат файлы
DIR="./"

# Проверяем, существует ли каталог
if [ ! -d "$DIR" ]; then
    echo "Каталог $DIR не найден."
    exit 1
fi

# Перебираем все файлы в каталоге
for file in "$DIR"/*; do
    # Пропускаем, если это не файл (например, подкаталог)
    if [ -f "$file" ]; then
        # Получаем имя файла без пути
        filename=$(basename "$file")
        # Получаем путь к каталогу
        dirname=$(dirname "$file")
        # Переименовываем, добавляя префикс
        mv "$file" "$dirname/funtik_$filename"
        echo "Переименован: $filename -> funtik_$filename"
    fi
done

echo "Готово."
