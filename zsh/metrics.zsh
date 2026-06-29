# One-shot system metrics summary:  metrics
metrics() {
  echo "=== CPU ==="
  echo "cores: $(nproc)   load:$(awk '{print " "$1" "$2" "$3}' /proc/loadavg)"
  echo
  echo "=== Memory ==="
  free -h | awk 'NR==1 || /Mem:|Swap:/'
  echo
  echo "=== Disk (/) ==="
  df -h / | awk 'NR==1 || NR==2'
  echo
  echo "=== GPU ==="
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu \
      --format=csv,noheader
  else
    echo "nvidia-smi not available"
  fi
}
