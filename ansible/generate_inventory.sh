#!/bin/bash

# Di chuyển sang thư mục terraform
cd "$(dirname "$0")/../terraform" || exit

# Kiểm tra output tồn tại
if ! terraform output -json vm_ips > /dev/null 2>&1; then
  echo "❌ Terraform output 'vm_ips' không tồn tại. Hãy chắc chắn bạn đã chạy terraform apply."
  exit 1
fi

# Lấy output JSON từ Terraform
output=$(terraform output -json vm_ips)

# Xoá host key cũ trong known_hosts
echo -e "\n🧹 Đang xoá các SSH key cũ trong ~/.ssh/known_hosts..."
echo "$output" | jq -r '.[]' | while read -r ip; do
  ssh-keygen -R "$ip" >/dev/null 2>&1 && echo "✅ Đã xoá key của $ip"
done

# Thêm các SSH key mới vào known_hosts
echo -e "\n🔑 Đang thêm các SSH key mới vào ~/.ssh/known_hosts..."
echo "$output" | jq -r '.[]' | while read -r ip; do
  ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts && echo "✅ Đã thêm key của $ip"
done

# Đường dẫn file inventory
inventory_file="../ansible/inventory.ini"
common_args="ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"

# Tạo phần [master]
echo "[master]" > "$inventory_file"
echo "$output" | jq -r '. as $ips | to_entries[] | select(.key == "master-node") | "\(.key) ansible_host=\(.value) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my_gcp_key"' >> "$inventory_file"
# Tạo phần [worker]
echo -e "\n[workers]" >> "$inventory_file"
echo "$output" | jq -r '. as $ips | to_entries[] | select(.key | test("^worker-node")) | "\(.key) ansible_host=\(.value) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my_gcp_key"' >> "$inventory_file"

echo -e "\n✅ Đã tạo xong inventory.ini tại thư mục ansible:"
cat "$inventory_file"

