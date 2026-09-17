# Hito 1 - Concurrencia en CPU



## Objetivo



El objetivo de este hito es implementar y analizar una soluciÃ³n concurrente para un problema de paralelismo de datos en CPU.



El problema que elegimos consiste en calcular la suma de un vector grande de nÃºmeros de tipo `float`, comparando una implementaciÃ³n secuencial con otra implementaciÃ³n que utiliza varios hilos.



La implementaciÃ³n fue realizada en Python utilizando el mÃ³dulo `threading`.



---



## Problema



Se genera un vector de `N = 16.777.216` elementos, donde todos los valores son `1.0`.



La operaciÃ³n que se realiza es:



$$

S = \\sum\_{i=0}^{N-1} x\_i

$$



Como todos los elementos tienen valor `1.0`, el resultado esperado es:



$$

S = N = 16.777.216

$$



Para resolver el problema se hicieron dos versiones:



* `secuencial.py`: realiza la suma utilizando un solo flujo de ejecuciÃ³n.

* `paralelo.py`: divide el vector en bloques y reparte el trabajo entre varios hilos.



---



## ImplementaciÃ³n secuencial



En la versiÃ³n secuencial se recorren todos los elementos del vector uno por uno y se va acumulando el resultado en una variable.



Para medir el tiempo utilizado se utiliza `time.perf\_counter()`.



---



\## ImplementaciÃ³n concurrente



En la versiÃ³n concurrente se utilizan:



* `threading.Thread` para crear los hilos.

* `threading.Lock` como mecanismo de sincronizaciÃ³n.

* Bloques de `100.000` elementos.

* Una suma local para cada hilo.

* `join()` para esperar a que todos los hilos terminen.



El `Lock` se utiliza para controlar el acceso a la variable que indica cuÃ¡l es el prÃ³ximo bloque que tiene que procesarse. De esta manera, dos hilos no pueden tomar el mismo bloque al mismo tiempo.



La suma de los elementos se realiza fuera del `Lock`, para evitar mantener bloqueado el recurso compartido mientras se hace todo el procesamiento.



---



\## MetodologÃ­a de mediciÃ³n



Para realizar las pruebas se utilizÃ³ el archivo `benchmark.py`.



Las pruebas se realizaron de la siguiente manera:



* TamaÃ±o del vector: `16.777.216` elementos.

* Cantidad de repeticiones: `5`.

* Se utiliza la mediana de las cinco mediciones.

* Se probaron `1`, `2`, `4`, `8` y `16` hilos.



El speedup se calcula mediante:



$$

S(T) = \\frac{T\_{seq}}{T(T)}

$$



donde:



* \\(T\_{seq}\\) es el tiempo de la versiÃ³n secuencial.

* \\(T(T)\\) es el tiempo de la versiÃ³n concurrente utilizando `T` hilos.



De esta forma podemos comparar cuÃ¡nto tarda la versiÃ³n concurrente con respecto a la versiÃ³n secuencial.



---



## Hardware



Para realizar las pruebas se detectaron:



* \*\*Procesadores lÃ³gicos disponibles:\*\* 16

* \*\*Sistema operativo:\*\* Windows

* \*\*Lenguaje:\*\* Python 3.11

* \*\*MÃ³dulo utilizado para la concurrencia:\*\* `threading`



---



## Resultados



El tiempo obtenido para la versiÃ³n secuencial fue:



*\*285.160 ms\*\*



Los resultados obtenidos con la versiÃ³n concurrente fueron:



| Hilos | Tiempo mediano (ms) | Speedup real | Speedup Amdahl |

| ----: | ------------------: | -----------: | -------------: |

|     1 |             415.419 |        0.686 |          1.000 |

|     2 |             428.492 |        0.665 |          1.905 |

|     4 |             420.891 |        0.678 |          3.478 |

|     8 |             428.318 |        0.666 |          5.926 |

|    16 |             422.009 |        0.676 |          9.143 |



En todas las pruebas el resultado de la suma fue:



`16.777.216`



Esto coincide con el resultado esperado, por lo que las dos implementaciones realizan correctamente la suma del vector.



