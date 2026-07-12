"""
golden_model.py - int8 matmul reference (project step 1.0)

The ORACLE for the whole project. Every RTL version you build later
(sequential one-MAC, broadcast array, true systolic array) must reproduce
these results bit-for-bit in simulation. The golden model defines WHAT the
correct output is; it says nothing about HOW the hardware computes it.

Number format - pin these down, the RTL must match exactly:
  inputs A, B : signed int8, two's complement, range [-128, 127]
  product     : signed8 * signed8 -> fits in signed 16-bit
  accumulator : signed int32 (safe until K ~= 131000, so you're fine for anything)
  output C    : raw signed int32, NO requantization (requant is an act-two / hls4ml job)
  matmul      : C[i,j] = sum_k A[i,k]*B[k,j];  A is MxK, B is KxN, C is MxN
"""

import numpy as np
from pathlib import Path


def matmul_ref(A, B):
    """The oracle. int8 in, exact int32 out."""
    A = np.asarray(A, dtype=np.int8)
    B = np.asarray(B, dtype=np.int8)
    assert A.ndim == 2 and B.ndim == 2, "A and B must be 2-D"
    assert A.shape[1] == B.shape[0], f"shape mismatch: {A.shape} x {B.shape}"
    # Cast to int32 BEFORE the multiply. numpy int8 math overflows SILENTLY -
    # this single cast is the most important line in the file.
    return A.astype(np.int32) @ B.astype(np.int32)


def rand_int8(rows, cols, rng, seed_edges=True):
    """Random int8 matrix, with the values that break signed-multiply RTL
    deliberately sprinkled in: -128 (asymmetric min), 127, 0, -1."""
    M = rng.integers(-128, 128, size=(rows, cols), dtype=np.int8)
    if seed_edges:
        for v in (-128, 127, 0, -1):
            M[rng.integers(rows), rng.integers(cols)] = v
    return M


def to_hex(v, nbytes):
    """Two's-complement hex, masked so negatives format correctly.
    int8 -1 -> 'ff', int32 -21 -> 'ffffffeb'."""
    return f"{int(v) & ((1 << (nbytes * 8)) - 1):0{nbytes * 2}x}"


def dump_readmemh(mat, path, nbytes):
    """Row-major flatten, one hex value per line, for SystemVerilog $readmemh.
    Your testbench memory layout MUST match this row-major order."""
    flat = mat.reshape(-1)  # numpy default is row-major (C order)
    Path(path).write_text("\n".join(to_hex(v, nbytes) for v in flat) + "\n")


def write_test_case(name, M, K, N, rng, outdir):
    A = rand_int8(M, K, rng)
    B = rand_int8(K, N, rng)
    C = matmul_ref(A, B)
    d = Path(outdir); d.mkdir(parents=True, exist_ok=True)
    dump_readmemh(A, d / f"{name}_A.hex", 1)   # int8  -> 2 hex digits/line
    dump_readmemh(B, d / f"{name}_B.hex", 1)
    dump_readmemh(C, d / f"{name}_C.hex", 4)   # int32 -> 8 hex digits/line
    (d / f"{name}.txt").write_text(
        f"A ({M}x{K}):\n{A}\n\nB ({K}x{N}):\n{B}\n\nC=A@B ({M}x{N}):\n{C}\n")
    return A, B, C


def sanity_checks():
    """Verify the oracle itself before you trust it to judge your hardware."""
    # identity: A @ I == A
    A = np.array([[1, 2], [3, 4]], dtype=np.int8)
    assert np.array_equal(matmul_ref(A, np.eye(2, dtype=np.int8)), A.astype(np.int32))
    # hand-computed 2x2 with negatives
    a = np.array([[2, -3], [4, 5]], dtype=np.int8)
    b = np.array([[1, 0], [-2, 7]], dtype=np.int8)
    assert np.array_equal(matmul_ref(a, b), np.array([[8, -21], [-6, 35]], dtype=np.int32))
    # the nasty signed corner: -128 * -128 = +16384
    assert matmul_ref(np.array([[-128]], dtype=np.int8),
                      np.array([[-128]], dtype=np.int8))[0, 0] == 16384
    print("sanity checks passed")


if __name__ == "__main__":
    sanity_checks()
    rng = np.random.default_rng(0xC0FFEE)   # fixed seed -> reproducible vectors
    cases = {"tiny_4x4": (4, 4, 4), "rect_3x5x2": (3, 5, 2), "med_8x8": (8, 8, 8)}
    for name, (M, K, N) in cases.items():
        A, B, C = write_test_case(name, M, K, N, rng, "vectors")
        print(f"{name:12s}: A{A.shape} @ B{B.shape} -> C{C.shape}, "
              f"C in [{C.min()}, {C.max()}]")
    print("vectors/ written")
