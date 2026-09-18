NVCC      ?= nvcc
NVCCFLAGS ?= -std=c++17 -O2

all: kernel_ingenuo kernel_optimizado

kernel_ingenuo: kernel_ingenuo.cu
	$(NVCC) $(NVCCFLAGS) -o $@ $<

kernel_optimizado: kernel_optimizado.cu
	$(NVCC) $(NVCCFLAGS) -o $@ $<

clean:
	rm -f kernel_ingenuo kernel_optimizado

.PHONY: all clean
