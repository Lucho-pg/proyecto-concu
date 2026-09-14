// secuencial.cpp — Hito 1
// Suma secuencial de un vector grande de float. Referencia completa y compilable.
//
// Uso:
//   ./secuencial [N]
// N por defecto: 2^24 (16 777 216), el mismo orden de magnitud que en las prácticas.

#include <chrono>
#include <cstdlib>
#include <iostream>
#include <vector>

using clock_type = std::chrono::steady_clock;

// Acumulamos en double para no perder tanto con N grande de unos.
// El vector sigue en float: es el tipo que después va a CUDA (Hito 2).
float suma_secuencial(const float* data, int n) {
    double acc = 0.0;
    for (int i = 0; i < n; ++i) {
        acc += static_cast<double>(data[i]);
    }
    return static_cast<float>(acc);
}

int main(int argc, char** argv) {
    const int n = (argc > 1) ? std::atoi(argv[1]) : (1 << 24);
    if (n < 1) {
        std::cerr << "N debe ser >= 1\n";
        return 1;
    }

    std::vector<float> a(static_cast<std::size_t>(n), 1.0f);

    const auto t0 = clock_type::now();
    const float suma = suma_secuencial(a.data(), n);
    const auto t1 = clock_type::now();
    const double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();

    std::cout << "N=" << n << " suma=" << suma << " tiempo_ms=" << ms << '\n';
    return 0;
}
