import sys
import time


def suma_secuencial(data):
    acumulador = 0.0

    for valor in data:
        acumulador += valor

    return acumulador


def main():
    # N por defecto: 2^24 = 16.777.216
    n = int(sys.argv[1]) if len(sys.argv) > 1 else (1 << 24)

    if n < 1:
        print("N debe ser >= 1")
        return

    # Creamos un vector de N elementos, todos con valor 1.0
    datos = [1.0] * n

    inicio = time.perf_counter()

    suma = suma_secuencial(datos)

    fin = time.perf_counter()

    tiempo_ms = (fin - inicio) * 1000

    print(f"N={n} suma={suma} tiempo_ms={tiempo_ms:.3f}")


if __name__ == "__main__":
    main()
