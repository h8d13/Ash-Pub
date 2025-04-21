echo "Ensuring all partitions are unmounted..."
for i in $(mount | grep "^${TARGET_DISK}" | cut -d' ' -f1); do
  echo "Unmounting $i..."
  umount -f "$i" || true
done

fuser -km "$TARGET_MOUNT" 2>/dev/null || true


# Try lazy unmount
umount -l "$TARGET_MOUNT" 2>/dev/null || true
umount -l "${TARGET_DISK}1" 2>/dev/null || true
umount -l "${TARGET_DISK}2" 2>/dev/null || true
