\Large УДК 004.4'4, 004.272

\begin{center}
\Large \textbf{БИБЛИОТЕКА LLVM2PY ДЛЯ АНАЛИЗА ПРОМЕЖУТОЧНОГО ПРЕДСТАВЛЕНИЯ LLVM И ЕЁ ПРИМЕНЕНИЕ В ОЦЕНКЕ СТЕПЕНИ РАСПАРАЛЛЕЛИВАНИЯ ЛИНЕЙНЫХ УЧАСТКОВ КОДА}
\end{center}

\vspace{0.6cm}

\begin{center}
\large \textbf{Павлов К.С., Советов П.Н.}
\end{center}

\normalsize

_МИРЭА — Российский технологический университет, 119454, г. Москва, пр-т Вернадского, 78, e-mail: pavlov.k.s@edu.mirea.ru, sovetov@mirea.ru_

---

**В статье рассматриваются вопросы проектирования и использования разработанной библиотеки llvm2py, предназначенной для быстрого создания на языке Python статических анализаторов программ для промежуточного представления LLVM. Обосновывается необходимость создания рассматриваемой библиотеки, а также выбор конкретных архитектурных решений. С использованием библиотеки llvm2py разработан инструмент статического анализа степени распараллеливания линейных участков кода. Данный инструмент позволяет для конкретного линейного участка получить коэффициент его ускорения с использованием абстрактного параллельного LLVM-процессора, а также узнать минимальное число параллельно работающих функциональных узлов этого процессора, обеспечивающих максимальное значение коэффициента ускорения. Для разработанного инструмента получены экспериментальные оценки на примере десяти известных алгоритмов, реализованных на языке C. Приведена статистика распараллеливания для наиболее ускоряемого линейного участка кода каждой из программ за счёт параллелизма уровня команд. На примере тестирования алгоритма JPEG, в частности, было достигнуто ускорение выполнения линейного участка кода в 5,4 раза при минимальном использовании количества функциональных узлов процессора, равном 6 узлам.**

---

Ключевые слова: LLVM, LLVM IR, Python, llvm2py, статический анализ, распараллеливание, ярусно-параллельная форма, параллелизм уровня команд, линейный участок, граф зависимостей

\begin{center}
\Large \textbf{THE LLVM2PY LIBRARY FOR ANALYZING LLVM INTERMEDIATE REPRESENTATION AND ITS APPLICATION IN ESTIMATING PARALLELIZABILITY OF BASIC BLOCKS}
\end{center}

\vspace{0.6cm}

\begin{center}
\large \textbf{Pavlov K.S., Sovietov P.N.}
\end{center}

_MIREA - Russian Technological University, 119454, Russia, Moscow, Vernadsky Avenue, 78, e-mail: pavlov.k.s@edu.mirea.ru, sovetov@mirea.ru_

\setlength{\parskip}{0pt}

---

**The article addresses the design and utilization of the developed library, llvm2py, which is intended for the rapid
construction of static program analyzers written in Python for LLVM intermediate representation. The necessity
of the presented library is demonstrated, as are the specific architectural solutions chosen. The LLVM2Py library
has been used to develop a tool for the static analysis of parallelizability of basic blocks. The tool enables the
calculation of the acceleration coefficient for a specific basic block through the use of an abstract parallel LLVM processor. Moreover, it allows for the calculation of the minimum number of parallel functional units of the processor that provide the maximum value of the acceleration coefficient. The efficacy of the developed tool is evaluated through experimentation with ten exemplar algorithms, each implemented in the C language. The following algorithms were used for the purposes of testing: Blowfish, ZIP, JPEG, AES, Base64, ChaCha20, SHA1, CSV, SHA256, and MD5.**

**The parallelization statistics are presented for the most accelerated basic block of each program due to instructionlevel parallelism. To illustrate, the JPEG algorithm achieved a 5.4-fold acceleration of the basic block execution
with the minimum utilization of the number of functional units, which was equal to 6 units.
The developed tool, when used in conjunction with information from the profiler regarding the frequency of execution of linear sections, can assist in making informed decisions regarding the porting of code for execution to a
specialized architecture with instruction-level parallelism. The functionality of the llvm2py library is planned to
be further extended for code compilation tasks, including the creation of domain-specific compilers for specialized
processors.**