---



## Ley de Amdahl



Para comparar nuestros resultados con un resultado teÃ³rico, utilizamos la Ley de Amdahl:



$$

S(T) = \\frac{1}{s + \\frac{1-s}{T}}

$$



Para este cÃ¡lculo utilizamos una fracciÃ³n secuencial de:



$$

s = 0.05

$$



Este valor es una suposiciÃ³n utilizada como referencia para hacer el cÃ¡lculo teÃ³rico. No fue obtenido a partir de una mediciÃ³n del programa.



Los resultados teÃ³ricos obtenidos fueron:



| Hilos | Speedup Amdahl |

| ----: | -------------: |

|     1 |          1.000 |

|     2 |          1.905 |

|     4 |          3.478 |

|     8 |          5.926 |

|    16 |          9.143 |



---



## AnÃ¡lisis de los resultados



Al analizar los resultados podemos ver que aumentar la cantidad de hilos no hizo que el programa fuera mÃ¡s rÃ¡pido que la versiÃ³n secuencial.



La versiÃ³n secuencial tuvo un tiempo mediano de `285.160 ms`, mientras que las versiones con hilos tuvieron tiempos superiores a `400 ms`.



El speedup real se mantuvo aproximadamente entre `0.66` y `0.69`, por lo que no se observa una mejora al aumentar la cantidad de hilos.



Una de las principales razones de este resultado es que estamos utilizando `threading` de Python para una tarea que requiere bastante procesamiento de CPU. Python utiliza el \*\*Global Interpreter Lock (GIL)\*\*, que limita la ejecuciÃ³n simultÃ¡nea de cÃ³digo Python por varios hilos dentro de un mismo proceso.



AdemÃ¡s, la versiÃ³n concurrente tiene algunos costos adicionales. Por ejemplo:



* creaciÃ³n y manejo de los hilos;

* uso del `Lock`;

* asignaciÃ³n de los bloques;

* coordinaciÃ³n entre los hilos;

* espera mediante `join()`;

* acceso a memoria.



Todos estos costos hacen que, en este caso, utilizar varios hilos termine siendo mÃ¡s lento que hacer la suma de forma secuencial.



TambiÃ©n podemos observar que utilizar mÃ¡s hilos no significa necesariamente obtener un mejor tiempo. Por ejemplo, entre 8 y 16 hilos prÃ¡cticamente no hubo una mejora en el tiempo obtenido.



Los resultados reales tambiÃ©n son bastante diferentes de los valores obtenidos con la Ley de Amdahl. Esto se debe a que el cÃ¡lculo de Amdahl representa un modelo teÃ³rico y supone que la parte paralelizable del programa puede ejecutarse realmente en paralelo. En nuestro caso existen las limitaciones propias de Python y de `threading`.



Por lo tanto, los resultados muestran que no alcanza solamente con aumentar la cantidad de hilos o tener mÃ¡s procesadores lÃ³gicos disponibles. TambiÃ©n hay que tener en cuenta cÃ³mo se ejecuta el programa y los costos que agrega la concurrencia.



---



## Conclusiones



En este hito implementamos una versiÃ³n secuencial y una versiÃ³n concurrente para realizar la suma de un vector grande.



La versiÃ³n concurrente utiliza `Thread` y `Lock`, cumpliendo con el requisito de utilizar una primitiva de sincronizaciÃ³n.



Las pruebas realizadas muestran que, para este problema y utilizando `threading` en Python, la versiÃ³n concurrente no fue mÃ¡s rÃ¡pida que la versiÃ³n secuencial.



TambiÃ©n pudimos comparar los resultados reales con la Ley de Amdahl y observar que existe una diferencia importante entre el resultado teÃ³rico y el comportamiento real del programa.



Con este experimento podemos ver que la cantidad de hilos no garantiza por sÃ­ sola una mejora de rendimiento. Hay que tener en cuenta factores como la sincronizaciÃ³n, el manejo de los hilos, el acceso a memoria y las caracterÃ­sticas del lenguaje utilizado.



