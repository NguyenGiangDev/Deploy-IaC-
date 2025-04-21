#!/bin/bash

# Di chuyển sang thư mục terraform
cd ../terraform || exit

# Kiểm tra output tồn tại
if ! terraform output -json vm_ips > /dev/null 2>&1; then
  echo "❌ Terraform output 'vm_ips' không tồn tại. Hãy chắc chắn bạn đã chạy terraform apply."
  exit 1
fi

# Lấy output JSON từ Terraform
output=$(terraform output -json vm_ips)

# Đường dẫn file inventory
inventory_file="../ansible/inventory.ini"
echo "[master]" > "$inventory_file"
echo "$output" | jq -r '. as $ips | to_entries[] | select(.key == "master-node") | "\(.key) ansible_host=\(.value) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my_gcp_key"' >> "$inventory_file"

echo -e "\n[workers]" >> "$inventory_file"
echo "$output" | jq -r '. as $ips | to_entries[] | select(.key | test("^worker-node")) | "\(.key) ansible_host=\(.value) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my_gcp_key"' >> "$inventory_file"

echo -e "\n✅ Đã tạo xong inventory.ini tại thư mục ansible:"
cat "$inventory_file"
