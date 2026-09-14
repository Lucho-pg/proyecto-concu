// paralelo.cpp — Hito 1
// Esqueleto multi-hilo (std::thread) de la suma del mismo vector que secuencial.cpp.
//
// Compila y corre, pero NO cumple el enunciado hasta que completes los TODO:
// hace falta al menos una primitiva de sincronización de la Clase 3
// (mutex, variable de condición o monitor). El join de los hilos no alcanza.
//
// Uso:
//   ./paralelo [N] [T]
// T = cantidad de hilos (por defecto 4).

#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

// Índice compartido para despacho dinámico de bloques (opción recomendada).
// Sin el candado, varios hilos pueden leer/escribir `proximo` a la vez → carrera.
[[maybe_unused]] std::mutex mtx;
int proximo = 0;

// Tamaño de bloque de trabajo. Elegilo y justificalo en el informe
// (muy chico: contención del mutex; muy grande: desbalance si N no es múltiplo).
[[maybe_unused]] const int BLOQUE = 1 << 16;

void worker(const float* data, int n, float& parcial) {
    double acc = 0.0;

    while (true) {
        int lo = 0;
        int hi = 0;
        
        {
            std::lock_guard<std::mutex> lock(mtx);

            if (proximo >= n) {
                break;
            }

            lo = proximo;
            proximo = std::min(proximo + BLOQUE, n);
            hi = proximo;
        }

        for (int i = lo; i < hi; ++i) {
            acc += static_cast<double>(data[i]);
        }
    }

    // Cada hilo escribe en su propia entrada de `parciales` (sin aliasing).
    parcial = static_cast<float>(acc);
}

int main(int argc, char** argv) {
    const int n = (argc > 1) ? std::atoi(argv[1]) : (1 << 24);
    const int t = (argc > 2) ? std::atoi(argv[2]) : 4;
    if (n < 1 || t < 1) {
        std::cerr << "N >= 1 y T >= 1\n";
        return 1;
    }

    std::vector<float> a(static_cast<std::size_t>(n), 1.0f);
    std::vector<float> parciales(static_cast<std::size_t>(t), 0.0f);
    std::vector<std::thread> hilos;
    hilos.reserve(static_cast<std::size_t>(t));

    proximo = 0;
    for (int i = 0; i < t; ++i) {
        hilos.emplace_back(worker, a.data(), n, std::ref(parciales[static_cast<std::size_t>(i)]));
    }
    for (auto& h : hilos) {
        h.join();
    }

    // Reduce serial de T parciales. Con T chico (núcleos de una notebook)
    // no hace falta mutex acá: este hilo es el único que queda vivo.
    double total = 0.0;
    for (float p : parciales) {
        total += static_cast<double>(p);
    }

    std::cout << "N=" << n << " T=" << t << " suma=" << static_cast<float>(total) << '\n';
    return 0;
}
