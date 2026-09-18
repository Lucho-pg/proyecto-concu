\# Hito 2 — Kernels CUDA optimizados



\## Objetivo



En este hito se realiza el port del problema de suma de un vector del Hito 1, originalmente resuelto sobre CPU, a una implementación utilizando CUDA sobre GPU.



Se implementan y comparan dos versiones:



\* \*\*Kernel ingenuo:\*\* utiliza `atomicAdd` sobre un único acumulador global.

\* \*\*Kernel optimizado:\*\* utiliza una reducción paralela mediante memoria compartida (`shared memory`).



El objetivo es analizar el impacto de una técnica de optimización CUDA sobre el rendimiento de la suma de un vector de gran tamaño.



\---



\## Hardware y entorno



Las pruebas fueron realizadas en Google Colab utilizando una GPU NVIDIA Tesla T4.



\* GPU: NVIDIA Tesla T4

\* Compute Capability: 7.5

\* Memoria GPU: 15 GB

\* CUDA Toolkit: 12.8

\* Nsight Compute: 2025.1.1

\* Cantidad de elementos: `N = 16.777.216`

\* Threads por bloque: `256`



\---



\## 1. Kernel ingenuo



El archivo `kernel\_ingenuo.cu` implementa una suma mediante un único acumulador global.



Cada hilo procesa un elemento del vector y utiliza:



```cpp

atomicAdd(out, x\[i]);

```



Todos los hilos actualizan la misma posición de memoria global.



Esta implementación es correcta, pero las operaciones sobre el acumulador compartido deben serializarse, generando una gran cantidad de esperas y limitando el aprovechamiento de la GPU.



\### Correctitud



Para `N = 16.777.216` se obtuvo:



```text

ref = 16.777.216,0

gpu = 16.777.216,0

rel = 0,000e+00

ok

```



\---



\## 2. Kernel optimizado



El archivo `kernel\_optimizado.cu` implementa una reducción paralela utilizando memoria compartida.



Cada bloque carga sus elementos en memoria compartida:



```cpp

s\[tid] = (i < n) ? x\[i] : 0.f;

```



Luego se realiza una reducción en forma de árbol:



```cpp

for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {

&#x20;   if (tid < stride) {

&#x20;       s\[tid] += s\[tid + stride];

&#x20;   }



&#x20;   \_\_syncthreads();

}

```



Finalmente, el hilo `0` de cada bloque almacena el resultado parcial:



```cpp

if (tid == 0) {

&#x20;   parcial\[blockIdx.x] = s\[0];

}

```



Los resultados parciales son sumados posteriormente por la CPU.



Esta implementación constituye una reducción paralela real y utiliza memoria compartida para evitar que todos los hilos actualicen un único acumulador global.



\### Técnica de optimización utilizada



La principal técnica aplicada es el uso de \*\*memoria compartida (`shared memory`)\*\* junto con una \*\*reducción paralela en árbol\*\*.



Esto permite que los hilos de un mismo bloque colaboren para obtener una suma parcial, reduciendo la necesidad de operaciones atómicas sobre memoria global.



\### Correctitud



Para `N = 16.777.216` se obtuvo:



```text

ref = 16.777.216,0

gpu = 16.777.216,0

rel = 0,000e+00

ok

```



\---



\## 3. Benchmark



Se realizaron cinco ejecuciones para cada implementación y se utilizó la mediana de los tiempos obtenidos.



\### Comparación CPU y GPU



| Implementación | Tiempo mediano |

| -------------- | -------------: |

| CPU — Hito 1   |     284,463 ms |

| GPU ingenuo    |      50,946 ms |

| GPU optimizado |       0,847 ms |



La versión GPU ingenua fue aproximadamente:



\*\*5,58× más rápida que la versión secuencial de CPU.\*\*



La versión GPU optimizada fue aproximadamente:



\*\*335,45× más rápida que la versión secuencial de CPU.\*\*



