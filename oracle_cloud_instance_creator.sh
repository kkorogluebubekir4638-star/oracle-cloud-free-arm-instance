#!/bin/bash

echo "=== Oracle ARM Bot Baslatiliyor ==="

# OCI Yapılandırma Dosyasını Olustur
mkdir -p ~/.oci
echo "[DEFAULT]" > ~/.oci/config
echo "user=$OCI_USER_OCID" >> ~/.oci/config
echo "fingerprint=$OCI_FINGERPRINT" >> ~/.oci/config
echo "tenancy=$OCI_TENANCY_OCID" >> ~/.oci/config
echo "region=$OCI_REGION" >> ~/.oci/config
echo "key_file=/home/runner/.oci/key.pem" >> ~/.oci/config

# Private Key'i yaz
echo "$OCI_PRIVATE_KEY" > ~/.oci/key.pem
chmod 600 ~/.oci/key.pem

echo "Bağlantı test ediliyor..."
oci iam compartment list --compartment-id "$OCI_TENANCY_OCID" > /dev/null

if [ $? -ne 0 ]; then
    echo "Hata: Oracle Cloud bağlantısı başarısız! Girdiğiniz şifreleri (Secrets) kontrol edin."
    exit 1
fi

echo "Bağlantı başarılı! İstek döngüsü başlatılıyor..."

# Sunucu oluşturma komutunu tetikle
oci compute instance launch \
  --availability-domain "$OCI_AVAILABILITY_DOMAIN" \
  --compartment-id "$OCI_TENANCY_OCID" \
  --shape "VM.Standard.A1.Flex" \
  --shape-config '{"ocpus":4,"memoryInGBs":24}' \
  --display-name "Kayseri-ARM-Sunucu" \
  --image-id "$OCI_IMAGE_ID" \
  --subnet-id "$OCI_SUBNET_ID" \
  --assign-public-ip true
