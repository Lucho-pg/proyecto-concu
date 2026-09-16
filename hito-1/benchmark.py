import subprocess
import sys
import statistics
import os


N = 1 << 24
REPETICIONES = 5
CANTIDAD_HILOS = [1, 2, 4, 8, 16]
FRACCION_SECUENCIAL = 0.05


def ejecutar_secuencial():
    tiempos = []

    for _ in range(REPETICIONES):
        resultado = subprocess.run(
            [sys.executable, "hito-1/secuencial.py", str(N)],
            capture_output=True,
            text=True,
            check=True
        )

        linea = resultado.stdout.strip()
        tiempo = float(linea.split("tiempo_ms=")[1])
        tiempos.append(tiempo)

    return statistics.median(tiempos)


def ejecutar_paralelo(hilos):
    tiempos = []

    for _ in range(REPETICIONES):
        resultado = subprocess.run(
            [
                sys.executable,
                "hito-1/paralelo.py",
                str(N),
                str(hilos)
            ],
            capture_output=True,
            text=True,
            check=True
        )

        linea = resultado.stdout.strip()
        tiempo = float(linea.split("tiempo_ms=")[1])
        tiempos.append(tiempo)

    return statistics.median(tiempos)


def main():
    print("=== Benchmark Hito 1 ===")
    print(f"N={N}")
    print(f"Repeticiones={REPETICIONES}")
    print()

    print("Midiendo versión secuencial...")
    tiempo_secuencial = ejecutar_secuencial()

    print(f"Tiempo secuencial (mediana): {tiempo_secuencial:.3f} ms")
    print()

    print("Resultados:")
    print("Hilos | Tiempo (ms) | Speedup real | Amdahl")
    print("---------------------------------------------")
    for hilos in CANTIDAD_HILOS:
        tiempo = ejecutar_paralelo(hilos)
        speedup = tiempo_secuencial / tiempo

        speedup_amdahl = 1 / (
            FRACCION_SECUENCIAL
            + (1 - FRACCION_SECUENCIAL) / hilos
        )

        print(
            f"{hilos:5d} | "
            f"{tiempo:11.3f} | "
            f"{speedup:12.3f} | "
            f"{speedup_amdahl:7.3f}"
        )

if __name__ == "__main__":
    main()
