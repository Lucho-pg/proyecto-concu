// kernel_ingenuo.cu — Hito 2
// Reducción (suma) ingenua en GPU del mismo problema del Hito 1.
// Completo y compilable con nvcc. Es el baseline: correcto y lento.
//
// Uso:
//   ./kernel_ingenuo [N]

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
#include <vector>

#define CUDA_CHECK(call)                                                       \
    do {                                                                       \
        cudaError_t e = (call);                                                \
        if (e != cudaSuccess) {                                                \
            fprintf(stderr, "%s:%d %s\n", __FILE__, __LINE__,                  \
                    cudaGetErrorString(e));                                    \
            exit(1);                                                           \
        }                                                                      \
    } while (0)

// Cada hilo hace atomicAdd sobre un único acumulador en memoria global.
// Correcto, pero serializa actualizaciones: sirve para vencerlo en
// kernel_optimizado.cu, no como solución del hito.
__global__ void suma_atomica(const float* x, float* out, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        atomicAdd(out, x[i]);
    }
}

int main(int argc, char** argv) {
    const int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    if (n < 1) {
        fprintf(stderr, "N >= 1\n");
        return 1;
    }

    std::vector<float> h(static_cast<std::size_t>(n), 1.0f);
    double ref = 0.0;
    for (int i = 0; i < n; ++i) {
        ref += static_cast<double>(h[static_cast<std::size_t>(i)]);
    }

    float* d_x = nullptr;
    float* d_out = nullptr;
    CUDA_CHECK(cudaMalloc(&d_x, static_cast<size_t>(n) * sizeof(float)));
    CUDA_CHECK(cudaMalloc(&d_out, sizeof(float)));
    CUDA_CHECK(cudaMemcpy(d_x, h.data(), static_cast<size_t>(n) * sizeof(float),
                          cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemset(d_out, 0, sizeof(float)));

    const int threads = 256;
    const int blocks = (n + threads - 1) / threads;

    cudaEvent_t ev_a, ev_b;
    CUDA_CHECK(cudaEventCreate(&ev_a));
    CUDA_CHECK(cudaEventCreate(&ev_b));
    CUDA_CHECK(cudaEventRecord(ev_a));
    suma_atomica<<<blocks, threads>>>(d_x, d_out, n);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(ev_b));
    CUDA_CHECK(cudaEventSynchronize(ev_b));
    float ms = 0.f;
    CUDA_CHECK(cudaEventElapsedTime(&ms, ev_a, ev_b));

    float gpu = 0.f;
    CUDA_CHECK(cudaMemcpy(&gpu, d_out, sizeof(float), cudaMemcpyDeviceToHost));
    const double rel = fabs(static_cast<double>(gpu) - ref) / fabs(ref);
    printf("ingenuo N=%d ref=%.1f gpu=%.1f rel=%.3e kernel_ms=%.3f %s\n", n, ref,
           static_cast<double>(gpu), rel, static_cast<double>(ms),
           rel < 1e-3 ? "ok" : "FAIL");

    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_out));
    CUDA_CHECK(cudaEventDestroy(ev_a));
    CUDA_CHECK(cudaEventDestroy(ev_b));
    return rel < 1e-3 ? 0 : 1;
}
