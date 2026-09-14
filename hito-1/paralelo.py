import sys
import time
import threading


def suma_paralela(data, cantidad_hilos):
    n = len(data)

    # Próximo bloque que debe ser procesado
    proximo = 0

    # Tamaño de cada bloque
    bloque = 100_000

    # Lock para proteger el acceso a "proximo"
    lock = threading.Lock()

    # Resultado parcial de cada hilo
    resultados = [0.0] * cantidad_hilos

    def trabajador(indice_hilo):
        nonlocal proximo

        suma_local = 0.0

        while True:
            # Sección crítica:
            # solo un hilo a la vez puede obtener un bloque.
            with lock:
                if proximo >= n:
                    break

                inicio = proximo
                fin = min(proximo + bloque, n)
                proximo = fin

            # El hilo procesa su bloque fuera del Lock
            for i in range(inicio, fin):
                suma_local += data[i]

        resultados[indice_hilo] = suma_local

    hilos = []

    for i in range(cantidad_hilos):
        hilo = threading.Thread(target=trabajador, args=(i,))
        hilos.append(hilo)
        hilo.start()

    # Esperamos a que terminen todos los hilos
    for hilo in hilos:
        hilo.join()

    return sum(resultados)


def main():
    # N por defecto: 2^24 = 16.777.216
    n = int(sys.argv[1]) if len(sys.argv) > 1 else (1 << 24)

    # Cantidad de hilos por defecto: 4
    cantidad_hilos = int(sys.argv[2]) if len(sys.argv) > 2 else 4

    if n < 1:
        print("N debe ser >= 1")
        return

    if cantidad_hilos < 1:
        print("La cantidad de hilos debe ser >= 1")
        return

    # Creamos un vector de N elementos, todos con valor 1.0
    datos = [1.0] * n

    inicio = time.perf_counter()

    suma = suma_paralela(datos, cantidad_hilos)

    fin = time.perf_counter()

    tiempo_ms = (fin - inicio) * 1000

    print(
        f"N={n} hilos={cantidad_hilos} "
        f"suma={suma} tiempo_ms={tiempo_ms:.3f}"
    )


if __name__ == "__main__":
    main()
