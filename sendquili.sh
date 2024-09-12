#!/bin/bash

# 钉钉机器人 WebHook URL 和密钥
WEBHOOK_URL="修改为你的钉钉机器人的webhook"
SECRET="修改为你的钉钉密匙"

# 服务器名称
SERVER_NAME="XX服务器"

# 日志文件路径
LOG_FILE="/root/monitor.log"

# 计算签名
calculate_signature() {
    local timestamp=$(date "+%s%3N")
    local secret="$SECRET"
    local string_to_sign="${timestamp}\n${secret}"
    local sign=$(echo -ne "${string_to_sign}" | openssl dgst -sha256 -hmac "${secret}" -binary | base64)
    echo "${timestamp}&${sign}"
}

# 发送钉钉消息
send_dingtalk_message() {
    local message=$1
    local sign=$(calculate_signature)
    local url="${WEBHOOK_URL}&timestamp=$(echo ${sign} | cut -d'&' -f1)&sign=$(echo ${sign} | cut -d'&' -f2)"

    # 添加当前时间到消息内容中
    local current_time=$(TZ="Asia/Shanghai" date "+%Y-%m-%d %H:%M:%S")
    local message_with_time="${current_time} - ${SERVER_NAME} - ${message}"

    echo "发送钉钉消息: ${message_with_time}" >> "$LOG_FILE"

    curl -s -X POST "${url}" \
        -H "Content-Type: application/json" \
        -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"${message_with_time}\"}}"
}

# 执行命令并获取输出
execute_and_send() {
    cd ~/ceremonyclient/node || { echo "目录不存在"; exit 1; }
    local output=$(./node-1.4.21.1-linux-amd64 -node-info 2>&1)

    # 添加日期标记
    local current_date=$(TZ="Asia/Shanghai" date "+%Y-%m-%d")
    echo "---- $current_date 查询结果 ----" >> "$LOG_FILE"

    # 发送命令输出到钉钉，并记录日志
    if [[ -n "$output" ]]; then
        send_dingtalk_message "$output"
        echo "$output" >> "$LOG_FILE"
    else
        send_dingtalk_message "命令执行失败或无输出"
        echo "命令执行失败或无输出" >> "$LOG_FILE"
    fi
}

# 计算从现在到下一个10:00的秒数
calculate_sleep_duration() {
    local current_time=$(TZ="Asia/Shanghai" date +%s)
    local next_target_time=$(TZ="Asia/Shanghai" date -d "10:00 next day" +%s)

    # 如果当前时间在10:00之前，则目标时间为今天的10:00
    if [[ $(date +%H) -lt 10 ]]; then
        next_target_time=$(TZ="Asia/Shanghai" date -d "10:00 today" +%s)
    fi

    echo $((next_target_time - current_time))
}

# 主循环
while true; do
    # 计算睡眠时间
    sleep_duration=$(calculate_sleep_duration)

    echo "等待 ${sleep_duration} 秒，直到北京时间10:00..." >> "$LOG_FILE"
    sleep "$sleep_duration"

    # 执行任务
    execute_and_send
done