---

Keywords: LLVM, LLVM IR, Python, llvm2py, static analysis, parallelization, level-parallel form, instruction level parallelism, basic block, dependence graph

\setlength{\parindent}{15pt}
\setlength{\baselineskip}{1.5em}

**Введение**

\setlength{\baselineskip}{1.2em}
\setlength{\parskip}{0pt}

Существует потребность в разработке специализированных программных инструментов для статического
анализа и преобразований программного кода. Можно, в частности, выделить следующие задачи, решаемые с
использованием таких инструментов:

* Интеллектуальный анализ программ, в том числе анализ программ на уязвимости.
* Оценка степени распараллеливания программного кода.
* Программно-аппаратное разбиение для вычислительных систем, состоящих как из универсальных процессоров, так и множества специализированных аппаратных ускорителей.
* Разработка предметно-ориентированных компиляторов для спецпроцессоров.

Традиционно такие инструменты разрабатываются на языке C++ в рамках фреймворка LLVM с использованием промежуточного представления LLVM IR (Intermediate Representation). Использование языка LLVM IR для
представления входных программ позволяет задействовать внешние инструменты для синтаксического разбора
множества входных языков, включающее языки C и C++, а также получить оптимизированный вариант программы за счёт существующего оптимизирующего компилятора. Как следствие, использование представления
LLVM IR позволяет получить готовый набор программ для задач анализа и компиляции

Учитывая, что для узких классов задач целесообразно разрабатывать специализированные программные инструменты, возникает необходимость задействования средств быстрой разработки и прототипирования этих инструментов. В частности, использование языка Python может позволить упростить и ускорить процесс разработки
прототипов рассматриваемых инструментов. По результатам анализа существующих решений, подходящих
средств для работы с представлением LLVM IR на языке Python найдено не было, в связи с этим была разработана
библиотека llvm2py [@llvm2py], описываемая в этой статье.

Разработанная библиотека написана преимущественно на языке Python, а также имеет в своём составе модуль
на C++. Разбор синтаксиса языка LLVM IR производится синтаксическим анализатором фреймворка LLVM, а
работа с представлением LLVM IR осуществляется через программный интерфейс модуля библиотеки llvm2py
на Python, реализующего подмножество классов представления LLVM IR. Связывание модулей на Python и С++
осуществлено с помощью сторонней библиотеки pybind11 [@pybind11].

С использованием разработанной библиотеки создан инструмент статического анализа степени распараллеливания линейных участков кода, позволяющий выявить степень параллелизма уровня команд для входной программы. Анализ осуществляется с использованием графа зависимостей команд (ГЗ) и ярусно-параллельной
формы (ЯПФ), позволяющей выявить минимальное число шагов, для выполнения линейного участка на параллельном абстрактном LLVM-процессоре. С помощью минимизации ширины ярусно-параллельной формы формируются сведения о минимальном количестве параллельно работающих функциональных узлов, требуемых для
выполнения линейного участка параллельным LLVM-процессором.

Практическое использование разработанного инструмента анализа степени распараллеливания линейных
участков рассмотрено на примере ряда известных алгоритмов, реализованных на языке C. По результатам анализа выявлены наиболее перспективные линейные участки, имеющие наибольший коэффициент ускорения выполнения на абстрактном параллельном LLVM-процессоре по сравнению с последовательным LLVMпроцессором. В частности, для тестовой программы JPEG получено ускорение в 5,4 раза.

Для каждого участка была произведена минимизация ширины ЯПФ, по результатам которой достигнуто существенное сокращение числа функциональных узлов параллельного LLVM-процессора. В случае линейного
участка алгоритма AES сокращение достигает 17-и узлов. Полученные результаты могут служить основанием
для переноса выполнения программного кода на специализированную архитектуру с параллелизмом уровня команд.