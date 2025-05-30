# План работы над WeLabelDataRecorder v1.2.0

## 1. Улучшение анализатора отношений между UI элементами

### 1.1. Расширение возможностей определения отношений

- [ ] Усовершенствовать алгоритм построения дерева иерархии UI элементов
  - Добавить обходы "снизу вверх" и "сверху вниз" для более полной картины
  - Улучшить обработку вложенных контейнеров
  - Учитывать z-индекс при построении визуальной иерархии

- [ ] Добавить обнаружение новых типов отношений
  - Добавить группировку однотипных элементов (списки, радиокнопки)
  - Определение элементов навигации
  - Отношения "до/после" в навигационной последовательности

- [ ] Улучшить алгоритм анализа пространственных отношений
  - Учитывать относительное положение (сверху, снизу, слева, справа)
  - Добавить метрики расстояния между элементами
  - Определение выравнивания (по вертикали/горизонтали)

### 1.2. Создание визуализации элементов и отношений

- [ ] Создать механизм экспорта визуальной иерархии в формат графа
  - Использовать DOT-формат для генерации графов через Graphviz
  - Экспортировать иерархию в формате JSON для использования d3.js или других библиотек визуализации

- [ ] Реализовать отрисовку элементов и их связей в приложении
  - Создать InspectorView для просмотра выбранного элемента и связанных с ним
  - Добавить возможность фильтрации отображаемых типов отношений
  - Добавить визуальное представление типов связей через цвета и формы

### 1.3. Интеграция анализатора с основным приложением

- [ ] Обновить `RecordingManager` для использования анализатора отношений
  - Сохранять информацию об отношениях автоматически при записи взаимодействий
  - Создать кэширование для повышения производительности

- [ ] Добавить UI для просмотра и редактирования отношений
  - Создать панель для просмотра иерархии обнаруженных элементов
  - Добавить возможность ручной корректировки автоматически определенных отношений
  - Реализовать ручное добавление отношений между элементами

## 2. Улучшение экспорта в формат COCO

### 2.1. Усовершенствование категоризации UI элементов

- [ ] Расширить систему категорий UI элементов
  - Добавить более детальную типизацию элементов (разделить кнопки на типы: обычные, переключатели, т.д.)
  - Добавить категории для составных элементов (формы, панели инструментов)
  - Создать иерархию категорий для улучшения совместимости с моделями компьютерного зрения

- [ ] Реализовать интеллектуальное определение типа UI элемента
  - Использовать не только роль элемента, но и его визуальные характеристики
  - Добавить эвристики для определения функционального назначения элемента
  - Учитывать контекст элемента при определении его категории

### 2.2. Улучшение качества аннотаций

- [ ] Улучшить точность ограничивающих рамок (bounding box)
  - Определять видимую часть элемента, а не только его фрейм
  - Учитывать прозрачность и перекрытия элементов
  - Добавить поддержку сегментации для элементов со сложной формой

- [ ] Добавить атрибуты состояния элемента
  - Аннотировать состояние (активно, неактивно, выбрано)
  - Добавить информацию о визуальном стиле элемента
  - Аннотировать взаимодействия пользователя с элементами

### 2.3. Тестирование и валидация

- [ ] Создать инструменты для валидации экспортированных данных
  - Разработать визуализатор для просмотра аннотаций
  - Реализовать проверку на соответствие формату COCO
  - Добавить статистику по экспортированным данным

- [ ] Тестирование на различных типах приложений
  - Проверить работу на стандартных приложениях macOS
  - Протестировать на веб-приложениях
  - Проверить совместимость с инструментами для обучения моделей компьютерного зрения

## 3. Общие задачи

### 3.1. Оптимизация производительности

- [ ] Оптимизировать процесс записи скриншотов
  - Использовать эффективное сжатие изображений
  - Реализовать захват изменившихся областей экрана вместо полных скриншотов
  - Оптимизировать использование памяти при работе с изображениями

- [ ] Улучшить работу с Accessibility API
  - Реализовать кэширование данных Accessibility
  - Оптимизировать запросы к API для снижения нагрузки на систему
  - Создать очередь запросов с приоритетами

### 3.2. Улучшение пользовательского интерфейса

- [ ] Добавить панель управления сессиями записи
  - Создать список сохраненных сессий с возможностью фильтрации
  - Добавить предпросмотр сессий с thumbnails скриншотов
  - Реализовать функционал объединения и разделения сессий

- [ ] Добавить настройки процесса записи
  - Добавить возможность выбора области экрана для записи
  - Реализовать фильтрацию по типам записываемых взаимодействий
  - Добавить настройки качества скриншотов и частоты их создания

## График реализации

1. **Июнь 2025**: Улучшение анализатора отношений между UI элементами
2. **Июль 2025**: Реализация визуализации отношений и интеграция с основным приложением
3. **Август 2025**: Улучшение экспорта в формат COCO и тестирование
4. **Сентябрь 2025**: Оптимизация производительности и пользовательского интерфейса
5. **Октябрь 2025**: Тестирование и стабилизация, подготовка к релизу v1.2.0