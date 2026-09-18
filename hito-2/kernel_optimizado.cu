// kernel_optimizado.cu — Hito 2

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

__global__ void reduce_shared(const float* x, float* parcial, int n) {
    extern __shared__ float s[];

    const int tid = threadIdx.x;
    const int i = blockIdx.x * blockDim.x + tid;

    // Cada hilo carga un elemento en memoria compartida.
    // Si queda fuera del vector, carga 0.
    s[tid] = (i < n) ? x[i] : 0.f;

    __syncthreads();

    // Reducción paralela en árbol.
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (tid < stride) {
            s[tid] += s[tid + stride];
        }

        __syncthreads();
    }

    // El hilo 0 guarda la suma del bloque.
    if (tid == 0) {
        parcial[blockIdx.x] = s[0];
    }
}

int main(int argc, char** argv) {
    const int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);

    if (n < 1) {
        fprintf(stderr, "N >= 1\n");
        return 1;
    }

    const int threads = 256;
    const int blocks = (n + threads - 1) / threads;

    std::vector<float> h(static_cast<std::size_t>(n), 1.0f);

    double ref = 0.0;

    for (int i = 0; i < n; ++i) {
        ref += static_cast<double>(
            h[static_cast<std::size_t>(i)]
        );
    }

    float* d_x = nullptr;
    float* d_p = nullptr;

    CUDA_CHECK(
        cudaMalloc(
            &d_x,
            static_cast<size_t>(n) * sizeof(float)
        )
    );

    CUDA_CHECK(
        cudaMalloc(
            &d_p,
            static_cast<size_t>(blocks) * sizeof(float)
        )
    );

    CUDA_CHECK(
        cudaMemcpy(
            d_x,
            h.data(),
            static_cast<size_t>(n) * sizeof(float),
            cudaMemcpyHostToDevice
        )
    );

    cudaEvent_t ev_a, ev_b;

    CUDA_CHECK(cudaEventCreate(&ev_a));
    CUDA_CHECK(cudaEventCreate(&ev_b));

    CUDA_CHECK(cudaEventRecord(ev_a));

    reduce_shared<<<
        blocks,
        threads,
        static_cast<size_t>(threads) * sizeof(float)
    >>>(
        d_x,
        d_p,
        n
    );

    CUDA_CHECK(cudaGetLastError());

    CUDA_CHECK(cudaEventRecord(ev_b));
    CUDA_CHECK(cudaEventSynchronize(ev_b));

    float ms = 0.f;

    CUDA_CHECK(
        cudaEventElapsedTime(
            &ms,
            ev_a,
            ev_b
        )
    );

    std::vector<float> parcial(
        static_cast<std::size_t>(blocks)
    );

    CUDA_CHECK(
        cudaMemcpy(
            parcial.data(),
            d_p,
            static_cast<size_t>(blocks) * sizeof(float),
            cudaMemcpyDeviceToHost
        )
    );

    double gpu = 0.0;

    for (int i = 0; i < blocks; ++i) {
        gpu += static_cast<double>(
            parcial[static_cast<std::size_t>(i)]
        );
    }

    const double rel =
        (ref == 0.0)
            ? fabs(gpu)
            : fabs(gpu - ref) / fabs(ref);

    printf(
        "opt N=%d ref=%.1f gpu=%.1f rel=%.3e "
        "kernel_ms=%.3f %s\n",
        n,
        ref,
        gpu,
        rel,
        static_cast<double>(ms),
        rel < 1e-4 ? "ok" : "FAIL"
    );

    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_p));

    CUDA_CHECK(cudaEventDestroy(ev_a));
    CUDA_CHECK(cudaEventDestroy(ev_b));

    return rel < 1e-4 ? 0 : 1;
}
