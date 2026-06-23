#!/bin/bash

# Read .env file
export $(grep -v '^#' .env | xargs)

# In case you have spaces in your SSH key
SSH_AUTHORIZED_KEYS=$(cat .env | grep SSH_AUTHORIZED_KEYS | cut -d '=' -f2-)

COUNTER=0
MAX_RETRIES=65
SLEEP_TIME=300

while [ $COUNTER -lt $MAX_RETRIES ]; do
    COUNTER=$((COUNTER + 1))
    echo "----------------------------------------"
    echo "Deneme Sayısı: $COUNTER - Tarih: $(date)"
    
    # Run the OCI CLI command and capture both standard output and standard error
    output=$(oci compute instance launch \
        --availability-domain "$AVAILABILITY_DOMAIN" \
        --compartment-id "$TENANCY_ID" \
        --shape "$SHAPE" \
        --assign-public-ip true \
        --subnet-id "$SUBNET_ID" \
        --image-id "$IMAGE_ID" \
        --ssh-authorized-keys "$SSH_AUTHORIZED_KEYS" \
        --shape-config '{"ocpus": 4, "memoryInGBs": 24}' \
        --display-name "Oracle-Free-ARM" 2>&1)

    # Check if the output contains the specific service error for out of host capacity
    if [[ "$output" == *"Out of host capacity"* ]]; then
        echo "Kapasite yetersiz. 5 dakika bekleniyor..."
        sleep $SLEEP_TIME
    # Check if Oracle hits us with too many requests limit
    elif [[ "$output" == *"TooManyRequests"* || "$output" == *"Too many requests"* ]]; then
        echo "Oracle: Çok fazla istek gönderildi (429). Döngü kırılmıyor, 5 dakika bekleniyor..."
        sleep $SLEEP_TIME
    # Check if the connection to Oracle API gateway timed out
    elif [[ "$output" == *"timed out"* || "$output" == *"RequestException"* || "$output" == *"connection"* ]]; then
        echo "Bağlantı zaman aşımına uğradı veya koptu (Oracle geç cevap verdi)."
        echo "Döngü kırılmıyor, 5 dakika sonra tekrar denenecek..."
        sleep $SLEEP_TIME
    else
        # If there is no specific error string, check if the output indicates success or unexpected error
        if [[ "$output" == *"id"* && "$output" == *"lifecycle-state"* ]]; then
            echo "TEBRİKLER! Sunucu başarıyla oluşturuldu!"
            echo "$output"
            break
        else
            echo "Bilinmeyen veya geçici bir yanıt alındı. Döngü riske atılmıyor, pusuya devam..."
            echo "$output"
            sleep $SLEEP_TIME
        fi
    fi
done
