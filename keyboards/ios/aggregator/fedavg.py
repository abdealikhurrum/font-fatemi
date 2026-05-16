"""
Federated averaging for ONNX model weight deltas.

Each contributor uploads a weight DELTA (fine_tuned_weights - base_weights).
We average the deltas and add them to the base model to produce the merged model.

This approach means:
  - Contributors only need to send the difference, not full model weights (smaller upload)
  - The server can apply a learning rate to control how aggressively updates are merged
  - Individual contributions cannot be inverted to recover training text
"""

import struct
import logging
import numpy as np
from pathlib import Path

log = logging.getLogger("fedavg")

# How strongly to apply the averaged delta to the base model.
# 1.0 = full replacement, 0.5 = blend equally with base.
GLOBAL_LEARNING_RATE = 0.8


def run_fedavg(
    delta_paths: list[str],
    base_model_path: str,
    output_path: str,
) -> None:
    """
    Average the weight deltas and apply them to the base model.

    Args:
        delta_paths:      Paths to .delta files received from contributors.
        base_model_path:  Path to the current base ONNX model.
        output_path:      Where to write the new merged ONNX model.
    """
    if not delta_paths:
        raise ValueError("No delta files provided")

    log.info("FedAvg: averaging %d deltas", len(delta_paths))

    # Load all deltas
    deltas = [load_delta(p) for p in delta_paths]

    # Validate that all deltas have the same keys
    keys = set(deltas[0].keys())
    for i, d in enumerate(deltas[1:], 1):
        if set(d.keys()) != keys:
            raise ValueError(f"Delta {i} has mismatched weight keys")

    # Average each weight tensor across all contributors
    averaged_delta: dict[str, np.ndarray] = {}
    for key in keys:
        arrays = [d[key] for d in deltas]
        # Simple mean — could be weighted by contributor pair count in future
        averaged_delta[key] = np.mean(arrays, axis=0)

    log.info("Averaged %d weight tensors", len(averaged_delta))

    # Load base model weights and apply the averaged delta
    try:
        base_weights = load_onnx_weights(base_model_path)
    except FileNotFoundError:
        log.warning("Base model not found at %s — using delta as absolute weights", base_model_path)
        base_weights = {k: np.zeros_like(v) for k, v in averaged_delta.items()}

    merged_weights: dict[str, np.ndarray] = {}
    for key in keys:
        if key in base_weights:
            merged_weights[key] = (
                base_weights[key] + GLOBAL_LEARNING_RATE * averaged_delta[key]
            )
        else:
            merged_weights[key] = averaged_delta[key]

    # Save merged model
    save_onnx_weights(base_model_path, merged_weights, output_path)
    log.info("Merged model written to %s", output_path)


# ---------------------------------------------------------------------------
# Delta serialisation
# Lightweight binary format: [num_tensors: u32] ([name_len: u32][name: utf8]
#                             [shape_len: u32][shape: i64...][data: f32...])*
# ---------------------------------------------------------------------------

MAGIC = b"LSDD"   # Lisan ud Dawat Delta


def save_delta(weights_before: dict, weights_after: dict, output_path: str) -> None:
    """
    Compute and serialise a weight delta.
    Call this from the iOS companion Python script after local fine-tuning.
    """
    delta = {k: weights_after[k] - weights_before[k] for k in weights_before}
    _write_delta(delta, output_path)


def load_delta(path: str) -> dict[str, np.ndarray]:
    data = Path(path).read_bytes()
    if data[:4] != MAGIC:
        raise ValueError(f"Bad magic bytes in {path}")
    return _read_delta(data[4:])


def _write_delta(tensors: dict[str, np.ndarray], path: str) -> None:
    buf = bytearray(MAGIC)
    buf += struct.pack("<I", len(tensors))
    for name, arr in tensors.items():
        arr = arr.astype(np.float32)
        name_bytes = name.encode("utf-8")
        buf += struct.pack("<I", len(name_bytes))
        buf += name_bytes
        shape = arr.shape
        buf += struct.pack("<I", len(shape))
        buf += struct.pack(f"<{len(shape)}q", *shape)
        buf += arr.tobytes()
    Path(path).write_bytes(bytes(buf))


def _read_delta(data: bytes) -> dict[str, np.ndarray]:
    offset = 0
    (n_tensors,) = struct.unpack_from("<I", data, offset); offset += 4
    tensors = {}
    for _ in range(n_tensors):
        (name_len,) = struct.unpack_from("<I", data, offset); offset += 4
        name = data[offset:offset + name_len].decode("utf-8"); offset += name_len
        (shape_len,) = struct.unpack_from("<I", data, offset); offset += 4
        shape = struct.unpack_from(f"<{shape_len}q", data, offset); offset += 8 * shape_len
        n_elements = int(np.prod(shape))
        arr = np.frombuffer(data, dtype=np.float32, count=n_elements, offset=offset).reshape(shape)
        offset += n_elements * 4
        tensors[name] = arr.copy()
    return tensors


# ---------------------------------------------------------------------------
# ONNX helpers
# Requires: pip install onnx onnxruntime
# ---------------------------------------------------------------------------

def load_onnx_weights(model_path: str) -> dict[str, np.ndarray]:
    import onnx
    from onnx import numpy_helper
    model = onnx.load(model_path)
    return {
        init.name: numpy_helper.to_array(init)
        for init in model.graph.initializer
    }


def save_onnx_weights(
    base_model_path: str,
    new_weights: dict[str, np.ndarray],
    output_path: str,
) -> None:
    import onnx
    from onnx import numpy_helper
    model = onnx.load(base_model_path)
    for init in model.graph.initializer:
        if init.name in new_weights:
            new_tensor = numpy_helper.from_array(
                new_weights[init.name].astype(np.float32), name=init.name
            )
            init.CopyFrom(new_tensor)
    onnx.save(model, output_path)