Respecto de la versión GPU ingenua, la versión optimizada obtuvo un speedup de:



\*\*50,946 / 0,847 ≈ 60,15×\*\*



Por lo tanto, la utilización de una reducción paralela con memoria compartida produjo una mejora considerable respecto de la implementación basada en `atomicAdd`.



\---



\## 4. Profiling con Nsight Compute



Los dos kernels fueron analizados utilizando NVIDIA Nsight Compute sobre una NVIDIA Tesla T4.



\### Kernel ingenuo



| Métrica                 | Resultado |

| ----------------------- | --------: |

| Memory Throughput       |    2,06 % |

| Compute (SM) Throughput |    1,22 % |

| Memoria                 | 1,62 GB/s |

| Achieved Occupancy      |   87,71 % |

| Theoretical Occupancy   |     100 % |



El profiler muestra una ocupación relativamente alta, pero un aprovechamiento muy bajo de los recursos de cómputo y memoria.



El análisis de los schedulers muestra además un `No Eligible` de aproximadamente \*\*99,89 %\*\*, indicando que gran parte de los ciclos no encuentran warps listos para ejecutar.



Esto es consistente con la utilización de `atomicAdd` sobre un único acumulador global, ya que las actualizaciones deben competir por la misma posición de memoria.



\### Kernel optimizado



| Métrica                           |  Resultado |

| --------------------------------- | ---------: |

| Memory Throughput                 |    76,27 % |

| Compute (SM) Throughput           |    76,27 % |

| Memoria                           | 58,28 GB/s |

| Achieved Occupancy                |    90,38 % |

| Theoretical Occupancy             |      100 % |

| Shared Memory dinámica por bloque |    1,02 KB |



En la versión optimizada se observa un aprovechamiento mucho mayor de los recursos de la GPU.



La reducción paralela permite realizar gran parte del trabajo dentro de cada bloque utilizando memoria compartida, reduciendo la necesidad de actualizaciones atómicas sobre memoria global.



\---



\## 5. Comparación del profiling



| Métrica            |   Ingenuo | Optimizado |

| ------------------ | --------: | ---------: |

| Memory Throughput  |    2,06 % |    76,27 % |

| Compute Throughput |    1,22 % |    76,27 % |

| Memoria            | 1,62 GB/s | 58,28 GB/s |

| Occupancy          |   87,71 % |    90,38 % |

| Shared Memory      |      0 KB |    1,02 KB |



La diferencia principal no está solamente en la ocupación, sino en la forma en que se utilizan los recursos de la GPU.



El kernel ingenuo mantiene muchos hilos activos, pero las operaciones atómicas sobre el mismo acumulador provocan una fuerte serialización y generan esperas.



En cambio, el kernel optimizado distribuye la reducción entre los hilos de cada bloque y utiliza memoria compartida para realizar las operaciones intermedias.



\---



\## 6. Consideración sobre los tiempos del profiling



Los tiempos mostrados por Nsight Compute no se utilizan como benchmark principal.



Durante el profiling, Nsight Compute realiza múltiples pasadas sobre los kernels para obtener las diferentes métricas. Por este motivo, los tiempos observados durante el profiling son considerablemente mayores que los obtenidos mediante `cudaEvent`.



Los tiempos utilizados para la comparación de rendimiento son los obtenidos mediante las mediciones normales del programa.



\---



\## 7. Conclusiones



La implementación ingenua permite realizar correctamente la suma del vector sobre la GPU, pero el uso de `atomicAdd` sobre un único acumulador global genera una fuerte serialización.



La implementación optimizada utiliza una reducción paralela basada en memoria compartida. Cada bloque calcula una suma parcial mediante operaciones cooperativas entre sus hilos, reduciendo la dependencia del acumulador global.



Los resultados obtenidos muestran una mejora de aproximadamente \*\*60,15×\*\* de la versión optimizada respecto de la versión ingenua en la medición realizada sobre una NVIDIA Tesla T4.



Además, al comparar con la implementación secuencial



