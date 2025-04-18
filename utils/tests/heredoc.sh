### Weird heredoc stuff I still need to correct. Testing

#!/bin/bash
TARGET_USER="testuser"

echo "=== With quoted EOF ==="
cat << 'EOF'
Username is $TARGET_USER
EOF

echo "=== With unquoted EOF ==="
cat << EOF
Username is $TARGET_USER
EOF

