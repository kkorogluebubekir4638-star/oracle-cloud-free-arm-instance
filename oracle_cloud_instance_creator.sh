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

echo "Bağlantı başarılı! Sonsuz istek döngüsü başlatılıyor..."

# GitHub Actions tek seferde en fazla 6 saat çalışabilir. 
# Bu yüzden botu 5 buçuk saat boyunca içeride aralıksız döndüreceğiz.
for ((i=1; i<=65; i++))
do
   echo "----------------------------------------"
   echo "Deneme Sayısı: $i - Tarih: $(date)"
   
   # Sunucu oluşturma komutunu tetikle
   OUTPUT=$(oci compute instance launch \
     --availability-domain "$OCI_AVAILABILITY_DOMAIN" \
     --compartment-id "$OCI_TENANCY_OCID" \
     --shape "VM.Standard.A1.Flex" \
     --shape-config '{"ocpus":4,"memoryInGBs":24}' \
     --display-name "Kayseri-ARM-Sunucu" \
     --image-id "$OCI_IMAGE_ID" \
     --subnet-id "$OCI_SUBNET_ID" \
     --assign-public-ip true 2>&1)

   echo "$OUTPUT"

   # Eğer çıktı içinde kapasite hatası varsa, sunucu henüz açılmamıştır
   if [[ "$OUTPUT" == *"Out of host capacity"* ]]; then
       echo "Kapasite yetersiz. 5 dakika bekleniyor..."
       sleep 300 # 5 dakika (300 saniye) uyku modu
   else
       echo "Farklı bir durum veya BAŞARI yakalandı! Döngü sonlandırılıyor."
       break
   fi
done
