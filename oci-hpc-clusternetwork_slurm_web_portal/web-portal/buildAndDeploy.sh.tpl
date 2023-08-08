# Export Variables as Environment variables
export OCI_PATH_CONF_FILE=/opt/oci-hpc/conf/queues.conf
export OCI_USER=${user}
export OCI_SEARCHDATE=${searchdate}
export OCI_PUBLIC_IP=${public_ip}
export OCI_SECRET_OCID=${secret_ocid}
export OCI_APIGWURL=${endpoint}

# Install modules and Build
npm install
./node_modules/.bin/grunt initVar vb-process-local vb-package --mode=fa

# Publish on OCI Object Storage
export OCI_OS_BUCKET=${bucket}
export OCI_NAMESPACE=${namespace}

cd build/optimized/webApps/slurmfrontend
# Delete files
oci os object bulk-delete -ns $OCI_NAMESPACE  -bn $OCI_OS_BUCKET  --prefix static --force
# Upload files with content type
oci os object bulk-upload -bn $OCI_OS_BUCKET --src-dir ./ --content-type application/json  --include "*.json" --overwrite
oci os object bulk-upload -bn $OCI_OS_BUCKET --src-dir ./ --content-type text/html --include "*.html" --overwrite
oci os object bulk-upload -bn $OCI_OS_BUCKET --src-dir ./ --content-type image/jpeg --include "*.png" --overwrite
oci os object bulk-upload -bn $OCI_OS_BUCKET --src-dir ./ --content-type text/javascript --include "*.js" --overwrite
oci os object bulk-upload -bn $OCI_OS_BUCKET --src-dir ./ --content-type application/pdf --include '*.pdf"' --overwrite
oci os object bulk-upload -bn $OCI_OS_BUCKET --src-dir ./ --content-type text/css --include "*.css" --overwrite
oci os object bulk-upload -bn $OCI_OS_BUCKET --src-dir ./ --content-type text/plain --exclude "*.js" --exclude "*.html" --exclude "*.png" --exclude '*.pdf' --exclude "*.css" --exclude "./*.json" --overwrite

