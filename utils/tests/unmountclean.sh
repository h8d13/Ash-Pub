echo "Ensuring all partitions are unmounted..."
for i in $(mount | grep "^${TARGET_DISK}" | cut -d' ' -f1); do
  echo "Unmounting $i..."
  umount -f "$i" || true
done
