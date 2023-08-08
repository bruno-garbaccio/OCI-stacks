# Export Variables as Environment variables
export OCI_PATH_CONF_FILE=/opt/oci-hpc/conf/queues.conf
export OCI_USER=opc
export OCI_SEARCHDATE=2023-05-24
export OCI_PUBLIC_IP=132.226.205.26
export OCI_SECRET_OCID=ocid1.vaultsecret.oc1.eu-frankfurt-1.amaaaaaaldij5aia6xztjv7azubjwrc7qhtc2kqhach7zftnne2i2eh6vteq
export OCI_APIGWURL=https://pmcxgzkma7wn7z7yh57tgo46na.apigateway.eu-frankfurt-1.oci.customer-oci.com/v1/slurm

# Install modules and Build
npm install
./node_modules/.bin/grunt initVar vb-process-local vb-package --mode=fa

# Publish on OCI Object Storage
export OCI_OS_BUCKET=OciSlurmFrontend
export OCI_NAMESPACE=frn9volod3kr

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

