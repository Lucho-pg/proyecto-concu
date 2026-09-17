import matplotlib.pyplot as plt

hilos = [1, 2, 4, 8, 16]

speedup_real = [
    0.686,
    0.665,
    0.678,
    0.666,
    0.676
]

speedup_amdahl = [
    1.000,
    1.905,
    3.478,
    5.926,
    9.143
]

plt.plot(hilos, speedup_real, marker="o", label="Speedup real")
plt.plot(hilos, speedup_amdahl, marker="o", label="Speedup Amdahl")

plt.xlabel("Cantidad de hilos")
plt.ylabel("Speedup")
plt.title("Speedup real vs. Ley de Amdahl")

plt.xticks(hilos)
plt.grid(True)
plt.legend()

plt.savefig("hito-1/grafico_speedup.png", dpi=150, bbox_inches="tight")

plt.show()