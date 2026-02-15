#!/bin/sh
set -e

echo "=== MinIO Init: Configuring buckets and policies ==="

# Wait for MinIO
until mc alias set fiutami http://${MINIO_HOST:-minio}:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} 2>/dev/null; do
  echo "Waiting for MinIO..."
  sleep 2
done

echo "MinIO connected."

# Create buckets (idempotent)
for bucket in fiutami-photos fiutami-documents fiutami-avatars; do
  if ! mc ls fiutami/$bucket > /dev/null 2>&1; then
    mc mb fiutami/$bucket
    echo "Created bucket: $bucket"
  else
    echo "Bucket already exists: $bucket"
  fi
done

# Enable versioning on documents bucket
mc version enable fiutami/fiutami-documents

# Create app policy (idempotent)
cat > /tmp/fiutami-app-policy.json << 'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::fiutami-photos",
        "arn:aws:s3:::fiutami-photos/*",
        "arn:aws:s3:::fiutami-documents",
        "arn:aws:s3:::fiutami-documents/*",
        "arn:aws:s3:::fiutami-avatars",
        "arn:aws:s3:::fiutami-avatars/*"
      ]
    }
  ]
}
POLICY

mc admin policy create fiutami fiutami-app-policy /tmp/fiutami-app-policy.json 2>/dev/null || \
  mc admin policy info fiutami fiutami-app-policy > /dev/null 2>&1 && echo "Policy already exists"

# Create app user (idempotent)
mc admin user add fiutami ${MINIO_APP_USER:-fiutami-app} ${MINIO_APP_PASSWORD} 2>/dev/null || \
  echo "User already exists: ${MINIO_APP_USER:-fiutami-app}"

# Attach policy to user
mc admin policy attach fiutami fiutami-app-policy --user ${MINIO_APP_USER:-fiutami-app} 2>/dev/null || true

echo "=== MinIO Init: Complete ==="
